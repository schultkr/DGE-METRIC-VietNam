% prepare_ee_pdp8_rts_expert_input  Build the clean expert CSV for the EE_Dir10_RTSslice scenario.
%   (clean-CSV / expert-sheet name stays EE_PDP8_RTS; model sheet is EE_Dir10_RTSslice)
%
% Run from the repository root:
%   run('scripts/maintenance/prepare_ee_pdp8_rts_expert_input.m')
%
% EE_Dir10_RTSslice isolates the rooftop-solar (RTS) contribution to Directive 10,
% deployed in industry and services, for comparison against Baseline and
% EE_Dir10_full. It is consumed by create_ee_scenarios_from_expert_inputs.m
% exactly like the other EE expert scenarios (clean CSV in ExpertClean/).
%
% Method
% ------
% RTS effort attributable to industry + services is the difference between the
% two expert scenario sheets in
%   ExcelFiles[/PDP8]/Vietnam_EnergyExpert_ScenarioInputs*.xlsx
%       Directive10_RTS_EE  (accelerated RTS)  minus
%       PDP8_revised        (reference RTS)
% assumed to be implemented in industry and services.
%
%   f(t) = ( RTS_Directive10(t) - RTS_PDP8_revised(t) ) / RTS_Directive10(t)   in [0,1]
%          (capacity basis; identical on a generation basis - same CF in both sheets)
%
% Baseline assumption: the extra rooftop in the compiled model Baseline (PDP8
% High) relative to PDP8_revised is ENTIRELY RESIDENTIAL. Hence PDP8 High and
% PDP8_revised carry the same C&I (industry+services) rooftop, and the
% Directive10 - PDP8_revised C&I difference is a clean add-on over the Baseline.
% The C&I share cancels inside f(t), so f is computed on totals; it is applied
% only to the physical/investment add-on (section 3).
%
% Energy saving = RTS-attributable slice of Directive 10's own sector EE path:
%   Industry_EE_Saving_pct(t) = f(t) * Directive10.Industry_EE_Saving_pct(t)
%   Services_EE_Saving_pct(t) = f(t) * Directive10.Services_EE_Saving_pct(t)
% -> create_ee_scenarios_from_expert_inputs.m maps these to exo_AI_4_1_2 / exo_AI_5_1_2,
%    the same lever EE_Dir10_full uses.
%
% RTS investment = incremental C&I rooftop capacity additions,
%     candi_share(t) * ( RTS_Directive10(t) - RTS_PDP8_revised(t) ),
%   (candi_share = expert-email non-residential share, 0.496 in 2030 -> 0.429 in 2050),
%   valued at "Solar PV (Rooftop)" CAPEX from ExcelFiles/PDP8/CAPEXINTER.csv, split
%   industry:services by Directive 10's Industry_EE_Investment : Services_EE_Investment
%   ratio (~81/19). Written to RTS_Industry_Investment_USDm / RTS_Services_Investment_USDm
%   -> accumulated into exo_GA_4_1 / exo_GA_5_1 by the builder.
%
% Everything else is zero: generic EE investment, PV integration gain, BESS
% investment, household RTS. Cap-and-trade is set by the builder (capTradeValue = 1),
% matching EE_Dir10_full.
%
% Output: ExcelFiles/Input/ExpertClean/EE_PDP8_RTS.csv

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);

% -----------------------------------------------------------------------
% Configuration
% -----------------------------------------------------------------------
expertPreferred = fullfile(repoRoot, 'ExcelFiles', 'PDP8', ...
    'Vietnam_EnergyExpert_ScenarioInputs - Adjust_2505.xlsx');
expertFallback  = fullfile(repoRoot, 'ExcelFiles', ...
    'Vietnam_EnergyExpert_ScenarioInputs.xlsx');
if isfile(expertPreferred)
    expertWorkbook = expertPreferred;
else
    expertWorkbook = expertFallback;
end

capexCsv = fullfile(repoRoot, 'ExcelFiles', 'PDP8', 'CAPEXINTER.csv');
outCsv   = fullfile(repoRoot, 'ExcelFiles', 'Input', 'ExpertClean', 'EE_PDP8_RTS.csv');

baselineSheet  = 'PDP8_revised';
directiveSheet = 'Directive10_RTS_EE';
firstYear = 2026;
lastYear  = 2050;

assert(isfile(expertWorkbook), 'Expert workbook not found:\n  %s', expertWorkbook);
assert(isfile(capexCsv),       'CAPEXINTER CSV not found:\n  %s', capexCsv);

fprintf('%s\n', repmat('=', 1, 70));
fprintf('Prepare EE_PDP8_RTS expert input\n');
fprintf('%s\n', repmat('=', 1, 70));
fprintf('Expert workbook: %s\n', expertWorkbook);

% -----------------------------------------------------------------------
% 1. Read the two RTS scenario sheets
% -----------------------------------------------------------------------
B = read_expert_sheet(expertWorkbook, baselineSheet);
D = read_expert_sheet(expertWorkbook, directiveSheet);

years = (firstYear:lastYear)';
capBase = pick(B, 'RTS_Capacity_GW', years);
capDir  = pick(D, 'RTS_Capacity_GW', years);
savIndDir = pick(D, 'Industry_EE_Saving_pct', years);
savComDir = pick(D, 'Services_EE_Saving_pct', years);
invIndDir = pick(D, 'Industry_EE_Investment_USDm', years);
invComDir = pick(D, 'Services_EE_Investment_USDm', years);

% -----------------------------------------------------------------------
% 2. RTS-attributable fraction and sector EE saving
% -----------------------------------------------------------------------
% f(t) is the share of Directive 10's C&I (industry+services) rooftop fleet
% that is incremental over the PDP8_revised reference. The C&I share cancels
% ( [s*capDir - s*capBase] / [s*capDir] = [capDir - capBase]/capDir ), so f is
% computed on totals. Assumption: the extra rooftop in the compiled Baseline
% (PDP8 High) vs PDP8_revised is entirely RESIDENTIAL, so PDP8 High and
% PDP8_revised share the same C&I rooftop and this increment is a clean add-on.
f = (capDir - capBase) ./ capDir;
f(~isfinite(f)) = 0;
f = min(max(f, 0), 1);

savInd = f .* savIndDir;
savCom = f .* savComDir;

% -----------------------------------------------------------------------
% 3. Incremental C&I rooftop capacity additions -> RTS investment cost
% -----------------------------------------------------------------------
% Only the C&I (industry+services) portion of the Directive10 - PDP8_revised
% rooftop difference is the industry/services add-on; the residential portion
% is out of scope. C&I share from the expert-email anchors (same values the
% baseline pipeline's read_vietnam_rts_sector_plan uses).
candiShare = candi_share(years);
deltaCapGW = candiShare .* max(0, capDir - capBase);   % incremental C&I fleet, GW
addMW = max(0, [deltaCapGW(1); diff(deltaCapGW)]) * 1000;   % annual C&I additions, MW/yr

split = invIndDir ./ (invIndDir + invComDir);          % industry share of sector EE spend
split(~isfinite(split)) = 0.5;
split = min(max(split, 0), 1);
addInd = addMW .* split;
addCom = addMW .* (1 - split);

capexPerMW = rooftop_capex_kusd_per_mw(capexCsv, years);   % kUSD/MW
invInd = addInd .* capexPerMW / 1000;                  % USD m / yr
invCom = addCom .* capexPerMW / 1000;

% -----------------------------------------------------------------------
% 4. Assemble clean CSV (schema read by load_expert_scenario_inputs)
% -----------------------------------------------------------------------
z = zeros(numel(years), 1);
T = table();
T.Year = years;
T.Industry_EE_Saving_pct        = savInd;
T.Services_EE_Saving_pct        = savCom;
T.Industry_EE_Investment_USDm   = z;
T.Services_EE_Investment_USDm   = z;
T.PV_Integration_Gain_pct       = z;
T.BESS_Annual_Investment_USDbn  = z;
T.RTS_Industry_Investment_USDm  = invInd;
T.RTS_Services_Investment_USDm  = invCom;
T.RTS_Household_Investment_USDm  = z;

writetable(T, outCsv);

% -----------------------------------------------------------------------
% Audit
% -----------------------------------------------------------------------
show = ismember(years, [2026 2030 2040 2050]);
fprintf('\n year | C&I sh |   f   | Ind_sav%% | Ser_sav%% | dC&I_GW | RTS_add_MW | RTS_inv_USDm(I+S)\n');
yy = years(show); cs = candiShare(show); ff = f(show); si = savInd(show); sc = savCom(show);
dc = deltaCapGW(show); am = addMW(show); iv = invInd(show) + invCom(show);
for k = 1:numel(yy)
    fprintf(' %4d | %.3f | %.3f |  %6.2f  |  %6.2f  | %6.2f |  %8.1f  |  %10.1f\n', ...
        yy(k), cs(k), ff(k), si(k), sc(k), dc(k), am(k), iv(k));
end
fprintf(['\nTotals: incremental C&I RTS %.1f GW (peak stock %.1f GW), ' ...
    'RTS investment USD %.2f bn (industry %.2f, services %.2f)\n'], ...
    sum(addMW)/1000, max(deltaCapGW), sum(invInd+invCom)/1000, sum(invInd)/1000, sum(invCom)/1000);
fprintf('-> Wrote %s\n', outCsv);
fprintf('%s\n', repmat('=', 1, 70));

% =======================================================================
% Helpers
% =======================================================================
function S = read_expert_sheet(workbookPath, sheetName)
% Read an expert scenario sheet into a struct of numeric column vectors,
% keyed by header name. Header row is the row whose first cell is 'Year'.
raw = readcell(workbookPath, 'Sheet', sheetName);
hdrRow = find(cellfun(@(x) (ischar(x) || isstring(x)) && ...
    strcmpi(strtrim(string(x)), "Year"), raw(:, 1)), 1, 'first');
assert(~isempty(hdrRow), 'No "Year" header row in sheet "%s".', sheetName);
headers = string(raw(hdrRow, :));
dataRows = raw((hdrRow + 1):end, :);
S = struct();
for c = 1:numel(headers)
    name = matlab.lang.makeValidName(strtrim(headers(c)));
    if isempty(char(name)), continue, end
    S.(name) = as_num(dataRows(:, c));
end
S.Year = as_num(dataRows(:, find(strcmpi(strtrim(headers), "Year"), 1)));
end

function v = pick(S, name, years)
% Value of column `name` aligned to `years` (hold-last outside coverage).
key = matlab.lang.makeValidName(name);
assert(isfield(S, key), 'Column "%s" not found in sheet struct.', name);
ok = isfinite(S.Year) & isfinite(S.(key));
v = interp1(S.Year(ok), S.(key)(ok), years, 'linear', 'extrap');
end

function s = candi_share(years)
% C&I (industry+commercial, i.e. non-residential) share of total rooftop PV.
% Anchors from the expert email, matching infer_rts_industrial_shares_from_email
% in create_baseline_from_user_input_file.m (kept in sync deliberately).
anchorYears = [2030, 2050];
anchorShare = [18231 / 36733, 59000 / 137670];   % 0.4963 -> 0.4286
years = years(:);
s = interp1(anchorYears, anchorShare, years, 'linear', 'extrap');
s(years <= anchorYears(1)) = anchorShare(1);
s(years >= anchorYears(end)) = anchorShare(end);
s = min(max(s, 0), 1);
end

function capexPerMW = rooftop_capex_kusd_per_mw(capexCsv, years)
t = readtable(capexCsv, 'VariableNamingRule', 'preserve');
yr = as_num(t.('Year'));
isRoof = strcmpi(strtrim(string(t.('Tech'))), 'Solar PV (Rooftop)');
assert(any(isRoof), 'No "Solar PV (Rooftop)" rows in %s', capexCsv);
kv = as_num(t.('CAPEX_kUSD_MW'));
ok = isRoof & isfinite(yr) & isfinite(kv);
capexPerMW = interp1(yr(ok), kv(ok), years, 'previous', 'extrap');
lastVal = kv(ok);
capexPerMW(~isfinite(capexPerMW)) = lastVal(end);
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
