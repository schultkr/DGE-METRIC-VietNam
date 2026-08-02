% define_sheets_scenarios  —  Script called by create_scenarios_excel_file.m
% Defines strSheet for the ModelScenarios workbook containing:
%   Scenario (template) | Content
%
% Add further scenario sheets (EE, NZ, RTS, ...) by duplicating the
% Scenario sheet block below before the Content block.

%% Define Scenario template sheet
icosheet = 0;

icosheet = icosheet + 1;
strSheet(icosheet).Name = 'Scenario';
strSheet(icosheet).Description = 'a sheet for a specific scenario you want to run';
temp = cellfun(@(x) arrayfun(@(y) ['exo_' x '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), casClimateVarsRegional, 'UniformOutput', false);
casClimExoReg = [temp{:}];
temp = cellfun(@(x) ['exo_' x], casClimateVarsNational, 'UniformOutput', false);
casClimExoNat = [temp{:}]; %#ok<NASGU>

casCategoriesHeader = [{'Time'}, {'exo_PoP'}, {'exo_E'}, {'exo_PE'}, {'exo_DH'},{'exo_G_A_DH'}];
casData = arrayfun(@(x) num2str(x), [(2:100)' zeros(99, size(casCategoriesHeader,2)-1)],'UniformOutput', false);
casCategories = [casCategoriesHeader; casData];
strSheet(icosheet).Categories = casCategories;

%% Define Content Sheet
icosheet = icosheet + 1;
casSheets = cellfun(@(x) ['=HYPERLINK("#''' x '''!A1";"' x '")'], {strSheet.Name}', 'UniformOutput', false);
casSheetDescriptions = {strSheet.Description}';
strSheet(icosheet).Name = 'Content';
casContentSheet = [{'Sheets', '', ''};...
                  [casSheets casSheetDescriptions, repmat({''}, length(casSheets),1)];...
                  {'Regions', '', ''};...
                  [arrayfun(@(x) num2str(x), 1:inbregions_p, 'UniformOutput', false)' , casRegions repmat({''}, length(casRegions),1)];...
                  {'Sectors', '', ''};...
                  [arrayfun(@(x) num2str(x), 1:inbsubsectors_p, 'UniformOutput', false)' , casSubSectors repmat({''}, length(casSubSectors),1)];...
                  ];
strSheet(icosheet).Categories = casContentSheet;
