% ================================================================
%  steadystate_model.m
%  Compute initial/terminal steady state for DGE-METRIC
% ================================================================
%  Called from: +DGE_Model/driver.m (after parameter setup)
%  Calls:      DGE_Model_steadystate, steady, check
%
%  Workspace variables used:
%    sScenario, sSensitivity, inbsectors_p, inbregions_p,
%    M_, oo_, options_
%
%  Workspace variables set:
%    ys0_, ex0_, casShareParams, casShareNParams
%    (consumed by simulation_model_refactored.m)
% ================================================================


% ----------------------------------------------------------------
% Setup
% ----------------------------------------------------------------
imaxsec_p = eval(['subend_' num2str(inbsectors_p) '_p']);
QZ_THRESHOLD = 1e-22;  % generalized eigenvalue threshold for BK check


% ----------------------------------------------------------------
% Baseline Branch: solve steady state from scratch
% ----------------------------------------------------------------
if contains(sScenario, 'Baseline')
    options_.initval_file = false;
    oo_.exo_steady_state(:) = 0;
    % Pass 1: calibrate (lCalibration_p = 1) to set phiY shares
    M_.params(ismember(M_.param_names, 'lCalibration_p')) = 1;
    [oo_.steady_state, params, ~, oo_.exo_steady_state] = ...
        DGE_Model_steadystate(oo_.steady_state, oo_.exo_steady_state, M_, options_);
    M_.params = params;
    [oo_.steady_state, params, ~, oo_.exo_steady_state] = ...
        DGE_Model_steadystate(oo_.steady_state, oo_.exo_steady_state, M_, options_);
    M_.params = params;
    steady;
    options_.qz_zero_threshold = QZ_THRESHOLD;

    % Pass 2: solve with calibration off (lCalibration_p = 0) and check BK
    M_.params(ismember(M_.param_names, 'lCalibration_p')) = 0;
    steady;
    options_.qz_zero_threshold = QZ_THRESHOLD;
    [eigenvalues_, result, info] = check(M_, options_, oo_);

    % Build list of phiY and phiN parameter names (subsector × region)
    phiY_names = arrayfun(@(y) arrayfun(@(x) ...
        ['phiY_' num2str(y) '_' num2str(x) '_p'], ...
        1:inbregions_p, 'UniformOutput', false), ...
        1:imaxsec_p, 'UniformOutput', false);
    casShareParams = [phiY_names{:}];

    phiN_names = arrayfun(@(y) arrayfun(@(x) ...
        ['phiN_' num2str(y) '_' num2str(x) '_p'], ...
        1:inbregions_p, 'UniformOutput', false), ...
        1:imaxsec_p, 'UniformOutput', false);
    casShareNParams = [phiN_names{:}];

    % Store baseline steady state as initial condition for simulations
    ys0_ = oo_.steady_state;
    ex0_ = oo_.exo_steady_state;
    % oo_.exo_steady_state(:) = 0;


% ----------------------------------------------------------------
% Scenario Branch: load previous results as initial condition
% ----------------------------------------------------------------
else
    load(['structScenarioResults' sSensitivity '.mat'], 'structScenarioResults');
    oo_.endo_simul       = structScenarioResults.(sVersion).Baseline.oo_.endo_simul;
    oo_.steady_state     = structScenarioResults.(sVersion).Baseline.oo_.steady_state;
    oo_.exo_simul        = structScenarioResults.(sVersion).Baseline.oo_.exo_simul;
    oo_.exo_steady_state = structScenarioResults.(sVersion).Baseline.oo_.exo_steady_state;
    % Restore all calibrated parameters written during the Baseline Pass 1.
    M_.params            = structScenarioResults.(sVersion).Baseline.M_.params;
    ys0_ = oo_.endo_simul(:,1);
    ex0_ = oo_.exo_simul(1,:);
    M_.params(ismember(M_.param_names, 'lEndogenousY_p')) = 1;
end
if ~exist('sScenario', 'var')
    sScenario = 'Baseline';
end
