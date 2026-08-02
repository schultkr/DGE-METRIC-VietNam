% compute_target_investment_ratios  Standalone PDP8 fossil/renewable target-I/Y CSV.
%
% Run from the repository root:
%   run('scripts/maintenance/compute_target_investment_ratios.m')
%
% Recomputes the same PDP8-implied target investment/GDP ratios
% (exo_targetIY_2_1 fossil, exo_targetIY_3_1 renewables) that
% create_baseline_from_user_input_file.m writes into ScenarioPathDefinition.xlsx,
% for the fossil/renewable maintenance depreciation rates currently in the
% calibration workbook (delta_2_1_p, delta_3_1_p), and writes them to a CSV
% under ExcelFiles/Output/ so the ratios can be inspected without rebuilding
% the whole Baseline sheet. The CSV is overwritten on every run.

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

sversion = "_replication";
targetConfig = get_pdp8_target_investment_config(repoRoot, sversion);
ProjectedGDPBaseYear = targetConfig.projectedGDPBaseYear;
ProjectedGDPBaseValueMioUSD = targetConfig.projectedGDPBaseValueMioUSD;

% Fallback maintenance-depreciation rates when the calibration workbook
% parameters can't be read.
DeltaMaintFossil_Default = 0.05;
DeltaMaintRenewable_Default = 0.05;

% Method selected for the FossilTargetIYRatio/RenewableTargetIYRatio primary
% columns below (both methods are always computed and written for comparison):
%   "IndexProxy"   (legacy) - delta * re-based PDP8 capacity index.
%   "CapitalStock" - delta * PDP8 CAP_MIOUSD capital-stock path (explicit
%                    target capital stock per year), so the investment ratio
%                    directly reflects capital-stock development.
% Override with env var DGE_TARGET_IY_METHOD.
TargetInvestmentMethod = targetConfig.defaultMethod;
envTargetInvestmentMethod = strtrim(getenv('DGE_TARGET_IY_METHOD'));
if ~isempty(envTargetInvestmentMethod)
    TargetInvestmentMethod = envTargetInvestmentMethod;
end
if ~ismember(lower(TargetInvestmentMethod), {'indexproxy', 'capitalstock'})
    error('compute_target_investment_ratios:UnknownMethod', ...
        'DGE_TARGET_IY_METHOD/TargetInvestmentMethod must be "IndexProxy" or "CapitalStock", got "%s".', ...
        TargetInvestmentMethod);
end

dedicatedPathWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ScenarioPathDefinition.xlsx');
calibrationWorkbook = targetConfig.calibrationWorkbook;
outputCsv = fullfile(repoRoot, 'ExcelFiles', 'Output', 'PDP8TargetInvestmentRatios_FossilRenewable.csv');

[deltaMaintFossilCalib, foundDeltaMaintFossil] = read_calibration_parameter_value(calibrationWorkbook, 'delta_2_1_p');
[deltaMaintRenewableCalib, foundDeltaMaintRenewable] = read_calibration_parameter_value(calibrationWorkbook, 'delta_3_1_p');

if foundDeltaMaintFossil
    DeltaMaintFossil = deltaMaintFossilCalib;
    fprintf('  Using calibration parameter delta_2_1_p=%.6f for fossil maintenance investment.\n', DeltaMaintFossil);
else
    DeltaMaintFossil = DeltaMaintFossil_Default;
    fprintf('  Calibration parameter delta_2_1_p not found; using fallback %.6f.\n', DeltaMaintFossil);
end

if foundDeltaMaintRenewable
    DeltaMaintRenewable = deltaMaintRenewableCalib;
    fprintf('  Using calibration parameter delta_3_1_p=%.6f for renewable maintenance investment.\n', DeltaMaintRenewable);
else
    DeltaMaintRenewable = DeltaMaintRenewable_Default;
    fprintf('  Calibration parameter delta_3_1_p not found; using fallback %.6f.\n', DeltaMaintRenewable);
end

[years, gvaGrowth, sourceSheet] = read_scenario_years_and_gva_growth(dedicatedPathWorkbook);

[okIndexProxy, fossilIndexProxy, renewIndexProxy, msgIndexProxy, ~, ~, ...
    fossilNewIY_ip, renewNewIY_ip, fossilMaintIndexProxy, renewMaintIndexProxy] = ...
    compute_pdp8_target_investment_series( ...
    years, gvaGrowth, repoRoot, ProjectedGDPBaseYear, ProjectedGDPBaseValueMioUSD, ...
    DeltaMaintFossil, DeltaMaintRenewable, 'IndexProxy', ...
    targetConfig.indexProxyBaseCapitalShareFossil, ...
    targetConfig.indexProxyBaseCapitalShareRenewable);

[okCapitalStock, fossilCapitalStock, renewCapitalStock, msgCapitalStock, capStockFossil, capStockRenew, ...
    fossilNewIY_cs, renewNewIY_cs, fossilMaintCapitalStock, renewMaintCapitalStock] = ...
    compute_pdp8_target_investment_series( ...
    years, gvaGrowth, repoRoot, ProjectedGDPBaseYear, ProjectedGDPBaseValueMioUSD, ...
    DeltaMaintFossil, DeltaMaintRenewable, 'CapitalStock', ...
    targetConfig.indexProxyBaseCapitalShareFossil, ...
    targetConfig.indexProxyBaseCapitalShareRenewable);

if strcmpi(TargetInvestmentMethod, 'CapitalStock')
    if ~okCapitalStock
        error('compute_target_investment_ratios:ComputeFailed', '%s', msgCapitalStock);
    end
    if ~okIndexProxy
        warning('compute_target_investment_ratios:IndexProxyMethodFailed', '%s', msgIndexProxy);
        fossilIndexProxy = nan(size(years));
        renewIndexProxy = nan(size(years));
        fossilMaintIndexProxy = nan(size(years));
        renewMaintIndexProxy = nan(size(years));
    end
    fossilSeries = fossilCapitalStock;
    renewSeries = renewCapitalStock;
    fossilNewInvestmentIY = fossilNewIY_cs;
    renewNewInvestmentIY = renewNewIY_cs;
else
    if ~okIndexProxy
        error('compute_target_investment_ratios:ComputeFailed', '%s', msgIndexProxy);
    end
    if ~okCapitalStock
        warning('compute_target_investment_ratios:CapitalStockMethodFailed', '%s', msgCapitalStock);
        fossilCapitalStock = nan(size(years));
        renewCapitalStock = nan(size(years));
        capStockFossil = nan(size(years));
        capStockRenew = nan(size(years));
        fossilMaintCapitalStock = nan(size(years));
        renewMaintCapitalStock = nan(size(years));
    end
    fossilSeries = fossilIndexProxy;
    renewSeries = renewIndexProxy;
    fossilNewInvestmentIY = fossilNewIY_ip;
    renewNewInvestmentIY = renewNewIY_ip;
end

skipParityCheck = strcmpi(strtrim(getenv('DGE_SKIP_TARGET_IY_PARITY_CHECK')), '1');
if ~skipParityCheck
    assert_target_investment_workbook_parity( ...
        dedicatedPathWorkbook, sourceSheet, years, fossilSeries, renewSeries);
end

resultTable = table(reshape(years, [], 1), ...
    repmat(DeltaMaintFossil, numel(years), 1), ...
    repmat(DeltaMaintRenewable, numel(years), 1), ...
    repmat(string(TargetInvestmentMethod), numel(years), 1), ...
    reshape(fossilSeries, [], 1), ...
    reshape(renewSeries, [], 1), ...
    reshape(fossilNewInvestmentIY, [], 1), ...
    reshape(renewNewInvestmentIY, [], 1), ...
    reshape(fossilMaintIndexProxy, [], 1), ...
    reshape(renewMaintIndexProxy, [], 1), ...
    reshape(fossilMaintCapitalStock, [], 1), ...
    reshape(renewMaintCapitalStock, [], 1), ...
    reshape(fossilIndexProxy, [], 1), ...
    reshape(renewIndexProxy, [], 1), ...
    reshape(fossilCapitalStock, [], 1), ...
    reshape(renewCapitalStock, [], 1), ...
    reshape(capStockFossil, [], 1), ...
    reshape(capStockRenew, [], 1), ...
    'VariableNames', {'Year', 'DeltaMaintFossil', 'DeltaMaintRenewable', 'TargetInvestmentMethod', ...
    'FossilTargetIYRatio', 'RenewableTargetIYRatio', ...
    'FossilNewInvestmentIYRatio', 'RenewableNewInvestmentIYRatio', ...
    'FossilMaintenanceIYRatio_IndexProxy', 'RenewableMaintenanceIYRatio_IndexProxy', ...
    'FossilMaintenanceIYRatio_CapitalStock', 'RenewableMaintenanceIYRatio_CapitalStock', ...
    'FossilTargetIYRatio_IndexProxy', 'RenewableTargetIYRatio_IndexProxy', ...
    'FossilTargetIYRatio_CapitalStock', 'RenewableTargetIYRatio_CapitalStock', ...
    'TargetCapitalStockFossil_MioUSD', 'TargetCapitalStockRenewable_MioUSD'});

outputDir = fileparts(outputCsv);
if ~isfolder(outputDir)
    mkdir(outputDir);
end
writetable(resultTable, outputCsv);

fprintf('\nComputeTargetInvestmentRatios complete.\n');
fprintf('  Source path workbook:  %s (sheet "%s")\n', dedicatedPathWorkbook, sourceSheet);
fprintf('  Calibration workbook:  %s\n', calibrationWorkbook);
fprintf('  Output CSV:            %s\n', outputCsv);
fprintf('  Years written:         %d:%d\n', years(1), years(end));
fprintf('  Primary method (FossilTargetIYRatio/RenewableTargetIYRatio): %s\n', TargetInvestmentMethod);
fprintf('  Both IndexProxy and CapitalStock columns are written for comparison.\n');

function [years, gvaGrowth, sourceSheet] = read_scenario_years_and_gva_growth(sourceWorkbook)
% Mirrors the year-header / row-10 GVA growth parsing in
% create_baseline_from_user_input_file.m's import_dedicated_path_inputs, trimmed
% to just the two series this script needs.
if ~isfile(sourceWorkbook)
    error('compute_target_investment_ratios:SourceNotFound', ...
        'Dedicated path workbook not found:\n  %s', sourceWorkbook);
end

srcSheet = 'Input Scenario';
fallbackSourceSheets = {'Baseline'};
srcStartCol = 'D';
srcEndCol = 'AD';

envSourceSheet = strtrim(getenv('DGE_BASELINE_SOURCE_SHEET'));
if ~isempty(envSourceSheet)
    srcSheet = char(envSourceSheet);
    fallbackSourceSheets = {};
end
sourceSheet = resolve_path_source_sheet(sourceWorkbook, srcSheet, fallbackSourceSheets);

yearHeader = readcell(sourceWorkbook, 'Sheet', sourceSheet, 'Range', [srcStartCol '9:' srcEndCol '9']);
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
        if ~isnan(numVal)
            if numVal > 1900 && numVal < 3000
                years(iYear) = numVal;
            end
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
    warning('compute_target_investment_ratios:YearHeaderInferred', ...
        ['Could not parse all year headers in %s row 9 (E:AD). ' ...
         'Using inferred sequence %d:%d.'], sourceSheet, years(1), years(end));
end

gvaGrowth = readmatrix(sourceWorkbook, 'Sheet', sourceSheet, 'Range', [srcStartCol '10:' srcEndCol '10']);
if numel(gvaGrowth) ~= numel(years)
    error('compute_target_investment_ratios:UnexpectedSourceLayout', ...
        'Unexpected source input layout in workbook:\n  %s', sourceWorkbook);
end

years = reshape(years, 1, []);
gvaGrowth = reshape(gvaGrowth, 1, []);
end

function sourceSheet = resolve_path_source_sheet(sourceWorkbook, preferredSheet, fallbackSheets)
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
    error('compute_target_investment_ratios:SourceSheetNotFound', ...
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

error('compute_target_investment_ratios:SourceSheetNotFound', ...
    'Could not read any requested source sheet: %s.', strjoin(candidates, ', '));
end

function [value, found] = read_calibration_parameter_value(calibrationWorkbook, paramName)
% Read a scalar parameter value from calibration workbook.
% Priority: sheet 'Structural Parameters', then sheet 'Start'.

value = NaN;
found = false;

if ~isfile(calibrationWorkbook)
    return
end

sheetCandidates = {'Structural Parameters', 'Start'};
for iCandidate = 1:numel(sheetCandidates)
    s = sheetCandidates{iCandidate};
    try
        t = readtable(calibrationWorkbook, 'Sheet', s, 'Range', 'A:C', 'VariableNamingRule', 'preserve');
    catch
        continue
    end

    if ~ismember('Parameter', t.Properties.VariableNames) || ~ismember('Value', t.Properties.VariableNames)
        continue
    end

    row = strcmp(string(t.Parameter), string(paramName));
    if any(row)
        v = t.Value(find(row, 1, 'first'));
        if isnumeric(v)
            vNum = double(v);
        else
            vNum = str2double(string(v));
        end
        if isfinite(vNum)
            value = vNum;
            found = true;
            return
        end
    end
end
end

function assert_target_investment_workbook_parity(sourceWorkbook, sourceSheet, years, fossilExpected, renewExpected)
% Confirm that the selected shared calculation matches the paths consumed
% by the baseline builder. Run the baseline builder first after changing the
% method or inputs. DGE_SKIP_TARGET_IY_PARITY_CHECK=1 disables this guard.

keys = {'exo_targetIY_2_1', 'exo_targetIY_3_1'};
expected = {fossilExpected, renewExpected};
meta = readcell(sourceWorkbook, 'Sheet', sourceSheet, 'Range', 'B1:B300');
for iKey = 1:numel(keys)
    rowNum = find(strcmpi(strtrim(string(meta)), keys{iKey}), 1, 'first');
    if isempty(rowNum)
        error('compute_target_investment_ratios:ParityRowMissing', ...
            'Cannot verify parity because %s is missing from %s/%s.', ...
            keys{iKey}, sourceWorkbook, sourceSheet);
    end

    actual = reshape(readmatrix(sourceWorkbook, 'Sheet', sourceSheet, ...
        'Range', sprintf('D%d:AD%d', rowNum, rowNum)), 1, []);
    if numel(actual) ~= numel(years) || any(~isfinite(actual))
        error('compute_target_investment_ratios:ParityPathInvalid', ...
            'Workbook path %s is missing or invalid for one or more years.', keys{iKey});
    end

    maxAbsDiff = max(abs(actual - expected{iKey}));
    tolerance = 1e-10;
    if maxAbsDiff > tolerance
        error('compute_target_investment_ratios:ParityMismatch', ...
            ['%s differs from the shared %s calculation (max abs diff %.3g). ' ...
             'Run create_baseline_from_user_input_file.m first, or set ' ...
             'DGE_SKIP_TARGET_IY_PARITY_CHECK=1 for diagnostic-only output.'], ...
            keys{iKey}, char(string(getenv_or_default( ...
            'DGE_TARGET_IY_METHOD', 'CapitalStock'))), maxAbsDiff);
    end
end
fprintf('  Workbook parity check passed for %d:%d (tolerance %.1e).\n', ...
    years(1), years(end), tolerance);
end

function value = getenv_or_default(name, defaultValue)
value = strtrim(getenv(name));
if isempty(value)
    value = defaultValue;
end
end

% Quarantined snapshot of the former local implementation. It is renamed so
% all active calls resolve to the shared function; retain until the existing
% uncommitted maintenance-script work is reconciled.
function [ok, fossilSeries, renewSeries, msg, capitalStockFossil, capitalStockRenew, fossilNewIY, renewNewIY, fossilMaintIY, renewMaintIY] = compute_pdp8_target_investment_series_legacy_unused(sourceYears, gvaGrowth, repoRoot, gdpBaseYear, gdpBaseValueMioUSD, deltaMaintFossil, deltaMaintRenewable, targetInvestmentMethod) %#ok<DEFNU>
ok = false;
msg = '';
fossilSeries = [];
renewSeries = [];
capitalStockFossil = [];
capitalStockRenew = [];
fossilNewIY = [];
renewNewIY = [];
fossilMaintIY = [];
renewMaintIY = [];

if nargin < 6 || ~isfinite(deltaMaintFossil)
    deltaMaintFossil = 0.05;
end
if nargin < 7 || ~isfinite(deltaMaintRenewable)
    deltaMaintRenewable = 0.05;
end
if nargin < 8 || isempty(targetInvestmentMethod)
    targetInvestmentMethod = 'CapitalStock';
end
targetInvestmentMethod = char(targetInvestmentMethod);
if ~ismember(lower(targetInvestmentMethod), {'indexproxy', 'capitalstock'})
    msg = sprintf('Unknown target-investment method "%s"; expected "IndexProxy" or "CapitalStock".', targetInvestmentMethod);
    return
end
useCapitalStock = strcmpi(targetInvestmentMethod, 'CapitalStock');

if ~isfinite(gdpBaseYear) || ~isfinite(gdpBaseValueMioUSD) || gdpBaseValueMioUSD <= 0
    msg = 'Projected GDP base-year configuration must be finite and positive.';
    return
end

invFile = fullfile(repoRoot, 'ExcelFiles', 'PDP8', 'Investment.csv');
idxFile = fullfile(repoRoot, 'ExcelFiles', 'PDP8', 'IndexedTrajectories_FossilRenewable_Capacity.csv');
if ~isfile(invFile) || (~useCapitalStock && ~isfile(idxFile))
    msg = sprintf('Required PDP8 files are missing. Investment=%d, Indexed=%d', isfile(invFile), isfile(idxFile));
    return
end

try
    inv = readtable(invFile, 'VariableNamingRule', 'preserve', 'TreatAsEmpty', {'NA'});
    if ~useCapitalStock
        idx = readtable(idxFile, 'VariableNamingRule', 'preserve', 'TreatAsEmpty', {'NA'});
    end
catch ME
    msg = sprintf('Failed to read PDP8 files: %s', ME.message);
    return
end

if ~ismember('Plan', inv.Properties.VariableNames) || ~ismember('Year', inv.Properties.VariableNames) || ...
        ~ismember('Technology', inv.Properties.VariableNames) || ~ismember('INV_MIOUSD', inv.Properties.VariableNames) || ...
        ~ismember('CAP_MIOUSD', inv.Properties.VariableNames)
    msg = 'Investment.csv does not have required columns Plan, Year, Technology, INV_MIOUSD, CAP_MIOUSD.';
    return
end

if ~useCapitalStock && (~ismember('Year', idx.Properties.VariableNames) || ~ismember('TechType', idx.Properties.VariableNames) || ...
        ~ismember('Index_Value', idx.Properties.VariableNames))
    msg = 'IndexedTrajectories file does not have required columns Year, TechType, Index_Value.';
    return
end

invPlan = inv(strcmpi(string(inv.Plan), "PDP8_rev_high"), :);
if isempty(invPlan)
    msg = 'No rows found in Investment.csv for Plan == PDP8.';
    return
end

years = sourceYears(:)';
nY = numel(years);

invYear = as_numeric(invPlan.Year);
invMio = as_numeric(invPlan.INV_MIOUSD);
capMio = as_numeric(invPlan.CAP_MIOUSD);
tech = string(invPlan.Technology);
isFossilTech = is_fossil_tech(tech);
isRenewTech = ~isFossilTech;

fossilDirect = zeros(1, nY);
renewDirect = zeros(1, nY);
for i = 1:nY
    y = years(i);
    m = (invYear == y);
    fossilDirect(i) = nansum(invMio(m & isFossilTech));
    renewDirect(i) = nansum(invMio(m & isRenewTech));
end

gdpPath = build_projected_gdp_path(sourceYears, gvaGrowth, gdpBaseYear, gdpBaseValueMioUSD);
if any(~isfinite(gdpPath)) || any(gdpPath <= 0)
    msg = 'Projected GDP path contains invalid values. Check total GVA growth inputs.';
    return
end

% New-addition investment ratio: direct PDP8 build-out (INV_MIOUSD) as a
% share of GDP. Identical definition under both methods -- this is the
% "old method" direct-investment component, unchanged by the maintenance
% branch below.
fossilNewIY = fossilDirect ./ gdpPath;
renewNewIY = renewDirect ./ gdpPath;

if useCapitalStock
    % Explicit target capital stock per year (MIOUSD), summed directly from
    % PDP8 CAP_MIOUSD by technology group. Maintenance investment is
    % delta * lagged capital stock, so the investment ratio is a direct
    % reflection of the capital-stock path rather than a re-based index.
    capitalStockFossil = zeros(1, nY);
    capitalStockRenew = zeros(1, nY);
    for i = 1:nY
        y = years(i);
        m = (invYear == y);
        capitalStockFossil(i) = nansum(capMio(m & isFossilTech));
        capitalStockRenew(i) = nansum(capMio(m & isRenewTech));
    end
    if any(~isfinite(capitalStockFossil)) || any(~isfinite(capitalStockRenew))
        msg = 'Could not determine PDP8 CAP_MIOUSD capital stock for fossil/renewables for one or more source years.';
        return
    end

    maintF = deltaMaintFossil .* [capitalStockFossil(1), capitalStockFossil(1:end-1)];
    maintR = deltaMaintRenewable .* [capitalStockRenew(1), capitalStockRenew(1:end-1)];

    fossilMaintIY = maintF ./ gdpPath;
    renewMaintIY = maintR ./ gdpPath;
else
    capR2025 = nansum(capMio(invYear == 2025 & isRenewTech));
    if ~isfinite(capR2025) || capR2025 <= 0
        msg = 'Could not determine positive 2025 CAP_MIOUSD for renewables in Investment.csv.';
        return
    end

    idxYear = as_numeric(idx.Year);
    idxType = string(idx.TechType);
    idxVal = as_numeric(idx.Index_Value);

    fossilIdx = nan(1, nY);
    renewIdx = nan(1, nY);
    for i = 1:nY
        y = years(i);
        mf = (idxYear == y) & strcmpi(idxType, "Fossil");
        mr = (idxYear == y) & strcmpi(idxType, "Renewable");
        if any(mf)
            fossilIdx(i) = idxVal(find(mf, 1, 'first'));
        end
        if any(mr)
            renewIdx(i) = idxVal(find(mr, 1, 'first'));
        end
    end

    missingIdx = ~isfinite(fossilIdx) | ~isfinite(renewIdx);
    if any(missingIdx)
        fossilIdx = fillmissing(fossilIdx, 'previous');
        renewIdx = fillmissing(renewIdx, 'previous');
        if any(~isfinite(fossilIdx)) || any(~isfinite(renewIdx))
            msg = ['Indexed trajectory file is missing Fossil/Renewable index values ' ...
                'and no earlier value is available to carry forward.'];
            return
        end
        missingYears = strjoin(string(years(missingIdx)), ', ');
        warning('compute_target_investment_ratios:IndexedTrajectoryCarryForward', ...
            ['Indexed trajectory file is missing Fossil/Renewable index values for year(s) %s. ' ...
             'The last available value was used for each missing year.'], missingYears);
    end

    fossilMaintIY = deltaMaintFossil .* 0.025 .* (fossilIdx ./ 100) ./ (gdpPath ./ gdpPath(1));
    renewMaintIY = deltaMaintRenewable .* 0.005 .* (renewIdx ./ 100) ./ (gdpPath ./ gdpPath(1));
end

fossilSeries = fossilNewIY + fossilMaintIY;
renewSeries = renewNewIY + renewMaintIY;

ok = true;
end

function gdpPath = build_projected_gdp_path(sourceYears, gvaGrowth, gdpBaseYear, gdpBaseValueMioUSD)
years = reshape(sourceYears, 1, []);
factors = normalize_growth_to_factors(gvaGrowth);
if numel(factors) ~= numel(years)
    error('compute_target_investment_ratios:GDPGrowthLengthMismatch', ...
        'GVA growth path length (%d) must match year path length (%d).', numel(factors), numel(years));
end

idxBase = find(years == gdpBaseYear, 1, 'first');
if isempty(idxBase)
    error('compute_target_investment_ratios:GDPBaseYearMissing', ...
        'GDP base year %d is not present in source years.', gdpBaseYear);
end

gdpPath = nan(1, numel(years));
gdpPath(idxBase) = gdpBaseValueMioUSD;

for i = (idxBase + 1):numel(years)
    gdpPath(i) = gdpPath(i - 1) * factors(i);
end
for i = (idxBase - 1):-1:1
    gdpPath(i) = gdpPath(i + 1) / factors(i + 1);
end
end

function growthFactors = normalize_growth_to_factors(totalGrowth)
    % Accept three conventions for user input:
    % 1) Factors (e.g., 1.02)
    % 2) Decimal rates (e.g., 0.02 or -0.01)
    % 3) Percent rates (e.g., 2 for 2%%)

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

function mask = is_fossil_tech(techNames)
t = lower(string(techNames));
mask = contains(t, "coal") | contains(t, "gas") | contains(t, "lng") | contains(t, "oil") | contains(t, "diesel") | contains(t, "nuclear") | contains(t, "ccgt");
end

function x = as_numeric(v)
if isnumeric(v)
    x = double(v);
else
    x = str2double(string(v));
end
end
