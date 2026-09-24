function summary = reproduce_macro_impact_assessment_figures(varargin)
% reproduce_macro_impact_assessment_figures  Regenerate every figure of the IWH Macro Impact report.
%
%   reproduce_macro_impact_assessment_figures
%   summary = reproduce_macro_impact_assessment_figures('Name', value, ...)
%
% Runs, in order, every script listed in README_MacroImpactAssessment.md
% (Figures 1-10 of "IWH_Report_Macro_Impact_Assessment_revised.docx"):
%
%   Fig. 1-2  generate_ee_simulation_results_figures.m       -> docs/figures/EE_Simulation_Results
%   Fig. 3    generate_ee_nz_simulation_results_figures.m    -> docs/figures/EE_NZ_Simulation_Results
%   Fig. 4-5  generate_finance_simulation_results_figures.m  -> docs/figures/Finance_Simulation_Results
%   Fig. 6    generate_gf_nz_simulation_results_figures.m    -> docs/figures/GF_NZ_Simulation_Results
%   Fig. 7-9  generate_nz_simulation_results_figures.m       -> docs/figures/NZ_Simulation_Results
%   Fig. 10   Visualization/PolicyRecommendations.py         -> scripts/reporting/Visualization
%
% Before running anything it checks that every scenario CSV each step needs
% exists in ExcelFiles/Output (using the same suffix/fallback rules as the
% scripts themselves), so a missing simulation is reported up front with the
% RunSimulations scenario group that produces it. Each step then runs in its
% own isolated workspace (the figure scripts call clearvars/clc/close all),
% failures are caught and recorded rather than aborting the batch, and the
% named report outputs are checked to have been (re)written. A summary table
% is printed at the end and returned.
%
% Prerequisites:
%   * ExcelFiles/Output/<Scenario><suffix>.csv for the scenarios below, i.e.
%     RunSimulations with DGE_SCENARIO_GROUPS=ReportReplication (or the
%     individual groups Reference, EE, GF_PDP8, GF_NZ, NZ_Sensitivity).
%   * <suffix> is report_version_suffix(): '_replication_fix' unless the
%     DGE_WORKBOOK_VERSION environment variable overrides it.
%   * Figure 10 needs Python 3 (stdlib only; the repo's .venv is used if
%     present, else DGE_PYTHON, else python/py on PATH) and, for the PNG
%     export, ImageMagick's `magick` on PATH (SVG is always written).
%
% Name-value options:
%   'Steps'        Subset of step keys to run, e.g. {'EE','NZ'}. Keys:
%                  EE, EE_NZ, Finance, GF_NZ, NZ, Policy. Default: all.
%   'StopOnError'  true -> rethrow the first failing step. Default false.
%   'DryRun'       true -> only run the input check and print the plan.
%                  Default false.
%   'RunPython'    false -> skip the Python step (Figure 10). Default true.
%
% Note: the figure scripts call clc, so progress lines printed while they
% run are cleared from the command window; the final summary survives.
%
% See also README_MacroImpactAssessment.md, report_version_suffix.

%% ---- Options -----------------------------------------------------------
p = inputParser;
p.FunctionName = mfilename;
addParameter(p, 'Steps', {}, @(x) ischar(x) || isstring(x) || iscellstr(x));
addParameter(p, 'StopOnError', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'DryRun', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'RunPython', true, @(x) islogical(x) || isnumeric(x));
parse(p, varargin{:});
opts = p.Results;
opts.StopOnError = logical(opts.StopOnError);
opts.DryRun = logical(opts.DryRun);
opts.RunPython = logical(opts.RunPython);
selectedSteps = string(opts.Steps);
selectedSteps = selectedSteps(strlength(selectedSteps) > 0);

%% ---- Paths -------------------------------------------------------------
reportingDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(fileparts(reportingDir));
oldPwd = pwd;
cleanupPwd = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

csvDir = fullfile(repoRoot, 'ExcelFiles', 'Output');
figDir = fullfile(repoRoot, 'docs', 'figures');
visDir = fullfile(reportingDir, 'Visualization');
sversion = report_version_suffix();

%% ---- Step definitions (mirror README_MacroImpactAssessment.md) --------
steps = struct('Key', {}, 'Figures', {}, 'Script', {}, 'Kind', {}, ...
    'Scenarios', {}, 'InputMode', {}, 'OutputDir', {}, 'Outputs', {}, ...
    'ResolvedSuffix', {}, 'MissingInputs', {});

steps(end+1) = make_step('EE', '1-2', ...
    fullfile(reportingDir, 'generate_ee_simulation_results_figures.m'), 'matlab', ...
    ["Baseline", "EE_Dir10_full", "EE_Dir10_full_NoBESS", "EE_RTS_prerev_95GW"], 'fallback', ...
    fullfile(figDir, 'EE_Simulation_Results'), ...
    ["GDP_Level_Deviation_vs_Baseline_5Y_Average.png", ...
     "Energy_Intensity_Deviation_vs_Baseline_5Y_Average.png"]);

steps(end+1) = make_step('EE_NZ', '3', ...
    fullfile(reportingDir, 'generate_ee_nz_simulation_results_figures.m'), 'matlab', ...
    ["Baseline", "NZ", "NZ_Dir10_full", "NZ_Dir10_full_NoBESS"], 'fallback', ...
    fullfile(figDir, 'EE_NZ_Simulation_Results'), ...
    ["GDP_Level_Deviation_vs_Baseline_5Y_Average.png", ...
     "Energy_Intensity_Deviation_vs_Baseline_5Y_Average.png"]);

steps(end+1) = make_step('Finance', '4-5', ...
    fullfile(reportingDir, 'generate_finance_simulation_results_figures.m'), 'matlab', ...
    ["Baseline", "PDP8_GF_A", "PDP8_GF_B", "PDP8_GF_C"], 'strict', ...
    fullfile(figDir, 'Finance_Simulation_Results'), ...
    ["GDP_Level_Deviation_vs_Baseline_5Y_Average.png", ...
     "WACC_Renewables_Deviation_vs_Baseline_5Y_Average.png"]);

steps(end+1) = make_step('GF_NZ', '6', ...
    fullfile(reportingDir, 'generate_gf_nz_simulation_results_figures.m'), 'matlab', ...
    ["Baseline", "NZ", "NZ_GF_B", "NZ_GF_C"], 'strict', ...
    fullfile(figDir, 'GF_NZ_Simulation_Results'), ...
    ["WACC_Renewables_Deviation_vs_Baseline_5Y_Average.png", ...
     "GDP_Level_Deviation_vs_Baseline_5Y_Average.png"]);

steps(end+1) = make_step('NZ', '7-9', ...
    fullfile(reportingDir, 'generate_nz_simulation_results_figures.m'), 'matlab', ...
    ["Baseline", "NZ", "NZ_subsidy", "NZ_subsidy_direct", "NZ_Dir10_full_GF_C"], 'strict', ...
    fullfile(figDir, 'NZ_Simulation_Results'), ...
    ["ETS_Revenue_5Y_Cumulative_Billion_USD_NZ_Scenarios.png", ...
     "ETS_Revenue_Share_Deviation_vs_Baseline_5Y_Average.png", ...
     "GDP_Level_Deviation_vs_Baseline_5Y_Average.png"]);

steps(end+1) = make_step('Policy', '10', ...
    fullfile(visDir, 'PolicyRecommendations.py'), 'python', ...
    strings(1, 0), 'none', visDir, ...
    ["Vietnam_integrated_policy_package_revised.svg", ...
     "Vietnam_integrated_policy_package_revised.png"]);

% Scenario stem -> RunSimulations scenario group (for the missing-input hint).
scenarioGroupOf = struct( ...
    'Baseline', 'Reference', 'NZ', 'Reference', ...
    'EE_Dir10_full', 'EE', 'EE_Dir10_full_NoBESS', 'EE', 'EE_RTS_prerev_95GW', 'EE', ...
    'PDP8_GF_A', 'GF_PDP8', 'PDP8_GF_B', 'GF_PDP8', 'PDP8_GF_C', 'GF_PDP8', ...
    'NZ_GF_A', 'GF_NZ', 'NZ_GF_B', 'GF_NZ', 'NZ_GF_C', 'GF_NZ', ...
    'NZ_Dir10_full', 'NZ_Sensitivity', 'NZ_Dir10_full_NoBESS', 'NZ_Sensitivity', ...
    'NZ_subsidy', 'NZ_Sensitivity', 'NZ_subsidy_direct', 'NZ_Sensitivity', ...
    'NZ_Dir10_full_GF_C', 'NZ_Sensitivity');

%% ---- Select steps ------------------------------------------------------
if ~isempty(selectedSteps)
    known = string({steps.Key});
    unknown = setdiff(selectedSteps, known);
    if ~isempty(unknown)
        error('reproduce_macro_impact_assessment_figures:UnknownStep', ...
            'Unknown step key(s): %s. Valid keys: %s.', ...
            strjoin(unknown, ', '), strjoin(known, ', '));
    end
    steps = steps(ismember(known, selectedSteps));
end
if ~opts.RunPython
    steps = steps(~strcmp({steps.Kind}, 'python'));
end
if isempty(steps)
    error('reproduce_macro_impact_assessment_figures:NoSteps', 'No steps selected.');
end

%% ---- Pre-flight: inputs and tools -------------------------------------
fprintf('\n=== Macro Impact Assessment figures: reproduction plan ===\n');
fprintf('Repo root       : %s\n', repoRoot);
fprintf('CSV directory   : %s\n', csvDir);
fprintf('Version suffix  : "%s"  (report_version_suffix; override with DGE_WORKBOOK_VERSION)\n\n', sversion);

pythonExe = '';
magickOnPath = false;
anyMissing = false;
for iStep = 1:numel(steps)
    st = steps(iStep);
    switch st.Kind
        case 'matlab'
            [usedSuffix, missing] = resolve_inputs(csvDir, st.Scenarios, st.InputMode, sversion);
            steps(iStep).ResolvedSuffix = usedSuffix;
            if isempty(missing)
                fprintf('[%-7s] Fig. %-4s inputs OK  (suffix "%s")\n', st.Key, st.Figures, usedSuffix);
            else
                anyMissing = true;
                steps(iStep).MissingInputs = missing;
                groups = unique(cellfun(@(s) group_hint(scenarioGroupOf, s), cellstr(missing), 'UniformOutput', false));
                fprintf('[%-7s] Fig. %-4s MISSING CSV: %s\n', st.Key, st.Figures, ...
                    strjoin(missing + usedSuffix + ".csv", ', '));
                fprintf('          -> run RunSimulations with DGE_SCENARIO_GROUPS=%s (or ReportReplication)\n', ...
                    strjoin(groups, ','));
            end
        case 'python'
            pythonExe = find_python(repoRoot);
            [stMagick, ~] = system('magick -version');
            magickOnPath = (stMagick == 0);
            if isempty(pythonExe)
                anyMissing = true;
                steps(iStep).MissingInputs = "python";
                fprintf('[%-7s] Fig. %-4s NO PYTHON found (set DGE_PYTHON or create .venv)\n', st.Key, st.Figures);
            else
                fprintf('[%-7s] Fig. %-4s python: %s', st.Key, st.Figures, pythonExe);
                if magickOnPath
                    fprintf('  | ImageMagick OK\n');
                else
                    fprintf('  | ImageMagick NOT on PATH -> PNG export will be skipped\n');
                end
            end
    end
end
fprintf('\n');

if opts.DryRun
    fprintf('DryRun=true: nothing executed.\n');
    summary = build_summary(steps, {}, [], sversion);
    if nargout == 0
        clear summary
    end
    return
end

%% ---- Run ---------------------------------------------------------------
nSteps = numel(steps);
status = repmat({'not run'}, nSteps, 1);
elapsed = nan(nSteps, 1);
errMsgs = repmat({''}, nSteps, 1);
outputsOk = false(nSteps, 1);

for iStep = 1:nSteps
    st = steps(iStep);
    fprintf('--- [%s] Figure(s) %s: %s\n', st.Key, st.Figures, relpath(st.Script, repoRoot));

    if ~isempty(st.MissingInputs)
        status{iStep} = 'skipped (missing inputs)';
        fprintf('    skipped: missing %s\n', strjoin(string(st.MissingInputs), ', '));
        continue
    end

    tStart = tic;
    startTime = datetime('now') - seconds(2);
    try
        switch st.Kind
            case 'matlab'
                run_script_isolated(st.Script);
                close all force;
            case 'python'
                run_python(pythonExe, st.Script);
        end
        status{iStep} = 'ok';
    catch ME
        status{iStep} = 'FAILED';
        errMsgs{iStep} = ME.message;
        close all force;
        cd(repoRoot);
        fprintf(2, '    FAILED: %s\n', ME.message);
        if opts.StopOnError
            rethrow(ME);
        end
    end
    elapsed(iStep) = toc(tStart);

    % Verify the report outputs were (re)written by this step.
    if strcmp(status{iStep}, 'ok')
        [outputsOk(iStep), stale] = check_outputs(st.OutputDir, st.Outputs, startTime);
        if strcmp(st.Kind, 'python') && ~magickOnPath
            % PNG is expected to be missing/stale without ImageMagick.
            stale = stale(~endsWith(stale, ".png"));
            outputsOk(iStep) = isempty(stale);
        end
        if ~outputsOk(iStep)
            status{iStep} = 'ok (outputs not refreshed)';
            errMsgs{iStep} = char("not (re)written: " + strjoin(stale, ', '));
        end
    end
end

%% ---- Summary -----------------------------------------------------------
summary = build_summary(steps, status, elapsed, sversion, errMsgs);

fprintf('\n=== Macro Impact Assessment figures: summary (suffix "%s") ===\n', sversion);
fprintf('%-8s %-6s %-9s %-58s %-28s %s\n', 'Step', 'Fig.', 'Time [s]', 'Script', 'Status', 'Output dir');
for iStep = 1:nSteps
    st = steps(iStep);
    fprintf('%-8s %-6s %9.1f %-58s %-28s %s\n', st.Key, st.Figures, elapsed(iStep), ...
        relpath(st.Script, repoRoot), status{iStep}, relpath(st.OutputDir, repoRoot));
    if ~isempty(errMsgs{iStep})
        fprintf('         %s\n', errMsgs{iStep});
    end
end
fprintf('\nReport figure files ("!" = missing):\n');
for iStep = 1:nSteps
    st = steps(iStep);
    for iOut = 1:numel(st.Outputs)
        f = fullfile(st.OutputDir, char(st.Outputs(iOut)));
        if isfile(f)
            mark = ' ';
        else
            mark = '!';
        end
        fprintf('  %s Fig. %-4s %s\n', mark, st.Figures, relpath(f, repoRoot));
    end
end
if anyMissing
    fprintf('\nSome steps were skipped for missing inputs (see above).\n');
end
nFailed = sum(strcmp(status, 'FAILED'));
if nFailed > 0
    fprintf(2, '\n%d step(s) FAILED.\n', nFailed);
elseif all(strcmp(status, 'ok'))
    fprintf('\nAll %d step(s) completed and report outputs refreshed.\n', nSteps);
end

if nargout == 0
    clear summary
end
end

%% ======================================================================
%% Local functions
%% ======================================================================

function st = make_step(key, figures, script, kind, scenarios, inputMode, outputDir, outputs)
st = struct('Key', key, 'Figures', figures, 'Script', script, 'Kind', kind, ...
    'Scenarios', scenarios, 'InputMode', inputMode, 'OutputDir', outputDir, ...
    'Outputs', outputs, 'ResolvedSuffix', '', 'MissingInputs', strings(1, 0));
end

function run_script_isolated(scriptPath)
% Run a figure script in this function's own workspace so that the
% clearvars/clc/close all at the top of the script cannot touch the caller.
% Nothing may be referenced after run(): the script clears this workspace.
run(scriptPath);
end

function run_python(pythonExe, scriptPath)
% Run the Python script from its own directory (it imports a sibling module
% and writes next to itself) with only one quoted token on the command line,
% which keeps Windows cmd.exe quote handling predictable.
scriptDir = fileparts(scriptPath);
[~, name, ext] = fileparts(scriptPath);
oldPwd = pwd;
cleanupPwd = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(scriptDir);
cmd = sprintf('"%s" %s%s', pythonExe, name, ext);
[status, out] = system(cmd);
fprintf('%s', out);
if status ~= 0
    error('reproduce_macro_impact_assessment_figures:PythonFailed', ...
        'Python exited with status %d running %s', status, cmd);
end
end

function pythonExe = find_python(repoRoot)
% Order: DGE_PYTHON env var, repo .venv, python on PATH, py launcher.
candidates = {};
envPy = strtrim(getenv('DGE_PYTHON'));
if ~isempty(envPy)
    candidates{end+1} = envPy;
end
if ispc
    candidates{end+1} = fullfile(repoRoot, '.venv', 'Scripts', 'python.exe');
else
    candidates{end+1} = fullfile(repoRoot, '.venv', 'bin', 'python');
end
candidates = [candidates, {'python', 'python3', 'py'}];
pythonExe = '';
for i = 1:numel(candidates)
    c = candidates{i};
    if any(c == '\') || any(c == '/')
        if isfile(c)
            pythonExe = c;
            return
        end
    else
        [st, ~] = system(sprintf('%s --version', c));
        if st == 0
            pythonExe = c;
            return
        end
    end
end
end

function [usedSuffix, missing] = resolve_inputs(csvDir, scenarios, inputMode, sversion)
% Mirror the file-resolution rules of the figure scripts:
%   'strict'   -> <Scenario><sversion>.csv must exist (finance pipeline)
%   'fallback' -> try sversion, then the other known suffixes, and use the
%                 first suffix for which ALL scenarios exist (EE pipeline)
switch inputMode
    case 'strict'
        candidateSuffixes = string(sversion);
    case 'fallback'
        candidateSuffixes = unique([string(sversion), "_replication_fix", "_replication", ""], 'stable');
    otherwise
        usedSuffix = '';
        missing = strings(1, 0);
        return
end
for iCand = 1:numel(candidateSuffixes)
    suffix = candidateSuffixes(iCand);
    present = arrayfun(@(s) isfile(fullfile(csvDir, char(s + suffix + ".csv"))), scenarios);
    if all(present)
        usedSuffix = char(suffix);
        missing = strings(1, 0);
        return
    end
end
% Nothing matched: report against the preferred suffix.
usedSuffix = char(candidateSuffixes(1));
present = arrayfun(@(s) isfile(fullfile(csvDir, char(s + candidateSuffixes(1) + ".csv"))), scenarios);
missing = scenarios(~present);
end

function g = group_hint(scenarioGroupOf, scenario)
if isfield(scenarioGroupOf, scenario)
    g = scenarioGroupOf.(scenario);
else
    g = '<unknown group>';
end
end

function [allOk, stale] = check_outputs(outputDir, outputs, startTime)
stale = strings(1, 0);
for i = 1:numel(outputs)
    f = fullfile(outputDir, char(outputs(i)));
    d = dir(f);
    if isempty(d) || datetime(d.datenum, 'ConvertFrom', 'datenum') < startTime
        stale(end+1) = outputs(i); %#ok<AGROW>
    end
end
allOk = isempty(stale);
end

function r = relpath(p, root)
p = char(p);
root = char(root);
if strncmpi(p, root, numel(root))
    r = p(numel(root) + 2:end);
else
    r = p;
end
r = strrep(r, '\', '/');
end

function summary = build_summary(steps, status, elapsed, sversion, errMsgs)
if nargin < 5 || isempty(errMsgs)
    errMsgs = repmat({''}, numel(steps), 1);
end
if isempty(status)
    status = repmat({'not run'}, numel(steps), 1);
end
if isempty(elapsed)
    elapsed = nan(numel(steps), 1);
end
Step = string({steps.Key}');
Figures = string({steps.Figures}');
Script = string({steps.Script}');
Status = string(status(:));
Seconds = elapsed(:);
OutputDir = string({steps.OutputDir}');
Outputs = arrayfun(@(s) strjoin(s.Outputs, '; '), steps(:));
Message = string(errMsgs(:));
summary = table(Step, Figures, Script, Status, Seconds, OutputDir, Outputs, Message);
summary.Properties.Description = sprintf('Macro Impact Assessment figure reproduction (suffix "%s")', sversion);
end
