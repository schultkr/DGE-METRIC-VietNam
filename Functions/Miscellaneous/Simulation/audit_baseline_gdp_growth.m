function summary = audit_baseline_gdp_growth(sWorkbookBaseline, sOutputCsv, sSheet, varargin)
% audit_baseline_gdp_growth  Compare Excel baseline targets with simulation output.
%
% The baseline workbook's gY_s_r columns are sector-by-region target factors.
% Under the default YTarget=1 model setting, these are price-weighted
% value-added targets in the model numeraire, so P_s_r * Y_s_r should match
% the target path. Real Y_s_r growth can differ when sector relative prices
% or shadow values move.
%
% Usage:
%   audit_baseline_gdp_growth(sWorkbookBaseline, 'ExcelFiles/Output/Baseline.csv')
%   audit_baseline_gdp_growth(sWorkbookBaseline, outputCsv, 'Baseline')

if nargin < 3 || isempty(sSheet)
    sSheet = 'Baseline';
end

cfg = parse_config(sOutputCsv, varargin{:});

if ~isfile(sWorkbookBaseline)
    error('audit_baseline_gdp_growth:WorkbookNotFound', ...
        'Baseline workbook not found:\n  %s', sWorkbookBaseline);
end

if ~isfile(sOutputCsv)
    error('audit_baseline_gdp_growth:OutputNotFound', ...
        'Simulation output CSV not found:\n  %s', sOutputCsv);
end

targets = read_table_preserve_names(sWorkbookBaseline, 'Sheet', sSheet);
results = read_table_preserve_names(sOutputCsv);

targetNames = targets.Properties.VariableNames;
resultNames = results.Properties.VariableNames;
growthCols = find_growth_columns(targetNames);

if isempty(growthCols)
    warning('audit_baseline_gdp_growth:NoGrowthTargets', ...
        'No gY_s_r target columns found in sheet "%s".', sSheet);
    summary = empty_summary(cfg);
    return
end

targetYears = get_optional_numeric_column(targets, 'Year');
resultYears = get_optional_numeric_column(results, 'Year');

sectorRows = build_sector_audit(targets, results, growthCols, targetNames, ...
    resultNames, targetYears, resultYears);
aggregateRows = build_aggregate_audit(targets, results, growthCols, ...
    targetNames, resultNames, targetYears, resultYears);

if ~isempty(sectorRows)
    writetable(sectorRows, cfg.sectorAuditFile);
end

if ~isempty(aggregateRows)
    writetable(aggregateRows, cfg.aggregateAuditFile);
end

summary = struct();
summary.sectorAuditFile = cfg.sectorAuditFile;
summary.aggregateAuditFile = cfg.aggregateAuditFile;
summary.nSectorRows = height(sectorRows);
summary.nAggregateRows = height(aggregateRows);
summary.maxAbsRealSectorDiff = max_or_nan(sectorRows.AbsDiffRealY);
summary.maxAbsPriceWeightedSectorDiff = max_or_nan(sectorRows.AbsDiffPriceWeightedVA);
summary.maxAbsNominalSectorDiff = summary.maxAbsPriceWeightedSectorDiff;
summary.maxAbsAggregateDiff = max_or_nan(aggregateRows.AbsDiffAggregateY);

if summary.maxAbsPriceWeightedSectorDiff > cfg.tolerance
    warning('audit_baseline_gdp_growth:PriceWeightedTargetMismatch', ...
        ['Baseline price-weighted sector value-added targets differ from the ' ...
         'simulation by as much as %.4g. See %s.'], ...
        summary.maxAbsPriceWeightedSectorDiff, cfg.sectorAuditFile);
end

if summary.maxAbsAggregateDiff > cfg.tolerance
    warning('audit_baseline_gdp_growth:AggregateTargetMismatch', ...
        ['Baseline aggregate value-added growth differs from the ' ...
         'previous-share weighted gY target by as much as %.4g. See %s.'], ...
        summary.maxAbsAggregateDiff, cfg.aggregateAuditFile);
end
end

function sectorRows = build_sector_audit(targets, results, growthCols, ...
    targetNames, resultNames, targetYears, resultYears)

outYear = [];
outRegion = [];
outSubsector = [];
outTarget = [];
outReal = [];
outPriceWeighted = [];
outRealDiff = [];
outPriceWeightedDiff = [];

nTargetRows = height(targets);
for iCol = growthCols(:)'
    sTargetName = targetNames{iCol};
    ids = parse_growth_name(sTargetName);
    if isempty(ids)
        continue
    end

    iSubsector = ids(1);
    iRegion = ids(2);
    sY = sprintf('Y_%d_%d', iSubsector, iRegion);
    sP = sprintf('P_%d_%d', iSubsector, iRegion);
    if ~has_variable(resultNames, sY) || ~has_variable(resultNames, sP)
        continue
    end

    target = to_numeric(targets.(sTargetName));
    y = to_numeric(results.(sY));
    p = to_numeric(results.(sP));

    for iRow = 1:nTargetRows
        if iRow > numel(target) || isnan(target(iRow))
            continue
        end

        [iBase, iNext, iYear] = result_row_pair(iRow, targetYears, resultYears);
        if iNext > numel(y) || iBase > numel(y) || iBase < 1
            continue
        end

        realFactor = y(iNext) / y(iBase);
        priceWeightedFactor = (p(iNext) * y(iNext)) / (p(iBase) * y(iBase));

        outYear(end + 1, 1) = iYear; %#ok<AGROW>
        outRegion(end + 1, 1) = iRegion; %#ok<AGROW>
        outSubsector(end + 1, 1) = iSubsector; %#ok<AGROW>
        outTarget(end + 1, 1) = target(iRow); %#ok<AGROW>
        outReal(end + 1, 1) = realFactor; %#ok<AGROW>
        outPriceWeighted(end + 1, 1) = priceWeightedFactor; %#ok<AGROW>
        outRealDiff(end + 1, 1) = abs(realFactor - target(iRow)); %#ok<AGROW>
        outPriceWeightedDiff(end + 1, 1) = abs(priceWeightedFactor - target(iRow)); %#ok<AGROW>
    end
end

sectorRows = table(outYear, outRegion, outSubsector, outTarget, outReal, ...
    outPriceWeighted, outRealDiff, outPriceWeightedDiff, ...
    'VariableNames', {'Year', 'Region', 'Subsector', 'TargetFactor', ...
    'SimulatedRealYFactor', 'SimulatedPriceWeightedVAFactor', ...
    'AbsDiffRealY', 'AbsDiffPriceWeightedVA'});
end

function aggregateRows = build_aggregate_audit(targets, results, growthCols, ...
    targetNames, resultNames, targetYears, resultYears)

growthMap = parse_growth_columns(growthCols, targetNames);
regions = unique(growthMap(:, 2));

outYear = [];
outRegion = [];
outWeightedTarget = [];
outAggregate = [];
outDiff = [];

for iReg = regions(:)'
    sAggY = sprintf('Y_%d', iReg);
    if ~has_variable(resultNames, sAggY)
        continue
    end

    sectors = growthMap(growthMap(:, 2) == iReg, 1)';
    yAgg = to_numeric(results.(sAggY));

    for iRow = 1:height(targets)
        [iBase, iNext, iYear] = result_row_pair(iRow, targetYears, resultYears);
        if iNext > numel(yAgg) || iBase > numel(yAgg) || iBase < 1
            continue
        end

        weightedTarget = 0;
        sectorPriceWeightedTotal = 0;
        hasAllSectors = true;

        for iSubsector = sectors
            sTarget = sprintf('gY_%d_%d', iSubsector, iReg);
            sY = sprintf('Y_%d_%d', iSubsector, iReg);
            sP = sprintf('P_%d_%d', iSubsector, iReg);

            if ~has_variable(targetNames, sTarget) || ...
               ~has_variable(resultNames, sY) || ...
               ~has_variable(resultNames, sP)
                hasAllSectors = false;
                break
            end

            target = to_numeric(targets.(sTarget));
            y = to_numeric(results.(sY));
            p = to_numeric(results.(sP));
            if iRow > numel(target) || isnan(target(iRow))
                hasAllSectors = false;
                break
            end

            sectorPriceWeighted = p(iBase) * y(iBase);
            sectorPriceWeightedTotal = sectorPriceWeightedTotal + sectorPriceWeighted;
            weightedTarget = weightedTarget + sectorPriceWeighted * target(iRow);
        end

        if ~hasAllSectors || sectorPriceWeightedTotal == 0
            continue
        end

        weightedTarget = weightedTarget / sectorPriceWeightedTotal;
        aggregateFactor = yAgg(iNext) / yAgg(iBase);

        outYear(end + 1, 1) = iYear; %#ok<AGROW>
        outRegion(end + 1, 1) = iReg; %#ok<AGROW>
        outWeightedTarget(end + 1, 1) = weightedTarget; %#ok<AGROW>
        outAggregate(end + 1, 1) = aggregateFactor; %#ok<AGROW>
        outDiff(end + 1, 1) = abs(aggregateFactor - weightedTarget); %#ok<AGROW>
    end
end

aggregateRows = table(outYear, outRegion, outWeightedTarget, outAggregate, outDiff, ...
    'VariableNames', {'Year', 'Region', 'WeightedTargetFactor', ...
    'SimulatedAggregateYFactor', 'AbsDiffAggregateY'});
end

function cfg = parse_config(sOutputCsv, varargin)
[outDir, outName] = fileparts(sOutputCsv);
if isempty(outDir)
    outDir = pwd();
end

cfg = struct();
cfg.tolerance = 1e-8;
cfg.sectorAuditFile = fullfile(outDir, [outName '_GDPGrowthAudit_Sectors.csv']);
cfg.aggregateAuditFile = fullfile(outDir, [outName '_GDPGrowthAudit_Aggregate.csv']);

if mod(numel(varargin), 2) ~= 0
    error('audit_baseline_gdp_growth:InvalidArguments', ...
        'Optional arguments must be name/value pairs.');
end

for iArg = 1:2:numel(varargin)
    sName = lower(varargin{iArg});
    value = varargin{iArg + 1};
    switch sName
        case 'tolerance'
            cfg.tolerance = value;
        case 'sectorauditfile'
            cfg.sectorAuditFile = char(value);
        case 'aggregateauditfile'
            cfg.aggregateAuditFile = char(value);
        otherwise
            error('audit_baseline_gdp_growth:UnknownArgument', ...
                'Unknown option "%s".', varargin{iArg});
    end
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

function cols = find_growth_columns(names)
cols = [];
for i = 1:numel(names)
    if ~isempty(parse_growth_name(names{i}))
        cols(end + 1) = i; %#ok<AGROW>
    end
end
end

function growthMap = parse_growth_columns(cols, names)
growthMap = zeros(numel(cols), 2);
for i = 1:numel(cols)
    growthMap(i, :) = parse_growth_name(names{cols(i)});
end
end

function ids = parse_growth_name(sName)
tokens = regexp(sName, '^gY_(\d+)_(\d+)$', 'tokens', 'once');
if isempty(tokens)
    ids = [];
else
    ids = [str2double(tokens{1}), str2double(tokens{2})];
end
end

function tf = has_variable(names, sName)
tf = any(strcmp(names, sName));
end

function x = get_optional_numeric_column(tab, sName)
if has_variable(tab.Properties.VariableNames, sName)
    x = to_numeric(tab.(sName));
else
    x = [];
end
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

function [iBase, iNext, iYear] = result_row_pair(iTargetRow, targetYears, resultYears)
if ~isempty(targetYears) && ~isempty(resultYears) && ...
        iTargetRow <= numel(targetYears) && ~isnan(targetYears(iTargetRow))
    iYear = targetYears(iTargetRow);
    iNext = find(abs(resultYears - iYear) < 1e-10, 1);
    iBase = find(abs(resultYears - (iYear - 1)) < 1e-10, 1);
    if ~isempty(iNext) && ~isempty(iBase)
        return
    end
end

iBase = iTargetRow;
iNext = iTargetRow + 1;
if ~isempty(targetYears) && iTargetRow <= numel(targetYears)
    iYear = targetYears(iTargetRow);
elseif ~isempty(resultYears) && iNext <= numel(resultYears)
    iYear = resultYears(iNext);
else
    iYear = iNext;
end
end

function value = max_or_nan(x)
if isempty(x)
    value = NaN;
else
    value = max(x);
end
end

function summary = empty_summary(cfg)
summary = struct();
summary.sectorAuditFile = cfg.sectorAuditFile;
summary.aggregateAuditFile = cfg.aggregateAuditFile;
summary.nSectorRows = 0;
summary.nAggregateRows = 0;
summary.maxAbsRealSectorDiff = NaN;
summary.maxAbsPriceWeightedSectorDiff = NaN;
summary.maxAbsNominalSectorDiff = NaN;
summary.maxAbsAggregateDiff = NaN;
end
