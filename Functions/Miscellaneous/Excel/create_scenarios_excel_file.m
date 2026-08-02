% create_scenarios_excel_file  —  Creates ModelScenarios*.xlsx
%
% Sheets: Scenario (template) | Content
%
% To add a new scenario sheet (EE, NZ, RTS, ...):
%   1. Duplicate an existing scenario sheet in Excel and rename it, OR
%   2. Add another strSheet block in define_sheets_scenarios.m before
%      the Content block and re-run this script.

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
sWorkBookName = ['ModelScenarios' num2str(inbsubsectors_p) 'Sectorsand' num2str(inbregions_p) 'Regions' sversion '.xlsx'];

addpath(genpath(fullfile(sPathWD, 'Functions')))
sThisFolder = fileparts(mfilename('fullpath'));
run(fullfile(sThisFolder, 'define_sheets_scenarios.m'));

sExcelFileName = [pwd() '\ExcelFiles\' sWorkBookName];
if exist(sExcelFileName, 'file')
    delete(sExcelFileName)
end
writecell({' '}, sExcelFileName);

% Put Content sheet first
strSheettemp = strSheet;
strSheet(1) = strSheettemp(end);
strSheet(2:end) = strSheettemp(1:end-1);

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
        if icorow == 1
            rngObj.Interior.ColorIndex = 48;
        end
    end
    exl.Cells.Select;
    exl.Cells.EntireColumn.AutoFit;
end
exlFile.Save
exl.Quit
exl.release
