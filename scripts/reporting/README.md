# Reporting Scripts

Scripts used to generate reports, figures, or publication-style outputs.

## Current Files

- `generate_ee_simulation_results_figures.m`: writes EE scenario figures used by the EE presentation and markdown report.
- `generate_finance_simulation_results_figures.m`: writes finance scenario figures used by the finance presentation.
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
- `simulation_results_financial_instruments.m`: MATLAB script version of the finance reporting workflow.
- `simulation_results_financial_instruments.mlx`: live script version of the finance reporting workflow.
- `simulation_results_financial_instruments.R`: R implementation of the finance reporting workflow.
- `export_ee_figures_jpeg.ps1`: PowerShell helper to export EE figure assets for TeX slides.
- `plot_sensitivity_scenario_results.m`: compares trajectories across parameter-sensitivity case folders and exports scenario-variable line charts plus a terminal-year summary CSV.
- `summarize_sensitivity_runs.m`: builds a short LaTeX report (run-status table, terminal-year comparison tables, embedded trajectory figures) for a sensitivity batch under `ExcelFiles/Output/SensitivityRuns/`; reads the CSV/PNG outputs of `plot_sensitivity_scenario_results.m`, so run that first for the tables/figures to populate.

Several `Compare*ScenarioVariables*.m` scripts share a large common plotting core and differ mainly in scenario configuration. They are kept separately today because they target different reporting packages.
