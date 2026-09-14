%% Generate Green-Finance-on-NZ scenario figures used for reporting and slides
% Compares the Green Finance variants built on the Net-Zero baseline with NZ
% itself (NZ plays the role Baseline plays for the PDP8 Green Finance set):
%   - NZ_GF_A  (Balanced,   WACF 6.43%)
%   - NZ_GF_B  (Market-led, WACF 7.37%)
%   - NZ_GF_C  (Public-led, WACF 5.07%)
%
% The shared reporting pipeline produces the same figures as
% generate_finance_simulation_results_figures.m: GDP growth/level deviation,
% expenditure shares, renewable WACC, renewable capital, and renewable
% investment, all measured against NZ rather than Baseline.
%
% Input:
%   ExcelFiles/Output/<scenario>_replication.csv  (NZ, NZ_GF_A, NZ_GF_B, NZ_GF_C)
%
% Output:
%   docs/figures/GF_NZ_Simulation_Results/*.svg and *.png
%
% Used in: IWH_Report_Macro Impact Assessment.docx, Figure 6 (top panel:
% WACC_Renewables_Deviation_vs_Baseline_5Y_Average; bottom panel:
% GDP_Level_Deviation_vs_Baseline_5Y_Average). See
% README_MacroImpactAssessment.md for the full figure map.

figureScenarioConfig = struct();
figureScenarioConfig.BaselineName = "Baseline";
figureScenarioConfig.BaselineLabel = "PDP8-rev";
figureScenarioConfig.VersionSuffix = "_replication";
figureScenarioConfig.ScenarioNames = [ ...
    "NZ", ...
    "NZ_GF_B", ...
    "NZ_GF_C"];
figureScenarioConfig.ScenarioLabels = [ ...
    "NZ", ...
    "NZ GF B", ...
    "NZ GF C"];
figureScenarioConfig.OutputSubdirectory = "GF_NZ_Simulation_Results";
figureScenarioConfig.ReportLabel = "Green Finance (NZ baseline) scenario";

run(fullfile(fileparts(mfilename('fullpath')), ...
    'generate_finance_simulation_results_figures.m'));
