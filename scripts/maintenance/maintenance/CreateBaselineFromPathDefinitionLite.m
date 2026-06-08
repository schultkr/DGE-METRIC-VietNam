% CreateBaselineFromPathDefinitionLite
% Build core runnable Baseline growth paths from ScenarioPathDefinition only.
%
% Run from repository root:
%   run('scripts/maintenance/CreateBaselineFromPathDefinitionLite.m')
%
% Input workbook (only):
%   ExcelFiles/ScenarioPathDefinition.xlsx, sheet "Baseline"
%   - Years: row 9, columns E:AD
%   - Total GVA growth: row 10
%   - Sector VA shares: rows 12:16
%   - Total employment growth: row 22
%   - Sector employment shares: rows 24:28
%
% Output workbook/sheet:
%   ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx, sheet "Baseline"
%   - Writes gY_1_1..gY_5_1 and gN_1_1..gN_5_1 for years >= 2026

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

sourceWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ScenarioPathDefinition.xlsx');
targetWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelBaseline5Sectorsand1Regions.xlsx');
sourceSheet = 'Baseline';
targetSheet = 'Baseline';
targetStartYear = 2026;
sourceStartCol = 'E';
sourceEndCol = 'AD';

if ~isfile(sourceWorkbook)
    error('CreateBaselineFromPathDefinitionLite:SourceNotFound', ...
        'Source workbook not found:\n  %s', sourceWorkbook);
end
if ~isfile(targetWorkbook)
    error('CreateBaselineFromPathDefinitionLite:TargetNotFound', ...
        'Target workbook not found:\n  %s', targetWorkbook);
end

inputs = import_core_baseline_inputs(sourceWorkbook, sourceSheet, sourceStartCol, sourceEndCol);
[gY, yearsY] = compute_sector_growth_factors(inputs.gvaGrowth, inputs.vaShares, inputs.years, targetStartYear);
[gN, yearsN] = compute_sector_growth_factors(inputs.empGrowth, inputs.empShares, inputs.years, targetStartYear);
if ~isequal(yearsY, yearsN)
    error('CreateBaselineFromPathDefinitionLite:YearAlignmentMismatch', ...
        'GVA and employment growth year ranges are not aligned.');
end

yearsOut = yearsY;
write_core_growth_to_baseline(targetWorkbook, targetSheet, yearsOut, gY, gN);

fprintf('\nCreateBaselineFromPathDefinitionLite complete.\n');
fprintf('  Source workbook: %s\n', sourceWorkbook);
fprintf('  Source sheet:    %s\n', sourceSheet);
fprintf('  Target workbook: %s\n', targetWorkbook);
fprintf('  Target sheet:    %s\n', targetSheet);
fprintf('  Years written:   %d:%d (%d rows)\n', yearsOut(1), yearsOut(end), numel(yearsOut));

function inputs = import_core_baseline_inputs(sourceWorkbook, sourceSheet, sourceStartCol, sourceEndCol)
yearHeader = readcell(sourceWorkbook, 'Sheet', sourceSheet, ...
    'Range', [sourceStartCol '9:' sourceEndCol '9']);
years = parse_year_row(yearHeader);

gvaGrowth = readmatrix(sourceWorkbook, 'Sheet', sourceSheet, ...
    'Range', [sourceStartCol '10:' sourceEndCol '10']);
vaShares = readmatrix(sourceWorkbook, 'Sheet', sourceSheet, ...
    'Range', [sourceStartCol '12:' sourceEndCol '16']);
empGrowth = readmatrix(sourceWorkbook, 'Sheet', sourceSheet, ...
    'Range', [sourceStartCol '22:' sourceEndCol '22']);
empShares = readmatrix(sourceWorkbook, 'Sheet', sourceSheet, ...
    'Range', [sourceStartCol '24:' sourceEndCol '28']);

nYears = numel(years);
if numel(gvaGrowth) ~= nYears || numel(empGrowth) ~= nYears || ...
        size(vaShares, 2) ~= nYears || size(empShares, 2) ~= nYears
    error('CreateBaselineFromPathDefinitionLite:UnexpectedSourceLayout', ...
        'Unexpected Baseline layout in workbook:\n  %s', sourceWorkbook);
end

inputs = struct();
inputs.years = reshape(years, 1, []);
inputs.gvaGrowth = reshape(gvaGrowth, 1, []);
inputs.vaShares = vaShares;
inputs.empGrowth = reshape(empGrowth, 1, []);
inputs.empShares = empShares;
end

function years = parse_year_row(yearHeader)
years = nan(1, numel(yearHeader));
for i = 1:numel(yearHeader)
    v = yearHeader{i};
    if isa(v, 'datetime')
        years(i) = year(v);
    elseif isnumeric(v)
        if ~isempty(v) && ~isnan(v)
            if v > 1900 && v < 3000
                years(i) = v;
            else
                try
                    years(i) = year(datetime(v, 'ConvertFrom', 'excel'));
                catch
                end
            end
        end
    elseif ischar(v) || isstring(v)
        s = strtrim(string(v));
        n = str2double(s);
        if ~isnan(n) && n > 1900 && n < 3000
            years(i) = n;
        else
            tok = regexp(char(s), '(19|20)\d{2}', 'match', 'once');
            if ~isempty(tok)
                years(i) = str2double(tok);
            end
        end
    end
end

if any(isnan(years))
    iValid = find(~isnan(years), 1, 'first');
    if isempty(iValid)
        startYear = 2025;
    else
        startYear = years(iValid) - (iValid - 1);
    end
    years = startYear + (0:(numel(yearHeader) - 1));
    warning('CreateBaselineFromPathDefinitionLite:YearHeaderInferred', ...
        ['Could not parse all year headers in Baseline row 9 (E:AD). ' ...
         'Using inferred sequence %d:%d.'], years(1), years(end));
end
end

function [growth, yearsOut] = compute_sector_growth_factors(totalGrowth, shares, years, targetStartYear)
if size(shares, 2) ~= numel(totalGrowth) || numel(years) ~= numel(totalGrowth)
    error('CreateBaselineFromPathDefinitionLite:GrowthShareLengthMismatch', ...
        ['Share and year path lengths must match growth path length. ' ...
         'Got shares=%d, years=%d, growth=%d.'], ...
        size(shares, 2), numel(years), numel(totalGrowth));
end

totalGrowthFactors = normalize_growth_to_factors(totalGrowth);
if any(totalGrowthFactors <= 0)
    error('CreateBaselineFromPathDefinitionLite:NonPositiveGrowth', ...
        ['Growth input implies nonpositive factors. Provide either factors (>0), ' ...
         'decimal rates (e.g., 0.02), or percent rates (e.g., 2 for 2%%).']);
end

if any(shares(:) <= 0)
    error('CreateBaselineFromPathDefinitionLite:NonPositiveShare', ...
        'All sector shares must be strictly positive to compute sector growth rates.');
end

shareSums = sum(shares, 1);
if any(abs(shareSums - 1) > 1e-4)
    error('CreateBaselineFromPathDefinitionLite:InvalidShares', ...
        'Sector shares must sum to 1 in each year.');
end

idxStart = find(years >= targetStartYear, 1, 'first');
if isempty(idxStart)
    error('CreateBaselineFromPathDefinitionLite:NoYearsAfterStart', ...
        'No source years >= %d were found in Baseline.', targetStartYear);
end
if idxStart == 1
    error('CreateBaselineFromPathDefinitionLite:MissingPreStartYear', ...
        ['Input must contain one year before the model start year (%d) ' ...
         'to compute growth from actual t-1 shares.'], targetStartYear);
end

idxOut = idxStart:numel(years);
prevIdx = (idxStart - 1):(numel(years) - 1);
growth = shares(:, idxOut) ./ shares(:, prevIdx);
growth = growth .* repmat(reshape(totalGrowthFactors(idxOut), 1, []), size(shares, 1), 1);
yearsOut = years(idxOut);
end

function growthFactors = normalize_growth_to_factors(totalGrowth)
if isempty(totalGrowth)
    growthFactors = totalGrowth;
    return
end

v = reshape(totalGrowth, 1, []);
vMax = max(v);
vMin = min(v);

if vMax < 0.5
    growthFactors = 1 + v;
elseif vMax > 2.5 || vMin <= 0
    growthFactors = v;
    isPercent = abs(v) >= 1;
    growthFactors(isPercent) = 1 + v(isPercent) ./ 100;
    growthFactors(~isPercent) = 1 + v(~isPercent);
else
    growthFactors = v;
end
end

function write_core_growth_to_baseline(targetWorkbook, targetSheet, yearsOut, gY, gN)
headers = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
if isempty(headers)
    error('CreateBaselineFromPathDefinitionLite:MissingHeaders', ...
        'Sheet "%s" has no header row in workbook:\n  %s', targetSheet, targetWorkbook);
end

iTime = find(strcmpi(headers, 'Time'), 1);
if isempty(iTime)
    error('CreateBaselineFromPathDefinitionLite:MissingTimeColumn', ...
        'Sheet "%s" is missing required column "Time".', targetSheet);
end

nYears = numel(yearsOut);
colTime = excel_col_name(iTime);
writematrix(yearsOut(:), targetWorkbook, 'Sheet', targetSheet, ...
    'Range', sprintf('%s2:%s%d', colTime, colTime, nYears + 1));

nSub = size(gY, 1);
for iSub = 1:nSub
    gYName = sprintf('gY_%d_1', iSub);
    gNName = sprintf('gN_%d_1', iSub);

    iColGY = find(strcmp(headers, gYName), 1);
    iColGN = find(strcmp(headers, gNName), 1);
    if isempty(iColGY) || isempty(iColGN)
        error('CreateBaselineFromPathDefinitionLite:MissingGrowthColumn', ...
            'Sheet "%s" missing required column(s) "%s" or "%s".', ...
            targetSheet, gYName, gNName);
    end

    colGY = excel_col_name(iColGY);
    colGN = excel_col_name(iColGN);

    writematrix(gY(iSub, :)', targetWorkbook, 'Sheet', targetSheet, ...
        'Range', sprintf('%s2:%s%d', colGY, colGY, nYears + 1));
    writematrix(gN(iSub, :)', targetWorkbook, 'Sheet', targetSheet, ...
        'Range', sprintf('%s2:%s%d', colGN, colGN, nYears + 1));
end
end

function col = excel_col_name(iCol)
if iCol < 1
    error('CreateBaselineFromPathDefinitionLite:InvalidColumnIndex', ...
        'Excel column index must be >= 1.');
end

letters = '';
while iCol > 0
    remIdx = mod(iCol - 1, 26);
    letters = [char(65 + remIdx) letters]; %#ok<AGROW>
    iCol = floor((iCol - 1) / 26);
end
col = letters;
end
