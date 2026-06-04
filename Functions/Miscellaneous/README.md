# Miscellaneous

General MATLAB utilities used by the model workflow. The folder is split by purpose so scripts can be found by role instead of living in one flat bucket.

## Folder Layout
- `Excel/`: workbook generators, sheet-definition scripts, Excel update utilities, and Excel address helpers.
- `Simulation/`: exogenous-series loading, perfect-foresight path setup, growth targets, and baseline final-state storage.
- `ModelSetup/`: Dynare macroprocessor edits and auxiliary-expression index setup.
- `Diagnostics/`: solver diagnostics and structure/residual comparison helpers.
- `Plotting/`: callbacks and small plotting helpers used by diagnostic figures.

Use `addpath(genpath(fullfile(pwd(), 'Functions')))` from the repository root before calling these utilities directly.

## Key Relationships
- `Excel/create_raw_excel_input_file.m` generates Excel input templates and runs `Excel/define_sheets_input_file.m`.
- `Excel/define_sheets_input_file.m` constructs sheet layouts and calls `Excel/add_sub_sheet.m` and `Excel/define_sheets_input_file_help1.m`.
- `Excel/update_data_excel.m` syncs calibration inputs from `IO_Data` and `Trade_Flows` into Data named ranges, then propagates those values to parameter sheets. See `ExcelFiles/README.md` for the full workflow.
- `Excel/update_baseline_excel.m` refreshes the split `ModelBaseline` workbook by recalculating `Baseline_Implied` and copying a values-only hardcoded sheet to `Baseline`. If `Baseline_Implied` is missing, it can bootstrap the split workbook from the legacy combined workbook. `scripts/maintenance/UpdateBaselineSheet.m` is the entry point.
- `Simulation/load_exogenous.m` and `Simulation/load_growth_rates.m` are called by `simulation_model_refactored.m`.
- `Simulation/audit_baseline_gdp_growth.m` writes post-run CSV checks comparing Excel `gY_*` targets with simulated real and price-weighted value-added growth in the model numeraire.
- `ModelSetup/change_mod_file.m` updates macroprocessor settings before model runs.
- `ModelSetup/define_auxiliary_expressions_looped.m` is called by `simulation_model_refactored.m` and generated Dynare drivers.

## Naming Notes
Function and script names were kept stable in this cleanup to avoid breaking MATLAB callers. If you want to rename the files next, update these callers at the same time:

| Current name | Suggested name | Callers found |
| --- | --- | --- |
| `compareStructs.m` | `compare_structs.m` | none |
| `define_sheets_input_file_help1.m` | `build_input_sheet_categories.m` | `Excel/define_sheets_input_file.m`, `Excel/define_sheets_calibration.m` |
| `depict_invadjcostuntitled4.m` | `plot_investment_adjustment_cost.m` | none |
| `diagnostics_crash.m` | `inspect_pf_solver_crash.m` | docs only |
| `filter_variables.m` | `filter_diagnostic_variables.m` | `Diagnostics/diagnostics_crash.m` |
| `update_plot.m` | `update_diagnostic_plot.m` | `Diagnostics/diagnostics_crash.m`, `Plotting/update_plot_mapped.m` |
| `update_plot_mapped.m` | `update_mapped_diagnostic_plot.m` | `Plotting/filter_variables.m` |

Several files are scripts rather than functions (`create_*`, `define_sheets_*`, `define_aux_expressions.m`, `define_auxiliary_expressions_looped.m`, `diagnostics_crash.m`, `migrate_to_split_workbooks.m`, and `update_data_excel.m`). Rename those more carefully because scripts rely on workspace variables.
