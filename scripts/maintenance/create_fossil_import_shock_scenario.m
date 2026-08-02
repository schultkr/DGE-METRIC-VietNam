% create_fossil_import_shock_scenario  Create a temporary fossil import shock
% scenario with a 10% import-amount reduction in period 10 for subsector 2.

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

baselineWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelBaseline5Sectorsand1Regions.xlsx');
scenarioWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions.xlsx');
sheetName = 'ImportShock_Fossil2_P10';

if ~isfile(baselineWorkbook)
    error('create_fossil_import_shock_scenario:BaselineNotFound', ...
        'Baseline workbook not found:\n  %s', baselineWorkbook);
end
if ~isfile(scenarioWorkbook)
    error('create_fossil_import_shock_scenario:ScenarioWorkbookNotFound', ...
        'Scenario workbook not found:\n  %s', scenarioWorkbook);
end

timeCol = readmatrix(baselineWorkbook, 'Sheet', 'Baseline', 'Range', 'A:A');
timeCol = timeCol(isfinite(timeCol));
if isempty(timeCol)
    error('create_fossil_import_shock_scenario:MissingTimeColumn', ...
        'Could not read a usable Time column from the Baseline sheet.');
end

nPeriods = numel(timeCol);
timeVec = timeCol(:);

shockPeriod = 10;
shockIndex = find(timeVec == shockPeriod, 1, 'first');
if isempty(shockIndex)
    error('create_fossil_import_shock_scenario:ShockPeriodMissing', ...
        'Shock period %d is not present in the Baseline Time column.', shockPeriod);
end

headers = {'Time', 'exo_M_2', 'exo_lMAmount_2', 'exo_MAmt_2'};
data = [ ...
    timeVec, ...
    zeros(nPeriods, 1), ...
    zeros(nPeriods, 1), ...
    zeros(nPeriods, 1) ...
];

data(shockIndex, 3) = 1;
data(shockIndex, 4) = log(0.9);

writecell(headers, scenarioWorkbook, 'Sheet', sheetName, 'Range', 'A1');
writematrix(data, scenarioWorkbook, 'Sheet', sheetName, 'Range', 'A2');

fprintf('\nCreateFossilImportShockScenario complete.\n');
fprintf('  Sheet: %s\n', sheetName);
fprintf('  Shock period: %d\n', shockPeriod);
fprintf('  Shock size: -10%% of fossil subsector 2 import amount\n');
