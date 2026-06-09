# Model

## Purpose

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
