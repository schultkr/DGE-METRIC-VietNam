# Model

## Model structure in plain language

DGE-METRIC is a **5-sector, 1-region dynamic general equilibrium model** calibrated to Vietnam. It simulates the economy over a 25-year deterministic transition path (2026–2050) using forward-looking rational expectations solved by Dynare.

### Five sectors

| # | Label | Economic role |
|---|---|---|
| 1 | Non-energy aggregate | General production; residual macro sector |
| 2 | Fossil energy | Coal, gas, oil generation; declining under NZ |
| 3 | Renewable energy | Solar, wind, hydro, storage; expanding under all transition scenarios |
| 4 | Industry | Manufacturing; major energy user, EE target sector |
| 5 | Services | Commercial and public services; secondary energy user |

Capital and labor move across sectors in response to relative prices. Energy sectors supply intermediate inputs to sectors 1, 4, and 5.

### Key model extensions beyond a standard DGE

| Feature | What it adds | Key variables |
|---|---|---|
| Input-output structure | Sectors buy intermediate goods from each other | `Q^I_{s,k}` intermediate demand matrix |
| Energy as intermediate input | Energy demand is derived from production decisions | `Q_A_{s,1}`, `Q_PV_1` |
| Emission coefficients | Each fossil fuel unit generates CO₂ | `e_s` emission intensity |
| Emissions trading system (ETS) | Carbon permit market with endogenous price | `E_ETS_1`, `P_E`, `xi_s` coverage rate |
| Energy efficiency shocks | Reduces energy per unit of output over time | `exo_AI_s` |
| Renewable capital accumulation | PV and grid investment paths | `exo_PVEff_1`, `exo_GA_s` |
| Climate damages | Temperature shocks reduce capital and housing | `D^K_{s,t}`, `D^H_t` |
| Green finance channels | Lower cost of capital for energy investment | `exo_r_G_s`, `exo_r_FDI_s`, `exo_P_K_s` |
| Housing as durable capital | Household wealth and climate exposure | `H_{t+1}`, `I^H_t` |

### Agent diagram

![Model Overview](figures/ModelDiagram.jpg)

### Calibration

The model is calibrated to a Vietnam 2026 baseline using GSO IO tables, EVN annual reports, IEA WEO 2025, and EDGAR 2024 emissions data. See [Calibration](calibration.md) and [Data sources](data_sources.md).

---

## Technical implementation

The repository implements a deterministic multi-sector DGE workflow that combines:

- Dynare model specification and solving.
- MATLAB steady-state and transition scripts.
- Excel-based inputs for calibration and scenario paths.

## Core Files

- `DGE_Model.mod`: central Dynare entry point.
- `ModFiles/DGE_Model_Declaration.mod`: variable and parameter declarations.
- `ModFiles/DGE_Model_Equations.mod`: equation blocks for the model.
- `ModFiles/DGE_Model_Parameters.mod`: parameter loading and assignment layer.
- `DGE_Model_steadystate.m`: steady-state routine called from the model flow.
- `Functions/steadystate_model.m`: scenario-aware steady-state setup.
- `Functions/simulation_model_refactored.m`: deterministic simulation pipeline.

## Runtime Flow

1. `RunSimulations.m` selects scenarios and writes switches into the model setup.
2. Dynare preprocesses and executes `DGE_Model.mod`.
3. `DGE_Model.mod` includes declaration/equation/parameter modules from `ModFiles/`.
4. `steadystate_model` computes or loads baseline steady-state objects.
5. `simulation_model_refactored` runs perfect-foresight baseline/scenario transitions.
6. Results are written into `structScenarioResults*.mat`.

## Model Configuration Highlights

Current defaults from `DGE_Model.mod` include:

- 5-subsector structure (`Subsecend = [1, 3, 4, 5]`).
- 1 region.
- Cap-and-trade switch enabled by default in the mod template.
- Baseline/scenario workbooks resolved from `ExcelFiles/ModelCalibration*`, `ModelBaseline*`, and `ModelScenarios*` naming conventions.

## Generated Artifacts

Typical outputs after runs:

- `structScenarioResults.mat` (and sensitivity variants).
- Dynare-generated files/folders under `+DGE_Model/` and `DGE_Model/Output/`.
- Excel output workbooks in `ExcelFiles/Output/`.
