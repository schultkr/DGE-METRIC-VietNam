function run_online_training_comparison(config)
%RUN_ONLINE_TRAINING_COMPARISON One figure per variable, relative to baseline.
%   For each variable in config.plotSpecs, this script creates a single plot
%   where all scenarios are shown together as deviations from baseline.

    arguments
        config struct
    end

    repoRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
    oldPwd = pwd;
    cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
    cd(repoRoot);
    setup_paths();

    cfg = apply_defaults(config);

    outputDir = fullfile(repoRoot, 'ExcelFiles', 'Output');
    baselineCsv = resolve_output_csv(outputDir, cfg.baselineName, true);
    baseline = readtable(baselineCsv);

    plotSpecs = normalize_plot_specs(cfg.plotSpecs);
    require_vars(baseline, ["Year"; plotSpecs.Variable], char(cfg.baselineName) + " data");

    loadedScenarios = struct('Name', {}, 'Label', {}, 'Data', {});
    for iScen = 1:height(cfg.scenarioSpecs)
        sName = string(cfg.scenarioSpecs.Name(iScen));
        sLabel = string(cfg.scenarioSpecs.Label(iScen));
        sCsv = resolve_output_csv(outputDir, sName, false);

        if ~isfile(sCsv)
            warning('OnlineTraining:MissingScenarioFile', ...
                'Scenario file not found for "%s": %s. Skipping.', sName, sCsv);
            continue
        end

        sData = readtable(sCsv);
        require_vars(sData, ["Year"; plotSpecs.Variable], char(sName) + " data");

        loadedScenarios(end + 1).Name = char(sName); %#ok<AGROW>
        loadedScenarios(end).Label = char(sLabel);
        loadedScenarios(end).Data = sData;
    end

    if isempty(loadedScenarios)
        error('OnlineTraining:NoScenarioData', ...
            'No scenario CSV files were loaded. Check scenario IDs in scenarioSpecs.');
    end

    commonYears = baseline.Year(:);
    for iScen = 1:numel(loadedScenarios)
        commonYears = intersect(commonYears, loadedScenarios(iScen).Data.Year(:));
    end
    commonYears = commonYears(commonYears >= cfg.plotStartYear & commonYears <= cfg.plotEndYear);
    commonYears = sort(commonYears(:));

    if isempty(commonYears)
        error('OnlineTraining:NoCommonYears', ...
            'No common years between %d and %d across baseline and scenarios.', ...
            cfg.plotStartYear, cfg.plotEndYear);
    end

    baseline = sortrows(baseline(ismember(baseline.Year, commonYears), :), 'Year');
    for iScen = 1:numel(loadedScenarios)
        s = loadedScenarios(iScen).Data;
        loadedScenarios(iScen).Data = sortrows(s(ismember(s.Year, commonYears), :), 'Year');
    end

    years = baseline.Year(:);
    yearRange = [years(1), years(end)];

    outDir = fullfile(repoRoot, 'Figures', cfg.plotSubfolder, 'RelativeToBaseline');
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    colors = default_colors();
    set_global_plot_defaults();

    summaryRows = [];
    for iPlot = 1:height(plotSpecs)
        spec = plotSpecs(iPlot, :);
        variableName = char(spec.Variable);

        fig = make_figure(sprintf('%s relative to baseline', spec.Label), [100 100 900 560]);
        ax = axes(fig);
        hold(ax, 'on');

        for iScen = 1:numel(loadedScenarios)
            sData = loadedScenarios(iScen).Data;
            dVals = compute_deviation(sData.(variableName), baseline.(variableName), string(spec.Deviation));
            c = scenario_color(iScen, colors);
            plot(ax, years, dVals, '-', 'Color', c, 'LineWidth', 1.9, ...
                'DisplayName', loadedScenarios(iScen).Label);

            summaryRows = [summaryRows; struct( ... %#ok<AGROW>
                'Variable', string(spec.Variable), ...
                'Scenario', string(loadedScenarios(iScen).Name), ...
                'FinalYear', years(end), ...
                'DeviationMode', string(spec.Deviation), ...
                'FinalYearDeviation', dVals(end))];
        end

        yline(ax, 0, ':', 'Color', colors.plan, 'LineWidth', 1.0, ...
            'HandleVisibility', 'off');
        hold(ax, 'off');

        title(ax, sprintf('%s: %s relative to %s', ...
            cfg.chartTitlePrefix, spec.Label, cfg.baselineLabel), 'Interpreter', 'none');
        ylabel(ax, build_deviation_ylabel(string(spec.Deviation), cfg.baselineLabel));
        xlabel(ax, 'Year');
        style_time_axis(ax, yearRange, colors);
        pad_y_axis(ax, string(spec.Deviation));
        legend(ax, 'Location', 'best', 'Box', 'off', 'Interpreter', 'none');

        stem = "relative_" + sanitize_filename(spec.Variable) + "_" + sanitize_filename(spec.Deviation);
        save_figure(fig, outDir, stem, cfg.exportPdf);
        close(fig);
    end

    if ~isempty(summaryRows)
        writetable(struct2table(summaryRows), fullfile(outDir, 'comparison_summary_final_year.csv'));
    end

    fprintf('\nOnline Training comparison complete: %s\n', cfg.chartTitlePrefix);
    fprintf('Baseline: %s\n', cfg.baselineName);
    fprintf('Scenarios loaded: %d/%d\n', numel(loadedScenarios), height(cfg.scenarioSpecs));
    fprintf('Years compared: %d-%d\n', years(1), years(end));
    fprintf('Output folder: %s\n\n', outDir);
end

function cfg = apply_defaults(config)
    cfg = config;

    required = {'baselineName', 'scenarioSpecs', 'plotSubfolder', 'chartTitlePrefix'};
    missing = required(~isfield(cfg, required));
    if ~isempty(missing)
        error('OnlineTraining:MissingConfigField', ...
            'Missing required config field(s): %s', strjoin(missing, ', '));
    end

    if ~isfield(cfg, 'baselineLabel') || strlength(string(cfg.baselineLabel)) == 0
        cfg.baselineLabel = string(cfg.baselineName);
    else
        cfg.baselineLabel = string(cfg.baselineLabel);
    end

    if ~isfield(cfg, 'plotStartYear')
        cfg.plotStartYear = 2025;
    end
    if ~isfield(cfg, 'plotEndYear')
        cfg.plotEndYear = 2050;
    end
    if ~isfield(cfg, 'exportPdf')
        cfg.exportPdf = true;
    end

    if ~isfield(cfg, 'plotSpecs')
        cfg.plotSpecs = table( ...
            ["Y_1"; "I_1"; "Q_3_1"; "E_1"; "PE_1"], ...
            ["GDP"; "Investment"; "Renewable generation"; "Emissions"; "Emission price"], ...
            ["pct_deviation"; "pct_deviation"; "pct_deviation"; "pct_deviation"; "difference"], ...
            'VariableNames', {'Variable', 'Label', 'Deviation'});
    end

    cfg.baselineName = string(cfg.baselineName);
    cfg.baselineLabel = string(cfg.baselineLabel);
    cfg.plotSubfolder = char(string(cfg.plotSubfolder));
    cfg.chartTitlePrefix = string(cfg.chartTitlePrefix);
end

function csvPath = resolve_output_csv(outputDir, stem, mustExist)
    if nargin < 3
        mustExist = true;
    end

    csvPath = fullfile(outputDir, char(string(stem) + ".csv"));
    if isfile(csvPath) || ~mustExist
        return;
    end

    if exist(outputDir, 'dir') ~= 7
        error('OnlineTraining:MissingOutputDir', ...
            ['Output folder not found: %s\n' ...
             'Run setup_paths; then run RunSimulations to generate output CSV files.'], ...
            outputDir);
    end

    availableCsv = dir(fullfile(outputDir, '*.csv'));
    if isempty(availableCsv)
        error('OnlineTraining:MissingCsv', ...
            ['Expected CSV not found: %s\n' ...
             'The output folder exists but contains no CSV files.'], ...
            csvPath);
    end

    listed = strjoin({availableCsv.name}, ', ');
    error('OnlineTraining:MissingCsv', ...
        ['Expected CSV not found: %s\n' ...
         'CSV files currently available: %s'], ...
        csvPath, listed);
end

function specs = normalize_plot_specs(specs)
    required = {'Variable', 'Label', 'Deviation'};
    missing = required(~ismember(required, specs.Properties.VariableNames));
    if ~isempty(missing)
        error('OnlineTraining:BadPlotSpecs', ...
            'plotSpecs is missing required column(s): %s', strjoin(missing, ', '));
    end

    specs.Variable = string(specs.Variable);
    specs.Label = string(specs.Label);
    specs.Deviation = lower(string(specs.Deviation));

    emptyLabels = strlength(strtrim(specs.Label)) == 0;
    specs.Label(emptyLabels) = specs.Variable(emptyLabels);

    supportedDeviation = ["pct_deviation", "difference"];
    badDeviation = ~ismember(specs.Deviation, supportedDeviation);
    if any(badDeviation)
        error('OnlineTraining:BadDeviation', ...
            'Unsupported deviation mode(s): %s', strjoin(unique(specs.Deviation(badDeviation)), ', '));
    end

    if numel(unique(specs.Variable)) ~= numel(specs.Variable)
        error('OnlineTraining:DuplicateVariables', ...
            'plotSpecs contains duplicate variables. Remove duplicates before plotting.');
    end
end

function require_vars(data, vars, dataName)
    vars = cellstr(string(vars));
    missing = vars(~ismember(vars, data.Properties.VariableNames));
    if ~isempty(missing)
        error('OnlineTraining:MissingVariables', ...
            'Missing required variable(s) in %s: %s', ...
            dataName, strjoin(missing, ', '));
    end
end

function colors = default_colors()
    colors = struct();
    colors.plan = [0.25 0.25 0.25];
    colors.grid = [0.82 0.82 0.82];
    colors.pool = [ ...
        0.00 0.45 0.70; ...
        0.84 0.37 0.00; ...
        0.00 0.62 0.45; ...
        0.49 0.18 0.56; ...
        0.18 0.55 0.34; ...
        0.64 0.08 0.18; ...
        0.30 0.30 0.30];
end

function set_global_plot_defaults()
    set(groot, 'defaultAxesFontSize', 12, ...
               'defaultTextFontSize', 12, ...
               'defaultLegendFontSize', 10, ...
               'defaultAxesFontName', 'Arial', ...
               'defaultTextFontName', 'Arial');
end

function values = compute_deviation(scenarioValues, baselineValues, deviationMode)
    switch deviationMode
        case "pct_deviation"
            values = safe_divide(scenarioValues, baselineValues) .* 100 - 100;
        case "difference"
            values = scenarioValues - baselineValues;
        otherwise
            error('OnlineTraining:UnsupportedDeviationMode', ...
                'Unsupported deviation mode: %s', deviationMode);
    end
end

function yLabel = build_deviation_ylabel(deviationMode, baselineLabel)
    switch deviationMode
        case "pct_deviation"
            yLabel = sprintf('%% deviation from %s', baselineLabel);
        case "difference"
            yLabel = sprintf('Scenario - %s', baselineLabel);
        otherwise
            yLabel = 'Deviation';
    end
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
    exportgraphics(fig, fullfile(outDir, char(stem + ".png")), 'Resolution', 300);
    if exportPdf
        exportgraphics(fig, fullfile(outDir, char(stem + ".pdf")), 'ContentType', 'vector');
    end
end

function c = scenario_color(idx, colors)
    pool = colors.pool;
    i = mod(idx - 1, size(pool, 1)) + 1;
    c = pool(i, :);
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
        ylim(ax, [yLow, yHigh]);
        return;
    end

    if yLimits(1) == 0
        yLow = 0;
    else
        yLow = yLimits(1) - pad;
    end
    ylim(ax, [yLow, yLimits(2) + pad]);
end

function out = sanitize_filename(value)
    out = lower(string(value));
    out = regexprep(out, '[^A-Za-z0-9]+', '_');
    out = regexprep(out, '^_+|_+$', '');
    if strlength(out) == 0
        out = "plot";
    end
end
