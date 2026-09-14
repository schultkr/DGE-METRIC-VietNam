% create_scenario_path_definition_templates  Build path-definition templates for
% Baseline, EE, Finance, and NZ scenario families.
%
% Run from the repository root:
%   run('scripts/maintenance/create_scenario_path_definition_templates.m')
%
% Output:
%   ExcelFiles/ScenarioPathDefinition.xlsx
%     - Baseline sheet is created by the existing Baseline template writer.
%     - EE, Finance, and NZ sheets are cloned from the current scenario workbook
%       so the path-definition workbook reproduces the current scenario layouts
%       exactly.
%
% Source workbook: ModelScenarios5Sectorsand1Regions_replication.xlsx, matching
% RunSimulations.m's default sSensitivity = '_replication' (i.e. the workbook
% actually read by simulation runs unless DGE_SCENARIO_GROUPS/sSensitivity is
% overridden). Keep this sheet list in sync with that workbook's actual tabs —
% see docs/scenario_notes/workbook_creation_procedure.md.

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

sourceWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions_replication.xlsx');
targetWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ScenarioPathDefinition.xlsx');

if ~isfile(sourceWorkbook)
    error('create_scenario_path_definition_templates:SourceNotFound', ...
        'Current scenario workbook not found:\n  %s', sourceWorkbook);
end

run(fullfile(repoRoot, 'scripts', 'maintenance', 'create_baseline_path_definition_template.m'));

eeSheets = {
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
};

financeSheets = {
    'PDP8_GF_A'
    'PDP8_GF_B'
    'PDP8_GF_C'
    'NZ_GF_A'
    'NZ_GF_B'
    'NZ_GF_C'
};

nzOtherSheets = {
    'NZ_constEE'
    'NZ_constInt'
    'NZ_constEEInt'
    'NZ_subsidy'
    'NZ_Dir10_full'
    'NZ_Dir10_full_NoBESS'
    'NZ_RTS_prerev_95GW'
    'NZ_RTS_prerev_95GW_NoBESS'
    'ImportShock_Fossil2_P10'
};

scenarioSheets = [eeSheets; financeSheets; nzOtherSheets; {'NZ'}];

availableSheets = cellstr(sheetnames(sourceWorkbook));
for iSheet = 1:numel(scenarioSheets)
    sheetName = scenarioSheets{iSheet};
    if ~ismember(sheetName, availableSheets)
        error('create_scenario_path_definition_templates:MissingSourceSheet', ...
            'Sheet "%s" was not found in:\n  %s', sheetName, sourceWorkbook);
    end
    clone_sheet_values(sourceWorkbook, targetWorkbook, sheetName);
end

fprintf('\nCreateScenarioPathDefinitionTemplates complete.\n');
fprintf('  Baseline template:  created by create_baseline_path_definition_template.m\n');
fprintf('  EE sheets cloned:   %s\n', strjoin(eeSheets, ', '));
fprintf('  Finance sheets:     %s\n', strjoin(financeSheets, ', '));
fprintf('  NZ sensitivity/other sheets: %s\n', strjoin(nzOtherSheets, ', '));
fprintf('  NZ sheet cloned:    NZ\n');
fprintf('  Source workbook:    %s\n', sourceWorkbook);
fprintf('  Target workbook:    %s\n', targetWorkbook);

function clone_sheet_values(sourceWorkbook, targetWorkbook, sheetName)
data = readcell(sourceWorkbook, 'Sheet', sheetName);
if isempty(data)
    return
end

writecell(data, targetWorkbook, 'Sheet', sheetName, 'Range', 'A1');
end