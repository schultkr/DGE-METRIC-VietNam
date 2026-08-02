%% Generate NZ vs Baseline comparison figures
% Template-based script aligned with generate_ee_simulation_results_figures.m.
% Produces comparison and deviation charts for NZ against Baseline.
%
% Output:
%   docs/figures/NZ_Simulation_Results/*.svg and *.png

clearvars; close all; clc;

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

outDir = fullfile(repoRoot, 'docs', 'figures', 'NZ_Simulation_Results');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

plotYears = (2025:2050)';
baselineName = "Baseline";
scenarioName = "NZ";
scenarioLabel = "Net Zero";

baselineCsv = fullfile(repoRoot, 'ExcelFiles', 'Output', baselineName + ".csv");
scenarioCsv = fullfile(repoRoot, 'ExcelFiles', 'Output', scenarioName + ".csv");

if ~isfile(baselineCsv)
    error('generate_nz_baseline_comparison_figures:missingCsv', ...
        'Required CSV not found: %s', baselineCsv);
end
if ~isfile(scenarioCsv)
    error('generate_nz_baseline_comparison_figures:missingCsv', ...
        'Required CSV not found: %s', scenarioCsv);
end

baseline = readtable(baselineCsv);
scenario = readtable(scenarioCsv);

requiredVars = ["Year", "Y_1", "I_1", "C_1", "Q_A_2_1", "Q_PV_1", "Q_A_F_2_1", "P_A_2_1", "E_1", "E_NOETS_1"];
require_vars(baseline, requiredVars, 'Baseline');
require_vars(scenario, requiredVars, 'NZ');

commonYears = intersect(baseline.Year(:), scenario.Year(:));
commonYears = commonYears(ismember(commonYears, plotYears));
commonYears = sort(commonYears(:));

if isempty(commonYears)
    error('generate_nz_baseline_comparison_figures:noYears', ...
        'No common years available in requested horizon.');
end

baseline = sortrows(baseline(ismember(baseline.Year, commonYears), :), 'Year');
scenario = sortrows(scenario(ismember(scenario.Year, commonYears), :), 'Year');
years = baseline.Year(:);

colors = struct();
colors.baseline = [0.20 0.20 0.20];
colors.scenario = [0.00 0.45 0.70];
colors.delta = [0.84 0.37 0.00];
colors.zero = [0.45 0.45 0.45];
lineWidth = 2.0;

% Precompute metric series.
bGDPGrowth = annual_growth(baseline, 'Y_1', years);
sGDPGrowth = annual_growth(scenario, 'Y_1', years);

bInvShare = level_share(baseline, 'I_1', 'Y_1', years);
sInvShare = level_share(scenario, 'I_1', 'Y_1', years);

bConsShare = level_share(baseline, 'C_1', 'Y_1', years);
sConsShare = level_share(scenario, 'C_1', 'Y_1', years);

bEnergyIntensity = energy_intensity_index(baseline, years);
sEnergyIntensity = energy_intensity_index(scenario, years);

bEnergyPrices = energy_price_index(baseline, years);
sEnergyPrices = energy_price_index(scenario, years);

bFinalDemand = final_energy_demand_index(baseline, years);
sFinalDemand = final_energy_demand_index(scenario, years);

bFinalDemandGrid = grid_final_energy_demand_index(baseline, years);
sFinalDemandGrid = grid_final_energy_demand_index(scenario, years);

bFinalDemandPV = pv_final_energy_demand_index(baseline, years);
sFinalDemandPV = pv_final_energy_demand_index(scenario, years);

bEmissions = emissions_index(baseline, years);
sEmissions = emissions_index(scenario, years);

bEmissionsNoETS = emissionsNoETS_index(baseline, years);
sEmissionsNoETS = emissionsNoETS_index(scenario, years);


bGDPLevel = extract_values(baseline, 'Y_1', years);
sGDPLevel = extract_values(scenario, 'Y_1', years);

% GDP growth comparison
save_comparison_figure(years, bGDPGrowth.Values, sGDPGrowth.Values, ...
    colors, lineWidth, 'GDP Growth Comparison with Baseline', 'Percent', ...
    scenarioLabel, outDir, 'GDP_Growth_Comparison_with_Baseline');

% GDP growth deviation
save_deviation_figure(years, sGDPGrowth.Values - bGDPGrowth.Values, ...
    colors, lineWidth, 'GDP Growth Deviation vs Baseline', 'Percentage points', ...
    scenarioLabel, outDir, 'GDP_Growth_Deviation_vs_Baseline');
maybe_save_five_year_average(years, sGDPGrowth.Values - bGDPGrowth.Values, ...
    scenarioLabel, outDir, 'GDP_Growth_Deviation_vs_Baseline', 'Percentage points');

% Investment share comparison + deviation
save_comparison_figure(years, bInvShare.Values, sInvShare.Values, ...
    colors, lineWidth, 'Investment Share of GDP', '% of GDP', ...
    scenarioLabel, outDir, 'Investment_Share_GDP');
save_deviation_figure(years, sInvShare.Values - bInvShare.Values, ...
    colors, lineWidth, 'Investment Share Deviation vs Baseline', 'pp of GDP', ...
    scenarioLabel, outDir, 'Investment_Share_Deviation_vs_Baseline');
maybe_save_five_year_average(years, sInvShare.Values - bInvShare.Values, ...
    scenarioLabel, outDir, 'Investment_Share_Deviation_vs_Baseline', 'pp of GDP');

% Consumption share comparison + deviation
save_comparison_figure(years, bConsShare.Values, sConsShare.Values, ...
    colors, lineWidth, 'Consumption Share of GDP', '% of GDP', ...
    scenarioLabel, outDir, 'Consumption_Share_GDP');
save_deviation_figure(years, sConsShare.Values - bConsShare.Values, ...
    colors, lineWidth, 'Consumption Share Deviation vs Baseline', 'pp of GDP', ...
    scenarioLabel, outDir, 'Consumption_Share_Deviation_vs_Baseline');
maybe_save_five_year_average(years, sConsShare.Values - bConsShare.Values, ...
    scenarioLabel, outDir, 'Consumption_Share_Deviation_vs_Baseline', 'pp of GDP');

% Energy intensity comparison + deviation
save_comparison_figure(years, bEnergyIntensity.Values, sEnergyIntensity.Values, ...
    colors, lineWidth, 'Energy Intensity Index', 'Index (2025 = 100)', ...
    scenarioLabel, outDir, 'Energy_Intensity_Index');
save_deviation_figure(years, sEnergyIntensity.Values - bEnergyIntensity.Values, ...
    colors, lineWidth, 'Energy Intensity Deviation vs Baseline', 'Index points', ...
    scenarioLabel, outDir, 'Energy_Intensity_Deviation_vs_Baseline');
maybe_save_five_year_average(years, sEnergyIntensity.Values - bEnergyIntensity.Values, ...
    scenarioLabel, outDir, 'Energy_Intensity_Deviation_vs_Baseline', 'Index points');

% Energy prices comparison + deviation
save_comparison_figure(years, bEnergyPrices.Values, sEnergyPrices.Values, ...
    colors, lineWidth, 'Energy Prices Index', 'Index (2025 = 100)', ...
    scenarioLabel, outDir, 'Energy_Prices_Index');
save_deviation_figure(years, sEnergyPrices.Values - bEnergyPrices.Values, ...
    colors, lineWidth, 'Energy Prices Deviation vs Baseline', 'Index points', ...
    scenarioLabel, outDir, 'Energy_Prices_Deviation_vs_Baseline');
maybe_save_five_year_average(years, sEnergyPrices.Values - bEnergyPrices.Values, ...
    scenarioLabel, outDir, 'Energy_Prices_Deviation_vs_Baseline', 'Index points');

% Final energy demand (total) comparison + deviation
save_comparison_figure(years, bFinalDemand.Values, sFinalDemand.Values, ...
    colors, lineWidth, 'Final Energy Demand Index', 'Index (2025 = 100)', ...
    scenarioLabel, outDir, 'Final_Energy_Demand_Index');
save_deviation_figure(years, sFinalDemand.Values - bFinalDemand.Values, ...
    colors, lineWidth, 'Final Energy Demand Deviation vs Baseline', 'Index points', ...
    scenarioLabel, outDir, 'Final_Energy_Demand_Deviation_vs_Baseline');
maybe_save_five_year_average(years, sFinalDemand.Values - bFinalDemand.Values, ...
    scenarioLabel, outDir, 'Final_Energy_Demand_Deviation_vs_Baseline', 'Index points');

% Final energy demand (grid) comparison + deviation
save_comparison_figure(years, bFinalDemandGrid.Values, sFinalDemandGrid.Values, ...
    colors, lineWidth, 'Final Energy Demand Index (Grid-provided)', 'Index (2025 = 100)', ...
    scenarioLabel, outDir, 'Final_Energy_Demand_Grid_Index');
save_deviation_figure(years, sFinalDemandGrid.Values - bFinalDemandGrid.Values, ...
    colors, lineWidth, 'Final Energy Demand Deviation vs Baseline (Grid-provided)', 'Index points', ...
    scenarioLabel, outDir, 'Final_Energy_Demand_Grid_Deviation_vs_Baseline');
maybe_save_five_year_average(years, sFinalDemandGrid.Values - bFinalDemandGrid.Values, ...
    scenarioLabel, outDir, 'Final_Energy_Demand_Grid_Deviation_vs_Baseline', 'Index points');

% Final energy demand (PV) comparison + deviation
save_comparison_figure(years, bFinalDemandPV.Values, sFinalDemandPV.Values, ...
    colors, lineWidth, 'Final Energy Demand Index (PV-provided)', 'Index (2025 = 100)', ...
    scenarioLabel, outDir, 'Final_Energy_Demand_PV_Index');
save_deviation_figure(years, sFinalDemandPV.Values - bFinalDemandPV.Values, ...
    colors, lineWidth, 'Final Energy Demand Deviation vs Baseline (PV-provided)', 'Index points', ...
    scenarioLabel, outDir, 'Final_Energy_Demand_PV_Deviation_vs_Baseline');
maybe_save_five_year_average(years, sFinalDemandPV.Values - bFinalDemandPV.Values, ...
    scenarioLabel, outDir, 'Final_Energy_Demand_PV_Deviation_vs_Baseline', 'Index points');

% Emissions comparison + deviation
save_comparison_figure(years, bEmissions.Values, sEmissions.Values, ...
    colors, lineWidth, 'Emissions Index', 'Index (2025 = 100)', ...
    scenarioLabel, outDir, 'Emissions_Index');
save_deviation_figure(years, sEmissions.Values - bEmissions.Values, ...
    colors, lineWidth, 'Emissions Deviation vs Baseline', 'Index points', ...
    scenarioLabel, outDir, 'Emissions_Deviation_vs_Baseline');
maybe_save_five_year_average(years, sEmissions.Values - bEmissions.Values, ...
    scenarioLabel, outDir, 'Emissions_Deviation_vs_Baseline', 'Index points');

% Emissions comparison + deviation
save_comparison_figure(years, bEmissionsNoETS.Values, sEmissionsNoETS.Values, ...
    colors, lineWidth, 'Emissions NoETS Index', 'Index (2025 = 100)', ...
    scenarioLabel, outDir, 'EmissionsNOETS_Index');
save_deviation_figure(years, sEmissionsNoETS.Values - bEmissionsNoETS.Values, ...
    colors, lineWidth, 'Emissions Deviation vs Baseline', 'Index points', ...
    scenarioLabel, outDir, 'EmissionsNoETS_Deviation_vs_Baseline');
maybe_save_five_year_average(years, sEmissionsNoETS.Values - bEmissionsNoETS.Values, ...
    scenarioLabel, outDir, 'EmissionsNoETS_Deviation_vs_Baseline', 'Index points');

% GDP level deviation
gdpLevelDev = safe_divide(sGDPLevel.Values, bGDPLevel.Values) * 100 - 100;
save_deviation_figure(years, gdpLevelDev, ...
    colors, lineWidth, 'GDP Level Deviation vs Baseline', '% deviation', ...
    scenarioLabel, outDir, 'GDP_Level_Deviation_vs_Baseline');
maybe_save_five_year_average(years, gdpLevelDev, ...
    scenarioLabel, outDir, 'GDP_Level_Deviation_vs_Baseline', '% deviation');

fprintf('Generated NZ comparison figures in: %s\n', outDir);

%% Local functions

function require_vars(tbl, vars, name)
    missing = vars(~ismember(vars, string(tbl.Properties.VariableNames)));
    if ~isempty(missing)
        error('generate_nz_baseline_comparison_figures:missingVars', ...
            'Missing variable(s) in %s: %s', name, strjoin(cellstr(missing), ', '));
    end
end

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
    stem = char(stem);
    svgPath = fullfile(outDir, [stem '.svg']);
    pngPath = fullfile(outDir, [stem '.png']);

    try
        exportgraphics(fig, svgPath, 'ContentType', 'vector');
    catch meSvg
        % Older MATLAB releases may not support SVG export with exportgraphics.
        % Fall back to print('-dsvg') before giving up on SVG.
        try
            set(fig, 'Renderer', 'painters');
            print(fig, svgPath, '-dsvg');
        catch mePrint
            warning('generate_nz_baseline_comparison_figures:svgExportFailed', ...
                ['SVG export failed for "%s". Continuing with PNG only. ' ...
                 'exportgraphics error: %s | print error: %s'], ...
                stem, meSvg.message, mePrint.message);
        end
    end

    try
        exportgraphics(fig, pngPath, 'Resolution', 300);
    catch ME
        try
            fr = getframe(fig);
            imwrite(fr.cdata, pngPath);
        catch ME2
            warning('generate_nz_baseline_comparison_figures:pngExportFailed', ...
                'PNG export failed for %s (%s | %s).', stem, ME.message, ME2.message);
        end
    end

    close(fig);
end

function save_comparison_figure(years, baseVals, scenVals, colors, lineWidth, ...
    plotTitle, yLabel, scenarioLabel, outDir, stem)
    fig = make_fig();
    hold on;
    plot(years, baseVals, '-', 'Color', colors.baseline, 'LineWidth', lineWidth, ...
        'DisplayName', 'Baseline');
    plot(years, scenVals, '-', 'Color', colors.scenario, 'LineWidth', lineWidth, ...
        'DisplayName', char(scenarioLabel));
    format_axes(plotTitle, 'Year', yLabel);
    if contains(string(plotTitle), "GDP Growth Comparison", 'IgnoreCase', true)
        yl = ylim;
        ylim([0, yl(2)]);
    end
    place_legend_below();
    save_dual(fig, outDir, stem);
end

function save_deviation_figure(years, devVals, colors, lineWidth, ...
    plotTitle, yLabel, scenarioLabel, outDir, stem)
    fig = make_fig();
    hold on;
    plot(years, devVals, '-', 'Color', colors.delta, 'LineWidth', lineWidth, ...
        'DisplayName', char(scenarioLabel));
    yline(0, ':', 'Color', colors.zero, 'LineWidth', 1.0, 'HandleVisibility', 'off');
    format_axes(plotTitle, 'Year', yLabel);
    place_legend_below();
    save_dual(fig, outDir, stem);
end

function maybe_save_five_year_average(years, values, scenarioLabel, outDir, stem, yLabel)
    [periodLabels, avgValues] = five_year_blocks_average(years, values);
    if isempty(periodLabels)
        return;
    end

    fig = make_fig();
    bar(categorical(periodLabels, periodLabels), avgValues, 0.65, ...
        'FaceColor', [0.00 0.45 0.70], 'EdgeColor', 'none', ...
        'DisplayName', char(scenarioLabel));
    yline(0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
    format_axes(strrep(stem, '_', ' ') + " (5-Year Average)", 'Time period', yLabel);
    place_legend_below();
    save_dual(fig, outDir, stem + "_5YAvg");
end

function [periodLabels, avgValues] = five_year_blocks_average(years, values)
    starts = [2026, 2031, 2036, 2041, 2046];
    periodLabels = strings(0, 1);
    avgValues = zeros(0, 1);

    for i = 1:numel(starts)
        y0 = starts(i);
        y1 = y0 + 4;
        mask = years >= y0 & years <= y1;
        block = values(mask);
        block = block(isfinite(block));
        if isempty(block)
            continue;
        end
        periodLabels(end+1, 1) = sprintf('%d-%d', y0, y1); %#ok<AGROW>
        avgValues(end+1, 1) = mean(block); %#ok<AGROW>
    end
end

function out = extract_values(tbl, varName, years)
    [tf, idx] = ismember(years(:), tbl.Year(:));
    validYears = years(tf);
    out.Years = validYears(:);
    out.Values = tbl.(varName)(idx(tf));
end

function out = annual_growth(tbl, varName, years)
    x = extract_values(tbl, varName, years);
    vals = nan(size(x.Values));
    if numel(vals) > 1
        vals(2:end) = (x.Values(2:end) ./ x.Values(1:end-1) - 1) * 100;
    end
    out.Years = x.Years;
    out.Values = vals;
end

function out = level_share(tbl, numVar, denVar, years)
    num = extract_values(tbl, numVar, years);
    den = extract_values(tbl, denVar, years);
    out.Years = num.Years;
    out.Values = safe_divide(num.Values, den.Values) * 100;
end

function out = energy_intensity_index(tbl, years)
    energy = extract_values(tbl, 'Q_A_2_1', years);
    pv = extract_values(tbl, 'Q_PV_1', years);
    gdp = extract_values(tbl, 'Y_1', years);

    eIdx = safe_divide(energy.Values + pv.Values, energy.Values(1) + pv.Values(1)) * 100;
    gIdx = safe_divide(gdp.Values, gdp.Values(1)) * 100;

    out.Years = energy.Years;
    out.Values = safe_divide(eIdx, gIdx) * 100;
end

function out = energy_price_index(tbl, years)
    price = extract_values(tbl, 'P_A_2_1', years);
    out.Years = price.Years;
    out.Values = safe_divide(price.Values, price.Values(1)) * 100;
end

function out = final_energy_demand_index(tbl, years)
    qf = extract_values(tbl, 'Q_A_F_2_1', years);
    pv = extract_values(tbl, 'Q_PV_1', years);
    out.Years = qf.Years;
    out.Values = safe_divide(qf.Values + pv.Values, qf.Values(1) + pv.Values(1)) * 100;
end

function out = grid_final_energy_demand_index(tbl, years)
    qf = extract_values(tbl, 'Q_A_F_2_1', years);
    out.Years = qf.Years;
    out.Values = safe_divide(qf.Values, qf.Values(1)) * 100;
end

function out = pv_final_energy_demand_index(tbl, years)
    pv = extract_values(tbl, 'Q_PV_1', years);
    out.Years = pv.Years;
    out.Values = safe_divide(pv.Values, pv.Values(1)) * 100;
end

function out = emissions_index(tbl, years)
    e = extract_values(tbl, 'E_1', years);
    out.Years = e.Years;
    out.Values = safe_divide(e.Values, e.Values(1)) * 100;
end

function out = emissionsNoETS_index(tbl, years)
    e = extract_values(tbl, 'E_NOETS_1', years);
    out.Years = e.Years;
    out.Values = safe_divide(e.Values, e.Values(1)) * 100;
end

function z = safe_divide(a, b)
    z = a ./ b;
    z(~isfinite(z)) = NaN;
end
