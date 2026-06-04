function summary = update_baseline_excel(varargin)
% update_baseline_excel  Refresh the runnable ModelBaseline workbook.
%
% The model reads exogenous baseline paths from:
%   ExcelFiles/ModelBaseline<S>Sectorsand<R>Regions.xlsx
%
% Preferred workflow in the split workbook:
%   Baseline_Input   user-edited assumptions
%   Baseline_calc    helper formulas
%   Baseline_Implied formula-driven model-ready scenario table
%   Baseline         values-only hardcoded copy read by MATLAB/Dynare
%
% If Baseline_Implied already exists in the split workbook, this function
% recalculates the workbook and copies Baseline_Implied values into Baseline.
% The Baseline sheet is validated and must be formula-free after the copy.
%
% Backward-compatible bootstrap:
% If Baseline_Implied is missing and the legacy combined workbook exists,
% the helper copies Baseline_Input and Baseline_calc from the combined
% workbook. It then preserves the current split Baseline sheet as
% Baseline_Implied, localizes formula links, and writes Baseline as a
% hardcoded values-only copy.
%
% Usage from the repository root:
%   addpath(genpath('Functions'))
%   update_baseline_excel()
%
% Optional name/value pairs:
%   'Subsectors'        numeric, default 5
%   'Regions'           numeric, default 1
%   'Version'           char,    default ''
%   'SourceWorkbook'    char,    default ExcelFiles/ModelSimulationandCalibration...
%   'TargetWorkbook'    char,    default ExcelFiles/ModelBaseline...
%   'ImpliedSheet'      char,    default 'Baseline_Implied'
%   'HardcodedSheet'    char,    default 'Baseline'
%   'BootstrapFromLegacy' logical, default true
%   'ForceBootstrap'    logical, default false
%   'RefreshInputSheetsFromSource' logical, default false
%   'Visible'           logical, default false

cfg = parse_config(varargin{:});

if ~isfile(cfg.targetWorkbook)
    error('update_baseline_excel:TargetNotFound', ...
        'Target workbook not found:\n  %s', cfg.targetWorkbook);
end

assert_file_writable(cfg.targetWorkbook);

exl = [];
wbSource = [];
wbTarget = [];

try
    exl = actxserver('excel.application');
    set(exl, 'AskToUpdateLinks', 0);
    set(exl, 'DisplayAlerts', false);
    exl.Visible = cfg.visible;

    exlWkbk = exl.Workbooks;
    wbTarget = exlWkbk.Open(cfg.targetWorkbook, 0, false);

    hasImplied = sheet_exists(wbTarget, cfg.impliedSheet);
    bootstrap = cfg.forceBootstrap || (~hasImplied && cfg.bootstrapFromLegacy);

    if cfg.refreshInputSheetsFromSource
        if ~isfile(cfg.sourceWorkbook)
            error('update_baseline_excel:SourceNotFound', ...
                'Source workbook not found:\n  %s', cfg.sourceWorkbook);
        end

        wbSource = exlWkbk.Open(cfg.sourceWorkbook, 0, true);
        copy_sheet_from_source(wbSource, wbTarget, 'Baseline_Input', 'Baseline_Input', exl);
        copy_sheet_from_source(wbSource, wbTarget, 'Baseline_calc', 'Baseline_calc', exl);
        localize_external_formula_links(wbTarget, wbSource.Name);
        close_if_open(wbSource, false);
        wbSource = [];
    end

    if bootstrap
        if ~isfile(cfg.sourceWorkbook)
            error('update_baseline_excel:SourceNotFound', ...
                ['Baseline_Implied is missing in the split workbook and ' ...
                 'the legacy source workbook was not found:\n  %s'], ...
                cfg.sourceWorkbook);
        end

        wbSource = exlWkbk.Open(cfg.sourceWorkbook, 0, true);
        bootstrap_from_legacy(wbSource, wbTarget, cfg, exl);
        localize_external_formula_links(wbTarget, wbSource.Name);
        hasImplied = true;
    end

    if ~hasImplied
        error('update_baseline_excel:MissingImpliedSheet', ...
            ['Workbook "%s" does not contain "%s". Add that sheet or run ' ...
             'with BootstrapFromLegacy=true and a valid SourceWorkbook.'], ...
            cfg.targetWorkbook, cfg.impliedSheet);
    end

    recalculate_excel(exl);

    wsImplied = get_sheet(wbTarget, cfg.impliedSheet);
    wsHardcoded = get_or_create_sheet(wbTarget, cfg.hardcodedSheet, exl);

    copy_sheet_values(wsImplied, wsHardcoded);
    validate_model_ready_sheet(wsHardcoded, cfg.hardcodedSheet);
    assert_sheet_has_no_formulas(wsHardcoded, cfg.hardcodedSheet);

    recalculate_excel(exl);
    rebuild_content_sheet(wbTarget, exl);
    wsHardcoded.Columns.AutoFit;
    wbTarget.Save;

    summary = struct();
    summary.sourceWorkbook = cfg.sourceWorkbook;
    summary.targetWorkbook = cfg.targetWorkbook;
    summary.impliedSheet = cfg.impliedSheet;
    summary.hardcodedSheet = cfg.hardcodedSheet;
    summary.bootstrappedFromLegacy = bootstrap;
    summary.rowsCopied = wsHardcoded.UsedRange.Rows.Count;
    summary.columnsCopied = wsHardcoded.UsedRange.Columns.Count;

    fprintf('Baseline update complete.\n');
    fprintf('  Target: %s\n', cfg.targetWorkbook);
    if bootstrap
        fprintf('  Bootstrapped from: %s\n', cfg.sourceWorkbook);
    end
    fprintf('  Implied sheet: %s\n', cfg.impliedSheet);
    fprintf('  Hardcoded sheet: %s\n', cfg.hardcodedSheet);
    fprintf('  Rows copied: %d\n', summary.rowsCopied);
    fprintf('  Columns copied: %d\n', summary.columnsCopied);

    close_if_open(wbSource, false);
    wbSource = [];
    close_if_open(wbTarget, true);
    wbTarget = [];
    quit_if_open(exl);
catch ME
    close_if_open(wbSource, false);
    close_if_open(wbTarget, false);
    quit_if_open(exl);
    rethrow(ME);
end

end

function bootstrap_from_legacy(wbSource, wbTarget, cfg, exl)
copy_sheet_from_source(wbSource, wbTarget, 'Baseline_Input', 'Baseline_Input', exl);
copy_sheet_from_source(wbSource, wbTarget, 'Baseline_calc', 'Baseline_calc', exl);
if sheet_exists(wbTarget, cfg.hardcodedSheet)
    copy_sheet_within_workbook(wbTarget, cfg.hardcodedSheet, cfg.impliedSheet, exl);
else
    copy_sheet_from_source(wbSource, wbTarget, cfg.hardcodedSheet, cfg.impliedSheet, exl);
end
end

function cfg = parse_config(varargin)
cfg = struct();
cfg.root = pwd();
cfg.subsectors = 5;
cfg.regions = 1;
cfg.version = '';
cfg.visible = false;
cfg.sourceWorkbook = '';
cfg.targetWorkbook = '';
cfg.impliedSheet = 'Baseline_Implied';
cfg.hardcodedSheet = 'Baseline';
cfg.bootstrapFromLegacy = true;
cfg.forceBootstrap = false;
cfg.refreshInputSheetsFromSource = false;

if mod(numel(varargin), 2) ~= 0
    error('update_baseline_excel:InvalidArguments', ...
        'Optional arguments must be name/value pairs.');
end

for iArg = 1:2:numel(varargin)
    sName = lower(varargin{iArg});
    value = varargin{iArg + 1};
    switch sName
        case 'subsectors'
            cfg.subsectors = value;
        case 'regions'
            cfg.regions = value;
        case 'version'
            cfg.version = char(value);
        case 'sourceworkbook'
            cfg.sourceWorkbook = char(value);
        case 'targetworkbook'
            cfg.targetWorkbook = char(value);
        case 'impliedsheet'
            cfg.impliedSheet = char(value);
        case 'hardcodedsheet'
            cfg.hardcodedSheet = char(value);
        case 'bootstrapfromlegacy'
            cfg.bootstrapFromLegacy = logical(value);
        case 'forcebootstrap'
            cfg.forceBootstrap = logical(value);
        case 'refreshinputsheetsfromsource'
            cfg.refreshInputSheetsFromSource = logical(value);
        case 'visible'
            cfg.visible = logical(value);
        otherwise
            error('update_baseline_excel:UnknownArgument', ...
                'Unknown option "%s".', varargin{iArg});
    end
end

sSuffix = [num2str(cfg.subsectors) 'Sectorsand' ...
           num2str(cfg.regions) 'Regions' cfg.version '.xlsx'];

if isempty(cfg.sourceWorkbook)
    cfg.sourceWorkbook = fullfile(cfg.root, 'ExcelFiles', ...
        ['ModelSimulationandCalibration' sSuffix]);
end

if isempty(cfg.targetWorkbook)
    cfg.targetWorkbook = fullfile(cfg.root, 'ExcelFiles', ...
        ['ModelBaseline' sSuffix]);
end

cfg.sourceWorkbook = absolute_path(cfg.sourceWorkbook);
cfg.targetWorkbook = absolute_path(cfg.targetWorkbook);
end

function sPath = absolute_path(sPath)
if isfolder(fileparts(sPath)) || isfile(sPath)
    fileInfo = dir(sPath);
    if ~isempty(fileInfo)
        sPath = fullfile(fileInfo(1).folder, fileInfo(1).name);
        return
    end
end

if ~is_absolute_path(sPath)
    sPath = fullfile(pwd(), sPath);
end
end

function tf = is_absolute_path(sPath)
tf = ~isempty(regexp(sPath, '^[A-Za-z]:[\\/]', 'once')) || startsWith(sPath, filesep);
end

function assert_file_writable(sFile)
[fid, msg] = fopen(sFile, 'a');
if fid < 0
    error('update_baseline_excel:TargetLocked', ...
        ['Target workbook is not writable. Close it in Excel and try again.\n' ...
         '  %s\n%s'], sFile, msg);
end
fclose(fid);
end

function recalculate_excel(exl)
try
    exl.CalculateFullRebuild;
catch
    try
        exl.CalculateFull;
    catch
        exl.Calculate;
    end
end
end

function tf = sheet_exists(wb, sName)
tf = false;
for iSheet = 1:wb.Worksheets.Count
    if strcmp(wb.Worksheets.Item(iSheet).Name, sName)
        tf = true;
        return
    end
end
end

function ws = get_sheet(wb, sName)
for iSheet = 1:wb.Worksheets.Count
    candidate = wb.Worksheets.Item(iSheet);
    if strcmp(candidate.Name, sName)
        ws = candidate;
        return
    end
end

error('update_baseline_excel:SheetNotFound', ...
    'Workbook "%s" does not contain a "%s" sheet.', wb.Name, sName);
end

function ws = get_or_create_sheet(wb, sName, exl)
if sheet_exists(wb, sName)
    ws = get_sheet(wb, sName);
    return
end

exl.DisplayAlerts = false;
ws = wb.Worksheets.Add([], wb.Worksheets.Item(wb.Worksheets.Count));
ws.Name = sName;
exl.DisplayAlerts = true;
end

function copy_sheet_from_source(wbSource, wbTarget, sSource, sTarget, exl)
wsSource = get_sheet(wbSource, sSource);
delete_sheet_if_exists(wbTarget, sTarget, exl);

wsSource.Copy([], wbTarget.Worksheets.Item(wbTarget.Worksheets.Count));
wsNew = wbTarget.Worksheets.Item(wbTarget.Worksheets.Count);
wsNew.Name = sTarget;
end

function copy_sheet_within_workbook(wb, sSource, sTarget, exl)
wsSource = get_sheet(wb, sSource);
delete_sheet_if_exists(wb, sTarget, exl);

wsSource.Copy([], wb.Worksheets.Item(wb.Worksheets.Count));
wsNew = wb.Worksheets.Item(wb.Worksheets.Count);
wsNew.Name = sTarget;
end

function delete_sheet_if_exists(wb, sName, exl)
for iSheet = wb.Worksheets.Count:-1:1
    if strcmp(wb.Worksheets.Item(iSheet).Name, sName)
        if wb.Worksheets.Count == 1
            error('update_baseline_excel:CannotDeleteOnlySheet', ...
                'Cannot replace "%s" because it is the only worksheet.', sName);
        end
        exl.DisplayAlerts = false;
        wb.Worksheets.Item(iSheet).Delete;
        exl.DisplayAlerts = true;
        return
    end
end
end

function localize_external_formula_links(wbTarget, sSourceWorkbookName)
% Remove common Excel external-link prefixes after bootstrapping sheets from
% the legacy workbook. This covers formulas such as [1]Baseline_calc!A4 and
% '[Workbook.xlsx]Baseline_calc'!A4.
for iSheet = 1:wbTarget.Worksheets.Count
    ws = wbTarget.Worksheets.Item(iSheet);
    replace_in_cells(ws, ['[' sSourceWorkbookName ']'], '');
    % Excel can emit numeric external-book tokens such as [1], [2], ...
    % depending on workbook open order. Strip a broad range proactively.
    for iBook = 1:50
        replace_in_cells(ws, ['[' num2str(iBook) ']'], '');
    end
end
end

function replace_in_cells(ws, sWhat, sReplacement)
try
    ws.Cells.Replace(sWhat, sReplacement, 2, 1, false, false, false, false);
catch
end
end

function copy_sheet_values(wsSource, wsTarget)
sourceUsed = wsSource.UsedRange;
targetUsed = wsTarget.UsedRange;

if sourceUsed.Row ~= 1 || sourceUsed.Column ~= 1
    error('update_baseline_excel:UnexpectedImpliedRange', ...
        'Expected "%s" used range to start at A1.', wsSource.Name);
end

nRows = sourceUsed.Rows.Count;
nCols = sourceUsed.Columns.Count;

targetRows = max(1, targetUsed.Rows.Count);
targetCols = max(1, targetUsed.Columns.Count);
clearRows = max(nRows, targetRows);
clearCols = max(nCols, targetCols);

clearAddress = ['A1:' excel_column(clearCols) num2str(clearRows)];
wsTarget.Range(clearAddress).ClearContents;
sourceAddress = ['A1:' excel_column(nCols) num2str(nRows)];
targetAddress = sourceAddress;
wsTarget.Range(targetAddress).Value = wsSource.Range(sourceAddress).Value;
end

function validate_model_ready_sheet(ws, sSheet)
used = ws.UsedRange;
if used.Row ~= 1 || used.Column ~= 1
    error('update_baseline_excel:UnexpectedHardcodedRange', ...
        'Expected "%s" used range to start at A1.', sSheet);
end

nRows = used.Rows.Count;
nCols = used.Columns.Count;
if nRows < 2 || nCols < 2
    error('update_baseline_excel:EmptyHardcodedSheet', ...
        'Sheet "%s" must contain a header row and at least one data row.', sSheet);
end

headers = read_header_row(ws, nCols);
if isempty(headers) || ~strcmp(headers{1}, 'Time')
    error('update_baseline_excel:MissingTimeHeader', ...
        'Sheet "%s" does not look valid: expected A1 to be "Time".', sSheet);
end

assert_no_duplicate_headers(headers, sSheet);

timeValues = read_numeric_column_by_index(ws, 1, nRows);
if any(isnan(timeValues))
    error('update_baseline_excel:InvalidTimeColumn', ...
        'Sheet "%s" has non-numeric values in the Time column.', sSheet);
end

expected = (timeValues(1):(timeValues(1) + numel(timeValues) - 1))';
if any(abs(timeValues(:) - expected) > 1e-10)
    error('update_baseline_excel:NonSequentialTime', ...
        'Sheet "%s" has a non-sequential Time column.', sSheet);
end
end

function assert_no_duplicate_headers(headers, sSheet)
headers = headers(~cellfun(@isempty, headers));
[uniqueHeaders, ~, idx] = unique(headers);
counts = accumarray(idx(:), 1);
duplicates = uniqueHeaders(counts > 1);

if ~isempty(duplicates)
    error('update_baseline_excel:DuplicateHeaders', ...
        'Sheet "%s" has duplicate header(s): %s', ...
        sSheet, strjoin(duplicates, ', '));
end
end

function assert_sheet_has_no_formulas(ws, sSheet)
try
    formulaCells = ws.UsedRange.SpecialCells(-4123); % xlCellTypeFormulas
    if formulaCells.Count > 0
        error('update_baseline_excel:HardcodedSheetHasFormulas', ...
            'Sheet "%s" must be a values-only hardcoded copy, but formulas remain.', ...
            sSheet);
    end
catch ME
    if ~contains(ME.identifier, 'HardcodedSheetHasFormulas') && ...
       ~contains(ME.message, 'No cells were found')
        rethrow(ME);
    elseif contains(ME.identifier, 'HardcodedSheetHasFormulas')
        rethrow(ME);
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

function values = read_numeric_column_by_index(ws, iCol, nRows)
sCol = excel_column(iCol);
raw = ws.Range([sCol '2:' sCol num2str(nRows)]).Value;
if ~iscell(raw)
    raw = {raw};
end

values = nan(nRows - 1, 1);
for iRow = 1:(nRows - 1)
    value = raw{iRow, 1};
    if isnumeric(value)
        values(iRow) = value;
    elseif ischar(value) || isstring(value)
        values(iRow) = str2double(char(value));
    end
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
wsContent.Range('B1').Value = 'Target';
wsContent.Range('A1:B1').Interior.ColorIndex = 48;

for iSheet = 2:wb.Worksheets.Count
    sName = wb.Worksheets.Item(iSheet).Name;
    wsContent.Range(['A' num2str(iSheet)]).Value = sName;
    wsContent.Range(['B' num2str(iSheet)]).Value = ['#''' sName '''!A1'];
end

wsContent.Columns.AutoFit;
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
