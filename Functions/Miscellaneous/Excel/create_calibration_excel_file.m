% create_calibration_excel_file  —  Creates ModelCalibration*.xlsx
%
% Sheets: Data | Start | Structural Parameters | Content
%
% Run this once when creating a new model configuration.  After running,
% populate IO_Data and Trade_Flows manually (or via update_data_excel.m).

%% Prologue
clearvars;
sPathWD = pwd();
chunkSize = 250;

%% Define version to create
sversion = '';

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
sThisFolder = fileparts(mfilename('fullpath'));
sRepoRoot = fileparts(fileparts(fileparts(sThisFolder)));
sExcelOutputFolder = fullfile(sRepoRoot, 'ExcelFiles');
run(fullfile(sThisFolder, 'define_sheets_calibration.m'));

if ~exist(sExcelOutputFolder, 'dir')
    mkdir(sExcelOutputFolder);
end

sExcelFileName = fullfile(sExcelOutputFolder, sWorkBookName);

% Close any running Excel workbook with the same target name before recreating it.
[~, sTgtStem, sTgtExt] = fileparts(sExcelFileName);
sTgtFile = [sTgtStem sTgtExt];
bPreflightClosed = false;
try
    hExl = actxGetRunningServer('Excel.Application');
    for iWb = hExl.Workbooks.Count : -1 : 1
        [~, sWbStem, sWbExt] = fileparts(hExl.Workbooks.Item(iWb).FullName);
        if strcmpi([sWbStem sWbExt], sTgtFile)
            hExl.Workbooks.Item(iWb).Close(false);
            bPreflightClosed = true;
        end
    end
catch
end
if bPreflightClosed
    pause(1.5);
end

if exist(sExcelFileName, 'file')
    delete(sExcelFileName)
end

tempProbe = fullfile(sExcelOutputFolder, ['.__write_probe__' char(java.util.UUID.randomUUID()) '.tmp']);
fid = fopen(tempProbe, 'w');
if fid == -1
    error(['create_calibration_excel_file: cannot create or overwrite workbook.\n' ...
           '  Path: %s\n' ...
           '  Close the file in Excel (or any other application) and re-run.'], ...
        sExcelFileName);
end
fclose(fid);
delete(tempProbe);

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
                write_column_chunks(exlSheet1, icocol, 2, strSheet(icosheet).Categories(2:end, icocol), true, chunkSize);
            else
                write_column_chunks(exlSheet1, icocol, 1, strSheet(icosheet).Categories(:, icocol), false, chunkSize);
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
exlFile.Save
exl.Quit
exl.release

function write_column_chunks(exlSheet, icol, startRow, values, useFormula, chunkSize)
nRows = size(values, 1);

for iStart = 1:chunkSize:nRows
    iEnd = min(iStart + chunkSize - 1, nRows);
    rowStart = startRow + iStart - 1;
    rowEnd = startRow + iEnd - 1;
    dat_range = [get_excel_column(icol) num2str(rowStart) ':' get_excel_column(icol) num2str(rowEnd)];
    rngObj = exlSheet.Range(dat_range);
    payload = values(iStart:iEnd, :);
    try
        if useFormula
            rngObj.Formula = payload;
        else
            rngObj.Value = payload;
        end
    catch
        write_column_cells(exlSheet, icol, rowStart, payload, useFormula);
    end
end
end

function write_column_cells(exlSheet, icol, startRow, values, useFormula)
nRows = size(values, 1);

for iRow = 1:nRows
    cellAddress = [get_excel_column(icol) num2str(startRow + iRow - 1)];
    rngObj = exlSheet.Range(cellAddress);
    [payload, writeAsFormula] = normalize_excel_payload(values{iRow, 1}, useFormula);
    if writeAsFormula
        rngObj.Formula = payload;
    else
        rngObj.Value = payload;
    end
end
end

function [payload, writeAsFormula] = normalize_excel_payload(payload, defaultFormulaMode)
writeAsFormula = defaultFormulaMode;

if isempty(payload)
    payload = '';
    writeAsFormula = false;
    return
end

if isstring(payload)
    payload = char(payload);
end

if islogical(payload)
    payload = double(payload);
end

if isnumeric(payload)
    if isscalar(payload)
        return
    end
    payload = payload(1);
    return
end

if ischar(payload)
    if startsWith(payload, '=')
        writeAsFormula = true;
    end
    return
end

payload = char(string(payload));
if startsWith(payload, '=')
    writeAsFormula = true;
end
end
