function [ok, fossilSeries, renewSeries, msg, capitalStockFossil, capitalStockRenew, ...
    fossilNewIY, renewNewIY, fossilMaintIY, renewMaintIY] = ...
    compute_pdp8_target_investment_series(sourceYears, gvaGrowth, repoRoot, ...
    gdpBaseYear, gdpBaseValueMioUSD, deltaMaintFossil, deltaMaintRenewable, ...
    targetInvestmentMethod, indexProxyBaseCapitalShareFossil, ...
    indexProxyBaseCapitalShareRenewable)
% COMPUTE_PDP8_TARGET_INVESTMENT_SERIES  PDP8 fossil/renewable target I/Y.
%
% The target is new PDP8 investment plus replacement investment:
%   new investment = INV_MIOUSD(t) / GDP(t)
%
% CapitalStock (recommended):
%   maintenance = delta * CAP_MIOUSD(t-1) / GDP(t)
%
% IndexProxy (legacy):
%   maintenance = delta * assumed base-year K/Y * capacity index(t)
%                 / GDP index(t)
%
% Both maintenance scripts call this function so their formulas cannot
% diverge. The IndexProxy base shares are explicit inputs rather than magic
% constants embedded in either caller.

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
if nargin < 9 || isempty(indexProxyBaseCapitalShareFossil)
    indexProxyBaseCapitalShareFossil = 0.025;
end
if nargin < 10 || isempty(indexProxyBaseCapitalShareRenewable)
    indexProxyBaseCapitalShareRenewable = 0.005;
end

targetInvestmentMethod = char(targetInvestmentMethod);
if ~ismember(lower(targetInvestmentMethod), {'indexproxy', 'capitalstock'})
    msg = sprintf(['Unknown target-investment method "%s"; expected ' ...
        '"IndexProxy" or "CapitalStock".'], targetInvestmentMethod);
    return
end
useCapitalStock = strcmpi(targetInvestmentMethod, 'CapitalStock');

if ~isfinite(gdpBaseYear) || ~isfinite(gdpBaseValueMioUSD) || gdpBaseValueMioUSD <= 0
    msg = 'Projected GDP base-year configuration must be finite and positive.';
    return
end
if ~isfinite(indexProxyBaseCapitalShareFossil) || indexProxyBaseCapitalShareFossil <= 0 || ...
        ~isfinite(indexProxyBaseCapitalShareRenewable) || indexProxyBaseCapitalShareRenewable <= 0
    msg = 'IndexProxy base-year capital/GDP shares must be finite and positive.';
    return
end

invFile = fullfile(repoRoot, 'ExcelFiles', 'PDP8', 'Investment.csv');
idxFile = fullfile(repoRoot, 'ExcelFiles', 'PDP8', ...
    'IndexedTrajectories_FossilRenewable_Capacity.csv');
if ~isfile(invFile) || (~useCapitalStock && ~isfile(idxFile))
    msg = sprintf('Required PDP8 files are missing. Investment=%d, Indexed=%d', ...
        isfile(invFile), isfile(idxFile));
    return
end

try
    inv = readtable(invFile, 'VariableNamingRule', 'preserve', ...
        'TreatAsEmpty', {'NA'});
    if ~useCapitalStock
        idx = readtable(idxFile, 'VariableNamingRule', 'preserve', ...
            'TreatAsEmpty', {'NA'});
    end
catch ME
    msg = sprintf('Failed to read PDP8 files: %s', ME.message);
    return
end

requiredInvColumns = {'Plan', 'Year', 'Technology', 'INV_MIOUSD', 'CAP_MIOUSD'};
missingInvColumns = requiredInvColumns( ...
    ~ismember(requiredInvColumns, inv.Properties.VariableNames));
if ~isempty(missingInvColumns)
    msg = sprintf('Investment.csv is missing required columns: %s.', ...
        strjoin(missingInvColumns, ', '));
    return
end
if ~useCapitalStock
    requiredIdxColumns = {'Year', 'TechType', 'Index_Value'};
    missingIdxColumns = requiredIdxColumns( ...
        ~ismember(requiredIdxColumns, idx.Properties.VariableNames));
    if ~isempty(missingIdxColumns)
        msg = sprintf('IndexedTrajectories file is missing required columns: %s.', ...
            strjoin(missingIdxColumns, ', '));
        return
    end
end

invPlan = inv(strcmpi(string(inv.Plan), "PDP8_rev_high"), :);
if isempty(invPlan)
    msg = 'No rows found in Investment.csv for Plan == PDP8_rev_high.';
    return
end

years = reshape(sourceYears, 1, []);
nY = numel(years);
if nY == 0 || any(~isfinite(years))
    msg = 'Source years must be a nonempty finite vector.';
    return
end

invYear = as_numeric(invPlan.Year);
invMio = as_numeric(invPlan.INV_MIOUSD);
capMio = as_numeric(invPlan.CAP_MIOUSD);
tech = string(invPlan.Technology);
isFossilTech = is_fossil_tech(tech);
isRenewTech = ~isFossilTech;

fossilDirect = zeros(1, nY);
renewDirect = zeros(1, nY);
capitalStockFossil = zeros(1, nY);
capitalStockRenew = zeros(1, nY);
for i = 1:nY
    yearMask = invYear == years(i);
    fossilDirect(i) = sum(invMio(yearMask & isFossilTech), 'omitnan');
    renewDirect(i) = sum(invMio(yearMask & isRenewTech), 'omitnan');
    capitalStockFossil(i) = sum(capMio(yearMask & isFossilTech), 'omitnan');
    capitalStockRenew(i) = sum(capMio(yearMask & isRenewTech), 'omitnan');
end

gdpPath = build_projected_gdp_path( ...
    years, gvaGrowth, gdpBaseYear, gdpBaseValueMioUSD);
if any(~isfinite(gdpPath)) || any(gdpPath <= 0)
    msg = 'Projected GDP path contains invalid values. Check total GVA growth inputs.';
    return
end

fossilNewIY = fossilDirect ./ gdpPath;
renewNewIY = renewDirect ./ gdpPath;

if useCapitalStock
    idxBase = find(years == gdpBaseYear, 1, 'first');
    if any(~isfinite(capitalStockFossil)) || any(capitalStockFossil < 0) || ...
            any(~isfinite(capitalStockRenew)) || any(capitalStockRenew < 0) || ...
            capitalStockFossil(idxBase) <= 0 || capitalStockRenew(idxBase) <= 0
        msg = ['Could not determine valid PDP8 CAP_MIOUSD capital stocks for ' ...
            'fossil/renewables. Base-year stocks must be positive; later ' ...
            'stocks may be zero after a technology phase-out.'];
        return
    end

    laggedCapitalFossil = [capitalStockFossil(1), capitalStockFossil(1:end-1)];
    laggedCapitalRenew = [capitalStockRenew(1), capitalStockRenew(1:end-1)];
    fossilMaintIY = deltaMaintFossil .* laggedCapitalFossil ./ gdpPath;
    renewMaintIY = deltaMaintRenewable .* laggedCapitalRenew ./ gdpPath;
else
    idxYear = as_numeric(idx.Year);
    idxType = string(idx.TechType);
    idxVal = as_numeric(idx.Index_Value);

    fossilIdx = read_index_path(idxYear, idxType, idxVal, years, "Fossil");
    renewIdx = read_index_path(idxYear, idxType, idxVal, years, "Renewable");
    missingIdx = ~isfinite(fossilIdx) | ~isfinite(renewIdx);
    if any(missingIdx)
        fossilIdx = fillmissing(fossilIdx, 'previous');
        renewIdx = fillmissing(renewIdx, 'previous');
        if any(~isfinite(fossilIdx)) || any(~isfinite(renewIdx))
            msg = ['Indexed trajectory file is missing Fossil/Renewable index ' ...
                'values and no earlier value is available to carry forward.'];
            return
        end
        warning('compute_pdp8_target_investment_series:IndexedTrajectoryCarryForward', ...
            ['Indexed trajectory file is missing Fossil/Renewable index values ' ...
             'for year(s) %s. The last available value was used.'], ...
            strjoin(string(years(missingIdx)), ', '));
    end

    gdpIndex = gdpPath ./ gdpPath(1);
    fossilMaintIY = deltaMaintFossil .* indexProxyBaseCapitalShareFossil .* ...
        (fossilIdx ./ 100) ./ gdpIndex;
    renewMaintIY = deltaMaintRenewable .* indexProxyBaseCapitalShareRenewable .* ...
        (renewIdx ./ 100) ./ gdpIndex;
end

fossilSeries = fossilNewIY + fossilMaintIY;
renewSeries = renewNewIY + renewMaintIY;
ok = true;
end

function indexPath = read_index_path(idxYear, idxType, idxVal, years, techType)
indexPath = nan(1, numel(years));
for i = 1:numel(years)
    match = idxYear == years(i) & strcmpi(idxType, techType);
    if any(match)
        indexPath(i) = idxVal(find(match, 1, 'first'));
    end
end
end

function gdpPath = build_projected_gdp_path(years, gvaGrowth, gdpBaseYear, gdpBaseValueMioUSD)
factors = normalize_growth_to_factors(gvaGrowth);
if numel(factors) ~= numel(years)
    error('compute_pdp8_target_investment_series:GDPGrowthLengthMismatch', ...
        'GVA growth path length (%d) must match year path length (%d).', ...
        numel(factors), numel(years));
end

idxBase = find(years == gdpBaseYear, 1, 'first');
if isempty(idxBase)
    error('compute_pdp8_target_investment_series:GDPBaseYearMissing', ...
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
v = reshape(totalGrowth, 1, []);
if isempty(v)
    growthFactors = v;
    return
end

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
mask = contains(t, "coal") | contains(t, "gas") | contains(t, "lng") | ...
    contains(t, "oil") | contains(t, "diesel") | contains(t, "nuclear") | ...
    contains(t, "ccgt");
end

function x = as_numeric(v)
if isnumeric(v)
    x = double(v);
else
    x = str2double(string(v));
end
end
