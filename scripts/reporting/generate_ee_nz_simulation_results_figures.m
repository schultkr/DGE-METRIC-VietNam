%% Generate EE simulation-result figures for the NZ-baseline variants
% NZ-baseline analogs of the scenario set in
% generate_ee_simulation_results_figures.m, compared against NZ instead of
% Baseline:
%   - NZ_Dir10_full            (Directive 10, full, on NZ)
%   - NZ_Dir10_full_NoBESS     (Directive 10, full, no BESS, on NZ)
%   - NZ_RTS_prerev_95GW       (RTS at pre-revision 95 GW, on NZ)
%
% Legend labels are kept identical to generate_ee_simulation_results_figures.m
% so the two figure sets read as a matched pair (PDP8-baseline vs NZ-baseline).
%
% Data version: scenarios (including Baseline) in ExcelFiles/Output/ can
% exist as a plain "<Name>.csv", a "<Name>_replication.csv" and a
% "<Name>_replication_fix.csv" (at any given time, only some may actually
% be present for a given scenario). DataVersion below picks which variant
% to prefer; the shared pipeline (generate_ee_simulation_results_figures.m)
% falls back to the other variants automatically if the preferred one isn't
% available for every required scenario (reported via fprintf), so this
% never has to be re-checked scenario by scenario.
%   "replication_fix" - prefer "<Name>_replication_fix.csv" (default)
%   "replication"     - prefer "<Name>_replication.csv"
%   "plain"           - prefer "<Name>.csv"
%
% Output:
%   docs/figures/EE_NZ_Simulation_Results/*.svg and *.png
%
% Used in: IWH_Report_Macro_Impact_Assessment_revised.docx, Figure 3 (top panel:
% GDP_Level_Deviation_vs_Baseline_5Y_Average; bottom panel:
% Energy_Intensity_Deviation_vs_Baseline_5Y_Average). See
% README_MacroImpactAssessment.md for the full figure map.

figureScenarioConfig = struct();
figureScenarioConfig.BaselineName = "Baseline";
figureScenarioConfig.BaselineLabel = "PDP8-rev";
figureScenarioConfig.DataVersion = "replication_fix";
figureScenarioConfig.ScenarioNames = [ ...
    "NZ",...
    "NZ_Dir10_full", ...
    "NZ_Dir10_full_NoBESS", ...
    ];
figureScenarioConfig.ScenarioLabels = [ ...
    "Net Zero", ...
    "Net Zero and Directive 10 (full)", ...
    "Net Zero and Directive 10 no BESS", ...
    ];
figureScenarioConfig.OutputSubdirectory = "EE_NZ_Simulation_Results";

run(fullfile(fileparts(mfilename('fullpath')), ...
    'generate_ee_simulation_results_figures.m'));
