% prepare_ee_directive10_norts_input  Build the clean expert CSV for EE_Dir10_EEonly.
%
% Run from the repository root:
%   run('scripts/maintenance/prepare_ee_directive10_norts_input.m')
%
% EE_Dir10_EEonly = Directive 10's demand-side energy-efficiency
% measures ONLY, with every rooftop-solar (RTS) contribution taken out:
%   * no BESS / PV-integration gain,
%   * the RTS-attributable share of Directive 10's industry/services EE saving
%     removed (PV-coupling share: ~15 % industry, ~31 % services),
%   * the RTS-attributable EE gain that the *Baseline* carries in exo_AI_4_1_2 /
%     exo_AI_5_1_2 (apply_industrial_pv_to_ee_coupling) subtracted back out,
%   * the residential RTS ramp in the Baseline exo_PV_1 held flat.
%
% The Baseline workbook itself is NOT rebuilt -- the removal is done entirely on
% the scenario sheet, so this compares against the unchanged Baseline.
%
% Construction (per sector i in {industry=4, services=5})
% ------------------------------------------------------------
%   nonRTS_sav_i(t)  = Directive10.<i>_EE_Saving_pct(t) * (1 - rtsShare_i)
%   dAI_nonRTS_i(t)  = log(1 / (1 - nonRTS_sav_i(t)/100))
%   etaCoupling_i(t) = log((1 - phi_i(1)) / (1 - phi_i(t)))          % Baseline RTS coupling
%     phi_i(t) = gen_RTS_i(t) / D_i(t)
%     gen_RTS_industry = gen_industrial_GWh              (RTS_split_assumptions_from_expert_email.csv)
%     gen_RTS_services = 0.30 * gen_household_GWh
%     D_i(t)  = 177.55 / 56.95 TWh (2025) * 1.04^(t-2025)            [ee_pv_coupling.md]
%   dAI_sheet_i(t)   = dAI_nonRTS_i(t) - etaCoupling_i(t)            % may be negative
%   <i>_EE_Saving_pct(t) = 100 * (1 - exp(-dAI_sheet_i(t)))         % fed to exo_AI via the builder
%
%   The builder writes exo_AI_i = ai_iBase + log(1/(1-sav/100)) = ai_iBase +
%   dAI_sheet_i, i.e. Baseline non-RTS EE + Directive 10 non-RTS EE.
%
%   Household RTS: RTS_Household_Investment_USDm(t) is back-solved so the builder's
%   exo_PV_1 accumulation cancels the Baseline residential-RTS ramp, holding
%   exo_PV_1 flat at its first-year value.
%
% EE investment (Directive 10's retrofit cost) is kept; RTS_*_Investment (I+S) = 0.
%
% Output: ExcelFiles/Input/ExpertClean/Directive10_noBESS_noRTS.csv

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

rtsSplitCsv  = fullfile(repoRoot, 'ExcelFiles', 'Output', 'RTS_split_assumptions_from_expert_email.csv');
baselineWb   = fullfile(repoRoot, 'ExcelFiles', 'ModelBaseline5Sectorsand1Regions.xlsx');
outCsv       = fullfile(repoRoot, 'ExcelFiles', 'Input', 'ExpertClean', 'Directive10_noBESS_noRTS.csv');

envelopeSheet = 'Directive10_RTS_EE';
firstYear = 2026;
lastYear  = 2050;

rtsShareInd = 0.15;      % RTS share of Directive 10's industry EE saving (PV-coupling doc)
rtsShareSer = 0.31;      % RTS share of Directive 10's services EE saving
commShareOfHousehold = 0.30;   % services rooftop = 30% of the household bucket
dIndBase2025 = 177550;  % GWh
dSerBase2025 = 56950;   % GWh
demandGrowth = 0.04;
gdpBaseMioUSD = 430000; % matches create_ee_scenarios_from_expert_inputs.m
deltaKA = 0.10;
removeHouseholdRTS = true;

assert(isfile(expertWorkbook), 'Expert workbook not found:\n  %s', expertWorkbook);
assert(isfile(rtsSplitCsv),   'RTS split CSV not found:\n  %s', rtsSplitCsv);
assert(isfile(baselineWb),    'Baseline workbook not found:\n  %s', baselineWb);

fprintf('%s\n', repmat('=', 1, 70));
fprintf('Prepare EE_Dir10_EEonly expert input\n');
fprintf('%s\n', repmat('=', 1, 70));

years = (firstYear:lastYear)';
nY = numel(years);
tRel = years - 2025;

% -----------------------------------------------------------------------
% 1. Directive 10 saving envelope -> non-RTS portion
% -----------------------------------------------------------------------
S = read_expert_sheet(expertWorkbook, envelopeSheet);
savIndDir = pick(S, 'Industry_EE_Saving_pct', years);
savSerDir = pick(S, 'Services_EE_Saving_pct', years);
invIndDir = pick(S, 'Industry_EE_Investment_USDm', years);
invSerDir = pick(S, 'Services_EE_Investment_USDm', years);

nonRtsSavInd = savIndDir .* (1 - rtsShareInd);
nonRtsSavSer = savSerDir .* (1 - rtsShareSer);
dAInonRtsInd = log(1 ./ (1 - min(nonRtsSavInd, 99) ./ 100));
dAInonRtsSer = log(1 ./ (1 - min(nonRtsSavSer, 99) ./ 100));

% -----------------------------------------------------------------------
% 2. Baseline RTS->EE coupling to subtract (same formula the baseline builder uses)
% -----------------------------------------------------------------------
tS = readtable(rtsSplitCsv, 'VariableNamingRule', 'preserve');
sy = as_num(tS.('year'));
genInd = as_num(tS.('gen_industrial_GWh'));
genHH  = as_num(tS.('gen_household_GWh'));
genIndY = interp1(sy, genInd, years, 'linear', 'extrap');
genSerY = commShareOfHousehold .* interp1(sy, genHH, years, 'linear', 'extrap');

Dind = dIndBase2025 .* (1 + demandGrowth) .^ tRel;
Dser = dSerBase2025 .* (1 + demandGrowth) .^ tRel;
phiInd = min(genIndY ./ Dind, 0.9999);
phiSer = min(genSerY ./ Dser, 0.9999);
etaCouplingInd = log((1 - phiInd(1)) ./ (1 - phiInd));
etaCouplingSer = log((1 - phiSer(1)) ./ (1 - phiSer));

% -----------------------------------------------------------------------
% 3. Net sheet increment -> EE saving % fed to the builder (may be negative)
% -----------------------------------------------------------------------
dAIsheetInd = dAInonRtsInd - etaCouplingInd;
dAIsheetSer = dAInonRtsSer - etaCouplingSer;
savIndOut = 100 .* (1 - exp(-dAIsheetInd));
savSerOut = 100 .* (1 - exp(-dAIsheetSer));

% -----------------------------------------------------------------------
% 4. Household RTS: back-solve RTS_Household_Investment_USDm to flatten exo_PV_1
% -----------------------------------------------------------------------
rtsHHInv = zeros(nY, 1);
if removeHouseholdRTS
    pvBase = read_baseline_col(baselineWb, 'exo_PV_1', years);
    pvTarget = repmat(pvBase(1), nY, 1);          % hold flat at first-year value
    pvPath = pvTarget - pvBase;                   % accumulation the builder must reproduce
    rtsHHInv(1) = gdpBaseMioUSD * pvPath(1);
    for i = 2:nY
        rtsHHInv(i) = gdpBaseMioUSD * (pvPath(i) - (1 - deltaKA) * pvPath(i-1));
    end
end

% -----------------------------------------------------------------------
% 5. Assemble clean CSV
% -----------------------------------------------------------------------
z = zeros(nY, 1);
T = table();
T.Year = years;
T.Industry_EE_Saving_pct        = savIndOut;
T.Services_EE_Saving_pct        = savSerOut;
T.Industry_EE_Investment_USDm   = invIndDir;   % Directive 10 retrofit cost, kept
T.Services_EE_Investment_USDm   = invSerDir;
T.PV_Integration_Gain_pct       = z;           % no BESS / integration gain
T.BESS_Annual_Investment_USDbn  = z;
T.RTS_Industry_Investment_USDm  = z;
T.RTS_Services_Investment_USDm  = z;
T.RTS_Household_Investment_USDm  = rtsHHInv;   % negative: cancels Baseline residential RTS in exo_PV_1
% documentation columns (ignored by the builder)
T.Directive10_Saving_Industry_pct = savIndDir;
T.Directive10_Saving_Services_pct = savSerDir;
T.NonRTS_Saving_Industry_pct      = nonRtsSavInd;
T.NonRTS_Saving_Services_pct      = nonRtsSavSer;
T.Baseline_RTS_coupling_Industry  = etaCouplingInd;
T.Baseline_RTS_coupling_Services  = etaCouplingSer;
T.Net_dAI_Industry               = dAIsheetInd;
T.Net_dAI_Services               = dAIsheetSer;

writetable(T, outCsv);

% -----------------------------------------------------------------------
% Audit
% -----------------------------------------------------------------------
show = ismember(years, [2026 2030 2040 2050]);
fprintf('\n year | Dir10 sav %%(i/s) | Baseline RTS coupling(i/s) | net dAI(i/s) | sheet sav %%(i/s)\n');
yy = years(show);
for k = 1:numel(yy)
    i = find(years == yy(k));
    fprintf(' %4d | %5.2f / %4.2f    | %7.4f / %7.4f          | %7.4f / %7.4f | %6.2f / %6.2f\n', ...
        yy(k), savIndDir(i), savSerDir(i), etaCouplingInd(i), etaCouplingSer(i), ...
        dAIsheetInd(i), dAIsheetSer(i), savIndOut(i), savSerOut(i));
end
fprintf('-> Wrote %s\n', outCsv);
fprintf('%s\n', repmat('=', 1, 70));

% =======================================================================
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

function S = read_expert_sheet(workbookPath, sheetName)
raw = readcell(workbookPath, 'Sheet', sheetName);
hdrRow = [];
for cc = 1:min(3, size(raw, 2))
    r = find(cellfun(@(x) (ischar(x) || isstring(x)) && ...
        strcmpi(strtrim(string(x)), "Year"), raw(:, cc)), 1, 'first');
    if ~isempty(r), hdrRow = r; break, end
end
assert(~isempty(hdrRow), 'No "Year" header row in sheet "%s".', sheetName);
headers = string(raw(hdrRow, :));
dataRows = raw((hdrRow + 1):end, :);
S = struct();
for c = 1:numel(headers)
    nm = matlab.lang.makeValidName(strtrim(headers(c)));
    if isempty(char(nm)), continue, end
    S.(nm) = as_num(dataRows(:, c));
end
S.Year = as_num(dataRows(:, find(strcmpi(strtrim(headers), "Year"), 1)));
end

function v = pick(S, name, years)
key = matlab.lang.makeValidName(name);
assert(isfield(S, key), 'Column "%s" not found in sheet struct.', name);
ok = isfinite(S.Year) & isfinite(S.(key));
v = interp1(S.Year(ok), S.(key)(ok), years, 'linear', 'extrap');
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
