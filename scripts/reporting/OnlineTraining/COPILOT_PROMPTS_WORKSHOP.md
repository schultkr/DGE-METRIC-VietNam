# Copilot Prompt Pack for OnlineTraining Scripts

Use these prompts directly in GitHub Copilot Chat.

## Prompt 1: Clone and retarget a script

"Create [scripts/reporting/OnlineTraining/CompareOnlineTraining_GroupA.m](scripts/reporting/OnlineTraining/CompareOnlineTraining_GroupA.m) from [scripts/reporting/OnlineTraining/compare_online_training_nz_variants_vs_baseline.m](scripts/reporting/OnlineTraining/compare_online_training_nz_variants_vs_baseline.m). Keep structure identical. Set baseline to Baseline, scenarios to NZ and NZ_GF_A only, and output subfolder to ScenarioComparisons/OnlineTraining/GroupA."

## Prompt 2: Keep only key variables

"In [scripts/reporting/OnlineTraining/CompareOnlineTraining_GroupA.m](scripts/reporting/OnlineTraining/CompareOnlineTraining_GroupA.m), set plotSpecs to:
Y_1 GDP pct_deviation,
I_1 Investment pct_deviation,
E_1 Emissions pct_deviation,
r_G_3_1 Public capital cost difference.
Do not modify other config fields."

## Prompt 3: Enforce one-figure-per-variable rule

"Review [scripts/reporting/OnlineTraining/run_online_training_comparison.m](scripts/reporting/OnlineTraining/run_online_training_comparison.m) and confirm it produces exactly one figure per variable with all scenarios together relative to baseline. If any extra outputs exist, remove them."

## Prompt 4: Add guardrails for participants

"Add clear error messages in [scripts/reporting/OnlineTraining/run_online_training_comparison.m](scripts/reporting/OnlineTraining/run_online_training_comparison.m) for missing baseline CSV, missing scenario CSV, and missing variable names, without changing plotting logic."

## Prompt 5: Pre-run checklist comment

"Insert a short participant checklist comment block at the top of [scripts/reporting/OnlineTraining/CompareOnlineTraining_GroupA.m](scripts/reporting/OnlineTraining/CompareOnlineTraining_GroupA.m): verify baseline name, scenario names, variable names, and year range."

## Prompt 6: Debrief helper output

"Extend [scripts/reporting/OnlineTraining/run_online_training_comparison.m](scripts/reporting/OnlineTraining/run_online_training_comparison.m) to print the top 3 largest absolute final-year deviations from comparison_summary_final_year.csv after writing the file. Keep existing file outputs unchanged."
