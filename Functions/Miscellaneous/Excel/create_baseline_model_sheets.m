function summary = create_baseline_model_sheets(varargin)
% create_baseline_model_sheets  Keep only Baseline + Content workbook sheets.
%
% This helper enforces a minimal workbook layout with exactly two sheets:
%   Content | Baseline
% It removes all other sheets from the workbook.
%
% Usage from the repository root:
%   addpath(genpath('Functions'))
%   create_baseline_model_sheets()
%
% Optional name/value pairs:
%   'Workbook'     char, default ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx
%   'SourceSheet'  char, default 'Baseline'
%   'Variants'     struct array, see default_variants() below
%   'Visible'      logical, default false

cfg = parse_config(varargin{:});

if ~ispc
    error('create_baseline_model_sheets:WindowsRequired', ...
        'This helper uses Excel ActiveX and must be run on Windows with Excel installed.');
end

if ~isfile(cfg.workbook)
    error('create_baseline_model_sheets:WorkbookNotFound', ...
        'Workbook not found:\n  %s', cfg.workbook);
end

assert_file_writable(cfg.workbook);

exl = [];
wb = [];

try
    exl = actxserver('excel.application');
    set(exl, 'AskToUpdateLinks', 0);
    set(exl, 'DisplayAlerts', false);
    exl.Visible = cfg.visible;

    wb = open_workbook_safe(exl, cfg.workbook);
    wsSource = get_sheet(wb, cfg.sourceSheet);
    sourceUsed = wsSource.UsedRange;

    if sourceUsed.Row ~= 1 || sourceUsed.Column ~= 1
        error('create_baseline_model_sheets:UnexpectedSourceRange', ...
            'Expected "%s" used range to start at A1.', cfg.sourceSheet);
    end

    nRows = sourceUsed.Rows.Count;
    nCols = sourceUsed.Columns.Count;
    if nRows < 2
        error('create_baseline_model_sheets:EmptySourceSheet', ...
            'Source sheet "%s" does not contain any data rows.', cfg.sourceSheet);
    end

    headers = read_header_row(wsSource, nCols);
    if isempty(headers) || ~strcmp(headers{1}, 'Time')
        error('create_baseline_model_sheets:MissingTimeHeader', ...
            'Source sheet "%s" does not look valid: expected A1 to be "Time".', ...
            cfg.sourceSheet);
    end

    [headers, ~] = migrate_demographic_columns(wsSource, headers, nRows);
    [~, ~] = ensure_columns(wsSource, headers, {'exo_LF_1', 'exo_NLF_1'}, nRows);
    [~, ~] = ensure_columns(wsSource, headers, {'exo_PV_1'}, nRows);
    [~, ~] = arrange_demographic_columns(wsSource, nRows);

    if ~strcmp(wsSource.Name, 'Baseline')
        delete_sheet_if_exists(wb, 'Baseline', exl);
        wsSource.Copy([], wb.Worksheets.Item(wb.Worksheets.Count));
        wsBaseline = wb.Worksheets.Item(wb.Worksheets.Count);
        wsBaseline.Name = 'Baseline';
    end

    delete_non_target_sheets(wb, {'Baseline'}, exl);

    wsBaseline = get_sheet(wb, 'Baseline');
    [~, baselineCols] = arrange_demographic_columns(wsBaseline, wsBaseline.UsedRange.Rows.Count);
    format_header_row(wsBaseline, baselineCols);
    adjust_baseline_column_widths(wsBaseline, baselineCols);

    rebuild_content_sheet(wb, exl);
    wb.Save;

    summary = struct();
    summary.workbook = cfg.workbook;
    summary.sourceSheet = 'Baseline';
    summary.createdSheets = {'Baseline'};

    fprintf('\nBaseline workbook normalized in:\n  %s\n', cfg.workbook);
    fprintf('Sheets: Content, Baseline\n');

    wb.Close(true);
    wb = [];
    exl.Quit;
    exl.release;
    exl = [];
catch ME
    close_if_open(wb, false);
    quit_if_open(exl);
    rethrow(ME);
end

end

function variants = default_variants()
% Scale factors are applied to log exo_K_G paths. i3Terminal is a terminal
% log investment wedge for renewables because the current Baseline has
% exo_I_3_1 equal to zero throughout.
variants = struct( ...
    'sheet', {'Baseline_Model_RESmooth', ...
              'Baseline_Model_REEarly', ...
              'Baseline_Model_RELate'}, ...
    'description', {'Smooth RE investment path with baseline public capital', ...
                    'Front-loaded RE path with higher RE public capital', ...
                    'Back-loaded RE path with lower RE public capital'}, ...
    'i2Scale', {0.85, 1.00, 0.65}, ...
    'i2Shape', {1.00, 0.65, 1.65}, ...
    'i3Terminal', {-0.25, -0.40, -0.15}, ...
    'i3Shape', {1.00, 0.65, 1.65}, ...
    'kg2Scale', {1.00, 0.75, 1.10}, ...
    'kg3Scale', {1.00, 1.25, 0.80});
end

function cfg = parse_config(varargin)
cfg = struct();
cfg.root = pwd();
cfg.workbook = fullfile(cfg.root, 'ExcelFiles', ...
    'ModelBaseline5Sectorsand1Regions.xlsx');
cfg.sourceSheet = 'Baseline';
cfg.variants = default_variants();
cfg.visible = false;

if mod(numel(varargin), 2) ~= 0
    error('create_baseline_model_sheets:InvalidArguments', ...
        'Optional arguments must be name/value pairs.');
end

for iArg = 1:2:numel(varargin)
    sName = lower(varargin{iArg});
    value = varargin{iArg + 1};
    switch sName
        case 'workbook'
            cfg.workbook = char(value);
        case 'sourcesheet'
            cfg.sourceSheet = char(value);
        case 'variants'
            cfg.variants = value;
        case 'visible'
            cfg.visible = logical(value);
        otherwise
            error('create_baseline_model_sheets:UnknownArgument', ...
                'Unknown option "%s".', varargin{iArg});
    end
end

cfg.workbook = absolute_path(cfg.workbook);
end

function sPath = absolute_path(sPath)
if isfolder(fileparts(sPath)) || isfile(sPath)
    fileInfo = dir(sPath);
    if ~isempty(fileInfo)
        sPath = fullfile(fileInfo(1).folder, fileInfo(1).name);
        return
    end
end

if isempty(regexp(sPath, '^[A-Za-z]:[\\/]', 'once')) && ~startsWith(sPath, filesep)
    sPath = fullfile(pwd(), sPath);
end
end

function spec = normalize_variant(spec, iVariant)
defaults = struct('sheet', '', 'description', '', ...
    'i2Scale', 1, 'i2Shape', 1, 'i3Terminal', 0, 'i3Shape', 1, ...
    'kg2Scale', 1, 'kg3Scale', 1);

for field = fieldnames(defaults)'
    f = field{1};
    if ~isfield(spec, f) || isempty(spec.(f))
        spec.(f) = defaults.(f);
    end
end

if isempty(spec.sheet)
    error('create_baseline_model_sheets:MissingSheetName', ...
        'Variant %d is missing the sheet field.', iVariant);
end

spec.sheet = char(spec.sheet);
spec.description = char(spec.description);
end

function validate_sheet_name(sName)
invalidChars = ['[', ']', ':', '*', '?', '/', '\'];
if numel(sName) > 31 || any(ismember(sName, invalidChars))
    error('create_baseline_model_sheets:InvalidSheetName', ...
        'Invalid Excel sheet name "%s". Use 31 chars or fewer and avoid []:*?/\\.', ...
        sName);
end
end

function assert_file_writable(sFile)
[fid, msg] = fopen(sFile, 'a');
if fid < 0
    error('create_baseline_model_sheets:WorkbookLocked', ...
        ['Workbook is not writable. Close it in Excel and try again.\n' ...
         '  %s\n%s'], sFile, msg);
end
fclose(fid);
end

function ws = get_sheet(wb, sName)
ws = [];
for iSheet = 1:wb.Worksheets.Count
    candidate = wb.Worksheets.Item(iSheet);
    if strcmp(candidate.Name, sName)
        ws = candidate;
        return
    end
end

error('create_baseline_model_sheets:SheetNotFound', ...
    'Workbook "%s" does not contain a "%s" sheet.', wb.Name, sName);
end

function delete_sheet_if_exists(wb, sName, exl)
for iSheet = wb.Worksheets.Count:-1:1
    if strcmp(wb.Worksheets.Item(iSheet).Name, sName)
        if wb.Worksheets.Count == 1
            error('create_baseline_model_sheets:CannotDeleteOnlySheet', ...
                'Cannot replace "%s" because it is the only worksheet.', sName);
        end
        exl.DisplayAlerts = false;
        wb.Worksheets.Item(iSheet).Delete;
        exl.DisplayAlerts = true;
        return
    end
end
end

function delete_non_target_sheets(wb, targetSheetNames, exl)
if ischar(targetSheetNames) || isstring(targetSheetNames)
    targetSheetNames = cellstr(targetSheetNames);
end

for iSheet = wb.Worksheets.Count:-1:1
    sName = wb.Worksheets.Item(iSheet).Name;
    if ~any(strcmp(sName, targetSheetNames))
        if wb.Worksheets.Count == 1
            return
        end
        exl.DisplayAlerts = false;
        wb.Worksheets.Item(iSheet).Delete;
        exl.DisplayAlerts = true;
    end
end
end

function headers = read_header_row(ws, nCols)
if nCols < 1
    headers = {};
    return
end

sRange = ['A1:' excel_column(nCols) '1'];
rawHeaders = ws.Range(sRange).Value;

if ~iscell(rawHeaders)
    rawHeaders = {rawHeaders};
end

headers = cell(1, numel(rawHeaders));
for iCol = 1:numel(rawHeaders)
    headers{iCol} = normalize_header(rawHeaders{iCol});
end
end

function sHeader = normalize_header(value)
if isempty(value)
    sHeader = '';
elseif isnumeric(value)
    sHeader = num2str(value);
elseif ischar(value)
    sHeader = strtrim(value);
elseif isstring(value)
    sHeader = strtrim(char(value));
else
    sHeader = strtrim(char(value));
end
end

function [headers, nCols] = ensure_columns(ws, headers, requiredHeaders, nRows)
nCols = numel(headers);
for iHeader = 1:numel(requiredHeaders)
    sHeader = requiredHeaders{iHeader};
    if any(strcmp(headers, sHeader))
        continue
    end

    nCols = nCols + 1;
    headers{nCols} = sHeader; %#ok<AGROW>
    sCol = excel_column(nCols);
    ws.Range([sCol '1']).Value = sHeader;
    ws.Range([sCol '2:' sCol num2str(nRows)]).Value = num2cell(zeros(nRows - 1, 1));
end
end

function [headers, nCols] = migrate_demographic_columns(ws, headers, nRows)
% Ensure exo_LF_1/exo_NLF_1 exist and remove legacy exo_PoP.

iPoP = find(strcmp(headers, 'exo_PoP'), 1);
iLF = find(strcmp(headers, 'exo_LF_1'), 1);

% Prefer keeping existing data by renaming exo_PoP -> exo_LF_1 when needed.
if isempty(iLF) && ~isempty(iPoP)
    ws.Range([excel_column(iPoP) '1']).Value = 'exo_LF_1';
end

headers = read_header_row(ws, ws.UsedRange.Columns.Count);
nCols = numel(headers);
iLF = find(strcmp(headers, 'exo_LF_1'), 1);
iNLF = find(strcmp(headers, 'exo_NLF_1'), 1);

if isempty(iLF)
    nCols = nCols + 1;
    iLF = nCols;
    ws.Range([excel_column(iLF) '1']).Value = 'exo_LF_1';
    ws.Range([excel_column(iLF) '2:' excel_column(iLF) num2str(nRows)]).Value = num2cell(zeros(nRows - 1, 1));
end

if isempty(iNLF)
    nCols = nCols + 1;
    iNLF = nCols;
    ws.Range([excel_column(iNLF) '1']).Value = 'exo_NLF_1';

    sLF = excel_column(iLF);
    sNLF = excel_column(iNLF);
    rawLF = ws.Range([sLF '2:' sLF num2str(nRows)]).Value;
    rawLF = normalize_range(rawLF, nRows - 1, 1);
    ws.Range([sNLF '2:' sNLF num2str(nRows)]).Value = rawLF;
end

headers = read_header_row(ws, ws.UsedRange.Columns.Count);

% Remove any leftover legacy exo_PoP columns.
iPoPAll = find(strcmp(headers, 'exo_PoP'));
for i = numel(iPoPAll):-1:1
    ws.Columns.Item(iPoPAll(i)).Delete;
end

headers = read_header_row(ws, ws.UsedRange.Columns.Count);
nCols = numel(headers);
end

function [headersOut, nColsOut] = arrange_demographic_columns(ws, nRows)
% Keep exo_NLF_1 directly to the right of exo_LF_1.

nCols = ws.UsedRange.Columns.Count;
headers = read_header_row(ws, nCols);
iLF = find(strcmp(headers, 'exo_LF_1'), 1);
iNLF = find(strcmp(headers, 'exo_NLF_1'), 1);

if isempty(iLF) || isempty(iNLF) || iNLF == iLF + 1
    headersOut = headers;
    nColsOut = nCols;
    return
end

order = 1:nCols;
order(order == iNLF) = [];
iLFNew = find(order == iLF, 1);
order = [order(1:iLFNew), iNLF, order(iLFNew + 1:end)];

sRange = ['A1:' excel_column(nCols) num2str(nRows)];
raw = ws.Range(sRange).Formula;
raw = normalize_range(raw, nRows, nCols);
ws.Range(sRange).Formula = raw(:, order);

headersOut = read_header_row(ws, nCols);
nColsOut = nCols;
end

function values = read_numeric_column(ws, headers, sHeader, nRows)
values = zeros(nRows - 1, 1);
iCol = find(strcmp(headers, sHeader), 1);
if isempty(iCol)
    return
end

sCol = excel_column(iCol);
raw = ws.Range([sCol '2:' sCol num2str(nRows)]).Value;
raw = normalize_range(raw, nRows - 1, 1);

for iRow = 1:(nRows - 1)
    values(iRow) = numeric_value(raw{iRow, 1});
end
end

function raw = normalize_range(raw, nRows, nCols)
if ~iscell(raw)
    raw = {raw};
end

if numel(raw) == nRows * nCols
    raw = reshape(raw, nRows, nCols);
else
    out = cell(nRows, nCols);
    out(:) = {[]};
    out(1:size(raw, 1), 1:size(raw, 2)) = raw;
    raw = out;
end
end

function value = numeric_value(raw)
if isempty(raw)
    value = 0;
elseif isnumeric(raw)
    value = raw;
elseif ischar(raw) || isstring(raw)
    value = str2double(raw);
else
    value = str2double(char(raw));
end

if isempty(value) || isnan(value)
    value = 0;
end
end

function write_numeric_column(ws, headers, sHeader, values)
iCol = find(strcmp(headers, sHeader), 1);
if isempty(iCol)
    error('create_baseline_model_sheets:MissingHeader', ...
        'Sheet "%s" is missing required column "%s".', ws.Name, sHeader);
end

sCol = excel_column(iCol);
nRows = numel(values) + 1;
ws.Range([sCol '2:' sCol num2str(nRows)]).Value = num2cell(values(:));
end

function path = shaped_path(baseValues, terminalValue, shape, fallbackProgress)
if abs(terminalValue) < eps
    path = zeros(size(baseValues));
    return
end

progress = normalized_progress(baseValues);
if isempty(progress)
    progress = fallbackProgress;
end

shape = max(shape, eps);
path = terminalValue .* (progress .^ shape);
end

function progress = normalized_progress(values)
scale = max(abs(values));
if isempty(values) || scale < eps
    progress = [];
    return
end

progress = abs(values(:)) ./ scale;
progress(~isfinite(progress)) = 0;
progress = min(max(progress, 0), 1);

for i = 2:numel(progress)
    if progress(i) < progress(i - 1)
        progress(i) = progress(i - 1);
    end
end

if progress(end) < eps
    progress = [];
end
end

function rebuild_content_sheet(wb, exl)
exl.DisplayAlerts = false;
for iSheet = wb.Worksheets.Count:-1:1
    if strcmp(wb.Worksheets.Item(iSheet).Name, 'Content') && wb.Worksheets.Count > 1
        wb.Worksheets.Item(iSheet).Delete;
        break
    end
end
exl.DisplayAlerts = true;

wb.Worksheets.Add(wb.Worksheets.Item(1));
wsContent = wb.Worksheets.Item(1);
wsContent.Name = 'Content';

wsContent.Range('A1').Value = 'Sheet';
wsContent.Range('B1').Value = 'Link';
format_header_row(wsContent, 2);

for iSheet = 2:wb.Worksheets.Count
    sName = wb.Worksheets.Item(iSheet).Name;
    sCellA = ['A' num2str(iSheet)];
    sCellB = ['B' num2str(iSheet)];
    wsContent.Range(sCellA).Value = sName;
    targetRange = wsContent.Range(sCellB);
    targetRange.Value = sName;

    % Prefer COM hyperlink API to avoid locale-specific formula separators.
    try
        invoke(wsContent.Hyperlinks, 'Add', targetRange, '', ['''' sName '''!A1'], '', sName);
    catch
        % Fallbacks if Hyperlinks.Add fails in some Excel builds.
        try
            targetRange.Formula = ['=HYPERLINK("#''' sName '''!A1","' sName '")'];
        catch
            targetRange.FormulaLocal = ['=HYPERLINK("#''' sName '''!A1";"' sName '")'];
        end
    end
end

wsContent.Columns.AutoFit;
end

function format_header_row(ws, nCols)
if nCols < 1
    return
end

sLastCol = excel_column(nCols);
headerRange = ws.Range(['A1:' sLastCol '1']);
headerRange.Font.Bold = true;
headerRange.Interior.Color = 15132390; % light gray
end

function adjust_baseline_column_widths(ws, nCols)
if nCols < 1
    return
end

lastCol = excel_column(nCols);
ws.Range(['A:' lastCol]).Columns.AutoFit;

% Keep early identifying columns readable.
if nCols >= 1
    ws.Range('A:A').ColumnWidth = max(ws.Range('A:A').ColumnWidth, 10);
end
if nCols >= 2
    ws.Range('B:B').ColumnWidth = max(ws.Range('B:B').ColumnWidth, 12);
end
if nCols >= 3
    ws.Range('C:C').ColumnWidth = max(ws.Range('C:C').ColumnWidth, 12);
end
end

function sColumn = excel_column(iCol)
letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
sColumn = '';
while iCol > 0
    iRem = mod(iCol - 1, 26);
    sColumn = [letters(iRem + 1) sColumn]; %#ok<AGROW>
    iCol = floor((iCol - 1) / 26);
end
end

function close_if_open(wb, lSave)
if isempty(wb)
    return
end

try
    wb.Close(lSave);
catch
end
end

function quit_if_open(exl)
if isempty(exl)
    return
end

try
    exl.Quit;
catch
end

try
    exl.release;
catch
end
end

function wb = open_workbook_safe(exl, workbookPath)
% Robust Excel open helper to reduce COM Open failures.

wb = [];
workbookPath = char(workbookPath);
workbookPath = strtrim(workbookPath);
workbookPath = strrep(workbookPath, '/', '\\');

if ~isfile(workbookPath)
    error('create_baseline_model_sheets:WorkbookNotFound', ...
        'Workbook not found:\n  %s', workbookPath);
end

% Reuse if already open in this Excel instance.
for iWb = 1:exl.Workbooks.Count
    try
        wbCandidate = exl.Workbooks.Item(iWb);
        if strcmpi(char(wbCandidate.FullName), workbookPath)
            wb = wbCandidate;
            return
        end
    catch
    end
end

% Try a sequence of Open signatures commonly affected by COM quirks.
openErrors = {};
openAttempts = {
    @() exl.Workbooks.Open(workbookPath), ...
    @() exl.Workbooks.Open(workbookPath, 0, false), ...
    @() exl.Workbooks.Open(workbookPath, 0, true)
    };

for iTry = 1:numel(openAttempts)
    try
        wb = openAttempts{iTry}();
        if ~isempty(wb)
            return
        end
    catch ME
        openErrors{end + 1} = sprintf('Attempt %d failed: %s', iTry, ME.message); %#ok<AGROW>
    end
end

error('create_baseline_model_sheets:WorkbookOpenFailed', ...
    ['Excel failed to open workbook:\n  %s\n\n' ...
     'Tried multiple Open signatures. Last errors:\n  %s\n\n' ...
     'Close any open Excel windows using this file and retry.'], ...
    workbookPath, strjoin(openErrors, '\n  '));
end
