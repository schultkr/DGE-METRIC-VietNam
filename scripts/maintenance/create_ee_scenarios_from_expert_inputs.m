% create_ee_scenarios_from_expert_inputs  Build EE and BESS scenario sheets from expert workbook.
%
% Run from the repository root:
%   run('scripts/maintenance/create_ee_scenarios_from_expert_inputs.m')
%
% Source (preferred): ExcelFiles/PDP8/Vietnam_EnergyExpert_ScenarioInputs - Adjust_2505.xlsx
% Fallback source:     ExcelFiles/Vietnam_EnergyExpert_ScenarioInputs.xlsx
% Clean input source:  ExcelFiles/Input/ExpertClean/<scenario>.csv
% Target: ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx
%
% For each expert scenario, TWO model sheets are written:
%   <name>          full scenario (EE + BESS integration gain)
%   <name>_NoBESS   counterfactual without BESS (exo_PVEff and BESS GA zeroed)
%
% The difference between the pair isolates the role of BESS systems.
%
% Variables written per sheet:
%   exo_AI_4_1_2   industrial EE productivity  (log(1/(1-saving_pct/100)))
%   exo_AI_5_1_2   commercial EE productivity
%   exo_GA_4_1     industrial K_A  (EE investment cost, accumulated stock)
%   exo_GA_5_1     commercial K_A  (EE investment cost, accumulated stock)
%   exo_PV_1       household RTS investment K_A  (zeroed in NoBESS)
%   exo_GA_3_1     renewables K_A  (grid BESS investment costs accumulated; zeroed in NoBESS)
%   exo_PVEff_1    PV integration-gain shock    (zeroed in NoBESS)
%   exo_lAddEE_4_1 EE-mode switch (1 = additive to exo_EE)
%   exo_lAddEE_5_1 EE-mode switch
%   exo_CapTrade_1 cap-and-trade active flag (1=on, 0=off)
%
% Design assumption (sector RTS):
%   Industry_EE_Saving_pct and Services_EE_Saving_pct are treated as
%   ALL-IN targets that already embed the energy-saving effect of sector-
%   level rooftop solar (RTS) alongside other EE measures.  Consequently
%   RTS_Industry_Investment_USDm and RTS_Services_Investment_USDm are NOT
%   added to exo_AI to avoid double-counting.  They are included in the
%   exo_GA accumulation only as an investment-cost add-on when the expert
%   explicitly provides non-NaN values; currently all three expert sheets
%   leave these columns blank (NaN -> treated as zero), so exo_GA_4_1 and
%   exo_GA_5_1 are driven solely by EE investment costs.
%
% BESS isolation:
%   exo_PVEff_r(t) = log(1 + PV_Integration_Gain_pct(t)/100)
%     captures how BESS makes additional PV output usable (Q_PV = phiPV*K_PV*exp(exo_PVEff))
%   exo_GA_3_1(t)  = baseline + K_A^BESS(t) accumulated from BESS_Annual_Investment_USDbn
%     captures the full BESS expenditure via the adaptation-capital stock channel

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

% -----------------------------------------------------------------------
% Configuration
% -----------------------------------------------------------------------
expertWorkbookPreferred = fullfile(repoRoot, 'ExcelFiles', 'PDP8', ...
    'Vietnam_EnergyExpert_ScenarioInputs - Adjust_2505.xlsx');
expertWorkbookFallback = fullfile(repoRoot, 'ExcelFiles', 'Vietnam_EnergyExpert_ScenarioInputs.xlsx');

if isfile(expertWorkbookPreferred)
    expertWorkbook = expertWorkbookPreferred;
else
    expertWorkbook = expertWorkbookFallback;
end
baselineWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelBaseline5Sectorsand1Regions.xlsx');
scenarioWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions.xlsx');
cleanInputDir = fullfile(repoRoot, 'ExcelFiles', 'Input', 'ExpertClean');
useCleanInputFiles = true;
autoPrepareCleanInputs = true;

if autoPrepareCleanInputs
    run(fullfile(repoRoot, 'scripts', 'maintenance', 'prepare_expert_inputs_for_sheet_creation.m'));
end

baseYear      = 2025;
gdpBaseMioUSD = 430000;   % Vietnam 2025 GDP (USD million)
deltaKA       = 0.10;     % K_A depreciation rate (10%/yr)
lAddEEValue   = 1;        % 1 = EE additive to baseline exo_EE trend
capTradeValue = 1;        % exo_CapTrade_1: 1 = cap-and-trade active

% Renewables subsector index (for BESS K_A cost channel).
subsecRenew = 3;

% Expert sheet -> model sheet base name (NoBESS variant appended automatically).
scenarios = {
    'EE_PDP8_reference',  'EE_PDP8'
    'Directive10_RTS_EE', 'EE_Directive10'
    'PDP8_PV_EV_BESS',    'EE_PDP8_PV_BESS'
};

% -----------------------------------------------------------------------
% Validate
% -----------------------------------------------------------------------
assert(isfile(expertWorkbook),   'Expert workbook not found:\n  %s', expertWorkbook);
assert(isfile(baselineWorkbook), 'Baseline workbook not found:\n  %s', baselineWorkbook);
assert(isfile(scenarioWorkbook), 'Scenario workbook not found:\n  %s', scenarioWorkbook);

fprintf('Expert source workbook: %s\n', expertWorkbook);
if useCleanInputFiles
    fprintf('Expert clean input dir: %s\n', cleanInputDir);
end
fprintf('IO: expert inputs -> %s -> %s\n', 'create_ee_scenarios_from_expert_inputs', scenarioWorkbook);

% -----------------------------------------------------------------------
% Load baseline paths
% -----------------------------------------------------------------------
baseHeaders = readcell(baselineWorkbook, 'Sheet', 'Baseline', 'Range', '1:1');
baseData    = readmatrix(baselineWorkbook, 'Sheet', 'Baseline');

yearColIdx = find_col(baseHeaders, 'Year');
if isempty(yearColIdx)
    timeColIdx = find_col(baseHeaders, 'Time');
    if isempty(timeColIdx)
        error('create_ee_scenarios_from_expert_inputs:MissingYearColumn', ...
            'Baseline sheet has no "Year" or "Time" column in:\n  %s', baselineWorkbook);
    end
    periods = baseData(:, timeColIdx);
    periods = periods(isfinite(periods));
    yearsBaseline = periods + baseYear - 1;
else
    yearsBaseline = baseData(:, yearColIdx);
    yearsBaseline = yearsBaseline(isfinite(yearsBaseline));
end
nYears = numel(yearsBaseline);

ai4Base    = read_col(baseData, baseHeaders, 'exo_AI_4_1_2',  nYears);
ai5Base    = read_col(baseData, baseHeaders, 'exo_AI_5_1_2',  nYears);
ga4Base    = read_col(baseData, baseHeaders, 'exo_GA_4_1',    nYears);
ga5Base    = read_col(baseData, baseHeaders, 'exo_GA_5_1',    nYears);
gaRenBase  = read_col(baseData, baseHeaders, ...
    sprintf('exo_GA_%d_1', subsecRenew), nYears);
pvEffBase  = read_col(baseData, baseHeaders, 'exo_PVEff_1',   nYears);
pvBase     = read_col(baseData, baseHeaders, 'exo_PV_1',      nYears);

fprintf('Baseline loaded: %d years (%d–%d).\n', nYears, yearsBaseline(1), yearsBaseline(end));

% -----------------------------------------------------------------------
% Process each scenario
% -----------------------------------------------------------------------
for iScen = 1:size(scenarios, 1)
    expertSheet = scenarios{iScen, 1};
    targetBase  = scenarios{iScen, 2};

    fprintf('\n--- %s -> "%s" / "%s_NoBESS" ---\n', expertSheet, targetBase, targetBase);

    [okInputs, inputData, inputSourceTag] = load_expert_scenario_inputs( ...
        expertWorkbook, expertSheet, cleanInputDir, useCleanInputFiles);
    if ~okInputs
        warning('create_ee_scenarios_from_expert_inputs:NoUsableInput', ...
            'Skipping "%s"; no usable expert inputs found.', expertSheet);
        continue
    end

    yearsExpert = inputData.years;
    savInd = inputData.savInd;
    savCom = inputData.savCom;
    invInd = inputData.invInd;
    invCom = inputData.invCom;
    bessGain = inputData.bessGain;
    bessInvBn = inputData.bessInvBn;
    rtsIndInv = inputData.rtsIndInv;
    rtsComInv = inputData.rtsComInv;
    rtsHHInv = inputData.rtsHHInv;
    bessInvMio = bessInvBn * 1000;         % convert bn → million for consistency

    fprintf('  Input source: %s\n', inputSourceTag);

    % Align to baseline years ------------------------------------------
    [~, iB, iE] = intersect(yearsBaseline, yearsExpert);
    if isempty(iB)
        warning('create_ee_scenarios_from_expert_inputs:NoOverlap', ...
            'No year overlap for "%s". Skipping.', expertSheet);
        continue
    end

    % --- Build EE paths -----------------------------------------------
    ai4 = ai4Base;  ai5 = ai5Base;

    phi4 = min(savInd(iE) / 100, 0.9999);
    phi5 = min(savCom(iE) / 100, 0.9999);
    dAI4 = log(1 ./ (1 - phi4));
    dAI5 = log(1 ./ (1 - phi5));

    ai4(iB) = ai4Base(iB) + dAI4(:);
    ai5(iB) = ai5Base(iB) + dAI5(:);

    % Extrapolate at terminal rate beyond last expert year.
    if iB(end) < nYears
        r4 = dAI4(end) / max(iB(end), 1);
        r5 = dAI5(end) / max(iB(end), 1);
        for tt = (iB(end)+1):nYears
            ai4(tt) = ai4Base(tt) + dAI4(end) + r4 * (tt - iB(end));
            ai5(tt) = ai5Base(tt) + dAI5(end) + r5 * (tt - iB(end));
        end
    end

    % EE + RTS K_A stocks (industry + commercial)
    [ga4, ga5] = accumulate_ka(ga4Base, ga5Base, invInd + rtsIndInv, invCom + rtsComInv, ...
        iB, iE, nYears, gdpBaseMioUSD, deltaKA);

    % --- Build BESS paths ---------------------------------------------
    % Effectiveness: exo_PVEff_r = log(1 + gain_pct/100)
    dPVEff = zeros(nYears, 1);
    dPVEff(iB) = log(1 + bessGain(iE) / 100);
    % Extrapolate at terminal rate.
    if iB(end) < nYears
        rPV = dPVEff(iB(end)) / max(iB(end), 1);
        for tt = (iB(end)+1):nYears
            dPVEff(tt) = dPVEff(iB(end)) + rPV * (tt - iB(end));
        end
    end
    pvEff = pvEffBase + dPVEff;

    % Cost: BESS investment -> accumulated K_A stock (exo_GA_3_1).
    kaRen = 0;
    kaRenPath = zeros(nYears, 1);
    for tt = 1:nYears
        if ismember(tt, iB)
            iePos = iE(iB == tt);
            if ~isempty(iePos)
                kaRen = (1 - deltaKA) * kaRen + bessInvMio(iePos) / gdpBaseMioUSD;
            end
        else
            kaRen = (1 - deltaKA) * kaRen;
        end
        kaRenPath(tt) = kaRen;
    end
    gaRen = gaRenBase + kaRenPath;

    % Household RTS -> accumulated K_A stock (exo_PV_1).
    kaPV = 0;
    pvPath = zeros(nYears, 1);
    for tt = 1:nYears
        if ismember(tt, iB)
            iePos = iE(iB == tt);
            if ~isempty(iePos)
                kaPV = (1 - deltaKA) * kaPV + rtsHHInv(iePos) / gdpBaseMioUSD;
            end
        else
            kaPV = (1 - deltaKA) * kaPV;
        end
        pvPath(tt) = kaPV;
    end
    pvSec = pvBase + pvPath;

    % --- Write full scenario (EE + BESS + RTS) ------------------------
    write_scenario_sheet(scenarioWorkbook, targetBase, yearsBaseline, ...
        ai4, ai5, ga4, ga5, gaRen, pvEff, pvSec, lAddEEValue, capTradeValue, subsecRenew);
    log_scenario(targetBase, yearsBaseline, ai4, ai5, pvEff, dPVEff);

    % --- Write NoBESS counterfactual (EE only, BESS/RTS zeroed) -------
    % exo_PVEff, exo_GA_3_1, and exo_PV_1 revert to baseline.
    noBESSSheet = [targetBase '_NoBESS'];
    write_scenario_sheet(scenarioWorkbook, noBESSSheet, yearsBaseline, ...
        ai4, ai5, ga4, ga5, gaRenBase, pvEffBase, pvBase, lAddEEValue, capTradeValue, subsecRenew);
    fprintf('  NoBESS: exo_PVEff / exo_GA_3_1 / exo_PV_1 = baseline\n');
    fprintf('  -> BESS isolation = difference between "%s" and "%s"\n', ...
        targetBase, noBESSSheet);
end

fprintf('\nCreateEEScenariosFromExpertInputs complete.\n');

% =======================================================================
% Functions
% =======================================================================

function write_scenario_sheet(workbook, sheetName, years, ...
        ai4, ai5, ga4, ga5, gaRen, pvEff, pvSec, lAddEE, capTrade, subsecRenew)
nY = numel(years);
periods = (1:nY)' + 1;

varNames = {'exo_AI_4_1_2', 'exo_AI_5_1_2', ...
    'exo_GA_4_1', 'exo_GA_5_1', sprintf('exo_GA_%d_1', subsecRenew), ...
    'exo_PVEff_1', 'exo_PV_1', 'exo_lAddEE_4_1', 'exo_lAddEE_5_1', 'exo_CapTrade_1'};
data = [ai4(:), ai5(:), ga4(:), ga5(:), gaRen(:), pvEff(:), pvSec(:), ...
    repmat(lAddEE, nY, 1), repmat(lAddEE, nY, 1), repmat(capTrade, nY, 1)];

writecell([{'Period','Year'}, varNames], workbook, 'Sheet', sheetName, 'Range', 'A1');
writematrix([[periods, years(:)], data], workbook, 'Sheet', sheetName, 'Range', 'A2');
end

function [ga4, ga5] = accumulate_ka(ga4Base, ga5Base, invInd, invCom, ...
        iB, iE, nYears, gdpBase, deltaKA)
ga4 = ga4Base;  ga5 = ga5Base;
ka4 = 0;  ka5 = 0;
for tt = 1:nYears
    if ismember(tt, iB)
        ip = iE(iB == tt);
        if ~isempty(ip)
            ka4 = (1-deltaKA)*ka4 + invInd(ip) / gdpBase;
            ka5 = (1-deltaKA)*ka5 + invCom(ip) / gdpBase;
        end
    else
        ka4 = (1-deltaKA)*ka4;
        ka5 = (1-deltaKA)*ka5;
    end
    ga4(tt) = ga4Base(tt) + ka4;
    ga5(tt) = ga5Base(tt) + ka5;
end
end

function log_scenario(name, years, ai4, ai5, pvEff, dPVEff)
[~,i30]=min(abs(years-2030)); [~,i50]=min(abs(years-2050));
fprintf('  Sheet "%s":\n', name);
fprintf('    AI industry:    %.4f (2030)  %.4f (2050)\n', ai4(i30), ai4(i50));
fprintf('    AI commercial:  %.4f (2030)  %.4f (2050)\n', ai5(i30), ai5(i50));
fprintf('    exo_PVEff:      %.4f (2030)  %.4f (2050)  [BESS gain: %.4f / %.4f]\n', ...
    pvEff(i30), pvEff(i50), dPVEff(i30), dPVEff(i50));
end

function iCol = find_col(hdrs, name)
iCol = find(cellfun(@(x) ischar(x) && strcmpi(strtrim(x), name), hdrs), 1);
end

function vals = cell2num_col(dataRows, col)
raw = dataRows(:, col);
vals = zeros(size(raw,1), 1);
for i = 1:numel(raw)
    v = raw{i};
    if isnumeric(v) && isscalar(v) && isfinite(v)
        vals(i) = v;
    end
end
end

function v = read_col(data, hdrs, name, nYears)
iC = find_col(hdrs, name);
if isempty(iC) || iC > size(data,2)
    v = zeros(nYears,1); return
end
v = data(1:nYears, iC);
v(~isfinite(v)) = 0;
v = v(:);
end

function [ok, data, sourceTag] = load_expert_scenario_inputs(expertWorkbook, expertSheet, cleanInputDir, useCleanInputs)
ok = false;
sourceTag = '';
data = struct('years', [], 'savInd', [], 'savCom', [], 'invInd', [], 'invCom', [], ...
    'bessGain', [], 'bessInvBn', [], 'rtsIndInv', [], 'rtsComInv', [], 'rtsHHInv', []);

if useCleanInputs
    csvPath = fullfile(cleanInputDir, char(string(expertSheet) + ".csv"));
    if isfile(csvPath)
        try
            t = readtable(csvPath, 'VariableNamingRule', 'preserve');
            if ~ismember('Year', t.Properties.VariableNames)
                error('Missing Year column in clean input.');
            end

            years = as_numeric_col(t.Year);
            isData = isfinite(years);
            years = years(isData);
            if ~isempty(years)
                data.years = years;
                data.savInd = read_optional_col(t, 'Industry_EE_Saving_pct', isData);
                data.savCom = read_optional_col(t, 'Services_EE_Saving_pct', isData);
                data.invInd = read_optional_col(t, 'Industry_EE_Investment_USDm', isData);
                data.invCom = read_optional_col(t, 'Services_EE_Investment_USDm', isData);
                data.bessGain = read_optional_col(t, 'PV_Integration_Gain_pct', isData);
                data.bessInvBn = read_optional_col(t, 'BESS_Annual_Investment_USDbn', isData);
                data.rtsIndInv = read_optional_col(t, 'RTS_Industry_Investment_USDm', isData);
                data.rtsComInv = read_optional_col(t, 'RTS_Services_Investment_USDm', isData);
                data.rtsHHInv = read_optional_col(t, 'RTS_Household_Investment_USDm', isData);

                ok = true;
                sourceTag = char(string('clean CSV ') + csvPath);
                return
            end
        catch ME
            warning('create_ee_scenarios_from_expert_inputs:CleanInputReadFailed', ...
                'Failed reading clean CSV for %s: %s', expertSheet, ME.message);
        end
    end
end

% Fallback: read directly from workbook sheet.
try
    raw = readcell(expertWorkbook, 'Sheet', expertSheet);
catch ME
    warning('create_ee_scenarios_from_expert_inputs:SheetMissing', ...
        'Cannot read sheet "%s": %s.', expertSheet, ME.message);
    return
end

hdrRow = find(cellfun(@(x) ischar(x) && strcmpi(x,'Year'), raw(:,1)), 1);
if isempty(hdrRow)
    warning('create_ee_scenarios_from_expert_inputs:NoHeader', ...
        'No "Year" header in sheet "%s".', expertSheet);
    return
end
hdrs     = raw(hdrRow, :);
dataRows = raw((hdrRow+1):end, :);

colYear    = find_col(hdrs, 'Year');
colIndSave = find_col(hdrs, 'Industry_EE_Saving_pct');
colComSave = find_col(hdrs, 'Services_EE_Saving_pct');
colIndInv  = find_col(hdrs, 'Industry_EE_Investment_USDm');
colComInv  = find_col(hdrs, 'Services_EE_Investment_USDm');
colBESSgain = find_col(hdrs, 'PV_Integration_Gain_pct');
colBESSinv  = find_col(hdrs, 'BESS_Annual_Investment_USDbn');
colRTSInd   = find_col(hdrs, 'RTS_Industry_Investment_USDm');
colRTSCom   = find_col(hdrs, 'RTS_Services_Investment_USDm');
colRTSHH    = find_col(hdrs, 'RTS_Household_Investment_USDm');

if isempty(colYear)
    warning('create_ee_scenarios_from_expert_inputs:MissingYear', ...
        'No Year column in "%s".', expertSheet);
    return
end

years = cell2num_col(dataRows, colYear);
if isempty(years)
    return
end

data.years = years;
data.savInd = zeros(size(years));
data.savCom = zeros(size(years));
data.invInd = zeros(size(years));
data.invCom = zeros(size(years));
data.bessGain = zeros(size(years));
data.bessInvBn = zeros(size(years));
data.rtsIndInv = zeros(size(years));
data.rtsComInv = zeros(size(years));
data.rtsHHInv = zeros(size(years));

if ~isempty(colIndSave), data.savInd = cell2num_col(dataRows, colIndSave); end
if ~isempty(colComSave), data.savCom = cell2num_col(dataRows, colComSave); end
if ~isempty(colIndInv),  data.invInd = cell2num_col(dataRows, colIndInv);  end
if ~isempty(colComInv),  data.invCom = cell2num_col(dataRows, colComInv);  end
if ~isempty(colBESSgain), data.bessGain = cell2num_col(dataRows, colBESSgain); end
if ~isempty(colBESSinv),  data.bessInvBn = cell2num_col(dataRows, colBESSinv);  end
if ~isempty(colRTSInd), data.rtsIndInv = cell2num_col(dataRows, colRTSInd); end
if ~isempty(colRTSCom), data.rtsComInv = cell2num_col(dataRows, colRTSCom); end
if ~isempty(colRTSHH),  data.rtsHHInv = cell2num_col(dataRows, colRTSHH);  end

ok = true;
sourceTag = char(string('workbook sheet ') + expertSheet);
end

function vals = read_optional_col(t, colName, isData)
if ~ismember(colName, t.Properties.VariableNames)
    vals = zeros(sum(isData), 1);
    return
end
vals = as_numeric_col(t.(colName));
vals = vals(isData);
vals(~isfinite(vals)) = 0;
end

function vals = as_numeric_col(v)
if isnumeric(v)
    vals = double(v);
    return
end
vals = nan(size(v));
for i = 1:numel(v)
    vv = v(i);
    if iscell(v)
        vv = v{i};
    end
    if isnumeric(vv) && isscalar(vv) && isfinite(vv)
        vals(i) = double(vv);
    elseif isstring(vv) || ischar(vv)
        numVal = str2double(strtrim(string(vv)));
        if isfinite(numVal)
            vals(i) = numVal;
        end
    end
end
end
