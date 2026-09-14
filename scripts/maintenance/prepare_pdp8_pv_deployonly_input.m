% prepare_pdp8_pv_deployonly_input  Build EE_RTS_prerev_95GW (RTS held at the pre-revision 95 GW).
%
% Run from the repository root:
%   run('scripts/maintenance/prepare_pdp8_pv_deployonly_input.m')
%
% PDP8's rooftop-solar (RTS) target was revised UP from the original ~95 GW to
% ~135 GW ("PDP8 High"), and the model Baseline now embeds the 135 GW path in
% three channels:
%   exo_AI_4_1_2 / exo_AI_5_1_2  industry/services energy productivity (PV->EE coupling)
%   exo_GA_4_1   / exo_GA_5_1    industry/services rooftop capital
%   exo_PV_1                     household rooftop capital
%
% EE_RTS_prerev_95GW (-> ... / _NoBESS) is the counterfactual where RTS
% reaches only the original 95 GW. Each channel is rewound from the 135 GW path
% ("A", = Baseline) to the 95 GW path ("B"); the CSV carries the B - A delta,
% which create_ee_scenarios_from_expert_inputs.m adds on top of the Baseline.
%   * Pure RTS counterfactual: NO retrofit EE (Industry_/Services_EE_Investment_USDm
%     = 0, no PDP8_PV_EV_BESS saving %).
%   * Cost side scaled too (exo_GA_4_1/5_1), via negative RTS_*_Investment_USDm.
%   * No clamping: 2027-2028 the 95 GW path is slightly ABOVE the revised High
%     path, so those years come out marginally positive.
%   * No BESS: PV_Integration_Gain_pct = 0, BESS_Annual_Investment_USDbn = 0.
%
% Sources:
%   Path A (135 GW = Baseline): ExcelFiles/Output/RTS_split_assumptions_from_expert_email.csv
%     (gen_industrial_GWh, gen_household_GWh, cap_industrial_MW, cap_household_MW, cap_total_MW)
%   Path B (95 GW): ExcelFiles/Input/ExpertClean/RTS_PDP8_revised_reference.csv
%     column RTS_Capacity_GW_Base (12 -> 95); generation by same-CF scaling
%     RTS_Generation_TWh * (RTS_Capacity_GW_Base / RTS_Capacity_GW) * 1000.
%   Baseline exo_PV_1: ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx sheet Baseline.
%
% Output: ExcelFiles/Input/ExpertClean/PDP8_PV_EV_BESS.csv  (overwrites the raw
%   extract; keep this script AFTER prepare_expert_inputs_for_sheet_creation.m).

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);

% -----------------------------------------------------------------------
% Configuration
% -----------------------------------------------------------------------
rtsSplitCsv = fullfile(repoRoot, 'ExcelFiles', 'Output', ...
    'RTS_split_assumptions_from_expert_email.csv');
rtsRefCsv   = fullfile(repoRoot, 'ExcelFiles', 'Input', 'ExpertClean', ...
    'RTS_PDP8_revised_reference.csv');
baselineWb  = fullfile(repoRoot, 'ExcelFiles', 'ModelBaseline5Sectorsand1Regions.xlsx');
outCsv      = fullfile(repoRoot, 'ExcelFiles', 'Input', 'ExpertClean', 'PDP8_PV_EV_BESS.csv');

firstYear = 2026;
lastYear  = 2051;

gdpBaseMioUSD = 430000;   % matches create_ee_scenarios_from_expert_inputs.m
deltaKA  = 0.10;          % builder K_A accumulation depreciation
deltaPV  = 0.10;          % stock-index -> investment-index conversion (baseline builder)
gaLevel0 = 0.013;         % first-year GA level = phiKPV0 (calibration param); verify vs Baseline exo_GA_4_1(2026)
dIndBase2025 = 177550;    % GWh, Vietnam 2025 industrial electricity demand
dSerBase2025 = 56950;     % GWh, 2025 commercial/services demand
demandGrowth = 0.04;
commShareOfHousehold = 0.30;

% Sector-share anchors (mirror infer_rts_industrial_shares_from_email / sibling prep scripts)
sGenAnchorYears = [2030, 2050];
sGenAnchor      = [23361 / 44827, 77676 / 176936];   % 0.52114 -> 0.43900 (generation)
sCapAnchorYears = [2030, 2050];
sCapAnchor      = [18231 / 36733, 59000 / 137670];   % 0.49631 -> 0.42857 (capacity)

assert(isfile(rtsRefCsv),   'RTS reference CSV not found:\n  %s', rtsRefCsv);
assert(isfile(baselineWb),  'Baseline workbook not found:\n  %s', baselineWb);

% The split CSV is a generated Baseline-pipeline artifact (gitignored). Regenerate
% it from the RTS reference path + expert-email anchors if a Baseline build has
% not produced it this session -- same formula as
% refresh_rts_split_csv_from_expert_workbook / infer_rts_industrial_shares_from_email.
if ~isfile(rtsSplitCsv)
    fprintf('RTS split CSV missing; regenerating from %s\n', rtsRefCsv);
    ensure_rts_split_csv(rtsRefCsv, rtsSplitCsv, sCapAnchor, sGenAnchor, sCapAnchorYears);
end

fprintf('%s\n', repmat('=', 1, 70));
fprintf('Rewrite PDP8_PV_EV_BESS: RTS counterfactual 135 GW -> original 95 GW\n');
fprintf('%s\n', repmat('=', 1, 70));

years = (firstYear:lastYear)';
nY = numel(years);
tRel = years - 2025;

sGen = clampShare(interp1(sGenAnchorYears, sGenAnchor, years, 'linear', 'extrap'), ...
    years, sGenAnchorYears, sGenAnchor);
sCap = clampShare(interp1(sCapAnchorYears, sCapAnchor, years, 'linear', 'extrap'), ...
    years, sCapAnchorYears, sCapAnchor);

% -----------------------------------------------------------------------
% Path A (135 GW = Baseline) -- straight from the split CSV
% -----------------------------------------------------------------------
tA = readtable(rtsSplitCsv, 'VariableNamingRule', 'preserve');
ay = as_num(tA.('year'));
genIndA = alignA(ay, as_num(tA.('gen_industrial_GWh')), years);
genHHA  = alignA(ay, as_num(tA.('gen_household_GWh')),  years);
capIndA = alignA(ay, as_num(tA.('cap_industrial_MW')),  years);
capHHA  = alignA(ay, as_num(tA.('cap_household_MW')),   years);
genComA = commShareOfHousehold .* genHHA;
capComA = commShareOfHousehold .* capHHA;

% -----------------------------------------------------------------------
% Path B (95 GW) -- RTS_Capacity_GW_Base, generation by same-CF scaling
% -----------------------------------------------------------------------
tB = readtable(rtsRefCsv, 'VariableNamingRule', 'preserve');
byr  = as_num(tB.('Year'));
capB     = alignA(byr, as_num(tB.('RTS_Capacity_GW_Base')), years);
capHigh  = alignA(byr, as_num(tB.('RTS_Capacity_GW')),      years);
genHigh  = alignA(byr, as_num(tB.('RTS_Generation_TWh')),   years);
genTotB  = genHigh .* (capB ./ capHigh) .* 1000;          % GWh
capTotB  = capB .* 1000;                                  % MW

genIndB = sGen .* genTotB;
genComB = commShareOfHousehold .* (1 - sGen) .* genTotB;
capIndB = sCap .* capTotB;
capComB = commShareOfHousehold .* (1 - sCap) .* capTotB;
capResB = (1 - commShareOfHousehold) .* (1 - sCap) .* capTotB;

% -----------------------------------------------------------------------
% Channel 1 -- exo_AI_4_1_2 / exo_AI_5_1_2  (PV->EE coupling, B minus A)
% -----------------------------------------------------------------------
Dind = dIndBase2025 .* (1 + demandGrowth) .^ tRel;
Dser = dSerBase2025 .* (1 + demandGrowth) .^ tRel;

etaIndA = coupling(genIndA, Dind);
etaIndB = coupling(genIndB, Dind);
etaSerA = coupling(genComA, Dser);
etaSerB = coupling(genComB, Dser);

dAIind = etaIndB - etaIndA;                               % <= 0 from ~2029
dAIser = etaSerB - etaSerA;
savInd = 100 .* (1 - exp(-dAIind));
savSer = 100 .* (1 - exp(-dAIser));

% -----------------------------------------------------------------------
% Channel 2 -- exo_GA_4_1 / exo_GA_5_1  (RTS capital, B minus A)
% -----------------------------------------------------------------------
idxIndA = capIndA ./ capIndA(1);
idxIndB = capIndB ./ capIndB(1);
idxComA = capComA ./ capComA(1);
idxComB = capComB ./ capComB(1);

dGA4 = gaLevel0 .* (idxIndB - idxIndA);                   % <= 0 from ~2029
dGA5 = gaLevel0 .* (idxComB - idxComA);
rtsIndInv = backsolve_ka(dGA4, gdpBaseMioUSD, deltaKA);
rtsSerInv = backsolve_ka(dGA5, gdpBaseMioUSD, deltaKA);

% -----------------------------------------------------------------------
% Channel 3 -- exo_PV_1  (household RTS, B minus A) via investment-index ratio
% -----------------------------------------------------------------------
idxResA = capHHA  ./ capHHA(1);
idxResB = capResB ./ capResB(1);
IhatA = stock_index_to_investment_index(idxResA, deltaPV);
IhatB = stock_index_to_investment_index(idxResB, deltaPV);

pvBase = read_baseline_col(baselineWb, 'exo_PV_1', years);
ratioPV = IhatB ./ max(IhatA, 1e-12);
dPV = pvBase .* (ratioPV - 1);                            % <= 0
rtsHHInv = backsolve_ka(dPV, gdpBaseMioUSD, deltaKA);

% -----------------------------------------------------------------------
% Assemble clean CSV (schema read by load_expert_scenario_inputs)
% -----------------------------------------------------------------------
z = zeros(nY, 1);
T = table();
T.Year = years;
T.Industry_EE_Saving_pct        = savInd;
T.Services_EE_Saving_pct        = savSer;
T.Industry_EE_Investment_USDm   = z;      % pure RTS counterfactual: no retrofit EE
T.Services_EE_Investment_USDm   = z;
T.PV_Integration_Gain_pct       = z;      % no BESS
T.BESS_Annual_Investment_USDbn  = z;
T.RTS_Industry_Investment_USDm  = rtsIndInv;   % negative: scales exo_GA_4_1 down to 95 GW
T.RTS_Services_Investment_USDm  = rtsSerInv;
T.RTS_Household_Investment_USDm  = rtsHHInv;   % negative: scales exo_PV_1 down to 95 GW
% documentation columns (ignored by the builder)
T.RTS_GW_135 = capHigh;
T.RTS_GW_95  = capB;
T.eta_ind_A  = etaIndA;
T.eta_ind_B  = etaIndB;
T.eta_ser_A  = etaSerA;
T.eta_ser_B  = etaSerB;
T.dGA4       = dGA4;
T.dGA5       = dGA5;
T.dPV        = dPV;

writetable(T, outCsv);

% -----------------------------------------------------------------------
% Audit
% -----------------------------------------------------------------------
show = ismember(years, [2026 2028 2030 2040 2050]);
fprintf('\n year | RTS_GW 135/95 | dAI ind/ser | EE sav %%(i/s) | RTS inv USDm (ind/ser/hh)\n');
yy = years(show);
for k = 1:numel(yy)
    i = find(years == yy(k));
    fprintf(' %4d | %5.1f / %4.1f | %+7.4f / %+7.4f | %+6.2f / %+6.2f | %+8.0f / %+7.0f / %+8.0f\n', ...
        yy(k), capHigh(i), capB(i), dAIind(i), dAIser(i), savInd(i), savSer(i), ...
        rtsIndInv(i), rtsSerInv(i), rtsHHInv(i));
end
fprintf('-> Wrote %s\n', outCsv);
fprintf('%s\n', repmat('=', 1, 70));

% =======================================================================
% Helpers
% =======================================================================
function e = coupling(genGWh, demandGWh)
% Baseline PV->EE coupling: log((1-phi(1))/(1-phi(t))), phi = gen/demand.
phi = min(genGWh ./ demandGWh, 0.9999);
e = log((1 - phi(1)) ./ (1 - phi));
end

function inv = backsolve_ka(delta, gdpBase, dKA)
% Investment stream so that ka(t) = (1-dKA)*ka(t-1) + inv(t)/gdpBase reproduces delta(t).
n = numel(delta);
inv = zeros(n, 1);
inv(1) = gdpBase * delta(1);
for t = 2:n
    inv(t) = gdpBase * (delta(t) - (1 - dKA) * delta(t-1));
end
end

function Ihat = stock_index_to_investment_index(Khat, deltaPV)
% Ihat(1) = 1; Ihat(t) = (Khat(t) - (1-deltaPV)*Khat(t-1)) / deltaPV; negatives -> 0.
n = numel(Khat);
Ihat = zeros(n, 1);
Ihat(1) = 1;
for t = 2:n
    Ihat(t) = (Khat(t) - (1 - deltaPV) * Khat(t-1)) / deltaPV;
end
Ihat = max(Ihat, 0);
end

function v = alignA(srcYears, srcVals, years)
ok = isfinite(srcYears) & isfinite(srcVals);
v = interp1(srcYears(ok), srcVals(ok), years, 'linear', 'extrap');
end

function s = clampShare(s, years, anchorYears, anchorVals)
s = s(:);
s(years <= anchorYears(1))   = anchorVals(1);
s(years >= anchorYears(end)) = anchorVals(end);
s = min(max(s, 0), 1);
end

function ensure_rts_split_csv(rtsRefCsv, outCsv, sCapAnchor, sGenAnchor, anchorYears)
% Regenerate ExcelFiles/Output/RTS_split_assumptions_from_expert_email.csv from
% the PDP8-High RTS reference path + the expert-email industrial-share anchors.
t = readtable(rtsRefCsv, 'VariableNamingRule', 'preserve');
yr  = as_num(t.('Year'));
cap = as_num(t.('RTS_Capacity_GW'));      % PDP8-High path
gen = as_num(t.('RTS_Generation_TWh'));
ok  = isfinite(yr) & isfinite(cap) & isfinite(gen) & yr >= 2026 & yr <= 2050;
yr = yr(ok); capMW = 1000 * cap(ok); genGWh = 1000 * gen(ok);
sCap = clampShare(interp1(anchorYears, sCapAnchor, yr, 'linear', 'extrap'), yr, anchorYears, sCapAnchor);
sGen = clampShare(interp1(anchorYears, sGenAnchor, yr, 'linear', 'extrap'), yr, anchorYears, sGenAnchor);
capInd = sCap .* capMW;   capHH = capMW - capInd;
genInd = sGen .* genGWh;  genHH = genGWh - genInd;
T = table(yr, capMW, capInd, capHH, genGWh, genInd, genHH, 'VariableNames', ...
    {'year','cap_total_MW','cap_industrial_MW','cap_household_MW', ...
     'gen_total_GWh','gen_industrial_GWh','gen_household_GWh'});
if ~isfolder(fileparts(outCsv)), mkdir(fileparts(outCsv)); end
writetable(T, outCsv);
end

function v = read_baseline_col(wb, name, years)
hdr = readcell(wb, 'Sheet', 'Baseline', 'Range', '1:1');
data = readmatrix(wb, 'Sheet', 'Baseline');
ci = find(cellfun(@(x) (ischar(x) || isstring(x)) && strcmpi(strtrim(string(x)), name), hdr), 1);
assert(~isempty(ci), 'Column "%s" not found in Baseline sheet.', name);
yi = find(cellfun(@(x) (ischar(x) || isstring(x)) && strcmpi(strtrim(string(x)), "Year"), hdr), 1);
by = data(:, yi); bv = data(:, ci);
ok = isfinite(by) & isfinite(bv);
v = interp1(by(ok), bv(ok), years, 'linear', 'extrap');
end

function v = as_num(col)
if isnumeric(col)
    v = double(col(:));
    return
end
col = col(:);
v = nan(numel(col), 1);
for i = 1:numel(col)
    x = col(i);
    if iscell(x), x = x{1}; end
    if isnumeric(x) && isscalar(x)
        v(i) = double(x);
    elseif isstring(x) || ischar(x)
        d = str2double(strtrim(string(x)));
        if isfinite(d), v(i) = d; end
    end
end
end
