% create_ee_scenarios_transparent_rts  Build EE scenarios with transparent RTS deployment.
%
% Run from the repository root:
%   run('scripts/maintenance/create_ee_scenarios_transparent_rts.m')
%
% This script creates EE scenarios where energy efficiency and RTS deployment
% are specified as INDEPENDENT, TRANSPARENT, and VERIFIABLE assumptions.
%
% Source (expert input): ExcelFiles/Input/ExpertClean/Transparent_EE_<scenario>.csv
%   Columns: Year, EE_Intensity_Improvement_*_pct, EE_Investment_Cost_*_USDm_yr,
%            RTS_Capacity_Addition_*_MW_yr, RTS_Investment_Cost_*_USDm_yr,
%            RTS_Grid_Integration_Gain_pct, RTS_Grid_Integration_Investment_USDbn_yr,
%            EE_Source_*, RTS_Capacity_Source, RTS_Cost_Basis
%
% Target: ExcelFiles/ModelScenarios_TransparentEE_5Sectorsand1Regions.xlsx (NEW)
%         (Original ModelScenarios5Sectorsand1Regions.xlsx is left UNTOUCHED)
%
% For each expert scenario, ONE model sheet is written:
%   <name>   full scenario (EE + RTS + BESS integration)
%
% Variables written per sheet:
%   exo_AI_4_1_2   industrial EE productivity shock (log(1/(1-saving_pct/100)))
%   exo_AI_5_1_2   commercial EE productivity shock
%   exo_GA_4_1     industrial EE capital accumulation (USD bn stock / GDP base)
%   exo_GA_5_1     commercial EE capital accumulation
%   exo_GA_3_1     renewable-sector BESS + grid integration capital accumulation
%   exo_PVEff_1    PV integration-gain shock (log(1 + BESS_gain_pct/100))
%   exo_CapTrade_1 cap-and-trade active flag (1=on, 0=off)
%   exo_lAddEE_4_1 EE-mode switch (1 = additive to exo_EE, 0 = replace)
%   exo_lAddEE_5_1 EE-mode switch (commercial)
%
% Key Design Principles:
%   1. EE intensity improvements are INDEPENDENT of RTS deployment.
%   2. RTS investment costs are accumulated into renewable-sector capital (exo_GA_3_1).
%   3. RTS energy displacement is NOT double-counted via AI; it is implicit in final demand.
%   4. BESS/grid integration is explicit in exo_PVEff and exo_GA_3_1.
%   5. All assumptions are sourced and verified in audit CSV output.
%
% Output Artifacts:
%   - ExcelFiles/ModelScenarios_TransparentEE_5Sectorsand1Regions.xlsx: main result.
%   - ExcelFiles/Output/TransparentEE/EE_Scenario_Audit_<name>.csv: input + verification.
%   - ExcelFiles/Output/TransparentEE/EE_Scenarios_Summary.csv: comparison across scenarios.

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

% -----------------------------------------------------------------------
% Configuration
% -----------------------------------------------------------------------
baselineWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelBaseline5Sectorsand1Regions.xlsx');
transparentScenarioWorkbook = fullfile(repoRoot, 'ExcelFiles', ...
    'ModelScenarios_TransparentEE_5Sectorsand1Regions.xlsx');
expertInputDir = fullfile(repoRoot, 'ExcelFiles', 'Input', 'ExpertClean');
auditOutputDir = fullfile(repoRoot, 'ExcelFiles', 'Output', 'TransparentEE');

if ~isfolder(auditOutputDir)
    mkdir(auditOutputDir);
end

% Model constants
baseYear       = 2025;
gdpBaseMioUSD  = 430000;   % Vietnam 2025 GDP (USD million)
deltaKA        = 0.10;     % K_A depreciation rate (10%/yr)
lAddEEValue    = 1;        % 1 = EE additive to baseline exo_EE trend
capTradeValue  = 1;        % exo_CapTrade_1: 1 = cap-and-trade active
subsecRenew    = 3;        % Renewables subsector index (for BESS K_A)

% Sector mapping: subsectors 1..5 = Primary, Fossil, Renewables, Industry, Commercial
%   Aggregate: 1=Primary, 2=Energy (Fossil+Renewables), 3=Secondary, 4=Tertiary
subsecIndustry = 4;
subsecCommercial = 5;

% Scenarios: (expert_csv_name, target_sheet_name)
% Update this list when adding new transparent EE scenarios.
% Note: Sheet names must be <= 31 characters (Excel limit)
scenarios = {
    'Transparent_EE_Baseline_RTS_Conservative',    'EE_Baseline_Conservative'
    'Transparent_EE_Enhanced_RTS_Ambitious',       'EE_Enhanced_Ambitious'
    'Transparent_EE_Only',                         'EE_EEOnly'
    'Transparent_RTS_Only',                        'EE_RTSOnly'
};

% -----------------------------------------------------------------------
% Initialization & Checks
% -----------------------------------------------------------------------
fprintf('%s\n', repmat('=', 1, 70));
fprintf('Create EE Scenarios with Transparent RTS Deployment\n');
fprintf('%s\n', repmat('=', 1, 70));
fprintf('Baseline workbook: %s\n', baselineWorkbook);
fprintf('Target workbook (NEW): %s\n', transparentScenarioWorkbook);
fprintf('Expert input dir: %s\n', expertInputDir);
fprintf('Audit output dir: %s\n\n', auditOutputDir);

assert(isfile(baselineWorkbook), 'Baseline workbook not found:\n  %s', baselineWorkbook);
assert(isfolder(expertInputDir), 'Expert input directory not found:\n  %s', expertInputDir);

% Load baseline paths
baseHeaders = readcell(baselineWorkbook, 'Sheet', 'Baseline', 'Range', '1:1');
baseData = readmatrix(baselineWorkbook, 'Sheet', 'Baseline');

yearColIdx = find_col(baseHeaders, 'Year');
if isempty(yearColIdx)
    error('create_ee_scenarios_transparent_rts:MissingYearColumn', ...
        'Baseline sheet has no "Year" column in:\n  %s', baselineWorkbook);
end
yearsBaseline = baseData(:, yearColIdx);
yearsBaseline = yearsBaseline(isfinite(yearsBaseline));
nYears = numel(yearsBaseline);

% Read baseline paths for all relevant variables
ai4Base    = read_col(baseData, baseHeaders, 'exo_AI_4_1_2',  nYears);
ai5Base    = read_col(baseData, baseHeaders, 'exo_AI_5_1_2',  nYears);
ga4Base    = read_col(baseData, baseHeaders, 'exo_GA_4_1',    nYears);
ga5Base    = read_col(baseData, baseHeaders, 'exo_GA_5_1',    nYears);
gaRenBase  = read_col(baseData, baseHeaders, ...
    sprintf('exo_GA_%d_1', subsecRenew), nYears);
pvEffBase  = read_col(baseData, baseHeaders, 'exo_PVEff_1',   nYears);

fprintf('Baseline loaded: %d years (%d–%d).\n', nYears, yearsBaseline(1), yearsBaseline(end));
fprintf('\nProcessing scenarios...\n');

% Track summary statistics across scenarios
scenarioSummary = {};
summaryRowCount = 1;

% -----------------------------------------------------------------------
% Process each scenario
% -----------------------------------------------------------------------
for iScen = 1:size(scenarios, 1)
    expertCsvName = scenarios{iScen, 1};
    targetSheet   = scenarios{iScen, 2};
    expertCsvPath = fullfile(expertInputDir, [expertCsvName '.csv']);

    fprintf('\n--- Scenario %d: %s ---\n', iScen, expertCsvName);

    % Load expert inputs
    if ~isfile(expertCsvPath)
        warning('create_ee_scenarios_transparent_rts:MissingInput', ...
            'Expert CSV not found; skipping:\n  %s', expertCsvPath);
        continue
    end

    [expertData, expertHeaders] = read_expert_transparent_inputs(expertCsvPath);
    yearsExpert = expertData.years;
    fprintf('  Expert input: %s\n', expertCsvPath);
    fprintf('  Years: %d–%d (%d data points)\n', yearsExpert(1), yearsExpert(end), numel(yearsExpert));

    % Align to baseline years
    [~, iB, iE] = intersect(yearsBaseline, yearsExpert, 'stable');
    if isempty(iB)
        warning('create_ee_scenarios_transparent_rts:NoOverlap', ...
            'No year overlap for "%s". Skipping.', expertCsvName);
        continue
    end

    % Extract expert assumptions by sector
    eeIntInd = expertData.eeIntensityInd;      % Industry EE intensity improvement, %
    eeIntCom = expertData.eeIntensityComm;     % Commercial EE intensity improvement, %
    eeInvInd = expertData.eeInvestmentInd;     % Industry EE investment, USD m/yr
    eeInvCom = expertData.eeInvestmentComm;    % Commercial EE investment, USD m/yr
    rtsCapInd = expertData.rtsCapacityInd;     % Industry RTS capacity addition, MW/yr
    rtsCapCom = expertData.rtsCapacityComm;    % Commercial RTS capacity addition, MW/yr
    rtsInvInd = expertData.rtsInvestmentInd;   % Industry RTS investment, USD m/yr
    rtsInvCom = expertData.rtsInvestmentComm;  % Commercial RTS investment, USD m/yr
    bessGain = expertData.bessGain;            % BESS/grid integration gain, %
    bessInvBn = expertData.bessInvBn;          % BESS investment, USD bn/yr
    eeSrcInd = expertData.eeSourceInd;         % Industry EE source (text)
    eeSrcCom = expertData.eeSourceComm;        % Commercial EE source (text)
    rtsSrc = expertData.rtsSource;             % RTS capacity source (text)
    rtsCostSrc = expertData.rtsCostSource;     % RTS cost source (text)

    % ---------------------------------------------------------------
    % Build EE paths (AI shocks for energy productivity)
    % ---------------------------------------------------------------
    ai4 = ai4Base;
    ai5 = ai5Base;

    % Industry: log(1 / (1 - saving_pct/100))
    phi4 = min(eeIntInd(iE) / 100, 0.9999);
    dAI4 = log(1 ./ (1 - phi4));
    ai4(iB) = ai4Base(iB) + dAI4(:);

    % Commercial
    phi5 = min(eeIntCom(iE) / 100, 0.9999);
    dAI5 = log(1 ./ (1 - phi5));
    ai5(iB) = ai5Base(iB) + dAI5(:);

    % Extrapolate beyond expert years at terminal rate
    if iB(end) < nYears
        r4 = dAI4(end) / max(iB(end), 1);
        r5 = dAI5(end) / max(iB(end), 1);
        for tt = (iB(end)+1):nYears
            ai4(tt) = ai4Base(tt) + dAI4(end) + r4 * (tt - iB(end));
            ai5(tt) = ai5Base(tt) + dAI5(end) + r5 * (tt - iB(end));
        end
    end

    % ---------------------------------------------------------------
    % Build EE capital accumulation (GA shocks)
    % ---------------------------------------------------------------
    [ga4, ga5] = accumulate_ka(ga4Base, ga5Base, eeInvInd, eeInvCom, ...
        iB, iE, nYears, gdpBaseMioUSD, deltaKA);

    % ---------------------------------------------------------------
    % Build RTS capital accumulation (into renewable-sector GA)
    % ---------------------------------------------------------------
    [gaRen, rtsAccumBySector] = accumulate_rts_ka(gaRenBase, rtsInvInd, rtsInvCom, ...
        iB, iE, nYears, gdpBaseMioUSD, deltaKA);

    % ---------------------------------------------------------------
    % Build BESS/grid integration paths
    % ---------------------------------------------------------------
    % BESS effectiveness: exo_PVEff = log(1 + gain_pct/100)
    pvEff = pvEffBase;
    dPVEff = zeros(nYears, 1);
    dPVEff(iB) = log(1 + bessGain(iE) / 100);

    % Extrapolate BESS gain beyond expert years
    if iB(end) < nYears
        rPV = dPVEff(iB(end)) / max(iB(end), 1);
        for tt = (iB(end)+1):nYears
            dPVEff(tt) = dPVEff(iB(end)) + rPV * (tt - iB(end));
        end
    end
    pvEff = pvEffBase + dPVEff;

    % BESS investment cost accumulation
    bessInvMio = bessInvBn * 1000;  % convert bn → million
    kaRen = 0;
    kaRenPath = zeros(nYears, 1);
    for tt = 1:nYears
        if ismember(tt, iB)
            iePos = iE(iB == tt);
            if ~isempty(iePos)
                kaRen = (1-deltaKA)*kaRen + bessInvMio(iePos) / gdpBaseMioUSD;
            end
        else
            kaRen = (1-deltaKA)*kaRen;
        end
        kaRenPath(tt) = kaRen;
    end
    % Add RTS investment costs to renewables capital
    gaRen = gaRen + kaRenPath;

    % ---------------------------------------------------------------
    % Write scenario sheet to NEW workbook
    % ---------------------------------------------------------------
    write_scenario_sheet_transparent(transparentScenarioWorkbook, targetSheet, ...
        yearsBaseline, ai4, ai5, ga4, ga5, gaRen, pvEff, ...
        lAddEEValue, capTradeValue, subsecRenew);
    fprintf('  -> Wrote sheet: "%s"\n', targetSheet);

    % ---------------------------------------------------------------
    % Write audit CSV
    % ---------------------------------------------------------------
    auditCsvPath = fullfile(auditOutputDir, ['EE_Scenario_Audit_' expertCsvName '.csv']);
    write_audit_csv(auditCsvPath, yearsBaseline, yearsExpert, iB, iE, ...
        eeIntInd, eeIntCom, eeInvInd, eeInvCom, ...
        rtsCapInd, rtsCapCom, rtsInvInd, rtsInvCom, bessGain, bessInvBn, ...
        dAI4, dAI5, ai4, ai5, ga4, ga5, gaRen, pvEff, ...
        eeSrcInd, eeSrcCom, rtsSrc, rtsCostSrc);
    fprintf('  -> Wrote audit: %s\n', auditCsvPath);

    % ---------------------------------------------------------------
    % Accumulate summary statistics
    % ---------------------------------------------------------------
    peakEE = max(max(eeIntInd(iE)), max(eeIntCom(iE)));
    totalEEInv = sum(eeInvInd(iE)) + sum(eeInvCom(iE));
    totalRTSInv = sum(rtsInvInd(iE)) + sum(rtsInvCom(iE));
    totalRTSCap = sum(rtsCapInd(iE)) + sum(rtsCapCom(iE));
    totalBESSInv = sum(bessInvBn(iE));

    scenarioSummary(summaryRowCount, :) = {
        expertCsvName, ...
        peakEE, ...
        totalEEInv, ...
        totalRTSInv, ...
        totalRTSCap, ...
        totalBESSInv
    };
    summaryRowCount = summaryRowCount + 1;
end

% -----------------------------------------------------------------------
% Write summary statistics
% -----------------------------------------------------------------------
if summaryRowCount > 1
    summaryPath = fullfile(auditOutputDir, 'EE_Scenarios_Summary.csv');
    writetable(table( ...
        scenarioSummary(:, 1), ...
        cell2mat(scenarioSummary(:, 2)), ...
        cell2mat(scenarioSummary(:, 3)), ...
        cell2mat(scenarioSummary(:, 4)), ...
        cell2mat(scenarioSummary(:, 5)), ...
        cell2mat(scenarioSummary(:, 6)), ...
        'VariableNames', { ...
            'Scenario', ...
            'Peak_EE_Intensity_Improvement_pct', ...
            'Total_EE_Investment_USDm', ...
            'Total_RTS_Investment_USDm', ...
            'Total_RTS_Capacity_Added_MW', ...
            'Total_BESS_Investment_USDbn' ...
        }), ...
        summaryPath);
    fprintf('\n-> Wrote summary: %s\n', summaryPath);
end

fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('CreateEEscenariosTransparentRTS complete.\n');
fprintf('All artifacts written to:\n');
fprintf('  Main workbook: %s\n', transparentScenarioWorkbook);
fprintf('  Audit CSVs: %s\n', auditOutputDir);
fprintf('%s\n', repmat('=', 1, 70));

% =======================================================================
% Helper Functions
% =======================================================================

function [expertData, headers] = read_expert_transparent_inputs(csvPath)
% Parse transparent EE expert input CSV.
% Returns a struct with aligned arrays and metadata.

opts = detectImportOptions(csvPath);
T = readtable(csvPath, opts);
headers = T.Properties.VariableNames;

expertData.years = T.Year;

% EE intensity improvements (%)
expertData.eeIntensityInd = T.EE_Intensity_Improvement_Industry_pct;
expertData.eeIntensityComm = T.EE_Intensity_Improvement_Commercial_pct;

% EE investment costs (USD m/yr)
expertData.eeInvestmentInd = T.EE_Investment_Cost_Industry_USDm_yr;
expertData.eeInvestmentComm = T.EE_Investment_Cost_Commercial_USDm_yr;

% RTS capacity additions (MW/yr)
expertData.rtsCapacityInd = T.RTS_Capacity_Addition_Industry_MW_yr;
expertData.rtsCapacityComm = T.RTS_Capacity_Addition_Commercial_MW_yr;

% RTS investment costs (USD m/yr)
expertData.rtsInvestmentInd = T.RTS_Investment_Cost_Industry_USDm_yr;
expertData.rtsInvestmentComm = T.RTS_Investment_Cost_Commercial_USDm_yr;

% BESS/grid integration
expertData.bessGain = T.RTS_Grid_Integration_Gain_pct;
expertData.bessInvBn = T.RTS_Grid_Integration_Investment_USDbn_yr;

% Source metadata
expertData.eeSourceInd = T.EE_Source_Industry;
expertData.eeSourceComm = T.EE_Source_Commercial;
expertData.rtsSource = T.RTS_Capacity_Source;
expertData.rtsCostSource = T.RTS_Cost_Basis;

end

function [ga4, ga5] = accumulate_ka(ga4Base, ga5Base, invInd, invCom, ...
        iB, iE, nYears, gdpBase, deltaKA)
% Accumulate EE investment costs into capital stocks.

ga4 = ga4Base;
ga5 = ga5Base;
ka4 = 0;
ka5 = 0;

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

function [gaRen, rtsAccumBySector] = accumulate_rts_ka(gaRenBase, rtsInvInd, rtsInvCom, ...
        iB, iE, nYears, gdpBase, deltaKA)
% Accumulate RTS investment costs into renewable-sector capital.

gaRen = gaRenBase;
kaRen = 0;
rtsAccumBySector.Industry = zeros(nYears, 1);
rtsAccumBySector.Commercial = zeros(nYears, 1);

for tt = 1:nYears
    if ismember(tt, iB)
        ip = iE(iB == tt);
        if ~isempty(ip)
            rtsInvThisYear = rtsInvInd(ip) + rtsInvCom(ip);
            kaRen = (1-deltaKA)*kaRen + rtsInvThisYear / gdpBase;
            rtsAccumBySector.Industry(tt) = (rtsAccumBySector.Industry(tt-1 | 1)) + rtsInvInd(ip) / gdpBase;
            rtsAccumBySector.Commercial(tt) = (rtsAccumBySector.Commercial(tt-1 | 1)) + rtsInvCom(ip) / gdpBase;
        end
    else
        kaRen = (1-deltaKA)*kaRen;
        if tt > 1
            rtsAccumBySector.Industry(tt) = rtsAccumBySector.Industry(tt-1);
            rtsAccumBySector.Commercial(tt) = rtsAccumBySector.Commercial(tt-1);
        end
    end
    gaRen(tt) = gaRenBase(tt) + kaRen;
end

end

function write_scenario_sheet_transparent(workbook, sheetName, years, ...
        ai4, ai5, ga4, ga5, gaRen, pvEff, lAddEE, capTrade, subsecRenew)
% Write a single scenario sheet to the transparent workbook.

nY = numel(years);
periods = (1:nY)' + 1;

varNames = {'exo_AI_4_1_2', 'exo_AI_5_1_2', ...
    'exo_GA_4_1', 'exo_GA_5_1', sprintf('exo_GA_%d_1', subsecRenew), ...
    'exo_PVEff_1', 'exo_lAddEE_4_1', 'exo_lAddEE_5_1', 'exo_CapTrade_1'};
data = [ai4(:), ai5(:), ga4(:), ga5(:), gaRen(:), pvEff(:), ...
    repmat(lAddEE, nY, 1), repmat(lAddEE, nY, 1), repmat(capTrade, nY, 1)];

writecell([{'Period','Year'}, varNames], workbook, 'Sheet', sheetName, 'Range', 'A1');
writematrix([[periods, years(:)], data], workbook, 'Sheet', sheetName, 'Range', 'A2');

end

function write_audit_csv(csvPath, yearsBase, yearsExpert, iB, iE, ...
        eeIntInd, eeIntCom, eeInvInd, eeInvCom, ...
        rtsCapInd, rtsCapCom, rtsInvInd, rtsInvCom, bessGain, bessInvBn, ...
        dAI4, dAI5, ai4, ai5, ga4, ga5, gaRen, pvEff, ...
        eeSrcInd, eeSrcCom, rtsSrc, rtsCostSrc)
% Write detailed audit CSV with inputs and derived variables.

nB = numel(iB);

% Pre-allocate all columns as cell arrays (mixed data types)
auditData = table( ...
    zeros(nB, 1), ...  % Year
    zeros(nB, 1), ...  % Period
    zeros(nB, 1), zeros(nB, 1), ...  % EE intensity improvements
    zeros(nB, 1), zeros(nB, 1), ...  % EE investment
    zeros(nB, 1), zeros(nB, 1), ...  % RTS capacity
    zeros(nB, 1), zeros(nB, 1), ...  % RTS investment
    zeros(nB, 1), zeros(nB, 1), ...  % BESS gain and investment
    zeros(nB, 1), zeros(nB, 1), ...  % Derived AI deltas
    zeros(nB, 1), zeros(nB, 1), ...  % Derived AI levels
    zeros(nB, 1), zeros(nB, 1), ...  % Derived GA 4,5 levels
    zeros(nB, 1), zeros(nB, 1), ...  % Derived GA renewables and PVEff
    zeros(nB, 1), zeros(nB, 1), ...  % Cumulative EE investments
    zeros(nB, 1), zeros(nB, 1), ...  % Cumulative RTS capacity
    zeros(nB, 1), zeros(nB, 1), ...  % Cumulative RTS investments
    zeros(nB, 1), ...  % Cumulative BESS investment
    repmat({''},nB,1), repmat({''},nB,1), repmat({''},nB,1), ... % String columns for sources
    'VariableNames', { ...
        'Year', 'Period', ...
        'EE_Intensity_Improvement_Industry_pct', 'EE_Intensity_Improvement_Commercial_pct', ...
        'EE_Investment_Industry_USDm_yr', 'EE_Investment_Commercial_USDm_yr', ...
        'RTS_Capacity_Industry_MW_yr', 'RTS_Capacity_Commercial_MW_yr', ...
        'RTS_Investment_Industry_USDm_yr', 'RTS_Investment_Commercial_USDm_yr', ...
        'BESS_Grid_Integration_Gain_pct', 'BESS_Investment_USDbn_yr', ...
        'Derived_AI_4_delta', 'Derived_AI_5_delta', ...
        'Derived_AI_4_level', 'Derived_AI_5_level', ...
        'Derived_GA_4_level', 'Derived_GA_5_level', ...
        'Derived_GA_Renewables_level', 'Derived_PVEff_level', ...
        'Cumulative_EE_Investment_Industry_USDm', 'Cumulative_EE_Investment_Commercial_USDm', ...
        'Cumulative_RTS_Capacity_Industry_MW', 'Cumulative_RTS_Capacity_Commercial_MW', ...
        'Cumulative_RTS_Investment_Industry_USDm', 'Cumulative_RTS_Investment_Commercial_USDm', ...
        'Cumulative_BESS_Investment_USDm', ...
        'EE_Source_Industry', 'EE_Source_Commercial', 'RTS_Capacity_Source' ...
    });

for ii = 1:nB
    idx_y = iB(ii);
    idx_e = iE(ii);
    auditData.Year(ii) = yearsExpert(idx_e);
    auditData.Period(ii) = idx_y + 1;
    auditData.EE_Intensity_Improvement_Industry_pct(ii) = eeIntInd(idx_e);
    auditData.EE_Intensity_Improvement_Commercial_pct(ii) = eeIntCom(idx_e);
    auditData.EE_Investment_Industry_USDm_yr(ii) = eeInvInd(idx_e);
    auditData.EE_Investment_Commercial_USDm_yr(ii) = eeInvCom(idx_e);
    auditData.RTS_Capacity_Industry_MW_yr(ii) = rtsCapInd(idx_e);
    auditData.RTS_Capacity_Commercial_MW_yr(ii) = rtsCapCom(idx_e);
    auditData.RTS_Investment_Industry_USDm_yr(ii) = rtsInvInd(idx_e);
    auditData.RTS_Investment_Commercial_USDm_yr(ii) = rtsInvCom(idx_e);
    auditData.BESS_Grid_Integration_Gain_pct(ii) = bessGain(idx_e);
    auditData.BESS_Investment_USDbn_yr(ii) = bessInvBn(idx_e);
    auditData.Derived_AI_4_delta(ii) = dAI4(ii);
    auditData.Derived_AI_5_delta(ii) = dAI5(ii);
    auditData.Derived_AI_4_level(ii) = ai4(idx_y);
    auditData.Derived_AI_5_level(ii) = ai5(idx_y);
    auditData.Derived_GA_4_level(ii) = ga4(idx_y);
    auditData.Derived_GA_5_level(ii) = ga5(idx_y);
    auditData.Derived_GA_Renewables_level(ii) = gaRen(idx_y);
    auditData.Derived_PVEff_level(ii) = pvEff(idx_y);
    auditData.Cumulative_EE_Investment_Industry_USDm(ii) = sum(eeInvInd(iE(1:ii)));
    auditData.Cumulative_EE_Investment_Commercial_USDm(ii) = sum(eeInvCom(iE(1:ii)));
    auditData.Cumulative_RTS_Capacity_Industry_MW(ii) = sum(rtsCapInd(iE(1:ii)));
    auditData.Cumulative_RTS_Capacity_Commercial_MW(ii) = sum(rtsCapCom(iE(1:ii)));
    auditData.Cumulative_RTS_Investment_Industry_USDm(ii) = sum(rtsInvInd(iE(1:ii)));
    auditData.Cumulative_RTS_Investment_Commercial_USDm(ii) = sum(rtsInvCom(iE(1:ii)));
    auditData.Cumulative_BESS_Investment_USDm(ii) = sum(bessInvBn(iE(1:ii))) * 1000;
    auditData.EE_Source_Industry{ii} = char(eeSrcInd(idx_e));
    auditData.EE_Source_Commercial{ii} = char(eeSrcCom(idx_e));
    auditData.RTS_Capacity_Source{ii} = char(rtsSrc(idx_e));
end

writetable(auditData, csvPath);

end

function colIdx = find_col(headers, colName)
% Find column index by name (case-insensitive).
colIdx = find(strcmpi(headers, colName), 1);
end

function colData = read_col(data, headers, colName, nRows)
% Read column from data matrix by name.
colIdx = find_col(headers, colName);
if isempty(colIdx)
    colData = zeros(nRows, 1);
else
    colData = data(1:nRows, colIdx);
end
end
