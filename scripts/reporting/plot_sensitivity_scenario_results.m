% plot_sensitivity_scenario_results
%
% Compare simulation outputs across sensitivity-parameter runs.
% Expects runs under ExcelFiles/Output/SensitivityRuns/<BatchName>/<CaseFolder>/
% with scenario CSV files such as Baseline.csv, NZ.csv, etc.
%
% Usage:
%   run('scripts/reporting/plot_sensitivity_scenario_results.m')

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);

%% Configuration

cfg = struct();

% Leave empty to auto-select latest sensitivity batch.
cfg.batchName = '';

% Scenarios to plot. Must match CSV filenames in case folders.
cfg.scenarios = {'Baseline', 'NZ'};

% Optional scenario-pair comparison inside each sensitivity case.
% The script adds a second figure set with both scenario series overlaid
% for every case and variable.
cfg.comparisonPair = {'Baseline', 'NZ'};
cfg.comparisonLineStyles = {'-', '--'};

% Variables to plot.
cfg.variables = {
    'Y_1', ...          % Aggregate GDP (region 1)
    'E_1', ...          % Emissions (region 1)
    'Q_2_1', ...        % Fossil output
    'Q_3_1', ...        % Renewable output
    'PE_1'              % Carbon/permit price (region 1)
    };

% Transform:
%   'level'      -> raw level
%   'index100'   -> indexed to first available year (100 at t0)
cfg.transform = 'index100';

% Reporting horizon (inclusive) used for both plots and summary outputs.
cfg.yearRange = [2025, 2050];

cfg.lineWidth = 1.8;
cfg.figureVisible = 'off';
cfg.outputSubdir = 'Plots';
cfg.caseCsvSubdirs = {'', 'ExcelOutput'};

% Top-impact sensitivity chart configuration.
% Computes percent deviation at terminal year:
%   100 * (scenarioB / scenarioA - 1)
% where scenarioA/scenarioB come from comparisonPair.
cfg.topImpact = struct();
cfg.topImpact.enabled = true;
cfg.topImpact.variable = 'Y_1';
cfg.topImpact.topN = 10;

%% Resolve batch directory and case folders

sensitivityRoot = fullfile(repoRoot, 'ExcelFiles', 'Output', 'SensitivityRuns');
if ~exist(sensitivityRoot, 'dir')
    error('plot_sensitivity_scenario_results:NoSensitivityRoot', ...
        'Sensitivity root not found: %s', sensitivityRoot);
end

batchDir = resolve_batch_dir(sensitivityRoot, cfg.batchName, cfg.scenarios, cfg.outputSubdir, cfg.caseCsvSubdirs);
plotDir = fullfile(batchDir, cfg.outputSubdir);
ensure_dir(plotDir);

caseFolders = list_case_folders(batchDir, cfg.outputSubdir, cfg.caseCsvSubdirs, cfg.scenarios);
if isempty(caseFolders)
    error('plot_sensitivity_scenario_results:NoCaseFolders', ...
        ['No case folders with scenario CSV files were found in batch: %s\n' ...
         'Expected scenario files like Baseline.csv either directly under each case folder\n' ...
         'or under case/ExcelOutput/.'], batchDir);
end

fprintf('Using sensitivity batch: %s\n', batchDir);
fprintf('Cases found: %d\n', numel(caseFolders));

summaryRows = table();

%% Plot loops: scenario x variable

for iScen = 1:numel(cfg.scenarios)
    scenarioName = cfg.scenarios{iScen};

    seriesByCase = load_scenario_tables(batchDir, caseFolders, scenarioName, cfg.caseCsvSubdirs, cfg.yearRange);
    if isempty(seriesByCase)
        warning('plot_sensitivity_scenario_results:ScenarioMissing', ...
            'Scenario %s not found in any case folder. Skipping.', scenarioName);
        continue
    end

    for iVar = 1:numel(cfg.variables)
        varName = cfg.variables{iVar};

        fig = figure('Visible', cfg.figureVisible, 'Color', 'w');
        ax = axes(fig);
        hold(ax, 'on');
        grid(ax, 'on');

        plottedLabels = {};
        colorIdx = 0;

        for iCase = 1:numel(seriesByCase)
            entry = seriesByCase(iCase);
            if ~ismember(varName, entry.data.Properties.VariableNames)
                continue
            end

            years = entry.data.Year;
            values = entry.data.(varName);
            if ~isnumeric(years) || ~isnumeric(values)
                continue
            end

            [xVals, yVals] = transform_series(years, values, cfg.transform);
            valid = isfinite(xVals) & isfinite(yVals);
            if ~any(valid)
                continue
            end

            colorIdx = colorIdx + 1;
            plot(ax, xVals(valid), yVals(valid), '-', ...
                'LineWidth', cfg.lineWidth, ...
                'Color', pick_color(colorIdx));

            plottedLabels{end + 1} = entry.caseLabel; %#ok<AGROW>

            terminalIdx = find(valid, 1, 'last');
            if ~isempty(terminalIdx)
                r = table( ...
                    string(entry.caseLabel), string(scenarioName), string(varName), ...
                    xVals(terminalIdx), yVals(terminalIdx), ...
                    'VariableNames', {'Case', 'Scenario', 'Variable', 'TerminalYear', 'TerminalValue'});
                summaryRows = [summaryRows; r]; %#ok<AGROW>
            end
        end

        if isempty(plottedLabels)
            close(fig);
            continue
        end

        title(ax, sprintf('%s | %s (%s)', scenarioName, varName, cfg.transform), ...
            'Interpreter', 'none');
        xlabel(ax, 'Year');
        ylabel(ax, y_axis_label(varName, cfg.transform));
        legend(ax, plottedLabels, 'Interpreter', 'none', 'Location', 'best');

        fileName = sprintf('%s__%s__%s.png', sanitize_name(scenarioName), sanitize_name(varName), sanitize_name(cfg.transform));
        exportgraphics(fig, fullfile(plotDir, fileName), 'Resolution', 220);
        close(fig);
    end
end

%% Plot loops: variable x (Baseline vs NZ inside each case)

if numel(cfg.comparisonPair) == 2
    scenarioA = cfg.comparisonPair{1};
    scenarioB = cfg.comparisonPair{2};

    for iVar = 1:numel(cfg.variables)
        varName = cfg.variables{iVar};

        fig = figure('Visible', cfg.figureVisible, 'Color', 'w');
        ax = axes(fig);
        hold(ax, 'on');
        grid(ax, 'on');

        plottedLabels = {};
        colorIdx = 0;

        for iCase = 1:numel(caseFolders)
            caseName = caseFolders{iCase};
            caseDir = fullfile(batchDir, caseName);

            csvA = resolve_scenario_csv_path(caseDir, scenarioA, cfg.caseCsvSubdirs);
            csvB = resolve_scenario_csv_path(caseDir, scenarioB, cfg.caseCsvSubdirs);
            if isempty(csvA) || isempty(csvB)
                continue
            end

            tabA = read_table_preserve_names(csvA);
            tabB = read_table_preserve_names(csvB);
            if ~ismember('Year', tabA.Properties.VariableNames) || ~ismember('Year', tabB.Properties.VariableNames)
                continue
            end
            tabA = restrict_to_year_range(tabA, cfg.yearRange);
            tabB = restrict_to_year_range(tabB, cfg.yearRange);
            if isempty(tabA) || isempty(tabB)
                continue
            end
            if ~ismember(varName, tabA.Properties.VariableNames) || ~ismember(varName, tabB.Properties.VariableNames)
                continue
            end

            [xA, yA] = transform_series(tabA.Year, tabA.(varName), cfg.transform);
            [xB, yB] = transform_series(tabB.Year, tabB.(varName), cfg.transform);
            [xCommon, yACommon, yBCommon] = align_series_by_year(xA, yA, xB, yB);

            validA = isfinite(xCommon) & isfinite(yACommon);
            validB = isfinite(xCommon) & isfinite(yBCommon);
            if ~any(validA) || ~any(validB)
                continue
            end

            colorIdx = colorIdx + 1;
            caseColor = pick_color(colorIdx);

            plot(ax, xCommon(validA), yACommon(validA), cfg.comparisonLineStyles{1}, ...
                'LineWidth', cfg.lineWidth, ...
                'Color', caseColor);
            plot(ax, xCommon(validB), yBCommon(validB), cfg.comparisonLineStyles{2}, ...
                'LineWidth', cfg.lineWidth, ...
                'Color', caseColor);

            plottedLabels{end + 1} = sprintf('%s | %s', caseName, scenarioA); %#ok<AGROW>
            plottedLabels{end + 1} = sprintf('%s | %s', caseName, scenarioB); %#ok<AGROW>

            validBoth = isfinite(xCommon) & isfinite(yACommon) & isfinite(yBCommon);
            terminalIdx = find(validBoth, 1, 'last');
            if ~isempty(terminalIdx)
                r = table( ...
                    string(caseName), string([scenarioB '_minus_' scenarioA]), string(varName), ...
                    xCommon(terminalIdx), yBCommon(terminalIdx) - yACommon(terminalIdx), ...
                    'VariableNames', {'Case', 'Scenario', 'Variable', 'TerminalYear', 'TerminalValue'});
                summaryRows = [summaryRows; r]; %#ok<AGROW>
            end
        end

        if isempty(plottedLabels)
            close(fig);
            continue
        end

        title(ax, sprintf('%s vs %s | %s (%s)', scenarioA, scenarioB, varName, cfg.transform), ...
            'Interpreter', 'none');
        xlabel(ax, 'Year');
        ylabel(ax, y_axis_label(varName, cfg.transform));
        legend(ax, plottedLabels, 'Interpreter', 'none', 'Location', 'best');

        fileName = sprintf('Comparison__%s_vs_%s__%s__%s.png', ...
            sanitize_name(scenarioA), sanitize_name(scenarioB), sanitize_name(varName), sanitize_name(cfg.transform));
        exportgraphics(fig, fullfile(plotDir, fileName), 'Resolution', 220);
        close(fig);
    end
end

if ~isempty(summaryRows)
    summaryPath = fullfile(plotDir, 'Sensitivity_TerminalValues.csv');
    writetable(summaryRows, summaryPath);
    fprintf('Terminal summary written: %s\n', summaryPath);
end

if cfg.topImpact.enabled && numel(cfg.comparisonPair) == 2
    topImpactTable = build_top_impact_table(batchDir, caseFolders, cfg.comparisonPair, ...
        cfg.topImpact.variable, cfg.caseCsvSubdirs);
    if ~isempty(topImpactTable)
        topImpactTable = sortrows(topImpactTable, 'AbsPercentDeviation', 'descend');
        topN = min(cfg.topImpact.topN, height(topImpactTable));
        topImpactTopN = topImpactTable(1:topN, :);

        fig = figure('Visible', cfg.figureVisible, 'Color', 'w');
        ax = axes(fig);
        grid(ax, 'on');
        hold(ax, 'on');
        b = bar(ax, topImpactTopN.PercentDeviation, 'FaceColor', [0.00 0.45 0.74]); %#ok<NASGU>
        yline(ax, 0, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0, 'HandleVisibility', 'off');
        hold(ax, 'off');

        xTickLabels = cell(height(topImpactTopN), 1);
        for i = 1:height(topImpactTopN)
            xTickLabels{i} = char(topImpactTopN.DisplayLabel(i));
        end
        ax.XTick = 1:height(topImpactTopN);
        ax.XTickLabel = xTickLabels;
        ax.XTickLabelRotation = 45;

        title(ax, sprintf('Top %d parameter impacts: %s vs %s (%s, terminal-year %% deviation)', ...
            topN, cfg.comparisonPair{2}, cfg.comparisonPair{1}, cfg.topImpact.variable), 'Interpreter', 'none');
        xlabel(ax, 'Parameter = value (from AppliedOverrides.csv)', 'Interpreter', 'none');
        ylabel(ax, sprintf('%% deviation: %s vs %s', cfg.comparisonPair{2}, cfg.comparisonPair{1}), 'Interpreter', 'none');

        impactFigName = sprintf('ImpactTop%d__%s_vs_%s__%s.png', ...
            topN, sanitize_name(cfg.comparisonPair{2}), sanitize_name(cfg.comparisonPair{1}), sanitize_name(cfg.topImpact.variable));
        exportgraphics(fig, fullfile(plotDir, impactFigName), 'Resolution', 220);
        close(fig);

        writetable(topImpactTable, fullfile(plotDir, 'Sensitivity_ImpactRanking_All.csv'));
        writetable(topImpactTopN, fullfile(plotDir, 'Sensitivity_ImpactRanking_TopN.csv'));
        fprintf('Top-impact ranking written: %s\n', fullfile(plotDir, 'Sensitivity_ImpactRanking_TopN.csv'));
    else
        warning('plot_sensitivity_scenario_results:NoImpactRankingData', ...
            'Could not build top-impact ranking table for %s vs %s (%s).', ...
            cfg.comparisonPair{2}, cfg.comparisonPair{1}, cfg.topImpact.variable);
    end
end

fprintf('Plots written to: %s\n', plotDir);

%% Local functions

function batchDir = resolve_batch_dir(sensitivityRoot, batchName, scenarios, outputSubdir, caseCsvSubdirs)
    if ~isempty(strtrim(batchName))
        batchDir = fullfile(sensitivityRoot, batchName);
        if ~exist(batchDir, 'dir')
            error('plot_sensitivity_scenario_results:BatchNotFound', ...
                'Specified batch not found: %s', batchDir);
        end
        if ~batch_has_scenario_csvs(batchDir, scenarios, outputSubdir, caseCsvSubdirs)
            warning('plot_sensitivity_scenario_results:SelectedBatchHasNoScenarioCSVs', ...
                'Selected batch %s does not seem to contain scenario CSVs for configured scenarios.', batchDir);
        end
        return
    end

    listing = dir(sensitivityRoot);
    candidates = listing([listing.isdir]);
    names = {candidates.name};
    names = names(~ismember(names, {'.', '..'}));
    names = names(startsWith(names, 'Batch_') | startsWith(names, 'Sensitivity_'));

    if isempty(names)
        error('plot_sensitivity_scenario_results:NoBatchFound', ...
            'No Batch_* or Sensitivity_* folder found under %s', sensitivityRoot);
    end

    % Prefer most-recent folders that actually contain scenario CSV files.
    timestamps = nan(size(names));
    for i = 1:numel(names)
        d = dir(fullfile(sensitivityRoot, names{i}));
        if ~isempty(d)
            timestamps(i) = d.datenum;
        end
    end
    [~, order] = sort(timestamps, 'descend');

    for i = 1:numel(order)
        candDir = fullfile(sensitivityRoot, names{order(i)});
        if batch_has_scenario_csvs(candDir, scenarios, outputSubdir, caseCsvSubdirs)
            batchDir = candDir;
            return
        end
    end

    error('plot_sensitivity_scenario_results:NoBatchWithScenarioCSVs', ...
        ['No sensitivity batch with scenario CSV files was found under %s.\n' ...
         'Check whether sensitivity runs created per-case CSV outputs.'], sensitivityRoot);
end

function caseFolders = list_case_folders(batchDir, outputSubdir, caseCsvSubdirs, scenarios)
    listing = dir(batchDir);
    isDir = [listing.isdir];
    names = {listing(isDir).name};
    names = names(~ismember(names, {'.', '..'}));
    names = names(~strcmp(names, outputSubdir));

    hasScenarioData = false(size(names));
    for i = 1:numel(names)
        hasScenarioData(i) = case_has_any_scenario(fullfile(batchDir, names{i}), scenarios, caseCsvSubdirs);
    end
    names = names(hasScenarioData);

    if isempty(names)
        caseFolders = {};
        return
    end

    % Keep numbered case folders first if present.
    isNumbered = false(size(names));
    for i = 1:numel(names)
        isNumbered(i) = ~isempty(regexp(names{i}, '^\d+_', 'once'));
    end
    caseFolders = [names(isNumbered), names(~isNumbered)];
end

function entries = load_scenario_tables(batchDir, caseFolders, scenarioName, caseCsvSubdirs, yearRange)
    entries = struct('caseLabel', {}, 'data', {});
    for i = 1:numel(caseFolders)
        caseName = caseFolders{i};
        csvPath = resolve_scenario_csv_path(fullfile(batchDir, caseName), scenarioName, caseCsvSubdirs);
        if isempty(csvPath)
            continue
        end
        tab = read_table_preserve_names(csvPath);
        if ~ismember('Year', tab.Properties.VariableNames)
            continue
        end
        tab = restrict_to_year_range(tab, yearRange);
        if isempty(tab)
            continue
        end
        entries(end + 1).caseLabel = caseName; %#ok<AGROW>
        entries(end).data = tab;
    end
end

function tab = restrict_to_year_range(tab, yearRange)
    if nargin < 2 || isempty(yearRange)
        return
    end
    if ~ismember('Year', tab.Properties.VariableNames)
        tab = tab([],:);
        return
    end

    y0 = yearRange(1);
    y1 = yearRange(2);
    years = tab.Year;
    keep = isfinite(years) & years >= y0 & years <= y1;
    tab = tab(keep, :);
end

function [xVals, yVals] = transform_series(years, values, transformName)
    xVals = years(:);
    yVals = values(:);

    switch lower(transformName)
        case 'level'
            % no change
        case 'index100'
            i0 = find(isfinite(yVals), 1, 'first');
            if isempty(i0) || yVals(i0) == 0
                yVals(:) = NaN;
            else
                yVals = 100 .* (yVals ./ yVals(i0));
            end
        otherwise
            error('plot_sensitivity_scenario_results:UnknownTransform', ...
                'Unknown transform: %s', transformName);
    end
end

function ylab = y_axis_label(varName, transformName)
    switch lower(transformName)
        case 'level'
            ylab = varName;
        case 'index100'
            ylab = [varName ' (index, t0=100)'];
        otherwise
            ylab = varName;
    end
end

function [xCommon, yACommon, yBCommon] = align_series_by_year(xA, yA, xB, yB)
    xA = xA(:);
    yA = yA(:);
    xB = xB(:);
    yB = yB(:);

    [xCommon, ia, ib] = intersect(xA, xB);
    xCommon = xCommon(:);
    yACommon = yA(ia);
    yBCommon = yB(ib);
end

function c = pick_color(i)
    palette = [ ...
        0.00, 0.45, 0.74;
        0.85, 0.33, 0.10;
        0.93, 0.69, 0.13;
        0.49, 0.18, 0.56;
        0.47, 0.67, 0.19;
        0.30, 0.75, 0.93;
        0.64, 0.08, 0.18;
        0.20, 0.20, 0.20
    ];
    c = palette(mod(i - 1, size(palette, 1)) + 1, :);
end

function tab = read_table_preserve_names(filePath)
    try
        tab = readtable(filePath, 'PreserveVariableNames', true);
    catch
        try
            tab = readtable(filePath, 'VariableNamingRule', 'preserve');
        catch
            tab = readtable(filePath);
        end
    end
end

function ensure_dir(pathStr)
    if ~exist(pathStr, 'dir')
        mkdir(pathStr);
    end
end

function out = sanitize_name(textIn)
    out = regexprep(char(string(textIn)), '[^A-Za-z0-9_-]', '_');
    out = regexprep(out, '_+', '_');
end

function tf = batch_has_scenario_csvs(batchDir, scenarios, outputSubdir, caseCsvSubdirs)
    caseFolders = list_case_folders(batchDir, outputSubdir, caseCsvSubdirs, scenarios);
    tf = ~isempty(caseFolders);
end

function tf = case_has_any_scenario(caseDir, scenarios, caseCsvSubdirs)
    tf = false;
    for i = 1:numel(scenarios)
        if ~isempty(resolve_scenario_csv_path(caseDir, scenarios{i}, caseCsvSubdirs))
            tf = true;
            return
        end
    end
end

function csvPath = resolve_scenario_csv_path(caseDir, scenarioName, caseCsvSubdirs)
    csvPath = '';
    for i = 1:numel(caseCsvSubdirs)
        subdir = caseCsvSubdirs{i};
        if isempty(subdir)
            cand = fullfile(caseDir, [scenarioName '.csv']);
        else
            cand = fullfile(caseDir, subdir, [scenarioName '.csv']);
        end
        if isfile(cand)
            csvPath = cand;
            return
        end
    end
end

function impactTable = build_top_impact_table(batchDir, caseFolders, comparisonPair, varName, caseCsvSubdirs)
    scenarioA = comparisonPair{1};
    scenarioB = comparisonPair{2};

    rows = table();
    for i = 1:numel(caseFolders)
        caseName = caseFolders{i};
        caseDir = fullfile(batchDir, caseName);

        csvA = resolve_scenario_csv_path(caseDir, scenarioA, caseCsvSubdirs);
        csvB = resolve_scenario_csv_path(caseDir, scenarioB, caseCsvSubdirs);
        if isempty(csvA) || isempty(csvB)
            continue
        end

        tabA = read_table_preserve_names(csvA);
        tabB = read_table_preserve_names(csvB);
        if ~ismember(varName, tabA.Properties.VariableNames) || ~ismember(varName, tabB.Properties.VariableNames)
            continue
        end

        seriesA = tabA.(varName);
        seriesB = tabB.(varName);
        if ~isnumeric(seriesA) || ~isnumeric(seriesB)
            continue
        end

        iA = find(isfinite(seriesA), 1, 'last');
        iB = find(isfinite(seriesB), 1, 'last');
        if isempty(iA) || isempty(iB)
            continue
        end

        vA = seriesA(iA);
        vB = seriesB(iB);
        if ~isfinite(vA) || ~isfinite(vB) || vA == 0
            continue
        end

        pctDev = 100 * (vB / vA - 1);

        [paramName, paramValue, displayLabel] = read_case_override(caseDir, caseName);
        r = table(string(caseName), string(paramName), string(paramValue), string(displayLabel), ...
            pctDev, abs(pctDev), ...
            'VariableNames', {'Case', 'Parameter', 'ParameterValue', 'DisplayLabel', 'PercentDeviation', 'AbsPercentDeviation'});
        rows = [rows; r]; %#ok<AGROW>
    end

    impactTable = rows;
end

function [paramName, paramValue, displayLabel] = read_case_override(caseDir, fallbackCaseName)
    paramName = fallbackCaseName;
    paramValue = '';
    displayLabel = fallbackCaseName;

    appliedPath = fullfile(caseDir, 'AppliedOverrides.csv');
    if ~isfile(appliedPath)
        return
    end

    t = read_table_preserve_names(appliedPath);
    if isempty(t) || ~all(ismember({'Parameter', 'NewValue'}, t.Properties.VariableNames))
        return
    end

    if height(t) == 0
        return
    end

    pName = string(t.Parameter(1));
    pVal = string(format_override_value(t.NewValue(1)));

    if height(t) > 1
        pName = strjoin(string(t.Parameter), ';');
        pVals = strings(height(t), 1);
        for i = 1:height(t)
            pVals(i) = string(format_override_value(t.NewValue(i)));
        end
        pVal = strjoin(pVals, ';');
    end

    paramName = char(pName);
    paramValue = char(pVal);
    displayLabel = sprintf('%s=%s', paramName, paramValue);
end

function out = format_override_value(v)
    if isnumeric(v)
        if isscalar(v) && isfinite(v)
            out = sprintf('%.4g', v);
        else
            out = 'NaN';
        end
    else
        out = char(string(v));
    end
end