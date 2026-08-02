% prepare_expert_inputs_for_sheet_creation
% Build clean, format-free CSV inputs for baseline/scenario sheet creation.
%
% Run from repository root:
%   run('scripts/maintenance/prepare_expert_inputs_for_sheet_creation.m')

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);

preferredWorkbook = fullfile(repoRoot, 'ExcelFiles', 'PDP8', 'Vietnam_EnergyExpert_ScenarioInputs - Adjust_2505.xlsx');
fallbackWorkbook = fullfile(repoRoot, 'ExcelFiles', 'Vietnam_EnergyExpert_ScenarioInputs.xlsx');
if isfile(preferredWorkbook)
    expertWorkbook = preferredWorkbook;
else
    expertWorkbook = fallbackWorkbook;
end

assert(isfile(expertWorkbook), 'prepare_expert_inputs_for_sheet_creation:MissingWorkbook', ...
    'Expert workbook not found:\n  %s', expertWorkbook);

outDir = fullfile(repoRoot, 'ExcelFiles', 'Input', 'ExpertClean');
if ~isfolder(outDir)
    mkdir(outDir);
end

useRevisedPDP8HighAsReference = true;

scenarioSheets = {
    'EE_PDP8_reference'
    'Directive10_RTS_EE'
    'PDP8_PV_EV_BESS'
    };

requiredCols = {
    'Year'
    'Industry_EE_Saving_pct'
    'Services_EE_Saving_pct'
    'Industry_EE_Investment_USDm'
    'Services_EE_Investment_USDm'
    'PV_Integration_Gain_pct'
    'BESS_Annual_Investment_USDbn'
    'RTS_Industry_Investment_USDm'
    'RTS_Services_Investment_USDm'
    'RTS_Household_Investment_USDm'
    };

manifestRecords = {};

for i = 1:numel(scenarioSheets)
    sh = scenarioSheets{i};
    t = extract_clean_table(expertWorkbook, sh, requiredCols);
    outFile = fullfile(outDir, sh + ".csv");
    writetable(t, outFile);

    manifestRecords(end + 1, :) = { ...
        'scenario_input', ...
        sh, ...
        outFile, ...
        'create_ee_scenarios_from_expert_inputs', ...
        strjoin(requiredCols, ';')}; %#ok<AGROW>

    fprintf('Wrote clean scenario input: %s\n', outFile);
end

% Build clean RTS reference path for baseline script.
sheetRTS = 'PDP8_revised';
raw = readcell(expertWorkbook, 'Sheet', sheetRTS);
[headers, dataRows] = split_header_and_data(raw, 'Year');

colYear = find_header_index(headers, 'Year');
colCapBase = find_header_index(headers, 'RTS_Capacity_GW');
colCapHigh = find_header_index(headers, 'Check PDP8 - High scenario');
colGen = find_header_index(headers, 'RTS_Generation_TWh');
colCF = find_header_index(headers, 'RTS_CapacityFactor');

assert(~isempty(colYear) && ~isempty(colCapBase), ...
    'prepare_expert_inputs_for_sheet_creation:MissingRTSColumns', ...
    'PDP8_revised must contain Year and RTS_Capacity_GW.');

if useRevisedPDP8HighAsReference && ~isempty(colCapHigh)
    capCol = colCapHigh;
    sourceCapacityColumn = "Check PDP8 - High scenario";
else
    capCol = colCapBase;
    sourceCapacityColumn = "RTS_Capacity_GW";
end

years = as_numeric(dataRows(:, colYear));
capGW = as_numeric(dataRows(:, capCol));
capBaseGW = as_numeric(dataRows(:, colCapBase));
cf = [];
if ~isempty(colCF)
    cf = as_numeric(dataRows(:, colCF));
end

% Fill sparse high-path years by linear interpolation/extrapolation only.
if any(~isfinite(capGW))
    missingCap = ~isfinite(capGW);
    validPts = isfinite(years) & isfinite(capGW);
    if any(missingCap)
        if sum(validPts) >= 2
            capGW(missingCap) = interp1(years(validPts), capGW(validPts), years(missingCap), 'linear', 'extrap');
        elseif sum(validPts) == 1
            capGW(missingCap) = capGW(find(validPts, 1, 'first'));
        end
    end
end

if useRevisedPDP8HighAsReference && ~isempty(cf)
    genTWh = capGW .* cf * 8.76;
elseif ~isempty(colGen)
    genTWh = as_numeric(dataRows(:, colGen));
else
    error('prepare_expert_inputs_for_sheet_creation:MissingGeneration', ...
        'Need RTS_Generation_TWh or RTS_CapacityFactor to construct generation path.');
end

isData = isfinite(years) & isfinite(capGW) & isfinite(genTWh);
tRTS = table( ...
    years(isData), ...
    capGW(isData), ...
    genTWh(isData), ...
    capBaseGW(isData), ...
    repmat(sourceCapacityColumn, sum(isData), 1), ...
    'VariableNames', {'Year', 'RTS_Capacity_GW', 'RTS_Generation_TWh', 'RTS_Capacity_GW_Base', 'Source_Capacity_Column'});

% Extend to cover the Baseline model's base year (2025) and terminal year
% (2051), which the raw expert sheet does not include. Convention matches
% the rest of the baseline/EE pipeline: backfill the base year from the
% first modeled year, and hold the terminal year at the last modeled value.
tRTS = sortrows(tRTS, 'Year');
firstRow = tRTS(1, :);
firstRow.Year = firstRow.Year - 1;
lastRow = tRTS(end, :);
lastRow.Year = lastRow.Year + 1;
tRTS = [firstRow; tRTS; lastRow];

outRTS = fullfile(outDir, 'RTS_PDP8_revised_reference.csv');
writetable(tRTS, outRTS);
manifestRecords(end + 1, :) = { ...
    'baseline_rts_reference', ...
    'PDP8_revised', ...
    outRTS, ...
    'create_baseline_from_user_input_file', ...
    'Year;RTS_Capacity_GW;RTS_Generation_TWh'}; %#ok<AGROW>

fprintf('Wrote clean RTS reference: %s\n', outRTS);

manifest = cell2table(manifestRecords, ...
    'VariableNames', {'io_type', 'source_sheet', 'clean_input_file', 'consumer_script', 'columns'});
manifestFile = fullfile(outDir, 'IO_manifest.csv');
writetable(manifest, manifestFile);

fprintf('\nPrepareExpertInputsForSheetCreation complete.\n');
fprintf('  Expert workbook: %s\n', expertWorkbook);
fprintf('  Clean input dir: %s\n', outDir);
fprintf('  IO manifest:     %s\n', manifestFile);

function t = extract_clean_table(workbookPath, sheetName, requiredCols)
raw = readcell(workbookPath, 'Sheet', sheetName);
[headers, dataRows] = split_header_and_data(raw, 'Year');

nRows = size(dataRows, 1);
t = table();
for iCol = 1:numel(requiredCols)
    colName = requiredCols{iCol};
    idx = find_header_index(headers, colName);
    vals = nan(nRows, 1);
    if ~isempty(idx)
        vals = as_numeric(dataRows(:, idx));
    end
    t.(matlab.lang.makeValidName(colName)) = vals;
end

isData = isfinite(t.Year);
t = t(isData, :);
end

function [headers, dataRows] = split_header_and_data(raw, headerKey)
hdrRow = find(cellfun(@(x) (ischar(x) || isstring(x)) && strcmpi(strtrim(string(x)), string(headerKey)), raw(:, 1)), 1, 'first');
if isempty(hdrRow)
    error('prepare_expert_inputs_for_sheet_creation:MissingHeader', ...
        'Could not find header row with key "%s".', headerKey);
end
headers = raw(hdrRow, :);
dataRows = raw((hdrRow + 1):end, :);
end

function idx = find_header_index(headers, key)
idx = find(cellfun(@(x) (ischar(x) || isstring(x)) && strcmpi(strtrim(string(x)), key), headers), 1, 'first');
end

function out = as_numeric(col)
out = nan(size(col));
for i = 1:numel(col)
    v = col{i};
    if isnumeric(v) && isscalar(v) && isfinite(v)
        out(i) = double(v);
    elseif isstring(v) || ischar(v)
        numVal = str2double(strtrim(string(v)));
        if isfinite(numVal)
            out(i) = numVal;
        end
    end
end
end