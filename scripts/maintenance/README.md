# Maintenance Scripts

Operational helpers for workbook regeneration and rebuild-readiness checks.

## Current Files

- `CreateModelWorkbooks.m`: creates `ModelBaseline`, `ModelCalibration`, and `ModelScenarios` workbook templates.
- `ValidateExcelRebuildPrereqs.m`: validates required files for either template-only rebuilds or full-reference parity checks.
- `REBUILD_GAP_CHECKLIST.md`: static comparison checklist against the reference repository (`DGE-METRIC`) for the Excel rebuild pipeline.

## Supported Workflow Modes

- **Template-only rebuild (supported in this repository)**
	- Generates blank/runnable workbook templates using in-repo sheet-definition scripts.
- **Full-reference parity rebuild (not fully present in this repository)**
	- Requires additional maintenance scripts and processed expert-input files (`ExcelFiles/Input/ExpertClean/*`) that exist in the reference repository.
	- Raw expert workbooks and scenario path-definition workbooks are treated as optional under this processed-only policy.

## Usage

Run from repository root:

```matlab
setup_paths;

% 1) Validate template-only prerequisites
ValidateExcelRebuildPrereqs('template-only');

% 2) Build baseline/calibration/scenario workbook templates
run('scripts/maintenance/CreateModelWorkbooks.m');

% 3) Optional: check parity with full reference workflow
ValidateExcelRebuildPrereqs('full-reference');
```

If `full-reference` mode reports missing files, use `REBUILD_GAP_CHECKLIST.md` as the transfer list.
