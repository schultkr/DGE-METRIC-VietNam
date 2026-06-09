# Calibration

## Calibration Inputs

The model calibration uses Excel workbooks in `ExcelFiles/`, with the current standard naming convention:

- `ModelCalibration5Sectorsand1Regions.xlsx`
- `ModelBaseline5Sectorsand1Regions.xlsx`
- `ModelScenarios5Sectorsand1Regions.xlsx`

## Main Calibration Builder

Primary builder script:

- `Functions/Miscellaneous/Excel/create_calibration_excel_file.m`

What it does:

1. Defines sectors/subsectors/regions and climate variable blocks.
2. Builds workbook structure using `define_sheets_calibration.m`.
3. Writes Data, Start, Structural Parameters, and Content sheets.
4. Optionally syncs selected sheet values from `Training/Day3_Calibration/` workbook copies.
5. Uses Excel COM automation and formula-fallback logic for locale differences.

## Data Propagation Script

Data synchronization script:

- `Functions/Miscellaneous/Excel/update_data_excel.m`

What it does:

1. Reads `IO_Data` content and updates Data-sheet named ranges.
2. Propagates named ranges into Start and Structural Parameters sheets.
3. Includes workbook lock checks and Excel session handling.

## Baseline Workbook Utilities

Current baseline-related workbook helpers:

- `Functions/Miscellaneous/Excel/update_baseline_excel.m`
- `Functions/Miscellaneous/Excel/create_baseline_model_sheets.m`
- `scripts/maintenance/CreateBaselineFromPathDefinitionLite.m`

These tools support rebuilding hardcoded baseline sheets from implied/formula-driven sheets and path-definition inputs.

## Platform Requirement

Excel workbook generation and updates rely on Excel ActiveX automation:

- Windows + Microsoft Excel are required for these scripts.
