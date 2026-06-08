
%% Baseline Energy Transition Dashboard
%  Run after the baseline simulation has written:
%    ExcelFiles/Output/Baseline.csv
%
%  Outputs are written to Figures/ as PNG and vector PDF files. The script
%  keeps the legacy single-panel filenames and adds dashboard panels for
%  faster review.

close all;

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd));
cd(repoRoot);
setup_paths();

% ---- configuration ------------------------------------------------------
baselineCsv = fullfile(repoRoot, 'ExcelFiles', 'Output', 'Baseline.csv');
capacityCsv = fullfile(repoRoot, 'ExcelFiles', 'PDP8', ...
    'IndexedTrajectories_FossilRenewable_Capacity.csv');
targetXlsx = fullfile(repoRoot, 'ExcelFiles', ...
    'ModelBaseline5Sectorsand1Regions.xlsx');

outDir = fullfile(repoRoot, 'Figures');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

plotStartYear = 2025;
plotEndYear   = 2050;
targetYears   = [2030; 2050];
periodLength  = 5;
periodStartYear = 2026;

colors = struct();
colors.renewable  = [0.00 0.45 0.70];
colors.fossil     = [0.84 0.37 0.00];
colors.efficiency = [0.49 0.18 0.56];
colors.share      = [0.00 0.62 0.45];
colors.plan       = [0.25 0.25 0.25];
colors.grid       = [0.82 0.82 0.82];

set(groot, 'defaultAxesFontSize', 12, ...
           'defaultTextFontSize', 12, ...
           'defaultLegendFontSize', 10, ...
           'defaultAxesFontName', 'Arial', ...
           'defaultTextFontName', 'Arial');

% ---- load ---------------------------------------------------------------
ds = readtable(baselineCsv);
require_vars(ds, ["Year", "Y_1", "P_1", ...
    "I_H_2_1", "I_G_2_1", "I_P_2_1", "P_INV_2_1", ...
    "I_H_3_1", "I_G_3_1", "I_P_3_1", "P_INV_3_1", ...
    "K_2_1", "K_P_2_1", "K_3_1", "K_P_3_1", ...
    "Q_2_1", "Q_3_1", "EE_1"], 'baseline data');

plotMask = ds.Year >= plotStartYear & ds.Year <= plotEndYear;
if ~any(plotMask)
    error('DisplayBaselineEnergy:noPlotYears', ...
        'No baseline rows found between %d and %d in %s.', ...
        plotStartYear, plotEndYear, baselineCsv);
end
ds = ds(plotMask, :);
years = ds.Year(:);
yearRange = [years(1), years(end)];

planCapacity = readtable(capacityCsv, 'TextType', 'string');
require_vars(planCapacity, ["Year", "TechType", "Index_Value"], ...
    'PDP8 capacity data');
planCapacity.TechType = string(planCapacity.TechType);

planTargets = readtable(targetXlsx, 'Sheet', 'Baseline');
planTargets = add_year_variable(planTargets, plotStartYear);
require_vars(planTargets, ["Year", "exo_targetIY_2_1", "exo_targetIY_3_1"], ...
    'baseline target sheet');

% ---- derived series -----------------------------------------------------
idx = @(v) v(:) ./ v(1) .* 100;

gdpNom = ds.Y_1 .* ds.P_1;

invRenNom = (ds.I_H_3_1 + ds.I_G_3_1 + ds.I_FDI_3_1 + ds.I_P_3_1) .* ds.P_INV_3_1;
invFosNom = (ds.I_H_2_1 + ds.I_G_2_1 + ds.I_FDI_2_1 + ds.I_P_2_1) .* ds.P_INV_2_1;

invRenShare = safe_divide(invRenNom, gdpNom) .* 100;
invFosShare = safe_divide(invFosNom, gdpNom) .* 100;
resShare    = safe_divide(ds.Q_3_1, ds.Q_2_1 + ds.Q_3_1) .* 100;

KRenIdx = idx(ds.K_3_1 + ds.K_P_3_1);
KFosIdx = idx(ds.K_2_1 + ds.K_P_2_1);
QRenIdx = idx(ds.Q_3_1);
EEIdx   = idx(ds.EE_1);

[targetInvYears, targetInvRenShare] = target_series(planTargets, ...
    'exo_targetIY_3_1', yearRange, 100);
[~, targetInvFosShare] = target_series(planTargets, ...
    'exo_targetIY_2_1', yearRange, 100);

capacityTargetYears = targetYears(targetYears >= yearRange(1) & ...
                                  targetYears <= yearRange(2));
targetCapRen = capacity_index_at_years(planCapacity, "Renewable", ...
    capacityTargetYears);
targetCapFos = capacity_index_at_years(planCapacity, "Fossil", ...
    capacityTargetYears);

% Investment comparisons use full 5-year periods only. Capacity is a stock,
% so its comparison bars use end-year levels instead of period averages.
periodRows = find(years >= periodStartYear & years <= yearRange(2));
nPeriods = floor(numel(periodRows) / periodLength);
if nPeriods < 1
    error('DisplayBaselineEnergy:noPeriods', ...
        'Need at least %d baseline years from %d onward for period comparison plots.', ...
        periodLength, periodStartYear);
end
periodIdx = reshape(periodRows(1:(nPeriods * periodLength)), ...
    periodLength, nPeriods)';
periodLabels = compose('%d-%d', years(periodIdx(:, 1)), years(periodIdx(:, end)));
periodEndYears = years(periodIdx(:, end));
capacityEndYears = periodEndYears;
capacityEndLabels = compose('%d', capacityEndYears);

prePeriodYears = years(years < periodStartYear);
if ~isempty(prePeriodYears)
    fprintf('Investment period charts start in %d; pre-period year(s) omitted: %s.\n', ...
        periodStartYear, strjoin(string(prePeriodYears'), ', '));
end

if nPeriods * periodLength < numel(periodRows)
    trailingRows = periodRows((nPeriods * periodLength + 1):end);
    trailingYears = years(trailingRows);
    fprintf('Investment period charts use %d full %d-year blocks; trailing year(s) omitted: %s.\n', ...
        nPeriods, periodLength, strjoin(string(trailingYears'), ', '));
end

simRen5 = nan(nPeriods, 1);
simFos5 = nan(nPeriods, 1);
pdp8Ren5 = nan(nPeriods, 1);
pdp8Fos5 = nan(nPeriods, 1);

for p = 1:nPeriods
    ii = periodIdx(p, :);
    yrRange = years(ii);
    simRen5(p) = safe_divide(sum(invRenNom(ii), 'omitnan'), ...
        sum(gdpNom(ii), 'omitnan')) * 100;
    simFos5(p) = safe_divide(sum(invFosNom(ii), 'omitnan'), ...
        sum(gdpNom(ii), 'omitnan')) * 100;
    pdp8Ren5(p) = period_target_mean(planTargets, 'exo_targetIY_3_1', yrRange) * 100;
    pdp8Fos5(p) = period_target_mean(planTargets, 'exo_targetIY_2_1', yrRange) * 100;
end

simCapRenEnd  = values_at_years(years, KRenIdx, capacityEndYears);
simCapFosEnd  = values_at_years(years, KFosIdx, capacityEndYears);
pdp8CapRenEnd = capacity_index_at_years(planCapacity, "Renewable", capacityEndYears);
pdp8CapFosEnd = capacity_index_at_years(planCapacity, "Fossil", capacityEndYears);

% ---- dashboard figures --------------------------------------------------
fig = make_figure('Baseline energy dashboard', [60 60 1280 760]);
tlo = tiledlayout(fig, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_path_panel(nexttile(tlo), years, KRenIdx, colors.renewable, ...
    'Renewable capital', 'Index (2025 = 100)', yearRange, colors);
plot_path_panel(nexttile(tlo), years, QRenIdx, colors.share, ...
    'Renewable production', 'Index (2025 = 100)', yearRange, colors);
plot_path_panel(nexttile(tlo), years, EEIdx, colors.efficiency, ...
    'Energy efficiency', 'Index (2025 = 100)', yearRange, colors);
plot_path_panel(nexttile(tlo), years, invRenShare, colors.renewable, ...
    'Renewable investment / GDP', '% of GDP', yearRange, colors);
plot_path_panel(nexttile(tlo), years, invFosShare, colors.fossil, ...
    'Fossil investment / GDP', '% of GDP', yearRange, colors);
plot_path_panel(nexttile(tlo), years, resShare, colors.share, ...
    'Renewable production share', '% of fossil + renewable output', ...
    yearRange, colors);

sgtitle(tlo, sprintf('Baseline energy transition indicators (%d-%d)', ...
    yearRange(1), yearRange(2)), 'FontSize', 15, 'FontWeight', 'bold');
save_figure(fig, outDir, 'baseline_energy_dashboard');

fig = make_figure('Baseline vs PDP8 annual comparison', [70 70 1180 760]);
tlo = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_annual_comparison(nexttile(tlo), years, KRenIdx, capacityTargetYears, ...
    targetCapRen, colors.renewable, 'Renewable capacity', ...
    'Index (2025 = 100)', yearRange, colors, 'markers');
plot_annual_comparison(nexttile(tlo), years, KFosIdx, capacityTargetYears, ...
    targetCapFos, colors.fossil, 'Fossil capacity', ...
    'Index (2025 = 100)', yearRange, colors, 'markers');
plot_annual_comparison(nexttile(tlo), years, invRenShare, targetInvYears, ...
    targetInvRenShare, colors.renewable, 'Renewable investment / GDP', ...
    '% of GDP', yearRange, colors, 'line');
plot_annual_comparison(nexttile(tlo), years, invFosShare, targetInvYears, ...
    targetInvFosShare, colors.fossil, 'Fossil investment / GDP', ...
    '% of GDP', yearRange, colors, 'line');

sgtitle(tlo, sprintf('Baseline simulation vs PDP8 targets (%d-%d)', ...
    yearRange(1), yearRange(2)), 'FontSize', 15, 'FontWeight', 'bold');
save_figure(fig, outDir, 'baseline_pdp8_annual_comparison');

fig = make_figure('Baseline vs PDP8 period comparison', [80 80 1180 760]);
tlo = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_period_bars(nexttile(tlo), capacityEndLabels, simCapRenEnd, pdp8CapRenEnd, ...
    colors.renewable, 'Renewable capacity: end-year level', ...
    'Index (2025 = 100)', colors);
plot_period_bars(nexttile(tlo), capacityEndLabels, simCapFosEnd, pdp8CapFosEnd, ...
    colors.fossil, 'Fossil capacity: end-year level', ...
    'Index (2025 = 100)', colors);
plot_period_bars(nexttile(tlo), periodLabels, simRen5, pdp8Ren5, ...
    colors.renewable, 'Renewable investment / GDP: 5-year periods', ...
    '% of period GDP', colors);
plot_period_bars(nexttile(tlo), periodLabels, simFos5, pdp8Fos5, ...
    colors.fossil, 'Fossil investment / GDP: 5-year periods', ...
    '% of period GDP', colors);

sgtitle(tlo, sprintf('Baseline simulation vs PDP8 period and end-year comparisons (%d-%d)', ...
    yearRange(1), yearRange(2)), ...
    'FontSize', 15, 'FontWeight', 'bold');
save_figure(fig, outDir, 'baseline_pdp8_period_comparison');

fig = make_figure('Baseline vs PDP8 period comparison (investment ratios)', ...
    [90 90 1080 520]);
tlo = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_period_bars(nexttile(tlo), periodLabels, simRen5, pdp8Ren5, ...
    colors.renewable, 'Renewable investment / GDP: 5-year periods', ...
    '% of period GDP', colors);
plot_period_bars(nexttile(tlo), periodLabels, simFos5, pdp8Fos5, ...
    colors.fossil, 'Fossil investment / GDP: 5-year periods', ...
    '% of period GDP', colors);

sgtitle(tlo, sprintf('Baseline simulation vs PDP8 investment ratios by period (%d-%d)', ...
    yearRange(1), yearRange(2)), ...
    'FontSize', 15, 'FontWeight', 'bold');
save_figure(fig, outDir, 'baseline_pdp8_period_comparison_investment_ratios');

fig = make_figure('Baseline vs PDP8 period comparison (installed capacity)', ...
    [100 100 1080 520]);
tlo = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

plot_period_bars(nexttile(tlo), capacityEndLabels, simCapRenEnd, pdp8CapRenEnd, ...
    colors.renewable, 'Renewable capacity: end-year level', ...
    'Index (2025 = 100)', colors);
plot_period_bars(nexttile(tlo), capacityEndLabels, simCapFosEnd, pdp8CapFosEnd, ...
    colors.fossil, 'Fossil capacity: end-year level', ...
    'Index (2025 = 100)', colors);

sgtitle(tlo, sprintf('Baseline simulation vs PDP8 installed capacity by end year (%d-%d)', ...
    yearRange(1), yearRange(2)), ...
    'FontSize', 15, 'FontWeight', 'bold');
save_figure(fig, outDir, 'baseline_pdp8_period_comparison_installed_capacity');

% ---- legacy single-panel exports ---------------------------------------
plot_single_path(years, KRenIdx, colors.renewable, ...
    'Renewable capital', 'Index (2025 = 100)', yearRange, colors, ...
    outDir, 'baseline_ren_capital');
plot_single_path(years, QRenIdx, colors.share, ...
    'Renewable production', 'Index (2025 = 100)', yearRange, colors, ...
    outDir, 'baseline_ren_production');
plot_single_path(years, EEIdx, colors.efficiency, ...
    'Energy efficiency', 'Index (2025 = 100)', yearRange, colors, ...
    outDir, 'baseline_energy_efficiency');
plot_single_path(years, invRenShare, colors.renewable, ...
    'Renewable investment / GDP', '% of GDP', yearRange, colors, ...
    outDir, 'baseline_ren_inv_gdp');
plot_single_path(years, resShare, colors.share, ...
    'Renewable production share', '%', yearRange, colors, ...
    outDir, 'baseline_res_share');

plot_single_annual(years, KRenIdx, capacityTargetYears, targetCapRen, ...
    colors.renewable, 'Renewable capacity: simulation vs PDP8 targets', ...
    'Index (2025 = 100)', yearRange, colors, 'markers', outDir, ...
    'ren_cap_annual');
plot_single_period(capacityEndLabels, simCapRenEnd, pdp8CapRenEnd, colors.renewable, ...
    'Renewable capacity: end-year level', ...
    'Index (2025 = 100)', colors, outDir, 'ren_cap_bar');
plot_single_annual(years, KFosIdx, capacityTargetYears, targetCapFos, ...
    colors.fossil, 'Fossil capacity: simulation vs PDP8 targets', ...
    'Index (2025 = 100)', yearRange, colors, 'markers', outDir, ...
    'fos_cap_annual');
plot_single_period(capacityEndLabels, simCapFosEnd, pdp8CapFosEnd, colors.fossil, ...
    'Fossil capacity: end-year level', ...
    'Index (2025 = 100)', colors, outDir, 'fos_cap_bar');
plot_single_annual(years, invRenShare, targetInvYears, targetInvRenShare, ...
    colors.renewable, 'Renewable investment / GDP: annual share', ...
    '% of GDP', yearRange, colors, 'line', outDir, 'ren_inv_annual');
plot_single_period(periodLabels, simRen5, pdp8Ren5, colors.renewable, ...
    'Renewable investment / GDP: 5-year periods', ...
    '% of period GDP', colors, outDir, 'ren_inv_bar');
plot_single_annual(years, invFosShare, targetInvYears, targetInvFosShare, ...
    colors.fossil, 'Fossil investment / GDP: annual share', ...
    '% of GDP', yearRange, colors, 'line', outDir, 'fos_inv_annual');
plot_single_period(periodLabels, simFos5, pdp8Fos5, colors.fossil, ...
    'Fossil investment / GDP: 5-year periods', ...
    '% of period GDP', colors, outDir, 'fos_inv_bar');

fprintf('Saved baseline energy plots to %s\n', outDir);

%% Local functions --------------------------------------------------------

function data = add_year_variable(data, startYear)
    if ismember('Year', data.Properties.VariableNames)
        return;
    end
    if ~ismember('Time', data.Properties.VariableNames)
        error('DisplayBaselineEnergy:missingYear', ...
            'Target sheet must contain either Year or Time.');
    end
    data.Year = data.Time + startYear - 1;
end

function require_vars(data, vars, dataName)
    if isstring(vars)
        vars = cellstr(vars);
    end
    missing = vars(~ismember(vars, data.Properties.VariableNames));
    if ~isempty(missing)
        error('DisplayBaselineEnergy:missingVariables', ...
            'Missing required variable(s) in %s: %s', ...
            dataName, strjoin(missing, ', '));
    end
end

function y = safe_divide(num, den)
    y = num ./ den;
    y(den == 0 | isnan(num) | isnan(den)) = NaN;
end

function [targetYears, targetValues] = target_series(data, varName, yearRange, scale)
    require_vars(data, ["Year", string(varName)], 'target data');
    varName = char(varName);
    keep = data.Year >= yearRange(1) & data.Year <= yearRange(2);
    targetYears = data.Year(keep);
    targetValues = data.(varName)(keep) .* scale;

    valid = ~isnan(targetYears) & ~isnan(targetValues);
    targetYears = targetYears(valid);
    targetValues = targetValues(valid);
    [targetYears, order] = sort(targetYears(:));
    targetValues = targetValues(order);
end

function values = capacity_index_at_years(data, techType, years)
    years = years(:);
    values = nan(size(years));
    tech = string(data.TechType);

    for iy = 1:numel(years)
        mask = tech == string(techType) & data.Year == years(iy);
        if any(mask)
            x = data.Index_Value(mask);
            x = x(~isnan(x));
            if ~isempty(x)
                values(iy) = x(end);
            end
        end
    end
end

function value = period_target_mean(data, varName, years)
    require_vars(data, ["Year", string(varName)], 'target data');
    varName = char(varName);
    mask = ismember(data.Year, years);
    x = data.(varName)(mask);
    x = x(~isnan(x));
    if isempty(x)
        value = NaN;
    else
        value = mean(x);
    end
end

function values = values_at_years(years, series, targetYears)
    targetYears = targetYears(:);
    values = nan(size(targetYears));
    for iy = 1:numel(targetYears)
        match = years == targetYears(iy);
        if any(match)
            values(iy) = series(find(match, 1, 'last'));
        end
    end
end

function fig = make_figure(name, position)
    fig = figure('Name', name, 'NumberTitle', 'off', ...
        'Color', 'w', 'Position', position);
end

function save_figure(fig, outDir, stem)
    exportgraphics(fig, fullfile(outDir, [stem '.png']), 'Resolution', 300);
    exportgraphics(fig, fullfile(outDir, [stem '.pdf']), 'ContentType', 'vector');
end

function plot_single_path(years, values, color, titleText, yLabel, yearRange, ...
    colors, outDir, stem)
    fig = make_figure(titleText, [100 100 760 500]);
    ax = axes(fig);
    plot_path_panel(ax, years, values, color, titleText, yLabel, yearRange, colors);
    xlabel(ax, 'Year');
    save_figure(fig, outDir, stem);
end

function plot_single_annual(years, simValues, targetYears, targetValues, ...
    color, titleText, yLabel, yearRange, colors, targetStyle, outDir, stem)
    fig = make_figure(titleText, [100 100 780 520]);
    ax = axes(fig);
    plot_annual_comparison(ax, years, simValues, targetYears, targetValues, ...
        color, titleText, yLabel, yearRange, colors, targetStyle);
    xlabel(ax, 'Year');
    save_figure(fig, outDir, stem);
end

function plot_single_period(labels, simValues, targetValues, color, titleText, ...
    yLabel, colors, outDir, stem)
    fig = make_figure(titleText, [100 100 780 520]);
    ax = axes(fig);
    plot_period_bars(ax, labels, simValues, targetValues, color, titleText, ...
        yLabel, colors);
    save_figure(fig, outDir, stem);
end

function plot_path_panel(ax, years, values, color, titleText, yLabel, ...
    yearRange, colors)
    plot(ax, years, values, '-', 'Color', color, 'LineWidth', 1.9);
    title(ax, titleText, 'Interpreter', 'none');
    ylabel(ax, yLabel);
    xlabel(ax, 'Year');
    style_time_axis(ax, yearRange, colors);
    pad_y_axis(ax);
end

function plot_annual_comparison(ax, years, simValues, targetYears, targetValues, ...
    color, titleText, yLabel, yearRange, colors, targetStyle)
    plot(ax, years, simValues, '-', 'Color', color, 'LineWidth', 1.9, ...
        'DisplayName', 'Simulation');
    hold(ax, 'on');
    targetYears = targetYears(:);
    targetValues = targetValues(:);
    validTarget = ~isnan(targetYears) & ~isnan(targetValues);

    if any(validTarget)
        switch targetStyle
            case 'markers'
                plot(ax, targetYears(validTarget), targetValues(validTarget), ...
                    'd', 'Color', colors.plan, 'MarkerFaceColor', colors.plan, ...
                    'MarkerSize', 7, 'LineStyle', 'none', ...
                    'DisplayName', 'PDP8 target');
            otherwise
                plot(ax, targetYears(validTarget), targetValues(validTarget), ...
                    ':', 'Color', colors.plan, 'LineWidth', 2.0, ...
                    'DisplayName', 'PDP8 target path');
        end
    end
    hold(ax, 'off');

    title(ax, titleText, 'Interpreter', 'none');
    ylabel(ax, yLabel);
    xlabel(ax, 'Year');
    style_time_axis(ax, yearRange, colors);
    pad_y_axis(ax);
    legend(ax, 'Location', 'best', 'Box', 'off');
end

function plot_period_bars(ax, labels, simValues, targetValues, color, ...
    titleText, yLabel, colors)
    b = bar(ax, [simValues(:), targetValues(:)], 'grouped');
    b(1).FaceColor = color;
    b(2).FaceColor = colors.plan;
    b(1).EdgeColor = 'none';
    b(2).EdgeColor = 'none';

    title(ax, titleText, 'Interpreter', 'none');
    ylabel(ax, yLabel);
    set(ax, 'XTick', 1:numel(labels), ...
        'XTickLabel', cellstr(labels), ...
        'XTickLabelRotation', 30);
    style_axis(ax, colors);
    pad_y_axis(ax);
    legend(ax, {'Simulation', 'PDP8 plan'}, 'Location', 'northoutside', ...
        'Orientation', 'horizontal', 'Box', 'off');
end

function style_time_axis(ax, yearRange, colors)
    style_axis(ax, colors);
    xlim(ax, yearRange);
    tickStart = ceil(yearRange(1) / 5) * 5;
    tickEnd = floor(yearRange(2) / 5) * 5;
    ticks = unique([yearRange(1), tickStart:5:tickEnd, yearRange(2)]);
    xticks(ax, ticks);
end

function style_axis(ax, colors)
    grid(ax, 'on');
    box(ax, 'off');
    if isprop(ax, 'Toolbar') && ~isempty(ax.Toolbar)
        ax.Toolbar.Visible = 'off';
    end
    ax.GridColor = colors.grid;
    ax.GridAlpha = 0.45;
    ax.LineWidth = 0.8;
    ax.TickDir = 'out';
    ax.Layer = 'top';
end

function pad_y_axis(ax)
    yLimits = ylim(ax);
    if any(~isfinite(yLimits)) || diff(yLimits) <= 0
        return;
    end

    pad = diff(yLimits) * 0.06;
    if yLimits(1) == 0
        yLow = 0;
    else
        yLow = yLimits(1) - pad;
    end
    ylim(ax, [yLow, yLimits(2) + pad]);
end
