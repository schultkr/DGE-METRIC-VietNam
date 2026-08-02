# Project State Summary

Last updated: 2026-05-25

## Purpose

This repository contains a MATLAB and Dynare implementation of the DGE-METRIC model for macroeconomic, sectoral, energy-transition, and carbon-market scenario analysis.

The active working setup is a Vietnam-focused 5-sector, 1-region calibration.

## Current Architecture

- `DGE_Model.mod`: canonical Dynare entry point.
- `DGE_Model_steadystate.m`: MATLAB steady-state dispatcher used by Dynare.
- `RunSimulations.m`: main scenario loop.
- `setup_paths.m`: central path setup for MATLAB and Dynare.
- `ModFiles/`: hand-maintained Dynare model blocks.
- `Functions/`: MATLAB source code for calibration, steady state, simulation helpers, Excel I/O, diagnostics, and plotting helpers.
- `ExcelFiles/`: calibration and scenario workbooks.
- `scripts/`: analysis, reporting, and maintenance scripts.
- `docs/`: project and model documentation.

## Generated Artifacts

Dynare-generated folders and local simulation outputs are ignored by Git:

- `+DGE_Model/`
- `DGE_Model/`
- `+DGE_CRED_Model/`
- `DGE_CRED_Model/`
- `ExcelFiles/Output/`

These can be regenerated from `DGE_Model.mod`, `ModFiles/`, MATLAB source, and Excel inputs.

## Execution Workflow

1. Open MATLAB in the repository root.
2. Run `setup_paths`.
3. Edit scenario selections in `RunSimulations.m`.
4. Run `RunSimulations`.
5. Inspect generated CSV outputs in `ExcelFiles/Output/`.
6. Use scripts in `scripts/analysis/` and `scripts/reporting/` for checks and figures.

## Cleanup Status

- The former `Functions/Miscallenous/` folder has been renamed and organized as `Functions/Miscellaneous/`.
- Root analysis/reporting scripts have been moved under `scripts/`.
- Dynare generated artifacts are excluded by `.gitignore`.
- Documentation has been aligned with the current `DGE_Model.mod` workflow.

## Remaining Follow-Up

- Decide whether large exported figures in `Figures/` should remain tracked or be treated as generated outputs.
- Consider moving historical notes such as `Summary_of_Changes.md` into `docs/archive/`.
- Consider adding a lightweight MATLAB health-check script for path, Dynare, workbook, and output availability.
