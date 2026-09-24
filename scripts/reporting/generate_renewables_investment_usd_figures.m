%% Generate renewables investment-need figures (% of GDP and billion USD)
% Shows total renewables-sector investment (household + government + FDI),
% valued at the investment-good price, for Baseline, Net Zero, Net Zero with
% Green Finance C, and Net Zero with Directive 10 (full).
%
% Per-scenario formula (subsector 3 = Renewables, region 1) — matches the
% convention already validated in display_baseline_energy.m:
%
%   gdpNom_1      = Y_1 * P_1                                  (nominal GDP)
%   RenInvNom_1   = (I_H_3_1 + I_G_3_1 + I_FDI_3_1) * P_INV_3_1  (nominal investment)
%   RenInvToGDP_1 = RenInvNom_1 / gdpNom_1
%
% P_INV_3_1 is the "purchase price of investment goods" (see
% ModFiles/DGE_Model_Declaration.mod) — the correct deflator for I_H/I_G/I_FDI.
% Do NOT use P_I_3_1: despite the similar name, that is the "regional sector
% intermediate inputs price index" (an unrelated price), and using it here
% previously produced numbers roughly 2-4x too high. Likewise gdpNom uses
% Y_1 * P_1 (nominal regional value added), not the aggregate "Y" alone —
% the two are close but not identical, and Y_1*P_1 is what
% display_baseline_energy.m treats as authoritative.
%
% To also report it in billion USD, the ratio is multiplied by an estimate
% of Vietnam's actual nominal GDP in USD for that year:
%
%   GDP_USDbn(t)      = gdpNom_1(t) / gdpNom_1(anchorYear) * gdpBaseBillionUSD
%   RenInvUSDbn(t)     = RenInvToGDP_1(t) * GDP_USDbn(t)
%
% i.e. the model's own nominal-GDP growth is used to project the anchor-year
% USD GDP level forward/backward (the same anchor-and-scale approach used for
% FTE employment in generate_employment_sector_decomposition_figures.m).
% Since RenInvToGDP_1 already divides by gdpNom_1, those terms cancel
% algebraically — RenInvUSDbn(t) = RenInvNom_1(t) *
% (gdpBaseBillionUSD / gdpNom_1(anchorYear)) — so this is a single fixed
% USD-per-model-unit conversion, not a claim about real-world inflation or
% relative-price dynamics; it is only as good as the 2025 GDP anchor.
%
% gdpBaseBillionUSD = 430 (i.e. 430,000 USD million) reuses the same
% Vietnam-2025-GDP anchor already used elsewhere in this repo (see
% scripts/maintenance/create_ee_scenarios_from_expert_inputs.m).

close all;

repoRoot   = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd     = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

outputDir = fullfile(repoRoot, 'ExcelFiles', 'Output');

scenarioSpecs = table( ...
    ["Baseline"; "NZ"; "NZ_GF_C"; "NZ_Dir10_full"], ...
    ["Baseline"; "Net Zero"; "Net Zero GF C"; "Net Zero Directive 10 (full)"], ...
    'VariableNames', {'Name', 'Label'});

plotStartYear = 2025;
plotEndYear   = 2050;

% Real-world USD anchor (see header comment).
anchorYear        = 2025;
gdpBaseBillionUSD = 430;  % Vietnam 2025 GDP, USD billion (430,000 USD million)

% Data version: scenarios (including Baseline) in ExcelFiles/Output/ can
% exist as a plain "<Name>.csv", a "<Name>_replication.csv" and a
% "<Name>.csv" (at any given time, only some may actually be
% present — "" is the suffix RunSimulations.m currently
% writes). Set which variant to prefer; if the preferred one is missing,
% the others are tried in turn (reported via fprintf), so this never has to
% be re-checked scenario by scenario. Same convention as
% generate_renewables_investment_cumulative_5yr_figures.m.
%   "plain"           - prefer "<Name>.csv" (default; falls
%                       back to replication)
%   "replication"     - prefer "<Name>_replication.csv"
%   "plain"           - prefer "<Name>.csv"
dataVersion = "plain";

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

[baselineCsv, baselineResolvedName, baselineUsedFallback] = resolve_scenario_csv(outputDir, "Baseline", dataVersion);
if baselineCsv == ""
    error('generate_renewables_investment_usd_figures:missingBaseline', ...
        'No CSV found for "Baseline" (tried "Baseline.csv", "Baseline_replication.csv" and "Baseline.csv").');
end
if baselineUsedFallback
    fprintf('Scenario "Baseline": preferred "%s" variant not found; using "%s" instead.\n', ...
        dataVersion, baselineResolvedName);
end

baseline = readtable(baselineCsv);
baseline = require_and_sort_years(baseline, plotStartYear, plotEndYear, 'baseline');
require_vars(baseline, ["Year", requiredVars], 'baseline data');

anchorRow = baseline(baseline.Year == anchorYear, :);
if height(anchorRow) ~= 1
    error('generate_renewables_investment_usd_figures:missingAnchorYear', ...
        'Baseline data must contain exactly one row for the anchor year %d to derive the USD scale factor.', ...
        anchorYear);
end
anchorGdpNom = anchorRow.Y_1 * anchorRow.P_1;
billionUSDPerModelUnit = gdpBaseBillionUSD / anchorGdpNom;
fprintf(['USD scale factor: %.6g billion USD per model-Y_1*P_1-unit ' ...
    '(anchored on %d Baseline Y_1*P_1 = %.4g -> %.1f billion USD)\n'], ...
    billionUSDPerModelUnit, anchorYear, anchorGdpNom, gdpBaseBillionUSD);

nScen = height(scenarioSpecs);
years = (plotStartYear:plotEndYear)';

ratioMatrix = nan(numel(years), nScen);
usdMatrix   = nan(numel(years), nScen);
available   = false(nScen, 1);

for iScen = 1:nScen
    sName = string(scenarioSpecs.Name(iScen));

    if sName == "Baseline"
        tbl = baseline;
    else
        [csvPath, resolvedName, usedFallback] = resolve_scenario_csv(outputDir, sName, dataVersion);
        if csvPath == ""
            warning('generate_renewables_investment_usd_figures:missingScenarioFile', ...
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
    end

    series = compute_investment_series(tbl, billionUSDPerModelUnit);

    summaryCsv = fullfile(outDir, 'Renewables_Investment_' + sanitize_filename(sName) + '.csv');
    writetable(series, summaryCsv);

    [tf, loc] = ismember(years, series.Year);
    loc = loc(tf);
    ratioMatrix(tf, iScen) = series.RenInvToGDPPct(loc);
    usdMatrix(tf, iScen)   = series.RenInvUSDBillion(loc);
    available(iScen)       = true;
end

% --- Chart 1: renewables investment as % of GDP ---------------------------
fig1 = figure('Color', 'w', 'Position', [90 90 900 560]);
ax1  = axes(fig1);
hold(ax1, 'on');
plot_scenario_lines(ax1, years, ratioMatrix, scenarioSpecs, available, iwh);
hold(ax1, 'off');
xlim(ax1, [plotStartYear, plotEndYear]);
ylabel(ax1, {'Renewables investment need, 2025-2050', ...
    '% of GDP (household + government + FDI, at P_{INV,3,1})'}, 'Interpreter', 'tex');
style_axis(ax1, iwh.grid);
pad_y_axis(ax1);
legend(ax1, 'Location', 'northoutside', 'Orientation', 'horizontal', ...
    'Box', 'off', 'Interpreter', 'none');
save_dual(fig1, outDir, 'Renewables_Investment_PctGDP_AllScenarios');

% --- Chart 2: renewables investment in billion USD -------------------------
fig2 = figure('Color', 'w', 'Position', [90 90 900 560]);
ax2  = axes(fig2);
hold(ax2, 'on');
plot_scenario_lines(ax2, years, usdMatrix, scenarioSpecs, available, iwh);
hold(ax2, 'off');
xlim(ax2, [plotStartYear, plotEndYear]);
ylabel(ax2, {'Renewables investment need, 2025-2050', 'Billion USD (2025 GDP-anchored)'}, 'Interpreter', 'none');
style_axis(ax2, iwh.grid);
pad_y_axis(ax2);
legend(ax2, 'Location', 'northoutside', 'Orientation', 'horizontal', ...
    'Box', 'off', 'Interpreter', 'none');
save_dual(fig2, outDir, 'Renewables_Investment_BillionUSD_AllScenarios');

fprintf('Renewables investment figures written to: %s\n', outDir);

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
        error('generate_renewables_investment_usd_figures:missingVars', ...
            'Missing variable(s) in %s: %s', label, strjoin(cellstr(missing), ', '));
    end
end

function [csvPath, resolvedName, usedFallback] = resolve_scenario_csv(outputDir, sName, dataVersion)
    % Resolves the CSV for scenario sName according to the preferred
    % dataVersion ("replication" or "plain"), falling back to the other
    % variant if the preferred one doesn't exist. Returns csvPath = "" if
    % neither is found. usedFallback is true iff the preferred variant was
    % NOT the one actually used. Same convention as
    % generate_renewables_investment_cumulative_5yr_figures.m.
    plainName          = sName;
    replicationName    = sName + "_replication";

    switch dataVersion
        case "plain"
            candidates = [plainName, replicationName];
        case "replication"
            candidates = [replicationName, plainName];
        otherwise
            error('generate_renewables_investment_usd_figures:badDataVersion', ...
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
    out.Year               = tbl.Year;
    out.RenInvToGDPPct     = ratio .* 100;
    out.GDP_USDBillion     = gdpNom .* billionUSDPerModelUnit;
    out.RenInvUSDBillion   = ratio .* out.GDP_USDBillion;
end

function z = safe_divide(a, b)
    z = a ./ b;
    z(~isfinite(z)) = NaN;
end

function plot_scenario_lines(ax, years, dataMatrix, scenarioSpecs, available, iwh)
    for iScen = 1:height(scenarioSpecs)
        if ~available(iScen)
            continue
        end
        sName = string(scenarioSpecs.Name(iScen));
        sLabel = string(scenarioSpecs.Label(iScen));
        if sName == "Baseline"
            lineColor = iwh.baseline;
            lineStyle = '-';
        else
            style     = iwh_scenario_style(sName);
            lineColor = style.Color;
            lineStyle = style.LineStyle;
        end
        plot(ax, years, dataMatrix(:, iScen), lineStyle, ...
            'Color', lineColor, 'LineWidth', 2.0, 'DisplayName', char(sLabel));
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
            warning('generate_renewables_investment_usd_figures:svgExportFailed', ...
                ['SVG export failed for "%s". Continuing with PNG only. ' ...
                 'exportgraphics error: %s | print error: %s'], ...
                stem, meSvg.message, mePrint.message);
        end
    end
    exportgraphics(fig, pngPath, 'Resolution', 300);
    close(fig);
end

function out = sanitize_filename(in)
    out = regexprep(string(in), '[^A-Za-z0-9_\-]', '_');
end
