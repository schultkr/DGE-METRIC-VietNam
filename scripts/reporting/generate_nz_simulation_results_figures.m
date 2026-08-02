%% Generate Net-Zero scenario figures used for reporting and slides
% Compares the requested Net-Zero policy variants with the Baseline:
%   - NZ
%   - NZ_subsidy
%   - NZ_subsidy_direct
%   - NZ_GF_C_EE
%
% The shared reporting pipeline produces the same annual and five-year
% figures as generate_finance_simulation_results_figures.m, including GDP,
% expenditure shares, renewable WACC, renewable capital, renewable
% investment, and ETS revenue as a share of GDP.
%
% Input:
%   ExcelFiles/Output/<scenario>_replication.csv
%
% Output:
%   docs/figures/NZ_Simulation_Results/*.svg and *.png

figureScenarioConfig = struct();
figureScenarioConfig.BaselineName = "Baseline";
figureScenarioConfig.VersionSuffix = "_replication";
figureScenarioConfig.ScenarioNames = [ ...
    "NZ", ...
    "NZ_subsidy", ...
    "NZ_subsidy_direct", ...
    "NZ_GF_C_EE"];
figureScenarioConfig.ScenarioLabels = [ ...
    "Net Zero", ...
    "Net Zero - subsidy", ...
    "Net Zero - direct subsidy", ...
    "Net Zero - GF C + EE"];
figureScenarioConfig.OutputSubdirectory = "NZ_Simulation_Results";
figureScenarioConfig.ReportLabel = "Net-Zero scenario";
figureScenarioConfig.IncludeETSRevenuePlot = true;
figureScenarioConfig.IncludeETSBillionUSDPlot = true;
figureScenarioConfig.ETSBillionUSDScenarioName = "NZ";
figureScenarioConfig.GDPAnchorYear = 2025;
figureScenarioConfig.GDPAnchorBillionUSD = 514.7;
figureScenarioConfig.IncludeEmissionPriceUSDPlot = true;
figureScenarioConfig.EmissionPriceScenarioName = "NZ";
% Latest observed EDGAR energy-related GHG total in the project input:
% Power Industry + Industrial Combustion + Transport + Buildings
% + Fuel Exploitation = 352.8946 MtCO2e in 2023.
figureScenarioConfig.EnergyGHGAnchorYear = 2023;
figureScenarioConfig.EnergyGHGAnchorMtCO2e = 352.894603746534;
% Map the latest observed physical total to the model's 2025 emissions base.
figureScenarioConfig.ModelEmissionsAnchorYear = 2025;

run(fullfile(fileparts(mfilename('fullpath')), ...
    'generate_finance_simulation_results_figures.m'));
