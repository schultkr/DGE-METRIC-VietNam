function ratios = compute_pdp8_capital_investment_ratio(repoRoot, deltaMaintFossil, deltaMaintRenewable, ...
    sFossilPath, sRenewablePath, yPath, popPath, etaKS_p, fossilParams, renewParams, years)
% COMPUTE_PDP8_CAPITAL_INVESTMENT_RATIO  Initial I_0/K_0 for fossil/renewables,
% found ITERATIVELY by forward-simulating the model's OWN capital-goods
% supply-price equation (investment_adjustment.mod, lCapPrice==1) period by
% period, and searching for the initial investment/capital ratio that makes
% the resulting terminal/initial capital-stock ratio match PDP8's target.
%
% ratios = compute_pdp8_capital_investment_ratio(repoRoot, deltaMaintFossil, deltaMaintRenewable, ...
%     sFossilPath, sRenewablePath, yPath, popPath, etaKS_p, fossilParams, renewParams, years)
%
% NOTE: the regional consumer price P_reg does NOT appear as an input here
% even though it appears in the wedge equation (I_pos*P_INV = s*y*P_reg):
% it cancels exactly out of nomRatio(t) = [s(t)*y(t)*P_reg]/[s(1)*y(1)*P_reg]
% (see METHOD below), so no assumption about its path is needed at all.
%
% METHOD
%   This replaces an earlier closed-form version that deflated the nominal
%   investment path by an EXOGENOUS PDP8 CAPEX_kUSD_MW price index. Here,
%   the investment price is instead solved from the model's OWN equations at
%   every period, so it genuinely reflects "how the investment price
%   develops depending on the change in the investment flow" as the model
%   itself would compute it.
%
%   Two equations bind jointly at each period t (investment_wedge.mod's muI
%   wedge, and investment_adjustment.mod's lCapPrice==1 supply curve):
%     (I)  I_pos(t) * P_INV(t) = s(t) * y(t) * P_reg
%     (II) P_INV(t) = PINVbase * (I_pos(t)/IRef(t))^(1/etaKS_p) * exp(exo_I(t))
%   where I_pos(t) = I(t)+I_G(t) (the combined quantity both equations
%   actually use -- the split into I_H/I_FDI/I_G is a separate, existing
%   mechanism handled entirely by reshuffle_initial_period.m step 1, not
%   re-derived here) and IRef(t) = delta*K(t-1) (replacement investment;
%   D_K assumed ~0, consistent with the prior closed-form version).
%
%   Solving (I) and (II) for the RELATIVE investment share q(t)=I_pos(t)/I_pos(1)
%   (rather than I_pos(t) itself, which is not yet known) gives a closed
%   form at each period, given I_pos(1) and the accumulated K(t-1):
%
%     nomRatio(t)  = [s(t)*y(t)] / [s(1)*y(1)]              (P_reg cancels)
%     refRatio(t)  = (IRef(1)/IRef(t))^(1/etaKS_p)
%     expShift(t)  = exp(exo_I(t) - exo_I(1))
%     q(t)         = [nomRatio(t) / (refRatio(t)*expShift(t))]^(etaKS_p/(etaKS_p+1))
%     I_pos(t)     = q(t) * I_pos(1)
%     K(t)         = (1-delta)*(PoP(t)/PoP(t-1))*K(t-1) + I_pos(t)
%
%   IRef(1) = delta*K(1) (period 1 bootstrapped against its own capital, the
%   same convention used elsewhere in this pipeline). I_pos(1) does not
%   enter q(2) directly (IRef(2) uses the FIXED K(1)), but from t=3 onward
%   the dependence compounds through the accumulated K path -- so the
%   OUTER search over I_pos(1) is genuinely well-posed for N>=3.
%
%   OUTER: I_pos(1) [equivalently tIK=I_pos(1)/K(1)] is found via a 1-D
%   root-find (fzero) so that the resulting K(N)/K(1) matches PDP8's
%   Capacity_MW(N)/Capacity_MW(1) target. K(1) itself is NEVER touched.
%
%   Only PDP8's Capacity_MW (the terminal/initial physical capacity target)
%   is still read from Investment.csv -- CAPEX_kUSD_MW/delta_cap (the old
%   exogenous price-index inputs) are no longer used at all, since price is
%   now endogenous to the forward simulation.
%
% Inputs:
%   repoRoot            [character] repository root.
%   deltaMaintFossil    [numeric] fossil depreciation rate, delta_2_1_p.
%   deltaMaintRenewable [numeric] renewable depreciation rate, delta_3_1_p.
%   sFossilPath         [numeric, 1 x numel(years)] exo_targetIY_2_1(t).
%   sRenewablePath      [numeric, 1 x numel(years)] exo_targetIY_3_1(t).
%   yPath               [numeric, 1 x numel(years)] regional nominal GDP
%                        path (Y_1), aligned 1:1 with `years`.
%   popPath             [numeric, 1 x numel(years)] regional population path
%                        (PoP_1), aligned 1:1 with `years`.
%   etaKS_p             [numeric scalar] capital-goods supply elasticity.
%   fossilParams        [struct] .K1 (current K_2_1, untouched), .PINVbase
%                        (P0_2_1_p), .exoIPath (1 x numel(years), exo_I_2_1(t)
%                        read from oo_.exo_simul).
%   renewParams         [struct] same fields as fossilParams for K_3_1.
%   years               [numeric, optional] full PDP8 horizon corresponding
%                        1:1 to sFossilPath/sRenewablePath/yPath/popPath/
%                        the exoIPath fields (t=1 is years(1), t=N is
%                        years(end)). Default: 2025:2050.
%
% Output:
%   ratios.Fossil / .Renewable                  I_0/K_0 = tIK (feed into
%                                                tabtargets.IK_2_1 / IK_3_1)
%   ratios.FossilPriceIndex / .RenewablePriceIndex   P_INV(t)/P_INV(1) path
%                                                (feed into
%                                                tabtargets.PINVIndex_2_1/3_1)
%   ratios.FossilRealIndex / .RenewableRealIndex     q(t) = I_pos(t)/I_pos(1)
%                                                path (diagnostic)
%   ratios.FossilCapacityRatio / .RenewableCapacityRatio   K_T/K_0 target used
%   ratios.FossilRealizedRatio / .RenewableRealizedRatio   K_T/K_0 actually
%                                                achieved by the solved tIK
%                                                (should match CapacityRatio
%                                                to solver tolerance)
%   ratios.Years                                the years used

if nargin < 2 || isempty(deltaMaintFossil) || ~isfinite(deltaMaintFossil)
    deltaMaintFossil = 0.05;
end
if nargin < 3 || isempty(deltaMaintRenewable) || ~isfinite(deltaMaintRenewable)
    deltaMaintRenewable = 0.05;
end
if nargin < 11 || isempty(years)
    years = 2025:2050;
end
years = reshape(years, 1, []);
N = numel(years);
if N < 2
    error('compute_pdp8_capital_investment_ratio:NotEnoughYears', ...
        'Need at least 2 years to solve for the initial I/K ratio; got %d.', N);
end

sFossilPath    = reshape(sFossilPath, 1, []);
sRenewablePath = reshape(sRenewablePath, 1, []);
yPath          = reshape(yPath, 1, []);
popPath        = reshape(popPath, 1, []);
if numel(sFossilPath) ~= N || numel(sRenewablePath) ~= N || numel(yPath) ~= N || numel(popPath) ~= N
    error('compute_pdp8_capital_investment_ratio:PathLengthMismatch', ...
        ['sFossilPath/sRenewablePath/yPath/popPath must each have %d elements ' ...
         '(one per requested year, aligned 1:1 with years); got %d/%d/%d/%d.'], ...
        N, numel(sFossilPath), numel(sRenewablePath), numel(yPath), numel(popPath));
end
if ~isfinite(sFossilPath(1)) || sFossilPath(1) <= 0
    error('compute_pdp8_capital_investment_ratio:InvalidFossilTarget', ...
        'sFossilPath(1) (exo_targetIY_2_1 at the initial period) must be positive.');
end
if ~isfinite(sRenewablePath(1)) || sRenewablePath(1) <= 0
    error('compute_pdp8_capital_investment_ratio:InvalidRenewableTarget', ...
        'sRenewablePath(1) (exo_targetIY_3_1 at the initial period) must be positive.');
end
if any(~isfinite(yPath)) || any(yPath <= 0)
    error('compute_pdp8_capital_investment_ratio:InvalidGDPPath', ...
        'yPath must be finite and positive for all requested years.');
end
if any(~isfinite(popPath)) || any(popPath <= 0)
    error('compute_pdp8_capital_investment_ratio:InvalidPopulationPath', ...
        'popPath must be finite and positive for all requested years.');
end
if ~isfinite(etaKS_p) || etaKS_p <= 0
    error('compute_pdp8_capital_investment_ratio:InvalidEtaKS', 'etaKS_p must be positive.');
end

invFile = fullfile(repoRoot, 'ExcelFiles', 'PDP8', 'Investment.csv');
if ~isfile(invFile)
    error('compute_pdp8_capital_investment_ratio:MissingFile', ...
        'PDP8 Investment.csv not found:\n  %s', invFile);
end

inv = readtable(invFile, 'VariableNamingRule', 'preserve', 'TreatAsEmpty', {'NA'});
requiredCols = {'Plan', 'Year', 'Technology', 'Capacity_MW'};
missingCols = requiredCols(~ismember(requiredCols, inv.Properties.VariableNames));
if ~isempty(missingCols)
    error('compute_pdp8_capital_investment_ratio:UnexpectedColumns', ...
        'Investment.csv is missing required columns: %s.', strjoin(missingCols, ', '));
end

invPlan = inv(strcmpi(string(inv.Plan), "PDP8_rev_high"), :);
if isempty(invPlan)
    error('compute_pdp8_capital_investment_ratio:NoPlanRows', ...
        'No rows found in Investment.csv for Plan == PDP8_rev_high.');
end

invYear = as_numeric(invPlan.Year);
capMW   = as_numeric(invPlan.Capacity_MW);
tech    = string(invPlan.Technology);
isFossilTech = is_fossil_tech(tech);
isRenewTech  = ~isFossilTech;

kT_k0Fossil    = capacity_ratio(isFossilTech, invYear, capMW, years);
kT_k0Renewable = capacity_ratio(isRenewTech,  invYear, capMW, years);

nominalRatioFossil    = (sFossilPath    ./ sFossilPath(1))    .* (yPath ./ yPath(1));
nominalRatioRenewable = (sRenewablePath ./ sRenewablePath(1)) .* (yPath ./ yPath(1));
[ratios.Fossil, ratios.FossilPriceIndex, ratios.FossilRealIndex, ratios.FossilRealizedRatio] = ...
    solve_initial_ik_ratio(deltaMaintFossil, nominalRatioFossil, popPath, fossilParams, etaKS_p, kT_k0Fossil, N, sFossilPath(1)*yPath(1));
ratios.FossilCapacityRatio = kT_k0Fossil;

[ratios.Renewable, ratios.RenewablePriceIndex, ratios.RenewableRealIndex, ratios.RenewableRealizedRatio] = ...
    solve_initial_ik_ratio(deltaMaintRenewable, nominalRatioRenewable, popPath, renewParams, etaKS_p, kT_k0Renewable, N, sRenewablePath(1)*yPath(1));
ratios.RenewableCapacityRatio = kT_k0Renewable;

ratios.Years = years;
end

function kT_k0 = capacity_ratio(techMask, invYear, capMW, years)
N = numel(years);
capacityMW = nan(1, N);
for i = 1:N
    capacityMW(i) = nansum(capMW(techMask & (invYear == years(i))));
end
if any(~isfinite(capacityMW)) || any(capacityMW <= 0)
    error('compute_pdp8_capital_investment_ratio:InvalidCapacity', ...
        'Could not determine positive Capacity_MW for all requested years.');
end
kT_k0 = capacityMW(end) / capacityMW(1);
end

function [tIK, priceIndex, qPath, realizedRatio] = solve_initial_ik_ratio(deltaMaint, nominalRatio, popPath, params, etaKS_p, kT_k0, N, nominalInit)
K1 = params.K1;

PINVbase = params.PINVbase;
exoIPath = reshape(params.exoIPath, 1, []);
if ~isfinite(K1) || K1 <= 0
    error('compute_pdp8_capital_investment_ratio:InvalidK1', 'K1 must be positive.');
end
if ~isfinite(PINVbase) || PINVbase <= 0
    error('compute_pdp8_capital_investment_ratio:InvalidPINVbase', 'PINVbase must be positive.');
end
if numel(exoIPath) ~= N
    error('compute_pdp8_capital_investment_ratio:ExoIPathLengthMismatch', ...
        'exoIPath must have %d elements; got %d.', N, numel(exoIPath));
end

popRel = popPath ./ popPath(1);

% Starting guess for fzero: the "natural" tIK implied by pure replacement
% investment (I_pos(1)/IRef(1)=1). Only a starting point for the root-find,
% not the returned answer.
initialGuess = deltaMaint;

objFun = @(tIK) forward_simulate(tIK, deltaMaint, nominalRatio, popRel, K1, PINVbase, etaKS_p, exoIPath, N, nominalInit) - kT_k0;

options = optimset('TolX', 1e-10, 'Display', 'off');
[tIK, ~, exitflag] = fsolve(objFun, initialGuess, options);

if exitflag <= 0 || ~isfinite(tIK) || tIK <= 0
    error('compute_pdp8_capital_investment_ratio:RootFindFailed', ...
        ['fzero failed to find a positive initial I/K ratio reproducing the PDP8 terminal ' ...
         'capacity target (exitflag=%d).'], exitflag);
end

[realizedRatio, qPath, priceIndex] = forward_simulate(tIK, deltaMaint, nominalRatio, popRel, K1, PINVbase, etaKS_p, exoIPath, N, nominalInit);
end

function [kTk0Model, qPath, priceIndex] = forward_simulate(tIK, deltaMaint, nominalRatio, popRel, K1, PINVbase, etaKS_p, exoIPath, N, nominalInit)
Ipos1 = tIK * K1;
Kprev = K1;
IRef1 = deltaMaint * K1;
PINVInit = nominalInit/Ipos1;
PINV0 = nominalInit/(deltaMaint * K1);
exoIPath(1:N) = log(PINVInit/PINV0) + exoIPath(1:N);
qPath = nan(1, N);
priceIndex = nan(1, N);
qPath(1) = 1;
priceIndex(1) = 1;

for t = 2:N
    IRefT = deltaMaint * Kprev;
    if ~isfinite(IRefT) || IRefT <= 0
        kTk0Model = NaN;
        return
    end
    refRatio = (IRef1 / IRefT) ^ (1 / etaKS_p);
    expShift = exp(exoIPath(t) - exoIPath(1));
    qT = (nominalRatio(t) / (refRatio * expShift)) ^ (etaKS_p / (etaKS_p + 1));
    qPath(t) = qT;
    priceIndex(t) = qT ^ (1 / etaKS_p) * refRatio * expShift;

    IposT = qT * Ipos1;
    Kprev = (1 - deltaMaint) * (popRel(t) / popRel(t - 1)) * Kprev + IposT;
end

kTk0Model = Kprev / K1;
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
