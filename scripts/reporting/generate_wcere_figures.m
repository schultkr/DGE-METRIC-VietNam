%% Generate EE simulation-result figures used by the TeX presentation
% Regenerates the exact figure filenames consumed by
% docs/EE_Scenario_Presentation/ee_scenarios_presentation.tex.

clearvars; close all; clc;

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

outDir = fullfile(repoRoot, 'docs', 'figures', 'EE_Simulation_Results');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

plotYears = 2026:2050;

options = struct();
options.ShowFiveYearAverageDeviation = true;
options.ShowFiveYearIntervalChange = true;
options.FiveYearBlockSize = 5;

baselineName = "Baseline";
scenarioNames = ["EE_Directive10", "EE_Directive10_NoBESS", "EE_PDP8_PV_BESS_NoBESS"];
scenarioLabels = ["EE Directive 10", "EE Directive 10 no BESS", "EE PDP8 PV + no BESS"];

allNames = [baselineName, scenarioNames];
allData = struct();

for i = 1:numel(allNames)
    name = allNames(i);
    csvPath = fullfile(repoRoot, 'ExcelFiles', 'Output', name + ".csv");
    if ~isfile(csvPath)
        error('generate_ee_simulation_results_figures:missingCsv', ...
            'Required CSV not found: %s', csvPath);
    end
    allData.(char(name)) = readtable(csvPath);
end

requiredVars = ["Year", "Y_1", "I_1", "C_1", "Q_A_2_1", "Q_PV_1", "Q_A_F_2_1", "P_A_2_1", "E_1"];
for i = 1:numel(allNames)
    tbl = allData.(char(allNames(i)));
    missing = requiredVars(~ismember(requiredVars, string(tbl.Properties.VariableNames)));
    if ~isempty(missing)
        error('generate_ee_simulation_results_figures:missingVars', ...
            'Missing variable(s) in %s.csv: %s', allNames(i), strjoin(cellstr(missing), ', '));
    end
end

% Keep only common years available across all required files.
commonYears = allData.Baseline.Year(:);
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
baseline = allData.Baseline;
bGDPGrowth = annual_growth(baseline, 'Y_1', plotYears);
bInvShare = level_share(baseline, 'I_1', 'Y_1', plotYears);
bConsShare = level_share(baseline, 'C_1', 'Y_1', plotYears);
bEnergyIntensity = energy_intensity_index(baseline, plotYears);
bEnergyPrices = energy_price_index(baseline, plotYears);
bFinalDemand = final_energy_demand_index(baseline, plotYears);
bFinalDemandGrid = grid_final_energy_demand_index(baseline, plotYears);
bFinalDemandPV = pv_final_energy_demand_index(baseline, plotYears);
bGDPLevel = extract_values(baseline, 'Y_1', plotYears);

colors = lines(max(4, numel(scenarioNames)));
lineTypes = {'-', '--', '-.', ':'};
lineWidth = 2.0;

% 1) GDP growth comparison with baseline.
fig = make_fig();
hold on;
plot(bGDPGrowth.Years, bGDPGrowth.Values, 'Color', [0.20 0.20 0.20], ...
    'LineWidth', lineWidth, 'LineStyle', '-', 'DisplayName', 'Baseline');
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    g = annual_growth(s, 'Y_1', plotYears);
    plot(g.Years, g.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('GDP Growth Comparison with Baseline', 'Year', '%');
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
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Investment Share of GDP', 'Year', '% of GDP');
place_legend_below();
save_dual(fig, outDir, 'Investment_Share_GDP');

% 3) Consumption share of GDP.
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = level_share(s, 'C_1', 'Y_1', plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Consumption Share of GDP', 'Year', '% of GDP');
place_legend_below();
save_dual(fig, outDir, 'Consumption_Share_GDP');

% 4) Energy intensity index.
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = energy_intensity_index(s, plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Energy Intensity Index', 'Year', 'Index (2026 = 100)');
place_legend_below();
save_dual(fig, outDir, 'Energy_Intensity_Index');

% 5) Energy prices index.
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = energy_price_index(s, plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Energy Prices Index', 'Year', 'Index (2026 = 100)');
place_legend_below();
save_dual(fig, outDir, 'Energy_Prices_Index');

% 6) Final energy demand index.
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = final_energy_demand_index(s, plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Final Energy Demand Index', 'Year', 'Index (2026 = 100)');
place_legend_below();
save_dual(fig, outDir, 'Final_Energy_Demand_Index');

% 6b) Final energy demand index (grid-provided).
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = grid_final_energy_demand_index(s, plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Final Energy Demand Index (Grid-provided)', 'Year', 'Index (2026 = 100)');
place_legend_below();
save_dual(fig, outDir, 'Final_Energy_Demand_Grid_Index');

% 6c) Final energy demand index (PV-provided).
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = pv_final_energy_demand_index(s, plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Final Energy Demand Index (PV-provided)', 'Year', 'Index (2026 = 100)');
place_legend_below();
save_dual(fig, outDir, 'Final_Energy_Demand_PV_Index');

% 7) Emissions index.
fig = make_fig(); hold on;
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = emissions_index(s, plotYears);
    plot(v.Years, v.Values, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
format_axes('Emissions Index', 'Year', 'Index (2026 = 100)');
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
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('GDP Level Deviation vs Baseline', 'Year', '% deviation');
place_legend_below();
save_dual(fig, outDir, 'GDP_Level_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'GDP_Level_Deviation_vs_Baseline', ...
    'GDP Level Deviation vs Baseline', '% deviation', plotYears, devMat, ...
    scenarioLabels, colors, lineTypes, lineWidth, options);

% 9) Investment share deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = level_share(s, 'I_1', 'Y_1', plotYears);
    d = v.Values - bInvShare.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Investment Share Deviation vs Baseline', 'Year', 'pp of GDP');
place_legend_below();
save_dual(fig, outDir, 'Investment_Share_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Investment_Share_Deviation_vs_Baseline', ...
    'Investment Share Deviation vs Baseline', 'pp of GDP', plotYears, devMat, ...
    scenarioLabels, colors, lineTypes, lineWidth, options);

% 10) Consumption share deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = level_share(s, 'C_1', 'Y_1', plotYears);
    d = v.Values - bConsShare.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Consumption Share Deviation vs Baseline', 'Year', 'pp of GDP');
place_legend_below();
save_dual(fig, outDir, 'Consumption_Share_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Consumption_Share_Deviation_vs_Baseline', ...
    'Consumption Share Deviation vs Baseline', 'pp of GDP', plotYears, devMat, ...
    scenarioLabels, colors, lineTypes, lineWidth, options);

% 11) Energy intensity deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = energy_intensity_index(s, plotYears);
    d = v.Values - bEnergyIntensity.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Energy Intensity Deviation vs Baseline', 'Year', 'Index points');
place_legend_below();
save_dual(fig, outDir, 'Energy_Intensity_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Energy_Intensity_Deviation_vs_Baseline', ...
    'Energy Intensity Deviation vs Baseline', 'Index points', plotYears, devMat, ...
    scenarioLabels, colors, lineTypes, lineWidth, options);

% 12) Energy prices deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = energy_price_index(s, plotYears);
    d = v.Values - bEnergyPrices.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Energy Prices Deviation vs Baseline', 'Year', 'Index points');
place_legend_below();
save_dual(fig, outDir, 'Energy_Prices_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Energy_Prices_Deviation_vs_Baseline', ...
    'Energy Prices Deviation vs Baseline', 'Index points', plotYears, devMat, ...
    scenarioLabels, colors, lineTypes, lineWidth, options);

% 13) Final energy demand deviation vs baseline.
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = final_energy_demand_index(s, plotYears);
    d = v.Values - bFinalDemand.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Final Energy Demand Deviation vs Baseline', 'Year', 'Index points');
place_legend_below();
save_dual(fig, outDir, 'Final_Energy_Demand_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Final_Energy_Demand_Deviation_vs_Baseline', ...
    'Final Energy Demand Deviation vs Baseline', 'Index points', plotYears, devMat, ...
    scenarioLabels, colors, lineTypes, lineWidth, options);

% 13b) Final energy demand deviation vs baseline (grid-provided).
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = grid_final_energy_demand_index(s, plotYears);
    d = v.Values - bFinalDemandGrid.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Final Energy Demand Deviation vs Baseline (Grid-provided)', 'Year', 'Index points');
place_legend_below();
save_dual(fig, outDir, 'Final_Energy_Demand_Grid_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Final_Energy_Demand_Grid_Deviation_vs_Baseline', ...
    'Final Energy Demand Deviation vs Baseline (Grid-provided)', 'Index points', plotYears, devMat, ...
    scenarioLabels, colors, lineTypes, lineWidth, options);

% 13c) Final energy demand deviation vs baseline (PV-provided).
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), numel(scenarioNames));
for i = 1:numel(scenarioNames)
    s = allData.(char(scenarioNames(i)));
    v = pv_final_energy_demand_index(s, plotYears);
    d = v.Values - bFinalDemandPV.Values;
    devMat(:, i) = d;
    plot(v.Years, d, 'Color', colors(i, :), 'LineWidth', lineWidth, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'DisplayName', char(scenarioLabels(i)));
end
yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
format_axes('Final Energy Demand Deviation vs Baseline (PV-provided)', 'Year', 'Index points');
place_legend_below();
save_dual(fig, outDir, 'Final_Energy_Demand_PV_Deviation_vs_Baseline');
maybe_save_five_year_summaries(outDir, 'Final_Energy_Demand_PV_Deviation_vs_Baseline', ...
    'Final Energy Demand Deviation vs Baseline (PV-provided)', 'Index points', plotYears, devMat, ...
    scenarioLabels, colors, lineTypes, lineWidth, options);

fprintf('Generated EE presentation figures in: %s\n', outDir);

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
            warning('generate_ee_simulation_results_figures:svgExportFailed', ...
                ['SVG export failed for "%s". Continuing with PNG only. ' ...
                 'exportgraphics error: %s | print error: %s'], ...
                stem, meSvg.message, mePrint.message);
        end
    end

    exportgraphics(fig, pngPath, 'Resolution', 300);
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

function out = emissions_index(tbl, years)
    e = extract_values(tbl, 'E_1', years);
    out.Years = e.Years;
    out.Values = safe_divide(e.Values, e.Values(1)) .* 100;
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
