%% Generate Baseline vs Net-Zero ETS revenue and CO2 price figures
% Three annual charts (plus a 5-year-average bar chart each) comparing the
% Baseline and NZ scenarios, matching the color palette and figure style
% used by generate_ee_simulation_results_figures.m (iwh_colors,
% make_fig/format_axes/place_legend_below/save_dual helpers):
%   - ETS revenue, USD billion
%   - ETS revenue, share of GDP
%   - Implied CO2 (emissions) price, USD per tCO2e
%
% Dollar conversion uses the same anchors as the existing NZ/finance
% reporting pipeline (generate_nz_simulation_results_figures.m) so the
% levels are consistent with the ETS figures already published under
% docs/figures/NZ_Simulation_Results:
%   - GDP anchor: USD 514.7 bn in 2025
%   - Energy-related GHG anchor: 352.8946 MtCO2e in 2023 (EDGAR: Power
%     Industry + Industrial Combustion + Transport + Buildings +
%     Fuel Exploitation), mapped onto the model's 2025 emissions level.
%
% Input:
%   ExcelFiles/Output/Baseline.csv
%   ExcelFiles/Output/NZ_Dir10_full_GF_C.csv
%   ("" is the sSensitivity suffix RunSimulations.m currently
%   writes by default; report_version_suffix() returns it, so both files
%   come from the same run. Override with DGE_WORKBOOK_VERSION.)
%
% Output:
%   docs/figures/Baseline_Simulation_Results/*.svg and *.png

clearvars; close all; clc;

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

outDir = fullfile(repoRoot, 'docs', 'figures', 'Baseline_Simulation_Results');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

plotYears = 2026:2050;

sversion = report_version_suffix();  % "" unless DGE_WORKBOOK_VERSION overrides
scenarioName = "NZ_Dir10_full_GF_C";
scenarioLabel = "Net Zero";

gdpAnchorYear = 2025;
gdpAnchorBillionUSD = 514.7;
energyGHGAnchorYear = 2023;
energyGHGAnchorMtCO2e = 352.894603746534;
modelEmissionsAnchorYear = 2025;

allNames = ["Baseline", scenarioName];
allData = struct();
for i = 1:numel(allNames)
    name = allNames(i);
    csvPath = fullfile(repoRoot, 'ExcelFiles', 'Output', name + sversion + ".csv");
    if ~isfile(csvPath)
        error('generate_baseline_co2_ets_figures:missingCsv', ...
            'Required CSV not found: %s', csvPath);
    end
    allData.(char(name)) = readtable(csvPath);
end

requiredVars = ["Year", "Y_1", "P_1", "PE_1", "E_1"];
for i = 1:numel(allNames)
    tbl = allData.(char(allNames(i)));
    missing = requiredVars(~ismember(requiredVars, string(tbl.Properties.VariableNames)));
    if ~isempty(missing)
        error('generate_baseline_co2_ets_figures:missingVars', ...
            'Missing variable(s) in %s%s.csv: %s', allNames(i), sversion, strjoin(cellstr(missing), ', '));
    end
end

baseline = allData.Baseline;
scenario = allData.(char(scenarioName));

commonYears = intersect(baseline.Year(:), scenario.Year(:));
plotYears = plotYears(ismember(plotYears, commonYears));
if isempty(plotYears)
    error('generate_baseline_co2_ets_figures:noYears', ...
        'No common years found in requested plotting horizon.');
end

scenarioStyle = iwh_scenario_style(scenarioName);
colors = reshape([scenarioStyle.Color], 3, [])';   % keeps existing colors(1,:) call sites unchanged
lineWidth = 2.0;
fiveYearBlockSize = 5;
barColors = [iwh_colors().baseline; colors(1, :)];
seriesLabels = ["Baseline", scenarioLabel];

anchorPrice = extract_values(baseline, 'P_1', gdpAnchorYear);
anchorGDP = extract_values(baseline, 'Y_1', gdpAnchorYear);
if isempty(anchorPrice.Values) || isempty(anchorGDP.Values)
    error('generate_baseline_co2_ets_figures:gdpAnchorYear', ...
        'Baseline data do not contain GDP anchor year %d.', gdpAnchorYear);
end
modelToBillionUSD = gdpAnchorBillionUSD / (anchorPrice.Values(1) * anchorGDP.Values(1));

anchorModelEmissions = extract_values(baseline, 'E_1', modelEmissionsAnchorYear);
if isempty(anchorModelEmissions.Values) || anchorModelEmissions.Values(1) == 0
    error('generate_baseline_co2_ets_figures:emissionsAnchorYear', ...
        'Baseline emissions are unavailable or zero in anchor year %d.', ...
        modelEmissionsAnchorYear);
end
modelToMtCO2e = energyGHGAnchorMtCO2e / anchorModelEmissions.Values(1);

% 1) ETS revenue, USD billion.
bETSRevenueUSD = ets_revenue_billion_usd(baseline, plotYears, modelToBillionUSD);
sETSRevenueUSD = ets_revenue_billion_usd(scenario, plotYears, modelToBillionUSD);
fig = make_fig(); hold on;
plot(bETSRevenueUSD.Years, bETSRevenueUSD.Values, '-', ...
    'Color', iwh_colors().baseline, 'LineWidth', lineWidth, 'DisplayName', 'Baseline');
plot(sETSRevenueUSD.Years, sETSRevenueUSD.Values, '--', ...
    'Color', colors(1, :), 'LineWidth', lineWidth, 'DisplayName', char(scenarioLabel));
format_axes(sprintf('ETS Revenues: Baseline vs %s', scenarioLabel), 'USD billion');
place_legend_below();
save_dual(fig, outDir, 'ETS_Revenue_Billion_USD_Baseline_vs_NZ');
save_five_year_average_bars(outDir, 'ETS_Revenue_Billion_USD_Baseline_vs_NZ', ...
    'ETS Revenues: Baseline vs Net Zero', 'USD billion', plotYears, ...
    [bETSRevenueUSD.Values, sETSRevenueUSD.Values], seriesLabels, barColors, fiveYearBlockSize);

% 2) ETS revenue, share of GDP.
bETSRevenueShare = ets_revenue_gdp_share(baseline, plotYears);
sETSRevenueShare = ets_revenue_gdp_share(scenario, plotYears);
fig = make_fig(); hold on;
plot(bETSRevenueShare.Years, bETSRevenueShare.Values, '-', ...
    'Color', iwh_colors().baseline, 'LineWidth', lineWidth, 'DisplayName', 'Baseline');
plot(sETSRevenueShare.Years, sETSRevenueShare.Values, '--', ...
    'Color', colors(1, :), 'LineWidth', lineWidth, 'DisplayName', char(scenarioLabel));
format_axes(sprintf('ETS Revenue Share of GDP: Baseline vs %s', scenarioLabel), ...
    '% of GDP');
place_legend_below();
save_dual(fig, outDir, 'ETS_Revenue_Share_GDP_Baseline_vs_NZ');
save_five_year_average_bars(outDir, 'ETS_Revenue_Share_GDP_Baseline_vs_NZ', ...
    'ETS Revenue Share of GDP: Baseline vs Net Zero', '% of GDP', plotYears, ...
    [bETSRevenueShare.Values, sETSRevenueShare.Values], seriesLabels, barColors, fiveYearBlockSize);

% 3) Implied CO2 price, USD per tCO2e.
bEmissionPriceUSD = emission_price_usd_per_tco2e(baseline, plotYears, modelToBillionUSD, modelToMtCO2e);
sEmissionPriceUSD = emission_price_usd_per_tco2e(scenario, plotYears, modelToBillionUSD, modelToMtCO2e);
fig = make_fig(); hold on;
plot(bEmissionPriceUSD.Years, bEmissionPriceUSD.Values, '-', ...
    'Color', iwh_colors().baseline, 'LineWidth', lineWidth, 'DisplayName', 'Baseline');
plot(sEmissionPriceUSD.Years, sEmissionPriceUSD.Values, '--', ...
    'Color', colors(1, :), 'LineWidth', lineWidth, 'DisplayName', char(scenarioLabel));
format_axes(sprintf('Implied CO2 Price: Baseline vs %s', scenarioLabel), 'USD per tCO2e');
place_legend_below();
save_dual(fig, outDir, 'CO2_Price_USD_per_tCO2e_Baseline_vs_NZ');
save_five_year_average_bars(outDir, 'CO2_Price_USD_per_tCO2e_Baseline_vs_NZ', ...
    'Implied CO2 Price: Baseline vs Net Zero', 'USD per tCO2e', plotYears, ...
    [bEmissionPriceUSD.Values, sEmissionPriceUSD.Values], seriesLabels, barColors, fiveYearBlockSize);

fprintf('Generated Baseline vs NZ ETS revenue and CO2 price figures in: %s\n', outDir);

%% Local functions

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
            warning('generate_baseline_co2_ets_figures:svgExportFailed', ...
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
            warning('generate_baseline_co2_ets_figures:pngExportFailed', ...
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

function out = ets_revenue_gdp_share(tbl, years)
    pe = extract_values(tbl, 'PE_1', years);
    emissions = extract_values(tbl, 'E_1', years);
    price = extract_values(tbl, 'P_1', years);
    gdp = extract_values(tbl, 'Y_1', years);

    out.Years = gdp.Years;
    out.Values = (pe.Values .* emissions.Values) ./ (price.Values .* gdp.Values) .* 100;
end

function out = ets_revenue_billion_usd(tbl, years, modelToBillionUSD)
    pe = extract_values(tbl, 'PE_1', years);
    emissions = extract_values(tbl, 'E_1', years);

    out.Years = pe.Years;
    out.Values = pe.Values .* emissions.Values .* modelToBillionUSD;
end

function out = emission_price_usd_per_tco2e(tbl, years, modelToBillionUSD, modelToMtCO2e)
    pe = extract_values(tbl, 'PE_1', years);

    % One USD billion per MtCO2e equals USD 1,000 per tCO2e.
    out.Years = pe.Years;
    out.Values = pe.Values .* modelToBillionUSD ./ modelToMtCO2e .* 1000;
end

function save_five_year_average_bars(outDir, stem, metricTitle, yLabel, years, levelMat, ...
    seriesLabels, colors, blockSize)
    [periodLabels, avgMat] = five_year_level_blocks(years, levelMat, blockSize);
    fig = make_fig();
    plot_grouped_period_bars(avgMat, periodLabels, seriesLabels, colors);
    format_axes({metricTitle, '5-year average'}, yLabel);
    place_legend_below();
    save_dual(fig, outDir, [stem '_5Y_Average']);
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

function plot_grouped_period_bars(dataMat, periodLabels, seriesLabels, colors)
    ax = gca;
    bh = bar(ax, dataMat, 'grouped');
    maxAbs = max(abs(dataMat(:)), [], 'omitnan');
    if maxAbs >= 100
        numFmt = '%.0f';
    elseif maxAbs >= 10
        numFmt = '%.1f';
    else
        numFmt = '%.2f';
    end
    for i = 1:numel(bh)
        bh(i).FaceColor = colors(i, :);
        bh(i).DisplayName = char(seriesLabels(i));
        labels = compose(numFmt, bh(i).YData);
        text(bh(i).XEndPoints, bh(i).YEndPoints, labels, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 9, 'Color', colors(i, :));
    end
    ax.XTick = 1:numel(periodLabels);
    ax.XTickLabel = cellstr(periodLabels);
    xtickangle(ax, 30);
    ylim(ax, [min(0, min(dataMat(:), [], 'omitnan')), max(dataMat(:), [], 'omitnan') * 1.1]);
end
