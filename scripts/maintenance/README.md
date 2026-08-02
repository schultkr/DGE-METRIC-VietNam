# Maintenance Scripts

Small operational helpers for refreshing workbooks or maintaining the project.

For the full, ordered procedure to rebuild `ScenarioPathDefinition.xlsx` →
`ModelBaseline5Sectorsand1Regions.xlsx` → `ModelScenarios5Sectorsand1Regions.xlsx` from scratch
(including corruption diagnostics and known gaps), see
[docs/workbook_creation_procedure.md](../../docs/scenario_notes/workbook_creation_procedure.md). The per-script
summaries below are a reference, not a sequence.

## Current Files

- `update_baseline_sheet.m`: refreshes the values-only `Baseline` sheet from the split `ModelBaseline5Sectorsand1Regions.xlsx` workbook.
- `update_nz_sheet.m`: refreshes the `NZ` scenario sheet in the scenario workbook.
- `create_baseline_from_user_input_file.m`: builds a runnable baseline workbook from a user-input sheet.
- `create_baseline_share_candidates.m`: creates multiple runnable `Baseline_*` sheets with alternative fossil/renewable VA-share interpolation paths.
- `optimize_baseline_share_path.m`: runs a coarse-to-fine outer search over the fossil/renewable VA-share interpolation parameter and scores candidates by `max(abs(A_INV))`.
- `create_baseline_path_definition_template.m`: creates a template workbook for baseline path definitions.
- `create_scenario_path_definition_templates.m`: builds a combined path-definition workbook with Baseline plus exact-current EE, finance, and NZ scenario sheets.
- `update_scenario_sheets_from_path_definition.m`: copies the path-definition EE, finance, and NZ sheets back into the runnable scenario workbook.
- `create_ee_scenarios_from_expert_inputs.m`: generates EE scenario workbook inputs from expert-input files.
- `prepare_expert_inputs_for_sheet_creation.m`: normalizes expert workbook inputs into clean CSV files used by baseline/scenario builders.
- `create_green_finance_scenarios.m`: generates finance scenario workbook inputs.
- `build_user_inputs_sheet.py`: Python helper for constructing user-input workbook sheets.
- `run_sensitivity_analysis.m`: runs parameter sensitivity cases defined in code, applies overrides to the calibration workbook, executes `RunSimulations.m`, and archives each run's outputs into case-specific folders.

## Expert Input IO Structure (Clean Pipeline)

The sheet-creation flow now uses clean, format-free CSV files under `ExcelFiles/Input/ExpertClean/`.

### Input Normalization

Run:

- `run('scripts/maintenance/prepare_expert_inputs_for_sheet_creation.m')`

Outputs:

- `ExcelFiles/Input/ExpertClean/EE_PDP8_reference.csv`
- `ExcelFiles/Input/ExpertClean/Directive10_RTS_EE.csv`
- `ExcelFiles/Input/ExpertClean/PDP8_PV_EV_BESS.csv`
- `ExcelFiles/Input/ExpertClean/RTS_PDP8_revised_reference.csv`
- `ExcelFiles/Input/ExpertClean/IO_manifest.csv`

### Consumers

- `create_ee_scenarios_from_expert_inputs.m` reads `.../ExpertClean/<scenario>.csv` first, then falls back to workbook sheets only if needed.
- `create_baseline_from_user_input_file.m` refreshes `ExcelFiles/Output/RTS_split_assumptions_from_expert_email.csv` from `RTS_PDP8_revised_reference.csv` first, then falls back to workbook extraction only if needed.

This keeps the model-facing IO explicit and stable, while still preserving workbook fallback resilience.

The older `CreateBaselineModelSheets.m` workflow is no longer present in this folder. An archived copy still exists at `ExcelFiles/Archive/CreateBaselineModelSheets.m`, and `scripts/analysis/analyze_end_shares.m` still assumes that its baseline-variant sheets have already been created.

## Baseline VA-share candidates

To explore alternative paths that respect user-entered fossil and renewables value-added shares at the anchor years:

```matlab
run('scripts/maintenance/create_baseline_share_candidates.m')
```

`create_baseline_share_candidates.m` first refreshes the canonical `Baseline` sheet from `ScenarioPathDefinition.xlsx`, then writes candidate sheets into `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx`. By default it reads the `Input Scenario` sheet, falling back to `Baseline` when that sheet is not present. The default anchor years are `2030`, `2035`, `2040`, `2045`, and `2050`; the fossil and renewables shares in those years are taken directly from the input sheet. The candidate suffix `g050`, `g100`, etc. is the common piecewise power interpolation parameter (`tau^gamma`) used between every pair of anchors. Services/tertiary is the default residual subsector (`5`), so primary and secondary VA-share paths stay unchanged while services absorbs the fossil/renewable adjustment and total GVA growth remains anchored by the original aggregate path.

For the automated analytical search:

```matlab
run('scripts/maintenance/optimize_baseline_share_path.m')
```

The optimizer creates candidate sheets, runs an evaluation sweep, reads `ExcelFiles/Output/BaselineCandidateScores.csv`, and refines the gamma grid around the feasible candidate with the lowest `max(abs(A_INV))`. It writes the full trace to `ExcelFiles/Output/BaselineSharePathOptimization.csv`.

Important: candidate-sheet evaluation is a maintenance workflow. The standard model run path should be treated as the canonical Baseline workflow.

During maintenance sweeps, non-`Baseline` candidate sheets can warm-start from the user-defined `Baseline` solution by default when solving their own `Baseline` path. Candidate-baseline solves can also use a lighter solver configuration: `DGE_BASELINE_CANDIDATE_STEPS=4` and `DGE_BASELINE_CANDIDATE_MAXIT=8` unless overridden. Set `DGE_BASELINE_WARM_START` to `previous` to chain candidates from the preceding candidate, or `none` to disable candidate warm-starts.

Useful overrides:

```matlab
setenv('DGE_BASELINE_OPT_GAMMAS', '0.35,0.5,0.75,1,1.5,2,3')
setenv('DGE_BASELINE_OPT_ANCHOR_YEARS', '2030,2035,2040,2045,2050')
setenv('DGE_BASELINE_WARM_START', 'user')
setenv('DGE_BASELINE_CANDIDATE_STEPS', '4')
setenv('DGE_BASELINE_CANDIDATE_MAXIT', '8')
setenv('DGE_BASELINE_OPT_ROUNDS', '2')
setenv('DGE_BASELINE_OPT_POINTS', '5')
setenv('DGE_BASELINE_OPT_RESIDUAL_SUBSECTOR', '5')
setenv('DGE_BASELINE_GDP_TOL', '1e-6')
```

## Parameter Sensitivity Batch

To run parameter sweeps where values are set directly in a script and outputs
are stored in separate folders:

```matlab
run('scripts/maintenance/run_sensitivity_analysis.m')
```

How it works:

- Define cases in `run_sensitivity_analysis.m` (`name` + parameter override struct).
- For each case, the script resets `ModelCalibration5Sectorsand1Regions.xlsx`
	to a clean backup, applies overrides on `Start` / `Structural Parameters`,
	runs `RunSimulations.m`, and copies changed outputs to a case folder.
- Batch outputs are written under
	`ExcelFiles/Output/SensitivityRuns/Sensitivity_<timestamp>/`.
- Each case folder contains:
	- `AppliedOverrides.csv`
	- `ModelCalibration_used.xlsx`
	- `RunSimulations.log`
	- `ExcelOutput/*.csv` (changed simulation CSVs)
	- `WorkspaceOutput/structScenarioResults*.mat` (changed MAT results)

Tip: adjust `cfg.scenarioGroupsCsv` and `cfg.baselineSheetsCsv` in the script
to control which scenario groups and baseline sheets are evaluated.
