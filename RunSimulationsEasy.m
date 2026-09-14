% RunSimulationsEasy  Friendly wrapper around RunSimulations.m for new users.
%
% Run from anywhere inside the repository:
%   RunSimulationsEasy
%
% Unlike RunSimulations.m (which is meant to be hand-edited per run and whose
% committed scenario-group selection can point at scenarios that need results
% from a prior run that doesn't exist on a fresh clone), this script:
%   - checks the environment (Dynare on the path, MATLAB version) before
%     attempting anything expensive, with actionable errors instead of a
%     cryptic crash mid-run;
%   - checks the canonical Excel workbooks exist and are structurally sane
%     before running, pointing at scripts/maintenance/build_all_workbooks.m
%     if not;
%   - forces a small, safe, self-contained scenario selection (Baseline then
%     NZ) via env-var overrides added to RunSimulations.m, so it never
%     depends on a scenario group or prior run state you haven't set up;
%   - captures the full run to a log file and derives an explicit
%     SOLVED/FAILED verdict per scenario afterward, since RunSimulations.m's
%     own per-scenario try/catch prints and continues with no reliable
%     pass/fail signal of its own;
%   - on failure, scans the log for known error signatures and prints a
%     concrete next step instead of leaving you to decode a raw Dynare error.
%
% See the "Easy-run wrapper" section of the build/run plan for the research
% behind these choices (RunSimulations.m's committed default currently
% resolves to a scenario group that fails silently on a fresh clone -- this
% script exists specifically so that trap is not the first thing a new user
% hits).

repoRoot = fileparts(mfilename('fullpath'));
cd(repoRoot);
setup_paths();
cfg = load_cfg(); % recomputed again after the run() call below, see Stage 3

fprintf('=== RunSimulationsEasy: scenarios={%s} ===\n', strjoin(cfg.scenarioNames, ', '));

%% Stage 0 -- Environment pre-flight
fprintf('\n--- Stage 0: environment pre-flight ---\n');

if isempty(which('dynare'))
    error('RunSimulationsEasy:DynareNotFound', ...
        ['Dynare was not found on the MATLAB path after setup_paths(). ' ...
         'setup_paths.m only checks C:\\dynare\\7.0\\matlab and C:\\dynare\\6.1\\matlab -- ' ...
         'install Dynare 7.0 there, or if it is installed elsewhere, addpath the folder ' ...
         'containing dynare.m manually and re-run.']);
end
fprintf('  Dynare found: %s\n', which('dynare'));

releaseYear = str2double(regexp(version('-release'), '^\d{4}', 'match', 'once'));
if ~isnan(releaseYear) && releaseYear < 2020
    warning('RunSimulationsEasy:OldMatlab', ...
        ['MATLAB %s detected; R2020a or newer is recommended (docs/reference/running.md). ' ...
         'Continuing, but unrelated errors may actually be a version issue.'], version('-release'));
end
fprintf('  MATLAB version: %s\n', version('-release'));

%% Stage 1 -- Workbook pre-flight (canonical workbooks only)
fprintf('\n--- Stage 1: workbook pre-flight ---\n');

calibrationWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelCalibration5Sectorsand1Regions.xlsx');
canonicalBaselineWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelBaseline5Sectorsand1Regions.xlsx');
replicationBaselineWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelBaseline5Sectorsand1Regions_replication.xlsx');
scenariosWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions.xlsx');

requiredWorkbooks = {calibrationWorkbook, canonicalBaselineWorkbook, scenariosWorkbook};
for iFile = 1:numel(requiredWorkbooks)
    if ~isfile(requiredWorkbooks{iFile})
        error('RunSimulationsEasy:MissingWorkbook', ...
            ['Required canonical workbook not found:\n  %s\n' ...
             'Run scripts/maintenance/build_all_workbooks.m first (with ' ...
             'cfg.promoteBaselineToCanonical = true, or DGE_PROMOTE_BASELINE=1) to build and ' ...
             'promote it.'], requiredWorkbooks{iFile});
    end
end

validate_baseline_sheet(canonicalBaselineWorkbook, 'Baseline');
if ismember('NZ', cfg.scenarioNames)
    validate_nz_sheet(scenariosWorkbook, 'NZ');
end

if isfile(replicationBaselineWorkbook)
    replicationInfo = dir(replicationBaselineWorkbook);
    canonicalInfo = dir(canonicalBaselineWorkbook);
    if replicationInfo.datenum > canonicalInfo.datenum
        warning('RunSimulationsEasy:PossiblyUnpromoted', ...
            ['%s is newer than the canonical %s -- a build_all_workbooks.m run may not have ' ...
             'been promoted yet (DGE_PROMOTE_BASELINE=1). Continuing against the canonical ' ...
             'workbook as-is.'], replicationBaselineWorkbook, canonicalBaselineWorkbook);
    end
end
fprintf('  Canonical workbooks present and structurally sane.\n');

%% Stage 2 -- Scenario selection and expected-runtime notice
fprintf('\n--- Stage 2: scenario selection ---\n');
setenv('DGE_SCENARIO_NAMES', strjoin(cfg.scenarioNames, ','));
setenv('DGE_WORKBOOK_VERSION', 'canonical');
fprintf('  Running: %s (in this order -- later scenarios can depend on earlier ones)\n', ...
    strjoin(cfg.scenarioNames, ' -> '));
fprintf(['  Expect several minutes: Baseline solves over 20 perfect-foresight steps, ' ...
         'NZ-derived scenarios over 40 -- this is not hung.\n']);

%% Stage 3 -- Run with captured log
fprintf('\n--- Stage 3: running RunSimulations.m ---\n');
logDir = fullfile(repoRoot, 'ExcelFiles', 'Output', 'EasyRunLogs');
if ~isfolder(logDir)
    mkdir(logDir);
end
logPath = fullfile(logDir, sprintf('RunSimulationsEasy_%s.log', ...
    string(datetime('now'), 'yyyyMMdd_HHmmss')));
runStartDatenum = now; %#ok<TNOW1> (dir()'s .datenum is also legacy-serial; keep units consistent)

diary(logPath);
runError = [];
try
    run(fullfile(repoRoot, 'RunSimulations.m'));
catch caughtError
    runError = caughtError;
end
diary off;

repoRoot = get_repo_root(); % RunSimulations.m redefines repoRoot in this shared workspace
cfg = load_cfg();

if ~isempty(runError)
    fprintf('\n  RunSimulations.m raised an error outside its own per-scenario handling:\n');
    fprintf('    %s\n', runError.message);
end
fprintf('  Full run log: %s\n', logPath);

%% Stage 4 -- Post-run success verification
fprintf('\n--- Stage 4: checking results ---\n');
statuses = check_scenario_results(repoRoot, cfg.scenarioNames, runStartDatenum);
anyFailed = false;
for iStatus = 1:numel(statuses)
    if statuses(iStatus).solved
        fprintf('  %-12s SOLVED\n', statuses(iStatus).name);
    else
        fprintf('  %-12s FAILED  (%s)\n', statuses(iStatus).name, statuses(iStatus).reason);
        anyFailed = true;
    end
end

%% Stage 5 -- Friendly failure diagnosis
if anyFailed || ~isempty(runError)
    fprintf('\n--- Stage 5: troubleshooting hints ---\n');
    print_troubleshooting_hints(logPath);
end

%% Stage 6 -- Summary
fprintf('\n=== RunSimulationsEasy complete ===\n');
for iStatus = 1:numel(statuses)
    if statuses(iStatus).solved
        csvPath = fullfile(repoRoot, 'ExcelFiles', 'Output', [statuses(iStatus).name '.csv']);
        fprintf('  %-12s -> %s\n', statuses(iStatus).name, csvPath);
    end
end
fprintf(['\n  Next steps:\n' ...
         '    run(''scripts/analysis/check_results.m'')  -- visual comparison plots\n' ...
         '    Functions/steady_state/diagnostics/check_allocation_errors.m -- allocation error diagnostics\n']);

%% Local helper functions
% Defined here so they remain callable regardless of what run('RunSimulations.m')
% does to this script's shared workspace -- see the comment above Stage 3.

function repoRoot = get_repo_root()
repoRoot = fileparts(mfilename('fullpath'));
end

function cfg = load_cfg()
cfg = struct();
cfg.scenarioNames = {'Baseline', 'NZ'};
envScenarioNames = strtrim(getenv('DGE_EASY_SCENARIO_NAMES'));
if ~isempty(envScenarioNames)
    cfg.scenarioNames = strtrim(strsplit(envScenarioNames, ','));
end
end

function statuses = check_scenario_results(repoRoot, scenarioNames, runStartDatenum)
% A scenario counts as SOLVED only if BOTH: (a) structScenarioResults.mat has
% a field for it, and (b) its output CSV was written/updated after this run
% started. RunSimulations.m's own per-scenario try/catch swallows failures
% and prints "Run error: ..." without ever raising a signal a caller can
% check, so this reconstructs pass/fail from the same artifacts a human would
% inspect manually.
statuses = struct('name', {}, 'solved', {}, 'reason', {});
matPath = fullfile(repoRoot, 'structScenarioResults.mat');
hasMat = isfile(matPath);
if hasMat
    matData = load(matPath, 'structScenarioResults');
end
for iScenario = 1:numel(scenarioNames)
    name = scenarioNames{iScenario};
    csvPath = fullfile(repoRoot, 'ExcelFiles', 'Output', [name '.csv']);
    hasMatField = hasMat && isfield(matData.structScenarioResults, name);
    hasFreshCsv = isfile(csvPath) && dir(csvPath).datenum > runStartDatenum;
    solved = hasMatField && hasFreshCsv;
    if solved
        reason = '';
    elseif ~hasMat
        reason = sprintf('results file not found: %s', matPath);
    elseif ~hasMatField
        reason = sprintf('no "%s" field in structScenarioResults.mat', name);
    elseif ~isfile(csvPath)
        reason = sprintf('output CSV not found: %s', csvPath);
    else
        reason = sprintf('output CSV exists but was not updated by this run: %s', csvPath);
    end
    statuses(end + 1) = struct('name', name, 'solved', solved, 'reason', reason); %#ok<AGROW>
end
end

function print_troubleshooting_hints(logPath)
if ~isfile(logPath)
    fprintf('  Log file not found; nothing to scan.\n');
    return
end
logText = fileread(logPath);
hints = { ...
    'Undefined function ''dynare''', ...
        ['Dynare was not found on the MATLAB path. Check setup_paths.m''s Dynare search ' ...
         'paths, or addpath the folder containing dynare.m manually.']; ...
    'without convergence', ...
        ['The perfect-foresight solver did not converge. Inspect ' ...
         'Functions/Miscellaneous/Diagnostics/detect_pf_nan_residuals.m against the current ' ...
         'oo_/M_ (if still in the base workspace) to pinpoint the failing period/variable.']; ...
    'could not be found', ...
        ['A scenario workbook sheet may be missing or misnamed -- check ' ...
         'ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx for the expected sheet name.']; ...
    'Unable to find file or directory', ...
        ['A scenario depends on a prior scenario''s saved results (e.g. an NZ-derived ' ...
         'scenario needs NZ solved first) that is not present in structScenarioResults.mat.']; ...
    };
foundAny = false;
for iHint = 1:size(hints, 1)
    if contains(logText, hints{iHint, 1})
        foundAny = true;
        fprintf('  Possible cause: %s\n', hints{iHint, 2});
    end
end
if ~foundAny
    fprintf('  No known failure signature matched in the log -- inspect it directly:\n    %s\n', logPath);
end
end
