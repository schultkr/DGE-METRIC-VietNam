# Model Consistency and Calibration Findings (2026-07-14)

## Scope

- Verified economic-theory consistency for:
  - Regional resource constraint.
  - External finance premium and foreign-asset closure.
  - Exchange-rate variable definition used by the model.
- Investigated calibration values for the 5-sector, 1-region workbook family.

## Files Reviewed

- `ModFiles/Equations/resource_constraints.mod`
- `ModFiles/Equations/households.mod`
- `ModFiles/Equations/regional_identities_demographics.mod`
- `ModFiles/Equations/rest_of_world.mod`
- `ModFiles/Equations/government.mod`
- `ModFiles/DGE_Model_Parameters.mod`
- `ExcelFiles/ModelCalibration5Sectorsand1Regions.xlsx` (sheets: `Start`, `Structural Parameters`)

## Theory Consistency Findings

### 1) Resource Constraint

- Implemented identity (regional):
  - `Q_reg = P_reg*(G + I_G + C + I + IH*PH/P) + I_PV + Q_I + NX + sum(NX_reg_regm)`.
- Interpretation is coherent in this model because:
  - `Q_reg` is nominal gross output (value aggregation of subsector output).
  - `Q_I_reg` is nominal intermediate use.
  - `NX_reg = X_reg * P_Q_reg - M_reg`.
- Conclusion: consistent with gross-output accounting in multi-sector open-economy models.

### 2) External Finance Premium

- The foreign-bond Euler condition and NFA law of motion use a debt-elastic premium term:
  - `exp(-phiB * external_position_gap / Y)`
  - plus a quadratic adjustment-cost term with `phiadjB`.
- This structure is standard for stationarity in small-open-economy DSGE settings.
- Conclusion: specification is theoretically reasonable.

### 3) Exchange Rate Definition in This Model

- Exchange-rate variable is `s_reg` (declared as change in exchange rate to ROW).
- The model uses a hybrid closure equation:
  - When `exo_lNXTarget = 0`, `s_reg` follows AR(1).
  - When `exo_lNXTarget = 1` (baseline mode), the same equation enforces the NX/GDP target and `s_reg` becomes the balancing variable.
- `s_reg` enters external returns/debt service blocks (household and government equations).
- Conclusion: `s_reg` is an external-balance closure/valuation factor, not a full UIP-style nominal exchange-rate block.

## Calibration Investigation (5 Sectors, 1 Region)

## Workbook Mapping Note

- No explicit `XFL` label was found in repository files.
- Relevant workbook names in this repository are:
  - `ExcelFiles/ModelCalibration5Sectorsand1Regions.xlsx` (active calibration input)
  - `ExcelFiles/Archive/ModelSimulationandCalibration5Sectorsand1Regions.xlsx` (archived combined workbook variants)

### A) Key values from `Start` sheet (selected)

- `Y0_p = 5`
- `N0_1_p = 0.15`
- `BG0_1_p = 0.3`
- `P0_1_p = 0`
- `PE0_1_p = 0`
- `E0_NOETS_1_p = 0.22`
- `E0_1_p = 0.78`
- `sH_1_p = 0.05`
- `PoP0_1_p = 1`
- `LF0_1_p = 0.68`
- `H0_1_p = 25`

Sector-level shares (region 1):

- Value-added shares `phiY0_{1..5,1}`:
  - `0.0438490, 0.0186175, 0.0033233, 0.1124221, 0.1642732`
- Employment shares `phiN0_{1..5,1}`:
  - `0.1842194, 0.0290014, 0.0033652, 0.3557479, 0.4276661`
- Public-investment shares `phiG_{1..5,1}`:
  - `0.48, 0.50, 0.01, 0.08, 0.30`

### B) Key values from `Structural Parameters` sheet (selected)

Macro and trade:

- `beta_p = 0.97`
- `deltaB_p = 0.05`
- `phiB_p = 0.1`
- `phiadjB_p = 0.1`
- `sigmaL_p = 1`
- `sigmaC_p = 1`
- `etaQ_p = 0.6`
- `etaF_p = 0.6`
- `etaX_p = 0.6`

Taxes (region 1):

- `tauC_1_p = 0.07`
- `tauNH_1_p = 0`
- `tauKH_1_p = 0`
- `tauKF_{1..5,1} = 0`
- `tauNF_{1..5,1} = 0`

Elasticities and cost shares (examples):

- `etaQA_2_p = 5` (other `etaQA` mostly `1`)
- `etaQ_{1..5,p} = 2`
- `etaI_{1..5,p} = 1`
- `etaIA_{1..5,p} = 0.1`
- Intermediate cost shares `phiQI_{1..5,1}`:
  - `0.0505417, 0.0189709, 0.0026778, 0.4772158, 0.1081086`
- Export shares `phiX_{1..5,1}`:
  - `0.0069606, 0.0040, 0.0001, 0.2620895, 0.0336509`

## Calibration Implications for the External Finance Premium

- In-code defaults (`ModFiles/DGE_Model_Parameters.mod`) include much stronger external-friction values (`phiB_p = 10`, `phiadjB_p = 1`).
- The active workbook overrides are materially lower (`phiB_p = 0.1`, `phiadjB_p = 0.1`).
- Practical implication: current 5S1R calibration implies a much weaker debt-elastic premium than raw code defaults, reducing risk of overly aggressive external-adjustment dynamics.

### Override-vs-default comparison (active workbook vs code defaults)

| Parameter | Code default (`ModFiles/DGE_Model_Parameters.mod`) | Active workbook (`Structural Parameters`) | Direction |
|---|---:|---:|---|
| `beta_p` | 0.95 | 0.97 | More patient households |
| `deltaB_p` | 0.05 | 0.05 | Same |
| `phiB_p` | 10.0 | 0.1 | Much weaker debt-elastic premium |
| `phiadjB_p` | 1.0 | 0.1 | Lower quadratic external adjustment cost |
| `sigmaL_p` | 0.5 | 1.0 | Lower labour-supply elasticity |
| `sigmaC_p` | 1.0 | 1.0 | Same |
| `etaQ_p` | 1.04 | 0.6 | Lower substitution across sector composites |
| `etaF_p` | 1.1 | 0.6 | Lower substitution between domestic and imports |
| `etaX_p` | 0.61 | 0.6 | Nearly same |

Interpretation:

- The workbook settings move the model away from very strong external stabilization (`phiB_p`, `phiadjB_p`) and toward stickier trade reallocation (`etaF_p`, `etaQ_p` lower than defaults).
- Since `phiB_p` differs by two orders of magnitude (10 vs 0.1), external-balance transition dynamics are likely dominated by workbook overrides rather than code defaults.

## Recommended Follow-up Checks

- Confirm which workbook is loaded in the exact run you care about (`DGE_Model.mod` auto-builds workbook names from sector/region macros).
- Run sensitivity around:
  - `phiB_p` in `[0.05, 0.1, 0.5, 1.0]`
  - `phiadjB_p` in `[0.05, 0.1, 0.5]`
- Validate accounting identities after any calibration edit using the workbook checks in `ExcelFiles/README.md`.
