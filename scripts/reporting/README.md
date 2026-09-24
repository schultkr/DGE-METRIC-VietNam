# Reporting Scripts

Scripts used to generate reports, figures, or publication-style outputs.

## Which script produces which report figure?

Per-report figure maps (report figure number → script → exact output file) live in their own
`README_<ReportName>.md` file rather than being listed inline below, since one script can appear in
several reports under different scenario configs:

- [`README_MacroImpactAssessment.md`](README_MacroImpactAssessment.md) — `IWH_Report_Macro Impact
  Assessment.docx`.

## Current Files

- `reproduce_macro_impact_assessment_figures.m`: one-shot driver for the Macro Impact Assessment report. Runs the five `generate_*_simulation_results_figures.m` scripts plus `Visualization/PolicyRecommendations.py` in figure order, checks the required scenario CSVs up front, isolates each script's `clearvars`/`clc`, and prints/returns a per-step status table. Options: `'DryRun'`, `'Steps'`, `'StopOnError'`, `'RunPython'`. See `README_MacroImpactAssessment.md`.
- `generate_ee_simulation_results_figures.m`: writes EE scenario figures used by the EE presentation and markdown report.
- `generate_ee_nz_simulation_results_figures.m`: NZ-baseline analog of `generate_ee_simulation_results_figures.m` (same EE scenario family, compared against NZ instead of Baseline); sets a `figureScenarioConfig` and `run()`s that script.
- `generate_finance_simulation_results_figures.m`: writes finance scenario figures used by the finance presentation.
- `generate_gf_nz_simulation_results_figures.m`: Green-Finance-on-NZ analog of `generate_finance_simulation_results_figures.m` (NZ_GF_B/NZ_GF_C vs NZ); sets a `figureScenarioConfig` and `run()`s that script.
- `generate_nz_simulation_results_figures.m`: Net-Zero policy variants (NZ, NZ_subsidy, NZ_subsidy_direct, NZ_GF_C_EE) through the same finance reporting pipeline; sets a `figureScenarioConfig` and `run()`s `generate_finance_simulation_results_figures.m`.
- `generate_nz_baseline_comparison_figures.m`: writes NZ-vs-baseline comparison figures.
- `compare_baseline_scenario_variables.m`: baseline comparison plotting workflow.
- `compare_finance_scenario_variables.m`: finance scenario comparison plotting workflow.
- `compare_wcere_scenario_variables.m`: EE/WCERE comparison plotting workflow.
- `compare_wcere_scenario_variables_nz.m`: NZ-focused WCERE comparison workflow.
- `compare_wcere_scenario_variables_pdp8.m`: PDP8-focused WCERE comparison workflow.
- `hands_on2_baseline_vs_alternative.m`: participant exercise script for baseline-vs-one-scenario comparison, core output export, one chart, and policy interpretation template.
- `display_baseline_energy.m`: baseline energy dashboard plots saved under `Figures/`.
- `estimate_inv_price_decline.m`: investment-price decline calculations used in reporting.
- `export_investment_gdp_ratios.m`: exports investment-to-GDP ratio tables or figures.
- `plot_investment_per_installed_capacity.m`: installed-capacity investment plot helper.
- `plot_pdp8_rev_high_capacity_stacked.m`: PDP8 revenue/high-capacity stacked plot.
- `plot_energy_efficiency_and_expenditure_paths.m`: plots sectoral energy-efficiency and cumulative expenditure/adaptation-cost paths across Baseline and EE scenarios; output saved under `Figures/EE/`. Moved here from `scripts/analysis/`.
- `save_figures_for_scenarios.m` / `save_figures_for_scenarios_ee.m` / `save_figures_for_scenarios_finance.m` / `save_figures_for_scenarios_all.m`: legacy per-scenario-family figure scripts (RTS, EE, finance, and a generic multi-scenario comparer); each has scenario lists and an output directory hardcoded near the top that must be edited before running. Moved here from `Figures/` (an output directory, not a source location).
- `save_my_figure.m`: helper used by the `save_figures_for_scenarios*` scripts to save a figure handle as both PNG (300 DPI) and PDF. Moved here from `Figures/`.
- `simulation_results_financial_instruments.m`: MATLAB script version of the finance reporting workflow.
- `simulation_results_financial_instruments.mlx`: live script version of the finance reporting workflow.
- `simulation_results_financial_instruments.R`: R implementation of the finance reporting workflow.
- `export_ee_figures_jpeg.ps1`: PowerShell helper to export EE figure assets for TeX slides.
- `plot_sensitivity_scenario_results.m`: compares trajectories across parameter-sensitivity case folders and exports scenario-variable line charts plus a terminal-year summary CSV.
- `summarize_sensitivity_runs.m`: builds a short LaTeX report (run-status table, terminal-year comparison tables, embedded trajectory figures) for a sensitivity batch under `ExcelFiles/Output/SensitivityRuns/`; reads the CSV/PNG outputs of `plot_sensitivity_scenario_results.m`, so run that first for the tables/figures to populate.
- `Visualization/NestedCounterfactualFramework.py`: generates the editable SVG for the nested scenario framework and exports `Figures/nested_counterfactual_framework.png` when ImageMagick is available.
- `Visualization/PolicyRecommendations.py` / `Visualization/InstitutionalPriorities.py`: build the editable SVG/PNG for the integrated policy-package and institutional-foundations figures in the Policy Brief / Technical Report. `PolicyRecommendations.py` emits three outputs built from the same diagram/table code so they can't drift apart: the diagram alone (`Vietnam_integrated_policy_package_diagram.svg`/`.png`), the companion table alone (`Vietnam_policy_recommendations_table.svg`/`.png`, same file `PolicyRecommendationsTable.py` produces standalone), and the two combined into a single Figure 10 (`Vietnam_integrated_policy_package_revised.svg`/`.png`).
- `Visualization/PolicyRecommendationsTable.py`: companion 4-column table (key model result / policy implication / institutionally constrained solution / implementation barriers) for the integrated policy-package figure; addresses the reviewer request to link the findings to Viet Nam's institutional and regulatory context. Emits `Vietnam_policy_recommendations_table.svg` and `.png` when run directly; `PolicyRecommendations.py` imports its `build_table_group`/`build_standalone_svg` helpers rather than duplicating the table layout.

Several `Compare*ScenarioVariables*.m` scripts share a large common plotting core and differ mainly in scenario configuration. They are kept separately today because they target different reporting packages.
