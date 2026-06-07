% CreateModelWorkbooks  Build baseline/scenario/calibration workbooks.
%
% Run from the repository root:
%   run('scripts/maintenance/CreateModelWorkbooks.m')

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

scriptsToRun = {
    fullfile(repoRoot, 'Functions', 'Miscellaneous', 'Excel', 'create_baseline_excel_file.m')
    fullfile(repoRoot, 'Functions', 'Miscellaneous', 'Excel', 'create_calibration_excel_file.m')
    fullfile(repoRoot, 'Functions', 'Miscellaneous', 'Excel', 'create_scenarios_excel_file.m')
};

for iScript = 1:numel(scriptsToRun)
    fprintf('Running %s\n', scriptsToRun{iScript});
    run(scriptsToRun{iScript});
end

expectedFiles = {
    fullfile(repoRoot, 'ExcelFiles', 'ModelBaseline5Sectorsand1Regions.xlsx')
    fullfile(repoRoot, 'ExcelFiles', 'ModelCalibration5Sectorsand1Regions.xlsx')
    fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions.xlsx')
};

for iFile = 1:numel(expectedFiles)
    if ~isfile(expectedFiles{iFile})
        error('CreateModelWorkbooks:MissingOutput', ...
            'Expected workbook not found after generation:\n  %s', expectedFiles{iFile});
    end
end

fprintf('\nCreateModelWorkbooks complete.\n');
for iFile = 1:numel(expectedFiles)
    fprintf('  %s\n', expectedFiles{iFile});
end
