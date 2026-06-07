# Excel Rebuild Gap Checklist (vs DGE-METRIC)

Date: 2026-06-07

Scope:
- Excel rebuild pipeline only (calibration, baseline, simulation/scenario workbook generation and pre-population support).

Reference repository:
- `C:\Users\schul\Documents\GitHub\DGE-METRIC`

Current repository:
- `C:\Users\schul\Documents\GitHub\DGE-METRIC-VietNam`

## Summary

- Template-only rebuild scripts are present.
- Full-reference maintenance helpers and processed ExpertClean inputs are incomplete.

## 1) Workbook builders and core helpers

Present in this repository:
- `scripts/maintenance/CreateModelWorkbooks.m`
- `Functions/Miscellaneous/Excel/create_baseline_excel_file.m`
- `Functions/Miscellaneous/Excel/create_calibration_excel_file.m`
- `Functions/Miscellaneous/Excel/create_scenarios_excel_file.m`
- `Functions/Miscellaneous/Excel/define_sheets_baseline.m`
- `Functions/Miscellaneous/Excel/define_sheets_calibration.m`
- `Functions/Miscellaneous/Excel/define_sheets_scenarios.m`
- `Functions/Miscellaneous/Excel/get_excel_column.m`
- `Functions/Miscellaneous/Excel/add_sub_sheet.m`
- `Functions/Miscellaneous/Excel/define_sheets_input_file_help1.m`

## 2) Maintenance scripts for full-reference pre-population

Missing in this repository (present in reference):
- `scripts/maintenance/UpdateBaselineSheet.m`
- `scripts/maintenance/UpdateNZSheet.m`
- `scripts/maintenance/CreateBaselineFromUserInputFile.m`
- `scripts/maintenance/CreateBaselinePathDefinitionTemplate.m`
- `scripts/maintenance/CreateEEScenariosFromExpertInputs.m`
- `scripts/maintenance/PrepareExpertInputsForSheetCreation.m`
- `scripts/maintenance/CreateGreenFinanceScenarios.m`
- `scripts/maintenance/build_user_inputs_sheet.py`

## 3) Required processed Expert inputs for full-reference workflow

Missing in this repository (present in reference):
- `ExcelFiles/Input/ExpertClean/Directive10_RTS_EE.csv`
- `ExcelFiles/Input/ExpertClean/EE_PDP8_reference.csv`
- `ExcelFiles/Input/ExpertClean/IO_manifest.csv`
- `ExcelFiles/Input/ExpertClean/PDP8_PV_EV_BESS.csv`
- `ExcelFiles/Input/ExpertClean/RTS_PDP8_revised_reference.csv`

## 3b) Optional raw/template seed files (not required under processed-only policy)

Optional in this repository (present in reference):
- `ExcelFiles/ScenarioPathDefinition.xlsx`
- `ExcelFiles/ScenarioPathDefinition_PV_EE_Translated.xlsx`
- `ExcelFiles/Vietnam_EnergyExpert_ScenarioInputs.xlsx`
- `ExcelFiles/Vietnam_EnergyExpert_ScenarioInputs_harmonized.xlsx`

## 4) Current workbook files in this repository

Present:
- `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx`

Not currently committed:
- `ExcelFiles/ModelCalibration5Sectorsand1Regions.xlsx`
- `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx`

## Operational conclusion

- You can regenerate the three workbook templates from code in this repository.
- You cannot reproduce the full pre-populated reference Excel pipeline without adding the missing scripts and seed inputs listed above.