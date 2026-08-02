% update_baseline_sheet  One-command refresh for the runnable Baseline sheet.
%
% Run from the repository root:
%   run('scripts/maintenance/update_baseline_sheet.m')
%
% This updates ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx by
% recalculating Baseline_Implied and copying its values into Baseline.
% If Baseline_Implied is missing, update_baseline_excel bootstraps the
% split workbook from the legacy combined workbook once.

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd));
cd(repoRoot);
setup_paths();

summary = update_baseline_excel(); %#ok<NASGU>
