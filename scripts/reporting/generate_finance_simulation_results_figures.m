%% Generate finance-scenario figures used for reporting and slides
% Produces baseline-vs-scenario charts for:
%   - GDP growth
%   - WACC (renewables sector)
%   - Renewable capital and investment deviations from Baseline
%
% Output:
%   docs/figures/Finance_Simulation_Results/*.svg and *.png

% A wrapper script may provide figureScenarioConfig to reuse this reporting
% pipeline for another scenario family while preserving identical figures.
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

outputDir = fullfile(repoRoot, 'ExcelFiles', 'Output');
if isfield(figureScenarioConfig, 'OutputSubdirectory')
    outputSubdirectory = char(figureScenarioConfig.OutputSubdirectory);
else
    outputSubdirectory = 'Finance_Simulation_Results';
end
if isfield(figureScenarioConfig, 'ReportLabel')
    reportLabel = char(figureScenarioConfig.ReportLabel);
else
    reportLabel = 'finance scenario';
end
if isfield(figureScenarioConfig, 'IncludeETSRevenuePlot')
    includeETSRevenuePlot = logical(figureScenarioConfig.IncludeETSRevenuePlot);
else
    includeETSRevenuePlot = false;
end
if isfield(figureScenarioConfig, 'IncludeETSBillionUSDPlot')
    includeETSBillionUSDPlot = logical(figureScenarioConfig.IncludeETSBillionUSDPlot);
else
    includeETSBillionUSDPlot = false;
end
if isfield(figureScenarioConfig, 'IncludeEmissionPriceUSDPlot')
    includeEmissionPriceUSDPlot = logical(figureScenarioConfig.IncludeEmissionPriceUSDPlot);
else
    includeEmissionPriceUSDPlot = false;
end
if includeETSBillionUSDPlot
    requiredETSConfig = {'ETSBillionUSDScenarioName', 'GDPAnchorYear', ...
        'GDPAnchorBillionUSD'};
    for iConfig = 1:numel(requiredETSConfig)
        if ~isfield(figureScenarioConfig, requiredETSConfig{iConfig})
            error('generate_finance_simulation_results_figures:etsConfig', ...
                'Missing figureScenarioConfig.%s.', requiredETSConfig{iConfig});
        end
    end
    etsBillionUSDScenarioName = string(figureScenarioConfig.ETSBillionUSDScenarioName);
    gdpAnchorYear = double(figureScenarioConfig.GDPAnchorYear);
    gdpAnchorBillionUSD = double(figureScenarioConfig.GDPAnchorBillionUSD);
end
if includeEmissionPriceUSDPlot
    requiredPriceConfig = {'EmissionPriceScenarioName', ...
        'EnergyGHGAnchorYear', 'EnergyGHGAnchorMtCO2e', ...
        'ModelEmissionsAnchorYear'};
    for iConfig = 1:numel(requiredPriceConfig)
        if ~isfield(figureScenarioConfig, requiredPriceConfig{iConfig})
            error('generate_finance_simulation_results_figures:emissionPriceConfig', ...
                'Missing figureScenarioConfig.%s.', requiredPriceConfig{iConfig});
        end
    end
    if ~includeETSBillionUSDPlot
        error('generate_finance_simulation_results_figures:emissionPriceMoneyScale', ...
            'IncludeEmissionPriceUSDPlot requires IncludeETSBillionUSDPlot.');
    end
    emissionPriceScenarioName = string( ...
        figureScenarioConfig.EmissionPriceScenarioName);
    energyGHGAnchorYear = double(figureScenarioConfig.EnergyGHGAnchorYear);
    energyGHGAnchorMtCO2e = double( ...
        figureScenarioConfig.EnergyGHGAnchorMtCO2e);
    modelEmissionsAnchorYear = double( ...
        figureScenarioConfig.ModelEmissionsAnchorYear);
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
if isfield(figureScenarioConfig, 'VersionSuffix')
    sversion = string(figureScenarioConfig.VersionSuffix);
else
    sversion = "_replication";
end
if isfield(figureScenarioConfig, 'ScenarioNames')
    scenarioNames = string(figureScenarioConfig.ScenarioNames);
else
    scenarioNames = ["PDP8_GF_A", "PDP8_GF_B", "PDP8_GF_C"];
end
if isfield(figureScenarioConfig, 'ScenarioLabels')
    scenarioLabels = string(figureScenarioConfig.ScenarioLabels);
else
    scenarioLabels = ["PDP8 GF A", "PDP8 GF B", "PDP8 GF C"];
end
if numel(scenarioNames) ~= numel(scenarioLabels)
    error('generate_finance_simulation_results_figures:scenarioConfig', ...
        'ScenarioNames and ScenarioLabels must have the same number of entries.');
end

allNames = [baselineName, scenarioNames];
allData = struct();

for i = 1:numel(allNames)
    sName = allNames(i);
    csvPath = fullfile(outputDir, char(sName + sversion + ".csv"));
    if ~isfile(csvPath)
        error('generate_finance_simulation_results_figures:missingCsv', ...
            'Required CSV not found: %s', csvPath);
    end
    allData.(char(sName)) = readtable(csvPath);
end

requiredVars = ["Year", "Y_1", "I_1", "C_1", "G_1", "NX_1", "IH_1", "PH_1", ...
    "r_F_3_1", "P_K_3_1", "P_INV_3_1", "K_3_1", "I_3_1"];
if includeETSRevenuePlot || includeETSBillionUSDPlot || includeEmissionPriceUSDPlot
    requiredVars = [requiredVars, "P_1", "PE_1", "E_1"];
end
for i = 1:numel(allNames)
    tbl = allData.(char(allNames(i)));
    missing = requiredVars(~ismember(requiredVars, string(tbl.Properties.VariableNames)));
    if ~isempty(missing)
        error('generate_finance_simulation_results_figures:missingVars', ...
            'Missing variable(s) in %s.csv: %s', allNames(i), strjoin(cellstr(missing), ', '));
    end
end

commonYears = allData.Baseline.Year(:);
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    commonYears = intersect(commonYears, s.Year(:));
end
plotYears = plotYears(ismember(plotYears, commonYears));
if isempty(plotYears)
    error('generate_finance_simulation_results_figures:noYears', ...
        'No common years available in requested horizon.');
end

colors = lines(max(4, numel(scenarioNames)));
lineTypes = {'-', '--', '-.', ':'};
lineWidth = 2.0;

baseline = allData.Baseline;
bGDPGrowth = annual_growth(baseline, 'Y_1', plotYears);
bGDPLevel = extract_values(baseline, 'Y_1', plotYears);
bInvShare = level_share(baseline, 'I_1', 'Y_1', plotYears);
bConsShare = level_share(baseline, 'C_1', 'Y_1', plotYears);
bGovConsShare = level_share(baseline, 'G_1', 'Y_1', plotYears);
bHousingInvShare = housing_investment_share(baseline, plotYears);
bNetExportsShare = net_exports_share(baseline, plotYears);
bWacc = renewable_wacc_pct(baseline, plotYears);
bRenewableCapital = extract_values(baseline, 'K_3_1', plotYears);
bRenewableInvestment = extract_values(baseline, 'I_3_1', plotYears);
if includeETSRevenuePlot
    bETSRevenueShare = ets_revenue_gdp_share(baseline, plotYears);
end
if includeETSBillionUSDPlot
    if ~any(scenarioNames == etsBillionUSDScenarioName)
        error('generate_finance_simulation_results_figures:etsScenario', ...
            'ETS billion-dollar scenario "%s" is not in ScenarioNames.', ...
            etsBillionUSDScenarioName);
    end
    anchorPrice = extract_values(baseline, 'P_1', gdpAnchorYear);
    anchorGDP = extract_values(baseline, 'Y_1', gdpAnchorYear);
    if isempty(anchorPrice.Values) || isempty(anchorGDP.Values)
        error('generate_finance_simulation_results_figures:etsAnchorYear', ...
            'Baseline data do not contain GDP anchor year %d.', gdpAnchorYear);
    end
    modelToBillionUSD = gdpAnchorBillionUSD / ...
        (anchorPrice.Values(1) * anchorGDP.Values(1));
end
if includeEmissionPriceUSDPlot
    if ~any(scenarioNames == emissionPriceScenarioName)
        error('generate_finance_simulation_results_figures:emissionPriceScenario', ...
            'Emission-price scenario "%s" is not in ScenarioNames.', ...
            emissionPriceScenarioName);
    end
    anchorModelEmissions = extract_values( ...
        baseline, 'E_1', modelEmissionsAnchorYear);
    if isempty(anchorModelEmissions.Values) || anchorModelEmissions.Values(1) == 0
        error('generate_finance_simulation_results_figures:emissionsAnchorYear', ...
            'Baseline emissions are unavailable or zero in anchor year %d.', ...
            modelEmissionsAnchorYear);
    end
    modelToMtCO2e = energyGHGAnchorMtCO2e / anchorModelEmissions.Values(1);
end

% 1) GDP growth comparison with baseline (levels, %)
fig = make_fig(); hold on;
plot(bGDPGrowth.Years, bGDPGrowth.Values, '-', 'Color', [0.20 0.20 0.20], ...
    'LineWidth', lineWidth, 'DisplayName', 'Baseline');
for i = 1:numel(scenarioNames)
    sName = char(scenarioNames(i));
    sLabel = char(scenarioLabels(i));
    sGDPGrowth = annual_growth(allData.(sName), 'Y_1', plotYears);
    plot(sGDPGrowth.Years, sGDPGrowth.Values, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'Color', colors(i, :), 'LineWidth', lineWidth, 'DisplayName', sLabel);
end
format_axes('GDP Growth Comparison with Baseline', 'Year', 'Percent');
yl = ylim;
ylim([0, yl(2)]);
place_legend_below();
save_dual(fig, outDir, 'GDP_Growth_Comparison_with_Baseline');

% 2) GDP growth deviation from baseline (percentage points)
fig = make_fig(); hold on;
devMat = nan(numel(bGDPGrowth.Years), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    sName = char(scenarioNames(i));
    sLabel = char(scenarioLabels(i));
    sGDPGrowth = annual_growth(allData.(sName), 'Y_1', plotYears);
    d = sGDPGrowth.Values - bGDPGrowth.Values;
    devMat(:, i) = d;
    plot(sGDPGrowth.Years, d, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'Color', colors(i, :), 'LineWidth', lineWidth, 'DisplayName', sLabel);
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('GDP Growth Deviation vs Baseline', 'Year', 'Percentage points');
place_legend_below();
save_dual(fig, outDir, 'GDP_Growth_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'GDP_Growth_Deviation_vs_Baseline', ...
    'GDP Growth Deviation vs Baseline', 'Percentage points', ...
    bGDPGrowth.Years, devMat, scenarioLabels, colors, lineTypes, lineWidth, options);

% 3) GDP level deviation from baseline (% deviation)
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    sName = char(scenarioNames(i));
    sLabel = char(scenarioLabels(i));
    y = extract_values(allData.(sName), 'Y_1', plotYears);
    d = safe_divide(y.Values, bGDPLevel.Values) * 100 - 100;
    devMat(:, i) = d;
    plot(y.Years, d, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'Color', colors(i, :), 'LineWidth', lineWidth, 'DisplayName', sLabel);
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('GDP Level Deviation vs Baseline', 'Year', '% deviation');
place_legend_below();
save_dual(fig, outDir, 'GDP_Level_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'GDP_Level_Deviation_vs_Baseline', ...
    'GDP Level Deviation vs Baseline', '% deviation', ...
    plotYears, devMat, scenarioLabels, colors, lineTypes, lineWidth, options);

% 4) Consumption share deviation from baseline (pp of GDP)
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    sName = char(scenarioNames(i));
    sLabel = char(scenarioLabels(i));
    v = level_share(allData.(sName), 'C_1', 'Y_1', plotYears);
    d = v.Values - bConsShare.Values;
    devMat(:, i) = d;
    plot(v.Years, d, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'Color', colors(i, :), 'LineWidth', lineWidth, 'DisplayName', sLabel);
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Consumption Share Deviation vs Baseline', 'Year', 'pp of GDP');
place_legend_below();
save_dual(fig, outDir, 'Consumption_Share_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Consumption_Share_Deviation_vs_Baseline', ...
    'Consumption Share Deviation vs Baseline', 'pp of GDP', ...
    plotYears, devMat, scenarioLabels, colors, lineTypes, lineWidth, options);

% 5) Investment share deviation from baseline (pp of GDP)
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    sName = char(scenarioNames(i));
    sLabel = char(scenarioLabels(i));
    v = level_share(allData.(sName), 'I_1', 'Y_1', plotYears);
    d = v.Values - bInvShare.Values;
    devMat(:, i) = d;
    plot(v.Years, d, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'Color', colors(i, :), 'LineWidth', lineWidth, 'DisplayName', sLabel);
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Investment Share Deviation vs Baseline', 'Year', 'pp of GDP');
place_legend_below();
save_dual(fig, outDir, 'Investment_Share_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Investment_Share_Deviation_vs_Baseline', ...
    'Investment Share Deviation vs Baseline', 'pp of GDP', ...
    plotYears, devMat, scenarioLabels, colors, lineTypes, lineWidth, options);

% 6) Government consumption share deviation from baseline (pp of GDP)
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    sName = char(scenarioNames(i));
    sLabel = char(scenarioLabels(i));
    v = level_share(allData.(sName), 'G_1', 'Y_1', plotYears);
    d = v.Values - bGovConsShare.Values;
    devMat(:, i) = d;
    plot(v.Years, d, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'Color', colors(i, :), 'LineWidth', lineWidth, 'DisplayName', sLabel);
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Government Consumption Share Deviation vs Baseline', 'Year', 'pp of GDP');
place_legend_below();
save_dual(fig, outDir, 'Government_Consumption_Share_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Government_Consumption_Share_Deviation_vs_Baseline', ...
    'Government Consumption Share Deviation vs Baseline', 'pp of GDP', ...
    plotYears, devMat, scenarioLabels, colors, lineTypes, lineWidth, options);

% 7) Housing investment share deviation from baseline (pp of GDP)
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    sName = char(scenarioNames(i));
    sLabel = char(scenarioLabels(i));
    v = housing_investment_share(allData.(sName), plotYears);
    d = v.Values - bHousingInvShare.Values;
    devMat(:, i) = d;
    plot(v.Years, d, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'Color', colors(i, :), 'LineWidth', lineWidth, 'DisplayName', sLabel);
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Housing Investment Share Deviation vs Baseline', 'Year', 'pp of GDP');
place_legend_below();
save_dual(fig, outDir, 'Housing_Investment_Share_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Housing_Investment_Share_Deviation_vs_Baseline', ...
    'Housing Investment Share Deviation vs Baseline', 'pp of GDP', ...
    plotYears, devMat, scenarioLabels, colors, lineTypes, lineWidth, options);

% 8) Net exports share deviation from baseline (pp of GDP)
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    sName = char(scenarioNames(i));
    sLabel = char(scenarioLabels(i));
    v = net_exports_share(allData.(sName), plotYears);
    d = v.Values - bNetExportsShare.Values;
    devMat(:, i) = d;
    plot(v.Years, d, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'Color', colors(i, :), 'LineWidth', lineWidth, 'DisplayName', sLabel);
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Net Exports Share Deviation vs Baseline', 'Year', 'pp of GDP');
place_legend_below();
save_dual(fig, outDir, 'Net_Exports_Share_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Net_Exports_Share_Deviation_vs_Baseline', ...
    'Net Exports Share Deviation vs Baseline', 'pp of GDP', ...
    plotYears, devMat, scenarioLabels, colors, lineTypes, lineWidth, options);

% 9) WACC comparison with baseline (levels, %)
fig = make_fig(); hold on;
plot(bWacc.Years, bWacc.Values, '-', 'Color', [0.20 0.20 0.20], ...
    'LineWidth', lineWidth, 'DisplayName', 'Baseline');
for i = 1:numel(scenarioNames)
    sName = char(scenarioNames(i));
    sLabel = char(scenarioLabels(i));
    sWacc = renewable_wacc_pct(allData.(sName), plotYears);
    plot(sWacc.Years, sWacc.Values, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'Color', colors(i, :), 'LineWidth', lineWidth, 'DisplayName', sLabel);
end
format_axes('WACC (Renewables) Comparison with Baseline', 'Year', 'Percent');
place_legend_below();
save_dual(fig, outDir, 'WACC_Renewables_Comparison_with_Baseline');

% 10) WACC deviation from baseline (percentage points)
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    sName = char(scenarioNames(i));
    sLabel = char(scenarioLabels(i));
    sWacc = renewable_wacc_pct(allData.(sName), plotYears);
    d = sWacc.Values - bWacc.Values;
    devMat(:, i) = d;
    plot(sWacc.Years, d, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'Color', colors(i, :), 'LineWidth', lineWidth, 'DisplayName', sLabel);
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('WACC (Renewables) Deviation vs Baseline', 'Year', 'Percentage points');
place_legend_below();
save_dual(fig, outDir, 'WACC_Renewables_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'WACC_Renewables_Deviation_vs_Baseline', ...
    'WACC (Renewables) Deviation vs Baseline', 'Percentage points', ...
    plotYears, devMat, scenarioLabels, colors, lineTypes, lineWidth, options);

% 11) Renewable capital deviation from baseline
% Baseline is normalized to 100 in every year, so the plotted difference is
% an index-point deviation (numerically equal to the percentage deviation).
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    sName = char(scenarioNames(i));
    sLabel = char(scenarioLabels(i));
    v = extract_values(allData.(sName), 'K_3_1', plotYears);
    d = safe_divide(v.Values, bRenewableCapital.Values) .* 100 - 100;
    devMat(:, i) = d;
    plot(v.Years, d, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'Color', colors(i, :), 'LineWidth', lineWidth, 'DisplayName', sLabel);
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Renewable Capital Deviation vs Baseline', 'Year', ...
    'Percentage points (Baseline = 100)');
place_legend_below();
save_dual(fig, outDir, 'Renewable_Capital_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Renewable_Capital_Deviation_vs_Baseline', ...
    'Renewable Capital Deviation vs Baseline', ...
    'Percentage points (Baseline = 100)', ...
    plotYears, devMat, scenarioLabels, colors, lineTypes, lineWidth, options);

% 12) Renewable investment deviation from baseline
% Baseline is normalized to 100 in every year, so the plotted difference is
% an index-point deviation (numerically equal to the percentage deviation).
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    sName = char(scenarioNames(i));
    sLabel = char(scenarioLabels(i));
    v = extract_values(allData.(sName), 'I_3_1', plotYears);
    d = safe_divide(v.Values, bRenewableInvestment.Values) .* 100 - 100;
    devMat(:, i) = d;
    plot(v.Years, d, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'Color', colors(i, :), 'LineWidth', lineWidth, 'DisplayName', sLabel);
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Renewable Investment Deviation vs Baseline', 'Year', ...
    'Percentage points (Baseline = 100)');
place_legend_below();
save_dual(fig, outDir, 'Renewable_Investment_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Renewable_Investment_Deviation_vs_Baseline', ...
    'Renewable Investment Deviation vs Baseline', ...
    'Percentage points (Baseline = 100)', ...
    plotYears, devMat, scenarioLabels, colors, lineTypes, lineWidth, options);

% 13) ETS revenue share deviation from baseline (pp of GDP)
if includeETSRevenuePlot
    fig = make_fig(); hold on;
    devMat = nan(numel(plotYears), numel(scenarioNames));
    for i = 1:numel(scenarioNames)
        sName = char(scenarioNames(i));
        sLabel = char(scenarioLabels(i));
        v = ets_revenue_gdp_share(allData.(sName), plotYears);
        d = v.Values - bETSRevenueShare.Values;
        devMat(:, i) = d;
        plot(v.Years, d, ...
            'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
            'Color', colors(i, :), 'LineWidth', lineWidth, 'DisplayName', sLabel);
    end
    yline(0, ':', 'Color', [0.45 0.45 0.45], ...
        'LineWidth', 1.0, 'HandleVisibility', 'off');
    format_axes('ETS Revenue Share Deviation vs Baseline', 'Year', ...
        'Percentage points of GDP');
    place_legend_below();
    save_dual(fig, outDir, 'ETS_Revenue_Share_Deviation_vs_Baseline');
    maybe_save_five_year_summaries(outDir, ...
        'ETS_Revenue_Share_Deviation_vs_Baseline', ...
        'ETS Revenue Share Deviation vs Baseline', ...
        'Percentage points of GDP', ...
        plotYears, devMat, scenarioLabels, colors, lineTypes, lineWidth, options);
end

% 14) ETS revenue levels in USD billion for Baseline and selected scenario
if includeETSBillionUSDPlot
    fig = make_fig(); hold on;
    bETSRevenueUSD = ets_revenue_billion_usd( ...
        baseline, plotYears, modelToBillionUSD);
    plot(bETSRevenueUSD.Years, bETSRevenueUSD.Values, '-', ...
        'Color', [0.20 0.20 0.20], 'LineWidth', lineWidth, ...
        'DisplayName', 'Baseline');

    iETSScenario = find(scenarioNames == etsBillionUSDScenarioName, 1, 'first');
    sName = char(scenarioNames(iETSScenario));
    sLabel = char(scenarioLabels(iETSScenario));
    sETSRevenueUSD = ets_revenue_billion_usd( ...
        allData.(sName), plotYears, modelToBillionUSD);
    plot(sETSRevenueUSD.Years, sETSRevenueUSD.Values, ...
        'LineStyle', lineTypes{mod(iETSScenario-1, numel(lineTypes)) + 1}, ...
        'Color', colors(iETSScenario, :), 'LineWidth', lineWidth, ...
        'DisplayName', sLabel);

    format_axes(sprintf( ...
        'ETS Revenues: Baseline vs %s (2025 GDP anchor: USD %.1f bn)', ...
        sLabel, gdpAnchorBillionUSD), ...
        'Year', 'USD billion');
    place_legend_below();
    save_dual(fig, outDir, 'ETS_Revenue_Billion_USD_Baseline_vs_NZ');

    % Sum annual ETS revenues within consecutive five-year periods for the
    % Baseline and every configured scenario.
    [periodLabels, bETSCumulativeUSD] = five_year_sum_blocks( ...
        bETSRevenueUSD.Years, bETSRevenueUSD.Values, options.FiveYearBlockSize);

    fig = make_fig();
    cumulativeMat = nan(numel(periodLabels), numel(scenarioNames) + 1);
    cumulativeMat(:, 1) = bETSCumulativeUSD;
    for i = 1:numel(scenarioNames)
        cumulativeScenario = ets_revenue_billion_usd( ...
            allData.(char(scenarioNames(i))), plotYears, modelToBillionUSD);
        [~, cumulativeMat(:, i + 1)] = five_year_sum_blocks( ...
            cumulativeScenario.Years, cumulativeScenario.Values, ...
            options.FiveYearBlockSize);
    end
    cumulativeLabels = ["Baseline", scenarioLabels];
    cumulativeColors = [[0.20 0.20 0.20]; colors(1:numel(scenarioNames), :)];
    plot_grouped_period_bars( ...
        cumulativeMat, periodLabels, cumulativeLabels, cumulativeColors);
    format_axes( ...
        'Five-Year Cumulative ETS Revenues by Net-Zero Scenario', ...
        'Time period', 'USD billion per five-year period');
    place_legend_below();
    save_dual(fig, outDir, ...
        'ETS_Revenue_5Y_Cumulative_Billion_USD_NZ_Scenarios');
end

% 15) Implied emission price in USD/tCO2e for Baseline and selected scenario
if includeEmissionPriceUSDPlot
    fig = make_fig(); hold on;
    bEmissionPriceUSD = emission_price_usd_per_tco2e( ...
        baseline, plotYears, modelToBillionUSD, modelToMtCO2e);
    plot(bEmissionPriceUSD.Years, bEmissionPriceUSD.Values, '-', ...
        'Color', [0.20 0.20 0.20], 'LineWidth', lineWidth, ...
        'DisplayName', 'Baseline');

    iPriceScenario = find( ...
        scenarioNames == emissionPriceScenarioName, 1, 'first');
    sName = char(scenarioNames(iPriceScenario));
    sLabel = char(scenarioLabels(iPriceScenario));
    sEmissionPriceUSD = emission_price_usd_per_tco2e( ...
        allData.(sName), plotYears, modelToBillionUSD, modelToMtCO2e);
    plot(sEmissionPriceUSD.Years, sEmissionPriceUSD.Values, ...
        'LineStyle', lineTypes{mod(iPriceScenario-1, numel(lineTypes)) + 1}, ...
        'Color', colors(iPriceScenario, :), 'LineWidth', lineWidth, ...
        'DisplayName', sLabel);

    format_axes(sprintf( ...
        ['Implied Emission Price: Baseline vs %s ' ...
         '(energy-GHG anchor: %.1f MtCO2e, %d)'], ...
        sLabel, energyGHGAnchorMtCO2e, energyGHGAnchorYear), ...
        'Year', 'USD per tCO2e');
    place_legend_below();
    save_dual(fig, outDir, ...
        'Emission_Price_USD_per_tCO2e_Baseline_vs_NZ');
end

fprintf('Generated %s figures in: %s\n', reportLabel, outDir);
clear figureScenarioConfig;



%% Local functions

function fig = make_fig()
    fig = figure('Color', 'w', 'Position', [80 80 1000 560]);
end

function format_axes(plotTitle, xLabelText, yLabelText)
    grid on;
    box off;
    xlabel(xLabelText);
    ylabel(yLabelText);
    title(plotTitle, 'Interpreter', 'none');
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
            warning('generate_finance_simulation_results_figures:svgExportFailed', ...
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
            warning('generate_finance_simulation_results_figures:pngExportFailed', ...
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

function out = renewable_wacc_pct(tbl, years)
    rf = extract_values(tbl, 'r_F_3_1', years);
    pk = extract_values(tbl, 'P_K_3_1', years);
    pinv = extract_values(tbl, 'P_INV_3_1', years);

    lagPinv = [pinv.Values(1); pinv.Values(1:end-1)];
    vals = safe_divide(rf.Values .* pk.Values, lagPinv) .* 100;

    out.Years = rf.Years;
    out.Values = vals;
end

function out = ets_revenue_gdp_share(tbl, years)
    pe = extract_values(tbl, 'PE_1', years);
    emissions = extract_values(tbl, 'E_1', years);
    price = extract_values(tbl, 'P_1', years);
    gdp = extract_values(tbl, 'Y_1', years);

    out.Years = gdp.Years;
    out.Values = safe_divide(pe.Values .* emissions.Values, ...
        price.Values .* gdp.Values) .* 100;
end

function out = ets_revenue_billion_usd(tbl, years, modelToBillionUSD)
    pe = extract_values(tbl, 'PE_1', years);
    emissions = extract_values(tbl, 'E_1', years);

    out.Years = pe.Years;
    out.Values = pe.Values .* emissions.Values .* modelToBillionUSD;
end

function out = emission_price_usd_per_tco2e( ...
    tbl, years, modelToBillionUSD, modelToMtCO2e)
    pe = extract_values(tbl, 'PE_1', years);

    % One USD billion per MtCO2e equals USD 1,000 per tCO2e.
    out.Years = pe.Years;
    out.Values = pe.Values .* modelToBillionUSD ./ modelToMtCO2e .* 1000;
end

function z = safe_divide(a, b)
    z = a ./ b;
    z(~isfinite(z)) = NaN;
end

function maybe_save_five_year_summaries(outDir, stem, metricTitle, yLabel, years, devMat, ...
    scenarioLabels, colors, ~, ~, options)
    if ~options.ShowFiveYearAverageDeviation && ~options.ShowFiveYearIntervalChange
        return
    end

    [periodLabels, avgMat, deltaMat] = five_year_deviation_blocks(years, devMat, options.FiveYearBlockSize);

    if options.ShowFiveYearAverageDeviation
        fig = make_fig();
        plot_grouped_period_bars(avgMat, periodLabels, scenarioLabels, colors);
        yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
        format_axes([metricTitle ' - 5-year average deviation'], 'Time period', yLabel);
        place_legend_below();
        save_dual(fig, outDir, [stem '_5Y_Average']);
    end

    if options.ShowFiveYearIntervalChange
        fig = make_fig();
        plot_grouped_period_bars(deltaMat, periodLabels, scenarioLabels, colors);
        yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
        format_axes([metricTitle ' - change vs previous 5-year block'], 'Time period', [yLabel ' change']);
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

function [periodLabels, sumMat] = five_year_sum_blocks(years, valueMat, blockSize)
    years = years(:);
    nBlocks = floor(numel(years) / blockSize);

    periodLabels = strings(nBlocks, 1);
    sumMat = nan(nBlocks, size(valueMat, 2));

    for b = 1:nBlocks
        idxStart = (b - 1) * blockSize + 1;
        idxEnd = b * blockSize;
        idx = idxStart:idxEnd;

        periodLabels(b) = string(years(idxStart)) + "-" + string(years(idxEnd));
        sumMat(b, :) = sum(valueMat(idx, :), 1, 'omitnan');
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
