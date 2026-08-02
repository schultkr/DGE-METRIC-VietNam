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

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

sourceWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions.xlsx');
targetWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ScenarioPathDefinition.xlsx');

if ~isfile(sourceWorkbook)
    error('create_scenario_path_definition_templates:SourceNotFound', ...
        'Current scenario workbook not found:\n  %s', sourceWorkbook);
end

run(fullfile(repoRoot, 'scripts', 'maintenance', 'create_baseline_path_definition_template.m'));

eeSheets = {
    'EE_PDP8'
    'EE_Directive10'
    'EE_PDP8_PV_BESS'
    'EE_Directive10_NoBESS'
    'EE_PDP8_PV_BESS_NoBESS'
};

financeSheets = {
    'PDP8_GF_A'
    'PDP8_GF_B'
    'PDP8_GF_C'
    'NZ_GF_A'
    'NZ_GF_B'
    'NZ_GF_C'
};

scenarioSheets = [eeSheets; financeSheets; {'NZ'}];

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
fprintf('  NZ sheet cloned:    NZ\n');
fprintf('  Target workbook:    %s\n', targetWorkbook);

function clone_sheet_values(sourceWorkbook, targetWorkbook, sheetName)
data = readcell(sourceWorkbook, 'Sheet', sheetName);
if isempty(data)
    return
end

writecell(data, targetWorkbook, 'Sheet', sheetName, 'Range', 'A1');
end