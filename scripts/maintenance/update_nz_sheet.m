% update_nz_sheet  Write NZ scenario paths from the definition workbook.
%
% Run from the repository root:
%   run('scripts/maintenance/update_nz_sheet.m')
%
% Generic behavior:
%   - Reads row definitions from ScenarioPathDefinition.xlsx (sheet NZ)
%   - Uses Import Key (column B) as target variable name
%   - Applies Conversion Rule (column C)
%   - Writes to ModelScenarios workbook sheet NZ
%   - Adds target columns automatically when missing

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

sourceWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ScenarioPathDefinition.xlsx');
targetWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions.xlsx');
srcSheet = 'NZ';
tgtSheet = 'NZ';

if ~isfile(sourceWorkbook)
    error('update_nz_sheet:SourceNotFound', 'Source not found:\n  %s', sourceWorkbook);
end
if ~isfile(targetWorkbook)
    error('update_nz_sheet:TargetNotFound', 'Target not found:\n  %s', targetWorkbook);
end

nzInputs = read_nz_inputs(sourceWorkbook, srcSheet);
write_nz_sheet(targetWorkbook, tgtSheet, nzInputs);

fprintf('\nUpdateNZSheet complete.\n');
fprintf('  Source: %s  [%s]\n', sourceWorkbook, srcSheet);
fprintf('  Target: %s  [%s]\n', targetWorkbook, tgtSheet);
fprintf('  Periods written: %d  (%d-%d)\n', numel(nzInputs.yearsOut), nzInputs.yearsOut(1), nzInputs.yearsOut(end));

function nzIn = read_nz_inputs(sourceWorkbook, srcSheet)
srcStartCol = 'E';
srcEndCol = 'AD';

yearHeader = readcell(sourceWorkbook, 'Sheet', srcSheet, 'Range', [srcStartCol '9:' srcEndCol '9']);
sourceYears = parse_year_header(yearHeader);

% Model periods are first year after base year onward.
targetStartYear = sourceYears(1) + 1;
[~, yearsOut] = trim_to_model_years(ones(1, numel(sourceYears)), sourceYears, targetStartYear);

nzIn = struct();
nzIn.yearsOut = yearsOut;
nzIn.rows = read_user_defined_rows(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, sourceYears, yearsOut);

requiredKey = 'exo_E_1';
hasRequired = any(strcmpi({nzIn.rows.importKey}, requiredKey));
if ~hasRequired
    error('update_nz_sheet:MissingRequiredInput', ...
        'Required NZ import key "%s" was not found in sheet %s.', requiredKey, srcSheet);
end
end

function write_nz_sheet(targetWorkbook, tgtSheet, nzIn)
nPeriods = numel(nzIn.yearsOut);
timeVec = (2:nPeriods + 1)';

headers = readcell(targetWorkbook, 'Sheet', tgtSheet, 'Range', '1:1');
[headers, ~] = ensure_nz_column_exists(targetWorkbook, tgtSheet, headers, 'Time', nPeriods, 'direct');
write_series_to_nz_column(targetWorkbook, tgtSheet, headers, 'Time', timeVec, nPeriods);

created = {};
for i = 1:numel(nzIn.rows)
    rowDef = nzIn.rows(i);
    [headers, wasCreated] = ensure_nz_column_exists(targetWorkbook, tgtSheet, headers, ...
        rowDef.importKey, nPeriods, rowDef.conversionRule);
    if wasCreated
        created{end + 1} = rowDef.importKey; %#ok<AGROW>
    end
    write_series_to_nz_column(targetWorkbook, tgtSheet, headers, rowDef.importKey, rowDef.series, nPeriods);
end

if ~isempty(created)
    fprintf('  NZ dynamic columns added: %s\n', strjoin(created, ', '));
end
end

function rowDefs = read_user_defined_rows(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, sourceYears, yearsOut)
meta = readcell(sourceWorkbook, 'Sheet', srcSheet, 'Range', 'A1:D200');
rowDefs = struct('rowNum', {}, 'importKey', {}, 'conversionRule', {}, 'series', {});

for r = 10:size(meta, 1)
    keyCell = meta{r, 2};
    if ~(ischar(keyCell) || isstring(keyCell))
        continue
    end

    key = strtrim(char(string(keyCell)));
    if isempty(key)
        continue
    end

    keyNorm = normalize_label_text(key);
    if strcmp(keyNorm, 'section header')
        continue
    end

    if ~(startsWith(lower(key), 'exo_') || startsWith(lower(key), 'idx_'))
        continue
    end

    ruleCell = meta{r, 3};
    if ischar(ruleCell) || isstring(ruleCell)
        rule = strtrim(char(string(ruleCell)));
    else
        rule = '';
    end

    raw = reshape(readmatrix(sourceWorkbook, 'Sheet', srcSheet, ...
        'Range', sprintf('%s%d:%s%d', srcStartCol, r, srcEndCol, r)), 1, []);
    if isempty(raw) || all(isnan(raw))
        continue
    end

    [trimmed, ~] = trim_to_model_years(raw, sourceYears, yearsOut(1));
    converted = apply_conversion_rule(trimmed, rule, key, r);

    rowDefs(end + 1) = struct( ...
        'rowNum', r, ...
        'importKey', key, ...
        'conversionRule', rule, ...
        'series', converted); %#ok<AGROW>
end
end

function converted = apply_conversion_rule(seriesRow, ruleText, importKey, rowNum)
if any(~isfinite(seriesRow))
    error('update_nz_sheet:InvalidPathValues', ...
        'Path %s (row %d) contains non-finite values.', importKey, rowNum);
end

ruleNorm = normalize_rule_text(ruleText);
if isempty(ruleNorm) || strcmp(ruleNorm, 'direct') || contains(ruleNorm, 'direct')
    converted = seriesRow;
    return
end

if contains(ruleNorm, 'binary') || contains(ruleNorm, 'value 0')
    if any(seriesRow < 0)
        error('update_nz_sheet:InvalidBinaryInput', ...
            'Binary rule for %s (row %d) does not allow negative values.', importKey, rowNum);
    end
    converted = double(seriesRow > 0);
    return
end

if contains(ruleNorm, 'additive') || (contains(ruleNorm, 'index') && contains(ruleNorm, 'index 1') && contains(ruleNorm, 'minus'))
    if any(seriesRow <= 0)
        error('update_nz_sheet:NonPositiveIndex', ...
            'Additive index rule for %s (row %d) requires positive values.', importKey, rowNum);
    end
    converted = seriesRow - seriesRow(1);
    return
end

if contains(ruleNorm, 'log') && contains(ruleNorm, 'index index 1')
    if any(seriesRow <= 0)
        error('update_nz_sheet:NonPositiveIndex', ...
            'Log index/index(1) rule for %s (row %d) requires positive values.', importKey, rowNum);
    end
    converted = log(seriesRow ./ seriesRow(1));
    return
end

if contains(ruleNorm, 'log') && contains(ruleNorm, 'index')
    if any(seriesRow <= 0)
        error('update_nz_sheet:NonPositiveIndex', ...
            'Log index rule for %s (row %d) requires positive values.', importKey, rowNum);
    end
    converted = log(seriesRow);
    return
end

error('update_nz_sheet:UnknownConversionRule', ...
    'Unknown conversion rule "%s" for %s (row %d).', ruleText, importKey, rowNum);
end

function out = normalize_rule_text(in)
if isempty(in)
    out = '';
    return
end
out = lower(strtrim(string(in)));
out = regexprep(out, '[^a-z0-9]+', ' ');
out = strtrim(regexprep(out, '\\s+', ' '));
end

function [headersOut, wasCreated] = ensure_nz_column_exists(targetWorkbook, targetSheet, headersIn, varName, nYears, ruleText)
headersOut = headersIn;
wasCreated = false;
if ~isempty(find_header_index(headersOut, varName))
    return
end

lastNonEmpty = find(~cellfun(@(x) isempty(x) || (isstring(x) && strlength(x) == 0), headersOut), 1, 'last');
if isempty(lastNonEmpty)
    lastNonEmpty = 1;
end

iNewCol = lastNonEmpty + 1;
colNew = excel_col_name(iNewCol);
writecell({varName}, targetWorkbook, 'Sheet', targetSheet, 'Range', sprintf('%s1', colNew));

ruleNorm = normalize_rule_text(ruleText);
if strcmpi(varName, 'Time')
    defaultVals = (2:nYears + 1)';
elseif startsWith(lower(varName), 'idx_')
    defaultVals = ones(nYears, 1);
elseif contains(ruleNorm, 'binary')
    defaultVals = zeros(nYears, 1);
else
    defaultVals = zeros(nYears, 1);
end

writematrix(defaultVals, targetWorkbook, 'Sheet', targetSheet, ...
    'Range', sprintf('%s2:%s%d', colNew, colNew, nYears + 1));

headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
wasCreated = true;
end

function write_series_to_nz_column(targetWorkbook, targetSheet, headers, varName, seriesRow, nYears)
if isempty(seriesRow)
    return
end

iCol = find_header_index(headers, varName);
if isempty(iCol)
    error('update_nz_sheet:MissingColumnAfterCreate', ...
        'Column %s was not found after creation step.', varName);
end

if numel(seriesRow) ~= nYears
    error('update_nz_sheet:SeriesLengthMismatch', ...
        'Column %s has %d values, expected %d.', varName, numel(seriesRow), nYears);
end

col = excel_col_name(iCol);
writematrix(seriesRow(:), targetWorkbook, 'Sheet', targetSheet, ...
    'Range', sprintf('%s2:%s%d', col, col, nYears + 1));
end

function iCol = find_header_index(headers, varName)
iCol = find(strcmpi(string(headers), string(varName)), 1);
end

function [trimmed, yearsOut] = trim_to_model_years(series, sourceYears, targetStartYear)
idx = sourceYears >= targetStartYear;
yearsOut = sourceYears(idx);
trimmed = series(idx);
end

function years = parse_year_header(yearHeader)
years = nan(1, numel(yearHeader));
for i = 1:numel(yearHeader)
    v = yearHeader{i};
    if isnumeric(v) && ~isnan(v) && v > 1900 && v < 3000
        years(i) = v;
    elseif isa(v, 'datetime')
        years(i) = year(v);
    elseif ischar(v) || isstring(v)
        n = str2double(strtrim(string(v)));
        if ~isnan(n) && n > 1900 && n < 3000
            years(i) = n;
        end
    end
end
if any(isnan(years))
    iV = find(~isnan(years), 1);
    if isempty(iV)
        error('update_nz_sheet:InvalidYearHeader', 'Could not parse any year values in NZ header row.');
    end
    startY = years(iV) - (iV - 1);
    years = startY + (0:numel(yearHeader) - 1);
    warning('update_nz_sheet:YearHeaderInferred', 'Could not parse all year headers; using %d:%d.', years(1), years(end));
end
end

function out = normalize_label_text(in)
out = lower(strtrim(string(in)));
out = regexprep(out, '[^a-z0-9]+', ' ');
out = strtrim(regexprep(out, '\\s+', ' '));
end

function col = excel_col_name(iCol)
letters = '';
while iCol > 0
    rem = mod(iCol - 1, 26);
    letters = [char(65 + rem) letters]; %#ok<AGROW>
    iCol = floor((iCol - 1) / 26);
end
col = letters;
end
