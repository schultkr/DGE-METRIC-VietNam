% update_scenario_sheets_from_path_definition  Copy scenario sheets from the
% path-definition workbook back into the runnable scenario workbook.
%
% Run from the repository root:
%   run('scripts/maintenance/update_scenario_sheets_from_path_definition.m')
%
% This is the companion to create_scenario_path_definition_templates.m.
% It copies the current EE, Finance, and NZ sheets from
% ExcelFiles/ScenarioPathDefinition.xlsx into
% ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx.

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

sourceWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ScenarioPathDefinition.xlsx');
targetWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions.xlsx');

if ~isfile(sourceWorkbook)
    error('update_scenario_sheets_from_path_definition:SourceNotFound', ...
        'Path-definition workbook not found:\n  %s', sourceWorkbook);
end
if ~isfile(targetWorkbook)
    error('update_scenario_sheets_from_path_definition:TargetNotFound', ...
        'Scenario workbook not found:\n  %s', targetWorkbook);
end

scenarioSheets = {
    'EE_PDP8'
    'EE_Directive10'
    'EE_PDP8_PV_BESS'
    'EE_Directive10_NoBESS'
    'EE_PDP8_PV_BESS_NoBESS'
    'PDP8_GF_A'
    'PDP8_GF_B'
    'PDP8_GF_C'
    'NZ_GF_A'
    'NZ_GF_B'
    'NZ_GF_C'
    'NZ'
};

availableSheets = cellstr(sheetnames(sourceWorkbook));
for iSheet = 1:numel(scenarioSheets)
    sheetName = scenarioSheets{iSheet};
    if ~ismember(sheetName, availableSheets)
        error('update_scenario_sheets_from_path_definition:MissingSourceSheet', ...
            'Sheet "%s" was not found in:\n  %s', sheetName, sourceWorkbook);
    end
    clone_sheet_values(sourceWorkbook, targetWorkbook, sheetName);
end

fprintf('\nUpdateScenarioSheetsFromPathDefinition complete.\n');
fprintf('  Source: %s\n', sourceWorkbook);
fprintf('  Target: %s\n', targetWorkbook);

function clone_sheet_values(sourceWorkbook, targetWorkbook, sheetName)
data = readcell(sourceWorkbook, 'Sheet', sheetName);
if isempty(data)
    return
end

writecell(data, targetWorkbook, 'Sheet', sheetName, 'Range', 'A1');
end