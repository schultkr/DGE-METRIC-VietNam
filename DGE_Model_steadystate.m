function [ys,params,check,exo] = DGE_Model_steadystate(ys,exo,M_,options_)
% DGE_CRED_Model_steadystate_new
% Refactored steady-state computation with clearer function structure.
%
% This is a non-breaking alternative to DGE_CRED_Model_steadystate.m that
% delegates core steady-state work to wrapper functions located under
% Functions/steady_state.
%
% Inputs:
%   - ys        [vector] initial values for the steady state of endogenous vars
%   - exo       [vector] values for the exogenous variables
%   - M_        [struct] Dynare model structure
%   - options_  [struct] Dynare options structure
%
% Outputs:
%   - ys        [vector] steady-state values of endogenous variables
%   - params    [vector] parameter values of the model
%   - check     [logical] flag for steady-state issues (always false here)
%   - exo       [vector] exogenous variables (possibly updated)
%

    check = false;
    options_ = options_;%#ok

    % Ensure the Functions tree (including subfolders) is on the MATLAB path.
    % This makes Functions/steady_state and its subfolders discoverable.
    thisFileDir = fileparts(mfilename('fullpath'));
    functionsDir = fullfile(thisFileDir, 'Functions');
    if exist(functionsDir, 'dir')
        addpath(genpath(functionsDir));
    end

    % ---------------------------------------------------------------------
    % 1. Read parameters and build convenience structures
    % ---------------------------------------------------------------------
    NumberOfParameters = M_.param_nbr;

    % create strings indicating fossil and energy sector
    strpar.casClimatevarsNational = strsplit(strrep(strrep(M_.ClimateVarsNational,'[','' ), ']', ''), ', ');
    strpar.casClimatevarsRegional = strsplit(strrep(strrep(M_.ClimateVarsRegional,'[','' ), ']', ''), ', ');
    strpar.casClimatevars = [strpar.casClimatevarsNational strpar.casClimatevarsRegional];
    strpar.Init = nan;
    for ii = 1:NumberOfParameters
        paramname = char(M_.param_names(ii,:));
        eval([ paramname ' = M_.params(' int2str(ii) ');']); %#ok<EVLDIR>
        strpar.(paramname) = M_.params(ii);
    end
    strpar.ssubsecfossil = num2str(strpar.iSubsecFossil_p);
    strpar.ssecenergy = num2str(strpar.iSecEnergy_p);

    % Endogenous variables into struct
    NumberOfEndo = M_.endo_nbr;
    strys.Init = nan;
    for ii = 1:NumberOfEndo
        varname = char(M_.endo_names(ii,:));
        strys.(varname) = ys(ii);
    end

    % Exogenous variables into struct
    NumberOfExo = M_.exo_nbr;
    strexo.Init = nan;
    for ii = 1:NumberOfExo
        exoname = char(M_.exo_names(ii,:));
        strexo.(exoname) = exo(ii);
    end

    % Guardrail: cap-and-trade compiled ON but regional cap activation OFF.
    % This commonly happens when baseline sheet exo_CapTrade_* entries are 0,
    % leaving the regional cap equation effectively inactive in the SS residual set.
    if isfield(strpar, 'lCapandTrade_p') && strpar.lCapandTrade_p == 1
        offRegions = [];
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);
            key = ['exo_CapTrade_' sreg];
            if isfield(strexo, key) && strexo.(key) < 0.5
                offRegions = [offRegions icoreg]; %#ok<AGROW>
            end
        end
        if ~isempty(offRegions)
            warning('DGE:CapTradeRegionalFlagOff', ...
                ['Cap-and-trade is compiled ON (lCapandTrade_p=1) but exo_CapTrade is OFF for region(s): %s. ', ...
                 'Set baseline exo_CapTrade_* = 1 where cap equations should be enforced.'], ...
                mat2str(offRegions));
        end
    end

    % ---------------------------------------------------------------------
    % 2. Steady-state / calibration logic
    % ---------------------------------------------------------------------
    if strpar.lCalibration_p == 0
        % Full steady state
        if isoctave()
            options = optimset('Display', 'off', 'TolFun', 1e-16, 'TolX', 1e-12, 'Updating', 'on');
        else
            options = optimset('Display', 'iter', 'TolFun', 1e-16, 'TolX', 1e-12, 'MaxFunEval', 100000);
        end

        
        [xstart_vec, strys, strpar] = ss_build_initial_guess(strys, strexo, strpar, 'fullSS');
        
        [Fval_vec, strys, strexo] = ss_compute_capital(xstart_vec, strys, strexo, strpar);

        if max(abs(Fval_vec(:))) > 1e-8
            computeCapitalTemp = @(x) ss_compute_capital(x, strys, strexo, strpar);
            [xopt, ~, ~, ~, ~] = fsolve(computeCapitalTemp, xstart_vec, options); %#ok<ASGLU>
            [Fval_vec, strys, strexo] = ss_compute_capital(xopt, strys, strexo, strpar);
            % if max(abs(Fval_vec(:))) > 1e-8
            %     [Fval_vec, strys, strexo] = ss_compute_capital(xopt, strys, strexo, strpar);
            %     tol = 1e-8;
            %     [~, idxMax] = max(abs(Fval_vec(:)));
            %     [Frow, Fcol] = ind2sub(size(Fval_vec), idxMax);
            %     Fmax = Fval_vec(idxMax);
            %     xpreview = xstart_vec(1:min(5,end));
            %     error('MyModel:FSolveNoConverge', ...
            %         ['fsolve failed to reduce residuals below tolerance.\n' ...
            %         ' max(|F|) = %g at element (%d,%d), tol = %g.\n' ...
            %         'xstart_vec(1:%d) = [%s]\n' ...
            %         'Check computeCapitalTemp, initial guess, and options.'], ...
            %         Fmax, Frow, Fcol, tol, numel(xpreview), sprintf('%g ', xpreview));
            % 
            % end
        end

    elseif strpar.lCalibration_p == 2
        % Hybrid mode
        if isoctave()
            options = optimset('Display', 'off', 'TolFun', 1e-16, 'TolX', 1e-12, 'Updating', 'on');
        else
            options = optimset('Display', 'iter', 'TolFun', 1e-16, 'TolX', 1e-12, 'MaxFunEval', 100000);
        end

        [xstart_vec, strys, strpar] = ss_build_initial_guess(strys, strexo, strpar, 'hybrid');
        computeCapitalTemp = @(x) ss_compute_capital(x, strys, strexo, strpar);
        [Fval_vec, strys, strexo] = ss_compute_capital(xstart_vec, strys, strexo, strpar);

        if max(abs(Fval_vec(:))) > 1e-8
            [xopt, ~, ~, ~, ~] = fsolve(computeCapitalTemp, xstart_vec, options); %#ok<ASGLU>
            [Fval_vec, strys, strexo] = ss_compute_capital(xopt, strys, strexo, strpar);
        end

        % Enforce exact regional cap closure from solved emissions levels.
        % This avoids tiny but persistent residuals in the Dynare cap equation
        % (e.g., equation "regional price of emissions/emission cap") when
        % tauS shocks are large and the nonlinear system is tightly coupled.
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);
            lCapActive = strexo.exo_CapTradeInternat == 1;
            if ~lCapActive && isfield(strexo, ['exo_CapTrade_' sreg])
                lCapActive = strexo.(['exo_CapTrade_' sreg]) == 1;
            end
            if ~lCapActive
                continue
            end

            eReg = strys.(['E_' sreg]);
            e0Reg = strpar.(['E0_' sreg '_p']);
            eBaseKey = ['exo_EBase_' sreg];
            capShift = (strexo.(['exo_PE_' sreg]) + strexo.exo_PE + strexo.exo_CapTradeInternat + strexo.(['exo_CapTrade_' sreg])) * strpar.phiG_p;
            eTarget = eReg + capShift;
            if isfield(strexo, eBaseKey) && isfinite(eTarget) && isfinite(e0Reg) && e0Reg > 0 && eTarget > 0
                strexo.(['exo_E_' sreg]) = log(eTarget / e0Reg) - strexo.(eBaseKey);
            end
        end

        disp(['Maximum absolute residual ' num2str(max(abs(Fval_vec)))]);

        % diagnostics
        check_allocation_errors(strys, strpar);

    else
        % Calibration mode
        if isoctave()
            options = optimset('Display', 'off', 'TolFun', 1e-20, 'TolX', 1e-25);
        else
            options = optimset('Display', 'iter', 'TolFun', 1e-20, 'TolX', 1e-25, 'MaxFunEval', 10000);
        end

        [xstart_vec, strys, strpar] = ss_build_initial_guess(strys, strexo, strpar, 'calibrate');
        setupInitialStateTemp = @(x) ss_setup_initial_state(x, strys, strexo, strpar);
        [Feval, strpar, strys] = ss_setup_initial_state(xstart_vec, strys, strexo, strpar);

        if max(abs(Feval)) > 1e-8
            [xopt, Feval, Info, outtemp, fjac] = fsolve(setupInitialStateTemp, xstart_vec, options); %#ok<ASGLU>
            [~, strpar, strys] = ss_setup_initial_state(xopt, strys, strexo, strpar);
        end

        % diagnostics
        check_allocation_errors(strys, strpar);
    end

    % ---------------------------------------------------------------------
    % 3. Write back to Dynare structures
    % ---------------------------------------------------------------------
    for iter = 1:length(M_.params) % update parameters set in the file
        M_.params(iter) = strpar.(char(M_.param_names(iter,:)));
    end
    params = M_.params;

    NumberOfEndogenousVariables = M_.orig_endo_nbr; % auxiliary variables set automatically
    for ii = 1:NumberOfEndogenousVariables
        varname = char(M_.endo_names(ii,:));
        ys(ii) = strys.(varname);
    end

    NumberOfExogenousVariables = M_.exo_nbr; % auxiliary variables set automatically
    for ii = 1:NumberOfExogenousVariables
        varname = char(M_.exo_names(ii,:));
        exo(ii) = strexo.(varname);
    end
end

