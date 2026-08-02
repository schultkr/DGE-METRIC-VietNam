% run_sensitivity_analysis
%
% Purpose:
%   Run sensitivity analyses by changing calibration parameters in code,
%   executing RunSimulations.m for each parameter case, and storing all
%   changed outputs in separate folders.
%
% Run from repository root:
%   run('scripts/maintenance/run_sensitivity_analysis.m')

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

%% Configuration

cfg = struct();
cfg.calibrationWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelCalibration5Sectorsand1Regions.xlsx');
cfg.parameterSheets = {'Start', 'Structural Parameters'};
cfg.runUpdateDataExcel = false;
cfg.allowMissingParameters = false;

% Optional overrides for scenario selection in RunSimulations.m.
cfg.scenarioGroupsCsv = 'Reference';
cfg.baselineSheetsCsv = 'Baseline';

% Root output folder for sensitivity batches.
cfg.outputRoot = fullfile(repoRoot, 'ExcelFiles', 'Output', 'SensitivityRuns');

% Define parameter cases here.
% Each case has:
%   - name: folder-friendly label
%   - overrides: struct of parameter-name -> value
cases = [ ...
    struct('name', 'deltaFossil_low', 'overrides', struct('delta_2_1_p', 0.040));
    struct('name', 'deltaFossil_high', 'overrides', struct('delta_2_1_p', 0.080));
    struct('name', 'etaKS_low', 'overrides', struct('etaKS_p', 0.500));
    struct('name', 'etaKS_high', 'overrides', struct('etaKS_p', 1.500))
    ];

if isempty(cases)
    error('run_sensitivity_analysis:NoCases', 'No sensitivity cases configured.');
end
if ~isfile(cfg.calibrationWorkbook)
    error('run_sensitivity_analysis:MissingCalibrationWorkbook', ...
        'Calibration workbook not found: %s', cfg.calibrationWorkbook);
end

runTag = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
batchDir = fullfile(cfg.outputRoot, ['Sensitivity_' runTag]);
ensure_dir(batchDir);

backupWorkbook = [tempname '.xlsx'];
copyfile(cfg.calibrationWorkbook, backupWorkbook);
restoreWorkbookCleanup = onCleanup(@() restore_workbook(cfg.calibrationWorkbook, backupWorkbook)); %#ok<NASGU>

oldScenarioGroups = getenv('DGE_SCENARIO_GROUPS');
oldBaselineSheets = getenv('DGE_BASELINE_SHEETS');
restoreEnvCleanup = onCleanup(@() restore_env(oldScenarioGroups, oldBaselineSheets)); %#ok<NASGU>

if ~isempty(strtrim(cfg.scenarioGroupsCsv))
    setenv('DGE_SCENARIO_GROUPS', cfg.scenarioGroupsCsv);
end
if ~isempty(strtrim(cfg.baselineSheetsCsv))
    setenv('DGE_BASELINE_SHEETS', cfg.baselineSheetsCsv);
end

summary = repmat(struct( ...
    'CaseName', '', ...
    'Status', '', ...
    'Message', '', ...
    'DurationMinutes', NaN, ...
    'OutputFolder', '', ...
    'ChangedCsvCount', 0, ...
    'ChangedMatCount', 0), numel(cases), 1);

fprintf('\nRunning sensitivity batch: %s\n', batchDir);
fprintf('Cases: %d\n', numel(cases));

for iCase = 1:numel(cases)
    c = cases(iCase);
    caseName = sanitize_name(c.name);
    caseDir = fullfile(batchDir, sprintf('%02d_%s', iCase, caseName));
    ensure_dir(caseDir);
    ensure_dir(fullfile(caseDir, 'ExcelOutput'));
    ensure_dir(fullfile(caseDir, 'WorkspaceOutput'));

    tCase = tic;
    summary(iCase).CaseName = c.name;
    summary(iCase).OutputFolder = caseDir;

    fprintf('\n[%d/%d] Case %s\n', iCase, numel(cases), c.name);

    try
        % Reset workbook for independent runs.
        copyfile(backupWorkbook, cfg.calibrationWorkbook, 'f');

        applied = apply_parameter_overrides(cfg.calibrationWorkbook, c.overrides, ...
            cfg.parameterSheets, cfg.allowMissingParameters);

        if cfg.runUpdateDataExcel
            run('Functions/Miscellaneous/Excel/update_data_excel.m');
        end

        overridesFile = fullfile(caseDir, 'AppliedOverrides.csv');
        writetable(applied, overridesFile);
        copyfile(cfg.calibrationWorkbook, fullfile(caseDir, 'ModelCalibration_used.xlsx'));

        runStart = now;
        diaryPath = fullfile(caseDir, 'RunSimulations.log');
        diary(diaryPath);
        run('RunSimulations.m');
        diary off;

        copiedCsv = copy_changed_files( ...
            fullfile(repoRoot, 'ExcelFiles', 'Output'), '*.csv', ...
            fullfile(caseDir, 'ExcelOutput'), runStart);

        copiedMat = copy_changed_files( ...
            repoRoot, 'structScenarioResults*.mat', ...
            fullfile(caseDir, 'WorkspaceOutput'), runStart);

        copy_changed_files( ...
            repoRoot, 'DGE_Model.log', ...
            fullfile(caseDir, 'WorkspaceOutput'), runStart);

        summary(iCase).Status = 'ok';
        summary(iCase).Message = 'Completed';
        summary(iCase).ChangedCsvCount = numel(copiedCsv);
        summary(iCase).ChangedMatCount = numel(copiedMat);
    catch ME
        if strcmp(get(0, 'Diary'), 'on')
            diary off;
        end
        summary(iCase).Status = 'failed';
        summary(iCase).Message = ME.message;
    end

    summary(iCase).DurationMinutes = toc(tCase) / 60;
end

summaryTable = struct2table(summary, 'AsArray', true);
summaryPath = fullfile(batchDir, 'SensitivitySummary.csv');
writetable(summaryTable, summaryPath);

fprintf('\nSensitivity batch finished.\n');
fprintf('Summary: %s\n', summaryPath);

%% Local functions

function restore_workbook(calibrationWorkbook, backupWorkbook)
    if isfile(backupWorkbook)
        copyfile(backupWorkbook, calibrationWorkbook, 'f');
        delete(backupWorkbook);
    end
end

function restore_env(oldScenarioGroups, oldBaselineSheets)
    setenv('DGE_SCENARIO_GROUPS', oldScenarioGroups);
    setenv('DGE_BASELINE_SHEETS', oldBaselineSheets);
end

function ensure_dir(p)
    if ~exist(p, 'dir')
        mkdir(p);
    end
end

function applied = apply_parameter_overrides(workbookPath, overrides, sheetNames, allowMissing)
    paramNames = fieldnames(overrides);
    applied = table('Size', [0 4], ...
        'VariableTypes', {'string', 'string', 'double', 'double'}, ...
        'VariableNames', {'Parameter', 'Sheet', 'OldValue', 'NewValue'});

    foundAny = false(numel(paramNames), 1);
    for iParam = 1:numel(paramNames)
        pName = paramNames{iParam};
        pValue = overrides.(pName);
        if ~(isnumeric(pValue) && isscalar(pValue) && isfinite(pValue))
            error('run_sensitivity_analysis:InvalidOverrideValue', ...
                'Override value for %s must be a finite numeric scalar.', pName);
        end

        for iSheet = 1:numel(sheetNames)
            sheetName = sheetNames{iSheet};
            [found, oldValue] = try_write_param_value(workbookPath, sheetName, pName, pValue);
            if found
                foundAny(iParam) = true;
                applied = [applied; {string(pName), string(sheetName), oldValue, pValue}]; %#ok<AGROW>
            end
        end

        if ~foundAny(iParam) && ~allowMissing
            error('run_sensitivity_analysis:ParameterNotFound', ...
                'Parameter %s was not found in sheets: %s', pName, strjoin(sheetNames, ', '));
        end
    end
end

function [found, oldValue] = try_write_param_value(workbookPath, sheetName, paramName, newValue)
    found = false;
    oldValue = NaN;

    raw = readcell(workbookPath, 'Sheet', sheetName);
    if isempty(raw)
        return
    end

    [headerRow, paramCol, valueCol] = find_parameter_headers(raw);
    if isnan(headerRow)
        return
    end

    nRows = size(raw, 1);
    for r = (headerRow + 1):nRows
        cellParam = raw{r, paramCol};
        if isstring(cellParam) || ischar(cellParam)
            thisName = strtrim(string(cellParam));
            if strcmp(thisName, string(paramName))
                oldValue = to_double(raw{r, valueCol});
                addr = [excel_col_name(valueCol) num2str(r)];
                writecell({newValue}, workbookPath, 'Sheet', sheetName, 'Range', addr);
                found = true;
                return
            end
        end
    end
end

function [headerRow, paramCol, valueCol] = find_parameter_headers(raw)
    headerRow = NaN;
    paramCol = NaN;
    valueCol = NaN;

    maxHeaderRow = min(20, size(raw, 1));
    for r = 1:maxHeaderRow
        rowVals = raw(r, :);
        labels = strings(1, numel(rowVals));
        for c = 1:numel(rowVals)
            v = rowVals{c};
            if isstring(v) || ischar(v)
                labels(c) = lower(strtrim(string(v)));
            else
                labels(c) = "";
            end
        end

        pIdx = find(labels == "parameter", 1, 'first');
        vIdx = find(labels == "value", 1, 'first');
        if ~isempty(pIdx) && ~isempty(vIdx)
            headerRow = r;
            paramCol = pIdx;
            valueCol = vIdx;
            return
        end
    end
end

function out = copy_changed_files(sourceDir, filePattern, targetDir, startDatenum)
    out = strings(0, 1);
    listing = dir(fullfile(sourceDir, filePattern));
    if isempty(listing)
        return
    end

    ensure_dir(targetDir);
    tEps = 2 / 86400; % 2 seconds
    for i = 1:numel(listing)
        if listing(i).isdir
            continue
        end
        if listing(i).datenum + tEps < startDatenum
            continue
        end
        src = fullfile(sourceDir, listing(i).name);
        dst = fullfile(targetDir, listing(i).name);
        copyfile(src, dst, 'f');
        out(end + 1, 1) = string(dst); %#ok<AGROW>
    end
end

function s = sanitize_name(nameIn)
    s = regexprep(char(string(nameIn)), '[^A-Za-z0-9_-]', '_');
    s = regexprep(s, '_+', '_');
    s = strtrim(s);
    if isempty(s)
        s = 'case';
    end
end

function col = excel_col_name(idx)
    col = '';
    while idx > 0
        remIdx = mod(idx - 1, 26);
        col = [char(65 + remIdx) col]; %#ok<AGROW>
        idx = floor((idx - 1) / 26);
    end
end

function x = to_double(v)
    if isnumeric(v)
        x = double(v);
    elseif isstring(v) || ischar(v)
        x = str2double(string(v));
    else
        x = NaN;
    end
end