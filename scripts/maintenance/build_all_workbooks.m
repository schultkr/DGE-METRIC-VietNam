% build_all_workbooks  Orchestrate the Excel workbook build chain end to end.
%
% Run from the repository root:
%   run('scripts/maintenance/build_all_workbooks.m')
%
% Chains the manual runbook documented in
% docs/scenario_notes/workbook_creation_procedure.md into one script:
%   ExcelFiles/ModelCalibration5Sectorsand1Regions.xlsx  (IO_Data/Trade_Flows propagation)
%     -> ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx (full PDP8/RTS/VNEEP3 Baseline)
%     -> ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx (NZ sheet, more groups later)
%
% This script only builds/refreshes workbooks; it does not invoke RunSimulations.m.
%
% Configuration (env var overrides shown, all optional):
%   DGE_BUILD_MODE              'quickcheck' (default) or 'full'
%   DGE_BUILD_SCENARIO_GROUPS    comma-separated subset of
%                                 Reference,EE,GF_PDP8,GF_NZ,NZ_Sensitivity
%                                 (default 'Reference'; only Reference is wired
%                                 up so far, see Stage 4)
%
% IMPORTANT: update_data_excel.m (Stage 1) calls `clearvars` at the top, which
% wipes THIS script's local workspace too when invoked via run() -- run()
% executes the target file's code in the caller's own workspace, it does not
% sandbox it. The other maintenance scripts called below (Stages 2 and 4)
% don't clearvars but do set their own local variables of the same names this
% script uses (repoRoot, etc.), which land in the shared workspace and
% overwrite this script's copies. Local variables (repoRoot, cfg, file
% paths, ...) must therefore NOT be trusted to survive any run() call, from
% any stage. This script recomputes everything it needs via the local
% functions below (get_repo_root, load_cfg, workbook path helpers)
% immediately after every such call, rather than relying on variables set
% earlier in the script. Local function definitions, unlike variables, are
% unaffected by both clearvars and being overwritten.

repoRoot = get_repo_root();
cd(repoRoot);
setup_paths();
cfg = load_cfg(); % recomputed again after every clearvars-risk stage below

fprintf('=== build_all_workbooks: buildMode=%s, scenarioGroups={%s} ===\n', ...
    cfg.buildMode, strjoin(cfg.scenarioGroups, ','));

%% Stage 0 -- Preconditions
fprintf('\n--- Stage 0: preconditions ---\n');

[~, tasklistOut] = system('tasklist /FI "IMAGENAME eq EXCEL.EXE"');
if contains(tasklistOut, 'EXCEL.EXE')
    warning('build_all_workbooks:ExcelRunning', ...
        ['An EXCEL.EXE process is currently running. COM automation can hang or ' ...
         'silently corrupt writes if it holds a lock on a target workbook. Close ' ...
         'Excel (and kill orphaned EXCEL.EXE via Task Manager if none is visibly open) ' ...
         'before continuing. See docs/scenario_notes/workbook_creation_procedure.md, ' ...
         'Troubleshooting.']);
end

requiredSourceFiles = { ...
    fullfile(repoRoot, 'ExcelFiles', 'ScenarioPathDefinition.xlsx') };
for iFile = 1:numel(requiredSourceFiles)
    if ~isfile(requiredSourceFiles{iFile})
        error('build_all_workbooks:MissingSource', ...
            ['Required hand-maintained source workbook not found:\n  %s\n' ...
             'This pipeline refreshes existing workbooks; it does not create them from ' ...
             'nothing. Restore from git history -- see "Step 1" in ' ...
             'docs/scenario_notes/workbook_creation_procedure.md.'], requiredSourceFiles{iFile});
    end
end
seedInfo = ensure_workbook_shells(repoRoot);
fprintf('  Required source workbook present; canonical workbook shells ensured.\n');

skipRebuildStages = cfg.seedCanonicalFromReplicationFix && seedInfo.allFromReplicationFix;
if skipRebuildStages
    fprintf(['  Canonical workbook triad was seeded from *_replication_fix and ' ...
        'DGE_SEED_CANONICAL_FROM_REPLICATION_FIX is enabled; skipping stages 1-4 ' ...
        'to preserve exact replication_fix content.\n']);
end

%% Stage 1 -- Calibration propagation (IO_Data/Trade_Flows -> Data/Start/Structural Parameters)
if ~skipRebuildStages
    fprintf('\n--- Stage 1: calibration propagation ---\n');
    % update_data_excel.m overwrites the canonical calibration workbook in place
    % and has no backup logic of its own -- back it up first, same as Stage 3
    % does for the canonical Baseline workbook.
    backup_workbook(calibration_workbook_path(repoRoot));
    setenv('DGE_CALIBRATION_VERSION', '');
    run(fullfile(get_repo_root(), 'Functions', 'Miscellaneous', 'Excel', 'update_data_excel.m'));

    repoRoot = get_repo_root();
    cd(repoRoot);
    setup_paths();
    cfg = load_cfg();
    % update_data_excel.m calls clearvars; Stage 1 only runs when skipRebuildStages
    % was false, so restore that state explicitly for downstream guards.
    skipRebuildStages = false;
end

%% Stage 2 -- Baseline (full builder: PDP8/RTS/VNEEP3 overlays)
if ~skipRebuildStages
    fprintf('\n--- Stage 2: baseline build (mode=%s) ---\n', cfg.buildMode);
    if cfg.usePDP8InvestmentTargets
        setenv('DGE_USE_PDP8_INVESTMENT_TARGETS', '1');
    else
        setenv('DGE_USE_PDP8_INVESTMENT_TARGETS', '0');
    end
    run(fullfile(repoRoot, 'scripts', 'maintenance', 'create_baseline_from_user_input_file.m'));

    repoRoot = get_repo_root();
    cd(repoRoot);
    setup_paths();
    cfg = load_cfg();
end
canonicalBaselineWorkbook = canonical_baseline_workbook_path(repoRoot);

%% Stage 3 -- Baseline validation target
fprintf('\n--- Stage 3: baseline target workbook ---\n');
fprintf('  Baseline build writes directly to canonical workbook:\n    %s\n', canonicalBaselineWorkbook);

%% Stage 4 -- Scenario sheets
fprintf('\n--- Stage 4: scenario sheets (groups={%s}) ---\n', strjoin(cfg.scenarioGroups, ','));
if ~skipRebuildStages && ismember('Reference', cfg.scenarioGroups)
    % update_nz_sheet.m writes the NZ sheet directly into the canonical
    % scenario workbook (hardcoded path, no replication/staging variant) and
    % has no backup logic of its own -- back it up first.
    backup_workbook(fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions.xlsx'));
    run(fullfile(repoRoot, 'scripts', 'maintenance', 'update_nz_sheet.m'));
    repoRoot = get_repo_root();
    cd(repoRoot);
    setup_paths();
    cfg = load_cfg();
end
if ~skipRebuildStages && ismember('EE', cfg.scenarioGroups)
    error('build_all_workbooks:NotImplemented', ...
        ['EE scenario group is not wired up yet. Run ' ...
         'scripts/maintenance/create_ee_scenarios_from_expert_inputs.m manually, or extend ' ...
         'Stage 4''s dispatch to add it.']);
end
if ~skipRebuildStages && any(ismember({'GF_PDP8', 'GF_NZ'}, cfg.scenarioGroups))
    error('build_all_workbooks:NotImplemented', ...
        ['Green-finance scenario groups are not wired up yet. Run ' ...
         'scripts/maintenance/create_green_finance_scenarios.m manually, or extend ' ...
         'Stage 4''s dispatch to add them.']);
end
if ~skipRebuildStages && ismember('NZ_Sensitivity', cfg.scenarioGroups)
    error('build_all_workbooks:NotImplemented', ...
        ['NZ_Sensitivity scenario group has no dedicated builder wired up yet -- extend ' ...
         'Stage 4''s dispatch to add it.']);
end

%% Stage 5 -- Post-build structural validation
fprintf('\n--- Stage 5: post-build validation ---\n');

canonicalBaselineWorkbook = canonical_baseline_workbook_path(repoRoot);
validate_baseline_sheet(canonicalBaselineWorkbook, 'Baseline');
if ismember('Reference', cfg.scenarioGroups)
    validate_nz_sheet(fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions.xlsx'), 'NZ');
end
fprintf('  All structural checks passed.\n');

%% Stage 6 -- Summary
fprintf('\n=== build_all_workbooks complete ===\n');
fprintf('  Build mode:              %s (PDP8 investment targets: %d)\n', ...
    cfg.buildMode, cfg.usePDP8InvestmentTargets);
fprintf('  Canonical baseline:      %s\n', canonicalBaselineWorkbook);
fprintf('  Seed canonical from *_replication_fix (default): %d\n', cfg.seedCanonicalFromReplicationFix);
fprintf('  Scenario groups built:   %s\n', strjoin(cfg.scenarioGroups, ', '));
fprintf(['\n  This script only builds workbooks. To actually run the model against them:\n' ...
         '    set DGE_SCENARIO_GROUPS=Reference\n' ...
         '    matlab -batch "RunSimulations"\n' ...
         '\n' ...
         '  Building a scenario''s Excel sheet does not make it run -- per ' ...
         'docs/reference/running.md, RunSimulations.m only simulates a scenario name that is BOTH ' ...
         '(a) uncommented inside its scenarioGroups.<name> block in RunSimulations.m and (b) in the ' ...
         'active group set (activeScenarioGroups, or DGE_SCENARIO_GROUPS). Check ' ...
         'casScenarioNames in MATLAB before trusting a run.\n' ...
         '\n' ...
         '  RunSimulations.m has TWO separate investment-target mechanisms this script does not ' ...
         'touch and that already degrade gracefully for a quick check run:\n' ...
         '    1) The GSO-based initial-period reshuffle (sInvestmentTargetsCsv / ' ...
         'sInvestmentTargetsIoTableXlsx, lReshuffleInitial_p) -- skips itself with a warning when ' ...
         'those personal-path files are not found.\n' ...
         '    2) The PDP8 fossil/renewable I/K reconciliation (lReshuffleIK_p=1 by default, via ' ...
         'compute_pdp8_capital_investment_ratio.m) -- applies manualScaleIK2_p/manualScaleIK3_p ' ...
         'multipliers that default to 0.72/0.65 in simulation_model_refactored.m if not overridden. ' ...
         'See docs/scenario_notes/reshuffle_initial_period_procedure.md for the full mechanism; set ' ...
         'lReshuffleIK_p=0 in RunSimulations.m if you want a run with no PDP8 IK reconciliation at ' ...
         'all, not just neutral scaling.\n']);

%% Local helper functions
% Defined here (script-local functions, R2016b+) so they remain callable
% after any run()-inside-this-script call to a script that clearvars its way
% through the shared workspace -- function definitions are not variables and
% are unaffected by clearvars.

function repoRoot = get_repo_root()
repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end

function cfg = load_cfg()
cfg = struct();

cfg.buildMode = 'quickcheck';
envBuildMode = strtrim(getenv('DGE_BUILD_MODE'));
if ~isempty(envBuildMode)
    cfg.buildMode = envBuildMode;
end
switch lower(cfg.buildMode)
    case 'quickcheck'
        cfg.usePDP8InvestmentTargets = false;
    case 'full'
        cfg.usePDP8InvestmentTargets = true;
    otherwise
        error('build_all_workbooks:InvalidBuildMode', ...
            'Unknown build mode "%s" (DGE_BUILD_MODE). Use "quickcheck" or "full".', cfg.buildMode);
end

cfg.scenarioGroups = {'Reference'};
envScenarioGroups = strtrim(getenv('DGE_BUILD_SCENARIO_GROUPS'));
if ~isempty(envScenarioGroups)
    cfg.scenarioGroups = strtrim(strsplit(envScenarioGroups, ','));
end

cfg.seedCanonicalFromReplicationFix = true;
envSeedCanonical = strtrim(getenv('DGE_SEED_CANONICAL_FROM_REPLICATION_FIX'));
if ~isempty(envSeedCanonical)
    cfg.seedCanonicalFromReplicationFix = logical(str2double(envSeedCanonical));
end
end

function p = calibration_workbook_path(repoRoot)
p = fullfile(repoRoot, 'ExcelFiles', 'ModelCalibration5Sectorsand1Regions.xlsx');
end

function p = canonical_baseline_workbook_path(repoRoot)
p = fullfile(repoRoot, 'ExcelFiles', 'ModelBaseline5Sectorsand1Regions.xlsx');
end

function seedInfo = ensure_workbook_shells(repoRoot)
calibrationWorkbook = calibration_workbook_path(repoRoot);
baselineWorkbook = canonical_baseline_workbook_path(repoRoot);
scenariosWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions.xlsx');
replicationCalibrationWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelCalibration5Sectorsand1Regions_replication.xlsx');
replicationFixCalibrationWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelCalibration5Sectorsand1Regions_replication_fix.xlsx');
replicationBaselineWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelBaseline5Sectorsand1Regions_replication.xlsx');
replicationFixBaselineWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelBaseline5Sectorsand1Regions_replication_fix.xlsx');
replicationScenariosWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions_replication.xlsx');
replicationFixScenariosWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions_replication_fix.xlsx');

seedInfo = struct('calibrationFromReplicationFix', false, ...
    'baselineFromReplicationFix', false, 'scenariosFromReplicationFix', false, ...
    'allFromReplicationFix', false);

if ~isfile(calibrationWorkbook)
    if isfile(replicationFixCalibrationWorkbook)
        fprintf('  Missing calibration workbook; cloning current replication_fix workbook into canonical path.\n');
        copyfile(replicationFixCalibrationWorkbook, calibrationWorkbook);
        seedInfo.calibrationFromReplicationFix = true;
    elseif isfile(replicationCalibrationWorkbook)
        fprintf('  Missing calibration workbook; cloning current replication workbook into canonical path.\n');
        copyfile(replicationCalibrationWorkbook, calibrationWorkbook);
    else
        fprintf('  Missing calibration workbook; creating %s\n', calibrationWorkbook);
        run(fullfile(repoRoot, 'Functions', 'Miscellaneous', 'Excel', 'create_calibration_excel_file.m'));
    end
end
if ~isfile(baselineWorkbook)
    if isfile(replicationFixBaselineWorkbook)
        fprintf('  Missing baseline workbook; cloning current replication_fix workbook into canonical path.\n');
        copyfile(replicationFixBaselineWorkbook, baselineWorkbook);
        seedInfo.baselineFromReplicationFix = true;
    elseif isfile(replicationBaselineWorkbook)
        fprintf('  Missing baseline workbook; cloning current replication workbook into canonical path.\n');
        copyfile(replicationBaselineWorkbook, baselineWorkbook);
    else
        fprintf('  Missing baseline workbook; creating %s\n', baselineWorkbook);
        run(fullfile(repoRoot, 'Functions', 'Miscellaneous', 'Excel', 'create_baseline_excel_file.m'));
    end
end
if ~isfile(scenariosWorkbook)
    if isfile(replicationFixScenariosWorkbook)
        fprintf('  Missing scenarios workbook; cloning current replication_fix workbook into canonical path.\n');
        copyfile(replicationFixScenariosWorkbook, scenariosWorkbook);
        seedInfo.scenariosFromReplicationFix = true;
    elseif isfile(replicationScenariosWorkbook)
        fprintf('  Missing scenarios workbook; cloning current replication workbook into canonical path.\n');
        copyfile(replicationScenariosWorkbook, scenariosWorkbook);
    else
        fprintf('  Missing scenarios workbook; creating %s\n', scenariosWorkbook);
        run(fullfile(repoRoot, 'Functions', 'Miscellaneous', 'Excel', 'create_scenarios_excel_file.m'));
    end
end

seedInfo.allFromReplicationFix = seedInfo.calibrationFromReplicationFix && ...
    seedInfo.baselineFromReplicationFix && seedInfo.scenariosFromReplicationFix;
end

function backupPath = backup_workbook(workbookPath)
% Copies workbookPath to a timestamped sibling before an in-place overwrite.
% Several maintenance scripts (update_data_excel.m, update_nz_sheet.m) write
% their target workbook directly with no backup of their own -- this is the
% only safety net between a build and losing whatever was previously in that
% file (git history is the fallback beyond that, if the prior state was
% committed).
if ~isfile(workbookPath)
    error('build_all_workbooks:BackupSourceMissing', ...
        'Cannot back up "%s": file not found.', workbookPath);
end
[dirPath, baseName, ext] = fileparts(workbookPath);
backupPath = fullfile(dirPath, sprintf('%s_backup_%s%s', baseName, ...
    string(datetime('now'), 'yyyyMMdd_HHmmss'), ext));
copyfile(workbookPath, backupPath);
fprintf('  Backed up %s\n    -> %s\n', workbookPath, backupPath);
end

% validate_baseline_sheet and validate_nz_sheet used to be local functions
% here; they now live in Functions/Miscellaneous/Excel/ (on the path via
% setup_paths()) so RunSimulationsEasy.m can reuse the exact same checks.
