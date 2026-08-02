%% ==============================
%  Deterministic Simulations Setup (Refactored)
%  ==============================
%
%  Additional Shocks Configuration (Optional):
%  For Baseline scenarios, specific shocks can be ignored during baseline transition
%  and then fine-tuned afterward using values from oo_.exo_simul_start.
%
%  Before running this script, define 'AdditionalShocks' structure array:
%
%  Example:
%    AdditionalShocks = struct();
%    AdditionalShocks(1).shockIndex = posIdx.iposKGShocks(3);      % Public capital stock shock to ignore then tune
%    AdditionalShocks(1).name = 'Public capital stock (region 3)';  % Descriptive name
%    AdditionalShocks(1).fineTuneSteps = 3;                        % Incremental steps (default 1)
%
%    % Add more shocks as needed:
%    AdditionalShocks(2).shockIndex = posIdx.ipostauKFShocks(1);
%    AdditionalShocks(2).name = 'Corporate tax (region 1)';
%    AdditionalShocks(2).fineTuneSteps = 5;
%
%  Workflow:
%    1. During baseline steps: Specified shocks are set to 0 (ignored)
%    2. After baseline converges: Shocks applied from oo_.exo_simul_start incrementally
%    3. Each fine-tune step applies (i/n) fraction of original shock values
%
%  If AdditionalShocks is not defined, a default example will be used for Baseline scenarios.
%  ==============================

define_auxiliary_expressions_looped

% Derive fossil-sector export shock indices from iposExpShocks.
% exo_X_ names are ordered subsector-major, so fossil row is at
% (iSubsecFossil_p - 1)*inbregions_p + (1:inbregions_p).
iFossilSub_local = M_.params(ismember(M_.param_names, 'iSubsecFossil_p'));
posIdx.iposFossilExpShocks = posIdx.iposExpShocks( ...
    (iFossilSub_local - 1)*inbregions_p + (1:inbregions_p) );

if ~isequal(sScenario, 'Baseline')
    % Apply baseline shock structure
    if ~exist('sBaseline', 'var')
        sBaseline = 'Baseline';
    end
    
    oo_ = apply_baseline_shock_structure(oo_, structScenarioResults, sVersion, lCapandTrade_p, posIdx, sBaseline, M_);

    % Parameter adjustments
    M_ = apply_parameter_adjustments(M_, lExoNX_p, lCapandTrade_p, sScenario, lEndoMig_p);
    M_ = assign_region_subsector_params(M_, sScenario, inbregions_p, imaxsec_p);
end

%% Simulation Options and Initialization
iStep = options_.iStepSimulation;
options_.simul.maxit = 20;
if exist('iStepSimulationOverride_p', 'var') && ...
        isfinite(iStepSimulationOverride_p) && iStepSimulationOverride_p >= 1
    options_.iStepSimulation = round(iStepSimulationOverride_p);
    iStep = options_.iStepSimulation;
    disp(['[Solver options] Using candidate simulation steps: ' num2str(iStep)]);
end
if exist('iPerfectForesightMaxit_p', 'var') && ...
        isfinite(iPerfectForesightMaxit_p) && iPerfectForesightMaxit_p >= 1
    options_.simul.maxit = round(iPerfectForesightMaxit_p);
    disp(['[Solver options] Using perfect-foresight Newton maxit: ' ...
        num2str(options_.simul.maxit)]);
end
imaxTermination_p = 100;
iminTermination_p = 100;
imaxsec_p = eval(['subend_' num2str(inbsectors_p) '_p']);
options_.periods = 1000;
options_.stack_solve_algo = 0;
lBaselineBackward = exist('lBaselineBackward_p', 'var') && lBaselineBackward_p == 1;
lBaselineWarmStartLoaded = false;

if isequal(sScenario, 'Baseline')
    oo_ = perfect_foresight_setup(M_, options_, oo_);
    % Warm-start endo_simul from a reference Baseline candidate if sBaselineWarmRef is set.
    % sBaselineWarmRef must equal the sSensitivity suffix used for that reference run
    % (e.g. '' for the plain reference Baseline, '_Cand01' for the first candidate).
    % Set lBaselineWarmStart_p in RunSimulations.m before calling dynare.
    lUseBaselineWarmStart = exist('lBaselineWarmStart_p', 'var') && lBaselineWarmStart_p;
    if ~lUseBaselineWarmStart && exist('sBaselineWarmRef', 'var') && ~isempty(sBaselineWarmRef)
        lUseBaselineWarmStart = true;
    end
    if lUseBaselineWarmStart
        if ~exist('sBaselineWarmRef', 'var')
            sBaselineWarmRef = '';
        end
        refMat = ['structScenarioResults' sBaselineWarmRef '.mat'];
        if isfile(refMat)
            refData  = load(refMat, 'structScenarioResults');
            sVersionRef = ['Sectors' num2str(imaxsec_p) 'Regions' num2str(inbregions_p) sBaselineWarmRef];
            if isfield(refData.structScenarioResults, sVersionRef) && ...
               isfield(refData.structScenarioResults.(sVersionRef), 'Baseline')
                refEndo = refData.structScenarioResults.(sVersionRef).Baseline.oo_.endo_simul;
                if size(refEndo, 1) == size(oo_.endo_simul, 1)
                    T = min(size(refEndo, 2), size(oo_.endo_simul, 2));
                    oo_.endo_simul(:, 1:T) = refEndo(:, 1:T);
                    lBaselineWarmStartLoaded = true;
                    disp(['[Warm-start] Baseline endo_simul seeded from structScenarioResults' sBaselineWarmRef '.mat']);
                else
                    disp(['[Warm-start] Reference Baseline has ' num2str(size(refEndo, 1)) ...
                        ' endogenous rows but current model has ' num2str(size(oo_.endo_simul, 1)) ...
                        ' - using default initial path.']);
                end
            else
                disp(['[Warm-start] Reference Baseline not found in structScenarioResults' sBaselineWarmRef '.mat - using default initial path.']);
            end
        else
            disp(['[Warm-start] File not found: ' refMat ' - using default initial path.']);
        end
    end
end

% Load exogenous variables and growth targets
% exoup = readtable(sWorkbookScenarios, 'Sheet', sScenario);
oo_ = load_exogenous_twice(sWorkbookBaseline, sWorkbookScenarios, sScenario, oo_, M_, sBaselineSheet);
oo_.endo_simul_start = oo_.endo_simul;
oo_.exo_simul_start = oo_.exo_simul;

% Target growth rates (gY_<subsec>_<reg>) are needed both by the baseline
% homotopy loop below AND by the PDP8 I/K reconciliation just below, so this
% is computed once, up front, and reused (moved earlier than its original
% position further down in this file).
nPeriods = size(oo_.exo_simul, 1);
[iaTargetGrowthRates, iaTargetGrowthRatesN, iTermination_p] = build_target_growth_rates(...
    sWorkbookBaseline, M_, nPeriods, sBaselineSheet);

% Reshuffle initial-period investment (by activity and source), and the
% consumption/government/net-export/debt flows it implies, to match
% calibration targets. Two ways to supply targets from RunSimulations.m:
%   - set sInvestmentTargetsCsv to a GSO investment_gdp_by_ownership_and_sector.csv
%     path to build tabtargets automatically (build_investment_targets_from_gso.m).
%     Optionally also set sInvestmentTargetsIoTableXlsx (+ sInvestmentTargetsIoTableSheet)
%     to rescale those targets to the IO table's non-housing investment ratio, or
%   - define 'tabtargets' directly (see reshuffle_initial_period.m for the field convention).
% If neither is set, the reshuffle is a no-op.
if isequal(sScenario, 'Baseline') && lReshuffleInitial_p == 1
    if exist('sInvestmentTargetsCsv', 'var') && ~isempty(sInvestmentTargetsCsv)
        if ~exist('sInvestmentTargetsIoTableXlsx', 'var')
            sInvestmentTargetsIoTableXlsx = '';
        end
        if ~exist('sInvestmentTargetsIoTableSheet', 'var')
            sInvestmentTargetsIoTableSheet = '';
        end
        tabtargets = build_investment_targets_from_gso(sInvestmentTargetsCsv, M_, '1', ...
            sInvestmentTargetsIoTableXlsx, sInvestmentTargetsIoTableSheet);
    elseif ~exist('tabtargets', 'var')
        tabtargets = struct();
    end

    % Optional: reconcile fossil/renewables (subsector 2/3) investment
    % against the initial I_0/K_0 ratio solved from the FULL PDP8 horizon
    % (2025:2050) via the capital-accumulation identity, so the implied real
    % investment path reproduces PDP8's terminal/initial physical capacity
    % ratio exactly -- conditional on PDP8's own relative investment-price
    % development (CAPEX_kUSD_MW trend). K is held fixed (see
    % reshuffle_initial_period.m step 1b). deltaMaintFossil/deltaMaintRenewable
    % are read from the COMPILED model parameters (delta_2_1_p/delta_3_1_p),
    % not re-read from Excel, so this stays consistent with whatever
    % maintenance-depreciation rate is actually calibrated into M_ -- and
    % with exo_targetIY_2_1/exo_targetIY_3_1, which share the same
    % New+Maintenance numerator.
    %
    % The (s_t/s_0)*(Y_t/Y_0) term in compute_pdp8_capital_investment_ratio.m's
    % derivation is built from the ACTUAL model/Baseline data, not
    % re-derived from PDP8's own dollar figures:
    %   - s_t = exo_targetIY_2_1/exo_targetIY_3_1, read directly from
    %     oo_.exo_simul (the target path that will actually drive the muI
    %     wedge), not a re-derivation of it.
    %   - Y_t = the regional nominal-GDP path implied by the Baseline
    %     scenario's own gY_<subsec>_1 growth targets (iaTargetGrowthRates,
    %     already computed above), aggregated with INITIAL value-added
    %     shares Y_<subsec>_1(0)/Y_1(0) as weights and anchored at the
    %     model's own calibrated Y_1(0) -- not an independent PDP8 GDP
    %     assumption.
    if exist('lReshuffleIK_p', 'var') && lReshuffleIK_p == 1
        deltaFossilIK = M_.params(ismember(M_.param_names, 'delta_2_1_p'));
        deltaRenewIK  = M_.params(ismember(M_.param_names, 'delta_3_1_p'));

        yearsPDP8 = 2025:2050;
        nPDP8 = numel(yearsPDP8);

        exoNamesLocal = cellstr(M_.exo_names);
        idxFossilTargetIY = find(strcmp(exoNamesLocal, 'exo_targetIY_2_1'), 1);
        idxRenewTargetIY  = find(strcmp(exoNamesLocal, 'exo_targetIY_3_1'), 1);
        if isempty(idxFossilTargetIY) || isempty(idxRenewTargetIY)
            error('simulation_model_refactored:MissingTargetIYExo', ...
                'exo_targetIY_2_1/exo_targetIY_3_1 not found in M_.exo_names.');
        end
        sFossilPath    = oo_.exo_simul(1:nPDP8, idxFossilTargetIY)';
        sRenewablePath = oo_.exo_simul(1:nPDP8, idxRenewTargetIY)';

        endoNamesLocal = cellstr(M_.endo_names);
        idxYReg = find(strcmp(endoNamesLocal, 'Y_1'), 1);
        if isempty(idxYReg)
            error('simulation_model_refactored:MissingYReg', 'Y_1 not found in M_.endo_names.');
        end
        Y0_agg = oo_.endo_simul(idxYReg, 1);
        Y0_sub = nan(1, imaxsec_p);
        for iSubsecLocal = 1:imaxsec_p
            idxYSub = find(strcmp(endoNamesLocal, ['Y_' num2str(iSubsecLocal) '_1']), 1);
            idxPSub = find(strcmp(endoNamesLocal, ['P_' num2str(iSubsecLocal) '_1']), 1);
            if isempty(idxYSub)
                error('simulation_model_refactored:MissingYSubsec', ...
                    'Y_%d_1 not found in M_.endo_names.', iSubsecLocal);
            end
            Y0_sub(iSubsecLocal) = oo_.endo_simul(idxYSub, 1) .* oo_.endo_simul(idxPSub, 1);
        end
        subsecShares = Y0_sub / Y0_agg;

        % exo_targetIY_<stemp> is structurally 0 at the steady state
        % (investment_wedge.mod: "SS: exo_ltargetIY = 0, exo_targetIY = 0"
        % -- targeting is a dynamic-path mechanism, not meaningful at the
        % calibrated initial state), so oo_.exo_simul(1, idx) is NOT the
        % empirically observed period-1 investment/GDP ratio, just an unset
        % placeholder. Substitute the actual empirically observed ratio at
        % period 1: the model's current (pre-reshuffle) nominal
        % investment/GDP ratio for fossil/renewables -- exactly the
        % nominalOld anchor reshuffle_initial_period.m step 1b uses.
        endoName2 = @(nm) find(strcmp(endoNamesLocal, nm), 1);
        idxI2 = endoName2('I_2_1'); idxIG2 = endoName2('I_G_2_1'); idxPINV2 = endoName2('P_INV_2_1');
        idxI3 = endoName2('I_3_1'); idxIG3 = endoName2('I_G_3_1'); idxPINV3 = endoName2('P_INV_3_1');
        if isempty(idxI2) || isempty(idxIG2) || isempty(idxPINV2) || isempty(idxI3) || isempty(idxIG3) || isempty(idxPINV3)
            error('simulation_model_refactored:MissingInvestmentEndo', ...
                'I_2_1/I_G_2_1/P_INV_2_1/I_3_1/I_G_3_1/P_INV_3_1 not all found in M_.endo_names.');
        end
        sFossilPath(1) = (oo_.endo_simul(idxI2, 1) + oo_.endo_simul(idxIG2, 1)) ...
            * oo_.endo_simul(idxPINV2, 1) / Y0_agg;
        sRenewablePath(1) = (oo_.endo_simul(idxI3, 1) + oo_.endo_simul(idxIG3, 1)) ...
            * oo_.endo_simul(idxPINV3, 1) / Y0_agg;

        weightedindex = cumprod(iaTargetGrowthRates(1:nPDP8, 1:imaxsec_p)) * subsecShares';
        yPath = nan(1, nPDP8);
        yPath = Y0_agg .* weightedindex;

        % Population path (PoP_1), needed because the model's capital LOM is
        % per-capita (see compute_pdp8_capital_investment_ratio.m). Anchored
        % at the model's own calibrated PoP_1(0); for t=2..nPDP8, built from
        % exo_LF_1/exo_NLF_1 (read from oo_.exo_simul, same timing as
        % sFossilPath/yPath above) combined with the calibration parameters
        % LF0_1_p/PoP0_1_p, matching regional_identities_demographics.mod's
        % own LF_reg/PoP_reg equations.
        LF0_1_p  = M_.params(ismember(M_.param_names, 'LF0_1_p'));
        PoP0_1_p = M_.params(ismember(M_.param_names, 'PoP0_1_p'));
        lEndoMig_p_local = M_.params(ismember(M_.param_names, 'lEndoMig_p'));

        idxPoP1 = find(strcmp(endoNamesLocal, 'PoP_1'), 1);
        if isempty(idxPoP1)
            error('simulation_model_refactored:MissingPoPReg', 'PoP_1 not found in M_.endo_names.');
        end
        popPath = nan(1, nPDP8);
        popPath(1) = oo_.endo_simul(idxPoP1, 1);

        if lEndoMig_p_local == 1 && inbregions_p > 1
            % Migration is endogenous (wage-gravity) across multiple regions
            % in this case, so LF_1 cannot be approximated exogenously from
            % exo_LF_1 alone -- fall back to a flat population path (today's
            % implicit no-correction behaviour) rather than use a wrong one.
            warning('simulation_model_refactored:PopPathApproximation', ...
                ['lEndoMig_p==1 with inbregions_p>1: the exogenous LF_1 approximation used for the ' ...
                 'PDP8 I/K population correction is not valid (migration is endogenous); falling back ' ...
                 'to a flat population path.']);
            popPath(:) = popPath(1);
        else
            idxExoLF1  = find(strcmp(exoNamesLocal, 'exo_LF_1'), 1);
            idxExoNLF1 = find(strcmp(exoNamesLocal, 'exo_NLF_1'), 1);
            if isempty(idxExoLF1) || isempty(idxExoNLF1)
                error('simulation_model_refactored:MissingLFExo', 'exo_LF_1/exo_NLF_1 not found in M_.exo_names.');
            end
            for t = 2:nPDP8
                LFt = LF0_1_p * exp(oo_.exo_simul(t, idxExoLF1));
                popPath(t) = LFt + (PoP0_1_p - LF0_1_p) * exp(oo_.exo_simul(t, idxExoNLF1));
            end
        end

        % compute_pdp8_capital_investment_ratio.m now solves I_0/K_0
        % ITERATIVELY by forward-simulating the model's OWN capital-goods
        % supply-price equation (investment_adjustment.mod, lCapPrice==1)
        % period by period -- not a closed-form/exogenous-price-index
        % approximation. It needs the same inputs that equation uses:
        % K_<stemp>(1) (untouched), PINVbase (P0_<stemp>_p, matching
        % lCapGoodsSecPrice_p's active branch), etaKS_p, and the
        % exo_I_<stemp> path (held at its calibrated/baseline value
        % throughout -- the solve does NOT introduce a separate price shift
        % mechanism; P_INV emerges endogenously from the supply curve).
        lCapGoodsSecPrice_p_local = M_.params(ismember(M_.param_names, 'lCapGoodsSecPrice_p'));
        etaKS_p = M_.params(ismember(M_.param_names, 'etaKS_p'));

        idxK2 = endoName2('K_2_1');
        idxK3 = endoName2('K_3_1');
        if isempty(idxK2) || isempty(idxK3)
            error('simulation_model_refactored:MissingKSubsec', 'K_2_1/K_3_1 not found in M_.endo_names.');
        end

        if lCapGoodsSecPrice_p_local == 1
            PINVbaseFossil    = M_.params(ismember(M_.param_names, 'P0_2_1_p'));
            PINVbaseRenewable = M_.params(ismember(M_.param_names, 'P0_3_1_p'));
        else
            PINVbaseFossil    = oo_.endo_simul(endoName2('P_2_1'), 1);
            PINVbaseRenewable = oo_.endo_simul(endoName2('P_3_1'), 1);
        end

        idxExoI2 = find(strcmp(exoNamesLocal, 'exo_I_2_1'), 1);
        idxExoI3 = find(strcmp(exoNamesLocal, 'exo_I_3_1'), 1);
        if isempty(idxExoI2) || isempty(idxExoI3)
            error('simulation_model_refactored:MissingExoI', 'exo_I_2_1/exo_I_3_1 not found in M_.exo_names.');
        end

        fossilParamsIK = struct('K1', oo_.endo_simul(idxK2, 1), 'PINVbase', PINVbaseFossil, ...
            'exoIPath', oo_.exo_simul(1:nPDP8, idxExoI2)');
        renewParamsIK = struct('K1', oo_.endo_simul(idxK3, 1), 'PINVbase', PINVbaseRenewable, ...
            'exoIPath', oo_.exo_simul(1:nPDP8, idxExoI3)');

        pdp8IKRatios = compute_pdp8_capital_investment_ratio(repoRoot, deltaFossilIK, deltaRenewIK, ...
            sFossilPath, sRenewablePath, yPath, popPath, etaKS_p, fossilParamsIK, renewParamsIK, yearsPDP8);
        tabtargets.IK_2_1 = pdp8IKRatios.Fossil;
        tabtargets.IK_3_1 = pdp8IKRatios.Renewable;

        % Optional manual shortcut: user-specified multipliers for IK_2_1/IK_3_1.
        % Default behavior is unchanged unless these variables are defined.
        manualScaleIK2 = 0.72; % value coming from: pdp8IKRatios.FossilCapacityRatio / (K_2_1(25)./K_2_1(1))
        manualScaleIK3 = 0.65; % value coming from: pdp8IKRatios.RenewableCapacityRatio / (K_3_1(25)./K_3_1(1))
        if exist('manualScaleIK2_p', 'var') && isfinite(manualScaleIK2_p) && manualScaleIK2_p > 0
            manualScaleIK2 = manualScaleIK2_p;
        end
        if exist('manualScaleIK3_p', 'var') && isfinite(manualScaleIK3_p) && manualScaleIK3_p > 0
            manualScaleIK3 = manualScaleIK3_p;
        end
        if manualScaleIK2 ~= 1 || manualScaleIK3 ~= 1
            ik2Old = tabtargets.IK_2_1;
            ik3Old = tabtargets.IK_3_1;
            tabtargets.IK_2_1 = tabtargets.IK_2_1 * manualScaleIK2;
            tabtargets.IK_3_1 = tabtargets.IK_3_1 * manualScaleIK3;
            fprintf(['[simulation_model_refactored] Manual IK shortcut applied: ' ...
                'IK_2_1 %.6f -> %.6f (x%.6f), IK_3_1 %.6f -> %.6f (x%.6f)\n'], ...
                ik2Old, tabtargets.IK_2_1, manualScaleIK2, ...
                ik3Old, tabtargets.IK_3_1, manualScaleIK3);
        end

        % PINVIndex is now the P_INV(t)/P_INV(1) path implied by the model's
        % OWN supply-curve equation (a byproduct of the forward simulation
        % above), not PDP8's CAPEX_kUSD_MW trend -- see
        % reshuffle_initial_period.m step 1b for how it's applied.
        tabtargets.PINVIndex_2_1 = pdp8IKRatios.FossilPriceIndex;
        tabtargets.PINVIndex_3_1 = pdp8IKRatios.RenewablePriceIndex;
        fprintf(['[simulation_model_refactored] PDP8 I0/K0 targets (years %s): fossil=%.4f ' ...
            '(K_T/K_0 target=%.3f, realized=%.3f) renewable=%.4f (K_T/K_0 target=%.3f, realized=%.3f) ' ...
            'popRatio=%.3f\n'], ...
            mat2str(pdp8IKRatios.Years([1 end])), pdp8IKRatios.Fossil, pdp8IKRatios.FossilCapacityRatio, ...
            pdp8IKRatios.FossilRealizedRatio, pdp8IKRatios.Renewable, pdp8IKRatios.RenewableCapacityRatio, ...
            pdp8IKRatios.RenewableRealizedRatio, popPath(end) / popPath(1));
    end

    oo_ = reshuffle_initial_period(oo_, M_, posIdx, inbregions_p, imaxsec_p, tabtargets);
    oo_.endo_simul_start(:, 1) = oo_.endo_simul(:, 1);
    % reshuffle_initial_period.m's step 1b shifts exo_I_<subsec>_<reg> (the
    % posIdx.iposProdIShocks group) across the whole oo_.exo_simul path, but
    % oo_.exo_simul_start was captured above BEFORE the reshuffle ran. Every
    % homotopy step in apply_baseline_step_shocks() below re-derives
    % oo_.exo_simul(:, posIdx.iposProdIShocks) from that stale
    % oo_.exo_simul_start (scaled by stepFrac), which would silently revert
    % the reshuffle's price-level shift -- including on the final step,
    % where stepFrac==1 reproduces the stale value exactly. Re-sync it here
    % so the shift survives the homotopy loop and reaches the terminal
    % steady state.
    oo_.exo_simul_start(:, posIdx.iposProdIShocks) = oo_.exo_simul(:, posIdx.iposProdIShocks);
end

% Baseline: activate endogenous wedge targeting (exo_ltargetIY = 1 during transition).
% (nPeriods/iaTargetGrowthRates/iaTargetGrowthRatesN/iTermination_p are
% computed earlier, right after oo_.exo_simul_start is captured, since the
% PDP8 I/K reconciliation above also needs iaTargetGrowthRates.)

exo_temp = zeros(size(oo_.exo_simul));

%% =================================
%  Run Deterministic Simulations
%  =================================

if isequal(sScenario, 'Baseline')
    % Step-wise simulation to match target GDP growth
    scaleVars = [posIdx.iposQIShock, posIdx.iposPriceHShock, posIdx.iposrfShock, posIdx.iposadjBShock, ...
                 posIdx.iposBShock, posIdx.iposPopShocks, posIdx.iposLFShocks, posIdx.iposPERegShocks, posIdx.iposNXShock];

    if lBaselineBackward
        % Precompute forward steady states for all steps
        oo_base = oo_;
        iStepSteady = 2;
        steadyStates = zeros(size(oo_.endo_simul, 1), iStepSteady);
        exo_steadyStates = zeros(iStepSteady, size(oo_.exo_simul, 2));
        icostep = 0;
        
        while icostep < iStepSteady
            icostep = icostep + 1;
            disp(['=== Precompute Step ' num2str(icostep) ' of ' num2str(iStepSteady) ' for ' sScenario ' ==='])

            M_.params(ismember(M_.param_names, 'lCalibration_p')) = 2;
            options_.iStepSteadyState = 1;

            stepFrac = compute_step_fraction(icostep, iStepSteady, false);
            oo_ = apply_baseline_step_shocks(oo_, iaTargetGrowthRates, iaTargetGrowthRatesN, ...
                stepFrac, lCapandTrade_p, posIdx);

            if lEndogenousN_p == 1
                oo_.exo_simul(:, posIdx.iposProdShocksN) = 0;
            end
            [yst, ~, ~, ~] = DGE_Model_steadystate(oo_.endo_simul(:, end), oo_.exo_simul(end,:), M_, options_);
            if icostep == iStepSteady
                options_.qz_zero_threshold = 1e-22;
                [eigenvalues_, result, info] = check(M_, options_, oo_);
            end
            steadyStates(:, icostep) = yst;
            oo_.exo_steady_state = oo_.exo_simul(end,:)';
            exo_steadyStates(icostep,:) = oo_.exo_simul(end,:);
            oo_.endo_simul(:, end) = yst;
        end

        % Restore baseline paths before backward simulation
        % oo_ = oo_base;

        % Backward simulation: terminal SS to first SS with step-ahead initial conditions
        
        yst = steadyStates(:, iStepSteady);
        oo_.exo_steady_state = oo_.exo_simul(end, :)';
        oo_.endo_simul(:, 1:end) = repmat(yst, 1, size(oo_.endo_simul, 2));%yst;%repmat(yst, 1, 1size(oo_.endo_simul, 2) - 1);
        oo_.exo_simul_start = oo_.exo_simul;
        oo_.exo_simul_final = repmat(oo_.exo_steady_state', size(oo_.exo_simul_start,1),1);
        icostep = 0;
        yst_next = yst;
        while icostep < iStep
            icostep = icostep + 1;
            disp(['=== Step ' num2str(icostep) ' of ' num2str(iStep) ' for ' sScenario ' (backward) ==='])

            M_.params(ismember(M_.param_names, 'lCalibration_p')) = 2;
            options_.iStepSteadyState = 1;

            stepFrac = 1;%compute_step_fraction(icostep, iStep, true);
            iTime = size(oo_.exo_simul(1:100,:),1);
            oo_.exo_simul = icostep / iStep .* oo_.exo_simul_start + (1-icostep / iStep).*oo_.exo_simul_final;
            if icostep < iStep
                [yst_next, ~, ~, ~] = DGE_Model_steadystate(yst_next, oo_.exo_simul(1,:), M_, options_);
            else
                yst_next = oo_.endo_simul_start(:,1);
            end

            if lEndogenousN_p == 1
                oo_.exo_simul(:, posIdx.iposProdShocksN) = 0;
            end

            if icostep ==1
                oo_.endo_simul(:, 1:100) = repmat(yst_next, 1, 100);
            else
                oo_.endo_simul(:, 1) = repmat(yst_next, 1, 1);
            end
            if ~lSteadyState
                tic;
                oo_ = perfect_foresight_solver(M_, options_, oo_);
                toc;
            end
        end
    else
        icostep = 0;
        % AdditionalShocks = struct();
        % AdditionalShocks(1).shockIndex = posIdx.iposKGShocks;
        % AdditionalShocks(1).name = 'Public capital stock';
        % AdditionalShocks(1).fineTuneSteps = 0;  % Number of incremental fine-tuning steps
        while icostep < iStep
            icostep = icostep+1;
            disp(['=== Step ' num2str(icostep) ' of ' num2str(iStep) ' for ' sScenario ' ==='])

            M_.params(ismember(M_.param_names, 'lCalibration_p')) = 2;
            options_.iStepSteadyState = 1;

            stepFrac = compute_step_fraction(icostep, iStep, false);
            oo_ = apply_baseline_step_shocks(oo_, iaTargetGrowthRates, iaTargetGrowthRatesN, ...
                stepFrac, scaleVars, posIdx);
            
            % Ignore specified additional shocks during baseline transition
            if exist('AdditionalShocks', 'var') && ~isempty(AdditionalShocks)
                for iShock = 1:length(AdditionalShocks)
                    oo_.exo_simul(:, AdditionalShocks(iShock).shockIndex) = 0;
                end
            end
            
            if lEndogenousN_p == 1
                oo_.exo_simul(:, posIdx.iposProdShocksN) = 0;
            end

            % Steady-state computation
            [yst, ~, ~, exo] = DGE_Model_steadystate(oo_.endo_simul(:, end), oo_.exo_simul(end,:), M_, options_);

            % Validate static residuals of the current candidate and retry once if needed.
            exoCandidate = oo_.exo_simul(end, :)';
            staticRes = DGE_Model.static_resid(yst, exoCandidate, M_.params);
            absStaticRes = abs(staticRes);
            absStaticRes(~isfinite(absStaticRes)) = -Inf;
            [maxStaticRes, maxResEq] = max(absStaticRes);
            if isempty(staticRes) || ~isfinite(maxStaticRes) || maxStaticRes < 0
                maxStaticRes = Inf;
                maxResEq = NaN;
            end

            staticTol = 1e-6;
            if ~isfinite(maxStaticRes) || maxStaticRes > staticTol
                eqLabel = get_static_eq_label(M_, maxResEq);
                disp(['Static residual check failed (eq ' num2str(maxResEq) ' - ' eqLabel ', max abs resid = ' num2str(maxStaticRes, '%.3e') '). Retrying DGE_Model_steadystate once...']);
                [yst, ~, ~, exo] = DGE_Model_steadystate(yst, oo_.exo_simul(end,:), M_, options_);
            end
            
            if icostep == 1 && lBaselineWarmStartLoaded
                oo_.endo_simul(:, end) = yst;
                disp('[Warm-start] Preserving seeded Baseline path for first candidate solve.');
            elseif icostep == 1
                oo_.endo_simul(:, 2:end) = repmat(yst, 1, size(oo_.endo_simul, 2) - 1);
            else
                oo_.endo_simul(:, end) = yst;
            end
            oo_.steady_state = oo_.endo_simul(:, end);

            exoSteady = oo_.exo_simul(end,:);
            oo_.exo_steady_state = exoSteady';
            steady;
            if icostep == iStep
                options_.qz_zero_threshold = 1e-22;
                [eigenvalues_, result, info] = check(M_, options_, oo_);
            end
            
            if ~lSteadyState
                tic;
                oo_ = perfect_foresight_solver(M_, options_, oo_);
                toc;
            end
        end
        
        % === Apply additional fine-tuning shocks after baseline transition path ===
        % Shocks that were ignored during baseline are now applied from oo_.exo_simul_start
        if exist('AdditionalShocks', 'var') && ~isempty(AdditionalShocks)
            oo_ = apply_additional_shocks_from_start(oo_, AdditionalShocks, lSteadyState, M_, options_);
        end
    end

else
    % Climate scenarios: apply damage shocks
    icostep = 0;
    % lLongHorizonWarmStart_p = 1;
    while icostep < iStep
        icostep = icostep+1;
        disp(['=== Step ' num2str(icostep) ' of ' num2str(iStep) ' for ' sScenario ' ==='])


        oo_ = apply_climate_step_shocks(oo_, icostep, iStep, lCapandTrade_p, posIdx, sBaseline, sScenario);
       
        % Solve for steady state
        [yst, ~, ~, exoSteady] = DGE_Model_steadystate(oo_.endo_simul(:, end), oo_.exo_simul(end,:), M_, options_);
        oo_.steady_state = yst;
        oo_.endo_simul(:, end) = repmat(yst, 1, size(oo_.endo_simul(:, end), 2));
        oo_.exo_steady_state = oo_.exo_simul(end,:)';
        steady;
        if icostep == -1 || icostep == iStep
            options_.qz_zero_threshold = 1e-22;
            [eigenvalues_, result, info] = check(M_, options_, oo_);
        end
        if ~lSteadyState
            tic;
            oo_ = perfect_foresight_solver(M_, options_, oo_);
            toc;
        end
        if exist('lLongHorizonWarmStart_p','var') && lLongHorizonWarmStart_p == 1
        
            % horizons
            Torig = options_.periods;
            Tlong = 4000;
        
            % solver options (store originals so we can restore)
            stack_algo_orig  = options_.stack_solve_algo;
            debug_orig       = options_.debug;
            no_homotopy_orig = options_.no_homotopy;
        
            options_.stack_solve_algo = 0;
            options_.debug = 0;
            options_.no_homotopy = 0;
        
            % Save current paths as warm start
            endo_short = oo_.endo_simul;
            exo_short  = oo_.exo_simul;
        
            % ===== long horizon (warm start) =====
            options_.periods = Tlong;
            oo_ = perfect_foresight_setup(M_, options_, oo_);
            oo_ = set_pf_paths_after_setup(oo_, M_, options_, exo_short, endo_short, ...
                "pad_exo_last", "pad_endo_last");
            oo_ = perfect_foresight_solver(M_, options_, oo_);
        
            % Store long-horizon results
            endo_long = oo_.endo_simul;
            exo_long  = oo_.exo_simul;
        
            % ===== resize back to original horizon =====
            options_.periods = Torig;
            oo_ = perfect_foresight_setup(M_, options_, oo_);
            oo_ = copy_pf_prefix_after_setup(oo_, endo_long, exo_long);
        
            % Restore solver options
            options_.stack_solve_algo = stack_algo_orig;
            options_.debug            = debug_orig;
            options_.no_homotopy      = no_homotopy_orig;
        
        end


    end
end    

%% =================================
%  Export Results
%  =================================
M_.params(ismember(M_.param_names, 'lCalibration_p')) = 0;
if ~lSteadyState
    perfect_foresight_solver(M_, options_, oo_);
end
dyn2vec(M_, oo_, options_);

% Output to Excel or CSV
iDisplay = 100;
iFrequency = 1;
iStartYear = 2025;

if isoctave()
    caResults = [cellstr(M_.endo_names)'; mat2cell(oo_.endo_simul(:,1:iFrequency:iDisplay)', ...
        ones(iDisplay,1), ones(M_.endo_nbr,1))];
    caYear = cellstr(['Year'; num2str((iStartYear + (1:iFrequency:iDisplay))')]);
    caExcelFile = [caYear caResults];
    sAddress = [FindExcelCell(M_.endo_nbr) num2str(iDisplay+1)];
    xlswrite(sWorkbookNameOutput, caExcelFile, sScenario, ['A1:' sAddress]);eta
else
    iaYear_vec = iStartYear + ((0:(size(oo_.endo_simul(:,1:iDisplay)',1)-1))./iFrequency)';
    tabvars = array2table([iaYear_vec oo_.endo_simul(:,1:iDisplay)']);
    tabvars.Properties.VariableNames = [{'Year'}; cellstr(M_.endo_names)];

    outputDir = fullfile('ExcelFiles', 'Output');
    outputSubfolderEnv = strtrim(getenv('DGE_OUTPUT_SUBFOLDER'));
    if ~isempty(outputSubfolderEnv)
        outputDir = fullfile(outputDir, outputSubfolderEnv);
    elseif exist('sOutputSubfolder', 'var') && ~isempty(sOutputSubfolder)
        outputDir = fullfile(outputDir, sOutputSubfolder);
    end
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    outputPath = fullfile(outputDir, sScenario);
    if ~contains(sScenario, '.csv')
        outputPath = fullfile(outputDir, [sScenario sSensitivity '.csv']);
    end
    writetable(tabvars, outputPath);
end

%% ==============================
%  Local helper functions
%  ==============================

function oo_ = apply_baseline_shock_structure(oo_, structScenarioResults,...
               sVersion, lCapandTrade_p, posIdx, sBaseline, M_)

    % Build baseline-aligned exogenous shocks and base paths.

    scenarioExo = oo_.exo_simul;
    baselineSim = structScenarioResults.(sVersion).(sBaseline).oo_.endo_simul;
    if isequal(sBaseline, 'Baseline')
        oo_.exo_simul(:, posIdx.iposProdShocks)  = log(baselineSim(posIdx.iposAVars,:) ./ baselineSim(posIdx.iposAVars,1))';
        oo_.exo_simul(:, posIdx.iposProdShocksN) = log(baselineSim(posIdx.iposANVars,:))';
        
        oo_.exo_simul(:, posIdx.iposadjBShock)   = baselineSim(posIdx.iposadjB,:)';
        oo_.exo_simul(:, posIdx.iposdeltaBShock) = baselineSim(posIdx.iposdeltaB,:)';
        oo_.exo_simul(:, posIdx.iposPriceHShock) = log(baselineSim(posIdx.iposPH,:) ./ baselineSim(posIdx.iposPH,1))';
        oo_.exo_simul(:, posIdx.iposkapEShock) = (baselineSim(posIdx.iposkappaE,:) - baselineSim(posIdx.iposkappaE,1))';
        oo_.exo_simul(:, posIdx.iposkapENOETSShock) = (baselineSim(posIdx.iposkappaENOETS,:) - baselineSim(posIdx.iposkappaENOETS,1))';
    
        oo_.exo_simul(:, posIdx.iposProdShocksN) = log(baselineSim(posIdx.iposANVars,:))';
        oo_.exo_simul(:, posIdx.iposAIShock)     = log(baselineSim(posIdx.iposAIVars,:))';
        oo_.exo_simul(:, posIdx.iposADShock)     = log(baselineSim(posIdx.iposADVars,:))';
        oo_.exo_base = structScenarioResults.(sVersion).(sBaseline).oo_.exo_simul;

        oo_.exo_base(:, posIdx.iposEERegShocks) = log(baselineSim(posIdx.iposEEReg,:)./baselineSim(posIdx.iposEEReg,1))';
        oo_.exo_simul(:, posIdx.iposEERegShocks) = oo_.exo_base(:, posIdx.iposEERegShocks);
        oo_.exo_simul(:, posIdx.iposPKShocks)  = log(baselineSim(posIdx.iposPKVars,:)./baselineSim(posIdx.iposPVars,:))';

        % Transfer baseline wedge path to exo_wedge for scenarios
        % Wedge is an additive term in exp(), so copy values directly (not log-ratio)
        if ~isempty(posIdx.iposWedgeVars) && ~isempty(posIdx.iposWedgeShocks)
            oo_.exo_simul(:, posIdx.iposWedgeShocks) = baselineSim(posIdx.iposWedgeVars, :)';
        end

        % Transfer baseline muI path to exo_muI and disable I/Y targeting for scenarios.
        % In Baseline muI is endogenous (exo_ltargetIY=1); outside Baseline it must be
        % exogenous (exo_ltargetIY=0) using the path muI solved during the Baseline run.
        if ~isempty(posIdx.iposMuIVars) && ~isempty(posIdx.iposMuIShocks)
            oo_.exo_simul(:, posIdx.iposMuIShocks) = baselineSim(posIdx.iposMuIVars, :)';
        end
        if isfield(posIdx, 'iposLMAmountShocks') && ~isempty(posIdx.iposLMAmountShocks)
            oo_.exo_simul(:, posIdx.iposLMAmountShocks) = scenarioExo(:, posIdx.iposLMAmountShocks);
        end
        if isfield(posIdx, 'iposMAmountShocks') && ~isempty(posIdx.iposMAmountShocks)
            oo_.exo_simul(:, posIdx.iposMAmountShocks) = scenarioExo(:, posIdx.iposMAmountShocks);
        end
        if ~isempty(posIdx.iposLTargetIYShocks)
            oo_.exo_simul(:, posIdx.iposLTargetIYShocks) = 0;
        end
        if ~isempty(posIdx.iposTargetIYShocks)
            oo_.exo_simul(:, posIdx.iposTargetIYShocks) = 0;
        end

        % Transfer baseline tauCEndo path to exo_tauC for scenarios. tauCEndo mirrors
        % EE_reg: no runtime switch to force off (the Baseline-vs-scenario branch is a
        % compile-time macro, BaselineScenario, in government.mod). exo_tauC carries the
        % baseline-required path; exo_tauCScen remains free for scenario-specific
        % additional tauC shocks layered on top (see government.mod).
        if ~isempty(posIdx.iposTauCEndoVars) && ~isempty(posIdx.iposTauCShocks) && ~isempty(posIdx.iposTauCParams)
            tauCParamVals = M_.params(posIdx.iposTauCParams);
            oo_.exo_simul(:, posIdx.iposTauCShocks) = (baselineSim(posIdx.iposTauCEndoVars, :) - tauCParamVals)';
        end

        % Transfer baseline s_reg path to exo_s and disable NX targeting for scenarios.
        % In Baseline s_reg is endogenous (exo_lNXTarget=1, solved so net exports hit
        % NX0_p/Y0_p+exo_NX); outside Baseline it must follow its own AR(1)
        %   s(t) = rhos_p*s(t-1) + (1-rhos_p)*s0_p*exp(exo_s(t))
        % so exo_s is back-solved to make that AR(1) reproduce the exact s_reg path
        % solved during the Baseline run.
        if ~isempty(posIdx.iposSVars) && ~isempty(posIdx.iposFXShock)
            sTarget = baselineSim(posIdx.iposSVars, :);
            sLag = [sTarget(:,1), sTarget(:,1:end-1)];
            s0Vals = M_.params(posIdx.iposS0Params);
            rhos_p_val = M_.params(ismember(M_.param_names, 'rhos_p'));
            oo_.exo_simul(:, posIdx.iposFXShock) = ...
                log((sTarget - rhos_p_val .* sLag) ./ ((1 - rhos_p_val) .* s0Vals))';
        end
        if ~isempty(posIdx.iposLNXTargetShocks)
            oo_.exo_simul(:, posIdx.iposLNXTargetShocks) = 0;
        end

        if lCapandTrade_p == 1
            % oo_.exo_base(:, posIdx.iposERegShocks) = log(baselineSim(posIdx.iposEETSReg,:)./baselineSim(posIdx.iposEETSReg,1))';
            oo_.exo_base(:, posIdx.iposERegShocks) = log(baselineSim(posIdx.iposEReg,:)./baselineSim(posIdx.iposEReg,1))';
            oo_.exo_simul(:, posIdx.iposERegShocks) = oo_.exo_base(:, posIdx.iposERegShocks);
        end
        oo_.exo_base(:, posIdx.iposkapEShock) = (baselineSim(posIdx.iposkappaE,:)-baselineSim(posIdx.iposkappaE,1))';
        oo_.exo_simul(:, posIdx.iposkapEShock) = oo_.exo_base(:, posIdx.iposkapEShock);
    else
        oo_.exo_base = structScenarioResults.(sVersion).(sBaseline).oo_.exo_simul;
        oo_.exo_simul = structScenarioResults.(sVersion).(sBaseline).oo_.exo_simul;
        oo_.endo_simul = structScenarioResults.(sVersion).(sBaseline).oo_.endo_simul;        
    end
end

function M_ = apply_parameter_adjustments(M_, lExoNX_p, lCapandTrade_p, sScenario, lEndoMig_p)
    % Apply scenario-level parameter switches.
    M_.params(ismember(M_.param_names, 'lCalibration_p')) = 0;
    M_.params(ismember(M_.param_names, 'lExoNX_p')) = lExoNX_p;
    M_.params(ismember(M_.param_names, 'lCapandTrade_p')) = lCapandTrade_p;

    if isequal(sScenario, 'BAU')
        M_.params(ismember(M_.param_names, 'lEndoMig_p')) = 0;
    end
end

function M_ = assign_region_subsector_params(M_, sScenario, inbregions_p, imaxsec_p)
    % Assign regional and subsectoral parameter flags.
    for icoreg = 1:inbregions_p
        for icosubsec = 1:imaxsec_p
            paramQ = ['lEndoQ_' num2str(icosubsec) '_' num2str(icoreg) '_p'];
            paramN = ['lEndoN_' num2str(icosubsec) '_' num2str(icoreg) '_p'];

            if contains(sScenario, 'EndoRen')
                M_.params(ismember(M_.param_names, paramQ)) = 1;
            else
                M_.params(ismember(M_.param_names, paramQ)) = evalin('base', paramQ);
            end
            M_.params(ismember(M_.param_names, paramN)) = evalin('base', paramN);
        end
    end
end

function oo_ = load_exogenous_twice(sWorkbookBaseline, sWorkbookScenarios, sScenario, oo_, M_, sBaselineSheet)
    % Maintain original double-load behavior for exogenous inputs.
    if nargin < 6, sBaselineSheet = 'Baseline'; end
    oo_ = load_exogenous(sWorkbookBaseline, sWorkbookScenarios, sScenario, oo_, M_, sBaselineSheet);
    oo_ = load_exogenous(sWorkbookBaseline, sWorkbookScenarios, sScenario, oo_, M_, sBaselineSheet);
end

function [iaTargetGrowthRates, iaTargetGrowthRatesN, iTermination_p] = build_target_growth_rates(...
    sWorkbookBaseline, M_, nPeriods, sBaselineSheet)

    % Construct target growth paths for baseline scaling.
    if nargin < 4, sBaselineSheet = 'Baseline'; end
    [iaGrowthRates, iaGrowthRatesN] = load_growth_rates(sWorkbookBaseline, M_, sBaselineSheet);
    iaTargetGrowthRates = [ones(1, size(iaGrowthRates', 2)); iaGrowthRates'; ones(nPeriods - size(iaGrowthRates', 1) - 1, size(iaGrowthRates', 2))];
    iaTargetGrowthRatesN = [ones(1, size(iaGrowthRatesN', 2)); iaGrowthRatesN'; ones(nPeriods - size(iaGrowthRatesN', 1) - 1, size(iaGrowthRatesN', 2))];
    iTermination_p = size(iaGrowthRates, 2);
end

function oo_ = apply_baseline_step_shocks(oo_, iaTargetGrowthRates, iaTargetGrowthRatesN, ...
    stepFrac, scaleVars, posIdx)

    % Apply stepwise baseline shocks and scale exogenous paths.

    % Apply stepwise growth shocks
    oo_.exo_simul(:, posIdx.iposProdShocks)  = log(cumprod(iaTargetGrowthRates .^ stepFrac, 1));
    oo_.exo_simul(:, posIdx.iposProdShocksN) = log(cumprod(iaTargetGrowthRatesN .^ stepFrac, 1));
    oo_.exo_simul(:, posIdx.iposAIShock)     = oo_.exo_simul_start(:, posIdx.iposAIShock) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposKTarShocks)     = oo_.exo_simul_start(:, posIdx.iposKTarShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposKTarBShocks)     = oo_.exo_simul_start(:, posIdx.iposKTarBShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposTargetIYShocks)     = oo_.exo_simul_start(:, posIdx.iposTargetIYShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposQShocks)          = oo_.exo_simul_start(:, posIdx.iposQShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposFossilExpShocks)  = oo_.exo_simul_start(:, posIdx.iposFossilExpShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposProdIShocks)     = oo_.exo_simul_start(:, posIdx.iposProdIShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposKGShocks)     = oo_.exo_simul_start(:, posIdx.iposKGShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposrGShocks)  = oo_.exo_simul_start(:, posIdx.iposrGShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposGAShocks)     = oo_.exo_simul_start(:, posIdx.iposGAShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposphiGShocks)   = oo_.exo_simul_start(:, posIdx.iposphiGShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposPVShocks)  = oo_.exo_simul_start(:, posIdx.iposPVShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposPVEffShocks)  = oo_.exo_simul_start(:, posIdx.iposPVEffShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposPKShocks)  = oo_.exo_simul_start(:, posIdx.iposPKShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.ipossGScenShocks)  = oo_.exo_simul_start(:, posIdx.ipossGScenShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposDamKShocks)  = oo_.exo_simul_start(:, posIdx.iposDamKShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposADShock)     = oo_.exo_simul_start(:, posIdx.iposADShock) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposIFDIShocks)  = oo_.exo_simul_start(:, posIdx.iposIFDIShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.ipossFDIShareShocks) = oo_.exo_simul_start(:, posIdx.ipossFDIShareShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposrFDIShocks) = oo_.exo_simul_start(:, posIdx.iposrFDIShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposEmShocks)     = oo_.exo_simul_start(:, posIdx.iposEmShocks) .* stepFrac;
    % oo_ = copy_exo_from_start(oo_, posIdx.iposAIShocksec);
    oo_.exo_simul(:, posIdx.iposAIShocksec)  = oo_.exo_simul_start(:, posIdx.iposAIShocksec) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposEERegShocks) = oo_.exo_simul_start(:, posIdx.iposEERegShocks) .* stepFrac;
    if any(posIdx.iposREShocks ~=0)
        oo_.exo_simul(:, posIdx.iposREShocks) = oo_.exo_simul_start(:, posIdx.iposREShocks) .* (icostep / iStep);
    end

    oo_ = scale_exo_from_start(oo_, scaleVars, stepFrac);

    oo_ = copy_exo_from_start(oo_, posIdx.iposEBaseRegShocks);
    oo_.exo_simul(:, posIdx.iposERegShocks) = oo_.exo_simul_start(:, posIdx.iposERegShocks) .* stepFrac;
end

function oo_ = apply_climate_step_shocks(oo_, icostep, iStep, lCapandTrade_p, posIdx, sBaseline, sScenario)

    % Apply stepwise climate shocks and base-to-scenario transitions.
    stepFrac = icostep / iStep;
    % Apply climate shock scaling
    if isequal(sBaseline, 'Baseline')
        climateVars = [posIdx.iposDamShocks, posIdx.iposDamKShocks, posIdx.iposDamNShocks, posIdx.iposDamHShock, ...
                       posIdx.iposPriceShock, posIdx.iposQShocks, posIdx.iposEmiShocks, ...
                       posIdx.iposExpShocks, posIdx.iposTauSShocks, posIdx.iposTauSTrShocks];
    

        oo_ = scale_exo_from_start(oo_, climateVars, stepFrac);
    
        oo_ = copy_exo_from_start(oo_, [posIdx.iposProdShocksN, posIdx.iposAIShocksec, posIdx.iposPopShocks, ...
            posIdx.iposLFShocks, posIdx.iposNXShock, ...
            posIdx.iposMuIShocks, posIdx.iposLTargetIYShocks, posIdx.iposTargetIYShocks]);
    
        oo_.exo_simul(:, posIdx.ipostauKFShocks)     = oo_.exo_simul_start(:, posIdx.ipostauKFShocks) .* stepFrac;
        oo_.exo_simul(:, posIdx.iposQShocks)   = oo_.exo_simul_start(:, posIdx.iposQShocks) * stepFrac;
        oo_.exo_simul(:, posIdx.iposTauSTrShocks)   = oo_.exo_simul_start(:, posIdx.iposTauSTrShocks) * stepFrac;
        oo_.exo_simul(:, posIdx.iposphiKShocks)  = oo_.exo_simul_start(:, posIdx.iposphiKShocks) .* stepFrac;
        oo_.exo_simul(:, posIdx.iposrGShocks)  = oo_.exo_simul_start(:, posIdx.iposrGShocks) .* stepFrac;
        oo_.exo_simul(:, posIdx.iposAFShock)     = oo_.exo_simul_start(:, posIdx.iposAFShock) .* stepFrac;
        if lCapandTrade_p == 1
            oo_.exo_simul(:, posIdx.iposERegShocks) = oo_.exo_base(:, posIdx.iposERegShocks).*(1 - stepFrac.^2) + ...
                                                      oo_.exo_simul_start(:, posIdx.iposERegShocks).*stepFrac.^2;
        else
            oo_.exo_simul(:, posIdx.iposPERegShocks) = oo_.exo_base(:, posIdx.iposPERegShocks).*(1 - stepFrac) + ...
                                                       oo_.exo_simul_start(:, posIdx.iposPERegShocks).*stepFrac;
        end
    end
    baseVars = [posIdx.iposPERegShocks,posIdx.iposkapEShock, posIdx.iposEERegShocks,...
            posIdx.iposUShocks, posIdx.iposPVShocks, posIdx.ipossGShocks, posIdx.iposKGShocks, posIdx.iposrGShocks ,...
            posIdx.iposphiKShocks, posIdx.iposTauSShocks, posIdx.iposkapEShock, posIdx.iposPKShocks, posIdx.iposGAShocks,...
            posIdx.iposLFDIShareShocks,posIdx.iposLIGShareShocks,posIdx.iposIFDIShocks,posIdx.iposWedgeShocks,posIdx.iposFossilExpShocks,...
            posIdx.iposENOETSShocks];
    
    oo_ = scale_exo_from_base(oo_,baseVars , stepFrac);
end

function oo_ = scale_exo_from_start(oo_, varList, stepFrac)
    % Linearly scale exogenous series from zero to start values.
    for var = varList
        oo_.exo_simul(:, var) = oo_.exo_simul_start(:, var) * stepFrac;
    end
end

function oo_ = scale_exo_from_base(oo_, varList, stepFrac)
    % Linearly transition exogenous series from base to scenario paths.
    for var = varList
        oo_.exo_simul(:, var) = oo_.exo_base(:, var) + ...
            (oo_.exo_simul_start(:, var) - oo_.exo_base(:, var)) * stepFrac;
    end
end

function oo_ = copy_exo_from_start(oo_, varList)
    % Copy exogenous series directly from the starting paths.
    for var = varList
        oo_.exo_simul(:, var) = oo_.exo_simul_start(:, var);
    end
end

function stepFrac = compute_step_fraction(icostep, iStep, lBackward)
    % Compute step fraction for forward or backward baseline scaling.
    if iStep <= 1
        stepFrac = 1;
        return
    end
    if lBackward
        stepFrac = (iStep - icostep) / (iStep - 1);
    else
        stepFrac = icostep / iStep;
    end
end

function oo_ = apply_additional_shocks_from_start(oo_, AdditionalShocks, lSteadyState, M_, options_)
    % Apply additional shocks from oo_.exo_simul_start with incremental fine-tuning
    % 
    % These shocks were set to 0 during baseline transition and are now applied
    % incrementally using their values from oo_.exo_simul_start.
    %
    % Inputs:
    %   oo_               - Dynare output structure (must have oo_.exo_simul_start)
    %   AdditionalShocks  - Array of shock specifications with fields:
    %                       .shockIndex     - Column index in oo_.exo_simul (from posIdx)
    %                       .name           - Descriptive name for display
    %                       .fineTuneSteps  - Number of incremental steps (default 1)
    %   lSteadyState      - Logical flag for steady state mode
    %   M_, options_      - Dynare structures
    %
    % Output:
    %   oo_               - Updated Dynare output structure
    
    % Validate oo_.exo_simul_start exists
    if ~isfield(oo_, 'exo_simul_start') || isempty(oo_.exo_simul_start)
        error('oo_.exo_simul_start not found. Cannot apply additional shocks.');
    end
    
    nShocks = length(AdditionalShocks);
    disp(' ');
    disp('========================================================');
    disp('=== Applying Additional Shocks from exo_simul_start ===');
    disp('========================================================');
    
    for iShock = 1:nShocks
        shock = AdditionalShocks(iShock);
        
        % Set default fine-tuning steps if not specified
        if ~isfield(shock, 'fineTuneSteps') || isempty(shock.fineTuneSteps)
            shock.fineTuneSteps = 1;
        end
        
        % Get original shock values from exo_simul_start
        originalShockValues = oo_.exo_simul_start(:, shock.shockIndex);
        
        % Check if shock has non-zero values to apply
        if all(originalShockValues == 0)
            warning('AdditionalShocks(%d) "%s": All values in exo_simul_start are zero. Skipping.', ...
                    iShock, shock.name);
            continue;
        end
        
        disp(' ');
        disp(['--- Shock ' num2str(iShock) ' of ' num2str(nShocks) ': ' shock.name ' ---']);
        disp(['    Shock index: ' num2str(shock.shockIndex)]);
        disp(['    Fine-tuning steps: ' num2str(shock.fineTuneSteps)]);
        disp(['    Non-zero periods in exo_simul_start: ' num2str(sum(originalShockValues ~= 0))]);
        
        % Apply shock incrementally with fine-tuning loop
        for iTune = 1:shock.fineTuneSteps
            tuneFrac = iTune / shock.fineTuneSteps;
            
            if shock.fineTuneSteps > 1
                disp(['    Fine-tuning step ' num2str(iTune) ' of ' num2str(shock.fineTuneSteps) ...
                      ' (applying ' num2str(tuneFrac*100, '%.1f') '% of original shock)']);
            end
            
            % Apply fraction of original shock values from exo_simul_start
            oo_.exo_simul(:, shock.shockIndex) = originalShockValues * tuneFrac;
            
            % Solve perfect foresight model after each fine-tuning step
            if ~lSteadyState
                tic;
                oo_ = perfect_foresight_solver(M_, options_, oo_);
                solveTime = toc;
                
                if oo_.deterministic_simulation.status == 1
                    disp(['    ✓ Solver converged in ' num2str(solveTime, '%.2f') ' seconds']);
                else
                    warning('AdditionalShocks(%d) "%s", fine-tuning step %d: Solver did not converge', ...
                            iShock, shock.name, iTune);
                end
            end
        end
        
        % Display summary statistics
        finalValues = oo_.exo_simul(:, shock.shockIndex);
        nonZeroIdx = finalValues ~= 0;
        if any(nonZeroIdx)
            disp(['    ✓ Successfully applied "' shock.name '"']);
            disp(['      - Periods affected: ' num2str(sum(nonZeroIdx))]);
            disp(['      - Value range: [' num2str(min(finalValues(nonZeroIdx)), '%.4f') ', ' ...
                  num2str(max(finalValues(nonZeroIdx)), '%.4f') ']']);
        end
    end
    
    disp(' ');
    disp('========================================================');
    disp('=== All Additional Shocks Applied Successfully ===');
    disp('========================================================');
    disp(' ');
end


function eqLabel = get_static_eq_label(M_, eqIndex)
    % Resolve equation label from Dynare equation tags.
    eqLabel = 'unknown equation';
    if ~isfinite(eqIndex)
        return
    end

    % Preferred source requested by user.
    if isfield(M_, 'eq_tags') && ~isempty(M_.eq_tags)
        label = lookup_label_in_tags(M_.eq_tags, eqIndex);
        if ~isempty(label)
            eqLabel = label;
            return
        end
    end

    % Fallback for Dynare variants that store tags here.
    if isfield(M_, 'equations_tags') && ~isempty(M_.equations_tags)
        label = lookup_label_in_tags(M_.equations_tags, eqIndex);
        if ~isempty(label)
            eqLabel = label;
        end
    end
end

function label = lookup_label_in_tags(tags, eqIndex)
    label = '';
    if ~iscell(tags)
        return
    end

    nRows = size(tags, 1);
    nCols = size(tags, 2);

    % Format A: {eqIndex, 'equation name'}
    if nCols >= 2
        for i = 1:nRows
            rowEq = parse_eq_index(tags{i, 1});
            if isfinite(rowEq) && rowEq == eqIndex
                candidate = tags{i, 2};
                if ischar(candidate) || isstring(candidate)
                    label = char(candidate);
                    return
                end
            end
        end
    end

    % Format B (Dynare): {eqIndex, 'name', 'equation name'}
    if nCols >= 3
        for i = 1:nRows
            rowEq = parse_eq_index(tags{i, 1});
            if ~(isfinite(rowEq) && rowEq == eqIndex)
                continue
            end
            key = tags{i, 2};
            val = tags{i, 3};
            if (ischar(key) || isstring(key)) && strcmpi(char(key), 'name') && (ischar(val) || isstring(val))
                label = char(val);
                return
            end
        end
    end
end

function idx = parse_eq_index(raw)
    idx = NaN;
    if isnumeric(raw) && isscalar(raw)
        idx = double(raw);
        return
    end
    if ischar(raw) || isstring(raw)
        idx = str2double(char(raw));
    end
end
