%% Generate EE simulation-result figures used by the TeX presentation
% Regenerates the exact figure filenames consumed by
% docs/EE_Scenario_Presentation/ee_scenarios_presentation.tex.
%
% Used in: IWH_Report_Macro_Impact_Assessment_revised.docx, Figure 1
% (GDP_Level_Deviation_vs_Baseline_5Y_Average) and Figure 2
% (Energy_Intensity_Deviation_vs_Baseline_5Y_Average). See
% README_MacroImpactAssessment.md for the full figure map.
%
% A wrapper script may provide figureScenarioConfig to reuse this reporting
% pipeline for another scenario family (e.g. the NZ-baseline analogs) while
% preserving identical figures.
if ~exist('figureScenarioConfig', 'var')
    figureScenarioConfig = struct();
end
clearvars -except figureScenarioConfig;
close all; clc;

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

if isfield(figureScenarioConfig, 'OutputSubdirectory')
    outputSubdirectory = char(figureScenarioConfig.OutputSubdirectory);
else
    outputSubdirectory = 'EE_Simulation_Results';
end
outDir = fullfile(repoRoot, 'docs', 'figures', outputSubdirectory);
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

plotYears = 2026:2050;

options = struct();
options.ShowFiveYearAverageDeviation = true;
options.ShowFiveYearIntervalChange = false;
options.FiveYearBlockSize = 5;

if isfield(figureScenarioConfig, 'BaselineName')
    baselineName = string(figureScenarioConfig.BaselineName);
else
    baselineName = "Baseline";
end
if isfield(figureScenarioConfig, 'BaselineLabel')
    baselineLabel = string(figureScenarioConfig.BaselineLabel);
else
    baselineLabel = "PDP8-rev";
end
if isfield(figureScenarioConfig, 'ScenarioNames')
    scenarioNames = string(figureScenarioConfig.ScenarioNames);
else
    scenarioNames = ["EE_Dir10_full", "EE_Dir10_full_NoBESS", "EE_RTS_prerev_95GW"];
end
if isfield(figureScenarioConfig, 'ScenarioLabels')
    scenarioLabels = string(figureScenarioConfig.ScenarioLabels);
else
    scenarioLabels = ["Directive 10 (full)", "Directive 10 no BESS", "RTS at pre-revision 95 GW"];
end
if numel(scenarioNames) ~= numel(scenarioLabels)
    error('generate_ee_simulation_results_figures:scenarioConfig', ...
        'ScenarioNames and ScenarioLabels must have the same number of entries.');
end

allNames = [baselineName, scenarioNames];

% Data version: scenarios (including Baseline) in ExcelFiles/Output/ can
% exist as a plain "<Name>.csv", a "<Name>_replication.csv" and a
% "<Name>_replication_fix.csv" (at any given time, only some of these may
% actually be present for a given scenario). A wrapper can force an exact
% suffix via VersionSuffix (used as-is, no fallback); otherwise DataVersion
% picks which variant to prefer and the others are tried automatically if
% the preferred one isn't available for every required scenario (reported
% via fprintf), so this never has to be re-checked scenario by scenario.
%   "replication_fix" - prefer "<Name>_replication_fix.csv" (default; falls
%                       back to replication, then plain)
%   "replication"     - prefer "<Name>_replication.csv"
%   "plain"           - prefer "<Name>.csv"
if isfield(figureScenarioConfig, 'VersionSuffix')
    sversion = string(figureScenarioConfig.VersionSuffix);
else
    if isfield(figureScenarioConfig, 'DataVersion')
        dataVersion = string(figureScenarioConfig.DataVersion);
    else
        dataVersion = "replication_fix";
    end
    outputDir = fullfile(repoRoot, 'ExcelFiles', 'Output');
    [sversion, usedFallback] = resolve_version_suffix(outputDir, allNames, dataVersion);
    if usedFallback
        fprintf(['generate_ee_simulation_results_figures: preferred "%s" variant ' ...
            'not found for all scenarios; using "%s" instead.\n'], ...
            dataVersion, version_label(sversion));
    end
end

allData = struct();
for i = 1:numel(allNames)
    name = allNames(i);
    csvPath = fullfile(repoRoot, 'ExcelFiles', 'Output', name + sversion +".csv");
    if ~isfile(csvPath)
        error('generate_ee_simulation_results_figures:missingCsv', ...
            'Required CSV not found: %s', csvPath);
    end
    allData.(char(name)) = readtable(csvPath);
end

requiredVars = ["Year", "Y_1", "I_1", "C_1", "NX_1", "Q_A_2_1", "Q_PV_1", "Q_A_F_2_1", "P_A_2_1", "E_1", "Q_2_1", "Q_3_1"];
for i = 1:numel(allNames)
    tbl = allData.(char(allNames(i)));
    missing = requiredVars(~ismember(requiredVars, string(tbl.Properties.VariableNames)));
    if ~isempty(missing)
        error('generate_ee_simulation_results_figures:missingVars', ...
            'Missing variable(s) in %s.csv: %s', allNames(i), strjoin(cellstr(missing), ', '));
    end
end

% Keep only common years available across all required files.
commonYears = allData.(char(baselineName)).Year(:);
for i = 1:numel(scenarioNames)
    commonYears = intersect(commonYears, allData.(char(scenarioNames(i))).Year(:));
end
commonYears = sort(commonYears(:));
plotYears = plotYears(ismember(plotYears, commonYears));
if isempty(plotYears)
    error('generate_ee_simulation_results_figures:noYears', ...
        'No common years found in requested plotting horizon.');
end

% Build baseline metric series for deviation charts.
baseline = allData.(char(baselineName));
bGDPGrowth = annual_growth(baseline, 'Y_1', plotYears);
bInvShare = level_share(baseline, 'I_1', 'Y_1', plotYears);
bConsShare = level_share(baseline, 'C_1', 'Y_1', plotYears);
bGovConsShare = level_share(baseline, 'G_1', 'Y_1', plotYears);
bHousingInvShare = housing_investment_share(baseline, plotYears);
bNetExportsShare = net_exports_share(baseline, plotYears);
bEnergyIntensity = energy_intensity_index(baseline, plotYears);
bEnergyPrices = energy_price_index(baseline, plotYears);
bFinalDemand = final_energy_demand_index(baseline, plotYears);
bFinalDemandGrid = grid_final_energy_demand_index(baseline, plotYears);
bFinalDemandPV = pv_final_energy_demand_index(baseline, plotYears);
bRenewableShare = renewable_share_of_energy(baseline, plotYears);
bFossilShare = fossil_share_of_energy(baseline, plotYears);
bRenewableProduction = renewable_production_index(baseline, plotYears);
bFossilProduction = fossil_production_index(baseline, plotYears);
bGDPLevel = extract_values(baseline, 'Y_1', plotYears);

styles = iwh_scenario_style(scenarioNames);
colors = reshape([styles.Color], 3, [])';   % keeps existing colors(i,:) call sites unchanged
lineWidth = 2.0;

% 1) GDP growth comparison with baseline.
fig = make_fig();
hold on;
plot(bGDPGrowth.Years, bGDPGrowth.Values, 'Color', iwh_colors().baseline, ...
    'LineWidth', lineWidth, 'LineStyle', '-', 'DisplayName', char(baselineLabel));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    g = annual_growth(s, 'Y_1', plotYears);
    plot(g.Years, g.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('GDP Growth Comparison with Baseline', '%');
yl = ylim;
ylim([0, yl(2)]);
place_legend_below();
save_dual(fig, outDir, 'GDP_Growth_Comparison_with_Baseline');

% 2) Investment share of GDP.
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = level_share(s, 'I_1', 'Y_1', plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Investment Share of GDP', '% of GDP');
place_legend_below();
save_dual(fig, outDir, 'Investment_Share_GDP');

% 3) Consumption share of GDP.
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = level_share(s, 'C_1', 'Y_1', plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Consumption Share of GDP', '% of GDP');
place_legend_below();
save_dual(fig, outDir, 'Consumption_Share_GDP');

% 3b) Government consumption share of GDP.
fig = make_fig(); hold on;
levelMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = level_share(s, 'G_1', 'Y_1', plotYears);
    levelMat(:, i) = v.Values;
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Government Consumption Share of GDP', '% of GDP');
place_legend_below();
save_dual(fig, outDir, 'Government_Consumption_Share_GDP');
maybe_save_five_year_level_bars(outDir, 'Government_Consumption_Share_GDP', ...
    'Government Consumption Share of GDP', '% of GDP', plotYears, levelMat, ...
    scenarioLabels, colors, options);

% 3c) Housing investment share of GDP.
fig = make_fig(); hold on;
levelMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = housing_investment_share(s, plotYears);
    levelMat(:, i) = v.Values;
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Housing Investment Share of GDP', '% of GDP');
place_legend_below();
save_dual(fig, outDir, 'Housing_Investment_Share_GDP');
maybe_save_five_year_level_bars(outDir, 'Housing_Investment_Share_GDP', ...
    'Housing Investment Share of GDP', '% of GDP', plotYears, levelMat, ...
    scenarioLabels, colors, options);

% 3d) Net exports share of GDP.
fig = make_fig(); hold on;
levelMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = net_exports_share(s, plotYears);
    levelMat(:, i) = v.Values;
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Net Exports Share of GDP', '% of GDP');
place_legend_below();
save_dual(fig, outDir, 'Net_Exports_Share_GDP');
maybe_save_five_year_level_bars(outDir, 'Net_Exports_Share_GDP', ...
    'Net Exports Share of GDP', '% of GDP', plotYears, levelMat, ...
    scenarioLabels, colors, options);

% 4) Energy intensity index.
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = energy_intensity_index(s, plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Energy Intensity Index', 'Index (2026 = 100)');
place_legend_below();
save_dual(fig, outDir, 'Energy_Intensity_Index');

% 5) Energy prices index.
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = energy_price_index(s, plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Energy Prices Index', 'Index (2026 = 100)');
place_legend_below();
save_dual(fig, outDir, 'Energy_Prices_Index');

% 6) Final energy demand index.
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = final_energy_demand_index(s, plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Final Energy Demand Index', 'Index (2026 = 100)');
place_legend_below();
save_dual(fig, outDir, 'Final_Energy_Demand_Index');

% 6b) Final energy demand index (grid-provided).
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = grid_final_energy_demand_index(s, plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Final Energy Demand Index (Grid-provided)', 'Index (2026 = 100)');
place_legend_below();
save_dual(fig, outDir, 'Final_Energy_Demand_Grid_Index');

% 6c) Final energy demand index (PV-provided).
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = pv_final_energy_demand_index(s, plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Final Energy Demand Index (PV-provided)', 'Index (2026 = 100)');
place_legend_below();
save_dual(fig, outDir, 'Final_Energy_Demand_PV_Index');

% 6d) Renewable share of energy output (grid renewables + PV vs. fossil + grid renewables + PV).
fig = make_fig(); hold on;
levelMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = renewable_share_of_energy(s, plotYears);
    levelMat(:, i) = v.Values;
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Renewable Share of Energy Output', 'Year', '% of total energy output');
place_legend_below();
save_dual(fig, outDir, 'Renewable_Share_Energy_Output');
maybe_save_five_year_level_bars(outDir, 'Renewable_Share_Energy_Output', ...
    'Renewable Share of Energy Output', '% of total energy output', plotYears, levelMat, ...
    scenarioLabels, colors, options);

% 6e) Fossil share of energy output.
fig = make_fig(); hold on;
levelMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = fossil_share_of_energy(s, plotYears);
    levelMat(:, i) = v.Values;
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Fossil Share of Energy Output', 'Year', '% of total energy output');
place_legend_below();
save_dual(fig, outDir, 'Fossil_Share_Energy_Output');
maybe_save_five_year_level_bars(outDir, 'Fossil_Share_Energy_Output', ...
    'Fossil Share of Energy Output', '% of total energy output', plotYears, levelMat, ...
    scenarioLabels, colors, options);

% 6f) Renewable production index (grid renewables + PV).
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = renewable_production_index(s, plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Renewable Production Index', 'Year', 'Index (2026 = 100)');
place_legend_below();
save_dual(fig, outDir, 'Renewable_Production_Index');

% 6g) Fossil production index.
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = fossil_production_index(s, plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Fossil Production Index', 'Year', 'Index (2026 = 100)');
place_legend_below();
save_dual(fig, outDir, 'Fossil_Production_Index');

% 7) Emissions index.
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = emissions_index(s, plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Emissions Index', 'Index (2026 = 100)');
place_legend_below();
save_dual(fig, outDir, 'Emissions_Index');

% 8) GDP level deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    y = extract_values(s, 'Y_1', plotYears);
    d = safe_divide(y.Values, bGDPLevel.Values) .* 100 - 100;
    devMat(:, i) = d;
    plot(y.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('GDP Level Deviation vs Baseline', '% deviation');
place_legend_below();
save_dual(fig, outDir, 'GDP_Level_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'GDP_Level_Deviation_vs_Baseline', ...
    'GDP Level Deviation vs Baseline', '% deviation', plotYears, devMat, ...
    scenarioLabels, colors, options);

% 9) Investment share deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = level_share(s, 'I_1', 'Y_1', plotYears);
    d = v.Values - bInvShare.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Investment Share Deviation vs Baseline', 'pp of GDP');
place_legend_below();
save_dual(fig, outDir, 'Investment_Share_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Investment_Share_Deviation_vs_Baseline', ...
    'Investment Share Deviation vs Baseline', 'pp of GDP', plotYears, devMat, ...
    scenarioLabels, colors, options);

% 10) Consumption share deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = level_share(s, 'C_1', 'Y_1', plotYears);
    d = v.Values - bConsShare.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Consumption Share Deviation vs Baseline', 'pp of GDP');
place_legend_below();
save_dual(fig, outDir, 'Consumption_Share_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Consumption_Share_Deviation_vs_Baseline', ...
    'Consumption Share Deviation vs Baseline', 'pp of GDP', plotYears, devMat, ...
    scenarioLabels, colors, options);

% 10b) Government consumption share deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = level_share(s, 'G_1', 'Y_1', plotYears);
    d = v.Values - bGovConsShare.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Government Consumption Share Deviation vs Baseline', 'pp of GDP');
place_legend_below();
save_dual(fig, outDir, 'Government_Consumption_Share_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Government_Consumption_Share_Deviation_vs_Baseline', ...
    'Government Consumption Share Deviation vs Baseline', 'pp of GDP', plotYears, devMat, ...
    scenarioLabels, colors, options);

% 10c) Housing investment share deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = housing_investment_share(s, plotYears);
    d = v.Values - bHousingInvShare.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Housing Investment Share Deviation vs Baseline', 'pp of GDP');
place_legend_below();
save_dual(fig, outDir, 'Housing_Investment_Share_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Housing_Investment_Share_Deviation_vs_Baseline', ...
    'Housing Investment Share Deviation vs Baseline', 'pp of GDP', plotYears, devMat, ...
    scenarioLabels, colors, options);

% 10d) Net exports share deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = net_exports_share(s, plotYears);
    d = v.Values - bNetExportsShare.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Net Exports Share Deviation vs Baseline', 'pp of GDP');
place_legend_below();
save_dual(fig, outDir, 'Net_Exports_Share_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Net_Exports_Share_Deviation_vs_Baseline', ...
    'Net Exports Share Deviation vs Baseline', 'pp of GDP', plotYears, devMat, ...
    scenarioLabels, colors, options);

% 11) Energy intensity deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = energy_intensity_index(s, plotYears);
    d = v.Values - bEnergyIntensity.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Energy Intensity Deviation vs Baseline', 'Index points');
place_legend_below();
save_dual(fig, outDir, 'Energy_Intensity_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Energy_Intensity_Deviation_vs_Baseline', ...
    'Energy Intensity Deviation vs Baseline', 'Index points', plotYears, devMat, ...
    scenarioLabels, colors, options);

% 12) Energy prices deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = energy_price_index(s, plotYears);
    d = v.Values - bEnergyPrices.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Energy Prices Deviation vs Baseline', 'Index points');
place_legend_below();
save_dual(fig, outDir, 'Energy_Prices_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Energy_Prices_Deviation_vs_Baseline', ...
    'Energy Prices Deviation vs Baseline', 'Index points', plotYears, devMat, ...
    scenarioLabels, colors, options);

% 13) Final energy demand deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = final_energy_demand_index(s, plotYears);
    d = v.Values - bFinalDemand.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Final Energy Demand Deviation vs Baseline', 'Index points');
place_legend_below();
save_dual(fig, outDir, 'Final_Energy_Demand_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Final_Energy_Demand_Deviation_vs_Baseline', ...
    'Final Energy Demand Deviation vs Baseline', 'Index points', plotYears, devMat, ...
    scenarioLabels, colors, options);

% 13b) Final energy demand deviation vs baseline (grid-provided).
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = grid_final_energy_demand_index(s, plotYears);
    d = v.Values - bFinalDemandGrid.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Final Energy Demand Deviation vs Baseline (Grid-provided)', 'Index points');
place_legend_below();
save_dual(fig, outDir, 'Final_Energy_Demand_Grid_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Final_Energy_Demand_Grid_Deviation_vs_Baseline', ...
    'Final Energy Demand Deviation vs Baseline (Grid-provided)', 'Index points', plotYears, devMat, ...
    scenarioLabels, colors, options);

% 13c) Final energy demand deviation vs baseline (PV-provided).
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = pv_final_energy_demand_index(s, plotYears);
    d = v.Values - bFinalDemandPV.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', styles(i).LineStyle, 'Marker', styles(i).Marker, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Final Energy Demand Deviation vs Baseline (PV-provided)', 'Index points');
place_legend_below();
save_dual(fig, outDir, 'Final_Energy_Demand_PV_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Final_Energy_Demand_PV_Deviation_vs_Baseline', ...
    'Final Energy Demand Deviation vs Baseline (PV-provided)', 'Index points', plotYears, devMat, ...
    scenarioLabels, colors, options);

% 13d) Renewable share of energy output deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = renewable_share_of_energy(s, plotYears);
    d = v.Values - bRenewableShare.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Renewable Share of Energy Output Deviation vs Baseline', 'Year', 'pp of energy output');
place_legend_below();
save_dual(fig, outDir, 'Renewable_Share_Energy_Output_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Renewable_Share_Energy_Output_Deviation_vs_Baseline', ...
    'Renewable Share of Energy Output Deviation vs Baseline', 'pp of energy output', plotYears, devMat, ...
    scenarioLabels, colors, lineTypes, lineWidth, options);

% 13e) Fossil share of energy output deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = fossil_share_of_energy(s, plotYears);
    d = v.Values - bFossilShare.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Fossil Share of Energy Output Deviation vs Baseline', 'Year', 'pp of energy output');
place_legend_below();
save_dual(fig, outDir, 'Fossil_Share_Energy_Output_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Fossil_Share_Energy_Output_Deviation_vs_Baseline', ...
    'Fossil Share of Energy Output Deviation vs Baseline', 'pp of energy output', plotYears, devMat, ...
    scenarioLabels, colors, lineTypes, lineWidth, options);

% 13f) Renewable production deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = renewable_production_index(s, plotYears);
    d = v.Values - bRenewableProduction.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Renewable Production Deviation vs Baseline', 'Year', 'Index points');
place_legend_below();
save_dual(fig, outDir, 'Renewable_Production_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Renewable_Production_Deviation_vs_Baseline', ...
    'Renewable Production Deviation vs Baseline', 'Index points', plotYears, devMat, ...
    scenarioLabels, colors, lineTypes, lineWidth, options);

% 13g) Fossil production deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = fossil_production_index(s, plotYears);
    d = v.Values - bFossilProduction.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Fossil Production Deviation vs Baseline', 'Year', 'Index points');
place_legend_below();
save_dual(fig, outDir, 'Fossil_Production_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Fossil_Production_Deviation_vs_Baseline', ...
    'Fossil Production Deviation vs Baseline', 'Index points', plotYears, devMat, ...
    scenarioLabels, colors, lineTypes, lineWidth, options);

fprintf('Generated EE presentation figures in: %s\n', outDir);

%% Local functions

function [versionSuffix, usedFallback] = resolve_version_suffix(outputDir, allNames, dataVersion)
    % Resolves the single suffix to apply to every name in allNames
    % according to the preferred dataVersion ("replication_fix",
    % "replication" or "plain"), falling back to the other variants only if
    % the preferred one is not available for ALL required names (one suffix
    % is applied uniformly across baseline + scenarios, so a partial match
    % isn't usable).
    switch dataVersion
        case "replication_fix"
            candidateSuffixes = ["_replication_fix", "_replication", ""];
        case "replication"
            candidateSuffixes = ["_replication", "_replication_fix", ""];
        case "plain"
            candidateSuffixes = ["", "_replication_fix", "_replication"];
        otherwise
            error('generate_ee_simulation_results_figures:badDataVersion', ...
                'DataVersion must be "replication_fix", "replication" or "plain", got "%s".', dataVersion);
    end

    for iCand = 1:numel(candidateSuffixes)
        suffix = candidateSuffixes(iCand);
        haveAll = all(arrayfun(@(n) isfile(fullfile(outputDir, n + suffix + ".csv")), allNames));
        if haveAll
            versionSuffix = suffix;
            usedFallback = (iCand > 1);
            return
        end
    end

    error('generate_ee_simulation_results_figures:missingCsv', ...
        ['Could not find a complete set of CSVs (tried %s variants) ' ...
         'for all of: %s in %s.'], strjoin(cellstr(arrayfun(@version_label, candidateSuffixes)), ', '), ...
        strjoin(cellstr(allNames), ', '), outputDir);
end

function label = version_label(suffix)
    if suffix == ""
        label = "plain";
    else
        label = extractAfter(suffix, "_");   % "_replication_fix" -> "replication_fix"
    end
end

function fig = make_fig()
    fig = figure('Color', 'w', 'Position', [80 80 1000 560]);
end

function format_axes(plotTitle, yLabelText)
    grid on;
    box off;
    if iscell(plotTitle)
        titleLines = plotTitle;
    else
        titleLines = {plotTitle};
    end
    ylabel([titleLines(:); {yLabelText}]);
end

function place_legend_below()
    lgd = legend('Location', 'southoutside', 'Box', 'off', 'Interpreter', 'none');
    if isprop(lgd, 'NumColumns')
        nLabels = numel(lgd.String);
        lgd.NumColumns = max(1, min(4, nLabels));
    end
end

function save_dual(fig, outDir, stem)
    svgPath = fullfile(outDir, [stem '.svg']);
    pngPath = fullfile(outDir, [stem '.png']);

    % MATLAB release behavior differs for SVG export support in exportgraphics.
    % Try the newer path first, then fall back to print('-dsvg') when needed.
    try
        exportgraphics(fig, svgPath, 'ContentType', 'vector');
    catch meSvg
        try
            set(fig, 'Renderer', 'painters');
            print(fig, svgPath, '-dsvg');
        catch mePrint
            warning('generate_ee_simulation_results_figures:svgExportFailed', ...
                ['SVG export failed for "%s". Continuing with PNG only. ' ...
                 'exportgraphics error: %s | print error: %s'], ...
                stem, meSvg.message, mePrint.message);
        end
    end

    try
        exportgraphics(fig, pngPath, 'Resolution', 300);
    catch mePng
        try
            set(fig, 'Renderer', 'painters');
            print(fig, pngPath, '-dpng', '-r300');
        catch mePrintPng
            warning('generate_ee_simulation_results_figures:pngExportFailed', ...
                ['PNG export failed for "%s". Continuing without a PNG. ' ...
                 'exportgraphics error: %s | print error: %s'], ...
                stem, mePng.message, mePrintPng.message);
        end
    end
    close(fig);
end

function out = extract_values(tbl, varName, years)
    [tf, idx] = ismember(years(:), tbl.Year(:));
    validYears = years(tf);
    out.Years = validYears(:);
    out.Values = tbl.(varName)(idx(tf));
end

function out = level_share(tbl, numVar, denVar, years)
    num = extract_values(tbl, numVar, years);
    den = extract_values(tbl, denVar, years);
    out.Years = num.Years;
    out.Values = safe_divide(num.Values, den.Values) .* 100;
end

function out = housing_investment_share(tbl, years)
    ih = extract_values(tbl, 'IH_1', years);
    ph = extract_values(tbl, 'PH_1', years);
    y = extract_values(tbl, 'Y_1', years);
    out.Years = y.Years;
    out.Values = safe_divide(ih.Values .* ph.Values, y.Values) .* 100;
end

function out = net_exports_share(tbl, years)
    y = extract_values(tbl, 'Y_1', years);
    nx = extract_values(tbl, 'NX_1', years);
    out.Years = y.Years;
    out.Values = safe_divide(nx.Values, y.Values) .* 100;
end

function out = annual_growth(tbl, varName, years)
    yAll = tbl.Year(:);
    xAll = tbl.(varName);
    target = years(:);

    vals = nan(size(target));
    for i = 1:numel(target)
        y = target(i);
        iNow = find(yAll == y, 1, 'first');
        iPrev = find(yAll == (y - 1), 1, 'first');
        if ~isempty(iNow) && ~isempty(iPrev)
            vals(i) = safe_divide(xAll(iNow), xAll(iPrev)) * 100 - 100;
        end
    end

    keep = ~isnan(vals);
    out.Years = target(keep);
    out.Values = vals(keep);
end

function out = energy_intensity_index(tbl, years)
    energy = extract_values(tbl, 'Q_A_2_1', years);
    pv = extract_values(tbl, 'Q_PV_1', years);
    gdp = extract_values(tbl, 'Y_1', years);

    baseEnergy = energy.Values(1) + pv.Values(1);
    baseGDP = gdp.Values(1);

    eIdx = safe_divide((energy.Values + pv.Values), baseEnergy) .* 100;
    gIdx = safe_divide(gdp.Values, baseGDP) .* 100;

    out.Years = years(:);
    out.Values = safe_divide(eIdx, gIdx) .* 100;
end

function out = energy_price_index(tbl, years)
    price = extract_values(tbl, 'P_A_2_1', years);
    out.Years = price.Years;
    out.Values = safe_divide(price.Values, price.Values(1)) .* 100;
end

function out = final_energy_demand_index(tbl, years)
    qf = extract_values(tbl, 'Q_A_F_2_1', years);
    pv = extract_values(tbl, 'Q_PV_1', years);
    out.Years = qf.Years;
    out.Values = safe_divide((qf.Values + pv.Values), (qf.Values(1) + pv.Values(1))) .* 100;
end

function out = grid_final_energy_demand_index(tbl, years)
    qf = extract_values(tbl, 'Q_A_F_2_1', years);
    out.Years = qf.Years;
    out.Values = safe_divide(qf.Values, qf.Values(1)) .* 100;
end

function out = pv_final_energy_demand_index(tbl, years)
    pv = extract_values(tbl, 'Q_PV_1', years);
    out.Years = pv.Years;
    out.Values = safe_divide(pv.Values, pv.Values(1)) .* 100;
end

function out = renewable_share_of_energy(tbl, years)
    fossil = extract_values(tbl, 'Q_2_1', years);
    renewable = extract_values(tbl, 'Q_3_1', years);
    pv = extract_values(tbl, 'Q_PV_1', years);
    total = fossil.Values + renewable.Values + pv.Values;
    out.Years = fossil.Years;
    out.Values = safe_divide(renewable.Values + pv.Values, total) .* 100;
end

function out = fossil_share_of_energy(tbl, years)
    fossil = extract_values(tbl, 'Q_2_1', years);
    renewable = extract_values(tbl, 'Q_3_1', years);
    pv = extract_values(tbl, 'Q_PV_1', years);
    total = fossil.Values + renewable.Values + pv.Values;
    out.Years = fossil.Years;
    out.Values = safe_divide(fossil.Values, total) .* 100;
end

function out = renewable_production_index(tbl, years)
    renewable = extract_values(tbl, 'Q_3_1', years);
    pv = extract_values(tbl, 'Q_PV_1', years);
    total = renewable.Values + pv.Values;
    out.Years = renewable.Years;
    out.Values = safe_divide(total, total(1)) .* 100;
end

function out = fossil_production_index(tbl, years)
    fossil = extract_values(tbl, 'Q_2_1', years);
    out.Years = fossil.Years;
    out.Values = safe_divide(fossil.Values, fossil.Values(1)) .* 100;
end

function out = emissions_index(tbl, years)
    e = extract_values(tbl, 'E_1', years);
    out.Years = e.Years;
    out.Values = safe_divide(e.Values, e.Values(1)) .* 100;
end

function z = safe_divide(a, b)
    z = a ./ b;
    z(~isfinite(z)) = NaN;
end

function maybe_save_five_year_level_bars(outDir, stem, metricTitle, yLabel, years, levelMat, ...
    scenarioLabels, colors, options)
    if ~options.ShowFiveYearAverageDeviation
        return
    end

    [periodLabels, avgMat] = five_year_level_blocks(years, levelMat, options.FiveYearBlockSize);
    fig = make_fig();
    plot_grouped_period_bars(avgMat, periodLabels, scenarioLabels, colors);
    format_axes({metricTitle, '5-year average level'}, yLabel);
    place_legend_below();
    save_dual(fig, outDir, [stem '_5Y_Average']);
end

function maybe_save_five_year_summaries(outDir, stem, metricTitle, yLabel, years, devMat, ...
    scenarioLabels, colors, options)
    if ~options.ShowFiveYearAverageDeviation && ~options.ShowFiveYearIntervalChange
        return
    end

    [periodLabels, avgMat, deltaMat] = five_year_deviation_blocks(years, devMat, options.FiveYearBlockSize);

    if options.ShowFiveYearAverageDeviation
        fig = make_fig();
        plot_grouped_period_bars(avgMat, periodLabels, scenarioLabels, colors);
        yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
        format_axes({metricTitle, '5-year average deviation'}, yLabel);
        place_legend_below();
        save_dual(fig, outDir, [stem '_5Y_Average']);
    end

    if options.ShowFiveYearIntervalChange
        fig = make_fig();
        plot_grouped_period_bars(deltaMat, periodLabels, scenarioLabels, colors);
        yline(0, ':', 'Color', iwh_colors().zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
        format_axes({metricTitle, 'Change vs previous 5-year block'}, [yLabel ' change']);
        place_legend_below();
        save_dual(fig, outDir, [stem '_5Y_Change']);
    end
end

function [periodLabels, avgMat, deltaMat] = five_year_deviation_blocks(years, devMat, blockSize)
    years = years(:);
    nBlocks = floor(numel(years) / blockSize);
    periodLabels = strings(nBlocks, 1);
    avgMat = nan(nBlocks, size(devMat, 2));

    for b = 1:nBlocks
        idxStart = (b - 1) * blockSize + 1;
        idxEnd = b * blockSize;
        idx = idxStart:idxEnd;
        periodLabels(b) = string(years(idxStart)) + "-" + string(years(idxEnd));
        avgMat(b, :) = mean(devMat(idx, :), 1, 'omitnan');
    end

    deltaMat = nan(size(avgMat));
    if nBlocks > 1
        deltaMat(2:end, :) = avgMat(2:end, :) - avgMat(1:end-1, :);
    end
end

function [periodLabels, avgMat] = five_year_level_blocks(years, levelMat, blockSize)
    years = years(:);
    nBlocks = floor(numel(years) / blockSize);
    periodLabels = strings(nBlocks, 1);
    avgMat = nan(nBlocks, size(levelMat, 2));

    for b = 1:nBlocks
        idxStart = (b - 1) * blockSize + 1;
        idxEnd = b * blockSize;
        idx = idxStart:idxEnd;
        periodLabels(b) = string(years(idxStart)) + "-" + string(years(idxEnd));
        avgMat(b, :) = mean(levelMat(idx, :), 1, 'omitnan');
    end
end

function plot_grouped_period_bars(dataMat, periodLabels, scenarioLabels, colors)
    ax = gca;
    bh = bar(ax, dataMat, 'grouped');
    for i = 1:numel(bh)
        bh(i).FaceColor = colors(i, :);
        bh(i).DisplayName = char(scenarioLabels(i));
    end
    ax.XTick = 1:numel(periodLabels);
    ax.XTickLabel = cellstr(periodLabels);
    xtickangle(ax, 30);
end
