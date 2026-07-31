# Model Calibration: Core Accounting Logic

This note explains the calibration idea that matters most for the current model:

```math
P0_{s,r} \cdot Y0_{s,r} = FCgva_{s,r}
```

For every subsector `s` and region `r`, the baseline price-weighted value-added target in the model numeraire must equal the factor-cost gross value added actually computed during calibration. Once this identity holds, the sector-specific TFP equations have zero static residuals at the calibrated steady state, including when the baseline emission price `PE` is positive.

---

## 1. The Core Problem

The model is calibrated to national-account production data at basic prices. At the same time, the production function is written in terms of factor-cost value added: labour and capital income net of direct emission permit costs.

The key accounting objects are:

| Object | Meaning |
| --- | --- |
| `QEXP_s` | Gross output revenue at basic prices |
| `QIEXP_s` | Intermediate input expenditure |
| `emDirect_s` | Direct ETS permit cost paid by the sector |
| `FCgva_s` | Factor-cost GVA used by the production function |
| `P_s * Y_s` | Price-weighted model value added in the numeraire |

The calibration must ensure:

```math
P_s \cdot Y_s = FCgva_s
```

not merely that `P_s * Y_s` matches a share-based approximation.

---

## 2. Factor-Cost GVA

For each subsector and region, the gross-output zero-profit condition is:

```math
P_Q \cdot Q
  =
  P_s \cdot Y_s
  + P_I \cdot Q_I
  + emDirect_s
```

where:

```math
emDirect_s
  =
  \kappa E_s \cdot PE_r \cdot Q_s \cdot lEndoQ_s
```

Therefore the model's factor-cost GVA target is:

```math
FCgva_s
  =
  QEXP_s - QIEXP_s - emDirect_s
```

This is the value-added object used to calibrate labour, capital, production-function parameters, and the TFP target.

When `PE = 0`, the emission cost is zero and factor-cost GVA collapses to ordinary basic-price GVA:

```math
FCgva_s = QEXP_s - QIEXP_s
```

---

## 3. Why the Old Normalization Failed

The old TFP normalization effectively used a share-based price-weighted target:

```math
\phi Y_s \cdot Q0_p
```

That is only safe when direct emission costs are zero.

When `PE > 0`, aggregate gross output includes direct emission payments:

```math
Q0_p = (Y + \phi EF^{direct}) / \phi Y_p
```

so the share-based target becomes:

```math
\phi Y_s \cdot Q0_p
```

but the production function is calibrated to:

```math
FCgva_s = QEXP_s - QIEXP_s - emDirect_s
```

In general:

```math
\phi Y_s \cdot Q0_p \ne FCgva_s
```

That mismatch produced non-zero Dynare static residuals in the sector-specific TFP equations whenever `PE > 0`.

---

## 4. The Fix

The calibration now stores the real baseline output `Y0_s` after factor-cost GVA has been computed:

```math
Y0_s = FCgva_s / P0_s
```

Equivalently:

```math
P0_s \cdot Y0_s = FCgva_s
```

This is the central invariant. The model should never reconstruct the TFP baseline from `phiY_s`, `phiY_p`, or `Q0_p` once `FCgva_s` has already been computed.

---

## 5. Calibration Flow

The baseline calibration follows this chain:

1. Build gross-output and expenditure targets from the input-output data:

```math
QEXP_s,\quad QIEXP_s,\quad WAexp_s,\quad XEXP_s,\quad MEXP_s
```

2. Compute direct emission costs:

```math
emDirect_s = \kappa E_s \cdot PE_r \cdot Q_s \cdot lEndoQ_s
```

3. Compute factor-cost GVA:

```math
FCgva_s = QEXP_s - QIEXP_s - emDirect_s
```

4. Calibrate real value added:

```math
Y_s = FCgva_s / P_s
```

5. Store the baseline target:

```math
Y0_s = Y_s
```

6. Calibrate labour, capital, and production-function parameters using `FCgva_s` as the income base:

```math
WAexp_s + CapInc_s = FCgva_s
```

7. Use the stored target in the Dynare TFP equation:

```math
Y_s \cdot P_s
  =
  P0_s \cdot Y0_s \cdot \exp(exo_s + exo\_A_s)
```

At the calibrated steady state, `Y_s = Y0_s`, `P_s = P0_s`, and `exo_s = exo_A_s = 0`, so both sides equal `FCgva_s`.

### 5.1 Operational run sequence in the current repository

The accounting chain above is executed inside a two-pass baseline steady-state workflow:

1. `RunSimulations.m` sets workbook paths and scenario/macro context.
2. `change_mod_file.m` rewrites `DGE_Model.mod` switches (including baseline/endogenous toggles).
3. `Functions/steadystate_model.m` baseline branch runs pass 1 with `lCalibration_p = 1` and calls `DGE_Model_steadystate(...)` twice to update solved calibration parameters.
4. `Functions/steadystate_model.m` then runs pass 2 with `lCalibration_p = 0`, solves full steady state, and runs BK diagnostics.
5. Scenario solves subsequently use hybrid mode (`lCalibration_p = 2`) in `simulation_model_refactored.m`, inheriting the calibrated baseline parameter state.

---

## 6. Labour and Capital Income

Compensation of employees is matched through the wage bill:

```math
W_s \cdot N_s \cdot LF_r \cdot (1 + \tau NF_s)
  =
  WAexp_s
```

Capital income is the residual:

```math
CapInc_s = FCgva_s - WAexp_s
```

The production-function shares and CES parameters are then calibrated around this factor-cost income split. This is why `FCgva_s`, not basic-price GVA including emission taxes, is the correct denominator for factor income shares.

---

## 7. Target Modes

The output target depends on `lTargetY_p`.

| `lTargetY_p` | Target | Baseline identity |
| --- | --- | --- |
| `1` | Price-weighted value added | `Y_s * P_s = P0_s * Y0_s` |
| `2` | Real value added | `Y_s = Y0_s` |
| Other | Gross output | `Q_s = Q0_s` |

For `lTargetY_p = 1`, the price-weighted target must be `P0_s * Y0_s = FCgva_s`.

The corresponding helper routines use the same convention:

```math
Y_s
  =
  \frac{P0_s \cdot Y0_s \cdot \exp(exo_s)}
       {P_s}
```

and:

```math
exo_s
  =
  \log
  \left(
    \frac{Y_s \cdot P_s}
         {P0_s \cdot Y0_s}
  \right)
```

At baseline, this gives `exo_s = 0`.

---

## 8. Code Locations and Run-Path Hooks

| File | Role |
| --- | --- |
| `RunSimulations.m` | Run orchestrator that selects workbook paths/scenarios and invokes Dynare per run. |
| `Functions/Miscellaneous/ModelSetup/change_mod_file.m` | Rewrites compile-time macro switches (`YEndogenous`, `BaselineScenario`, sector/region structure, etc.) before each compile. |
| `Functions/steadystate_model.m` | Baseline wrapper: pass 1 with `lCalibration_p = 1` (two calls), then pass 2 with `lCalibration_p = 0` and BK check. |
| `DGE_Model_steadystate.m` | Dispatcher for `calibrate`/`fullSS`/`hybrid` branches and parameter write-back to `M_.params`. |
| `Functions/SteadyState/setupInitialState/compute_expenditure_assignments.m` | Builds gross-output, intermediate-use, wage, trade, and emission expenditure targets. |
| `Functions/SteadyState/setupInitialState/compute_pf_parameters.m` | Computes `FCgva_s`, sets `Y_s = FCgva_s / P_s`, and stores `Y0_s`. |
| `Functions/SteadyState/computeCapital/compute_exogenous_y_production.m` | Applies the `P0_s * Y0_s` target when output is exogenous. |
| `Functions/SteadyState/compute_production_factors_and_output.m` | Reconstructs `exo_s` from the same target. |
| `ModFiles/Equations/productivity_damages.mod` | Uses `P0_s_r_p * Y0_s_r_p` in the static TFP equation for `YTarget=1`. |
| `ModFiles/DGE_Model_Parameters.mod` | Provides the default `Y0_s_r_p` parameter. |

---

## 9. Baseline Checks

A clean calibration should satisfy these identities sector by sector:

```math
P_s \cdot Y_s = FCgva_s
```

```math
P0_s \cdot Y0_s = FCgva_s
```

```math
W_s \cdot N_s \cdot LF_r \cdot (1 + \tau NF_s) = WAexp_s
```

```math
P_Q \cdot Q_s
  =
  P_s \cdot Y_s
  + P_I \cdot Q_I
  + emDirect_s
```

The fastest diagnostic for TFP residuals is:

```math
Y_s \cdot P_s - P0_s \cdot Y0_s
```

At the calibrated steady state, this should be zero up to numerical precision.

---

## 10. Backward Compatibility

If `PE = 0`, then:

```math
emDirect_s = 0
```

and:

```math
FCgva_s = QEXP_s - QIEXP_s
```

In that special case, the old share-based normalization and the corrected `P0_s * Y0_s` normalization coincide. The correction therefore preserves zero-emission-price calibrations while making positive-emission-price calibrations internally consistent.

---

## 11. Baseline GVA Path Construction (Workbook)

The baseline time path for GVA composition is now constructed directly in the calibration workbook (`Baseline_Input` sheet) as a formula-driven interpolation between explicit anchor years.

### 11.1 Block and Year Layout

- Year headers: row `237`, columns `C:AB` (`2025` to `2050`).
- Share rows: `C242:AB246` for the five model activities:
  - row `242`: Primary
  - row `243`: Fossil
  - row `244`: Renewables
  - row `245`: Secondary
  - row `246`: Tertiary

### 11.2 Anchors

- `2025` (`C` column): baseline share formula from IO data.
- `2030` (`H` column): explicit target value.
- `2050` (`AB` column): explicit long-run target value.

For each row `r \in {242,243,244,245,246}`:

```math
\mathrm{Share}_{r,2030} = H_r, \qquad
\mathrm{Share}_{r,2050} = AB_r
```

### 11.3 Interpolation Rules

For `2026-2029` (columns `D:G`), interpolate linearly between 2025 and 2030:

```math
\mathrm{Share}_{r,t}
=
\mathrm{Share}_{r,2025}
+
\left(\mathrm{Share}_{r,2030}-\mathrm{Share}_{r,2025}\right)
\frac{t-2025}{2030-2025}
```

For `2031-2049` (columns `I:AA`), interpolate linearly between 2030 and 2050:

```math
\mathrm{Share}_{r,t}
=
\mathrm{Share}_{r,2030}
+
\left(\mathrm{Share}_{r,2050}-\mathrm{Share}_{r,2030}\right)
\frac{t-2030}{2050-2030}
```

In-sheet formula form (example row `242`):

- `D242:G242`:

```excel
=C242+($H242-C242)*(D$237-2025)/(2030-2025)
```

- `I242:AA242`:

```excel
=$H242+($AB242-$H242)*(I$237-2030)/(2050-2030)
```

The same structure is used for rows `243:246`.

### 11.4 Share-Adding-Up Condition

The identity check row (`247`) remains:

```excel
=SUM(C242:C246)
```

and copied across years through column `AB`. This enforces that sector shares add to 1 in each year up to rounding.

### 11.5 Link to Model GVA Levels

Given total GDP value in the model numeraire, `GDP_t` (row `240`), each activity's price-weighted GVA path is:

```math
GVA_{r,t}^{value} = \text{Share}_{r,t} \cdot GDP_t
```

These annual share inputs provide the time profile used to generate baseline sectoral value-added trajectories before model solution and scenario shocks.

---

## 12. Active Calibration vs. Code Defaults (5-Sector, 1-Region)

`ModFiles/DGE_Model_Parameters.mod` ships hard-coded default parameter
values, but the active 5-sector/1-region calibration workbook
(`ExcelFiles/ModelCalibration5Sectorsand1Regions.xlsx`, `Structural
Parameters` sheet) overrides several of them materially. Because Dynare reads
whichever workbook `RunSimulations.m` points at, **the workbook values, not
the `.mod` file defaults, govern the currently compiled model.** This
distinction matters most for the external-sector closure parameters, where
the two differ by an order of magnitude:

| Parameter | Code default (`DGE_Model_Parameters.mod`) | Active workbook override | Direction |
| --- | ---: | ---: | --- |
| `beta_p` | 0.95 | 0.97 | More patient households |
| `deltaB_p` | 0.05 | 0.05 | Same |
| `phiB_p` | 10.0 | 0.1 | Much weaker debt-elastic risk premium |
| `phiadjB_p` | 1.0 | 0.1 | Lower quadratic external-adjustment cost |
| `sigmaL_p` | 0.5 | 1.0 | Lower labour-supply (Frisch) elasticity |
| `sigmaC_p` | 1.0 | 1.0 | Same |
| `etaQ_p` | 1.04 | 0.6 | Lower substitution across sector composites |
| `etaF_p` | 1.1 | 0.6 | Lower substitution between domestic and imported goods |
| `etaX_p` | 0.61 | 0.6 | Nearly unchanged |

**Implication for interpreting transition dynamics:** with `phiB_p` and
`phiadjB_p` two orders of magnitude below the code defaults, external-balance
adjustment in the active calibration is dominated by the workbook overrides,
not the `.mod` file's built-in values — the debt-elastic external finance
premium (§ resource-constraint / rest-of-world equations) is far weaker than
a reader of `DGE_Model_Parameters.mod` alone would assume, and trade
reallocation is stickier (lower `etaQ_p`, `etaF_p`) than the code defaults
imply.

**Before citing any calibration parameter in a report:** confirm which
workbook paths are active in the run configuration (`RunSimulations.m`
sets `sWorkbookCalibration`, `sWorkbookBaseline`, and `sWorkbookScenarios`
from the selected sector/region setup), since defaults and overrides can
silently diverge as shown above. Recommended sensitivity ranges for
follow-up checks: `phiB_p ∈
[0.05, 0.1, 0.5, 1.0]`, `phiadjB_p ∈ [0.05, 0.1, 0.5]`. See
[dev/model_consistency_and_calibration_findings_2026-07-14.md](../dev/model_consistency_and_calibration_findings_2026-07-14.md)
for the full theory-consistency review this table was drawn from (resource
constraint, external finance premium, and exchange-rate closure checks).
