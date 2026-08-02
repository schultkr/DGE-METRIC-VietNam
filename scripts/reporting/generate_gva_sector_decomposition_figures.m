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
baselineCsv = fullfile(outputDir, 'Baseline.csv');

scenarioSpecs = table( ...
    ["Baseline"; "EE_Directive10"; "PDP8_GF_C"], ...
    ["revised PDP 8 high"; "EE Directive 10"; "PDP 8 GF C"], ...
    'VariableNames', {'Name', 'Label'});

nSectors      = 5;
sectorNames   = ["Primary", "Fossil", "Renewables", "Secondary", "Tertiary"];
plotStartYear = 2025;
plotEndYear   = 2050;

outDir = fullfile(repoRoot, 'Figures', 'ScenarioComparisons', 'GVADecomposition');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

sectorColors = [ ...
    0.34 0.62 0.31;   % Primary    — muted green
    0.40 0.40 0.40;   % Fossil     — dark grey
    0.99 0.75 0.05;   % Renewables — amber
    0.21 0.47 0.75;   % Secondary  — steel blue
    0.84 0.37 0.11];  % Tertiary   — burnt orange

colors = struct();
colors.total   = [0.10 0.10 0.10];
colors.residual = [0.55 0.55 0.55];

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

    csvPath = fullfile(outputDir, sName + ".csv");
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
    xlabel(ax, 'Year');
    ylabel(ax, 'Percentage points of baseline GDP');
    title(ax, sprintf('%s vs Baseline — GVA by economic activity', sLabel), ...
        'Interpreter', 'none');
    legend(ax, 'Location', 'bestoutside', 'Box', 'off', 'Interpreter', 'none');

    save_dual(fig, outDir, 'GVA_Sector_Decomposition_' + sanitize_filename(sName));
    fprintf('Saved GVA sector decomposition for %s to %s\n', sName, outDir);
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
