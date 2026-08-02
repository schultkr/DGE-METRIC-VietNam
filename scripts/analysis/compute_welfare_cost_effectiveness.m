% Welfare / cost-effectiveness metrics computed from ExcelFiles/Output/*.csv.
%
% Implements the three metrics recommended in
% docs/reports/TECHNICAL_REPORT_PERFECT.md section 14, item 1:
%   1. Consumption-equivalent variation (CEV), any scenario vs. Baseline.
%   2. USD-per-tonne-CO2-avoided, NZ family vs. Baseline.
%   3. GDP-pp per WACF-pp, finance-scenario pairs (PDP8_GF_*/NZ_GF_*).
%
% LIMITATIONS (read before citing any number produced here):
%   1. Utility parameters below (hHabit, gammaH, sigmaC, sigmaL, phiL, beta)
%      are hardcoded to the active calibration in ModFiles/DGE_Model_Parameters.mod
%      as of 2026-07-21 (lines 97, 115-116, 176). CSVs carry no parameter
%      metadata, so a recalibration requires updating this config block by hand.
%   2. Welfare sums are over the finite simulated horizon only -- no terminal
%      continuation value beyond the last simulated year is added.
%   3. Y_1 (ExcelFiles/README.md:227, YTarget=1 numeraire) and E_1
%      (Functions/SteadyState/setupInitialState/finalize_calibration_parameters.m:13,
%      set at runtime from the calibration workbook) are calibration-relative
%      index units, not confirmed absolute USD/MtCO2. Metric 2 therefore
%      defaults to index units; set the anchors below only once a verified
%      numeraire-to-real conversion is confirmed.
%   4. WACF percentages are external documented assumptions
%      (docs/data_sources.md:126), not read from the CSVs. The script also
%      reports a model-internal financing-cost proxy as a cross-check.

clear all

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd));
cd(repoRoot);
setup_paths();

%% Configuration

% --- Household felicity parameters (ModFiles/DGE_Model_Parameters.mod) ---
params.hHabit = 0.7;      % h_p            (line 118)
params.gammaH = 0.05;     % gamma_1_p      (line 176)
params.sigmaC = 1;        % sigmaC_p       (line 116)
params.sigmaL = 0.5;      % sigmaL_p       (line 115)
params.nSectors = 5;
params.phiL = ones(1, params.nSectors);  % phiL_<s>_1_p, all default to 1 (line 253)
pBeta = 0.95;             % beta_p         (line 97)

% --- Unit anchors for metric 2 (see LIMITATIONS item 3); default = no conversion ---
anchors.GDPAnchorUSDperUnit = 1;
anchors.EmissionsAnchorMtPerUnit = 1;

% --- Metric 1: CEV, scenario vs. Baseline ---
casScenariosCEV = {'NZ', 'NZ_constEE', 'NZ_constInt', 'NZ_constEEInt', ...
    'EE_PDP8', 'PDP8_GF_A', 'PDP8_GF_B', 'PDP8_GF_C', ...
    'NZ_GF_A', 'NZ_GF_B', 'NZ_GF_C'};
sBaselineScenario = 'Baseline';

% --- Metric 2: USD/tonne-CO2 avoided, NZ family vs. Baseline ---
casScenariosAbatement = {'NZ', 'NZ_constEE', 'NZ_constInt', 'NZ_constEEInt'};

% --- Metric 3: GDP-pp per WACF-pp, finance scenario pairs ---
% WACF source: docs/data_sources.md:126 (GF_A balanced 6.43%, GF_B market-led
% 7.37%, GF_C public-led 5.07%), applied identically under PDP8 and NZ.
casWACFTable = struct('PDP8_GF_A', 6.43, 'PDP8_GF_B', 7.37, 'PDP8_GF_C', 5.07, ...
    'NZ_GF_A', 6.43, 'NZ_GF_B', 7.37, 'NZ_GF_C', 5.07);
casPairsWACF = {{'PDP8_GF_C', 'PDP8_GF_B'}, {'PDP8_GF_A', 'PDP8_GF_B'}, ...
    {'NZ_GF_C', 'NZ_GF_B'}, {'NZ_GF_A', 'NZ_GF_B'}};

%% Load all required scenario CSVs once

casAllScenarios = unique([{sBaselineScenario}, casScenariosCEV, casScenariosAbatement, ...
    [casPairsWACF{:}]]);
dsall = struct();
for iscen = 1:length(casAllScenarios)
    sScen = char(casAllScenarios(iscen));
    dsall.(sScen) = readtable(['ExcelFiles/Output/' sScen '.csv']);
end
dsBaseline = dsall.(sBaselineScenario);

%% Metric 1: consumption-equivalent variation

fprintf('\n=== Metric 1: Consumption-equivalent variation vs. %s ===\n', sBaselineScenario);
resultsCEV = table();
for iscen = 1:length(casScenariosCEV)
    sScen = char(casScenariosCEV(iscen));
    [lambdaPct, diagOut] = compute_cev(dsall.(sScen), dsBaseline, params, pBeta);
    fprintf('%-16s CEV = %8.4f %%   (T = %d years)\n', sScen, lambdaPct, diagOut.T);
    resultsCEV = [resultsCEV; table({sScen}, lambdaPct, diagOut.T, ...
        'VariableNames', {'Scenario', 'CEV_Pct', 'HorizonYears'})]; %#ok<AGROW>
end

%% Metric 2: USD-per-tonne-CO2 avoided (index units by default)

fprintf('\n=== Metric 2: Cost per tonne CO2 avoided vs. %s ===\n', sBaselineScenario);
resultsAbatement = table();
for iscen = 1:length(casScenariosAbatement)
    sScen = char(casScenariosAbatement(iscen));
    out = compute_abatement_cost(dsall.(sScen), dsBaseline, pBeta, anchors);
    fprintf('%-16s PV GDP cost = %10.4f   CumAbated = %10.4f   Cost/tonne = %8.4f (index units)   PE avg (cross-check) = %6.4f\n', ...
        sScen, out.PVGDPCost, out.CumulativeAbatement, out.CostPerTonneIndexUnits, out.CarbonPriceAvgCrossCheck);
    resultsAbatement = [resultsAbatement; table({sScen}, out.PVGDPCost, out.CumulativeAbatement, ...
        out.CostPerTonneIndexUnits, out.CostPerTonneUSD, out.CarbonPriceAvgCrossCheck, ...
        'VariableNames', {'Scenario', 'PVGDPCost', 'CumulativeAbatement', ...
        'CostPerTonneIndexUnits', 'CostPerTonneUSD', 'CarbonPriceAvgCrossCheck'})]; %#ok<AGROW>
end

%% Metric 3: GDP-pp per WACF-pp

fprintf('\n=== Metric 3: GDP-pp per WACF-pp ===\n');
resultsWACF = table();
for ipair = 1:length(casPairsWACF)
    sA = char(casPairsWACF{ipair}{1});
    sB = char(casPairsWACF{ipair}{2});
    wacfA = casWACFTable.(sA);
    wacfB = casWACFTable.(sB);
    out = compute_gdp_per_wacf(dsall.(sA), dsall.(sB), wacfA, wacfB);
    % Sector 3 (renewables): the only sector create_green_finance_scenarios.m shocks.
    proxyA = financing_cost_proxy(dsall.(sA), 3);
    proxyB = financing_cost_proxy(dsall.(sB), 3);
    fprintf('%-16s vs %-16s  DeltaWACF = %5.2f pp   GDPpp(term) = %7.4f   Metric(term) = %7.4f   [WACF proxy: %s=%.2f%%, %s=%.2f%% vs documented %.2f%%/%.2f%%]\n', ...
        sA, sB, out.DeltaWACFpp, out.GDPppTerminal, out.MetricTerminal, ...
        sA, proxyA, sB, proxyB, wacfA, wacfB);
    resultsWACF = [resultsWACF; table({sA}, {sB}, out.DeltaWACFpp, out.GDPppTerminal, ...
        out.GDPppAverage, out.MetricTerminal, out.MetricAverage, proxyA, proxyB, ...
        'VariableNames', {'ScenarioA', 'ScenarioB', 'DeltaWACFpp', 'GDPppTerminal', ...
        'GDPppAverage', 'MetricTerminal', 'MetricAverage', 'WACFProxyA', 'WACFProxyB'})]; %#ok<AGROW>
end

%% Write combined summary

writetable(resultsCEV, 'ExcelFiles/Output/WelfareCostEffectiveness_CEV.csv');
writetable(resultsAbatement, 'ExcelFiles/Output/WelfareCostEffectiveness_CostPerTonne.csv');
writetable(resultsWACF, 'ExcelFiles/Output/WelfareCostEffectiveness_GDPperWACF.csv');

fprintf('\nWrote ExcelFiles/Output/WelfareCostEffectiveness_{CEV,CostPerTonne,GDPperWACF}.csv\n');
