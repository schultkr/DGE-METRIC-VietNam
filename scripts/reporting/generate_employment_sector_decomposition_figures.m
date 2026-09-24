%% Generate employment-by-sector decomposition figures vs Baseline
% Shows full-time-equivalent (FTE) employment deviations relative to
% baseline, decomposed into sectoral contributions consistent with the
% model identity:
%
%   FTE_1   = N_1 * LF_1
%           = sum_s (N_s_1 * LF_1)   (s = 1..5)
%
% N_s_1 is the model's "hours worked relative to potential hours" ratio for
% sector s (region 1); LF_1 is the regional labour force. Their product is
% the model's own definition of total employment (see identities.mod,
% 'aggregate employment'), expressed in full-time-equivalent terms, but in
% the model's internal normalized units (PoP0_1_p = 1 in the base year),
% not literal headcounts.
%
% To report real-world numbers, model-unit FTE is rescaled to million
% persons using an external anchor: Vietnam had ~51.3 million employed
% persons in 2025 (vnEmployment2025Persons below), and a standard workday
% is assumed to be 8 hours (vnFullTimeHoursPerDay) — i.e. the 2025 headcount
% is treated as 2025 FTE. The scale factor is derived once from the
% Baseline scenario's own 2025 model-unit FTE level and then applied
% uniformly across all years and scenarios, so it is a pure unit
% conversion and does not alter the shape of any series or the exactness
% of the sectoral decomposition identity.
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
sversion    = report_version_suffix();  % "" unless DGE_WORKBOOK_VERSION overrides
baselineCsv = fullfile(outputDir, ['Baseline' sversion '.csv']);

scenarioSpecs = table( ...
    ["Baseline"; "EE_Dir10_full"; "PDP8_GF_C"; "NZ"; "NZ_GF_C"; "NZ_Dir10_full"], ...
    ["revised PDP 8 high"; "Directive 10 (full)"; "PDP 8 GF C"; "Net Zero"; "Net Zero GF C"; "Net Zero Directive 10 (full)"], ...
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

% Real-world FTE anchor (see header comment).
anchorYear               = 2025;
vnEmployment2025Persons  = 51.3e6;  % Vietnam employed persons, 2025
vnFullTimeHoursPerDay    = 8;       % assumed hours/day defining 1 FTE

outDir = fullfile(repoRoot, 'Figures', 'ScenarioComparisons', 'EmploymentDecomposition');
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

sectorNvars = arrayfun(@(s) sprintf('N_%d_1', s), 1:nSectors, 'UniformOutput', false);
requiredVars = ["N_1", "LF_1", sectorNvars{:}];

baseline = readtable(baselineCsv);
baseline = require_and_sort_years(baseline, plotStartYear, plotEndYear, 'baseline');
require_vars(baseline, ["Year", requiredVars], 'baseline data');

anchorRow = baseline(baseline.Year == anchorYear, :);
if height(anchorRow) ~= 1
    error('generate_employment_sector_decomposition_figures:missingAnchorYear', ...
        'Baseline data must contain exactly one row for the anchor year %d to derive the FTE scale factor.', ...
        anchorYear);
end
anchorModelFTE = anchorRow.N_1 * anchorRow.LF_1;
personsPerModelUnit = vnEmployment2025Persons / anchorModelFTE;
fprintf(['FTE scale factor: %.4g persons per model unit ' ...
    '(anchored on %d Baseline N_1*LF_1 = %.6g -> %.1f million persons; %dh/day = 1 FTE)\n'], ...
    personsPerModelUnit, anchorYear, anchorModelFTE, vnEmployment2025Persons / 1e6, vnFullTimeHoursPerDay);

for iScen = 1:height(scenarioSpecs)
    sName  = string(scenarioSpecs.Name(iScen));
    sLabel = string(scenarioSpecs.Label(iScen));

    if sName == "Baseline"
        continue
    end

    csvPath = fullfile(outputDir, sName + sversion + ".csv");
    if ~isfile(csvPath)
        warning('generate_employment_sector_decomposition_figures:missingScenarioFile', ...
            'Scenario file not found for "%s": %s. Skipping.', sName, csvPath);
        continue
    end

    scenario = readtable(csvPath);
    require_vars(scenario, ["Year", requiredVars], char(sName) + " data");

    commonYears = intersect(baseline.Year(:), scenario.Year(:));
    commonYears = commonYears(commonYears >= plotStartYear & commonYears <= plotEndYear);
    commonYears = sort(commonYears(:));
    if isempty(commonYears)
        warning('generate_employment_sector_decomposition_figures:noCommonYears', ...
            'No common years found for "%s". Skipping.', sName);
        continue
    end

    baselineAligned = sortrows(baseline(ismember(baseline.Year, commonYears), :), 'Year');
    scenarioAligned  = sortrows(scenario(ismember(scenario.Year,  commonYears), :), 'Year');

    decomp = compute_decomposition(baselineAligned, scenarioAligned, ...
                                   nSectors, sectorNames, personsPerModelUnit);

    if any(abs(decomp.ResidualPctOfBaseline) > 1e-8)
        warning('generate_employment_sector_decomposition_figures:nonZeroResidual', ...
            'Non-zero decomposition residual detected for "%s" (max abs = %.3g pp of baseline FTE employment).', ...
            sName, max(abs(decomp.ResidualPctOfBaseline)));
    end

    summaryCsv = fullfile(outDir, 'Employment_FTE_Decomposition_' + sanitize_filename(sName) + '.csv');
    writetable(decomp, summaryCsv);

    % Build matrix: columns = sectors, rows = years — absolute FTE change,
    % in million persons.
    stackedData = zeros(height(decomp), nSectors);
    for s = 1:nSectors
        stackedData(:, s) = decomp.(['Employment_' char(sectorNames(s)) '_FTE_Change_MillionPersons']);
    end

    fig = figure('Color', 'w', 'Position', [80 80 1120 560]);
    bh  = bar(decomp.Year, stackedData, 'stacked');
    ax  = gca;
    hold(ax, 'on');

    for s = 1:nSectors
        bh(s).FaceColor  = sectorColors(s, :);
        bh(s).DisplayName = sectorNames(s);
    end

    plot(ax, decomp.Year, decomp.EmploymentFTEDeviation_MillionPersons, '-', ...
        'Color', colors.total, 'LineWidth', 2.0, 'DisplayName', 'Total FTE employment change');

    yline(ax, 0, ':', 'Color', colors.residual, 'LineWidth', 1.0, 'HandleVisibility', 'off');
    hold(ax, 'off');
    grid(ax, 'on');
    box(ax, 'off');
    ylabel(ax, {sprintf('%s vs Baseline — employment by economic activity', sLabel), ...
        'Change in full-time-equivalent employment (million persons)'}, 'Interpreter', 'none');
    legend(ax, 'Location', 'bestoutside', 'Box', 'off', 'Interpreter', 'none');

    save_dual(fig, outDir, 'Employment_FTE_Decomposition_' + sanitize_filename(sName));
    fprintf('Saved employment FTE decomposition for %s to %s\n', sName, outDir);

    % --- 5-year period average companion chart --------------------------
    periodVars = ["EmploymentFTEDeviation_MillionPersons", ...
        arrayfun(@(s) "Employment_" + sectorNames(s) + "_FTE_Change_MillionPersons", 1:nSectors)];
    periodDecomp = aggregate_to_periods(decomp, periodStartYear, plotEndYear, periodLength, periodVars);

    periodCsv = fullfile(outDir, 'Employment_FTE_Decomposition_5yr_' + sanitize_filename(sName) + '.csv');
    writetable(periodDecomp, periodCsv);

    stackedDataP = zeros(height(periodDecomp), nSectors);
    for s = 1:nSectors
        stackedDataP(:, s) = periodDecomp.("Employment_" + sectorNames(s) + "_FTE_Change_MillionPersons");
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

    plot(axP, periodCats, periodDecomp.EmploymentFTEDeviation_MillionPersons, '-o', ...
        'Color', colors.total, 'LineWidth', 2.0, 'MarkerFaceColor', colors.total, ...
        'DisplayName', 'Total FTE employment change');

    yline(axP, 0, ':', 'Color', colors.residual, 'LineWidth', 1.0, 'HandleVisibility', 'off');
    hold(axP, 'off');
    grid(axP, 'on');
    box(axP, 'off');
    ylabel(axP, {sprintf('%s vs Baseline — employment by economic activity', sLabel), ...
        '5-year average change in FTE employment (million persons)'}, 'Interpreter', 'none');
    legend(axP, 'Location', 'bestoutside', 'Box', 'off', 'Interpreter', 'none');

    save_dual(figP, outDir, 'Employment_FTE_Decomposition_5yr_' + sanitize_filename(sName));
    fprintf('Saved 5-year employment FTE decomposition for %s to %s\n', sName, outDir);
end

fprintf('Employment FTE decomposition figures written to: %s\n', outDir);

%% Level chart: total FTE employment evolution, 2025-2050, all scenarios ---
% Unlike the deviation charts above, this shows each scenario's own level
% (not its difference from Baseline), so Baseline is plotted alongside the
% others rather than skipped.

levelYears     = (plotStartYear:plotEndYear)';
nScenLevel     = height(scenarioSpecs);
levelMatrix    = nan(numel(levelYears), nScenLevel);
levelLabels    = strings(nScenLevel, 1);
levelAvailable = false(nScenLevel, 1);

for iScen = 1:nScenLevel
    sName = string(scenarioSpecs.Name(iScen));

    if sName == "Baseline"
        tbl = baseline;
        levelLabels(iScen) = "Baseline";
    else
        csvPath = fullfile(outputDir, sName + sversion + ".csv");
        if ~isfile(csvPath)
            warning('generate_employment_sector_decomposition_figures:missingScenarioFile', ...
                'Scenario file not found for "%s": %s. Skipping in level chart.', sName, csvPath);
            continue
        end
        tbl = readtable(csvPath);
        require_vars(tbl, ["Year", "N_1", "LF_1"], char(sName) + " data");
        tbl = require_and_sort_years(tbl, plotStartYear, plotEndYear, char(sName));
        levelLabels(iScen) = string(scenarioSpecs.Label(iScen));
    end

    [tf, loc] = ismember(levelYears, tbl.Year);
    loc = loc(tf);
    fteLevel = tbl.N_1(loc) .* tbl.LF_1(loc) .* (personsPerModelUnit / 1e6);
    levelMatrix(tf, iScen) = fteLevel;
    levelAvailable(iScen)  = true;
end

levelTable = array2table(levelMatrix, 'VariableNames', cellstr(scenarioSpecs.Name));
levelTable = addvars(levelTable, levelYears, 'Before', 1, 'NewVariableNames', 'Year');
writetable(levelTable, fullfile(outDir, 'Employment_FTE_Level_AllScenarios.csv'));

fig = figure('Color', 'w', 'Position', [80 80 1120 560]);
ax  = axes(fig);
hold(ax, 'on');

for iScen = 1:nScenLevel
    if ~levelAvailable(iScen)
        continue
    end
    sName = string(scenarioSpecs.Name(iScen));
    if sName == "Baseline"
        lineColor = iwh.baseline;
        lineStyle = '-';
    else
        style     = iwh_scenario_style(sName);
        lineColor = style.Color;
        lineStyle = style.LineStyle;
    end
    plot(ax, levelYears, levelMatrix(:, iScen), lineStyle, ...
        'Color', lineColor, 'LineWidth', 2.0, 'DisplayName', char(levelLabels(iScen)));
end

hold(ax, 'off');
grid(ax, 'on');
box(ax, 'off');
xlim(ax, [plotStartYear, plotEndYear]);
ylabel(ax, {'Full-time-equivalent employment, 2025-2050', 'Million persons'}, 'Interpreter', 'none');
legend(ax, 'Location', 'bestoutside', 'Box', 'off', 'Interpreter', 'none');

save_dual(fig, outDir, 'Employment_FTE_Level_AllScenarios');
fprintf('Saved total FTE employment level evolution (all scenarios) to %s\n', outDir);

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
        error('generate_employment_sector_decomposition_figures:missingVars', ...
            'Missing variable(s) in %s: %s', label, strjoin(cellstr(missing), ', '));
    end
end

function out = compute_decomposition(baseTbl, scenTbl, nSectors, sectorNames, personsPerModelUnit)
    % Identity: FTE_1 = N_1 * LF_1 = sum_s (N_s_1 * LF_1), in model units;
    % personsPerModelUnit rescales to real-world million persons (a pure
    % unit conversion, so the identity holds exactly in both units).
    millionPersonsPerModelUnit = personsPerModelUnit / 1e6;

    baseEmploymentFTE = baseTbl.N_1 .* baseTbl.LF_1;
    scenEmploymentFTE = scenTbl.N_1 .* scenTbl.LF_1;

    out      = table();
    out.Year = baseTbl.Year;
    out.BaselineEmploymentFTE_ModelUnits  = baseEmploymentFTE;
    out.ScenarioEmploymentFTE_ModelUnits  = scenEmploymentFTE;
    out.EmploymentFTEDeviation_ModelUnits = scenEmploymentFTE - baseEmploymentFTE;
    out.BaselineEmploymentFTE_MillionPersons  = baseEmploymentFTE  .* millionPersonsPerModelUnit;
    out.ScenarioEmploymentFTE_MillionPersons  = scenEmploymentFTE  .* millionPersonsPerModelUnit;
    out.EmploymentFTEDeviation_MillionPersons = out.EmploymentFTEDeviation_ModelUnits .* millionPersonsPerModelUnit;
    out.EmploymentFTEDeviationPctOfBaseline = safe_divide(out.EmploymentFTEDeviation_ModelUnits, baseEmploymentFTE) .* 100;

    componentSum = zeros(height(baseTbl), 1);
    for s = 1:nSectors
        Nvar = sprintf('N_%d_1', s);
        base_emp_fte = baseTbl.(Nvar) .* baseTbl.LF_1;
        scen_emp_fte = scenTbl.(Nvar) .* scenTbl.LF_1;
        delta        = scen_emp_fte - base_emp_fte;
        fieldName = ['Employment_' char(sectorNames(s))];
        out.([fieldName '_FTE_Change_ModelUnits'])     = delta;
        out.([fieldName '_FTE_Change_MillionPersons']) = delta .* millionPersonsPerModelUnit;
        out.([fieldName '_FTE_PctOfBaseline'])         = safe_divide(delta, baseEmploymentFTE) .* 100;
        componentSum = componentSum + delta;
    end

    out.Residual_ModelUnits     = out.EmploymentFTEDeviation_ModelUnits - componentSum;
    out.Residual_MillionPersons = out.Residual_ModelUnits .* millionPersonsPerModelUnit;
    out.ResidualPctOfBaseline   = safe_divide(out.Residual_ModelUnits, baseEmploymentFTE) .* 100;
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
        error('generate_employment_sector_decomposition_figures:noPeriods', ...
            'Need at least %d years from %d to build one %d-year period.', ...
            periodLength, periodStartYear, periodLength);
    end

    usedRows = rows(1:(nPeriods * periodLength));
    if numel(usedRows) < numel(rows)
        trailingYears = years(rows((nPeriods * periodLength + 1):end));
        warning('generate_employment_sector_decomposition_figures:trailingPeriodYears', ...
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
            warning('generate_employment_sector_decomposition_figures:svgExportFailed', ...
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
