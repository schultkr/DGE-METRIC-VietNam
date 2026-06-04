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
    
    oo_ = apply_baseline_shock_structure(oo_, structScenarioResults, sVersion, lCapandTrade_p, posIdx, sBaseline);

    % Parameter adjustments
    M_ = apply_parameter_adjustments(M_, lExoNX_p, lCapandTrade_p, sScenario, lEndoMig_p);
    M_ = assign_region_subsector_params(M_, sScenario, inbregions_p, imaxsec_p);
end

%% Simulation Options and Initialization
iStep = options_.iStepSimulation;
options_.simul.maxit = 20;
imaxTermination_p = 100;
iminTermination_p = 100;
imaxsec_p = eval(['subend_' num2str(inbsectors_p) '_p']);
options_.periods = 1000;
options_.stack_solve_algo = 0;
lBaselineBackward = exist('lBaselineBackward_p', 'var') && lBaselineBackward_p == 1;

if isequal(sScenario, 'Baseline')
    oo_ = perfect_foresight_setup(M_, options_, oo_);
    % Warm-start endo_simul from a reference Baseline candidate if sBaselineWarmRef is set.
    % sBaselineWarmRef must equal the sSensitivity suffix used for that reference run
    % (e.g. '' for the plain reference Baseline, '_Cand01' for the first candidate).
    % Set it in RunSimulations.m before calling dynare; leave unset or '' to skip.
    if exist('sBaselineWarmRef', 'var') && ~isempty(sBaselineWarmRef)
        refMat = ['structScenarioResults' sBaselineWarmRef '.mat'];
        if isfile(refMat)
            refData  = load(refMat, 'structScenarioResults');
            sVersionRef = ['Sectors' num2str(imaxsec_p) 'Regions' num2str(inbregions_p) sBaselineWarmRef];
            if isfield(refData.structScenarioResults, sVersionRef) && ...
               isfield(refData.structScenarioResults.(sVersionRef), 'Baseline')
                refEndo = refData.structScenarioResults.(sVersionRef).Baseline.oo_.endo_simul;
                T = min(size(refEndo, 2), size(oo_.endo_simul, 2));
                oo_.endo_simul(:, 1:T) = refEndo(:, 1:T);
                disp(['[Warm-start] Baseline endo_simul seeded from structScenarioResults' sBaselineWarmRef '.mat']);
            else
                disp(['[Warm-start] Reference Baseline not found in structScenarioResults' sBaselineWarmRef '.mat — using default initial path.']);
            end
        else
            disp(['[Warm-start] File not found: ' refMat ' — using default initial path.']);
        end
    end
end

% Load exogenous variables and growth targets
% exoup = readtable(sWorkbookScenarios, 'Sheet', sScenario);
oo_ = load_exogenous_twice(sWorkbookBaseline, sWorkbookScenarios, sScenario, oo_, M_, sBaselineSheet);
oo_.endo_simul_start = oo_.endo_simul;
oo_.exo_simul_start = oo_.exo_simul;

% Baseline: activate endogenous wedge targeting (exo_lTargetInv = 1 during transition).


nPeriods = size(oo_.exo_simul, 1);
[iaTargetGrowthRates, iaTargetGrowthRatesN, iTermination_p] = build_target_growth_rates(...
    sWorkbookBaseline, M_, nPeriods, sBaselineSheet);
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
            [yst, ~, ~, ~] = DGE_Model_steadystate(oo_.endo_simul(:, end), oo_.exo_simul(end,:), M_, options_);

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
                [yst, ~, ~, ~] = DGE_Model_steadystate(yst, oo_.exo_simul(end,:), M_, options_);
            end
            
            if icostep == 1
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

    outputPath = ['ExcelFiles/Output/' sScenario];
    if ~contains(sScenario, '.csv')
        outputPath = ['ExcelFiles/Output/' sSensitivity sScenario '.csv'];
    end
    writetable(tabvars, outputPath);
end

%% ==============================
%  Local helper functions
%  ==============================

function oo_ = apply_baseline_shock_structure(oo_, structScenarioResults,...
               sVersion, lCapandTrade_p, posIdx, sBaseline)

    % Build baseline-aligned exogenous shocks and base paths.

    baselineSim = structScenarioResults.(sVersion).(sBaseline).oo_.endo_simul;
    if isequal(sBaseline, 'Baseline')
        oo_.exo_simul(:, posIdx.iposProdShocks)  = log(baselineSim(posIdx.iposAVars,:) ./ baselineSim(posIdx.iposAVars,1))';
        oo_.exo_simul(:, posIdx.iposProdShocksN) = log(baselineSim(posIdx.iposANVars,:))';
        
        oo_.exo_simul(:, posIdx.iposadjBShock)   = baselineSim(posIdx.iposadjB,:)';
        oo_.exo_simul(:, posIdx.iposdeltaBShock) = baselineSim(posIdx.iposdeltaB,:)';
        oo_.exo_simul(:, posIdx.iposPriceHShock) = log(baselineSim(posIdx.iposPH,:) ./ baselineSim(posIdx.iposPH,1))';
        oo_.exo_simul(:, posIdx.iposkapEShock) = (baselineSim(posIdx.iposkappaE,:) - baselineSim(posIdx.iposkappaE,1))';
    
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
        if lCapandTrade_p == 1
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
    oo_.exo_simul(:, posIdx.iposGAShocks)     = oo_.exo_simul_start(:, posIdx.iposGAShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposphiGShocks)   = oo_.exo_simul_start(:, posIdx.iposphiGShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposPVShocks)  = oo_.exo_simul_start(:, posIdx.iposPVShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposPVEffShocks)  = oo_.exo_simul_start(:, posIdx.iposPVEffShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposPKShocks)  = oo_.exo_simul_start(:, posIdx.iposPKShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.ipossGScenShocks)  = oo_.exo_simul_start(:, posIdx.ipossGScenShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposDamKShocks)  = oo_.exo_simul_start(:, posIdx.iposDamKShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposADShock)     = oo_.exo_simul_start(:, posIdx.iposADShock) .* stepFrac;
    oo_.exo_simul(:, posIdx.ipossFDIShareShocks) = oo_.exo_simul_start(:, posIdx.ipossFDIShareShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposrFDIShocks) = oo_.exo_simul_start(:, posIdx.iposrFDIShocks) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposEmShocks)     = oo_.exo_simul_start(:, posIdx.iposEmShocks) .* stepFrac;
    % oo_ = copy_exo_from_start(oo_, posIdx.iposAIShocksec);
    oo_.exo_simul(:, posIdx.iposAIShocksec)  = oo_.exo_simul_start(:, posIdx.iposAIShocksec) .* stepFrac;
    oo_.exo_simul(:, posIdx.iposEERegShocks) = oo_.exo_simul_start(:, posIdx.iposEERegShocks) .* stepFrac;
    if any(posIdx.iposREShocks ~=0)
        oo_.exo_simul(:, posIdx.iposREShocks) = oo_.exo_simul_start(:, posIdx.iposREShocks) .* (icostep / iStep);
    end
    % oo_.exo_simul(:, posIdx.iposkapEShock)     = oo_.exo_simul_start(:, posIdx.iposkapEShock) .* stepFrac;

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
            posIdx.iposLFShocks, posIdx.iposNXShock]);
    
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
            posIdx.iposLFDIShareShocks,posIdx.iposLIGShareShocks];
    
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
