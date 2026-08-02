function [U, chFelicity, laborDis] = compute_period_utility(ds, params)
% Evaluates the household felicity function U(C_t, H_{t+1}, N_{s,t}) row-by-row
% along a scenario's simulated path, matching ModFiles/Equations/households.mod:
%   cHab_t = (C_t - h*C_{t-1}) / PoP_t
%   hpc_t  = H_t / PoP_t
%   uBundle_t = cHab_t^(1-gammaH) * hpc_t^gammaH
%   chFelicity_t = uBundle_t^(1-sigmaC) / (1-sigmaC), or log(uBundle_t) if sigmaC == 1
%   laborDis_t = sum_s phiL_s * A_N_{s,t} * N_{s,t}^(1+sigmaL) / (1+sigmaL)
%   U_t = chFelicity_t - laborDis_t
%
% ds: table read from an ExcelFiles/Output/<scenario>.csv (readtable), must
%     contain C_1, H_1, PoP_1, N_<s>_1, A_N_<s>_1 for s = 1:params.nSectors.
% params: struct with fields hHabit, gammaH, sigmaC, sigmaL, phiL (1x nSectors), nSectors.
%
% Period 1 has no observed C_0 in the CSV; the lagged-consumption term is
% assumed equal to period-1 consumption itself (i.e. the run starts from a
% symmetric habit stock), so cHab_1 = C_1(1)*(1-hHabit)/PoP_1(1).

T = height(ds);
C = ds.C_1;
H = ds.H_1;
PoP = ds.PoP_1;

Clag = [C(1); C(1:end-1)];
cHab = (C - params.hHabit .* Clag) ./ PoP;
hpc = H ./ PoP;

uBundle = cHab.^(1 - params.gammaH) .* hpc.^params.gammaH;

if abs(params.sigmaC - 1) < 1e-10
    chFelicity = log(uBundle);
else
    chFelicity = uBundle.^(1 - params.sigmaC) ./ (1 - params.sigmaC);
end

laborDis = zeros(T, 1);
for s = 1:params.nSectors
    N_s = ds.(['N_' num2str(s) '_1']);
    A_N_s = ds.(['A_N_' num2str(s) '_1']);
    laborDis = laborDis + params.phiL(s) .* A_N_s .* N_s.^(1 + params.sigmaL) ./ (1 + params.sigmaL);
end

U = chFelicity - laborDis;

end
