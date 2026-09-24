%% Generate GVA-by-sector decomposition figures vs Baseline
% Shows percentage-point deviations of GDP relative to baseline, decomposed
% into sectoral contributions consistent with the model identity:
%
%   Y_1 = sum_s  P_s_1 * Y_s_1   (s = 1..5)
%
% Sectors:
%   1 — Primary       (agriculture, mining, forestry)
%   2 — Fossil        (coal, oil, gas)
%   3 — Renewables    (wind, solar, hydro)
%   4 — Secondary     (manufacturing, construction)
%   5 — Tertiary      (services)

close all;

repoRoot   = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd     = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

outputDir   = fullfile(repoRoot, 'ExcelFiles', 'Output');
sversion    = report_version_suffix();  % "_replication_fix" unless DGE_WORKBOOK_VERSION overrides
baselineCsv = fullfile(outputDir, ['Baseline' sversion '.csv']);

scenarioSpecs = table( ...
    ["Baseline"; "EE_Dir10_full"; "PDP8_GF_C"], ...
    ["revised PDP 8 high"; "Directive 10 (full)"; "PDP 8 GF C"], ...
    'VariableNames', {'Name', 'Label'});

nSectors      = 5;
sectorNames   = ["Primary", "Fossil", "Renewables", "Secondary", "Tertiary"];
plotStartYear = 2025;
plotEndYear   = 2050;

% 5-year period averaging (matches the period-comparison convention used in
% display_baseline_energy.m): 2025 is the base year (zero deviation by
% construction), so periods start in 2026.
periodStartYear = 2026;
periodLength    = 5;

outDir = fullfile(repoRoot, 'Figures', 'ScenarioComparisons', 'GVADecomposition');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

iwh = iwh_colors();
sectorColors = [ ...
    iwh.green;        % Primary    — IWH secondary green
    iwh.mediumBlue;   % Fossil     — IWH medium blue
    iwh.yellow;       % Renewables — IWH secondary yellow
    iwh.primaryBlue;  % Secondary  — IWH primary blue
    iwh.orange];      % Tertiary   — IWH secondary orange

colors = struct();
colors.total   = iwh.slate;
colors.residual = iwh.slate40;

set(groot, 'defaultAxesFontSize', 12, ...
           'defaultTextFontSize', 12, ...
           'defaultLegendFontSize', 10, ...
           'defaultAxesFontName', 'Arial', ...
           'defaultTextFontName', 'Arial');

sectorYvars = arrayfun(@(s) sprintf('Y_%d_1', s), 1:nSectors, 'UniformOutput', false);
sectorPvars = arrayfun(@(s) sprintf('P_%d_1', s), 1:nSectors, 'UniformOutput', false);
requiredVars = ["Y_1", sectorYvars{:}, sectorPvars{:}];

baseline = readtable(baselineCsv);
baseline = require_and_sort_years(baseline, plotStartYear, plotEndYear, 'baseline');
require_vars(baseline, ["Year", requiredVars], 'baseline data');

for iScen = 1:height(scenarioSpecs)
    sName  = string(scenarioSpecs.Name(iScen));
    sLabel = string(scenarioSpecs.Label(iScen));

    if sName == "Baseline"
        continue
    end

    csvPath = fullfile(outputDir, sName + sversion + ".csv");
    if ~isfile(csvPath)
        warning('generate_gva_sector_decomposition_figures:missingScenarioFile', ...
            'Scenario file not found for "%s": %s. Skipping.', sName, csvPath);
        continue
    end

    scenario = readtable(csvPath);
    require_vars(scenario, ["Year", requiredVars], char(sName) + " data");

    commonYears = intersect(baseline.Year(:), scenario.Year(:));
    commonYears = commonYears(commonYears >= plotStartYear & commonYears <= plotEndYear);
    commonYears = sort(commonYears(:));
    if isempty(commonYears)
        warning('generate_gva_sector_decomposition_figures:noCommonYears', ...
            'No common years found for "%s". Skipping.', sName);
        continue
    end

    baselineAligned = sortrows(baseline(ismember(baseline.Year, commonYears), :), 'Year');
    scenarioAligned  = sortrows(scenario(ismember(scenario.Year,  commonYears), :), 'Year');

    decomp = compute_decomposition(baselineAligned, scenarioAligned, ...
                                   nSectors, sectorNames);

    if any(abs(decomp.ResidualPctOfBaseline) > 1e-8)
        warning('generate_gva_sector_decomposition_figures:nonZeroResidual', ...
            'Non-zero decomposition residual detected for "%s" (max abs = %.3g pp of baseline GDP).', ...
            sName, max(abs(decomp.ResidualPctOfBaseline)));
    end

    summaryCsv = fullfile(outDir, 'GVA_Sector_Decomposition_' + sanitize_filename(sName) + '.csv');
    writetable(decomp, summaryCsv);

    % Build matrix: columns = sectors, rows = years
    stackedData = zeros(height(decomp), nSectors);
    for s = 1:nSectors
        stackedData(:, s) = decomp.(['GVA_' char(sectorNames(s)) '_PctOfBaseline']);
    end

    fig = figure('Color', 'w', 'Position', [80 80 1120 560]);
    bh  = bar(decomp.Year, stackedData, 'stacked');
    ax  = gca;
    hold(ax, 'on');

    for s = 1:nSectors
        bh(s).FaceColor  = sectorColors(s, :);
        bh(s).DisplayName = sectorNames(s);
    end

    plot(ax, decomp.Year, decomp.GDPDeviationPctOfBaseline, '-', ...
        'Color', colors.total, 'LineWidth', 2.0, 'DisplayName', 'Total GDP change');

    yline(ax, 0, ':', 'Color', colors.residual, 'LineWidth', 1.0, 'HandleVisibility', 'off');
    hold(ax, 'off');
    grid(ax, 'on');
    box(ax, 'off');
    ylabel(ax, {sprintf('%s vs Baseline — GVA by economic activity', sLabel), ...
        'Percentage points of baseline GDP'}, 'Interpreter', 'none');
    legend(ax, 'Location', 'bestoutside', 'Box', 'off', 'Interpreter', 'none');

    save_dual(fig, outDir, 'GVA_Sector_Decomposition_' + sanitize_filename(sName));
    fprintf('Saved GVA sector decomposition for %s to %s\n', sName, outDir);

    % --- 5-year period average companion chart --------------------------
    periodVars = ["GDPDeviationPctOfBaseline", ...
        arrayfun(@(s) "GVA_" + sectorNames(s) + "_PctOfBaseline", 1:nSectors)];
    periodDecomp = aggregate_to_periods(decomp, periodStartYear, plotEndYear, periodLength, periodVars);

    periodCsv = fullfile(outDir, 'GVA_Sector_Decomposition_5yr_' + sanitize_filename(sName) + '.csv');
    writetable(periodDecomp, periodCsv);

    stackedDataP = zeros(height(periodDecomp), nSectors);
    for s = 1:nSectors
        stackedDataP(:, s) = periodDecomp.("GVA_" + sectorNames(s) + "_PctOfBaseline");
    end

    figP = figure('Color', 'w', 'Position', [80 80 1120 560]);
    periodCats = categorical(periodDecomp.Period, periodDecomp.Period);
    bhP = bar(periodCats, stackedDataP, 'stacked');
    axP = gca;
    hold(axP, 'on');

    for s = 1:nSectors
        bhP(s).FaceColor  = sectorColors(s, :);
        bhP(s).DisplayName = sectorNames(s);
    end

    plot(axP, periodCats, periodDecomp.GDPDeviationPctOfBaseline, '-o', ...
        'Color', colors.total, 'LineWidth', 2.0, 'MarkerFaceColor', colors.total, ...
        'DisplayName', 'Total GDP change');

    yline(axP, 0, ':', 'Color', colors.residual, 'LineWidth', 1.0, 'HandleVisibility', 'off');
    hold(axP, 'off');
    grid(axP, 'on');
    box(axP, 'off');
    ylabel(axP, {sprintf('%s vs Baseline — GVA by economic activity', sLabel), ...
        '5-year average, percentage points of baseline GDP'}, 'Interpreter', 'none');
    legend(axP, 'Location', 'bestoutside', 'Box', 'off', 'Interpreter', 'none');

    save_dual(figP, outDir, 'GVA_Sector_Decomposition_5yr_' + sanitize_filename(sName));
    fprintf('Saved 5-year GVA sector decomposition for %s to %s\n', sName, outDir);
end

fprintf('GVA sector decomposition figures written to: %s\n', outDir);

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
        error('generate_gva_sector_decomposition_figures:missingVars', ...
            'Missing variable(s) in %s: %s', label, strjoin(cellstr(missing), ', '));
    end
end

function out = compute_decomposition(baseTbl, scenTbl, nSectors, sectorNames)
    % Identity: Y_1 = sum_s  P_s_1 * Y_s_1
    baseGDP = baseTbl.Y_1;

    out      = table();
    out.Year = baseTbl.Year;
    out.BaselineGDP             = baseTbl.Y_1;
    out.ScenarioGDP             = scenTbl.Y_1;
    out.GDPDeviation            = scenTbl.Y_1 - baseTbl.Y_1;
    out.GDPDeviationPctOfBaseline = safe_divide(out.GDPDeviation, baseGDP) .* 100;

    componentSum = zeros(height(baseTbl), 1);
    for s = 1:nSectors
        Yvar = sprintf('Y_%d_1', s);
        Pvar = sprintf('P_%d_1', s);
        base_gva = baseTbl.(Pvar) .* baseTbl.(Yvar);
        scen_gva = scenTbl.(Pvar) .* scenTbl.(Yvar);
        delta    = scen_gva - base_gva;
        fieldName = ['GVA_' char(sectorNames(s))];
        out.([fieldName '_Change'])        = delta;
        out.([fieldName '_PctOfBaseline']) = safe_divide(delta, baseGDP) .* 100;
        componentSum = componentSum + delta;
    end

    out.Residual              = out.GDPDeviation - componentSum;
    out.ResidualPctOfBaseline = safe_divide(out.Residual, baseGDP) .* 100;
end

function z = safe_divide(a, b)
    z = a ./ b;
    z(~isfinite(z)) = NaN;
end

function periodTbl = aggregate_to_periods(tbl, periodStartYear, periodEndYear, periodLength, varsToAverage)
    % Splits tbl.Year(periodStartYear:periodEndYear) into consecutive
    % non-overlapping periodLength-year blocks and averages each variable
    % in varsToAverage within each block. Trailing years that don't fill a
    % full block are dropped (reported via warning).
    years = tbl.Year;
    rows  = find(years >= periodStartYear & years <= periodEndYear);
    nPeriods = floor(numel(rows) / periodLength);
    if nPeriods < 1
        error('generate_gva_sector_decomposition_figures:noPeriods', ...
            'Need at least %d years from %d to build one %d-year period.', ...
            periodLength, periodStartYear, periodLength);
    end

    usedRows = rows(1:(nPeriods * periodLength));
    if numel(usedRows) < numel(rows)
        trailingYears = years(rows((nPeriods * periodLength + 1):end));
        warning('generate_gva_sector_decomposition_figures:trailingPeriodYears', ...
            'Dropping %d trailing year(s) that do not fill a full %d-year period: %s.', ...
            numel(trailingYears), periodLength, strjoin(string(trailingYears'), ', '));
    end

    periodIdx = reshape(usedRows, periodLength, nPeriods)';

    periodTbl = table();
    periodTbl.Period    = compose('%d-%d', years(periodIdx(:, 1)), years(periodIdx(:, end)));
    periodTbl.StartYear = years(periodIdx(:, 1));
    periodTbl.EndYear   = years(periodIdx(:, end));

    varsToAverage = string(varsToAverage);
    for iVar = 1:numel(varsToAverage)
        v = varsToAverage(iVar);
        vals = tbl.(v);
        periodMeans = zeros(nPeriods, 1);
        for p = 1:nPeriods
            periodMeans(p) = mean(vals(periodIdx(p, :)));
        end
        periodTbl.(v) = periodMeans;
    end
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
            warning('generate_gva_sector_decomposition_figures:svgExportFailed', ...
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
