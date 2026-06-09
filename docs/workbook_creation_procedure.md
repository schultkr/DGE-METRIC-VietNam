# Workbook Creation Procedure

This runbook explains how to create and refresh the workbook set used by DGE-METRIC:

- allSimulation workbook (legacy combined workbook)
- Calibration workbook
- Baseline workbook

The instructions assume the current project setup (5 sectors, 1 region) and that MATLAB is started from the repository root.

## Prerequisites

- MATLAB (R2020a or newer recommended)
- Microsoft Excel on Windows (required for COM-based workbook scripts)
- Repository opened at root folder

Initialize MATLAB paths first:

```matlab
setup_paths
```

## Workflow A (recommended in this repository)

This is the most reliable workflow when you want all workbook types aligned with current split-workbook usage.

### Step 1. Create the legacy allSimulation workbook

```matlab
run('Functions/Miscellaneous/Excel/create_raw_excel_input_file.m')
```

Expected output workbook:

- `ExcelFiles/ModelSimulationandCalibration<S>Sectorsand<R>Regions.xlsx`

For the standard setup this is typically:

- `ExcelFiles/ModelSimulationandCalibration5Sectorsand1Regions.xlsx`

### Step 2. Split into Calibration, Baseline, and Scenarios workbooks

```matlab
run('Functions/Miscellaneous/Excel/migrate_to_split_workbooks.m')
```

Expected output workbooks:

- `ExcelFiles/ModelCalibration5Sectorsand1Regions.xlsx`
- `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx`
- `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx`

### Step 3. Populate and propagate calibration data

Fill user-edited calibration sheets first:

- `IO_Data`
- `Trade_Flows`

Then run:

```matlab
run('Functions/Miscellaneous/Excel/update_data_excel.m')
```

This propagates data through named ranges and updates parameter sheets used by the model.

### Step 4. Refresh runnable Baseline sheet

After editing baseline assumptions in the split baseline workbook (`Baseline_Input` and helpers), run:

```matlab
run('scripts/maintenance/UpdateBaselineSheet.m')
```

This rebuilds the values-only `Baseline` sheet used by MATLAB/Dynare runs.

## Workflow B (direct split workbook generation)

Use this only if you do not need to generate the combined allSimulation workbook.

### Step 1. Create Calibration workbook directly

```matlab
run('Functions/Miscellaneous/Excel/create_calibration_excel_file.m')
```

### Step 2. Create Baseline workbook directly

```matlab
run('Functions/Miscellaneous/Excel/create_baseline_excel_file.m')
```

### Step 3. Run propagation and baseline refresh

```matlab
run('Functions/Miscellaneous/Excel/update_data_excel.m')
run('scripts/maintenance/UpdateBaselineSheet.m')
```

## Validation checklist

After running the procedure, verify:

1. The three split workbooks exist in `ExcelFiles/`.
2. `ModelBaseline5Sectorsand1Regions.xlsx` contains a non-empty `Baseline` sheet.
3. No workbook is left open/locked in Excel during script execution.
4. `update_data_excel.m` completes without unresolved warnings related to missing named ranges.

## Common issues

- Script fails to open workbook:
  Excel file is open in another Excel session. Close it and rerun.
- Missing named ranges during propagation:
  Ensure `Data` sheet definitions exist and `create_raw_excel_input_file.m` or migration step was completed.
- Baseline refresh fails:
  Confirm `ModelBaseline5Sectorsand1Regions.xlsx` exists and has required helper sheets (`Baseline_Input`, `Baseline_calc`, `Baseline_Implied` or legacy source available for bootstrap).

## Notes

- The repository's operational workflow uses split workbooks (`ModelCalibration`, `ModelBaseline`, `ModelScenarios`) for runs.
- The allSimulation workbook is kept mainly for compatibility and migration-oriented workflows.