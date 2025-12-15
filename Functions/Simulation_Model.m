%% ==============================
%  Deterministic Simulations Setup
%  ==============================
if ~isequal(sScenario, 'Baseline')
    % Apply baseline shock structure
    baselineSim = structScenarioResults.(sVersion).Baseline.oo_.endo_simul;
    oo_.exo_simul(:, iposProdShocks)  = log(baselineSim(iposAVars,:) ./ baselineSim(iposAVars,1))';
    oo_.exo_simul(:, iposProdShocksN) = log(baselineSim(iposANVars,:))';
    oo_.exo_simul(:, iposProdShocksN) = log(baselineSim(iposANVars,:))';
    % oo_.exo_simul(:, iposPMShocks) = (baselineSim(iposPMPrices,:)-baselineSim(iposPMPrices,1))';

    oo_.exo_simul(:, iposadjBShock)   = baselineSim(iposadjB,:)';
    oo_.exo_simul(:, iposdeltaBShock) = baselineSim(iposdeltaB,:)';
    oo_.exo_simul(:, iposPriceHShock) = log(baselineSim(iposPH,:) ./ baselineSim(iposPH,1))';
    oo_.exo_simul(:, iposkapEShock) = (baselineSim(iposkappaE,:) - baselineSim(iposkappaE,1))';
    oo_.exo_simul(:, iposAIShock)     = log(baselineSim(iposAIVars,:))';

    oo_.exo_base = structScenarioResults.(sVersion).Baseline.oo_.exo_simul;
    oo_.exo_steady_state = oo_.exo_simul(end,:)';
    oo_.exo_base(:, iposEERegShocks) = log(baselineSim(iposEEReg,:)./baselineSim(iposEEReg,1))';
    oo_.exo_simul(:, iposEERegShocks) = oo_.exo_base(:, iposEERegShocks);
    if lCapandTrade_p == 1
        oo_.exo_base(:, iposERegShocks) = log(baselineSim(iposEReg,:)./baselineSim(iposEReg,1))';
        oo_.exo_simul(:, iposERegShocks) = oo_.exo_base(:, iposERegShocks);
        oo_.exo_base(:, iposkapEShock) = (baselineSim(iposkappaE,:)-baselineSim(iposkappaE,1))';
        oo_.exo_simul(:, iposkapEShock) = oo_.exo_base(:, iposkapEShock);
    end


    % Parameter adjustments
    M_.params(ismember(M_.param_names, 'lCalibration_p')) = 0;
    M_.params(ismember(M_.param_names, 'lExoNX_p')) = lExoNX_p;
    M_.params(ismember(M_.param_names, 'lCapandTrade_p')) = lCapandTrade_p;

    if isequal(sScenario, 'BAU')
        M_.params(ismember(M_.param_names, 'lEndoMig_p')) = 0;
    end

    % Loop over regions and subsectors to assign parameters
    for icoreg = 1:inbregions_p
        for icosubsec = 1:imaxsec_p
            paramQ = ['lEndoQ_' num2str(icosubsec) '_' num2str(icoreg) '_p'];
            paramN = ['lEndoN_' num2str(icosubsec) '_' num2str(icoreg) '_p'];

            if contains(sScenario, 'EndoRen')
                M_.params(ismember(M_.param_names, paramQ)) = 1;
            else
                M_.params(ismember(M_.param_names, paramQ)) = eval(paramQ);
            end
            M_.params(ismember(M_.param_names, paramN)) = eval(paramN);
        end
    end
end

%% Simulation Options and Initialization
iStep = options_.iStepSimulation;
options_.simul.maxit = 20;
imaxTermination_p = 100;
iminTermination_p = 100;
imaxsec_p = eval(['subend_' num2str(inbsectors_p) '_p']);
options_.periods = 1000;
options_.stack_solve_algo = 0;

if isequal(sScenario, 'Baseline')
    oo_ = perfect_foresight_setup(M_, options_, oo_);
end

% Load exogenous variables and growth targets
% exoup = readtable(sWorkbookNameInput, 'Sheet', sScenario);
oo_ = LoadExogenous(sWorkbookNameInput, sScenario, oo_, M_);
oo_.endo_simul_start = oo_.endo_simul;
oo_.exo_simul_start = oo_.exo_simul;

[iaGrowthRates, iaGrowthRatesN] = LoadGrowthRates(sWorkbookNameInput, 'Baseline', M_);
nPeriods = size(oo_.exo_simul, 1);
iaTargetGrowthRates = [ones(1, size(iaGrowthRates', 2)); iaGrowthRates'; ones(nPeriods - size(iaGrowthRates', 1) - 1, size(iaGrowthRates', 2))];
iaTargetGrowthRatesN = [ones(1, size(iaGrowthRatesN', 2)); iaGrowthRatesN'; ones(nPeriods - size(iaGrowthRatesN', 1) - 1, size(iaGrowthRatesN', 2))];
iTermination_p = size(iaGrowthRates, 2);
exo_temp = zeros(size(oo_.exo_simul));

%% =================================
%  Run Deterministic Simulations
%  =================================

if isequal(sScenario, 'Baseline')
    % Step-wise simulation to match target GDP growth
    
    icostep = 0;
    while icostep < iStep
        icostep = icostep+1;
        disp(['=== Step ' num2str(icostep) ' of ' num2str(iStep) ' for ' sScenario ' ==='])

        M_.params(ismember(M_.param_names, 'lCalibration_p')) = 2;
        options_.iStepSteadyState = 1;

        % Apply stepwise growth shocks
        oo_.exo_simul(:, iposProdShocks)  = log(cumprod(iaTargetGrowthRates .^ (icostep / iStep), 1));
        oo_.exo_simul(:, iposProdShocksN) = log(cumprod(iaTargetGrowthRatesN .^ (icostep / iStep), 1));
        oo_.exo_simul(:, iposAIShock)     = oo_.exo_simul_start(:, iposAIShock) .* (icostep / iStep);
        oo_.exo_simul(:, iposQShocks)     = oo_.exo_simul_start(:, iposQShocks) .* (icostep / iStep);
        oo_.exo_simul(:, iposEmShocks)     = oo_.exo_simul_start(:, iposEmShocks) .* (icostep / iStep);
        oo_.exo_simul(:, iposAIShocksec) = oo_.exo_simul_start(:, iposAIShocksec);
        oo_.exo_simul(:, iposEERegShocks) = oo_.exo_simul_start(:, iposEERegShocks) .* (icostep / iStep);
        % oo_.exo_simul(:, iposAIShock)     = oo_.exo_simul_start(:, iposAIShock) .* (icostep / iStep);
        oo_.exo_simul(:, iposkapEShock)     = oo_.exo_simul_start(:, iposkapEShock) .* (icostep / iStep);
        scaleVars = [iposQIShock, iposPriceHShock, iposrfShock, iposadjBShock, ...
                     iposBShock, iposPopShocks, iposLFShocks, iposPERegShocks, iposNXShock];

        for var = scaleVars
            oo_.exo_simul(:, var) = oo_.exo_simul_start(:, var) * (icostep / iStep);
        end

        oo_.exo_simul(:, iposEBaseRegShocks) = oo_.exo_simul_start(:, iposEBaseRegShocks);
        oo_.exo_simul(:, iposERegShocks) = oo_.exo_simul_start(:, iposERegShocks) .* (icostep / iStep);
        % Steady-state computation
        [yst, ~, ~, exoSteady] = DGE_CRED_Model_steadystate(oo_.endo_simul(:, end), oo_.exo_simul(end,:), M_, options_);
        [yst, ~, ~, exoSteady] = DGE_CRED_Model_steadystate(yst, exoSteady, M_, options_);

        if icostep == 1
            oo_.endo_simul(:, 2:end) = repmat(yst, 1, size(oo_.endo_simul, 2) - 1);
        else
            oo_.endo_simul(:, end) = yst;
        end

        oo_.steady_state = oo_.endo_simul(:, end);
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

else
    % Climate scenarios: apply damage shocks
    icostep = 0;
    while icostep < iStep
        icostep = icostep+1;
        disp(['=== Step ' num2str(icostep) ' of ' num2str(iStep) ' for ' sScenario ' ==='])

        % Apply climate shock scaling
        climateVars = [iposDamShocks, iposDamKShocks, iposDamNShocks, iposDamHShock, ...
                       iposPriceShock, iposQShocks, iposEmiShocks, iposERegShocks, ...
                       iposExpShocks, iposTauSShocks, iposTauSTrShocks];

        for var = climateVars
            oo_.exo_simul(:, var) = oo_.exo_simul_start(:, var) * (icostep / iStep);
        end

        oo_.exo_simul(:, iposProdShocksN) = oo_.exo_simul_start(:, iposProdShocksN);
        oo_.exo_simul(:, iposAIShocksec) = oo_.exo_simul_start(:, iposAIShocksec);
        oo_.exo_simul(:, iposPopShocks) = oo_.exo_simul_start(:, iposPopShocks);
        oo_.exo_simul(:, iposLFShocks)  = oo_.exo_simul_start(:, iposLFShocks);
        oo_.exo_simul(:, iposNXShock)   = oo_.exo_simul_start(:, iposNXShock);
        oo_.exo_simul(:, iposQShocks)   = oo_.exo_simul_start(:, iposQShocks) * (icostep / iStep);
        oo_.exo_simul(:, iposTauSTrShocks)   = oo_.exo_simul_start(:, iposTauSTrShocks) * (icostep / iStep);
        oo_.exo_simul(:, iposkapEShock)     = oo_.exo_base(:, iposkapEShock) + ...
            (oo_.exo_simul_start(:, iposkapEShock) - oo_.exo_base(:, iposkapEShock)) * (icostep / iStep);
        oo_.exo_simul(:, iposPERegShocks) = oo_.exo_base(:, iposPERegShocks) + ...
            (oo_.exo_simul_start(:, iposPERegShocks) - oo_.exo_base(:, iposPERegShocks)) * (icostep / iStep);
        oo_.exo_simul(:, iposEERegShocks) = oo_.exo_base(:, iposEERegShocks) + ...
            (oo_.exo_simul_start(:, iposEERegShocks) - oo_.exo_base(:, iposEERegShocks)) * (icostep / iStep);

        % oo_.exo_simul(:, iposEERegShocks) = oo_.exo_simul_start(:, iposEERegShocks);
        if lCapandTrade_p == 1
            
            % oo_.exo_simul(:, iposEShock) = oo_.exo_simul_start(:, iposEShock) * (icostep / iStep);
            oo_.exo_simul(:, iposERegShocks) = oo_.exo_base(:, iposERegShocks).*((iStep-icostep) ./ iStep) + ...
            oo_.exo_simul_start(:, iposERegShocks).*(icostep ./ iStep);
        else
            oo_.exo_simul(:, iposPEShock) = oo_.exo_simul_start(:, iposPEShock) * (icostep / iStep);
        end

        % Solve for steady state
        % oo_.endo_simul(iposEReg,:) = exp(oo_.exo_simul(:, iposERegShocks));
        [yst, ~, ~, ~] = DGE_CRED_Model_steadystate(oo_.endo_simul(:, end), oo_.exo_simul(end,:), M_, options_);
        oo_.steady_state = yst;
        oo_.endo_simul(:, end) = repmat(yst, 1, size(oo_.endo_simul(:, end), 2));
        oo_.exo_steady_state = oo_.exo_simul(end,:)';

        steady;
        if icostep == 1 || icostep == iStep
            options_.qz_zero_threshold = 1e-22;
            [eigenvalues_, result, info] = check(M_, options_, oo_);
        end

        tic;
        oo_ = perfect_foresight_solver(M_, options_, oo_);
        toc;
        
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
    xlswrite(sWorkbookNameOutput, caExcelFile, sScenario, ['A1:' sAddress]);
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
