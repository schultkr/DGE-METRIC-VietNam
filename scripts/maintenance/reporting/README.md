# Reporting Scripts

Scripts used to generate reports, figures, or publication-style outputs.

## Current Files

- `GenerateEESimulationResultsFigures.m`: writes EE scenario figures used by the EE presentation and markdown report.
- `GenerateFinanceSimulationResultsFigures.m`: writes finance scenario figures used by the finance presentation.
- `GenerateNZBaselineComparisonFigures.m`: writes NZ-vs-baseline comparison figures.
- `CompareBaselineScenarioVariables.m`: baseline comparison plotting workflow.
- `CompareFinanceScenarioVariables.m`: finance scenario comparison plotting workflow.
- `CompareWCEREScenarioVariables.m`: EE/WCERE comparison plotting workflow.
- `CompareWCEREScenarioVariablesNZ.m`: NZ-focused WCERE comparison workflow.
- `CompareWCEREScenarioVariablesPDP8.m`: PDP8-focused WCERE comparison workflow.
- `DisplayBaselineEnergy.m`: baseline energy dashboard plots saved under `Figures/`.
- `EstimateInvPriceDecline.m`: investment-price decline calculations used in reporting.
- `ExportInvestmentGDPRatios.m`: exports investment-to-GDP ratio tables or figures.
- `PlotInvestmentPerInstalledCapacity.m`: installed-capacity investment plot helper.
- `PlotPDP8RevHighCapacityStacked.m`: PDP8 revenue/high-capacity stacked plot.
- `SimulationResultsFinancialInstruments.m`: MATLAB script version of the finance reporting workflow.
- `SimulationResultsFinancialInstruments.mlx`: live script version of the finance reporting workflow.
- `SimulationResultsFinancialInstruments.R`: R implementation of the finance reporting workflow.
- `export_ee_figures_jpeg.ps1`: PowerShell helper to export EE figure assets for TeX slides.

Several `Compare*ScenarioVariables*.m` scripts share a large common plotting core and differ mainly in scenario configuration. They are kept separately today because they target different reporting packages.
