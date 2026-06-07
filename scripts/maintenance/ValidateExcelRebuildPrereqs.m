function report = ValidateExcelRebuildPrereqs(mode)
% ValidateExcelRebuildPrereqs  Preflight checks for Excel rebuild workflows.
%
% Usage (from repository root):
%   setup_paths
%   ValidateExcelRebuildPrereqs                 % default: template-only
%   ValidateExcelRebuildPrereqs('template-only')
%   ValidateExcelRebuildPrereqs('full-reference')
%
% Modes:
%   template-only  : checks files needed to generate baseline/calibration/
%                    scenario workbook templates from in-repo scripts.
%   full-reference : includes template-only checks plus additional scripts
%                    and processed ExpertClean inputs used in the reference
%                    DGE-METRIC flow.

if nargin < 1 || isempty(mode)
    mode = 'template-only';
end

if ~(ischar(mode) || isstring(mode))
    error('ValidateExcelRebuildPrereqs:InvalidModeType', ...
        'Mode must be a character vector or string scalar.');
end

mode = lower(strtrim(char(mode)));
if ~ismember(mode, {'template-only', 'full-reference'})
    error('ValidateExcelRebuildPrereqs:InvalidMode', ...
        'Unknown mode "%s". Use "template-only" or "full-reference".', mode);
end

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));

rows = template_only_rows();
if strcmp(mode, 'full-reference')
    rows = [rows; full_reference_rows()]; %#ok<AGROW>
end

nRows = size(rows, 1);
existsFlags = false(nRows, 1);

fprintf('\n=== ValidateExcelRebuildPrereqs (%s) ===\n', mode);
fprintf('Repository root: %s\n\n', repoRoot);

for iRow = 1:nRows
    relPath = rows{iRow, 1};
    category = rows{iRow, 2};
    note = rows{iRow, 3};
    absPath = fullfile(repoRoot, relPath);
    absPath = strrep(absPath, '/', filesep);

    existsNow = isfile(absPath) || isfolder(absPath);
    existsFlags(iRow) = existsNow;

    if existsNow
        status = 'OK     ';
    else
        status = 'MISSING';
    end

    fprintf('[%s] %-18s %-70s %s\n', status, category, relPath, note);
end

missingRows = find(~existsFlags);

report = struct();
report.Mode = mode;
report.RepositoryRoot = repoRoot;
report.RequiredCount = nRows;
report.MissingCount = numel(missingRows);
report.AllPresent = isempty(missingRows);
report.MissingPaths = rows(missingRows, 1);

fprintf('\n--- Summary ---\n');
fprintf('Required checks : %d\n', report.RequiredCount);
fprintf('Missing         : %d\n', report.MissingCount);

if report.AllPresent
    fprintf('Result          : PASS\n');
else
    fprintf('Result          : FAIL\n');
    fprintf('Missing paths:\n');
    for iMiss = 1:numel(missingRows)
        fprintf('  - %s\n', rows{missingRows(iMiss), 1});
    end
end

if strcmp(mode, 'template-only')
    if report.AllPresent
        fprintf('\nTemplate-only rebuild prerequisites are complete.\n');
    else
        fprintf('\nTemplate-only prerequisites are incomplete; fix missing files before running CreateModelWorkbooks.\n');
    end
else
    if report.AllPresent
        fprintf('\nFull-reference parity prerequisites are complete.\n');
    else
        fprintf(['\nFull-reference parity prerequisites are incomplete in this repository.\n' ...
                 'Use scripts/maintenance/REBUILD_GAP_CHECKLIST.md as transfer checklist from DGE-METRIC.\n']);
    end
end

end

function rows = template_only_rows()
rows = {
    'setup_paths.m', 'core', 'MATLAB path bootstrap'
    'scripts/maintenance/CreateModelWorkbooks.m', 'maintenance', 'Top-level workbook builder'
    'Functions/Miscellaneous/Excel/create_baseline_excel_file.m', 'excel-builder', 'Baseline workbook generator'
    'Functions/Miscellaneous/Excel/create_calibration_excel_file.m', 'excel-builder', 'Calibration workbook generator'
    'Functions/Miscellaneous/Excel/create_scenarios_excel_file.m', 'excel-builder', 'Scenarios workbook generator'
    'Functions/Miscellaneous/Excel/define_sheets_baseline.m', 'excel-helper', 'Baseline sheet definitions'
    'Functions/Miscellaneous/Excel/define_sheets_calibration.m', 'excel-helper', 'Calibration sheet definitions'
    'Functions/Miscellaneous/Excel/define_sheets_scenarios.m', 'excel-helper', 'Scenario sheet definitions'
    'Functions/Miscellaneous/Excel/add_sub_sheet.m', 'excel-helper', 'Sheet-construction helper'
    'Functions/Miscellaneous/Excel/define_sheets_input_file_help1.m', 'excel-helper', 'Shared definition helper'
    'Functions/Miscellaneous/Excel/get_excel_column.m', 'excel-helper', 'Excel column-address helper'
    'Functions/Miscellaneous/Excel/update_data_excel.m', 'excel-helper', 'Calibration propagation utility'
    };
end

function rows = full_reference_rows()
rows = {
    'scripts/maintenance/UpdateBaselineSheet.m', 'reference-script', 'Baseline hardcopy refresh wrapper'
    'scripts/maintenance/UpdateNZSheet.m', 'reference-script', 'NZ scenario refresh wrapper'
    'scripts/maintenance/CreateBaselineFromUserInputFile.m', 'reference-script', 'Build baseline from user input'
    'scripts/maintenance/CreateBaselinePathDefinitionTemplate.m', 'reference-script', 'Create baseline path template'
    'scripts/maintenance/CreateEEScenariosFromExpertInputs.m', 'reference-script', 'Create EE scenarios from expert inputs'
    'scripts/maintenance/PrepareExpertInputsForSheetCreation.m', 'reference-script', 'Normalize expert input files'
    'scripts/maintenance/CreateGreenFinanceScenarios.m', 'reference-script', 'Create finance scenarios'
    'scripts/maintenance/build_user_inputs_sheet.py', 'reference-script', 'Python user-input sheet helper'
    'ExcelFiles/Input/ExpertClean/Directive10_RTS_EE.csv', 'seed-input', 'Clean expert CSV'
    'ExcelFiles/Input/ExpertClean/EE_PDP8_reference.csv', 'seed-input', 'Clean expert CSV'
    'ExcelFiles/Input/ExpertClean/IO_manifest.csv', 'seed-input', 'Clean expert manifest'
    'ExcelFiles/Input/ExpertClean/PDP8_PV_EV_BESS.csv', 'seed-input', 'Clean expert CSV'
    'ExcelFiles/Input/ExpertClean/RTS_PDP8_revised_reference.csv', 'seed-input', 'Clean expert CSV'
    };
end