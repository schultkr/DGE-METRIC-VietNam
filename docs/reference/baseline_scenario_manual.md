# Baseline Scenario Manual

This manual explains the live one-region, five-subsector Baseline input in
`ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx`: what every column means, where its values come
from, how `ScenarioPathDefinition.xlsx` is converted into the runnable sheet, and how the model
uses the result.

The intended reader is a model user, not only a workbook developer. The most important distinction
is:

> `ScenarioPathDefinition.xlsx` expresses assumptions in readable levels, indices, shares, and
> switches. `ModelBaseline5Sectorsand1Regions.xlsx` is the period-indexed, model-facing
> representation after conversions and optional overlays.

## 1. What the Baseline represents

Baseline is the policy-consistent reference trajectory used for comparison with all other
scenarios. It is aligned with the PDP8 reference path and does not impose an active Net-Zero
binding emissions cap. It is not a "no change" scenario: it contains structural transformation,
demographic change, fossil decline, renewable expansion, carbon-price assumptions, investment
targets, rooftop solar, and energy-efficiency measures.

Related conceptual documentation:

- [Scenarios at a glance](../policy/scenarios_overview.md)
- [Scenario design and implementation](scenario.md)
- [Exogenous shocks](exogenous_shocks.md)
- [Technical report](../reports/TECHNICAL_REPORT.md)

## 2. The workbook in one minute

The live workbook contains two sheets:

| Sheet | Live range | Purpose |
|---|---:|---|
| `Content` | `A1:B2` | Minimal sheet index: `Sheet`, `Link`, and the `Baseline` entry. It is not read by the model. |
| `Baseline` | `A1:BV27` | Header row plus 26 annual observations, 2026-2051. This is the sheet read by the Baseline loader. |

The `Baseline` sheet has no blank data cells in its live range. A zero, one, or negative value is
therefore usually meaningful; it is not a missing value.

### 2.1 Row and time conventions

- Row 1 contains column names.
- Rows 2-27 represent 2026-2051.
- `Time` runs from 2 to 27 because period 1 is the calibrated 2025 initial state. The workbook
  supplies the transition beginning in period 2.
- `Year` is a human-readable label. `load_exogenous.m` uses `Time`, not `Year`, to place values in
  `oo_.exo_simul`.
- If the simulation is longer than the last workbook row, the loader holds the final value flat.

### 2.2 Sector and suffix conventions

| Number | Subsector |
|---:|---|
| 1 | Primary |
| 2 | Fossil |
| 3 | Renewables |
| 4 | Secondary / industry |
| 5 | Tertiary / services |

There is one region, so the regional suffix is `_1`. For example,
`exo_K_G_3_1` means the public-capital input for renewables in region 1.

In `exo_AI_4_1_2`, the suffixes mean receiving subsector 4, region 1, and source sector 2
(energy intermediates). The final `_2` is not a second region or a time index.

## 3. How to read the numbers

The workbook mixes four numerical conventions. Reading every column as a percentage is incorrect.

| Convention | Example | Interpretation |
|---|---|---|
| Growth factor | `gY_1_1 = 1.0518` | Level is multiplied by 1.0518, i.e. growth of about 5.18%. A value below 1 is contraction. |
| Log deviation | `exo_E_2_1 = -1.3863` | The model uses `exp(value)`. Here `exp(-1.3863)=0.25`, so the level is 25% of its anchor. |
| Direct level/share/rate | `exo_sIGShare_2_1 = 0.85` | Used directly: 85%, not `exp(0.85)`. |
| Binary switch | `exo_lNXTarget_1 = 1` | Selects one branch of an equation. Use 0 or 1 only. |

The conversion text in column C of `ScenarioPathDefinition.xlsx` controls the transformation:

- `log(index/index(1))`: `log(raw index / 2025 index)`. A value of 0 means the 2025 level.
- `log(index)`: `log(raw index)`.
- `additive (index-index(1))`: `raw index - 2025 index`. A value of 0 means no change.
- `direct (level)`: pass the number through without conversion.
- `1 if value>0 else 0`: convert a positive number to 1 and zero to 0.

Do not remove or casually rewrite conversion-rule cells. A missing rule defaults to direct
pass-through and can produce plausible-looking but economically incorrect shocks.

### 3.1 Economic story told by the current paths

Taken together, the current inputs describe the following reference transition:

- aggregate value added grows while its composition shifts away from Primary and Fossil and toward
  Renewables and Tertiary/services;
- employment composition also changes, so sector employment can contract even when total
  employment is broadly flat;
- fossil emissions rise modestly in the near term and then fall, fossil production declines after
  the mid-2030s, and fossil exports approach a small floor much earlier;
- fossil and renewable investment-to-GDP targets are active through 2050 and decline as the major
  investment program matures;
- the regional emissions price rises strongly, peaks in the late 2040s, and then eases;
- rooftop solar and VNEEP3 measures add both productive energy-efficiency gains (`exo_AI`) and the
  adaptation-capital/expenditure needed to obtain them (`exo_GA`);
- fossil public investment is run in share mode through 2050, renewable FDI uses a 14% share-mode
  assumption through 2049, and both switch back to their alternative closure at the end;
- the calibrated structural-balance target is unchanged, while the Baseline keeps net exports at
  the calibrated NX/GDP ratio.

This is a model interpretation of the workbook values. The path-definition workbook records the
assumptions and transformations, but it is not by itself a source-citation register for every
underlying empirical series.

## 4. The upstream path-definition workbook

The current `ScenarioPathDefinition.xlsx` contains a `Baseline` sheet plus NZ, EE, and green-finance
scenario sheets. Only the `Baseline` sheet is used to build the Baseline workbook.

### 4.1 Required macro and labour block

The current live layout uses years 2025-2051 in columns `D:AD`:

| Rows | Assumption |
|---:|---|
| 9 | Year headers |
| 10 | Total value-added growth factor |
| 12-16 | Value-added shares: Primary, Fossil, Renewables, Secondary, Tertiary |
| 18 | Total employment growth factor |
| 20-24 | Employment shares in the same subsector order |

The 2025 column is required even though the runnable workbook begins in 2026. It supplies the
previous-year share needed to calculate the first model-year growth factor. In every year, each set
of five shares must be strictly positive and sum to one.

For subsector \(s\) and year \(t\), the builders calculate:

```text
gY(s,t) = total value-added growth factor(t)
           * VA share(s,t) / VA share(s,t-1)

gN(s,t) = total employment growth factor(t)
           * employment share(s,t) / employment share(s,t-1)
```

This is why the runnable workbook contains `gY_*` and `gN_*`, not the total-growth and share rows
themselves. Large sector growth factors can be correct when a small sector's share changes quickly.

### 4.2 Optional path blocks

The rest of the current `Baseline` sheet is organized as:

| Rows | Block |
|---:|---|
| 27-37 | Sector emissions, fossil production/exports, fossil FDI, and non-ETS emissions |
| 39-44 | Public capital stock |
| 46-51 | Target investment ratios and their switches |
| 53-58 | Investment prices |
| 60-65 | Public-capital interest rates |
| 67-69 | Global and regional emissions prices |
| 71-73 | Labour-force and non-labour-force indices |
| 75-80 | Sector energy-efficiency indices |
| 82-85 | Rooftop-PV investment/production and a currently unused power-factor row |
| 86-94 | FDI/public-investment share modes and financing rates |
| 95-98 | Fiscal balance and net-export targeting |

For these rows:

- Column A is the human-readable label.
- Column B is the exact import key written to the runnable workbook.
- Column C is the conversion rule.
- Columns D:AD contain 2025-2051 assumptions.

The generic importer processes rows whose column-B key starts with `exo_` or `idx_`. Section
headers are ignored. An optional row can therefore be added without changing a hard-coded row map,
provided its import key and conversion rule are valid.

## 5. How the runnable Baseline is created

There are two builders, and they are intentionally not equivalent.

### 5.1 Full builder

[create_baseline_from_user_input_file.m](../../scripts/maintenance/create_baseline_from_user_input_file.m)
uses `ScenarioPathDefinition.xlsx` and then enables the enriched Baseline overlays:

- PDP8 fossil/renewable investment targets;
- calibration-backed depreciation and rooftop-PV scale parameters;
- revised PDP8 rooftop-solar sector paths;
- industrial/commercial PV-to-energy-efficiency coupling;
- VNEEP3 sector-specific efficiency and adaptation-capital paths;
- the non-power non-ETS path when it is not already supplied in the path workbook.

Its current `sversion = "_replication"` setting writes
`ModelBaseline5Sectorsand1Regions_replication.xlsx`, not the canonical workbook named in this
manual. Treat promotion from the reviewed replication file to the canonical file as an explicit
release step; do not assume the script silently updates both.

### 5.2 Lite builder

[create_baseline_from_path_definition_lite.m](../../scripts/maintenance/create_baseline_from_path_definition_lite.m)
writes the canonical `ModelBaseline5Sectorsand1Regions.xlsx`, but deliberately disables external
PDP8, calibration, RTS, VNEEP3, and non-power-data overlays. It is useful for testing the dedicated
path workbook in isolation.

> The lite builder does not reproduce the enriched PV/EE paths visible in the current canonical
> workbook. It resets additive PV/EE columns before rebuilding. Do not run it merely as a
> "refresh" if the intended Baseline includes the full overlays.

### 5.3 Write order and precedence

The full build sequence is:

1. Read years, total growth, and subsector shares from `ScenarioPathDefinition.xlsx`.
2. Optionally recalculate PDP8 target-investment series and write them to the path-definition
   workbook.
3. Prepare or bootstrap the runnable sheet structure.
4. Add required demographic and non-ETS switch columns.
5. Reset additive GA/AI columns so repeated runs are idempotent.
6. Import every labeled `exo_`/`idx_` path using its conversion rule.
7. Apply higher-precedence non-ETS, RTS/PV, PV-to-EE, and VNEEP3 overlays when enabled.
8. Calculate and write `gY_*` and `gN_*`.
9. Verify that the runnable sheet is numeric and has a valid `Time` column.

Consequently, the path-definition workbook is the upstream assumption source, but not every final
cell is a direct copy. The final runnable workbook is the authoritative record of what is actually
loaded for a run.

## 6. Complete dictionary for `Baseline!A:BV`

Every live header is covered below. "Current path" summarizes the inspected workbook, not a
permanent policy rule.

### 6.1 Structure, demographics, and growth (`A:P`)

| Col. | Header(s) | Meaning and model use | Origin / current path |
|---|---|---|---|
| A | `Time` | Model period used as the row index by the loader. | 2-27. |
| B | `Year` | Calendar-year label; not a declared shock. | 2026-2051. |
| C | `exo_LF_1` | Log deviation of the labour-force population index. The demographic equation uses `LF0_1_p * exp(exo_LF_1)` when migration is exogenous. | From the labour-force index row via `log(index/2025 index)`. About 0.0073 in 2026, peaks near 0.0371, and is 0.0087 in 2050-51. |
| D | `exo_NLF_1` | Log deviation of the population outside the labour force. It combines with labour force to determine total population. | From the non-labour-force index row via `log(index/2025 index)`; rises from about 0.0018 to 0.2128. |
| E:I | `gY_1_1`, `gY_2_1`, `gY_3_1`, `gY_4_1`, `gY_5_1` | Annual real value-added growth factors for Primary, Fossil, Renewables, Secondary, and Tertiary. These are target paths used in Baseline stepping and growth audits. | Derived from total VA growth and VA shares. They are factors, not rates. |
| J:N | `gN_1_1`, `gN_2_1`, `gN_3_1`, `gN_4_1`, `gN_5_1` | Annual employment growth factors in the same subsector order. | Derived from total employment growth and employment shares. |
| O:P | `idx_LF_1`, `idx_NLF_1` | Helper/index columns retained for workbook construction and auditing. They are not declared `varexo` names and are ignored by `load_exogenous.m`. | Constant 1 in the current workbook. The actual demographic shocks are C:D. |

### 6.2 Emissions, fossil activity, and public capital (`Q:AC`)

| Col. | Header(s) | Meaning and model use | Origin / current path |
|---|---|---|---|
| Q:U | `exo_E_1_1`, `exo_E_2_1`, `exo_E_3_1`, `exo_E_4_1`, `exo_E_5_1` | Subsector emissions log paths. In the Baseline compile, `exp(exo_E_s_1)` scales the calibrated subsector emissions anchor. | Path-definition emissions indices converted with `log(index/2025 index)`. Primary, Renewables, Secondary, and Tertiary are 0; Fossil rises slightly at first and then falls to `-1.3863`, i.e. 25% of the 2025 anchor. |
| V | `exo_Q_2_1` | Fossil-output log driver in the Baseline closure. Despite a stale declaration label, this is the fossil-output pin, not a generic non-ETS share. | Fossil production index converted to a log deviation; flat initially, then falls to about `-0.2650` (roughly 76.7% of the anchor). |
| W | `exo_X_2_1` | Fossil export-demand log shock; multiplies the calibrated export-demand term. | Fossil export index converted relative to 2025. It reaches `-5.5215`, corresponding to the 0.001 floor relative to a 0.25 anchor. |
| X | `exo_I_FDI_2_1` | Fossil FDI level-mode control. It is used only when `exo_lFDIShare_2_1=0`. In the executing equation, the level-mode flow is proportional to `phiFDI0*(1-exo_I_FDI)`, so the current value 1 implies zero level-mode FDI. | Constant 1. It is inactive while fossil FDI share mode is on. |
| Y:AC | `exo_K_G_1_1`, `exo_K_G_2_1`, `exo_K_G_3_1`, `exo_K_G_4_1`, `exo_K_G_5_1` | Public-capital/replacement-investment log multipliers. In level mode, `exp(exo_K_G_s_1)` scales the public-capital replacement target. | From public-capital indices via `log(index/2025 index)`. Only Fossil and Renewables vary; the other three are 0. Fossil share mode can make `exo_K_G_2_1` inactive while its switch is 1. |

### 6.3 Investment targeting and capital prices (`AD:AL`)

| Col. | Header(s) | Meaning and model use | Origin / current path |
|---|---|---|---|
| AD:AE | `exo_targetIY_2_1`, `exo_targetIY_3_1` | Direct nominal investment-to-GDP targets for Fossil and Renewables. When the corresponding switch is 1, the investment wedge adjusts until `(I + I_G)*P_INV/(Y*P)` equals this target. | Direct shares. Current targets decline from about 2.80%/7.37% in 2026 to 0.22%/0.71% in 2050-51. Full builds may overwrite the path-definition rows using PDP8 investment plus maintenance. |
| AF:AG | `exo_ltargetIY_2_1`, `exo_ltargetIY_3_1` | Binary Baseline-only I/Y-target switches: 1 makes the wedge endogenous to hit AD:AE; 0 uses the transferred/exogenous wedge path. | 1 through 2050 and 0 in 2051. The terminal 0 prevents the target mechanism from remaining active beyond its intended path. |
| AH:AL | `exo_P_K_1_1`, `exo_P_K_2_1`, `exo_P_K_3_1`, `exo_P_K_4_1`, `exo_P_K_5_1` | Log/additive capital-goods price shocks used when the capital-price closure is active. | The path-definition indices are all 1, so conversion produces 0 in every year: no capital-price shock. |

### 6.4 Financing rates and emissions prices (`AM:AT`)

| Col. | Header(s) | Meaning and model use | Origin / current path |
|---|---|---|---|
| AM | `exo_r_G_1_1` | Additive public rental-rate deviation for Primary: `r_G` is anchored to `rf0_p + exo_r_G`. | 0. |
| AN | `exo_r_G_2_1` | Same public rental-rate deviation for Fossil. | Constant `-0.0675`, i.e. 6.75 percentage points below the reference rate in the model's rate units. |
| AO | `exo_r_FDI_2_1` | Additive fossil FDI rental-rate deviation from `rf0_p`. | 0. |
| AP:AR | `exo_r_G_3_1`, `exo_r_G_4_1`, `exo_r_G_5_1` | Public rental-rate deviations for Renewables, Secondary, and Tertiary. | All 0. |
| AS | `exo_PE` | National/global additive emissions-price component. | 0. |
| AT | `exo_PE_1` | Region-1 additive emissions-price path used in the no-cap Baseline price closure. | Direct level: 0.011 in 2026, peaks near 0.2903 in 2047, and ends near 0.2529. |

### 6.5 Sector energy efficiency and finance-share modes (`AU:BF`)

| Col. | Header(s) | Meaning and model use | Origin / current path |
|---|---|---|---|
| AU:AW | `exo_AI_1_1_2`, `exo_AI_2_1_2`, `exo_AI_3_1_2` | Log productivity additions for energy intermediates used by Primary, Fossil, and Renewables. | 0 throughout: no subsector-specific addition beyond other energy-efficiency channels. |
| AX:AY | `exo_AI_4_1_2`, `exo_AI_5_1_2` | Log productivity additions for energy intermediates used by Secondary/industry and Tertiary/services. They combine with the regional EE factor when the `lAddEE` switch is 1. | Full-build overlays add PV generation/demand efficiency and VNEEP3 measures. Industry rises from 0.005 to roughly 0.23; services from 0.02 to roughly 0.49. These are log productivity increments, not percentage-point shares. |
| AZ | `exo_lIGShare_2_1` | Fossil public-investment mode switch: 1 targets `I_G/I` using BA; 0 uses the `exo_K_G_2_1` level/replacement formula. | 1 through 2050, 0 in 2051. |
| BA | `exo_sIGShare_2_1` | Direct fossil public-investment share target used when AZ=1. | 0.85 through 2050; 0.50 in 2051, but the 2051 value is inactive because AZ=0. |
| BB | `exo_lFDIShare_2_1` | Fossil FDI mode switch: 1 uses the FDI share target in BC; 0 uses the level-mode control in X. | 1 through 2050, 0 in 2051. |
| BC | `exo_sFDIShare_2_1` | Direct fossil FDI share target used when BB=1. | 0, so fossil FDI is zero in share mode. |
| BD | `exo_lFDIShare_3_1` | Renewable FDI mode switch. | 1 through 2049, 0 in 2050-51. |
| BE | `exo_sFDIShare_3_1` | Direct renewable FDI share target used when BD=1. | Constant 0.14. It becomes inactive once BD switches to 0. |
| BF | `exo_r_FDI_3_1` | Additive renewable FDI rental-rate deviation from `rf0_p`. | Constant about `-0.03838`. |

### 6.6 Rooftop solar, adaptation capital, and audit indices (`BG:BP`)

| Col. | Header(s) | Meaning and model use | Origin / current path |
|---|---|---|---|
| BG | `idx_PV_Res_1` | Residential rooftop-PV investment index produced from the residential stock path and PV depreciation. It is an audit/helper column, not a declared `varexo`. | Varies strongly with the investment needed to create and maintain the planned stock. |
| BH | `exo_PV_1` | Direct household rooftop-PV investment term. The household equation uses `(deltaPV_p*phiKPV0_p + exo_PV_1)*Y0_p`. | In a full build, the residential stock index is converted to an investment index and scaled by `deltaPV*phiKPV0`. Current path is about 0.0013 in 2026 and 0.0224 in 2051. |
| BI:BJ | `exo_GA_4_1`, `exo_GA_5_1` | Direct adaptation-capital targets for industry and services: `K_A = exo_GA*Y0_p`. They represent the cost/capital-stock side of PV and EE measures, not their productivity benefit. | Full-build RTS stock paths plus VNEEP3 cost ramps. Current paths rise from 0.016/0.015 to about 0.228/0.255. |
| BK:BL | `idx_GA_4_1_plan`, `idx_GA_5_1_plan` | Industrial and commercial RTS stock indices used to audit the mapping into BI:BJ. Not declared shocks; ignored by the model loader. | Normalized to 1 initially, ending near 13.13 and 17.25. |
| BM | `idx_PV_1_plan` | Aggregate rooftop-PV stock index for consistency checks. Not a declared shock. | Normalized to 1 initially, ending near 15.20. |
| BN | `idx_PV_1_plan_inv` | Investment index implied by BM and the PV law of motion. Not a declared shock. | Computed as `[K_t-(1-deltaPV)K_(t-1)]/deltaPV`, with negative results clipped to zero. |
| BO:BP | `exo_lAddEE_4_1`, `exo_lAddEE_5_1` | Binary switches for industry and services. A value 1 multiplies in the regional autonomous EE factor in addition to AX:AY; 0 suppresses that regional factor for the subsector. | Constant 1: the current Baseline uses additive mode. |

The cost and benefit channels must not be confused: `exo_GA` determines adaptation capital and
associated expenditure, while `exo_AI` raises energy-intermediate productivity.

### 6.7 Non-ETS emissions, fiscal balance, and external balance (`BQ:BV`)

| Col. | Header(s) | Meaning and model use | Origin / current path |
|---|---|---|---|
| BQ | `exo_E_NOETS_1_1` | Primary-sector non-ETS emissions log path. In the Baseline closure it scales calibrated non-ETS emissions directly. | From the path-definition index via `log(index/2025 index)`, falling from 0 to about `-0.3254` by 2050-51. |
| BR | `exo_lE_NOETS_1_1` | Legacy/helper column. This exact name is not a declared `varexo`; `load_exogenous.m` ignores it. | Constant 1. Do not confuse it with BS. |
| BS | `exo_lE_NOETS_Target_1_1` | Actual declared binary non-ETS targeting switch. For endogenous-output scenario compiles, 1 makes non-ETS intensity adjust to match BQ; 0 uses the ordinary `exo_kappaE_NOETS` branch. In the Baseline compile, BQ is used directly regardless of this switch. | Constant 0. |
| BT | `exo_PVEff_1` | Rooftop-PV production/efficiency log shock. Household PV output is multiplied by `exp(exo_PVEff_1)`. | The path-definition production index is log-converted. It rises from about 0.0677 to 1.712, corresponding to a level multiplier near 5.54. |
| BU | `exo_BG_1` | Additive structural-balance target relative to calibrated `BG0_1_p`. | 0: retain the calibrated structural-balance target. |
| BV | `exo_lNXTarget_1` | Baseline-only net-export targeting switch. At 1, the model solves the external-balance variable so NX/GDP matches the calibrated ratio plus `exo_NX_1`. At 0, the ordinary AR(1) branch applies. | Constant 1. The current runnable workbook omits `exo_NX_1`; omitted shocks remain 0, matching the all-zero `exo_NX_1` row currently present in `ScenarioPathDefinition.xlsx`. |

## 7. Which columns the model actually loads

`load_exogenous.m` matches each header against compiled `M_.exo_names`.

- Headers beginning with a valid declared `exo_` name are loaded.
- `gY_*` and `gN_*` are read separately by `load_growth_rates.m`.
- `Time` supplies destination row numbers.
- `Year`, all `idx_*` columns, and the legacy `exo_lE_NOETS_1_1` column are ignored by the model
  loader. They remain useful for auditability.
- A missing exogenous column is not an error; its existing simulation value normally remains zero.

This name-based behavior is why exact spelling matters and why helper columns can coexist safely
with model inputs.

## 8. Current formula cells and the "values-only" convention

The runnable sheet is intended to be numeric and operationally values-only. The inspected workbook
nevertheless contains eight simple carry-forward formulas in the 2051 row:

- `B27 = B26 + 1`;
- `O27 = O26`, `P27 = P26`, and `X27 = X26`;
- `BR27 = BR26`, `BS27 = BS26`, `BU27 = BU26`, and `BV27 = BV26`.

Their cached results are valid, but this means the current file is not literally formula-free.
Regeneration is preferable to hand-editing these cells. If a downstream non-Excel reader is used,
confirm that it reads cached formula values.

## 9. From workbook to model solution

### 9.1 Load and calibration

1. `RunSimulations.m` selects the Baseline sheet (normally `Baseline`).
2. `load_exogenous.m` writes matching shocks into `oo_.exo_simul`.
3. `load_growth_rates.m` reads the `gY_*` and `gN_*` matrices.
4. `steadystate_model.m` solves the Baseline calibration pass and then the full steady state.
5. The resulting state becomes the initial condition for transition simulation.

### 9.2 Transition

`simulation_model_refactored.m`:

1. prepares the Baseline exogenous and growth-target paths;
2. optionally performs the initial-period investment reshuffle;
3. reconciles selected fossil/renewable investment and capital paths when enabled;
4. solves the perfect-foresight transition using stepwise homotopy;
5. stores the solved Baseline so non-Baseline scenarios can inherit required paths and initial
   conditions.

Baseline-only targeting switches such as `exo_ltargetIY_*` and `exo_lNXTarget_1` are turned off
when the Baseline solution is transferred to ordinary scenarios; those scenarios use the
transferred wedge/closure paths rather than solving the same target again.

### 9.3 Post-load adjustments that can change the effective path

The Excel values are the starting inputs, but two optional transition procedures can alter the
effective period-1 investment allocation:

- [reshuffle_initial_period.m](../../Functions/SteadyState/reshuffle_initial_period.m) aligns the
  initial investment composition and then re-derives dependent accounting blocks;
- [compute_pdp8_capital_investment_ratio.m](../../Functions/Miscellaneous/Simulation/compute_pdp8_capital_investment_ratio.m)
  supports fossil/renewable I/K reconciliation and related investment-price paths.

`simulation_model_refactored.m` also contains an operational shortcut that can scale the computed
fossil and renewable I/K targets before reshuffling. A reported Baseline must state whether those
scales were neutral (`1.0`) or non-neutral. This is not visible from the workbook alone.

Typical results are written to `ExcelFiles/Output/Baseline.csv` and stored in the Baseline entry of
the scenario-results structure. Do not manually edit files under `ExcelFiles/Output/`.

## 10. Safe editing and rebuilding workflow

1. Edit `ScenarioPathDefinition.xlsx`, not the runnable workbook, for upstream assumptions.
2. Preserve columns B and C for every optional path: exact import key and conversion rule.
3. Keep 2025 as the anchor and 2051 as the terminal extension.
4. Check that VA and employment shares are positive and sum to one in every year.
5. Decide explicitly whether the intended output is:
   - path-definition-only (`create_baseline_from_path_definition_lite.m`), or
   - full PDP8/RTS/VNEEP3 replication (`create_baseline_from_user_input_file.m`).
6. Close Excel before running MATLAB automation.
7. Review the generated workbook column-by-column before promoting it to the canonical filename.
8. Run the Baseline and validate convergence, identities, and growth audits.

See [Workbook creation procedure](../scenario_notes/workbook_creation_procedure.md) for recovery and regeneration
details.

## 11. Validation checklist

Before accepting a Baseline:

1. Workbook structure is `Baseline!A1:...`, with unique headers and `Time=2:27`.
2. Years are 2026-2051 and all cells in the live range are finite.
3. VA and employment input shares sum to one.
4. The terminal VA-share reconstruction check is near zero.
5. Every binary column contains only 0 or 1.
6. Log-index source rows are strictly positive before conversion.
7. The intended builder and output filename are documented.
8. Any full-build external input, calibration fallback, or warning is recorded.
9. Steady-state and transition solvers converge.
10. Accounting/allocation diagnostics pass.
11. `audit_baseline_gdp_growth.m` shows acceptable agreement with `gY_*` targets.
12. Any non-neutral manual I/K scaling in `simulation_model_refactored.m` is disclosed.

Useful checks:

- [audit_baseline_gdp_growth.m](../../Functions/Miscellaneous/Simulation/audit_baseline_gdp_growth.m)
- [check_results.m](../../scripts/analysis/check_results.m)
- [check_allocation_errors.m](../../Functions/steady_state/diagnostics/check_allocation_errors.m)
- [display_baseline_energy.m](../../scripts/reporting/display_baseline_energy.m)

## 12. Common misunderstandings

1. **"A value of 1 always means no shock."** False. It means no change for an index, but it can
   mean "on" for a switch, a 100% direct share,
   or—specifically for current `exo_I_FDI_2_1`—zero level-mode FDI through `1-exo_I_FDI`.

2. **"The optional blocks are ignored."** False. "Optional" means the builder can operate without
   a row; a present valid `exo_` row is
   imported and can affect the model.

3. **"The path-definition workbook and runnable workbook should match cell-for-cell."** False.
   Growth paths are derived, indices are converted, 2025 is dropped from the runnable
   transition, and full-build overlays can replace or augment imported paths.

4. **"The lite builder is a harmless refresh."** False. It intentionally excludes the external
   PV/EE and PDP8 overlays.

5. **"Every column in the runnable workbook affects Dynare."** False. `Year`, `idx_*`, and legacy
   helper columns are documentation/audit fields.

6. **"Zero means missing."** False. Zero usually means no additive/log deviation, while one
   usually means an active switch
   or an unchanged raw index. Missingness should not be encoded by guessing between zero and one.

## 13. Main implementation references

- [RunSimulations.m](../../RunSimulations.m)
- [create_baseline_from_user_input_file.m](../../scripts/maintenance/create_baseline_from_user_input_file.m)
- [create_baseline_from_path_definition_lite.m](../../scripts/maintenance/create_baseline_from_path_definition_lite.m)
- [update_baseline_excel.m](../../Functions/Miscellaneous/Excel/update_baseline_excel.m)
- [load_exogenous.m](../../Functions/Miscellaneous/Simulation/load_exogenous.m)
- [load_growth_rates.m](../../Functions/Miscellaneous/Simulation/load_growth_rates.m)
- [steadystate_model.m](../../Functions/steadystate_model.m)
- [simulation_model_refactored.m](../../Functions/simulation_model_refactored.m)
- [Workbook creation procedure](../scenario_notes/workbook_creation_procedure.md)
- [PV/EE coupling](../scenario_notes/ee_pv_coupling.md)
- [Exogenous shocks](exogenous_shocks.md)
