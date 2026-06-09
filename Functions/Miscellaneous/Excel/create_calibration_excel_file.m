% create_calibration_excel_file  —  Creates ModelCalibration*.xlsx
%
% Sheets: Data | Start | Structural Parameters | Content
%
% Run this once when creating a new model configuration.  After running,
% populate IO_Data and Trade_Flows manually (or via update_data_excel.m).

%% Prologue
clearvars;
sThisFolder = fileparts(mfilename('fullpath'));
sRepoRoot = fileparts(fileparts(fileparts(sThisFolder)));
sPathWD = sRepoRoot;

%% Define version to create
sversion = '';

%% Optional: sync Start/Structural Parameters values from training workbook
lSyncValuesFromTraining = true;

%% Define sectors
casSectors = {'Primary'; 'Energy'; 'Secondary'; 'Tertiary'};
inbsectors_p = length(casSectors);

%% Define subsectors
casSubSectors = {'Primary'; 'Fossil'; 'Renewables'; 'Secondary'; 'Tertiary'};
inbsubsectors_p = length(casSubSectors);

%% Define regions
casRegions = {'VNM'};
inbregions_p = length(casRegions);

%% Define climate variables
casClimateVarsRegionalName = {'surface temperature (Celsius)'};
casClimateVarsRegional = {'tas'};
casClimateVarsNationalName = {'Sea level'};
casClimateVarsNational = {'SL'};

%% Build workbook name and sheet definitions
sWorkBookName = ['ModelCalibration' num2str(inbsubsectors_p) 'Sectorsand' num2str(inbregions_p) 'Regions' sversion '.xlsx'];

addpath(genpath(fullfile(sPathWD, 'Functions')))
run(fullfile(sThisFolder, 'define_sheets_calibration.m'));

sExcelFileName = fullfile(sPathWD, 'ExcelFiles', sWorkBookName);
if exist(sExcelFileName, 'file')
    delete(sExcelFileName)
end
writecell({' '}, sExcelFileName);

% Put Content sheet first
strSheettemp = strSheet;
strSheet(1) = strSheettemp(end);
strSheet(2:end) = strSheettemp(1:end-1);

[~, iposData] = ismember('Data', {strSheet.Name});
if iposData > 0
    temp = cellfun(@(x) reshape(x,[],1), {strSheet(iposData).Categories.CellNames}, 'UniformOutput', false);
    casCellNamesTotal = vertcat(temp{:});
    casCellNamesTotal = casCellNamesTotal(cellfun(@(x) ~isempty(x), casCellNamesTotal));
end

exl = actxserver('excel.application');
set(exl,'AskToUpdateLinks',0)
exl.Visible = 1;
exlWkbk = exl.Workbooks;
exlFile = exlWkbk.Open(sExcelFileName);

for icosheet = 1:size(strSheet,2)-exlFile.Sheets.Count
    exlFile.Sheets.Add;
end

for icosheet = 1:size(strSheet,2)
    exlFile.Sheets.Item(icosheet).Name = strSheet(icosheet).Name;
    exlSheet1 = exlFile.Sheets.Item(strSheet(icosheet).Name);
    exlSheet1.Activate
    if isstruct(strSheet(icosheet).Categories)
        strsubsheets = strSheet(icosheet).Categories;
        icostartcol = 1;
        for icosubsheet = 1:size(strsubsheets,2)
            inbrow = size(strsubsheets(icosubsheet).Data,1);
            inbcol = size(strsubsheets(icosubsheet).Data,2);
            dat_range = [get_excel_column(icostartcol) '1:' get_excel_column(icostartcol+inbcol-1) num2str(inbrow)];
            rngObj = exlSheet1.Range(dat_range);
            set(rngObj,'NumberFormat','0.00');
            rngObj.Value = strsubsheets(icosubsheet).Data;
            for icorow = 1:inbrow
                for icocol = 1:inbcol
                    if ~isempty(strsubsheets(icosubsheet).CellNames{icorow, icocol})
                        rngObj = exlSheet1.Range([get_excel_column(icostartcol+icocol-1) num2str(icorow)]);
                        rngObj.Name = strsubsheets(icosubsheet).CellNames{icorow, icocol};
                    end
                end
            end
            icostartcol = icostartcol + inbcol + 1;
        end
        exl.Cells.Select;
        exl.Cells.EntireColumn.AutoFit;
    else
        inbrow = size(strSheet(icosheet).Categories,1);
        inbcol = size(strSheet(icosheet).Categories,2);
        [~, ivaluecol] = ismember('Value', strSheet(icosheet).Categories(1,:));
        for icocol = 1:inbcol
            if icocol == ivaluecol
                dat_range = [get_excel_column(icocol) '1:' get_excel_column(icocol) '1'];
                rngObj = exlSheet1.Range(dat_range);
                rngObj.Value = strSheet(icosheet).Categories(1, icocol);
                dat_range = [get_excel_column(icocol) '2:' get_excel_column(icocol) num2str(inbrow)];
                rngObj = exlSheet1.Range(dat_range);
                write_excel_value_or_formula_safe(rngObj, strSheet(icosheet).Categories(2:end, icocol));
            else
                dat_range = [get_excel_column(icocol) '1:' get_excel_column(icocol) num2str(inbrow)];
                rngObj = exlSheet1.Range(dat_range);
                write_excel_value_or_formula_safe(rngObj, strSheet(icosheet).Categories(:, icocol));
            end
        end
        invoke(exl.Selection.Columns,'Autofit');
        for icorow = 1:inbrow
            dat_range = ['A' num2str(icorow) ':' get_excel_column(inbcol) num2str(icorow)];
            rngObj = exlSheet1.Range(dat_range);
            if sum(cellfun(@(x) isequal(x, ''), strSheet(icosheet).Categories(icorow, :)),2) == 2
                rngObj.MergeCells = 1;
                rngObj.Interior.ColorIndex = 48;
            end
            if icorow == 1 && ~ismember(strSheet(icosheet).Name, {'Data'})
                rngObj.Interior.ColorIndex = 48;
            end
        end
        exl.Cells.Select;
        exl.Cells.EntireColumn.AutoFit;
    end
end

if lSyncValuesFromTraining
    sync_calibration_values_from_training(exlFile, sPathWD, sWorkBookName, {'Start', 'Structural Parameters'});
end

exlFile.Save
exl.Quit
exl.release

function write_excel_formula_safe(rngObj, formulaData)
if try_write_formula_variant(rngObj, formulaData)
    return
end
error('ExcelFormulaWrite:Failed', 'Unable to write formula with either comma or semicolon separators.');
end

function write_excel_value_or_formula_safe(rngObj, data)
try
    rngObj.Value = data;
    return
catch
end

if is_formula_like_data(data) && try_write_formula_variant(rngObj, data)
    return
end

% Last fallback if Value fails for mixed text content.
rngObj.Value2 = data;
end

function ok = try_write_formula_variant(rngObj, data)
ok = false;
variants = build_formula_variants_for_data(data);

for i = 1:numel(variants)
    thisData = variants{i};
    try
        rngObj.FormulaLocal = thisData;
        ok = true;
        return
    catch
    end
    try
        rngObj.Formula = thisData;
        ok = true;
        return
    catch
    end
end
end

function variants = build_formula_variants_for_data(data)
variants = {data};

if iscell(data)
    if any(cellfun(@(x) ischar(x) && contains(x, ';'), data(:)))
        variants{end + 1} = cellfun(@replace_sep_semicolon_to_comma, data, 'UniformOutput', false); %#ok<AGROW>
    end
    if any(cellfun(@(x) ischar(x) && contains(x, ','), data(:)))
        variants{end + 1} = cellfun(@replace_sep_comma_to_semicolon, data, 'UniformOutput', false); %#ok<AGROW>
    end
else
    if ischar(data) && contains(data, ';')
        variants{end + 1} = strrep(data, ';', ','); %#ok<AGROW>
    end
    if ischar(data) && contains(data, ',')
        variants{end + 1} = strrep(data, ',', ';'); %#ok<AGROW>
    end
end

end

function tf = is_formula_like_data(data)
if iscell(data)
    tf = any(cellfun(@(x) ischar(x) && ~isempty(x) && x(1) == '=', data(:)));
elseif ischar(data)
    tf = ~isempty(data) && data(1) == '=';
else
    tf = false;
end
end

function out = replace_sep_semicolon_to_comma(x)
if ischar(x)
    out = strrep(x, ';', ',');
else
    out = x;
end
end

function out = replace_sep_comma_to_semicolon(x)
if ischar(x)
    out = strrep(x, ',', ';');
else
    out = x;
end
end

function sync_calibration_values_from_training(exlFile, sPathWD, sWorkBookName, sheetNames)
% Ensure generated calibration workbook uses the exact same sheet layout
% and formulas/constants as the Day3 training calibration workbook.

sourcePath = fullfile(sPathWD, 'Training', 'Day3_Calibration', sWorkBookName);
if ~exist(sourcePath, 'file')
    warning('TrainingSource:Missing', 'Training source workbook not found: %s', sourcePath);
    return
end

try
    exl = exlFile.Application;
    srcWkbk = exl.Workbooks.Open(sourcePath, 0, true);
catch ME
    warning('TrainingSource:OpenFailed', 'Failed to open training source workbook (%s): %s', sourcePath, ME.message);
    return
end

try
    for iSheet = 1:numel(sheetNames)
        sSheet = sheetNames{iSheet};
        if ~sheet_exists(srcWkbk, sSheet) || ~sheet_exists(exlFile, sSheet)
            continue
        end

        srcSheet = srcWkbk.Sheets.Item(sSheet);
        dstSheet = exlFile.Sheets.Item(sSheet);
        copy_entire_sheet_content(srcSheet, dstSheet);
    end
catch ME
    warning('TrainingSource:SyncFailed', 'Failed while syncing values from training source: %s', ME.message);
end

try
    srcWkbk.Close(false);
catch
end
end

function copy_entire_sheet_content(srcSheet, dstSheet)
% Copy values, formulas, and formatting for the full used range.

srcUsed = srcSheet.UsedRange;
srcRows = srcUsed.Rows.Count;
srcCols = srcUsed.Columns.Count;

dstSheet.Cells.Clear;

if srcRows <= 0 || srcCols <= 0
    return
end

lastCol = get_excel_column(srcCols);
srcRange = srcSheet.Range(['A1:' lastCol num2str(srcRows)]);
dstRange = dstSheet.Range(['A1:' lastCol num2str(srcRows)]);

srcRange.Copy(dstRange);

% Mirror source column widths for readability and stable workbook diffs.
for iCol = 1:srcCols
    dstSheet.Columns.Item(iCol).ColumnWidth = srcSheet.Columns.Item(iCol).ColumnWidth;
end

dstSheet.Cells.EntireColumn.AutoFit;
dstSheet.Parent.Application.CutCopyMode = false;
end

function tf = sheet_exists(wkbk, sheetName)
tf = false;
try
    wkbk.Sheets.Item(sheetName);
    tf = true;
catch
end
end
