# DGE-METRIC Documentation

This page is the entry point for the repository documentation.

## Sections

- [Model](model.md): model architecture, main files, and execution flow.
- [Scenarios](scenario.md): scenario groups and baseline/scenario mechanics.
- [Calibration](calibration.md): calibration workbook generation and update workflow.
- [Running](running.md): practical run order and commands.

## Current Repository Map

Main top-level components in this version:

- `DGE_Model.mod`: Dynare model entry file.
- `RunSimulations.m`: batch scenario runner.
- `DGE_Model_steadystate.m`: steady-state function used by the model workflow.
- `setup_paths.m`: adds MATLAB/Dynare paths.
- `Functions/`: steady-state, simulation, model setup, and Excel helpers.
- `ModFiles/`: model declarations, equations, parameters, and LaTeX output includes.
- `ExcelFiles/`: calibration/baseline/scenario workbooks and output files.
- `scripts/maintenance/`: workbook maintenance scripts (currently includes `CreateBaselineFromPathDefinitionLite.m`).
- `Training/`: training assets and calibration resources.

## Important Notes

- The root README links an Excel rebuild guide at `scripts/maintenance/USER_GUIDE_EXCEL_REBUILD.md`, but this file is not present in the current repository state.
- Current scenario execution defaults are defined in `RunSimulations.m`.
- Current calibration workbook generation logic is in `Functions/Miscellaneous/Excel/create_calibration_excel_file.m`.
