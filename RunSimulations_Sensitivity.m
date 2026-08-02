% RunSimulations_Sensitivity
%
% Minimal sensitivity runner based on RunSimulations.m.
% It runs the model once per parameter case and stores each run's outputs
% in a dedicated folder whose name encodes the parameter changes.
%
% Usage:
%   run('RunSimulations_Sensitivity.m')

repoRoot = fileparts(which('RunSimulations_Sensitivity.m'));
if isempty(repoRoot)
    repoRoot = pwd;
end
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

% Workbook to edit for calibration parameter changes.
calibrationWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelCalibration5Sectorsand1Regions.xlsx');
parameterSheets = {'Start', 'Structural Parameters'};

if ~isfile(calibrationWorkbook)
    error('RunSimulations_Sensitivity:MissingCalibrationWorkbook', ...
        'Calibration workbook not found: %s', calibrationWorkbook);
end

% Backup workbook so each case starts from the same base values.
backupWorkbook = [tempname '.xlsx'];
copy_replace(calibrationWorkbook, backupWorkbook);
cleanupWorkbook = onCleanup(@() restore_calibration(calibrationWorkbook, backupWorkbook)); %#ok<NASGU>

% Optional: force a fixed scenario group selection in each run.
% Keep empty '' to use the selection hardcoded in RunSimulations.m.
scenarioGroupsCsv = '';

% Define sensitivity cases here.
% Each case has a struct of parameter overrides and an optional custom label.
% Parameter names/descriptions below are copied from the "Structural
% Parameters" sheet of ExcelFiles/ModelCalibration5Sectorsand1Regions.xlsx.
cases = [ ...
    % etaIA_x_p: elasticity of substitution between intermediate inputs
    % within a sector (all 5 sectors) -- default 0.1, near-Leontief. Low
    % value = intermediates are close to fixed proportions; high value =
    % production can reshuffle intermediate-input mix more freely.
    struct('label', 'etaIA2_low',       'overrides', struct('etaIA_1_p', 0.05,...
                                                            'etaIA_2_p', 0.05,...
                                                            'etaIA_3_p', 0.05,...
                                                            'etaIA_4_p', 0.05,...
                                                            'etaIA_5_p', 0.05));
    struct('label', 'etaIA2_high',      'overrides', struct('etaIA_1_p', 0.3,...
                                                            'etaIA_2_p', 0.3,...
                                                            'etaIA_3_p', 0.3,...
                                                            'etaIA_4_p', 0.3,...
                                                            'etaIA_5_p', 0.3));
    % etaQA_2_p: elasticity of substitution between subsectors within the
    % Energy sector (Fossil vs Renewables), default 5. This is the main
    % fuel-switching lever -- how easily output shifts from Fossil to
    % Renewables in response to relative prices (e.g. a carbon price).
    struct('label', 'etaQA2_low',       'overrides', struct('etaQA_2_p', 2.5));
    struct('label', 'etaQA2_high',      'overrides', struct('etaQA_2_p', 10));
    % delta_2_1_p: capital depreciation rate, Fossil subsector, region 1,
    % default 0.05. Governs how fast fossil capacity naturally retires
    % (stranded-asset speed) absent any policy-forced phase-out.
    struct('label', 'deltaFossil_fast', 'overrides', struct('delta_2_1_p', 0.08));
    struct('label', 'deltaFossil_slow', 'overrides', struct('delta_2_1_p', 0.03));
    % etaNK_x_1_p: elasticity of substitution between labour and capital,
    % Fossil (2) and Renewables (3) subsectors, region 1, default 1. Governs
    % how much capital/labour intensity responds to relative factor costs
    % (e.g. capital subsidies for renewables).
    struct('label', 'etaNK_low',        'overrides', struct('etaNK_2_1_p', 0.5, 'etaNK_3_1_p', 0.5));
    struct('label', 'etaNK_high',       'overrides', struct('etaNK_2_1_p', 2,   'etaNK_3_1_p', 2));
    % beta_p: household discount factor, default 0.97. Governs how
    % forward-looking investment/consumption decisions are -- lower beta
    % (more impatient) discounts future transition benefits more heavily.
    struct('label', 'beta_low',         'overrides', struct('beta_p', 0.94));
    struct('label', 'beta_high',        'overrides', struct('beta_p', 0.99));
    % etaQ_p: elasticity of substitution between the four aggregate sectors
    % (Primary/Energy/Secondary/Tertiary), default 0.6. Governs how far the
    % whole economy can reshuffle output composition, not just within Energy.
    % struct('label', 'etaQ_low',         'overrides', struct('etaQ_p', 0.5));
    struct('label', 'etaQ_high',        'overrides', struct('etaQ_p', 0.7));
    % etaI_2_p: elasticity of substitution between primary factors
    % (capital/labour) and intermediate inputs, Energy sector, default 1.
    % Governs indirect fuel-switching -- e.g. substituting intermediates for
    % capital/labour within Energy production.
    struct('label', 'etaI2_low',        'overrides', struct('etaI_2_p', 0.9));
    struct('label', 'etaI2_high',       'overrides', struct('etaI_2_p', 1.1));
    % sigmaL_p: inverse Frisch elasticity of labour supply, default 1.
    % Lower value = labour supply more responsive to wages (elastic); higher
    % value = labour supply more rigid (inelastic) -- relevant to how easily
    % labour reallocates between fossil and renewables employment.
    struct('label', 'sigmaL_low',       'overrides', struct('sigmaL_p', 0.5));
    struct('label', 'sigmaL_high',      'overrides', struct('sigmaL_p', 2.0));
    % phiB_p / phiadjB_p: foreign bond adjustment costs, default 0.1 each.
    % Govern how costly it is for the current account to adjust when the
    % economy borrows abroad -- relevant to financing a fast renewables
    % buildout via foreign capital.
    struct('label', 'phiB_low',         'overrides', struct('phiB_p', 0.05));
    struct('label', 'phiB_high',        'overrides', struct('phiB_p', 0.3));
    struct('label', 'phiadjB_low',      'overrides', struct('phiadjB_p', 0.05));
    struct('label', 'phiadjB_high',     'overrides', struct('phiadjB_p', 0.3));
    ];

if isempty(cases)
    error('RunSimulations_Sensitivity:NoCases', 'No sensitivity cases configured.');
end

timestampTag = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
batchRoot = fullfile('SensitivityRuns', ['Batch_' timestampTag]);
summary = repmat(struct( ...
    'CaseLabel', '', ...
    'OutputSubfolder', '', ...
    'Status', '', ...
    'Message', '', ...
    'DurationMinutes', NaN), numel(cases), 1);

oldScenarioGroups = getenv('DGE_SCENARIO_GROUPS');
cleanupEnv = onCleanup(@() setenv('DGE_SCENARIO_GROUPS', oldScenarioGroups)); %#ok<NASGU>
oldOutputSubfolderEnv = getenv('DGE_OUTPUT_SUBFOLDER');
cleanupOutputEnv = onCleanup(@() setenv('DGE_OUTPUT_SUBFOLDER', oldOutputSubfolderEnv)); %#ok<NASGU>

hWait = waitbar(0, 'Starting sensitivity runs...', 'Name', 'RunSimulations_Sensitivity');
cleanupWaitbar = onCleanup(@() close_waitbar(hWait)); %#ok<NASGU>

for iCase = 1:numel(cases)
    tRun = tic;

    % Reset workbook to baseline before applying this case.
    copy_replace(backupWorkbook, calibrationWorkbook);

    overrides = cases(iCase).overrides;
    validate_overrides(overrides);
    caseLabel = cases(iCase).label;
    if isempty(caseLabel)
        caseLabel = build_case_label(overrides);
    end

    % Apply parameter values to calibration workbook.
    apply_overrides_to_workbook(calibrationWorkbook, parameterSheets, overrides);

    % Optional scenario-group override.
    if ~isempty(strtrim(scenarioGroupsCsv))
        setenv('DGE_SCENARIO_GROUPS', scenarioGroupsCsv);
    else
        setenv('DGE_SCENARIO_GROUPS', oldScenarioGroups);
    end

    % Redirect output to a case-specific subfolder.
    sOutputSubfolder = fullfile(batchRoot, sprintf('%02d_%s', iCase, sanitize_label(caseLabel))); %#ok<NASGU>
    setenv('DGE_OUTPUT_SUBFOLDER', sOutputSubfolder);

    summary(iCase).CaseLabel = caseLabel;
    summary(iCase).OutputSubfolder = sOutputSubfolder;

    fprintf('\n[%d/%d] Running sensitivity case: %s\n', iCase, numel(cases), caseLabel);
    fprintf('Output folder: ExcelFiles/Output/%s\n', sOutputSubfolder);

    update_waitbar(hWait, iCase - 1, numel(cases), caseLabel);

    try
        run('RunSimulations.m');

        % Also copy MAT summary files into the same run folder.
        outAbs = fullfile(repoRoot, 'ExcelFiles', 'Output', sOutputSubfolder);
        if ~exist(outAbs, 'dir')
            mkdir(outAbs);
        end
        copy_struct_results(repoRoot, outAbs);
        copy_calibration_snapshot(calibrationWorkbook, outAbs);

        summary(iCase).Status = 'ok';
        summary(iCase).Message = 'Completed';
    catch ME
        summary(iCase).Status = 'failed';
        summary(iCase).Message = getReport(ME, 'basic', 'hyperlinks', 'off');
    end

    summary(iCase).DurationMinutes = toc(tRun) / 60;

    update_waitbar(hWait, iCase, numel(cases), caseLabel);

    % Close any Excel COM processes left open by readcell/writecell/RunSimulations
    % before the next iteration overwrites the calibration workbook, otherwise
    % the file can remain locked and copy_replace/copyfile will fail.
    close_excel_processes();
end

close_waitbar(hWait);

summaryTable = struct2table(summary, 'AsArray', true);
summaryPath = fullfile(repoRoot, 'ExcelFiles', 'Output', batchRoot, 'SensitivitySummary.csv');
ensure_dir(fileparts(summaryPath));
writetable(summaryTable, summaryPath);

fprintf('\nSensitivity run complete.\nSummary: %s\n', summaryPath);

%% Local functions

function restore_calibration(workbookPath, backupPath)
    if isfile(backupPath)
        copy_replace(backupPath, workbookPath);
        delete(backupPath);
    end
end

function validate_overrides(overrides)
    names = fieldnames(overrides);
    if isempty(names)
        error('RunSimulations_Sensitivity:EmptyOverrides', ...
            'Each case must define at least one parameter override.');
    end
    for i = 1:numel(names)
        v = overrides.(names{i});
        if ~(isnumeric(v) && isscalar(v) && isfinite(v))
            error('RunSimulations_Sensitivity:InvalidOverrideValue', ...
                'Override for %s must be a finite numeric scalar.', names{i});
        end
    end
end

function apply_overrides_to_workbook(workbookPath, sheetNames, overrides)
    names = fieldnames(overrides);
    for iName = 1:numel(names)
        pName = names{iName};
        pVal = overrides.(pName);
        found = false;

        for iSheet = 1:numel(sheetNames)
            sheetName = sheetNames{iSheet};
            if write_param_if_present(workbookPath, sheetName, pName, pVal)
                found = true;
            end
        end

        if ~found
            error('RunSimulations_Sensitivity:ParameterNotFound', ...
                'Parameter %s not found in sheets: %s', pName, strjoin(sheetNames, ', '));
        end
    end
end

function tf = write_param_if_present(workbookPath, sheetName, paramName, paramValue)
    tf = false;
    raw = readcell(workbookPath, 'Sheet', sheetName);
    if isempty(raw)
        return
    end

    [headerRow, paramCol, valueCol] = find_header_cols(raw);
    if ~isnan(headerRow)
        for r = (headerRow + 1):size(raw, 1)
            c = raw{r, paramCol};
            if ischar(c) || isstring(c)
                if strcmp(strtrim(string(c)), string(paramName))
                    addr = [excel_col(valueCol) num2str(r)];
                    writecell({paramValue}, workbookPath, 'Sheet', sheetName, 'Range', addr);
                    tf = true;
                    return
                end
            end
        end
    end

    % Fallback: search full sheet for exact parameter name and write to the
    % cell to the immediate right (common two-column parameter/value layout).
    for r = 1:size(raw, 1)
        for c = 1:size(raw, 2)
            item = raw{r, c};
            if ~(ischar(item) || isstring(item))
                continue
            end
            if strcmp(strtrim(string(item)), string(paramName))
                writeCol = c + 1;
                addr = [excel_col(writeCol) num2str(r)];
                writecell({paramValue}, workbookPath, 'Sheet', sheetName, 'Range', addr);
                tf = true;
                return
            end
        end
    end
end

function [headerRow, paramCol, valueCol] = find_header_cols(raw)
    headerRow = NaN;
    paramCol = NaN;
    valueCol = NaN;
    for r = 1:min(20, size(raw, 1))
        p = NaN;
        v = NaN;
        for c = 1:size(raw, 2)
            item = raw{r, c};
            if ~(ischar(item) || isstring(item))
                continue
            end
            label = lower(strtrim(string(item)));
            if strcmp(label, "parameter")
                p = c;
            elseif strcmp(label, "value")
                v = c;
            end
        end
        if isfinite(p) && isfinite(v)
            headerRow = r;
            paramCol = p;
            valueCol = v;
            return
        end
    end
end

function s = build_case_label(overrides)
    names = sort(fieldnames(overrides));
    parts = cell(1, numel(names));
    for i = 1:numel(names)
        pname = names{i};
        pval = overrides.(pname);
        valText = num2str(pval, '%.6g');
        valText = strrep(valText, '-', 'm');
        valText = strrep(valText, '.', 'p');
        parts{i} = [pname '_' valText];
    end
    s = strjoin(parts, '__');
end

function s = sanitize_label(s)
    s = regexprep(char(string(s)), '[^A-Za-z0-9_-]', '_');
    s = regexprep(s, '_+', '_');
    if isempty(s)
        s = 'case';
    end
end

function copy_struct_results(repoRoot, outputDir)
    files = dir(fullfile(repoRoot, 'structScenarioResults*.mat'));
    for i = 1:numel(files)
        copy_replace(fullfile(repoRoot, files(i).name), fullfile(outputDir, files(i).name));
    end
end

function copy_calibration_snapshot(workbookPath, outputDir)
    copy_replace(workbookPath, fullfile(outputDir, 'ModelCalibration_used.xlsx'));
end

function ensure_dir(pathStr)
    if ~exist(pathStr, 'dir')
        mkdir(pathStr);
    end
end

function out = excel_col(idx)
    out = '';
    while idx > 0
        r = mod(idx - 1, 26);
        out = [char(65 + r) out]; %#ok<AGROW>
        idx = floor((idx - 1) / 26);
    end
end

function update_waitbar(hWait, nDone, nTotal, caseLabel)
    if isempty(hWait) || ~isvalid(hWait)
        return
    end
    frac = nDone / nTotal;
    msg = sprintf('Case %d/%d: %s', nDone, nTotal, strrep(caseLabel, '_', '\_'));
    waitbar(frac, hWait, msg);
end

function close_waitbar(hWait)
    if ~isempty(hWait) && isvalid(hWait)
        close(hWait);
    end
end

function copy_replace(src, dst)
    if isfile(dst)
        delete(dst);
    end
    copyfile(src, dst);
end

function close_excel_processes()
    % Gracefully quit any Excel COM server MATLAB is still attached to
    % (left over from readcell/writecell calls), then force-kill any
    % remaining EXCEL.EXE processes so the workbook isn't file-locked
    % going into the next sensitivity case.
    try
        excelApp = actxGetRunningServer('Excel.Application');
        excelApp.DisplayAlerts = false;
        excelApp.Quit();
        delete(excelApp);
    catch
        % No running COM server attached; nothing to close gracefully.
    end

    if ispc
        try
            [~, ~] = system('taskkill /IM EXCEL.EXE /F /T');
        catch
            % No EXCEL.EXE process found, or taskkill unavailable; ignore.
        end
    end
end