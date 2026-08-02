# Analysis Scripts

Exploratory model checks and post-processing scripts.

## Current Files

- `analyze_end_shares.m`: inspects final energy-demand and related output shares from simulation results.
- `analyze_va_shares.m`: summarizes value-added shares after a model run.
- `check_results.m`: quick consistency checks on saved simulation outputs.
- `compute_terminal_ss.m`: reconstructs or inspects terminal steady-state objects from a completed run.

These scripts are intended for ad hoc analysis after `RunSimulations.m` has produced the `.mat` outputs in the repository root.

`analyze_end_shares.m` also expects alternative baseline sheets to exist in `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx`. The historical helper that generated those sheets is no longer in `scripts/maintenance/`; an archived copy remains under `ExcelFiles/Archive/CreateBaselineModelSheets.m`.
