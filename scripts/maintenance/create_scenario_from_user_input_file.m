% create_scenario_from_user_input_file  Build a runnable scenario sheet from user input.
%
% Run from the repository root:
%   run('scripts/maintenance/create_scenario_from_user_input_file.m')
%
% Set ScenarioName to the sheet name in ScenarioPathDefinition.xlsx to read from.
% The same name is used as the target sheet in ModelScenarios workbook.
%
% Two sources for row data are supported (both always active):
%   1) Structured GVA/employment block (rows 10, 12-16, 22, 24-28) — used when
%      WriteGrowthRates = true to produce gY_s_1 / gN_s_1 paths.
%   2) Generic exo_/idx_ rows (column B = Import Key, column C = Conversion Rule)
%      — always written to the target sheet.

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

% -------------------------------------------------------------------------
% User configuration
% -------------------------------------------------------------------------

% Sheet name in ScenarioPathDefinition.xlsx (source) and ModelScenarios (target).
ScenarioName = 'NZ';

% Set to true if the scenario sheet has GVA growth (row 10) and VA shares (rows 12-16)
% plus employment growth (row 22) and employment shares (rows 24-28).
% When true, sector growth rates gY_s_1 / gN_s_1 are computed and written.
WriteGrowthRates = false;

% GDP anchor used only when WriteGrowthRates = true and UsePDP8InvestmentTargets = true.
ProjectedGDPBaseYear = 2025;
ProjectedGDPBaseValueMioUSD = 430000;

% Optional: map industrial rooftop PV deployment to direct EE gains.
% Mirrors the same feature in create_baseline_from_user_input_file.m.
EnableIndustrialPVtoEECoupling = false;
IndustrialPVGATargetSubsector = 4;
CommercialPVGATargetSubsector = 5;
IndustrialPVMaxDemandReduction_Secondary = 0.08;
IndustrialPVMaxDemandReduction_Tertiary  = 0.075;
IndustrialElecDemandBase_GWh = 177550;
CommercialElecDemandBase_GWh = 56950;
ElecDemandAnnualGrowth_Ind   = 0.040;
ElecDemandAnnualGrowth_Com   = 0.040;

% Optional: apply VNEEP3 sector-specific EE targets on top of PV paths.
EnableVNEEP3EETargets = false;
EEAdditiveMode = true;
VNEEP3_Ind_AIRate_To2030   = 0.005;
VNEEP3_Ind_AIRate_Post2030 = 0.003;
VNEEP3_Com_AIRate_To2030   = 0.020;
VNEEP3_Com_AIRate_Post2030 = 0.010;
VNEEP3_Ind_GARate_To2030   = 0.003;
VNEEP3_Ind_GARate_Post2030 = 0.002;
VNEEP3_Com_GARate_To2030   = 0.002;
VNEEP3_Com_GARate_Post2030 = 0.001;

% Source / target workbooks.
sourceWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ScenarioPathDefinition.xlsx');
targetWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions.xlsx');
srcSheet = ScenarioName;
tgtSheet = ScenarioName;

% -------------------------------------------------------------------------
% Validation
% -------------------------------------------------------------------------
if ~isfile(sourceWorkbook)
    error('create_scenario_from_user_input_file:SourceNotFound', ...
        'Source workbook not found:\n  %s', sourceWorkbook);
end
if ~isfile(targetWorkbook)
    error('create_scenario_from_user_input_file:TargetNotFound', ...
        'Target workbook not found:\n  %s', targetWorkbook);
end

% -------------------------------------------------------------------------
% Read source inputs
% -------------------------------------------------------------------------
inputs = import_scenario_inputs(sourceWorkbook, srcSheet, WriteGrowthRates);
inputs.repoRoot = repoRoot;
inputs.enableIndustrialPVtoEECoupling = EnableIndustrialPVtoEECoupling;
inputs.industrialPVGATargetSubsector  = IndustrialPVGATargetSubsector;
inputs.commercialPVGATargetSubsector  = CommercialPVGATargetSubsector;
inputs.industrialPVMaxDemandReductionSecondary = IndustrialPVMaxDemandReduction_Secondary;
inputs.industrialPVMaxDemandReductionTertiary  = IndustrialPVMaxDemandReduction_Tertiary;
inputs.industrialElecDemandBaseGWh    = IndustrialElecDemandBase_GWh;
inputs.commercialElecDemandBaseGWh    = CommercialElecDemandBase_GWh;
inputs.elecDemandAnnualGrowthInd      = ElecDemandAnnualGrowth_Ind;
inputs.elecDemandAnnualGrowthCom      = ElecDemandAnnualGrowth_Com;
inputs.eeAdditiveMode                 = EEAdditiveMode;
inputs.enableVNEEP3EETargets          = EnableVNEEP3EETargets;
inputs.vneep3IndAIRateTo2030          = VNEEP3_Ind_AIRate_To2030;
inputs.vneep3IndAIRatePost2030        = VNEEP3_Ind_AIRate_Post2030;
inputs.vneep3ComAIRateTo2030          = VNEEP3_Com_AIRate_To2030;
inputs.vneep3ComAIRatePost2030        = VNEEP3_Com_AIRate_Post2030;
inputs.vneep3IndGARateTo2030          = VNEEP3_Ind_GARate_To2030;
inputs.vneep3IndGARatePost2030        = VNEEP3_Ind_GARate_Post2030;
inputs.vneep3ComGARateTo2030          = VNEEP3_Com_GARate_To2030;
inputs.vneep3ComGARatePost2030        = VNEEP3_Com_GARate_Post2030;

% -------------------------------------------------------------------------
% Write to target scenario sheet
% -------------------------------------------------------------------------
nYears = numel(inputs.yearsOut);

headers = readcell(targetWorkbook, 'Sheet', tgtSheet, 'Range', '1:1');
if isempty(headers)
    headers = {};
end

% Ensure Time column.
[headers, ~] = ensure_column_exists(targetWorkbook, tgtSheet, headers, 'Time', nYears, 'direct');
write_series_to_column(targetWorkbook, tgtSheet, headers, 'Time', (2:nYears + 1)', nYears);

% Generic exo_/idx_ rows from source sheet.
write_generic_optional_paths(targetWorkbook, tgtSheet, headers, inputs, nYears);
headers = readcell(targetWorkbook, 'Sheet', tgtSheet, 'Range', '1:1');

% Optional PV->EE coupling.
headers = apply_industrial_pv_to_ee_coupling(targetWorkbook, tgtSheet, headers, inputs, inputs.yearsOut, nYears);

% Optional VNEEP3 EE targets.
headers = apply_vneep3_ee_targets(targetWorkbook, tgtSheet, headers, inputs, inputs.yearsOut, nYears);

% Optional growth rates (gY / gN).
if WriteGrowthRates
    write_growth_rates_to_scenario(targetWorkbook, tgtSheet, headers, inputs);
end

fprintf('\nCreateScenarioFromUserInputFile complete.\n');
fprintf('  Scenario:       %s\n', ScenarioName);
fprintf('  Source: %s  [%s]\n', sourceWorkbook, srcSheet);
fprintf('  Target: %s  [%s]\n', targetWorkbook, tgtSheet);
fprintf('  Periods written: %d  (%d-%d)\n', nYears, inputs.yearsOut(1), inputs.yearsOut(end));

% =========================================================================
% Local functions
% =========================================================================

function inputs = import_scenario_inputs(sourceWorkbook, srcSheet, readGrowth)
srcStartCol = 'E';
srcEndCol   = 'AD';

yearHeader = readcell(sourceWorkbook, 'Sheet', srcSheet, 'Range', [srcStartCol '9:' srcEndCol '9']);
sourceYears = parse_year_header(yearHeader, srcSheet);

% Model periods start one year after the base year in the header.
targetStartYear = sourceYears(1) + 1;
yearsOut = sourceYears(sourceYears >= targetStartYear);

inputs = struct();
inputs.years       = sourceYears;
inputs.yearsOut    = yearsOut;
inputs.sourceWorkbook = sourceWorkbook;
inputs.sourceSheet    = srcSheet;
inputs.sourceStartCol = srcStartCol;
inputs.sourceEndCol   = srcEndCol;

if readGrowth
    gvaGrowth = readmatrix(sourceWorkbook, 'Sheet', srcSheet, 'Range', [srcStartCol '10:' srcEndCol '10']);
    vaShares  = readmatrix(sourceWorkbook, 'Sheet', srcSheet, 'Range', [srcStartCol '12:' srcEndCol '16']);
    empGrowth = readmatrix(sourceWorkbook, 'Sheet', srcSheet, 'Range', [srcStartCol '22:' srcEndCol '22']);
    empShares = readmatrix(sourceWorkbook, 'Sheet', srcSheet, 'Range', [srcStartCol '24:' srcEndCol '28']);

    if numel(gvaGrowth) ~= numel(sourceYears) || numel(empGrowth) ~= numel(sourceYears) || ...
            size(vaShares, 2) ~= numel(sourceYears) || size(empShares, 2) ~= numel(sourceYears)
        error('create_scenario_from_user_input_file:UnexpectedGrowthLayout', ...
            'Growth/share block dimensions do not match the year header in sheet %s.', srcSheet);
    end

    inputs.gvaGrowth = reshape(gvaGrowth, 1, []);
    inputs.vaShares  = vaShares;
    inputs.empGrowth = reshape(empGrowth, 1, []);
    inputs.empShares = empShares;
end

% Generic exo_/idx_ paths.
inputs.rowDefs = read_user_defined_rows(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, sourceYears, yearsOut);

% Structured optional path groups (mirrors baseline import structure).
inputs.pvPath = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_PV_1', 'exo_PV_1', 'pv_path', 'rooftop pv', 'Rooftop PV investment index'});
inputs.pvProductionPath = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_PVEff_1', 'exo_PVEff_1', 'pv production', 'rooftop pv production', ...
     'Rooftop PV production index', 'Rooftop PV efficiency index'});
end

% -------------------------------------------------------------------------

function write_growth_rates_to_scenario(targetWorkbook, tgtSheet, headers, inputs)
targetStartYear = inputs.yearsOut(1);

[gY, years] = compute_sector_growth_factors( ...
    inputs.gvaGrowth, inputs.vaShares, inputs.years, targetStartYear);
[gN, yearsEmp] = compute_sector_growth_factors( ...
    inputs.empGrowth, inputs.empShares, inputs.years, targetStartYear);

if ~isequal(years, yearsEmp)
    error('create_scenario_from_user_input_file:YearAlignmentMismatch', ...
        'GVA and employment growth year ranges are not aligned in scenario sheet.');
end

nYears = numel(years);
for iSub = 1:size(gY, 1)
    gYName = sprintf('gY_%d_1', iSub);
    gNName = sprintf('gN_%d_1', iSub);

    [headers, ~] = ensure_column_exists(targetWorkbook, tgtSheet, headers, gYName, nYears, 'direct');
    [headers, ~] = ensure_column_exists(targetWorkbook, tgtSheet, headers, gNName, nYears, 'direct');
    headers = readcell(targetWorkbook, 'Sheet', tgtSheet, 'Range', '1:1');

    write_series_to_column(targetWorkbook, tgtSheet, headers, gYName, gY(iSub, :)', nYears);
    write_series_to_column(targetWorkbook, tgtSheet, headers, gNName, gN(iSub, :)', nYears);
end

fprintf('  Wrote sector growth rates for %d subsectors (%d periods).\n', size(gY, 1), nYears);
end

% -------------------------------------------------------------------------

function write_generic_optional_paths(targetWorkbook, tgtSheet, headers, inputs, nYears)
if isempty(inputs.rowDefs)
    return
end

created = {};
for i = 1:numel(inputs.rowDefs)
    def = inputs.rowDefs(i);
    [headers, wasCreated] = ensure_column_exists(targetWorkbook, tgtSheet, headers, ...
        def.importKey, nYears, def.conversionRule);
    if wasCreated
        created{end + 1} = def.importKey; %#ok<AGROW>
        headers = readcell(targetWorkbook, 'Sheet', tgtSheet, 'Range', '1:1');
    end
    write_series_to_column(targetWorkbook, tgtSheet, headers, def.importKey, def.series(:), nYears);
end

if ~isempty(created)
    fprintf('  Scenario dynamic columns added: %s\n', strjoin(created, ', '));
end
end

% -------------------------------------------------------------------------

function headersOut = apply_industrial_pv_to_ee_coupling(targetWorkbook, targetSheet, headersIn, inputs, yearsRef, nYears)
headersOut = headersIn;
if ~isfield(inputs, 'enableIndustrialPVtoEECoupling') || ~inputs.enableIndustrialPVtoEECoupling
    return
end

subsecInd = get_scalar_field(inputs, 'industrialPVGATargetSubsector', 4);
subsecCom = get_scalar_field(inputs, 'commercialPVGATargetSubsector', 5);
aiVarSec  = sprintf('exo_AI_%d_1_2', subsecInd);
aiVarTer  = sprintf('exo_AI_%d_1_2', subsecCom);

demandSecBase = get_scalar_field(inputs, 'industrialElecDemandBaseGWh', 177550);
demandTerBase = get_scalar_field(inputs, 'commercialElecDemandBaseGWh', 56950);
gInd = get_scalar_field(inputs, 'elecDemandAnnualGrowthInd', 0.040);
gCom = get_scalar_field(inputs, 'elecDemandAnnualGrowthCom', 0.040);

pvSeries = read_scenario_series(targetWorkbook, targetSheet, headersIn, 'exo_PV_1', nYears);
if isempty(pvSeries)
    warning('create_scenario_from_user_input_file:IndustrialPVPathMissing', ...
        'No exo_PV_1 column found; skipping PV->EE coupling.');
    return
end

tRel = (0:nYears-1)';
demandSec = demandSecBase .* (1 + gInd).^tRel;
demandTer = demandTerBase .* (1 + gCom).^tRel;
phiSec = min(pvSeries(:) ./ demandSec, 0.9999);
phiTer = min(pvSeries(:) ./ demandTer, 0.9999);
etaAddSec = log((1 - phiSec(1)) ./ (1 - phiSec));
etaAddTer = log((1 - phiTer(1)) ./ (1 - phiTer));

for info = {subsecInd, aiVarSec, etaAddSec; subsecCom, aiVarTer, etaAddTer}'
    varName = info{2};
    eta     = info{3};
    [headersOut, wasCreated] = ensure_column_exists(targetWorkbook, targetSheet, headersOut, ...
        varName, nYears, 'log(index)');
    if wasCreated
        headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
    end
    existing = read_scenario_series(targetWorkbook, targetSheet, headersOut, varName, nYears);
    if isempty(existing), existing = zeros(nYears, 1); end
    write_series_to_column(targetWorkbook, targetSheet, headersOut, varName, existing(:) + eta(:), nYears);
end

fprintf('  Applied PV->EE effectiveness coupling (gen/demand coverage fractions).\n');
end

% -------------------------------------------------------------------------

function headersOut = apply_vneep3_ee_targets(targetWorkbook, targetSheet, headersIn, inputs, yearsRef, nYears)
headersOut = headersIn;
if ~isfield(inputs, 'enableVNEEP3EETargets') || ~inputs.enableVNEEP3EETargets
    return
end

subsecInd = get_scalar_field(inputs, 'industrialPVGATargetSubsector', 4);
subsecCom = get_scalar_field(inputs, 'commercialPVGATargetSubsector', 5);

aiRateIndTo2030   = get_scalar_field(inputs, 'vneep3IndAIRateTo2030',   0.005);
aiRateIndPost2030 = get_scalar_field(inputs, 'vneep3IndAIRatePost2030', 0.003);
aiRateComTo2030   = get_scalar_field(inputs, 'vneep3ComAIRateTo2030',   0.020);
aiRateComPost2030 = get_scalar_field(inputs, 'vneep3ComAIRatePost2030', 0.010);
gaRateIndTo2030   = get_scalar_field(inputs, 'vneep3IndGARateTo2030',   0.003);
gaRateIndPost2030 = get_scalar_field(inputs, 'vneep3IndGARatePost2030', 0.002);
gaRateComTo2030   = get_scalar_field(inputs, 'vneep3ComGARateTo2030',   0.002);
gaRateComPost2030 = get_scalar_field(inputs, 'vneep3ComGARatePost2030', 0.001);

t = (0:nYears-1)';
idx2030 = find(yearsRef >= 2030, 1);
nYearsTo2030 = min(idx2030, nYears);
if isempty(nYearsTo2030), nYearsTo2030 = min(5, nYears); end
pw = @(rTo, rPost) rTo * min(t+1, nYearsTo2030) + rPost * max(t+1 - nYearsTo2030, 0);

aiInd = pw(aiRateIndTo2030, aiRateIndPost2030);
aiCom = pw(aiRateComTo2030, aiRateComPost2030);
gaInd = pw(gaRateIndTo2030, gaRateIndPost2030);
gaCom = pw(gaRateComTo2030, gaRateComPost2030);

for sInfo = {subsecInd, aiInd; subsecCom, aiCom}'
    sub = sInfo{1};  inc = sInfo{2};
    varName = sprintf('exo_AI_%d_1_2', sub);
    [headersOut, wasCreated] = ensure_column_exists(targetWorkbook, targetSheet, headersOut, varName, nYears, 'log(index)');
    if wasCreated, headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1'); end
    existing = read_scenario_series(targetWorkbook, targetSheet, headersOut, varName, nYears);
    if isempty(existing), existing = zeros(nYears, 1); end
    write_series_to_column(targetWorkbook, targetSheet, headersOut, varName, (existing(:) + inc)', nYears);
end

for sInfo = {subsecInd, gaInd; subsecCom, gaCom}'
    sub = sInfo{1};  inc = sInfo{2};
    varName = sprintf('exo_GA_%d_1', sub);
    [headersOut, wasCreated] = ensure_column_exists(targetWorkbook, targetSheet, headersOut, varName, nYears, 'direct (index)');
    if wasCreated, headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1'); end
    existing = read_scenario_series(targetWorkbook, targetSheet, headersOut, varName, nYears);
    if isempty(existing), existing = zeros(nYears, 1); end
    write_series_to_column(targetWorkbook, targetSheet, headersOut, varName, (existing(:) + inc)', nYears);
end

additive = get_scalar_field(inputs, 'eeAdditiveMode', true);
lAddEEVal = double(logical(additive));

regIdxFound = [];
for rr = 1:20
    if ~isempty(find_header_index(headersOut, sprintf('exo_EE_%d', rr)))
        regIdxFound(end+1) = rr; %#ok<AGROW>
    end
end
if isempty(regIdxFound), regIdxFound = 1; end

existingSubsecs = [];
for rr = regIdxFound
    for ss = 1:30
        if ~isempty(find_header_index(headersOut, sprintf('exo_lAddEE_%d_%d', ss, rr)))
            existingSubsecs(end+1) = ss; %#ok<AGROW>
        end
    end
end
existingSubsecs = unique([existingSubsecs, subsecInd, subsecCom]);

for rr = regIdxFound
    for ss = existingSubsecs
        switchVar = sprintf('exo_lAddEE_%d_%d', ss, rr);
        [headersOut, wasCreated] = ensure_column_exists(targetWorkbook, targetSheet, headersOut, switchVar, nYears, 'binary');
        if wasCreated, headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1'); end
        write_series_to_column(targetWorkbook, targetSheet, headersOut, switchVar, repmat(lAddEEVal, 1, nYears), nYears);
    end

    if ~additive
        eeVar = sprintf('exo_EE_%d', rr);
        [headersOut, wasCreated] = ensure_column_exists(targetWorkbook, targetSheet, headersOut, eeVar, nYears, 'log(index)');
        if wasCreated, headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1'); end
        write_series_to_column(targetWorkbook, targetSheet, headersOut, eeVar, zeros(1, nYears), nYears);
    end
end

modeStr = 'additive (exo_EE_r kept)';
if ~additive, modeStr = 'sole-driver (exo_EE_r zeroed)'; end
fprintf(['  Applied VNEEP3 EE targets [%s]: ' ...
    'ind AI +%.3f/+%.3f log/yr, GA +%.3f/+%.3f per yr; ' ...
    'com AI +%.3f/+%.3f log/yr, GA +%.3f/+%.3f per yr (to2030/post2030).\n'], ...
    modeStr, ...
    aiRateIndTo2030, aiRateIndPost2030, gaRateIndTo2030, gaRateIndPost2030, ...
    aiRateComTo2030, aiRateComPost2030, gaRateComTo2030, gaRateComPost2030);
end

% =========================================================================
% Utility functions
% =========================================================================

function rowDefs = read_user_defined_rows(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, sourceYears, yearsOut)
meta = readcell(sourceWorkbook, 'Sheet', srcSheet, 'Range', 'A1:D300');
rowDefs = struct('rowNum', {}, 'importKey', {}, 'conversionRule', {}, 'series', {});

for r = 10:size(meta, 1)
    keyCell = meta{r, 2};
    if ~(ischar(keyCell) || isstring(keyCell)), continue; end
    key = strtrim(char(string(keyCell)));
    if isempty(key), continue; end

    keyNorm = normalize_label_text(key);
    if strcmp(keyNorm, 'section header'), continue; end

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
    if isempty(raw) || all(isnan(raw)), continue; end
    if any(~isfinite(raw))
        warning('create_scenario_from_user_input_file:NonFiniteValues', ...
            'Path %s (row %d) contains non-finite values; skipping.', key, r);
        continue
    end

    trimmed = trim_to_model_years(raw, sourceYears, yearsOut(1));
    if isempty(trimmed), continue; end
    converted = apply_conversion_rule(trimmed, rule, key, r);

    rowDefs(end + 1) = struct( ...
        'rowNum', r, ...
        'importKey', key, ...
        'conversionRule', rule, ...
        'series', converted); %#ok<AGROW>
end
end

% -------------------------------------------------------------------------

function series = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, labelCandidates)
labelBlock = readcell(sourceWorkbook, 'Sheet', srcSheet, 'Range', 'A1:D300');
series = [];
for i = 1:numel(labelCandidates)
    s = read_single_labeled_path(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, labelBlock, labelCandidates{i});
    if ~isempty(s)
        series = s;
        return
    end
end
end

function series = read_single_labeled_path(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, labelBlock, label)
series = [];
labelNorm = normalize_label_text(label);
[nR, nC] = size(labelBlock);
rowFound = [];
for r = 1:nR
    for c = 1:nC
        v = labelBlock{r, c};
        if isstring(v) || ischar(v)
            cellNorm = normalize_label_text(v);
            if strcmp(cellNorm, labelNorm) || contains(cellNorm, labelNorm) || contains(labelNorm, cellNorm)
                rowFound = r;
                break
            end
        end
    end
    if ~isempty(rowFound), break; end
end
if isempty(rowFound), return; end
series = reshape(readmatrix(sourceWorkbook, 'Sheet', srcSheet, ...
    'Range', sprintf('%s%d:%s%d', srcStartCol, rowFound, srcEndCol, rowFound)), 1, []);
end

% -------------------------------------------------------------------------

function series = read_scenario_series(targetWorkbook, targetSheet, headers, varName, nYears)
series = [];
iCol = find_header_index(headers, varName);
if isempty(iCol), return; end
col = excel_col_name(iCol);
series = readmatrix(targetWorkbook, 'Sheet', targetSheet, ...
    'Range', sprintf('%s2:%s%d', col, col, nYears + 1));
series = reshape(series, [], 1);
if numel(series) ~= nYears, series = []; end
end

% -------------------------------------------------------------------------

function [headersOut, wasCreated] = ensure_column_exists(targetWorkbook, targetSheet, headersIn, varName, nYears, ruleText)
headersOut = headersIn;
wasCreated = false;
if ~isempty(find_header_index(headersOut, varName)), return; end

isRealHeader = @(x) (ischar(x) && ~isempty(x)) || (isstring(x) && strlength(x) > 0);
lastNonEmpty = find(cellfun(isRealHeader, headersOut), 1, 'last');
if isempty(lastNonEmpty), lastNonEmpty = 1; end

iNewCol = lastNonEmpty + 1;
colNew = excel_col_name(iNewCol);
writecell({varName}, targetWorkbook, 'Sheet', targetSheet, 'Range', sprintf('%s1', colNew));

ruleNorm = normalize_rule_text(ruleText);
if strcmpi(varName, 'Time')
    defaultVals = (2:nYears + 1)';
elseif startsWith(lower(varName), 'idx_') || startsWith(lower(varName), 'exo_r_g_')
    defaultVals = ones(nYears, 1);
else
    defaultVals = zeros(nYears, 1);
end

writematrix(defaultVals, targetWorkbook, 'Sheet', targetSheet, ...
    'Range', sprintf('%s2:%s%d', colNew, colNew, nYears + 1));
headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
wasCreated = true;
end

% -------------------------------------------------------------------------

function write_series_to_column(targetWorkbook, targetSheet, headers, varName, seriesCol, nYears)
if isempty(seriesCol), return; end
iCol = find_header_index(headers, varName);
if isempty(iCol)
    warning('create_scenario_from_user_input_file:MissingColumn', ...
        'Column "%s" not found after creation; skipping write.', varName);
    return
end
if numel(seriesCol) ~= nYears
    error('create_scenario_from_user_input_file:LengthMismatch', ...
        'Column "%s" has %d values, expected %d.', varName, numel(seriesCol), nYears);
end
col = excel_col_name(iCol);
writematrix(seriesCol(:), targetWorkbook, 'Sheet', targetSheet, ...
    'Range', sprintf('%s2:%s%d', col, col, nYears + 1));
end

% -------------------------------------------------------------------------

function converted = apply_conversion_rule(seriesRow, ruleText, importKey, rowNum)
ruleNorm = normalize_rule_text(ruleText);

if isempty(ruleNorm) || strcmp(ruleNorm, 'direct') || contains(ruleNorm, 'direct')
    converted = seriesRow;
    return
end

if contains(ruleNorm, 'binary') || contains(ruleNorm, 'value 0')
    if any(seriesRow < 0)
        error('create_scenario_from_user_input_file:InvalidBinaryInput', ...
            'Binary rule for %s (row %d) does not allow negative values.', importKey, rowNum);
    end
    converted = double(seriesRow > 0);
    return
end

if contains(ruleNorm, 'additive') || (contains(ruleNorm, 'index') && contains(ruleNorm, 'index 1') && contains(ruleNorm, 'minus'))
    if any(seriesRow <= 0)
        error('create_scenario_from_user_input_file:NonPositiveIndex', ...
            'Additive index rule for %s (row %d) requires positive values.', importKey, rowNum);
    end
    converted = seriesRow - seriesRow(1);
    return
end

if contains(ruleNorm, 'log') && contains(ruleNorm, 'index index 1')
    if any(seriesRow <= 0)
        error('create_scenario_from_user_input_file:NonPositiveIndex', ...
            'Log index/index(1) rule for %s (row %d) requires positive values.', importKey, rowNum);
    end
    converted = log(seriesRow ./ seriesRow(1));
    return
end

if contains(ruleNorm, 'log') && contains(ruleNorm, 'index')
    if any(seriesRow <= 0)
        error('create_scenario_from_user_input_file:NonPositiveIndex', ...
            'Log index rule for %s (row %d) requires positive values.', importKey, rowNum);
    end
    converted = log(seriesRow);
    return
end

error('create_scenario_from_user_input_file:UnknownConversionRule', ...
    'Unknown conversion rule "%s" for %s (row %d).', ruleText, importKey, rowNum);
end

% -------------------------------------------------------------------------

function [growth, yearsOut] = compute_sector_growth_factors(totalGrowth, shares, years, targetStartYear)
if size(shares, 2) ~= numel(totalGrowth) || numel(years) ~= numel(totalGrowth)
    error('create_scenario_from_user_input_file:GrowthShareLengthMismatch', ...
        'Share and year path lengths must match growth path length.');
end

totalGrowthFactors = normalize_growth_to_factors(totalGrowth);
if any(totalGrowthFactors <= 0)
    error('create_scenario_from_user_input_file:NonPositiveGrowth', ...
        'Growth input implies nonpositive factors.');
end
if any(shares(:) <= 0)
    error('create_scenario_from_user_input_file:NonPositiveShare', ...
        'All sector shares must be strictly positive.');
end
shareSums = sum(shares, 1);
if any(abs(shareSums - 1) > 1e-4)
    error('create_scenario_from_user_input_file:InvalidShares', ...
        'Sector shares must sum to 1 in each year.');
end

idxStart = find(years >= targetStartYear, 1, 'first');
if isempty(idxStart)
    error('create_scenario_from_user_input_file:NoYearsAfterStart', ...
        'No source years >= %d found.', targetStartYear);
end
if idxStart == 1
    error('create_scenario_from_user_input_file:MissingPreStartYear', ...
        'Input must contain one year before the model start year (%d).', targetStartYear);
end

idxOut  = idxStart:numel(years);
prevIdx = (idxStart - 1):(numel(years) - 1);
growth  = shares(:, idxOut) ./ shares(:, prevIdx);
growth  = growth .* repmat(reshape(totalGrowthFactors(idxOut), 1, []), size(shares, 1), 1);
yearsOut = years(idxOut);
end

% -------------------------------------------------------------------------

function growthFactors = normalize_growth_to_factors(totalGrowth)
if isempty(totalGrowth), growthFactors = totalGrowth; return; end
v = reshape(totalGrowth, 1, []);
vMax = max(v); vMin = min(v);
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

% -------------------------------------------------------------------------

function trimmed = trim_to_model_years(series, sourceYears, targetStartYear)
idx = sourceYears >= targetStartYear;
trimmed = series(idx);
end

% -------------------------------------------------------------------------

function years = parse_year_header(yearHeader, srcSheet)
years = nan(1, numel(yearHeader));
for i = 1:numel(yearHeader)
    v = yearHeader{i};
    if isa(v, 'datetime')
        years(i) = year(v);
    elseif isnumeric(v) && ~isnan(v) && v > 1900 && v < 3000
        years(i) = v;
    elseif isnumeric(v) && ~isnan(v)
        try, years(i) = year(datetime(v, 'ConvertFrom', 'excel')); catch, end
    elseif ischar(v) || isstring(v)
        n = str2double(strtrim(string(v)));
        if ~isnan(n) && n > 1900 && n < 3000
            years(i) = n;
        else
            tok = regexp(char(strtrim(string(v))), '(19|20)\d{2}', 'match', 'once');
            if ~isempty(tok), years(i) = str2double(tok); end
        end
    end
end
if any(isnan(years))
    iV = find(~isnan(years), 1, 'first');
    if isempty(iV)
        error('create_scenario_from_user_input_file:InvalidYearHeader', ...
            'Could not parse any year values in header row 9 of sheet %s.', srcSheet);
    end
    startY = years(iV) - (iV - 1);
    years = startY + (0:numel(yearHeader) - 1);
    warning('create_scenario_from_user_input_file:YearHeaderInferred', ...
        'Could not parse all year headers in %s; using %d:%d.', srcSheet, years(1), years(end));
end
end

% -------------------------------------------------------------------------

function iCol = find_header_index(headers, varName)
iCol = find(strcmpi(string(headers), string(varName)), 1);
end

% -------------------------------------------------------------------------

function out = normalize_rule_text(in)
if isempty(in), out = ''; return; end
out = lower(strtrim(string(in)));
out = regexprep(out, '[^a-z0-9]+', ' ');
out = strtrim(regexprep(out, '\s+', ' '));
end

% -------------------------------------------------------------------------

function out = normalize_label_text(in)
out = lower(strtrim(string(in)));
out = regexprep(out, '[^a-z0-9]+', ' ');
out = strtrim(regexprep(out, '\s+', ' '));
end

% -------------------------------------------------------------------------

function v = get_scalar_field(s, fname, default)
if isfield(s, fname) && isscalar(s.(fname)) && isfinite(s.(fname))
    v = s.(fname);
else
    v = default;
end
end

% -------------------------------------------------------------------------

function col = excel_col_name(iCol)
if iCol < 1
    error('create_scenario_from_user_input_file:InvalidColumnIndex', ...
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
