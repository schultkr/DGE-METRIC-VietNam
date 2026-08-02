# Scripts

Convenience scripts live here instead of the repository root.

- `analysis/`: post-run diagnostics and steady-state inspection helpers.
- `reporting/`: figure generation, scenario comparison, and report export scripts.
- `maintenance/`: workbook generation and refresh helpers.

## Current Layout

```text
scripts/
|-- analysis/
|   |-- analyze_end_shares.m
|   |-- analyze_va_shares.m
|   |-- check_results.m
|   `-- compute_terminal_ss.m
|-- reporting/
|   |-- compare_baseline_scenario_variables.m
|   |-- compare_finance_scenario_variables.m
|   |-- compare_wcere_scenario_variables.m
|   |-- compare_wcere_scenario_variables_nz.m
|   |-- compare_wcere_scenario_variables_pdp8.m
|   |-- display_baseline_energy.m
|   |-- estimate_inv_price_decline.m
|   |-- export_investment_gdp_ratios.m
|   |-- export_ee_figures_jpeg.ps1
|   |-- generate_ee_simulation_results_figures.m
|   |-- generate_finance_simulation_results_figures.m
|   |-- generate_nz_baseline_comparison_figures.m
|   |-- plot_investment_per_installed_capacity.m
|   |-- plot_pdp8_rev_high_capacity_stacked.m
|   |-- simulation_results_financial_instruments.m
|   |-- simulation_results_financial_instruments.mlx
|   `-- simulation_results_financial_instruments.R
`-- maintenance/
	|-- build_user_inputs_sheet.py
	|-- create_baseline_share_candidates.m
	|-- create_baseline_from_user_input_file.m
	|-- create_baseline_path_definition_template.m
	|-- create_ee_scenarios_from_expert_inputs.m
	|-- create_green_finance_scenarios.m
	|-- optimize_baseline_share_path.m
	|-- update_baseline_sheet.m
	`-- update_nz_sheet.m
```

Run `setup_paths` from MATLAB before using scripts directly.
