% create_baseline_share_candidates  Create model-ready Baseline candidate sheets.
%
% This script builds on create_baseline_from_user_input_file.m:
%   1. Refreshes the canonical ModelBaseline...xlsx!Baseline sheet from
%      ExcelFiles/ScenarioPathDefinition.xlsx.
%   2. Creates additional runnable Baseline_* sheets with alternative
%      value-added share interpolation paths.
%
% The default candidates respect user-entered fossil/renewable value-added
% shares at anchor years 2030, 2035, 2040, 2045, and 2050. Between anchor
% years, each candidate uses one common interpolation speed for both
% fossil and renewables.
%
% Services/tertiary (subsector 5) is the residual sector: primary and
% secondary VA shares remain on their source paths, while services absorbs
% the fossil/renewable share adjustment so total shares always sum to one.
%
% Sector growth targets are generated analytically from:
%   gY_s,t = GVA_growth_t * VA_share_s,t / VA_share_s,t-1
%
% Run from repository root:
%   run('scripts/maintenance/create_baseline_share_candidates.m')
%
% Optional maintenance sweep (not the canonical baseline run path):
%   setenv('DGE_BASELINE_SHEETS', 'Baseline,Baseline_FR_g050,Baseline_FR_g100,Baseline_FR_g200')
%   run('RunSimulations.m')

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

%% Configuration

RefreshMainBaselineFirst = true;

sourceWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ScenarioPathDefinition.xlsx');
sourceSheet = 'Input Scenario';
fallbackSourceSheets = {'Baseline'};
targetWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelBaseline5Sectorsand1Regions.xlsx');
baseModelSheet = 'Baseline';

% ScenarioPathDefinition year/value layout. This matches
% create_baseline_from_user_input_file.m after the conversion-rule column exists.
srcStartCol = 'E';
srcEndCol = 'AD';

targetStartYear = 2026;
interpolationAnchorYears = [2030, 2035, 2040, 2045, 2050];

fossilSubsector = 2;
renewableSubsector = 3;
residualSubsector = 5; % Tertiary/services absorbs fossil/renewable share changes.

% Piecewise power-path grid between user-input anchors: tau^gamma.
% gamma < 1 is front-loaded; gamma > 1 is back-loaded; gamma = 1 is linear.
candidateGammas = [0.1, 0.2];
includeSmoothStepCandidate = true;
candidateSheetPrefix = 'Baseline_FR';

% Optional environment overrides for quick experiments:
%   DGE_BASELINE_SOURCE_SHEET="Input Scenario"
%   DGE_BASELINE_ANCHOR_YEARS="2030,2035,2040,2045,2050"
%   DGE_BASELINE_SHARE_GAMMAS="0.4,0.8,1,1.8"
%   DGE_BASELINE_CANDIDATE_PREFIX="Baseline_FR"
%   DGE_BASELINE_INCLUDE_SMOOTH="false"
%   DGE_BASELINE_RESIDUAL_SUBSECTOR="5"
%   DGE_REFRESH_BASELINE_FIRST="false"
envSourceSheet = strtrim(getenv('DGE_BASELINE_SOURCE_SHEET'));
if ~isempty(envSourceSheet)
    sourceSheet = char(envSourceSheet);
    fallbackSourceSheets = {};
end

envAnchorYears = strtrim(getenv('DGE_BASELINE_ANCHOR_YEARS'));
if ~isempty(envAnchorYears)
    interpolationAnchorYears = parse_numeric_list(envAnchorYears, 'DGE_BASELINE_ANCHOR_YEARS');
end

envGammas = strtrim(getenv('DGE_BASELINE_SHARE_GAMMAS'));
if ~isempty(envGammas)
    parsedGammas = parse_numeric_list(envGammas, 'DGE_BASELINE_SHARE_GAMMAS');
    parsedGammas = parsedGammas(isfinite(parsedGammas) & parsedGammas > 0);
    if isempty(parsedGammas)
        error('create_baseline_share_candidates:InvalidGammaGrid', ...
            'DGE_BASELINE_SHARE_GAMMAS did not contain any positive numeric values.');
    end
    candidateGammas = parsedGammas;
end

envPrefix = strtrim(getenv('DGE_BASELINE_CANDIDATE_PREFIX'));
if ~isempty(envPrefix)
    candidateSheetPrefix = char(envPrefix);
end

envIncludeSmooth = lower(strtrim(getenv('DGE_BASELINE_INCLUDE_SMOOTH')));
if any(strcmp(envIncludeSmooth, {'0', 'false', 'no'}))
    includeSmoothStepCandidate = false;
elseif any(strcmp(envIncludeSmooth, {'1', 'true', 'yes'}))
    includeSmoothStepCandidate = true;
end

envResidualSubsector = strtrim(getenv('DGE_BASELINE_RESIDUAL_SUBSECTOR'));
if ~isempty(envResidualSubsector)
    residualSubsector = str2double(envResidualSubsector);
    if ~isfinite(residualSubsector) || abs(residualSubsector - round(residualSubsector)) > 1e-10
        error('create_baseline_share_candidates:InvalidResidualSubsector', ...
            'DGE_BASELINE_RESIDUAL_SUBSECTOR must be an integer subsector index.');
    end
    residualSubsector = round(residualSubsector);
end

envRefresh = lower(strtrim(getenv('DGE_REFRESH_BASELINE_FIRST')));
if any(strcmp(envRefresh, {'0', 'false', 'no'}))
    RefreshMainBaselineFirst = false;
end

%% Refresh main Baseline, then create candidate sheets

if RefreshMainBaselineFirst
    refresh_main_baseline_from_user_input();
end

if ~isfile(sourceWorkbook)
    error('create_baseline_share_candidates:SourceNotFound', ...
        'Scenario path definition workbook not found:\n  %s', sourceWorkbook);
end
if ~isfile(targetWorkbook)
    error('create_baseline_share_candidates:TargetNotFound', ...
        'Target baseline workbook not found:\n  %s', targetWorkbook);
end

sourceSheet = resolve_source_sheet(sourceWorkbook, sourceSheet, fallbackSourceSheets);
inputs = read_share_inputs(sourceWorkbook, sourceSheet, srcStartCol, srcEndCol);
interpolationAnchorYears = normalize_anchor_years(interpolationAnchorYears, inputs.years);

baseTable = read_table_preserve_names(targetWorkbook, 'Sheet', baseModelSheet);
candidateSpecs = build_candidate_specs(candidateSheetPrefix, candidateGammas, includeSmoothStepCandidate);

candidateNames = cell(numel(candidateSpecs), 1);
diagnostics = table();

for iCandidate = 1:numel(candidateSpecs)
    spec = candidateSpecs(iCandidate);

    candidateShares = build_candidate_share_path(inputs.vaShares, inputs.years, ...
        fossilSubsector, renewableSubsector, residualSubsector, ...
        interpolationAnchorYears, spec.shape, spec.gamma);

    [gY, yearsOut] = compute_sector_growth_factors( ...
        inputs.gvaGrowth, candidateShares, inputs.years, targetStartYear);

    candidateTable = apply_growth_targets_to_baseline_table(baseTable, gY, yearsOut);
    write_table_over_sheet(candidateTable, targetWorkbook, spec.sheetName);

    candidateNames{iCandidate} = spec.sheetName;
    diagnostics = [diagnostics; build_candidate_diagnostics(spec, inputs.years, candidateShares, yearsOut, gY)]; %#ok<AGROW>
end

outDir = fullfile(repoRoot, 'ExcelFiles', 'Output');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
diagnosticFile = fullfile(outDir, 'BaselineShareCandidatePaths.csv');
writetable(diagnostics, diagnosticFile);

fprintf('\nCreateBaselineShareCandidates complete.\n');
fprintf('  Source path workbook:   %s\n', sourceWorkbook);
fprintf('  Source input sheet:     %s\n', sourceSheet);
fprintf('  Target baseline workbook: %s\n', targetWorkbook);
fprintf('  Anchor years respected: %s\n', num2str(interpolationAnchorYears));
finalAnchorIdx = find(inputs.years == interpolationAnchorYears(end), 1, 'first');
fprintf('  Final-anchor fossil share:    %.6f\n', inputs.vaShares(fossilSubsector, finalAnchorIdx));
fprintf('  Final-anchor renewable share: %.6f\n', inputs.vaShares(renewableSubsector, finalAnchorIdx));
fprintf('  Residual subsector:     %d\n', residualSubsector);
fprintf('  Candidate sheets written:\n');
for i = 1:numel(candidateNames)
    fprintf('    %s\n', candidateNames{i});
end
fprintf('  Candidate path diagnostics: %s\n', diagnosticFile);
fprintf('\nOptional maintenance sweep helper:\n');
fprintf('  setenv(''DGE_BASELINE_SHEETS'', ''%s'')\n', strjoin([{baseModelSheet}; candidateNames], ','));
fprintf('  run(''RunSimulations.m'')\n');

%% Local functions

function refresh_main_baseline_from_user_input()
    run('scripts/maintenance/create_baseline_from_user_input_file.m');
end

function sourceSheet = resolve_source_sheet(sourceWorkbook, preferredSheet, fallbackSheets)
    candidates = [{char(preferredSheet)}, reshape(fallbackSheets, 1, [])];
    candidates = candidates(~cellfun(@isempty, candidates));

    try
        availableSheets = cellstr(sheetnames(sourceWorkbook));
    catch
        availableSheets = {};
    end

    if ~isempty(availableSheets)
        for iCandidate = 1:numel(candidates)
            matchIdx = find(strcmpi(availableSheets, candidates{iCandidate}), 1, 'first');
            if ~isempty(matchIdx)
                sourceSheet = availableSheets{matchIdx};
                return
            end
        end
        error('create_baseline_share_candidates:SourceSheetNotFound', ...
            'None of the requested source sheets were found. Requested: %s. Available: %s.', ...
            strjoin(candidates, ', '), strjoin(availableSheets, ', '));
    end

    for iCandidate = 1:numel(candidates)
        try
            readcell(sourceWorkbook, 'Sheet', candidates{iCandidate}, 'Range', 'A1:A1');
            sourceSheet = candidates{iCandidate};
            return
        catch
        end
    end

    error('create_baseline_share_candidates:SourceSheetNotFound', ...
        'Could not read any requested source sheet: %s.', strjoin(candidates, ', '));
end

function values = parse_numeric_list(rawText, envName)
    parts = strsplit(char(rawText), ',');
    values = str2double(parts);
    values = values(isfinite(values));
    if isempty(values)
        error('create_baseline_share_candidates:InvalidNumericList', ...
            '%s must contain at least one numeric value.', envName);
    end
end

function inputs = read_share_inputs(sourceWorkbook, sourceSheet, srcStartCol, srcEndCol)
    yearHeader = readcell(sourceWorkbook, 'Sheet', sourceSheet, ...
        'Range', [srcStartCol '9:' srcEndCol '9']);
    years = parse_year_headers(yearHeader);

    gvaGrowth = readmatrix(sourceWorkbook, 'Sheet', sourceSheet, ...
        'Range', [srcStartCol '10:' srcEndCol '10']);
    vaShares = readmatrix(sourceWorkbook, 'Sheet', sourceSheet, ...
        'Range', [srcStartCol '12:' srcEndCol '16']);

    if numel(gvaGrowth) ~= numel(years) || size(vaShares, 2) ~= numel(years)
        error('create_baseline_share_candidates:UnexpectedSourceLayout', ...
            'Unexpected source input layout in workbook:\n  %s', sourceWorkbook);
    end

    vaShares = normalize_share_columns(vaShares);

    inputs = struct();
    inputs.years = reshape(years, 1, []);
    inputs.gvaGrowth = reshape(gvaGrowth, 1, []);
    inputs.vaShares = vaShares;
end

function anchorYears = normalize_anchor_years(anchorYears, sourceYears)
    rawYears = reshape(anchorYears, 1, []);
    rawYears = rawYears(isfinite(rawYears));
    if isempty(rawYears)
        error('create_baseline_share_candidates:InvalidAnchorYears', ...
            'At least one interpolation anchor year is required.');
    end
    if any(abs(rawYears - round(rawYears)) > 1e-10)
        error('create_baseline_share_candidates:InvalidAnchorYears', ...
            'Interpolation anchor years must be integer years.');
    end

    anchorYears = sort(unique(round(rawYears)));
    sourceYears = reshape(round(sourceYears), 1, []);

    if any(anchorYears <= sourceYears(1)) || any(anchorYears > sourceYears(end))
        error('create_baseline_share_candidates:InvalidAnchorYears', ...
            'Anchor years must be after %d and no later than %d.', ...
            sourceYears(1), sourceYears(end));
    end

    missingYears = anchorYears(~ismember(anchorYears, sourceYears));
    if ~isempty(missingYears)
        error('create_baseline_share_candidates:MissingAnchorYears', ...
            'The source input sheet does not contain anchor year(s): %s.', num2str(missingYears));
    end
end

function years = parse_year_headers(yearHeader)
    years = nan(1, numel(yearHeader));
    for iYear = 1:numel(yearHeader)
        v = yearHeader{iYear};
        if isa(v, 'datetime')
            years(iYear) = year(v);
        elseif isnumeric(v)
            if ~isempty(v) && ~isnan(v)
                if v > 1900 && v < 3000
                    years(iYear) = v;
                else
                    try
                        years(iYear) = year(datetime(v, 'ConvertFrom', 'excel'));
                    catch
                    end
                end
            end
        elseif isstring(v) || ischar(v)
            sVal = strtrim(string(v));
            numVal = str2double(sVal);
            if ~isnan(numVal) && numVal > 1900 && numVal < 3000
                years(iYear) = numVal;
            else
                token = regexp(char(sVal), '(19|20)\d{2}', 'match', 'once');
                if ~isempty(token)
                    years(iYear) = str2double(token);
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
        warning('create_baseline_share_candidates:YearHeaderInferred', ...
            'Could not parse all year headers. Using inferred sequence %d:%d.', ...
            years(1), years(end));
    end
end

function shares = normalize_share_columns(shares)
    if any(~isfinite(shares(:))) || any(shares(:) < 0)
        error('create_baseline_share_candidates:InvalidShares', ...
            'VA share inputs must be finite and non-negative.');
    end
    colSums = sum(shares, 1);
    if any(colSums <= 0)
        error('create_baseline_share_candidates:InvalidShareSums', ...
            'Each VA share column must have a positive sum.');
    end
    shares = shares ./ colSums;
end

function specs = build_candidate_specs(prefix, gammas, includeSmoothStep)
    specs = struct('sheetName', {}, 'shape', {}, 'gamma', {});
    for i = 1:numel(gammas)
        specs(end + 1).sheetName = safe_sheet_name([prefix '_' gamma_tag(gammas(i))]); %#ok<AGROW>
        specs(end).shape = 'power';
        specs(end).gamma = gammas(i);
    end
    if includeSmoothStep
        specs(end + 1).sheetName = safe_sheet_name([prefix '_smooth']);
        specs(end).shape = 'smoothstep';
        specs(end).gamma = NaN;
    end
end

function tag = gamma_tag(gamma)
    tag = sprintf('g%03d', round(100 * gamma));
end

function name = safe_sheet_name(rawName)
    name = regexprep(char(rawName), '[:\\/\?\*\[\]]', '_');
    if numel(name) > 31
        name = name(1:31);
    end
end

function candidateShares = build_candidate_share_path(sourceShares, years, ...
    fossilSubsector, renewableSubsector, residualSubsector, anchorYears, shape, gamma)

    nSub = size(sourceShares, 1);
    if fossilSubsector < 1 || fossilSubsector > nSub || ...
            renewableSubsector < 1 || renewableSubsector > nSub || ...
            residualSubsector < 1 || residualSubsector > nSub
        error('create_baseline_share_candidates:InvalidSubsector', ...
            'Fossil, renewable, and residual subsector indices must be between 1 and %d.', nSub);
    end

    if any(residualSubsector == [fossilSubsector, renewableSubsector])
        error('create_baseline_share_candidates:InvalidResidualSubsector', ...
            'Residual subsector must be distinct from fossil and renewables.');
    end

    anchorYears = normalize_anchor_years(anchorYears, years);

    candidateShares = sourceShares;
    fossilPath = interpolate_anchor_path(sourceShares(fossilSubsector, :), ...
        years, anchorYears, shape, gamma);
    renewablePath = interpolate_anchor_path(sourceShares(renewableSubsector, :), ...
        years, anchorYears, shape, gamma);

    fixedIdx = setdiff(1:nSub, [fossilSubsector, renewableSubsector, residualSubsector]);
    residualPath = 1 - sum(sourceShares(fixedIdx, :), 1) - fossilPath - renewablePath;

    if any(residualPath <= 0)
        error('create_baseline_share_candidates:NegativeResidualShare', ...
            ['Candidate path leaves non-positive services/residual VA share. ' ...
             'Use a different interpolation speed or revise anchor-year shares.']);
    end

    candidateShares(fossilSubsector, :) = fossilPath;
    candidateShares(renewableSubsector, :) = renewablePath;
    candidateShares(residualSubsector, :) = residualPath;

    shareSumError = max(abs(sum(candidateShares, 1) - 1));
    if shareSumError > 1e-10
        error('create_baseline_share_candidates:ShareSumError', ...
            'Candidate VA shares do not sum to one. Max abs error: %.3g.', shareSumError);
    end
end

function path = interpolate_anchor_path(sourcePath, years, anchorYears, shape, gamma)
    years = reshape(years, 1, []);
    sourcePath = reshape(sourcePath, 1, []);
    path = sourcePath;
    segmentYears = [years(1), reshape(anchorYears, 1, [])];

    for iSegment = 1:(numel(segmentYears) - 1)
        y0 = segmentYears(iSegment);
        y1 = segmentYears(iSegment + 1);
        idx0 = find(years == y0, 1, 'first');
        idx1 = find(years == y1, 1, 'first');
        if isempty(idx0) || isempty(idx1)
            error('create_baseline_share_candidates:MissingSegmentEndpoint', ...
                'Interpolation endpoint year is missing from source path: %d or %d.', y0, y1);
        end

        segmentIdx = find(years >= y0 & years <= y1);
        tau = (years(segmentIdx) - y0) ./ (y1 - y0);
        tau = min(1, max(0, tau));
        z = shape_progress(tau, shape, gamma);
        z(1) = 0;
        z(end) = 1;

        path(segmentIdx) = sourcePath(idx0) + ...
            (sourcePath(idx1) - sourcePath(idx0)) .* z;
    end
end

function z = shape_progress(tau, shape, gamma)
    switch lower(char(shape))
        case 'power'
            z = tau .^ gamma;
        case 'smoothstep'
            z = tau .^ 2 .* (3 - 2 .* tau);
        otherwise
            error('create_baseline_share_candidates:UnknownShape', ...
                'Unknown interpolation shape "%s".', shape);
    end
end

function [growth, yearsOut] = compute_sector_growth_factors(totalGrowth, shares, years, targetStartYear)
    if size(shares, 2) ~= numel(totalGrowth) || numel(years) ~= numel(totalGrowth)
        error('create_baseline_share_candidates:GrowthShareLengthMismatch', ...
            'Share, year, and aggregate growth paths must have the same length.');
    end

    totalGrowthFactors = normalize_growth_to_factors(totalGrowth);
    if any(totalGrowthFactors <= 0)
        error('create_baseline_share_candidates:NonPositiveGrowth', ...
            'Aggregate GVA growth factors must be positive.');
    end

    idxStart = find(years >= targetStartYear, 1, 'first');
    if isempty(idxStart) || idxStart == 1
        error('create_baseline_share_candidates:InvalidTargetStartYear', ...
            'Input must contain one year before targetStartYear=%d.', targetStartYear);
    end

    idxOut = idxStart:numel(years);
    prevIdx = (idxStart - 1):(numel(years) - 1);
    growth = shares(:, idxOut) ./ shares(:, prevIdx);
    growth = growth .* repmat(reshape(totalGrowthFactors(idxOut), 1, []), size(shares, 1), 1);
    yearsOut = years(idxOut);
end

function growthFactors = normalize_growth_to_factors(totalGrowth)
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

function candidateTable = apply_growth_targets_to_baseline_table(baseTable, gY, yearsOut)
    candidateTable = baseTable;
    varNames = candidateTable.Properties.VariableNames;

    if has_variable(varNames, 'Year')
        rows = nan(numel(yearsOut), 1);
        yearValues = to_numeric(candidateTable.Year);
        for i = 1:numel(yearsOut)
            rowIdx = find(yearValues == yearsOut(i), 1, 'first');
            if ~isempty(rowIdx)
                rows(i) = rowIdx;
            end
        end
        if any(isnan(rows))
            missingYears = yearsOut(isnan(rows));
            error('create_baseline_share_candidates:MissingBaselineYearRows', ...
                'Baseline sheet does not contain rows for year(s): %s', num2str(missingYears));
        end
    else
        rows = (1:numel(yearsOut))';
        if height(candidateTable) < numel(rows)
            error('create_baseline_share_candidates:TooFewBaselineRows', ...
                'Baseline sheet has fewer rows than the generated gY path.');
        end
    end

    for iSub = 1:size(gY, 1)
        varName = sprintf('gY_%d_1', iSub);
        if ~has_variable(varNames, varName)
            error('create_baseline_share_candidates:MissingGrowthColumn', ...
                'Baseline sheet is missing required column "%s".', varName);
        end
        candidateTable.(varName)(rows) = gY(iSub, :)';
    end
end

function diagnostics = build_candidate_diagnostics(spec, years, shares, yearsOut, gY)
    nYears = numel(years);
    diagnostics = table();
    diagnostics.Candidate = repmat(string(spec.sheetName), nYears, 1);
    diagnostics.Shape = repmat(string(spec.shape), nYears, 1);
    diagnostics.Gamma = repmat(spec.gamma, nYears, 1);
    diagnostics.Year = reshape(years, [], 1);

    for iSub = 1:size(shares, 1)
        diagnostics.(sprintf('VA_Share_%d', iSub)) = shares(iSub, :)';
    end

    for iSub = 1:size(gY, 1)
        values = nan(nYears, 1);
        [tf, loc] = ismember(yearsOut, years);
        values(loc(tf)) = gY(iSub, tf)';
        diagnostics.(sprintf('gY_%d_1', iSub)) = values;
    end
end

function tab = read_table_preserve_names(sFile, varargin)
    try
        tab = readtable(sFile, varargin{:}, 'PreserveVariableNames', true);
    catch
        try
            tab = readtable(sFile, varargin{:}, 'VariableNamingRule', 'preserve');
        catch
            tab = readtable(sFile, varargin{:});
        end
    end
end

function write_table_over_sheet(tab, workbook, sheetName)
    try
        writetable(tab, workbook, 'Sheet', sheetName, 'WriteMode', 'overwritesheet');
    catch
        writetable(tab, workbook, 'Sheet', sheetName);
    end
end

function tf = has_variable(names, sName)
    tf = any(strcmp(names, sName));
end

function x = to_numeric(value)
    if isnumeric(value)
        x = double(value);
    elseif iscell(value)
        x = nan(size(value));
        for i = 1:numel(value)
            x(i) = numeric_scalar(value{i});
        end
    elseif isstring(value)
        x = str2double(value);
    elseif ischar(value)
        x = str2double(cellstr(value));
    else
        x = double(value);
    end
    x = x(:);
end

function value = numeric_scalar(raw)
    if isempty(raw)
        value = NaN;
    elseif isnumeric(raw)
        value = double(raw);
    elseif ischar(raw) || isstring(raw)
        value = str2double(char(raw));
    else
        value = NaN;
    end
end
