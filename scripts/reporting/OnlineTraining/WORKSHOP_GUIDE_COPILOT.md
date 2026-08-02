# Online Training Workshop Guide (GitHub Copilot)

This guide helps participants build scenario-comparison plots similar to the OnlineTraining scripts in this folder, using GitHub Copilot as an assistant.

## 1) Learning Objective

By the end of the exercise, each participant (or group) should be able to:

- create one MATLAB comparison script for a chosen baseline and scenario set,
- generate one figure per variable where all scenarios are shown together relative to baseline,
- export figures and a compact summary table.

## 2) What Participants Should Produce

Minimum deliverables:

- one MATLAB driver script (copied from an existing OnlineTraining driver and edited),
- figure outputs in `Figures/ScenarioComparisons/OnlineTraining/<your_subfolder>/RelativeToBaseline/`,
- `comparison_summary_final_year.csv` in the same folder,
- a 3-4 sentence interpretation for one finance variable and one macro variable.

## 3) Starter Workflow (for participants)

1. Open one of the existing driver scripts in this folder.
2. Duplicate it and rename for your scenario group.
3. Edit:
   - `config.baselineName`
   - `config.baselineLabel`
   - `config.scenarioSpecs`
   - `config.plotSubfolder`
   - `config.plotSpecs`
4. Run the script in MATLAB.
5. Check missing-variable or missing-CSV warnings and adjust scenario names/variables.
6. Export and discuss the results.

## 4) Recommended Facilitation Flow (45-60 min)

- 0-10 min: Explain expected output and show one completed example.
- 10-25 min: Participants draft script edits with Copilot prompts.
- 25-40 min: Participants run scripts, fix errors, re-run.
- 40-60 min: Group interpretation and report-out.

## 5) Copilot Prompt Pattern (use in Chat)

Use this structure to keep Copilot focused:

- Context: what file you are editing and where outputs should go.
- Task: exactly what must change.
- Constraints: keep one figure per variable, all scenarios relative to baseline.
- Validation: ask Copilot to check for syntax/runtime pitfalls.

Example:

"In [scripts/reporting/OnlineTraining/compare_online_training_nz_variants_vs_nz.m](scripts/reporting/OnlineTraining/compare_online_training_nz_variants_vs_nz.m), update baseline to NZ, include scenarios NZ_GF_A and NZ_GF_B only, and keep one relative-to-baseline figure per variable. Keep current style and export path. Then check MATLAB syntax errors."

## 6) Copy-Paste Prompts for Participants

### Prompt A: Create a new driver from a template

"Create a new script in [scripts/reporting/OnlineTraining](scripts/reporting/OnlineTraining) named CompareOnlineTraining_MyGroup.m by copying structure from [scripts/reporting/OnlineTraining/compare_online_training_pdp8_vs_baseline.m](scripts/reporting/OnlineTraining/compare_online_training_pdp8_vs_baseline.m). Use baseline Baseline and scenarios PDP8_GF_A, PDP8_GF_B. Keep one relative-to-baseline figure per variable."

### Prompt B: Adjust variable list

"In [scripts/reporting/OnlineTraining/CompareOnlineTraining_MyGroup.m](scripts/reporting/OnlineTraining/CompareOnlineTraining_MyGroup.m), set plotSpecs to these variables with labels and deviation modes:
I_1 (pct_deviation), r_G_3_1 (difference), r_FDI_3_1 (difference), Y_1 (pct_deviation), E_1 (pct_deviation)."

### Prompt C: Validate scenario names against available CSV files

"Check scenario names in my script against files in ExcelFiles/Output. If a scenario CSV is missing, propose the closest valid scenario name and patch the script."

### Prompt D: Improve chart readability

"In [scripts/reporting/OnlineTraining/run_online_training_comparison.m](scripts/reporting/OnlineTraining/run_online_training_comparison.m), increase legend readability for 4+ scenarios and keep style consistent. Do not change core logic."

### Prompt E: Add a short interpretation table

"Add export of a compact CSV with final-year deviations for only Y_1, I_1, and E_1 in my output folder, without changing existing exports."

## 7) Common Mistakes and Fast Fixes

- Wrong baseline/scenario names:
  - Symptom: missing CSV warning.
  - Fix: verify exact names in `ExcelFiles/Output/*.csv`.

- Variable does not exist in outputs:
  - Symptom: missing required variable error.
  - Fix: remove or replace variable in `config.plotSpecs`.

- No overlapping years:
  - Symptom: no common years error.
  - Fix: broaden `plotStartYear`/`plotEndYear` or use matching scenario runs.

- Baseline label mismatch in narrative:
  - Symptom: chart text confusing for participants.
  - Fix: set a clear `config.baselineLabel`.

## 8) Assessment Rubric (quick)

- Correctness (40%): script runs and outputs are generated.
- Comparability (30%): scenarios are correctly relative to the intended baseline.
- Clarity (20%): labels, legends, and folder naming are understandable.
- Interpretation (10%): concise explanation of one finance and one macro finding.

## 9) Instructor Notes

- Keep participants on one script each; avoid over-customization.
- Encourage small prompt iterations instead of one large prompt.
- Ask participants to confirm every Copilot suggestion before applying.
- If groups diverge too much, reset by returning to one known template script.
