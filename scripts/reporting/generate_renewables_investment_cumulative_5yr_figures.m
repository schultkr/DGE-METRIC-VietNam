%% Generate cumulative 5-year renewables investment-need bar chart
% Companion to generate_renewables_investment_usd_figures.m: instead of an
% annual line, this sums (not averages) renewables investment need within
% each 5-year period, i.e. "how much total investment is required over this
% period" rather than the annual run-rate. Grouped bars, one group per
% period, one bar per scenario.
%
% Per-scenario, per-year formula (subsector 3 = Renewables, region 1) — see
% generate_renewables_investment_usd_figures.m for the full derivation, and
% for why P_INV_3_1 (purchase price of investment goods) is the correct
% deflator here, NOT the similarly-named P_I_3_1 (intermediate-inputs price
% index — an unrelated variable):
%
%   gdpNom(t)      = Y_1(t) * P_1(t)
%   RenInvUSDbn(t) = (I_H_3_1(t) + I_G_3_1(t) + I_FDI_3_1(t)) * P_INV_3_1(t) ...
%                    / gdpNom(t) * [gdpNom(t)/gdpNom(anchorYear) * gdpBaseBillionUSD]
%
% Each period's bar is sum(RenInvUSDbn(t)) over the 5 years in that period.
%
% Scenarios: NZ_Dir10_full_GF_C, NZ.

close all;

repoRoot   = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd     = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

outputDir = fullfile(repoRoot, 'ExcelFiles', 'Output');

scenarioSpecs = table( ...
    ["Baseline"; "NZ_Dir10_full_GF_C"; "NZ"], ...
    ["PDP8-rev"; "Net Zero Directive 10 (full) + GF C"; "Net Zero"], ...
    'VariableNames', {'Name', 'Label'});

plotStartYear = 2025;
plotEndYear   = 2050;

% 5-year period aggregation: 2025 is the base year, so periods start 2026
% (same convention as generate_employment_sector_decomposition_figures.m /
% generate_gva_sector_decomposition_figures.m).
periodStartYear = 2026;
periodLength    = 5;

% Real-world USD anchor (see generate_renewables_investment_usd_figures.m).
anchorYear        = 2025;
gdpBaseBillionUSD = 430;  % Vietnam 2025 GDP, USD billion (430,000 USD million)

% Data version: scenarios (including Baseline) in ExcelFiles/Output/ can
% exist as a plain "<Name>.csv", a "<Name>_replication.csv" and a
% "<Name>.csv" (at any given time, only some may actually be
% present — "" is the suffix RunSimulations.m currently
% writes). Set which variant to prefer; if the preferred one is missing,
% the others are tried in turn (reported via fprintf/warning), so this never
% has to be re-checked scenario by scenario.
%   "plain"           - prefer "<Name>.csv" (default; falls
%                       back to replication)
%   "replication"     - prefer "<Name>_replication.csv"
%   "plain"           - prefer "<Name>.csv"
dataVersion = "plain";

[baselineCsv, baselineResolvedName, baselineUsedFallback] = resolve_scenario_csv(outputDir, "Baseline", dataVersion);
if baselineCsv == ""
    error('generate_renewables_investment_cumulative_5yr_figures:missingBaseline', ...
        'No CSV found for "Baseline" (tried "Baseline.csv", "Baseline_replication.csv" and "Baseline.csv").');
end
if baselineUsedFallback
    fprintf('Scenario "Baseline": preferred "%s" variant not found; using "%s" instead.\n', ...
        dataVersion, baselineResolvedName);
end

outDir = fullfile(repoRoot, 'Figures', 'ScenarioComparisons', 'RenewablesInvestment');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

iwh = iwh_colors();

set(groot, 'defaultAxesFontSize', 12, ...
           'defaultTextFontSize', 12, ...
           'defaultLegendFontSize', 10, ...
           'defaultAxesFontName', 'Arial', ...
           'defaultTextFontName', 'Arial');

requiredVars = ["I_H_3_1", "I_G_3_1", "I_FDI_3_1", "P_INV_3_1", "Y_1", "P_1"];

baseline = readtable(baselineCsv);
baseline = require_and_sort_years(baseline, plotStartYear, plotEndYear, 'baseline');
require_vars(baseline, ["Year", requiredVars], 'baseline data');

anchorRow = baseline(baseline.Year == anchorYear, :);
if height(anchorRow) ~= 1
    error('generate_renewables_investment_cumulative_5yr_figures:missingAnchorYear', ...
        'Baseline data must contain exactly one row for the anchor year %d to derive the USD scale factor.', ...
        anchorYear);
end
anchorGdpNom = anchorRow.Y_1 * anchorRow.P_1;
billionUSDPerModelUnit = gdpBaseBillionUSD / anchorGdpNom;
fprintf(['USD scale factor: %.6g billion USD per model-Y_1*P_1-unit ' ...
    '(anchored on %d Baseline Y_1*P_1 = %.4g -> %.1f billion USD)\n'], ...
    billionUSDPerModelUnit, anchorYear, anchorGdpNom, gdpBaseBillionUSD);

nScen = height(scenarioSpecs);
periodTables = cell(nScen, 1);
available    = false(nScen, 1);

for iScen = 1:nScen
    sName = string(scenarioSpecs.Name(iScen));

    [csvPath, resolvedName, usedFallback] = resolve_scenario_csv(outputDir, sName, dataVersion);
    if isempty(csvPath)
        warning('generate_renewables_investment_cumulative_5yr_figures:missingScenarioFile', ...
            'No CSV found for "%s" (tried "%s.csv", "%s_replication.csv" and "%s.csv"). Skipping.', ...
            sName, sName, sName, sName);
        continue
    end
    if usedFallback
        fprintf('Scenario "%s": preferred "%s" variant not found; using "%s" instead.\n', ...
            sName, dataVersion, resolvedName);
    end

    tbl = readtable(csvPath);
    require_vars(tbl, ["Year", requiredVars], char(sName) + " data");
    tbl = require_and_sort_years(tbl, plotStartYear, plotEndYear, char(sName));

    series = compute_investment_series(tbl, billionUSDPerModelUnit);
    periodTables{iScen} = aggregate_to_periods_sum(series, periodStartYear, plotEndYear, periodLength, ...
        "RenInvUSDBillion");
    available(iScen) = true;
end

if ~any(available)
    error('generate_renewables_investment_cumulative_5yr_figures:noScenarios', ...
        'No scenario data available; nothing to plot.');
end

firstAvail  = find(available, 1);
periodLabels = periodTables{firstAvail}.Period;
nPeriods     = numel(periodLabels);

cumMatrix = nan(nPeriods, nScen);
for iScen = 1:nScen
    if ~available(iScen)
        continue
    end
    if ~isequal(periodTables{iScen}.Period, periodLabels)
        error('generate_renewables_investment_cumulative_5yr_figures:periodMismatch', ...
            'Scenario "%s" has different periods than "%s"; cannot align for a grouped bar chart.', ...
            scenarioSpecs.Name(iScen), scenarioSpecs.Name(firstAvail));
    end
    cumMatrix(:, iScen) = periodTables{iScen}.RenInvUSDBillion;
end

resultTable = table(periodLabels, 'VariableNames', {'Period'});
resultTable = addvars(resultTable, periodTables{firstAvail}.StartYear, periodTables{firstAvail}.EndYear, ...
    'NewVariableNames', {'StartYear', 'EndYear'});
for iScen = 1:nScen
    resultTable.(matlab.lang.makeValidName(char(scenarioSpecs.Name(iScen)))) = cumMatrix(:, iScen);
end
writetable(resultTable, fullfile(outDir, 'Renewables_Investment_Cumulative_5yr_AllScenarios.csv'));

fig = figure('Color', 'w', 'Position', [90 90 900 560]);
ax  = axes(fig);
periodCats = categorical(periodLabels, periodLabels);
bh = bar(ax, periodCats, cumMatrix, 'grouped');

for iScen = 1:nScen
    sName = string(scenarioSpecs.Name(iScen));
    style = iwh_scenario_style(sName);
    bh(iScen).FaceColor  = style.Color;
    bh(iScen).EdgeColor  = 'none';
    bh(iScen).DisplayName = char(scenarioSpecs.Label(iScen));
end

ylabel(ax, {'Cumulative renewables investment need per 5-year period', ...
    'Billion USD (2025 GDP-anchored)'}, 'Interpreter', 'none');
set(ax, 'XTickLabelRotation', 30);
style_axis(ax, iwh.grid);
pad_y_axis(ax);
legend(ax, 'Location', 'northoutside', 'Orientation', 'horizontal', ...
    'Box', 'off', 'Interpreter', 'none');

save_dual(fig, outDir, 'Renewables_Investment_Cumulative_5yr_AllScenarios');
fprintf('Saved cumulative 5-year renewables investment chart to %s\n', outDir);

%% Local functions --------------------------------------------------------

function tbl = require_and_sort_years(tbl, startYear, endYear, label)
    require_vars(tbl, 'Year', label);
    tbl = tbl(tbl.Year >= startYear & tbl.Year <= endYear, :);
    tbl = sortrows(tbl, 'Year');
end

function require_vars(tbl, vars, label)
    vars = string(vars);
    missing = vars(~ismember(vars, string(tbl.Properties.VariableNames)));
    if ~isempty(missing)
        error('generate_renewables_investment_cumulative_5yr_figures:missingVars', ...
            'Missing variable(s) in %s: %s', label, strjoin(cellstr(missing), ', '));
    end
end

function [csvPath, resolvedName, usedFallback] = resolve_scenario_csv(outputDir, sName, dataVersion)
    % Resolves the CSV for scenario sName according to the preferred
    % dataVersion ("replication" or "plain"), falling back to the other
    % variant if the preferred one doesn't exist. Returns csvPath = "" if
    % neither is found. usedFallback is true iff the preferred variant was
    % NOT the one actually used.
    plainName          = sName;
    replicationName    = sName + "_replication";

    switch dataVersion
        case "plain"
            candidates = [plainName, replicationName];
        case "replication"
            candidates = [replicationName, plainName];
        otherwise
            error('generate_renewables_investment_cumulative_5yr_figures:badDataVersion', ...
                'dataVersion must be "plain" or "replication", got "%s".', dataVersion);
    end

    for iCand = 1:numel(candidates)
        candidatePath = fullfile(outputDir, candidates(iCand) + ".csv");
        if isfile(candidatePath)
            csvPath      = candidatePath;
            resolvedName = candidates(iCand);
            usedFallback = (iCand > 1);
            return
        end
    end

    csvPath      = "";
    resolvedName = sName;
    usedFallback = false;
end

function out = compute_investment_series(tbl, billionUSDPerModelUnit)
    % gdpNom_1      = Y_1 * P_1
    % RenInvToGDP_1 = (I_H_3_1 + I_G_3_1 + I_FDI_3_1) * P_INV_3_1 / gdpNom_1
    gdpNom        = tbl.Y_1 .* tbl.P_1;
    renInvNominal = (tbl.I_H_3_1 + tbl.I_G_3_1 + tbl.I_FDI_3_1) .* tbl.P_INV_3_1;
    ratio         = safe_divide(renInvNominal, gdpNom);

    out = table();
    out.Year             = tbl.Year;
    out.RenInvToGDPPct   = ratio .* 100;
    out.GDP_USDBillion   = gdpNom .* billionUSDPerModelUnit;
    out.RenInvUSDBillion = ratio .* out.GDP_USDBillion;
end

function z = safe_divide(a, b)
    z = a ./ b;
    z(~isfinite(z)) = NaN;
end

function periodTbl = aggregate_to_periods_sum(tbl, periodStartYear, periodEndYear, periodLength, varsToSum)
    % Splits tbl.Year(periodStartYear:periodEndYear) into consecutive
    % non-overlapping periodLength-year blocks and SUMS each variable in
    % varsToSum within each block (cumulative need over the period, not an
    % annual run-rate average). Trailing years that don't fill a full block
    % are dropped (reported via warning).
    years = tbl.Year;
    rows  = find(years >= periodStartYear & years <= periodEndYear);
    nPeriods = floor(numel(rows) / periodLength);
    if nPeriods < 1
        error('generate_renewables_investment_cumulative_5yr_figures:noPeriods', ...
            'Need at least %d years from %d to build one %d-year period.', ...
            periodLength, periodStartYear, periodLength);
    end

    usedRows = rows(1:(nPeriods * periodLength));
    if numel(usedRows) < numel(rows)
        trailingYears = years(rows((nPeriods * periodLength + 1):end));
        warning('generate_renewables_investment_cumulative_5yr_figures:trailingPeriodYears', ...
            'Dropping %d trailing year(s) that do not fill a full %d-year period: %s.', ...
            numel(trailingYears), periodLength, strjoin(string(trailingYears'), ', '));
    end

    periodIdx = reshape(usedRows, periodLength, nPeriods)';

    periodTbl = table();
    periodTbl.Period    = compose('%d-%d', years(periodIdx(:, 1)), years(periodIdx(:, end)));
    periodTbl.StartYear = years(periodIdx(:, 1));
    periodTbl.EndYear   = years(periodIdx(:, end));

    varsToSum = string(varsToSum);
    for iVar = 1:numel(varsToSum)
        v = varsToSum(iVar);
        vals = tbl.(v);
        periodSums = zeros(nPeriods, 1);
        for p = 1:nPeriods
            periodSums(p) = sum(vals(periodIdx(p, :)));
        end
        periodTbl.(v) = periodSums;
    end
end

function style_axis(ax, gridColor)
    % Matches display_baseline_energy.m's axis styling: thin outward ticks,
    % a muted grid, and the axes toolbar hidden (also avoids the "Exported
    % image displays axes toolbar" export warning).
    grid(ax, 'on');
    box(ax, 'off');
    if isprop(ax, 'Toolbar') && ~isempty(ax.Toolbar)
        ax.Toolbar.Visible = 'off';
    end
    ax.GridColor = gridColor;
    ax.GridAlpha = 0.45;
    ax.LineWidth = 0.8;
    ax.TickDir   = 'out';
    ax.Layer     = 'top';
end

function pad_y_axis(ax)
    % Matches display_baseline_energy.m: adds a small headroom margin
    % without pulling a zero baseline away from zero.
    yLimits = ylim(ax);
    if any(~isfinite(yLimits)) || diff(yLimits) <= 0
        return
    end
    pad = diff(yLimits) * 0.06;
    if yLimits(1) == 0
        yLow = 0;
    else
        yLow = yLimits(1) - pad;
    end
    ylim(ax, [yLow, yLimits(2) + pad]);
end

function save_dual(fig, outDir, stem)
    svgPath = fullfile(outDir, char(string(stem) + '.svg'));
    pngPath = fullfile(outDir, char(string(stem) + '.png'));
    try
        exportgraphics(fig, svgPath, 'ContentType', 'vector');
    catch meSvg
        try
            set(fig, 'Renderer', 'painters');
            print(fig, svgPath, '-dsvg');
        catch mePrint
            warning('generate_renewables_investment_cumulative_5yr_figures:svgExportFailed', ...
                ['SVG export failed for "%s". Continuing with PNG only. ' ...
                 'exportgraphics error: %s | print error: %s'], ...
                stem, meSvg.message, mePrint.message);
        end
    end
    exportgraphics(fig, pngPath, 'Resolution', 300);
    close(fig);
end
