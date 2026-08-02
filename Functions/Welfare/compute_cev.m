function [lambdaPct, diagOut] = compute_cev(dsScenario, dsBaseline, params, beta)
% Consumption-equivalent variation (CEV) of a scenario relative to a baseline.
%
% Finds the scalar lambda such that scaling the BASELINE's (C,H) path
% uniformly by (1+lambda), holding the baseline's labor path fixed, yields
% the same discounted lifetime utility as the scenario's actual path.
% Because uBundle = cHab^(1-gammaH) * hpc^gammaH is homogeneous of degree 1
% in (C,H), this has closed form (see plan doc for derivation):
%   sigmaC == 1 (log case, current calibration):
%     lambda = exp((1-beta) * (W_scenario - W_baseline)) - 1
%   sigmaC ~= 1 (general CRRA case):
%     (1+lambda)^(1-sigmaC) = (W_scenario + LaborPV_baseline) / CH_PV_baseline
%
% lambdaPct is lambda expressed in percent (positive = scenario welfare-
% superior to baseline). diagOut carries the underlying PV components for
% inspection/debugging.

[Uscenario, ~, ~] = compute_period_utility(dsScenario, params);
[~, chFelicityBase, laborDisBase] = compute_period_utility(dsBaseline, params);

T = min(length(Uscenario), length(chFelicityBase));
discount = beta .^ (0:T-1)';

Wscenario = sum(discount .* Uscenario(1:T));
chPvBase = sum(discount .* chFelicityBase(1:T));
laborPvBase = sum(discount .* laborDisBase(1:T));
Wbase = chPvBase - laborPvBase;

if abs(params.sigmaC - 1) < 1e-10
    lambda = exp((1 - beta) * (Wscenario - Wbase)) - 1;
else
    ratio = (Wscenario + laborPvBase) / chPvBase;
    lambda = ratio ^ (1 / (1 - params.sigmaC)) - 1;
end

lambdaPct = lambda * 100;

diagOut = struct('T', T, 'Wscenario', Wscenario, 'Wbaseline', Wbase, ...
    'chPvBaseline', chPvBase, 'laborPvBaseline', laborPvBase);

end
