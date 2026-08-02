# Exogenous shocks

A catalog of every `varexo` in DGE-METRIC: what each family represents, how a value set in Excel
or MATLAB actually reaches `oo_.exo_simul`, and the mechanisms/pitfalls specific to shocks that
aren't obvious from reading a single equation. For the broader calibration → steady-state →
simulation pipeline, see [running.md](running.md) and [model.md](model.md); this page is scoped to
the exogenous-variable layer only.

## 1. Where shocks are declared

All exogenous variables are declared in **one place**: the `varexo` block in
[ModFiles/DGE_Model_Declaration.mod](../../ModFiles/DGE_Model_Declaration.mod) (lines 191–302),
included from `DGE_Model.mod`. The block is entirely macro-generated — concrete names like
`exo_A_2_1` or `exo_PE_1` come from `@# for sec/subsec/reg/secm` loops driven by the compile-time
macros at the top of `DGE_Model.mod` (`Sectors`, `Subsecstart`/`Subsecend`, `Regions`). If the
sector/region structure changes, the whole `varexo` list reshapes on the next `dynare` compile —
don't hand-list shock names anywhere that has to stay in sync; always regenerate from the compiled
`M_.exo_names`.

**This is the only file to edit to add a genuinely new shock.** Everything downstream (`posIdx`,
Excel column matching, `AdditionalShocks`) discovers shocks by name against `M_.exo_names` and
needs no separate registration — except `define_auxiliary_expressions_looped.m`'s `specs` table
(§2), which needs one new row if you want a convenient `posIdx.iposXxx` handle for the new family.

## 2. How a shock value reaches the model

```
Excel workbook (varexo-named column headers)
        │  load_exogenous.m
        ▼
oo_.exo_simul  (nPeriods × nExo matrix, one column per varexo, indexed by M_.exo_names position)
        │  posIdx.iposXxx(k)  ← column index for instance k of shock family Xxx
        ▼
perfect_foresight_solver / steady-state solver read oo_.exo_simul at the relevant column
```

- `oo_.exo_simul` is a plain `[nPeriods x nExo]` matrix. There is no other storage for a shock's
  time path — everything that "sets a shock" ultimately writes into a column of this matrix.
- **`posIdx`**, built by
  [Functions/Miscellaneous/ModelSetup/define_auxiliary_expressions_looped.m](../../Functions/Miscellaneous/ModelSetup/define_auxiliary_expressions_looped.m),
  is the lookup table from a human-readable shock family (e.g. "public capital stock shocks") to
  the actual column indices. It works off a `specs` table (one row per family: name prefix,
  loop dimensions, target `'exo'|'endo'|'param'`, output variable names) — for each row it builds
  the concrete name list (`exo_K_G_1_1, exo_K_G_2_1, ...`) and resolves it against
  `M_.exo_names`/`M_.endo_names`/`M_.param_names` with `ismember`. The result is stored as
  `posIdx.iposKGShocks`, etc. **Treat `posIdx` as generated infrastructure** (per `CLAUDE.md`) —
  don't hand-edit index numbers; if a shock family has no `posIdx` entry, add a row to the `specs`
  table instead.
- **Silent-zero gotcha**: if a `specs` row's prefix doesn't match any declared `varexo` (a stale
  entry, or a typo), `ismember` returns `ipos == 0` for every instance — `posIdx.iposXxx` becomes a
  vector of zeros rather than erroring, and indexing `oo_.exo_simul(:, 0)` errors far from the real
  cause. `exo_REShare_`, `exo_rexo_`, and `exo_piM` are current examples of `specs` rows with no
  backing `varexo` — don't assume a `posIdx` field name means the shock exists; check
  `any(posIdx.iposXxx ~= 0)` first (this is exactly what
  `simulation_model_refactored.m` does before touching `posIdx.iposREShocks`).
- **`iposIGShocks` is an alias, not a distinct shock**: it's set equal to `iposKGShocks`
  (`define_auxiliary_expressions_looped.m:226-231`) for old code that called the public-capital
  shock "public investment." The underlying `varexo` is `exo_K_G_*` — a **stock** log-multiplier —
  not `exo_I_G_*`, which doesn't exist as a `varexo` at all (see §3's header-rename note).

## 3. How shocks get their values in practice

### 3.1 Excel (the normal path — use this unless you have a specific reason not to)

[Functions/Miscellaneous/Simulation/load_exogenous.m](../../Functions/Miscellaneous/Simulation/load_exogenous.m)
reads a sheet whose header row is `varexo` names and whose first column is the period index, and
writes matched columns into `oo_.exo_simul`. Routing is by `sScenario`:

- `sScenario == 'Baseline'` → `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx`, sheet
  `sBaselineSheet` (default `'Baseline'`).
- any other scenario name → `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx`, sheet named
  exactly `sScenario`.
- a scenario name containing `.csv` → `ExcelFiles/Input/<name>.csv`, a period-indexed matrix
  parsed with `textscan`/`str2num` (used by single-shock scenarios like
  `ImportShock_Fossil2_P10`, see `RunSimulations.m`'s `ImportShock` group).

Practical rules:
- **Periods after the last row in the sheet are held flat** at the last provided value
  (`load_exogenous.m:48`) — you do not need to fill every period out to the simulation horizon,
  but you do need to know that "last row" silently becomes "forever after."
- **Untouched shocks must be left at 0** in the sheet (or omitted) — a column not present in the
  sheet is simply never written, so it keeps whatever `oo_.exo_simul` already had (usually the
  steady-state default of 0). Don't rely on an omitted column meaning "off" if a previous step in
  the pipeline already wrote something non-zero into that column.
- **Legacy header rename**: a column literally named `exo_I_G_<subsec>_<reg>` in an old workbook is
  silently remapped to `exo_K_G_<subsec>_<reg>` on read (`load_exogenous.m:40-45`). Don't rely on
  this for new sheets — write `exo_K_G_*` directly.
- `simulation_model_refactored.m` calls `load_exogenous` twice in a row with identical arguments
  before proceeding (an existing idiosyncrasy, harmless for plain numeric loads — not something to
  "clean up" without checking why it was doubled).

### 3.2 `AdditionalShocks` — post-baseline programmatic layer

Documented in
[Functions/QUICKSTART_AdditionalShocks.md](../../Functions/QUICKSTART_AdditionalShocks.md) and (less
reliably — see warning below)
[Functions/README_AdditionalShocks.md](../../Functions/README_AdditionalShocks.md). Implemented by
`apply_additional_shocks_from_start` in
[Functions/simulation_model_refactored.m:919-1015](../../Functions/simulation_model_refactored.m).

**What it actually does:**
1. During each step of the Baseline homotopy loop, every shock listed in `AdditionalShocks` is
   force-zeroed in `oo_.exo_simul`.
2. Once the Baseline loop finishes, each listed shock's **original Excel-loaded path** — captured
   earlier into `oo_.exo_simul_start` before any zeroing happened — is reintroduced in
   `fineTuneSteps` increments (`tuneFrac = iTune/fineTuneSteps` for `iTune = 1..fineTuneSteps`),
   calling `perfect_foresight_solver` after every increment and warning
   (`AdditionalShocks:SolverDidNotConverge`-style message) if
   `oo_.deterministic_simulation.status ~= 1`.
3. If `AdditionalShocks` is undefined or empty, this mechanism is a complete no-op.

**Struct schema — only three fields are actually consumed:**

| Field | Required | Description |
|---|---|---|
| `shockIndex` | Yes | Column index in `oo_.exo_simul`, typically `posIdx.iposXxx(k)` |
| `name` | Yes | Label used in log output |
| `fineTuneSteps` | No (default `1`) | Number of incremental re-solve steps |

> **Do not follow `README_AdditionalShocks.md`'s "Shock Structure Fields" table literally.** It
> lists `periods` (cell array of period ranges) and `values` (numeric array) as required fields
> with a worked example that sets them — but `apply_additional_shocks_from_start` never reads
> either field. The mechanism always takes the *entire* pre-existing Excel-loaded column and
> ramps it up as one block; there is no per-period-range granularity in the executing code, no
> matter what's written in `AdditionalShocks(i).periods`/`.values`. `QUICKSTART_AdditionalShocks.md`
> and the doc-comment at the top of `simulation_model_refactored.m` (lines 9-27) are the versions
> that match the actual code — use those, and set shock *values* by editing the Excel input, not by
> populating a `values` field. If updating this mechanism, update `README_AdditionalShocks.md`'s
> field table in the same change, since it's what a reader is most likely to open first.

Guidance on `fineTuneSteps` (from both docs, consistent with the code): `1` for small/stable
shocks, `2-3` for medium shocks, `4-5+` for large or tightly-coupled shock blocks; increase it if
`perfect_foresight_solver` fails to converge after a shock is applied. This mechanism only runs
inside the `Baseline`, non-backward-compatible branch of `simulation_model_refactored.m` — it does
nothing for `sScenario ~= 'Baseline'` or when `lBaselineBackward_p == 1`.

**Ordering gotcha**: `oo_.exo_simul_start` must be captured before any `AdditionalShocks` zeroing
happens (it is, at `simulation_model_refactored.m:119`) — that's what lets the zero/reapply trick
work without losing the original Excel values. Also, several other shock columns are re-derived
from `oo_.exo_simul_start` on *every* homotopy step regardless of `AdditionalShocks`
(`simulation_model_refactored.m:808-841`, e.g. `iposProdIShocks`, `iposKGShocks`, `iposQShocks`).
**Any manual, mid-loop edit you make directly to `oo_.exo_simul` for one of those columns will be
silently overwritten on the next step** — if you need a one-off manual override, edit
`oo_.exo_simul_start`, not `oo_.exo_simul`, before the loop starts.

## 4. The Baseline-only endogenous-target pattern (EE_reg/Q_fossil, tauCEndo/G_reg)

Two shocks — `exo_EE_<reg>` and `exo_tauC_<reg>` — aren't ordinary Excel-driven inputs in the
Baseline scenario. Instead, the corresponding *endogenous* variable (`EE_<reg>`, `tauCEndo_<reg>`)
is solved by the model to hit a calibration target, and the resulting path is then transcribed
*into* the exogenous shock so that every non-Baseline scenario reproduces the Baseline path
exactly (rather than re-deriving it, which would require re-solving the same target in every
scenario). This pattern is documented in detail in `CLAUDE.md` under "Standard workflow:
Baseline-only endogenous targets" — this section is the shock-specific summary.

**Mechanism:**
1. **One compile-time indicator drives both.** `RunSimulations.m` → `change_mod_file.m` always
   sets `YEndogenous`, `NEndogenous`, and `BaselineScenario` together from a single
   `contains(sScenario,'Baseline')` test — Baseline is always `YEndogenous=0`; every other scenario
   is always `YEndogenous=1`. `lEndogenousY_p` (the runtime copy of `YEndogenous`) is therefore a
   reliable, already-existing proxy for "was this compiled as Baseline" — don't add a second,
   separate flag for a new instance of this pattern.
2. **A runtime multiplier inside one equation, not `@#if`/`@#else`.** Dynare's strict mode requires
   every declared `varexo` to appear textually in the model block, so a preprocessor branch would
   make each compiled variant miss the shocks used only in the other branch. Both governing
   equations use `(expr_a)*(lEndogenousY_p==0) + (expr_b)*(lEndogenousY_p==1)` on each side:
   - `EE_<reg>`/`Q_fossil` — [ModFiles/Equations/climate_emissions.mod:78-84](../../ModFiles/Equations/climate_emissions.mod):
     `EE_<reg>*(Y endog=1) + Q_fossil_<reg>*(Y endog=0)` on the left,
     `exp(exo_EE_<reg>)*(Y endog=1) + Q0_fossil_<reg>_p*exp(exo_Q_fossil_<reg>)*(Y endog=0)` on the
     right.
   - `tauCEndo`/`G/Y` — [ModFiles/Equations/government.mod:98-103](../../ModFiles/Equations/government.mod):
     `(G_<reg>/Y_<reg>)*(Y endog=0) + tauCEndo_<reg>*(Y endog=1)` on the left,
     `(GY0_<reg>_p+exo_targetGY_<reg>)*(Y endog=0) + (tauC_<reg>_p+exo_tauC_<reg>+exo_tauCScen_<reg>)*(Y endog=1)`
     on the right. Note `exo_tauCScen_<reg>` is a *separate* shock, layered on top of the
     Baseline-required `exo_tauC_<reg>` path, for scenario-specific consumption-tax policy shocks —
     don't put scenario tax policy into `exo_tauC_<reg>` itself, it will be overwritten by the
     Baseline transfer (step 4 below).
3. **Freed only inside the hybrid steady-state solver** (`lCalibration_p==2`, a MATLAB-only runtime
   switch, never appearing in any `.mod` equation): the free variable is added to
   `build_initial_guess.m`'s `'hybrid'` unknown vector, with a matching pinning residual in
   `Functions/SteadyState/computeCapital/evaluate_capital_steady_state_residuals.m`:
   `fval_vec_11` (lines 304-313) pins `Q_fossil = Q0*exp(exo_Q_fossil)`, freeing `EE_reg`;
   `fval_vec_13` (lines 339-346) pins `G_reg/Y_reg` to `GY0_reg_p + exo_targetGY_reg`, freeing
   `tauCEndo`. **`fval_vec_11` must never be removed** — see §5.
4. **Transfer into the exogenous shock for every non-Baseline scenario**, done by
   `apply_baseline_shock_structure` (`Functions/simulation_model_refactored.m:663-754`), called
   once per scenario compile. The transfer formula follows the *shape of the governing equation* —
   don't copy one variable's formula onto another:
   - **Log-ratio against the series' own period-1 value**, for `exp()`-form equations where the
     shock is a *multiplicative* deviation:
     `exo_simul(:,iposEERegShocks) = log(baselineSim(EE_reg,:) ./ baselineSim(EE_reg,1))` (line 685).
     Same shape for `iposProdShocks` (TFP), `iposPriceHShock` (house prices).
   - **Additive difference against the calibrated parameter**, for linear/additive equations:
     `exo_simul(:,iposTauCShocks) = baselineSim(tauCEndo,:) - M_.params(iposTauCParams)` (line 721)
     — subtracting the *parameter* `tauC_<reg>_p`, not a period-1 value, because the governing
     equation is additive (`tauC_p + exo_tauC`), not multiplicative.
   - Other transfer shapes exist for other shocks in the same function and are **not
     interchangeable** — e.g. the exchange-rate shock `exo_s_<reg>` is back-solved algebraically
     from its own AR(1) law (`s(t) = rhos_p*s(t-1) + (1-rhos_p)*s0_p*exp(exo_s(t))`, lines 730-737),
     and wedge/adjustment-cost shocks are copied directly with no transform at all (additive-in-
     `exp()` wedges, lines 674-675, 691-693) because their governing equation already treats the
     shock as an untransformed additive term.
   - Two Baseline-only targeting *switches*, `exo_ltargetIY_*` and `exo_lNXTarget_<reg>`, are
     explicitly zeroed for scenarios (lines 707-712, 738-740) so the ordinary-scenario branch of
     their equations doesn't try to re-solve for the target a second time on top of the transferred
     path.
5. **Don't re-derive an existing accounting identity when computing a Baseline target.** `G_reg`'s
   GDP-identity formula already satisfies the government budget constraint via Walras' law; a
   since-reverted attempt to re-derive it directly from the budget constraint introduced a
   term-omission bug (`CLAUDE.md`). If a target can be read off an identity that already balances,
   read it off — don't rebuild the identity.

**If you're adding a third instance of this pattern**: reuse `lEndogenousY_p`
(step 1), write the runtime-multiplier equation on both sides (step 2), add a paired
free-variable/pinning-residual to the hybrid solver only (step 3, and add both halves together —
see §5), and write a transfer line in `apply_baseline_shock_structure` whose shape matches your
equation's functional form, not `EE_reg`'s or `tauCEndo`'s by default.

## 5. Cap-and-trade regime shocks

`lCapandTrade_p` is a compile-time macro (`CapandTrade` in `DGE_Model.mod`, set via
`change_mod_file.m`) that selects between two closure regimes in
[ModFiles/Equations/climate_emissions.mod:60-76](../../ModFiles/Equations/climate_emissions.mod):
an exogenous emission-price path (`exo_PE_<reg>`) or a binding regional cap (`exo_E_<reg>` /
`exo_CapTrade_<reg>` / `exo_CapTradeInternat`). `RunSimulations.m` sets `CapandTrade=0` for
Baseline and `CapandTrade=1` for `NZ_*`/`PDP8_GF_*` scenario groups.

**Guardrail (added after a past silent-failure incident, see commit `f6f2052`)**: compiling with
`lCapandTrade_p==1` while a region's Excel `exo_CapTrade_<reg>` value is left at `0` leaves the cap
equation inert — the model runs, converges, and produces output with no binding cap, silently.
`DGE_Model_steadystate.m` now emits a `warning('DGE:CapTradeRegionalFlagOff', ...)` if this
combination is detected, but **it is only a warning, not a hard error** — always check for it in
the console output after compiling a cap-and-trade scenario, don't assume "it ran without errors"
means the cap was actually binding.

If you're running a cap-and-trade scenario: set `exo_CapTrade_<reg> = 1` (and
`exo_CapTradeInternat` if relevant) for every affected region in the scenario's Excel sheet, in
addition to whatever `exo_E_<reg>` cap-level path you intend.

## 6. Full shock catalog by mechanism

Every `varexo` in `ModFiles/DGE_Model_Declaration.mod`, grouped by what it drives. `<s>`/`<r>` are
subsector/region loop indices; `<k>` is a second sector index for 3-D shocks (intermediate-input
flows). Where a family has a `posIdx` handle, it's listed for convenience — re-derive it from
`define_auxiliary_expressions_looped.m` rather than trusting this table blindly if it's been a
while since this doc was written, since `posIdx` regenerates from the compiled model.

### Macro / global
| Shock | Meaning |
|---|---|
| `exo_rf` | world interest rate |
| `exo_beta` | discount factor |

### Productivity / TFP (`ModFiles/Equations/productivity_damages.mod`, `wholesalers.mod`, `firms.mod`)
| Shock | Meaning | `posIdx` |
|---|---|---|
| `exo_<s>_<r>` | sector/region TFP (the one actually wired to `iposProdShocks`) | `iposProdShocks` |
| `exo_A_<s>_<r>` | **duplicate declaration**, same long_name as above, different `posIdx` field | `iposProdAShocks` |
| `exo_N_<s>_<r>` | labour-specific TFP | `iposProdShocksN` |
| `exo_K_<s>_<r>` | capital-specific TFP | — |
| `exo_A_I_<s>_<r>` | intermediate-input productivity | `iposAIShock` |
| `exo_A_D_<s>_<r>` | wholesaler/efficiency productivity | `iposADShock` |
| `exo_A_F_<sec>_<r>` | final-use productivity (aggregate-sector loop) | `iposAFShock` |
| `exo_AI_<s>_<r>_<k>` | 3-D intermediate productivity, per source sector | `iposAIShocksec` |
| `exo_QI_<s>_<r>` | intermediate-input share shock | `iposQIShock` |
| `exo_mu_<s>_<r>` | markup shock | — |

> `exo_<s>_<r>` and `exo_A_<s>_<r>` are two distinct declared `varexo` with the identical
> long_name `${\eta^{A,s,r}}$` (`DGE_Model_Declaration.mod:216,218`) — easy to shock the wrong one.
> Only the unprefixed `exo_<s>_<r>` is `iposProdShocks`; `exo_A_<s>_<r>` is the separate
> `iposProdAShocks`. Check which one an equation you're reading actually references.

### Energy efficiency / fossil output
| Shock | Meaning |
|---|---|
| `exo_EE_<r>` | regional energy efficiency — Baseline-solved target, see §4 |
| `exo_Q_<s>_<r>` | fossil-output driver when `lEndogenousY_p==0` (long_name says "share of emissions not part of ETS" — stale/misleading, its actual runtime role is the §4 fossil-output pin) |
| `exo_lAddEE_<s>_<r>` | switch: 1 = `exo_EE_<r>` additive to this subsector's EE gains; 0 = suppressed (used where PV/VNEEP3 is the sole EE driver for that subsector) |
| `exo_REShare_<r>` | **vestigial** — appears only as a `posIdx` spec row (`iposREShocks`), no backing `varexo`; do not use |

### Capital / investment (`ModFiles/Equations/investment_adjustment.mod`, `investment_wedge.mod`)
| Shock | Meaning | `posIdx` |
|---|---|---|
| `exo_I_<s>_<r>` | investment growth shock | `iposProdIShocks` |
| `exo_K_G_<s>_<r>` | public capital stock, log multiplier | `iposKGShocks` (alias `iposIGShocks`) |
| `exo_phiG_<s>_<r>` | public-capital-share shock | `iposphiGShocks` |
| `exo_r_G_<s>_<r>` | government rental rate | `iposrGShocks` |
| `exo_r_FDI_<s>_<r>`, `exo_I_FDI_<s>_<r>`, `exo_lFDIShare_<s>_<r>`, `exo_sFDIShare_<s>_<r>` | FDI capital block | `iposrFDIShocks`, `iposIFDIShocks`, `iposLFDIShareShocks`, `ipossFDIShareShocks` |
| `exo_lIGShare_<s>_<r>`, `exo_sIGShare_<s>_<r>` | I_G/I share-mode switch and target share | `iposLIGShareShocks`, `ipossIGShareShocks` |
| `exo_s_G_<s>_<r>`, `exo_s_GScen_<s>_<r>` | public savings rate (base and scenario) | `ipossGShocks`, `ipossGScenShocks` |
| `exo_u_K_<s>_<r>` | capital utilization | `iposUShocks` |
| `exo_KTarget_<s>_<r>`, `exo_KTargetB_<s>_<r>` | capital-target binary/level per plan | `iposKTarShocks`, `iposKTarBShocks` |
| `exo_P_K_<s>_<r>` | capital-goods price (active when `lCapPrice==1`) | `iposPKShocks` |
| `exo_phiK_<s>_<r>` | investment adjustment cost (active when `lCapPrice==0`) | `iposphiKShocks` |
| `exo_targetIY_<s>_<r>`, `exo_muI_<s>_<r>`, `exo_ltargetIY_<s>_<r>` | I/Y-targeting wedge triple — see §7 landmine on reading period-1 values | `iposTargetIYShocks`, `iposMuIShocks`, `iposLTargetIYShocks` |

### Government / fiscal (`ModFiles/Equations/government.mod`)
| Shock | Meaning |
|---|---|
| `exo_tauC_<r>` | consumption tax — Baseline-required path, set programmatically for scenarios, see §4 |
| `exo_tauCScen_<r>` | scenario-specific *additional* consumption tax, layered on top of `exo_tauC_<r>` |
| `exo_tauH_<r>` | housing tax |
| `exo_tauNH_<r>` | labour income tax paid by households |
| `exo_tauKF_<s>_<r>`, `exo_tauKH_<s>_<r>` | corporate / capital-income tax rate |
| `exo_tauNF_<s>_<r>` | sector labour tax rate |
| `exo_BG_<r>` | structural balance target |
| `exo_phi_BG_ext_<r>` | share of public debt held externally |
| `exo_Tr_<r>` | transfer payments |
| `exo_targetGY_<r>` | deviation from initial G/Y ratio (Baseline-active, see §4) |
| `exo_tauS_<r>`, `exo_tauSTr_<r>` | ETS-revenue subsidy / transfer share |
| `exo_GA_<s>_<r>`, `exo_G_A_DH` | climate adaptation expenditure (per-sector, housing) |

### Trade / exports / imports (`ModFiles/Equations/rest_of_world.mod`)
| Shock | Meaning |
|---|---|
| `exo_X_<s>_<r>` | export demand shock |
| `exo_M_<s>`, `exo_lMAmount_<s>`, `exo_MAmt_<s>` | import price/amount hybrid — see [README_ImportShocks.md](../implementation_plans/README_ImportShocks.md); `lMAmount` selects regime (0=price via `exo_M_`, 1=amount via `exo_MAmt_`, log-growth) |
| `exo_NX_<r>`, `exo_NXL_<r>`, `exo_lNXTarget_<r>` | net-export-to-GDP target and its Baseline-only switch |
| `exo_B_<r>`, `exo_BL_<r>`, `exo_deltaB_<r>`, `exo_adjB_<r>` | net foreign asset position, depreciation, adjustment cost |
| `exo_s_<r>` | FX/valuation AR(1) innovation — back-solved for Baseline transfer, see §4 |

### Capacity / demographics
| Shock | Meaning |
|---|---|
| `exo_H_<r>` | housing-area-to-population ratio |
| `exo_PV_<r>`, `exo_PVEff_<r>` | rooftop-PV investment / efficiency |
| `exo_LF_<r>`, `exo_NLF_<r>` | labour-force / non-labour-force population growth |

### Price
| Shock | Meaning |
|---|---|
| `exo_P_D_<r>` | regional price-level shock |

### Emissions / climate (`ModFiles/Equations/climate_emissions.mod`)
| Shock | Meaning |
|---|---|
| `exo_kappaE_<s>_<r>`, `exo_kappaE_NOETS_<s>_<r>` | emission intensity (ETS-covered / not) |
| `exo_E_<s>_<r>` | sub-sector emissions target (hybrid-calibration pin) |
| `exo_E_NOETS_<s>_<r>`, `exo_lE_NOETS_Target_<s>_<r>` | non-ETS emissions and its targeting switch |
| `exo_EI_<s>_<r>_<k>` | 3-D: emissions embodied in intermediate use |
| `exo_wedgeKE_<s>_<r>` | emission-intensity capital-rental wedge (SRI/green-taxonomy) |
| `exo_GA_<s>_<r>`, `exo_G_A_DH` | adaptation expenditure |
| `exo_<z>_<r>` / `exo_<z>` (`z`=`tas`) | regional / national climate variable |
| `exo_CapTradeInternat`, `exo_CapTrade_<r>`, `exo_PE_<r>`, `exo_E_<r>`, `exo_EBase_<r>` | cap-and-trade regime — see §5 |
| `exo_E`, `exo_PE` | national aggregate emissions / price closure |
| `exo_D_<s>_<r>`, `exo_D_N_<s>_<r>`, `exo_D_K_<s>_<r>`, `exo_DH_<r>` | climate damage (TFP, labour-TFP, capital, housing) |

## 7. Landmines specific to shocks

- **Never remove `fval_vec_11`**
  (`Functions/SteadyState/computeCapital/evaluate_capital_steady_state_residuals.m:304-313`). It
  pins `Q_fossil` in hybrid calibration (`lCalibration_p==2`), the closing residual that frees
  `EE_reg` (§4). Removing it makes the hybrid steady-state underdetermined and `fsolve` will fail
  to converge — this has been mistakenly "cleaned up" before.
- **`fval_vec_13` is its sibling for `tauCEndo`/`G_reg`** (same file, lines 339-346) — add or remove
  a free variable and its pinning residual **together**. Dropping one while keeping the other
  silently removes a degree of freedom; in practice this produced a small, hard-to-trace nonzero
  residual in an unrelated equation because the solver borrowed slack from the other pin to
  compensate.
- **`AdditionalShocks(i).periods`/`.values` are dead fields** — see §3.2. Setting them does
  nothing; the entire pre-existing Excel-loaded column is always used.
- **`exo_sKGmax_<s>_<r>` no longer exists** as a `varexo` (removed in commit `f6f2052`), but
  `Functions/SteadyState/compute_production_factors_and_output.m` still has an `isfield` guard for
  it that degrades to a no-op. Comments referencing it as a tunable lever are stale — there is no
  way to set this shock any more.
- **Duplicate `exo_<s>_<r>` / `exo_A_<s>_<r>`** — see the Productivity/TFP table note above.
  Confirm which `posIdx` field (`iposProdShocks` vs. `iposProdAShocks`) an equation actually reads
  before writing a shock to "the" TFP variable.
- **Vestigial `posIdx` spec rows with no backing `varexo`**: `exo_REShare_`, `exo_rexo_`,
  `exo_piM`. Guard with `any(posIdx.iposXxx ~= 0)` before indexing, per §2.
- **Shocks re-derived every homotopy step get silently overwritten by mid-loop manual edits** —
  see the ordering gotcha at the end of §3.2. If you need a one-off override, edit
  `oo_.exo_simul_start` before the loop, not `oo_.exo_simul` inside it.
- **`exo_targetIY_<s>_<r>`/`exo_ltargetIY_<s>_<r>`/`exo_muI_<s>_<r>` are structurally 0 at steady
  state** — reading `oo_.exo_simul(1, idx)` for these does **not** give the empirically observed
  period-1 investment/GDP ratio, just an unset placeholder.
  `simulation_model_refactored.m:212-231` substitutes the real empirical ratio explicitly for this
  reason; don't read period-1 `exo_targetIY` naively elsewhere.
- **Cap-and-trade regional flag** — see §5. A `lCapandTrade_p==1` compile with
  `exo_CapTrade_<r>==0` in Excel produces a silently non-binding cap; only a warning is raised, not
  an error.
- **Population-path approximation breaks under endogenous multi-region migration** —
  `simulation_model_refactored.m:255-264` (warning ID `simulation_model_refactored:PopPathApproximation`)
  falls back to a flat population path whenever `lEndoMig_p==1 && inbregions_p>1`, since the
  `exo_LF_1`-based shortcut used for PDP8 investment/capital reconciliation assumes exogenous
  labour force. Not currently triggered at `Regions=1`, but relevant if the model is ever run with
  more than one region and endogenous migration.

## 8. Setting a shock — practical checklist

1. Confirm the `varexo` name and its loop dimensions in
   [ModFiles/DGE_Model_Declaration.mod](../../ModFiles/DGE_Model_Declaration.mod) (or `M_.exo_names`
   after compiling) — don't guess the naming convention from a similar-looking variable.
2. Check whether it's one of the two Baseline-only targeted shocks in §4
   (`exo_EE_<r>`, `exo_tauC_<r>`) — if so, **don't set it directly for the Baseline scenario**; it's
   solved by the hybrid steady-state and transcribed automatically. For non-Baseline scenarios,
   layer scenario-specific policy onto `exo_tauCScen_<r>` (not `exo_tauC_<r>`, which will be
   overwritten by the Baseline transfer).
3. If it's a cap-and-trade shock, make sure `exo_CapTrade_<r>` is also set to `1` for every
   affected region (§5) — the guardrail only warns, it doesn't stop the run.
4. Add the column, with header exactly matching the `varexo` name, to the appropriate sheet: the
   `Baseline` sheet in `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx` for a Baseline-wide input,
   or a named sheet in `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx` matching your scenario
   name. Fill values only for the periods where the shock is active; later periods hold flat at the
   last provided value.
5. Only reach for `AdditionalShocks`/`fineTuneSteps` (§3.2) if the solver fails to converge with
   the shock applied all at once from period 1 — it's a convergence aid for Baseline shocks with
   large magnitude, not a general-purpose shock-input mechanism, and it only fires for
   `sScenario=='Baseline'`.
6. Re-run `dynare DGE_Model.mod`/`RunSimulations` (never hand-edit generated `+DGE_Model/`,
   `*_dynamic.m`, or `*_static.m` files to reflect a shock change).

## See also

- [Functions/QUICKSTART_AdditionalShocks.md](../../Functions/QUICKSTART_AdditionalShocks.md) — the
  accurate `AdditionalShocks` reference; prefer this over `README_AdditionalShocks.md`.
- [docs/implementation_plans/README_ImportShocks.md](../implementation_plans/README_ImportShocks.md) —
  worked examples for the import price/amount hybrid shock.
- [docs/running.md](running.md) — `RunSimulations.m` scenario-group mechanism and env var overrides.
- [docs/model.md](model.md) — full equation reference, including the equations shocks feed into.
- `CLAUDE.md` §"Standard workflow: Baseline-only endogenous targets" — the template this doc's §4
  summarizes, written for adding a *new* instance of the pattern.
