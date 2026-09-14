% update_scenario_sheets_from_path_definition  Copy scenario sheets from the
% path-definition workbook back into the runnable scenario workbook.
%
% Run from the repository root:
%   run('scripts/maintenance/update_scenario_sheets_from_path_definition.m')
%
% This is the companion to create_scenario_path_definition_templates.m.
% It copies the current EE, Finance, and NZ sheets from
% ExcelFiles/ScenarioPathDefinition.xlsx into
% ExcelFiles/ModelScenarios5Sectorsand1Regions_replication.xlsx.
%
% Target workbook: the _replication suffix matches RunSimulations.m's default
% sSensitivity = '_replication' (i.e. the workbook actually read by simulation
% runs unless DGE_SCENARIO_GROUPS/sSensitivity is overridden). Keep this sheet
% list in sync with that workbook's actual tabs — see
% docs/scenario_notes/workbook_creation_procedure.md.

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

sourceWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ScenarioPathDefinition.xlsx');
targetWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions_replication.xlsx');

if ~isfile(sourceWorkbook)
    error('update_scenario_sheets_from_path_definition:SourceNotFound', ...
        'Path-definition workbook not found:\n  %s', sourceWorkbook);
end
if ~isfile(targetWorkbook)
    error('update_scenario_sheets_from_path_definition:TargetNotFound', ...
        'Scenario workbook not found:\n  %s', targetWorkbook);
end

scenarioSheets = {
    'EE_PDP8_ref'
    'EE_PDP8_ref_NoBESS'
    'EE_Dir10_full'
    'EE_Dir10_full_NoBESS'
    'EE_RTS_prerev_95GW'
    'EE_RTS_prerev_95GW_NoBESS'
    'EE_Dir10_RTSslice'
    'EE_Dir10_RTSslice_NoBESS'
    'EE_Dir10_EEonly'
    'EE_Dir10_EEonly_NoBESS'
    'PDP8_GF_A'
    'PDP8_GF_B'
    'PDP8_GF_C'
    'NZ_GF_A'
    'NZ_GF_B'
    'NZ_GF_C'
    'NZ_constEE'
    'NZ_constInt'
    'NZ_constEEInt'
    'NZ_subsidy'
    'NZ_Dir10_full'
    'NZ_Dir10_full_NoBESS'
    'NZ_RTS_prerev_95GW'
    'NZ_RTS_prerev_95GW_NoBESS'
    'ImportShock_Fossil2_P10'
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