# Excel Rebuild User Guide (Step by Step)

This guide gives a single, practical procedure to rebuild Excel workbooks in this repository.

## 1. Goal

You can run one of two workflows:

- Template-only rebuild
  - Creates fresh workbook templates:
    - `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx`
    - `ExcelFiles/ModelCalibration5Sectorsand1Regions.xlsx`
    - `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx`
- Full processed-input parity check
  - Verifies whether this repo has the same processed ExpertClean inputs used in the reference workflow.

## 2. Prerequisites

1. Use Windows with Microsoft Excel installed (the scripts use Excel COM automation).
2. Open MATLAB in the repository root folder.
3. Make sure no target workbook is open in Excel before running scripts.

## 3. Open MATLAB in the repository root

In MATLAB, confirm your current folder is this repository root.

If needed, change folder to the repo root, then run:

```matlab
setup_paths;
```

Expected outcome:
- MATLAB paths for `Functions` and `ModFiles` are available.

## 4. Validate template-only prerequisites

Run:

```matlab
ValidateExcelRebuildPrereqs('template-only');
```

Expected outcome:
- Summary shows `Result : PASS`.

If it fails:
1. Read the `Missing paths` list printed in MATLAB.
2. Restore missing files in this repository.
3. Run the same command again until it passes.

## 5. Rebuild all workbook templates

Run:

```matlab
run('scripts/maintenance/CreateModelWorkbooks.m');
```

Expected outcome:
- MATLAB prints `CreateModelWorkbooks complete.`
- These files exist in `ExcelFiles/`:
  - `ModelBaseline5Sectorsand1Regions.xlsx`
  - `ModelCalibration5Sectorsand1Regions.xlsx`
  - `ModelScenarios5Sectorsand1Regions.xlsx`

## 6. Optional: validate full processed-input parity

If you want parity with the processed ExpertClean input workflow, run:

```matlab
ValidateExcelRebuildPrereqs('full-reference');
```

Interpretation:
- `Result : PASS`
  - You can reproduce the processed-input parity workflow in this repo.
- `Result : FAIL`
  - Some required assets are missing.

Use this checklist to see exactly what is missing:
- `scripts/maintenance/REBUILD_GAP_CHECKLIST.md`

## 7. Processed-input policy (current project decision)

Under the current policy, only processed ExpertClean files are required for full-reference parity checks:

- `ExcelFiles/Input/ExpertClean/Directive10_RTS_EE.csv`
- `ExcelFiles/Input/ExpertClean/EE_PDP8_reference.csv`
- `ExcelFiles/Input/ExpertClean/IO_manifest.csv`
- `ExcelFiles/Input/ExpertClean/PDP8_PV_EV_BESS.csv`
- `ExcelFiles/Input/ExpertClean/RTS_PDP8_revised_reference.csv`

Raw expert workbooks and path-definition workbooks are optional under this policy.

## 8. Quick troubleshooting

1. Excel automation errors
   - Close all Excel windows and rerun.
2. File locked / cannot overwrite
   - Close the workbook in Excel and rerun.
3. Missing prerequisite files
   - Run the validator again and restore only listed missing paths.
4. Wrong working directory
   - Ensure MATLAB current folder is repository root before running commands.

## 9. Minimal command block

Use this exact sequence for normal rebuilds:

```matlab
setup_paths;
ValidateExcelRebuildPrereqs('template-only');
run('scripts/maintenance/CreateModelWorkbooks.m');
ValidateExcelRebuildPrereqs('full-reference');
```
