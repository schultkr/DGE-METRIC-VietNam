%% Generate finance-scenario figures used for reporting and slides
% Produces baseline-vs-scenario charts for:
%   - GDP growth
%   - WACC (renewables sector)
%
% Output:
%   docs/figures/Finance_Simulation_Results/*.svg and *.png

clearvars; close all; clc;

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

outputDir = fullfile(repoRoot, 'ExcelFiles', 'Output');
outDir = fullfile(repoRoot, 'docs', 'figures', 'Finance_Simulation_Results');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

plotYears = (2025:2050)';

options = struct();
options.ShowFiveYearGroupedBars = true;
options.FiveYearBlockSize = 5;

baselineName = "Baseline";
scenarioSpecs = table( ...
    ["PDP8_GF_A"; "PDP8_GF_B"; "PDP8_GF_C"], ...
    ["PDP8 GF A"; "PDP8 GF B"; "PDP8 GF C"], ...
    'VariableNames', {'Name', 'Label'});

allNames = [baselineName; scenarioSpecs.Name];
allData = struct();

for i = 1:numel(allNames)
    sName = allNames(i);
    csvPath = fullfile(outputDir, char(sName + ".csv"));
    if ~isfile(csvPath)
        error('GenerateFinanceSimulationResultsFigures:missingCsv', ...
            'Required CSV not found: %s', csvPath);
    end
    allData.(char(sName)) = readtable(csvPath);
end

requiredVars = ["Year", "Y_1", "r_F_3_1", "P_K_3_1", "P_INV_3_1"];
for i = 1:numel(allNames)
    tbl = allData.(char(allNames(i)));
    missing = requiredVars(~ismember(requiredVars, string(tbl.Properties.VariableNames)));
    if ~isempty(missing)
        error('GenerateFinanceSimulationResultsFigures:missingVars', ...
            'Missing variable(s) in %s.csv: %s', allNames(i), strjoin(cellstr(missing), ', '));
    end
end

commonYears = allData.Baseline.Year(:);
for i = 1:height(scenarioSpecs)
    s = allData.(char(scenarioSpecs.Name(i)));
    commonYears = intersect(commonYears, s.Year(:));
end
plotYears = plotYears(ismember(plotYears, commonYears));
if isempty(plotYears)
    error('GenerateFinanceSimulationResultsFigures:noYears', ...
        'No common years available in requested horizon.');
end

colors = lines(max(3, height(scenarioSpecs)));
lineTypes = {'-', '--', '-.', ':'};
lineWidth = 2.0;

baseline = allData.Baseline;
bGDPGrowth = annual_growth_pct(baseline, 'Y_1', plotYears);
bWacc = renewable_wacc_pct(baseline, plotYears);

% 1) GDP growth comparison with baseline (levels, %)
fig = make_fig(); hold on;
plot(bGDPGrowth.Years, bGDPGrowth.Values, '-', 'Color', [0.20 0.20 0.20], ...
    'LineWidth', lineWidth, 'DisplayName', 'Baseline');
for i = 1:height(scenarioSpecs)
    sName = char(scenarioSpecs.Name(i));
    sLabel = char(scenarioSpecs.Label(i));
    sGDPGrowth = annual_growth_pct(allData.(sName), 'Y_1', plotYears);
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
devMat = nan(numel(plotYears), height(scenarioSpecs));
for i = 1:height(scenarioSpecs)
    sName = char(scenarioSpecs.Name(i));
    sLabel = char(scenarioSpecs.Label(i));
    sGDPGrowth = annual_growth_pct(allData.(sName), 'Y_1', plotYears);
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
maybe_save_five_year_grouped_bars(outDir, 'GDP_Growth_Deviation_vs_Baseline', ...
    'GDP Growth Deviation vs Baseline', 'Percentage points', ...
    plotYears, devMat, string(scenarioSpecs.Label), colors, options);

% 3) WACC comparison with baseline (levels, %)
fig = make_fig(); hold on;
plot(bWacc.Years, bWacc.Values, '-', 'Color', [0.20 0.20 0.20], ...
    'LineWidth', lineWidth, 'DisplayName', 'Baseline');
for i = 1:height(scenarioSpecs)
    sName = char(scenarioSpecs.Name(i));
    sLabel = char(scenarioSpecs.Label(i));
    sWacc = renewable_wacc_pct(allData.(sName), plotYears);
    plot(sWacc.Years, sWacc.Values, ...
        'LineStyle', lineTypes{mod(i-1, numel(lineTypes)) + 1}, ...
        'Color', colors(i, :), 'LineWidth', lineWidth, 'DisplayName', sLabel);
end
format_axes('WACC (Renewables) Comparison with Baseline', 'Year', 'Percent');
place_legend_below();
save_dual(fig, outDir, 'WACC_Renewables_Comparison_with_Baseline');

% 4) WACC deviation from baseline (percentage points)
fig = make_fig(); hold on;
devMat = nan(numel(plotYears), height(scenarioSpecs));
for i = 1:height(scenarioSpecs)
    sName = char(scenarioSpecs.Name(i));
    sLabel = char(scenarioSpecs.Label(i));
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
maybe_save_five_year_grouped_bars(outDir, 'WACC_Renewables_Deviation_vs_Baseline', ...
    'WACC (Renewables) Deviation vs Baseline', 'Percentage points', ...
    plotYears, devMat, string(scenarioSpecs.Label), colors, options);

fprintf('Generated finance scenario figures in: %s\n', outDir);

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
            warning('GenerateFinanceSimulationResultsFigures:svgExportFailed', ...
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

function out = annual_growth_pct(tbl, varName, years)
    y = extract_values(tbl, varName, years);
    n = numel(y.Values);
    vals = nan(n, 1);
    if n > 1
        vals(2:end) = (y.Values(2:end) ./ y.Values(1:end-1) - 1) .* 100;
    end
    out.Years = y.Years;
    out.Values = vals;
end

function out = renewable_wacc_pct(tbl, years)
    rf = extract_values(tbl, 'r_F_3_1', years);
    pk = extract_values(tbl, 'P_K_3_1', years);
    pinv = extract_values(tbl, 'P_INV_3_1', years);

    lagPinv = [pinv.Values(1); pinv.Values(1:end-1)];
    vals = (rf.Values .* pk.Values ./ lagPinv) .* 100;

    out.Years = rf.Years;
    out.Values = vals;
end

function maybe_save_five_year_grouped_bars(outDir, stem, metricTitle, yLabel, ...
    years, valuesMat, scenarioLabels, colors, options)
    if ~options.ShowFiveYearGroupedBars
        return
    end

    [periodLabels, avgMat] = five_year_blocks_average(years, valuesMat, options.FiveYearBlockSize);

    fig = make_fig();
    plot_grouped_period_bars(avgMat, periodLabels, scenarioLabels, colors);
    yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
    format_axes([metricTitle ' - 5-year averages'], 'Time period', yLabel);
    place_legend_below();
    save_dual(fig, outDir, [stem '_5Y_Average']);
end

function [periodLabels, avgMat] = five_year_blocks_average(years, valuesMat, blockSize)
    years = years(:);
    nBlocks = floor(numel(years) / blockSize);

    periodLabels = strings(nBlocks, 1);
    avgMat = nan(nBlocks, size(valuesMat, 2));

    for b = 1:nBlocks
        idxStart = (b - 1) * blockSize + 1;
        idxEnd = b * blockSize;
        idx = idxStart:idxEnd;

        periodLabels(b) = string(years(idxStart)) + "-" + string(years(idxEnd));
        avgMat(b, :) = mean(valuesMat(idx, :), 1, 'omitnan');
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
