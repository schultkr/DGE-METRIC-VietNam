% summarize_sensitivity_runs
%
% Build a short, self-contained LaTeX report summarizing one sensitivity
% batch under ExcelFiles/Output/SensitivityRuns/<BatchName>/. Pulls run
% status from SensitivitySummary.csv, terminal-year comparisons from
% Plots/Sensitivity_TerminalValues.csv, and embeds Comparison__*.png
% figures, all of which are written by plot_sensitivity_scenario_results.m.
% Falls back gracefully (run-status table only) if a batch has no plots.
%
% Usage:
%   run('scripts/reporting/summarize_sensitivity_runs.m')
%
% Then compile the .tex file written into the batch folder, e.g.:
%   pdflatex SensitivityReport.tex   (run from that folder)

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);

%% Configuration

cfg = struct();
cfg.batchName = '';                    % '' = auto-pick most recent batch with content
cfg.outputTexName = 'SensitivityReport.tex';
cfg.maxFigures = 8;                    % cap keeps the report short
cfg.maxImpactRows = 10;

sensitivityRoot = fullfile(repoRoot, 'ExcelFiles', 'Output', 'SensitivityRuns');
if ~exist(sensitivityRoot, 'dir')
    error('summarize_sensitivity_runs:NoSensitivityRoot', ...
        'Sensitivity root not found: %s', sensitivityRoot);
end

batchDir = resolve_batch_dir(sensitivityRoot, cfg.batchName);
[~, batchName] = fileparts(batchDir);
plotDir = fullfile(batchDir, 'Plots');

fprintf('Summarizing sensitivity batch: %s\n', batchDir);

%% Gather inputs

runTable = read_table_if_exists(fullfile(batchDir, 'SensitivitySummary.csv'));

caseFolders = list_case_folders(batchDir);
overridesByCase = containers.Map('KeyType', 'char', 'ValueType', 'char');
for i = 1:numel(caseFolders)
    overridesByCase(caseFolders{i}) = describe_case_overrides(fullfile(batchDir, caseFolders{i}));
end

terminalTable = read_table_if_exists(fullfile(plotDir, 'Sensitivity_TerminalValues.csv'));
impactTable = read_table_if_exists(fullfile(plotDir, 'Sensitivity_ImpactRanking_TopN.csv'));

figFiles = {};
if exist(plotDir, 'dir')
    names = {};

    dImpact = dir(fullfile(plotDir, 'ImpactTop*.png'));
    if ~isempty(dImpact)
        names = [names, sort({dImpact.name})]; %#ok<AGROW>
    end

    d = dir(fullfile(plotDir, 'Comparison__*.png'));
    if isempty(d)
        d = dir(fullfile(plotDir, '*.png'));
    end
    if ~isempty(d)
        names = [names, sort({d.name})]; %#ok<AGROW>
    end

    % keep first occurrence order but remove duplicates
    [~, ia] = unique(names, 'stable');
    names = names(sort(ia));
    figFiles = names(1:min(cfg.maxFigures, numel(names)));
end

%% Build and write the report

lines = build_report_lines(batchName, runTable, caseFolders, overridesByCase, terminalTable, impactTable, figFiles, cfg.maxImpactRows);

texPath = fullfile(batchDir, cfg.outputTexName);
fid = fopen(texPath, 'w');
if fid < 0
    error('summarize_sensitivity_runs:CannotWriteTex', 'Could not open for writing: %s', texPath);
end
for i = 1:numel(lines)
    if ~is_valid_fid(fid)
        fid = fopen(texPath, 'a');
        if fid < 0
            error('summarize_sensitivity_runs:CannotWriteTex', ...
                'File handle became invalid and could not be reopened: %s', texPath);
        end
    end
    fprintf(fid, '%s\n', lines{i});
end
close_if_open(fid);

fprintf('LaTeX report written: %s\n', texPath);
fprintf('Compile with (from that folder): pdflatex %s\n', cfg.outputTexName);

%% Local functions

function batchDir = resolve_batch_dir(sensitivityRoot, batchName)
    if ~isempty(strtrim(batchName))
        batchDir = fullfile(sensitivityRoot, batchName);
        if ~exist(batchDir, 'dir')
            error('summarize_sensitivity_runs:BatchNotFound', 'Specified batch not found: %s', batchDir);
        end
        return
    end

    listing = dir(sensitivityRoot);
    candidates = listing([listing.isdir]);
    names = {candidates.name};
    names = names(~ismember(names, {'.', '..'}));
    names = names(startsWith(names, 'Batch_') | startsWith(names, 'Sensitivity_'));
    if isempty(names)
        error('summarize_sensitivity_runs:NoBatchFound', 'No Batch_* or Sensitivity_* folder found under %s', sensitivityRoot);
    end

    timestamps = nan(size(names));
    hasContent = false(size(names));
    for i = 1:numel(names)
        d = dir(fullfile(sensitivityRoot, names{i}));
        if ~isempty(d)
            timestamps(i) = max([d.datenum]);
        end
        hasContent(i) = isfile(fullfile(sensitivityRoot, names{i}, 'SensitivitySummary.csv'));
    end

    [~, order] = sortrows([~hasContent(:), -timestamps(:)]);
    batchDir = fullfile(sensitivityRoot, names{order(1)});
end

function caseFolders = list_case_folders(batchDir)
    listing = dir(batchDir);
    isDir = [listing.isdir];
    names = {listing(isDir).name};
    names = names(~ismember(names, {'.', '..', 'Plots'}));
    isNumbered = ~cellfun(@isempty, regexp(names, '^\d+_', 'once'));
    caseFolders = [sort(names(isNumbered)), sort(names(~isNumbered))];
end

function s = describe_case_overrides(caseDir)
    s = '';
    appliedPath = fullfile(caseDir, 'AppliedOverrides.csv');
    if isfile(appliedPath)
        t = read_table_if_exists(appliedPath);
        if ~isempty(t) && all(ismember({'Parameter', 'NewValue'}, t.Properties.VariableNames))
            parts = cell(height(t), 1);
            for r = 1:height(t)
                parts{r} = sprintf('%s=%s', char(string(t.Parameter(r))), format_num(t.NewValue(r)));
            end
            s = strjoin(parts, ', ');
            return
        end
    end
end

function t = read_table_if_exists(p)
    t = table();
    if ~isfile(p)
        return
    end
    try
        t = readtable(p, 'PreserveVariableNames', true);
    catch
        try
            t = readtable(p, 'VariableNamingRule', 'preserve');
        catch
            t = readtable(p);
        end
    end

    if has_generic_var_names(t) && endsWith(lower(p), '.csv')
        t = read_csv_with_header(p);
    end
end

function lines = build_report_lines(batchName, runTable, caseFolders, overridesByCase, terminalTable, impactTable, figFiles, maxImpactRows)
    lines = {};
    lines = append_line(lines, '\documentclass[11pt]{article}');
    lines = append_line(lines, '\usepackage[T1]{fontenc}');
    lines = append_line(lines, '\usepackage[utf8]{inputenc}');
    lines = append_line(lines, '\usepackage[margin=2.5cm]{geometry}');
    lines = append_line(lines, '\usepackage{booktabs}');
    lines = append_line(lines, '\usepackage{graphicx}');
    lines = append_line(lines, '\graphicspath{{Plots/}}');
    lines = append_line(lines, sprintf('\\title{DGE-METRIC Sensitivity Report\\\\\\large %s}', escape_latex(batchName)));
    lines = append_line(lines, '\author{DGE-METRIC}');
    lines = append_line(lines, sprintf('\\date{%s}', datestr(now, 'yyyy-mm-dd'))); %#ok<TNOW1,DATST>
    lines = append_line(lines, '\begin{document}');
    lines = append_line(lines, '\maketitle');

    % --- Run summary ---
    lines = append_line(lines, '\section*{Run Summary}');
    if isempty(runTable)
        lines = append_line(lines, 'No \texttt{SensitivitySummary.csv} found for this batch; showing case folders only.\\[0.5em]');
        lines = append_line(lines, '\begin{tabular}{ll}');
        lines = append_line(lines, '\toprule');
        lines = append_line(lines, 'Case & Overrides \\');
        lines = append_line(lines, '\midrule');
        for i = 1:numel(caseFolders)
            ov = overridesByCase(caseFolders{i});
            lines = append_line(lines, sprintf('%s & %s \\\\', escape_latex(caseFolders{i}), escape_latex(ov)));
        end
        lines = append_line(lines, '\bottomrule');
        lines = append_line(lines, '\end{tabular}');
    else
        caseVar = pick_first_variable(runTable, {'CaseLabel', 'CaseName', 'Case'});
        statusVar = pick_first_variable(runTable, {'Status'});
        durationVar = pick_first_variable(runTable, {'DurationMinutes'});

        if isempty(caseVar) || isempty(statusVar) || isempty(durationVar)
            error('summarize_sensitivity_runs:MissingSummaryColumns', ...
                ['SensitivitySummary.csv is missing one of the required columns. ' ...
                 'Expected case/status/duration columns, found: %s'], ...
                strjoin(runTable.Properties.VariableNames, ', '));
        end

        lines = append_line(lines, '\begin{tabular}{llrl}');
        lines = append_line(lines, '\toprule');
        lines = append_line(lines, 'Case & Status & Duration (min) & Overrides \\');
        lines = append_line(lines, '\midrule');
        for r = 1:height(runTable)
            caseLabel = char(string(runTable.(caseVar)(r)));
            status = char(string(runTable.(statusVar)(r)));
            duration = format_num(runTable.(durationVar)(r));
            key = caseLabel;
            matchIdx = find(endsWith(caseFolders, caseLabel), 1);
            if ~isempty(matchIdx)
                key = caseFolders{matchIdx};
            end
            if isKey(overridesByCase, key)
                ov = overridesByCase(key);
            else
                ov = '';
            end
            lines = append_line(lines, sprintf('%s & %s & %s & %s \\\\', ...
                escape_latex(caseLabel), escape_latex(status), duration, escape_latex(ov)));
        end
        lines = append_line(lines, '\bottomrule');
        lines = append_line(lines, '\end{tabular}');
    end

    % --- Top parameter impact ranking ---
    if ~isempty(impactTable) && all(ismember({'Parameter', 'ParameterValue', 'PercentDeviation'}, impactTable.Properties.VariableNames))
        lines = append_line(lines, '\section*{Top Parameter Impacts (terminal-year \% deviation)}');
        lines = append_line(lines, '\begin{tabular}{llr}');
        lines = append_line(lines, '\toprule');
        lines = append_line(lines, 'Parameter & Value & Deviation (\%) \\');
        lines = append_line(lines, '\midrule');

        nRows = min(maxImpactRows, height(impactTable));
        for r = 1:nRows
            pName = safe_text(impactTable.Parameter(r));
            pVal = safe_text(impactTable.ParameterValue(r));
            pDev = format_num(impactTable.PercentDeviation(r));
            lines = append_line(lines, sprintf('%s & %s & %s \\', ...
                escape_latex(pName), escape_latex(pVal), pDev));
        end

        lines = append_line(lines, '\bottomrule');
        lines = append_line(lines, '\end{tabular}');
    end

    % --- Terminal-year comparison ---
    if ~isempty(terminalTable) && all(ismember({'Case', 'Scenario', 'Variable', 'TerminalValue'}, terminalTable.Properties.VariableNames))
        terminalYear = '';
        if ismember('TerminalYear', terminalTable.Properties.VariableNames) && height(terminalTable) > 0
            terminalYear = format_num(terminalTable.TerminalYear(1));
        end
        lines = append_line(lines, sprintf('\\section*{Terminal-Year Comparison (%s)}', escape_latex(terminalYear)));

        scenarios = unique(string(terminalTable.Scenario), 'stable');
        for iScen = 1:numel(scenarios)
            scen = scenarios(iScen);
            sub = terminalTable(string(terminalTable.Scenario) == scen, :);
            variables = unique(string(sub.Variable), 'stable');
            cases = unique(string(sub.Case), 'stable');

            lines = append_line(lines, sprintf('\\subsection*{%s}', escape_latex(char(scen))));
            colSpec = ['l' repmat('r', 1, numel(variables))];
            lines = append_line(lines, sprintf('\\begin{tabular}{%s}', colSpec));
            lines = append_line(lines, '\toprule');
            headerCells = arrayfun(@(v) [' & ' escape_latex(char(v))], variables, 'UniformOutput', false);
            header = [{'Case'}, reshape(headerCells, 1, [])];
            lines = append_line(lines, [strjoin(header, ''), ' \\']);
            lines = append_line(lines, '\midrule');
            for iCase = 1:numel(cases)
                rowVals = cell(1, numel(variables));
                for iVar = 1:numel(variables)
                    m = sub(string(sub.Case) == cases(iCase) & string(sub.Variable) == variables(iVar), :);
                    if isempty(m)
                        rowVals{iVar} = '--';
                    else
                        rowVals{iVar} = format_num(m.TerminalValue(1));
                    end
                end
                rowStr = [{escape_latex(char(cases(iCase)))} arrayfun(@(x) [' & ' x{1}], rowVals, 'UniformOutput', false)];
                lines = append_line(lines, [strjoin(rowStr, ''), ' \\']);
            end
            lines = append_line(lines, '\bottomrule');
            lines = append_line(lines, '\end{tabular}');
        end
    else
        lines = append_line(lines, '\section*{Terminal-Year Comparison}');
        lines = append_line(lines, 'No \texttt{Sensitivity\_TerminalValues.csv} found; run \texttt{plot_sensitivity_scenario_results.m} for this batch first.');
    end

    % --- Figures ---
    if ~isempty(figFiles)
        lines = append_line(lines, '\section*{Selected Trajectories}');
        for i = 1:numel(figFiles)
            [~, base] = fileparts(figFiles{i});
            caption = strrep(base, '__', ' | ');
            lines = append_line(lines, '\begin{figure}[h!]');
            lines = append_line(lines, '\centering');
            lines = append_line(lines, sprintf('\\includegraphics[width=0.85\\linewidth]{%s}', figFiles{i}));
            lines = append_line(lines, sprintf('\\caption{%s}', escape_latex(caption)));
            lines = append_line(lines, '\end{figure}');
        end
    end

    lines = append_line(lines, '\end{document}');
end

function lines = append_line(lines, s)
    lines{end + 1} = s;
end

function name = pick_first_variable(tab, candidates)
    name = '';
    for i = 1:numel(candidates)
        if ismember(candidates{i}, tab.Properties.VariableNames)
            name = candidates{i};
            return
        end
    end
end

function tf = has_generic_var_names(tab)
    names = tab.Properties.VariableNames;
    tf = ~isempty(names) && all(~cellfun(@isempty, regexp(names, '^Var\d+$', 'once')));
end

function t = read_csv_with_header(p)
    raw = readcell(p, 'Delimiter', ',');
    if isempty(raw)
        t = table();
        return
    end

    headers = raw(1, :);
    data = raw(2:end, :);
    headers = cellfun(@normalize_header_cell, headers, 'UniformOutput', false);

    validCols = ~cellfun(@isempty, headers);
    headers = headers(validCols);
    data = data(:, validCols);

    t = cell2table(data, 'VariableNames', headers);
end

function header = normalize_header_cell(value)
    header = strtrim(char(string(value)));
    if strcmpi(header, '<missing>')
        header = '';
    end
end

function out = escape_latex(s)
    s = char(string(s));
    s = strrep(s, '\', '');
    s = strrep(s, '_', '\_');
    s = strrep(s, '%', '\%');
    s = strrep(s, '&', '\&');
    s = strrep(s, '#', '\#');
    out = s;
end

function out = format_num(v)
    if isnumeric(v)
        if isscalar(v) && isfinite(v)
            out = sprintf('%.4g', v);
        else
            out = 'NaN';
        end
    else
        out = escape_latex(char(string(v)));
    end
end

function out = safe_text(v)
    if ismissing(v)
        out = '';
        return
    end
    out = char(string(v));
end

function close_if_open(fid)
    if fid >= 0 && ~isempty(fopen(fid))
        fclose(fid);
    end
end

function tf = is_valid_fid(fid)
    tf = isnumeric(fid) && isscalar(fid) && fid >= 0 && ~isempty(fopen(fid));
end
