function store_baseline_final_state(yst, exo_vec, M_, sScenario, sSensitivity)
% Reconstructs strys, strpar, strexo from Dynare structures at the final
% Baseline iteration and saves them to a .mat file.
%
% Inputs:
%   yst          - solved endogenous steady-state vector (output of DGE_Model_steadystate)
%   exo_vec      - exogenous variable vector at the terminal step (oo_.exo_simul(end,:))
%   M_           - Dynare model structure (M_.params already updated by the solver)
%   sScenario    - scenario name string, e.g. 'Baseline'
%   sSensitivity - sensitivity prefix used in output filenames (may be '')

    % ---- strpar: rebuild from current M_.params (updated by steady-state solver) ----
    strpar.Init = nan;
    strpar.casClimatevarsNational = strsplit( ...
        strrep(strrep(M_.ClimateVarsNational, '[', ''), ']', ''), ', ');
    strpar.casClimatevarsRegional = strsplit( ...
        strrep(strrep(M_.ClimateVarsRegional, '[', ''), ']', ''), ', ');
    strpar.casClimatevars = [strpar.casClimatevarsNational strpar.casClimatevarsRegional];
    for ii = 1:M_.param_nbr
        strpar.(char(M_.param_names(ii,:))) = M_.params(ii);
    end
    strpar.ssubsecfossil = num2str(strpar.iSubsecFossil_p);
    strpar.ssecenergy    = num2str(strpar.iSecEnergy_p);

    % ---- strys: rebuild from solved endogenous vector ----
    strys.Init = nan;
    for ii = 1:M_.endo_nbr
        strys.(char(M_.endo_names(ii,:))) = yst(ii);
    end

    % ---- strexo: rebuild from exogenous vector ----
    strexo.Init = nan;
    for ii = 1:M_.exo_nbr
        strexo.(char(M_.exo_names(ii,:))) = exo_vec(ii);
    end

    % ---- Save ----
    outDir  = fullfile('ExcelFiles', 'Output');
    outPath = fullfile(outDir, [sSensitivity sScenario '_baseline_final_state.mat']);
    save(outPath, 'strys', 'strpar', 'strexo');
    disp(['Baseline final state saved to ' outPath]);
end
