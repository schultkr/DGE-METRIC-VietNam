% create_calibration_excel_file  —  Creates ModelCalibration*.xlsx
%
% Sheets: Data | Start | Structural Parameters | Content
%
% Run this once when creating a new model configuration.  After running,
% populate IO_Data and Trade_Flows manually (or via update_data_excel.m).

%% Prologue
clearvars;
sPathWD = pwd();

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
run(fullfile(sThisFolder, 'define_sheets_calibration.m'));

sExcelFileName = [pwd() '\ExcelFiles\' sWorkBookName];
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
                rngObj.Formula = strSheet(icosheet).Categories(2:end, icocol);
            else
                dat_range = [get_excel_column(icocol) '1:' get_excel_column(icocol) num2str(inbrow)];
                rngObj = exlSheet1.Range(dat_range);
                rngObj.Value = strSheet(icosheet).Categories(:, icocol);
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
