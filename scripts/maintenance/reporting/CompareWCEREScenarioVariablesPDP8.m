%% Compare Baseline with selected scenarios for user-selected variables
%  Run after the model has written the baseline and scenario CSV files.
%
%  Edit the configuration block below to choose:
%    - one or more scenarios in scenarioSpecs
%    - plotStartYear / plotEndYear
%    - plotSubfolder under Figures for saving plots
%    - plotSpecs: variable names, display labels, comparison transform,
%      and deviation transform
%
%  Transform options:
%    "index"         plot Baseline and scenario indexed to first plot year = 100
%    "level"         plot raw levels
%    "pct_deviation" plot 100 * (scenario / Baseline - 1)
%    "difference"    plot scenario - Baseline
%
%  Deviation options:
%    "pct_deviation" plot 100 * (scenario / Baseline - 1)
%    "difference"    plot scenario - Baseline

close all;

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd));
cd(repoRoot);
setup_paths();

% ---- user configuration -------------------------------------------------
outputDir = fullfile(repoRoot, 'ExcelFiles', 'Output');
baselineCsv = resolve_output_csv(outputDir, "Baseline");

% New scenarios for slide updates. Add/remove rows as needed.
scenarioSpecs = table( ...
    ["EE_Directive10"; "PDP8_GF_A"; "NZ"; "NZ_GF_A"], ...
    ["Directive 10"; "PDP8 GF A"; "NZ"; "NZ GF A"], ...
    'VariableNames', {'Name', 'Label'});

plotStartYear = 2025;
plotEndYear   = 2050;

exportOptions = struct();
exportOptions.Pdf = false;              % Set true for vector PDF exports.
exportOptions.SinglePlotsForSlides = true;  % One plot per variable.

plotOptions = struct();
plotOptions.PctDeviationVisibilityThreshold = 0.01; % percentage points

% Subfolder under Figures where this script saves outputs.
% Examples: 'ScenarioComparisons/Finance', 'PDP8/Slides'
plotSubfolder = 'ScenarioComparisons/WCERE';

% Add/remove rows here to choose variables. Variable names must match the
% MATLAB table names created by readtable from the output CSV headers.
plotSpecs = table( ...
    ["Y_1";   "C_1";          "I_1";       "E_1";       ...
     "EE_1";  "Q_3_1";        "K_3_1";     "PE_1"], ...
    ["GDP";   "Consumption";  "Investment"; "Emissions"; ...
     "Energy efficiency"; "Renewable production"; ...
     "Renewable capital"; "Emission price"], ...
    ["index"; "index";        "index";     "index";     ...
     "index"; "index";        "index";     "level"], ...
    ["pct_deviation"; "pct_deviation"; "pct_deviation"; "pct_deviation"; ...
     "pct_deviation"; "pct_deviation"; "pct_deviation"; "difference"], ...
    'VariableNames', {'Variable', 'Label', 'Transform', 'Deviation'});

outDir = fullfile(repoRoot, 'Figures', plotSubfolder);
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

slideOutDir = fullfile(outDir, 'SlideDeckSingles');
if ~exist(slideOutDir, 'dir')
    mkdir(slideOutDir);
end

% ---- style --------------------------------------------------------------
colors = struct();
colors.baseline = [0.25 0.25 0.25];
colors.scenario = [0.00 0.45 0.70];
colors.delta    = [0.84 0.37 0.00];
colors.zero     = [0.45 0.45 0.45];
colors.grid     = [0.82 0.82 0.82];

set(groot, 'defaultAxesFontSize', 12, ...
           'defaultTextFontSize', 12, ...
           'defaultLegendFontSize', 10, ...
           'defaultAxesFontName', 'Arial', ...
           'defaultTextFontName', 'Arial');

% ---- load and align -----------------------------------------------------
baseline = readtable(baselineCsv);
plotSpecs = normalize_plot_specs(plotSpecs);
require_vars(baseline, ["Year"; plotSpecs.Variable], 'baseline data');

loadedScenarios = struct('Name', {}, 'Label', {}, 'Data', {});
for iScen = 1:height(scenarioSpecs)
    sName = string(scenarioSpecs.Name(iScen));
    sLabel = string(scenarioSpecs.Label(iScen));
    sCsv = resolve_output_csv(outputDir, sName, false);
    if ~isfile(sCsv)
        warning('CompareBaselineScenarioVariables:missingScenarioFile', ...
            'Scenario file not found for "%s": %s. Skipping.', sName, sCsv);
        continue
    end

    sData = readtable(sCsv);
    require_vars(sData, ["Year"; plotSpecs.Variable], char(sName) + " data");
    loadedScenarios(end+1).Name = char(sName); %#ok<AGROW>
    loadedScenarios(end).Label = char(sLabel);
    loadedScenarios(end).Data = sData;
end

if isempty(loadedScenarios)
    error('CompareBaselineScenarioVariables:noScenarioData', ...
        'No scenario CSV files were loaded. Check scenarioSpecs and ExcelFiles/Output.');
end

commonYears = baseline.Year(:);
for iScen = 1:numel(loadedScenarios)
    commonYears = intersect(commonYears, loadedScenarios(iScen).Data.Year(:));
end
commonYears = commonYears(commonYears >= plotStartYear & commonYears <= plotEndYear);
commonYears = sort(commonYears(:));

if isempty(commonYears)
    error('CompareBaselineScenarioVariables:noCommonYears', ...
        'No common years between %d and %d across baseline and selected scenarios.', ...
        plotStartYear, plotEndYear);
end

baseline = sortrows(baseline(ismember(baseline.Year, commonYears), :), 'Year');
for iScen = 1:numel(loadedScenarios)
    s = loadedScenarios(iScen).Data;
    loadedScenarios(iScen).Data = sortrows(s(ismember(s.Year, commonYears), :), 'Year');
end

years = baseline.Year(:);
yearRange = [years(1), years(end)];

if exportOptions.SinglePlotsForSlides
    for iPlot = 1:height(plotSpecs)
        spec = plotSpecs(iPlot, :);

        % Baseline + all scenarios (comparison transform)
        fig = make_figure(sprintf('%s: Baseline and scenarios', spec.Label), ...
            [100 100 860 560]);
        ax = axes('Parent', fig);
        plot(ax, years, compute_transform_series(baseline.(char(spec.Variable)), ...
            baseline.(char(spec.Variable)), string(spec.Transform), plotOptions), ...
            '-', 'Color', colors.baseline, 'LineWidth', 1.9, 'DisplayName', 'Baseline');
        hold(ax, 'on');
        scenarioColors = lines(max(3, numel(loadedScenarios)));
        for iScen = 1:numel(loadedScenarios)
            sData = loadedScenarios(iScen).Data;
            yVals = compute_transform_series(sData.(char(spec.Variable)), ...
                baseline.(char(spec.Variable)), string(spec.Transform), plotOptions);
            plot(ax, years, yVals, '-', 'Color', scenarioColors(iScen, :), ...
                'LineWidth', 1.8, 'DisplayName', loadedScenarios(iScen).Label);
        end
        hold(ax, 'off');
        title(ax, char(spec.Label), 'Interpreter', 'none');
        ylabel(ax, build_transform_ylabel(string(spec.Transform), years(1)), ...
            'Interpreter', 'none');
        xlabel(ax, 'Year');
        style_time_axis(ax, yearRange, colors);
        pad_y_axis(ax, string(spec.Transform));
        legend(ax, 'Location', 'best', 'Box', 'off', 'Interpreter', 'none');

        panelStem = "slides_" + sanitize_filename(spec.Variable) + ...
            "_comparison_" + sanitize_filename(spec.Transform);
        save_figure(fig, slideOutDir, panelStem, exportOptions.Pdf);
        close(fig);

        % Deviation plot for all scenarios
        fig = make_figure(sprintf('%s: Scenario deviation from Baseline', spec.Label), ...
            [100 100 860 560]);
        ax = axes('Parent', fig);
        hold(ax, 'on');
        for iScen = 1:numel(loadedScenarios)
            sData = loadedScenarios(iScen).Data;
            [dVals, ~] = compute_deviation(sData.(char(spec.Variable)), ...
                baseline.(char(spec.Variable)), string(spec.Deviation), ...
                'Baseline', loadedScenarios(iScen).Label, ...
                plotOptions.PctDeviationVisibilityThreshold);
            plot(ax, years, dVals, '-', 'Color', scenarioColors(iScen, :), ...
                'LineWidth', 1.9, 'DisplayName', loadedScenarios(iScen).Label);
        end
        yline(ax, 0, ':', 'Color', colors.zero, 'LineWidth', 1.0, ...
            'HandleVisibility', 'off');
        hold(ax, 'off');
        title(ax, char(spec.Label), 'Interpreter', 'none');
        ylabel(ax, build_deviation_ylabel(string(spec.Deviation)), 'Interpreter', 'none');
        xlabel(ax, 'Year');
        style_time_axis(ax, yearRange, colors);
        pad_y_axis(ax, string(spec.Deviation));
        legend(ax, 'Location', 'best', 'Box', 'off', 'Interpreter', 'none');

        deviationPanelStem = "slides_" + sanitize_filename(spec.Variable) + ...
            "_deviation_" + sanitize_filename(spec.Deviation);
        save_figure(fig, slideOutDir, deviationPanelStem, exportOptions.Pdf);
        close(fig);
    end

    fprintf('Saved slide-deck single plots to %s\n', slideOutDir);
else
    fprintf('Single slide plots disabled (exportOptions.SinglePlotsForSlides=false).\n');
end

%% Local functions --------------------------------------------------------

function csvPath = resolve_output_csv(outputDir, stem, mustExist)
    if nargin < 3
        mustExist = true;
    end

    csvPath = fullfile(outputDir, char(string(stem) + ".csv"));
    if isfile(csvPath)
        return;
    end

    if ~mustExist
        return;
    end

    outputDirExists = exist(outputDir, 'dir') == 7;
    if ~outputDirExists
        error('CompareBaselineScenarioVariables:missingOutputDir', ...
            ['Output folder not found: %s\n' ...
             'Expected simulation CSV files in ExcelFiles/Output/.\n' ...
             'Run setup_paths; then run RunSimulations to generate Baseline.csv and scenario CSVs.'], ...
            outputDir);
    end

    availableCsv = dir(fullfile(outputDir, '*.csv'));
    if isempty(availableCsv)
        error('CompareBaselineScenarioVariables:missingBaselineCsv', ...
            ['Baseline CSV not found: %s\n' ...
             'The output folder exists but contains no CSV files.\n' ...
             'Run setup_paths; then run RunSimulations to generate Baseline.csv.'], ...
            csvPath);
    else
        listed = strjoin({availableCsv.name}, ', ');
        error('CompareBaselineScenarioVariables:missingBaselineCsv', ...
            ['Baseline CSV not found: %s\n' ...
             'CSV files currently in ExcelFiles/Output/: %s\n' ...
             'Ensure a Baseline run is included in RunSimulations and rerun.'], ...
            csvPath, listed);
    end
end

function specs = normalize_plot_specs(specs)
    required = {'Variable', 'Label', 'Transform'};
    missing = required(~ismember(required, specs.Properties.VariableNames));
    if ~isempty(missing)
        error('CompareBaselineScenarioVariables:badPlotSpecs', ...
            'plotSpecs is missing required column(s): %s', strjoin(missing, ', '));
    end

    specs.Variable = string(specs.Variable);
    specs.Label = string(specs.Label);
    specs.Transform = lower(string(specs.Transform));
    if ~ismember('Deviation', specs.Properties.VariableNames)
        specs.Deviation = repmat("pct_deviation", height(specs), 1);
    else
        specs.Deviation = lower(string(specs.Deviation));
    end

    emptyLabels = strlength(strtrim(specs.Label)) == 0;
    specs.Label(emptyLabels) = specs.Variable(emptyLabels);

    supported = ["index", "level", "pct_deviation", "difference"];
    bad = ~ismember(specs.Transform, supported);
    if any(bad)
        error('CompareBaselineScenarioVariables:badTransform', ...
            'Unsupported transform(s): %s. Supported transforms: %s.', ...
            strjoin(unique(specs.Transform(bad)), ', '), ...
            strjoin(supported, ', '));
    end

    deviationSupported = ["pct_deviation", "difference"];
    badDeviation = ~ismember(specs.Deviation, deviationSupported);
    if any(badDeviation)
        error('CompareBaselineScenarioVariables:badDeviation', ...
            'Unsupported deviation mode(s): %s. Supported deviations: %s.', ...
            strjoin(unique(specs.Deviation(badDeviation)), ', '), ...
            strjoin(deviationSupported, ', '));
    end

    if numel(unique(specs.Variable)) ~= numel(specs.Variable)
        error('CompareBaselineScenarioVariables:duplicateVariables', ...
            'plotSpecs contains duplicate variables. Remove duplicates before plotting.');
    end
end

function require_vars(data, vars, dataName)
    vars = cellstr(string(vars));
    missing = vars(~ismember(vars, data.Properties.VariableNames));
    if ~isempty(missing)
        error('CompareBaselineScenarioVariables:missingVariables', ...
            'Missing required variable(s) in %s: %s', ...
            dataName, strjoin(missing, ', '));
    end
end

function [values, yLabel] = compute_deviation(scenarioValues, baselineValues, ...
    deviationMode, baselineLabel, scenarioLabel, pctVisibilityThreshold)
    switch deviationMode
        case "pct_deviation"
            values = safe_divide(scenarioValues, baselineValues) .* 100 - 100;
            values = hide_small_pct_deviations(values, pctVisibilityThreshold);
            yLabel = sprintf('%% deviation from %s', baselineLabel);

        case "difference"
            values = scenarioValues - baselineValues;
            yLabel = sprintf('%s - %s', scenarioLabel, baselineLabel);
    end
end

function values = compute_transform_series(seriesValues, baselineValues, transformMode, ~)
    switch transformMode
        case "index"
            values = index_to_first_value(seriesValues);

        case "level"
            values = seriesValues;

        case "pct_deviation"
            values = safe_divide(seriesValues, baselineValues) .* 100 - 100;
            %values = hide_small_pct_deviations(values, ...
             %   plotOptions.PctDeviationVisibilityThreshold);

        case "difference"
            values = seriesValues - baselineValues;

        otherwise
            error('CompareBaselineScenarioVariables:unsupportedTransformMode', ...
                'Unsupported transform mode: %s', transformMode);
    end
end

function yLabel = build_transform_ylabel(transformMode, baseYear)
    switch transformMode
        case "index"
            yLabel = sprintf('Index (%d = 100)', baseYear);
        case "level"
            yLabel = 'Level';
        case "pct_deviation"
            yLabel = '% deviation from Baseline';
        case "difference"
            yLabel = 'Scenario - Baseline';
        otherwise
            yLabel = 'Value';
    end
end

function yLabel = build_deviation_ylabel(deviationMode)
    switch deviationMode
        case "pct_deviation"
            yLabel = '% deviation from Baseline';
        case "difference"
            yLabel = 'Scenario - Baseline';
        otherwise
            yLabel = 'Deviation';
    end
end

function values = hide_small_pct_deviations(values, threshold)
    if threshold <= 0
        return;
    end
    values(abs(values) < threshold) = NaN;
end

function y = index_to_first_value(x)
    first = x(1);
    y = safe_divide(x, first) .* 100;
end

function y = safe_divide(num, den)
    y = num ./ den;
    y(den == 0 | isnan(num) | isnan(den)) = NaN;
end

function fig = make_figure(name, position)
    fig = figure('Name', name, 'NumberTitle', 'off', ...
        'Color', 'w', 'Position', position);
end

function save_figure(fig, outDir, stem, exportPdf)
    exportgraphics(fig, fullfile(outDir, char(stem + ".png")), ...
        'Resolution', 300);
    if exportPdf
        exportgraphics(fig, fullfile(outDir, char(stem + ".pdf")), ...
            'ContentType', 'vector');
    end
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

function pad_y_axis(ax, mode)
    yLimits = ylim(ax);
    if any(~isfinite(yLimits)) || diff(yLimits) <= 0
        return;
    end

    pad = diff(yLimits) * 0.06;
    if nargin >= 2 && string(mode) == "pct_deviation"
        yLow = min(yLimits(1) - pad, -1);
        yHigh = max(yLimits(2) + pad, 1);
    else
        if yLimits(1) == 0
            yLow = 0;
        else
            yLow = yLimits(1) - pad;
        end
        yHigh = yLimits(2) + pad;
    end
    ylim(ax, [yLow, yHigh]);
end

function out = sanitize_filename(value)
    out = lower(string(value));
    out = regexprep(out, '[^A-Za-z0-9]+', '_');
    out = regexprep(out, '^_+|_+$', '');
    if strlength(out) == 0
        out = "plot";
    end
end
