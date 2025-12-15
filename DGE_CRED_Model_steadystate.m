function [ys,params,check,exo] = DGE_CRED_Model_steadystate(ys,exo,M_,options_)
% function [ys,check] = IWH_CRED_Model_steadystate(ys,exo)
% computes the steady state for the IWH_CRED_Model.mod and uses a numerical
% solver to do so
% Inputs: 
%   - ys        [vector] vector of initial values for the steady state of
%                   the endogenous variables
%   - exo       [vector] vector of values for the exogenous variables
%   - M_        [structure] dynare model structure
%   - options_  [structure] dynare model options structure
%
%
% Output: 
%   - ys        [vector] vector of steady state values for the the endogenous variables
%   - params    [vector] vector of parameter values of the model
%   - exo       [vector] vector of exogenous variables of the model
    check = false;
    options_ = options_;%#ok
    % read out parameters to access them with their name
    NumberOfParameters = M_.param_nbr;
    % create strings indicating fossil and energy sector
    strpar.casClimatevarsNational = strsplit(strrep(strrep(M_.ClimateVarsNational,'[','' ), ']', ''), ', ');
    strpar.casClimatevarsRegional = strsplit(strrep(strrep(M_.ClimateVarsRegional,'[','' ), ']', ''), ', ');
    strpar.casClimatevars = [strpar.casClimatevarsNational strpar.casClimatevarsRegional];
    strpar.Init = nan;
    for ii = 1:NumberOfParameters
      paramname = char(M_.param_names(ii,:));
      eval([ paramname ' = M_.params(' int2str(ii) ');']);
      strpar.(paramname) = M_.params(ii);
    end
    strpar.ssubsecfossil = num2str(strpar.iSubsecFossil_p);
    strpar.ssecenergy = num2str(strpar.iSecEnergy_p);    
    % read out parameters to access them with their name
    NumberOfEndo = M_.endo_nbr;
    strys.Init = nan;
    for ii = 1:NumberOfEndo
      varname = char(M_.endo_names(ii,:));
      strys.(varname) = ys(ii);
    end
    
    % read out parameters to access them with their name
    NumberOfExo = M_.exo_nbr;
    strexo.Init = nan;
    for ii = 1:NumberOfExo
      exoname = char(M_.exo_names(ii,:));
      strexo.(exoname) = exo(ii);
    end
    if strpar.lCalibration_p == 0
        if isoctave()
            options = optimset('Display', 'off', 'TolFun', 1e-16, 'TolX', 1e-12, 'Updating', 'on');  
        else
            options = optimset('Display', 'iter', 'TolFun', 1e-16, 'TolX', 1e-12, 'MaxFunEval', 100000);
        end
        [xstart_vec, strys, strpar] = buildInitialGuess(strys, strexo, strpar, 'fullSS');
        computeCapitalTemp = @(x)computeCapital(x,strys,strexo,strpar);
        [Fval_vec, strys, strexo] = computeCapital(xstart_vec, strys, strexo, strpar);
        if max(abs(Fval_vec(:)))>1e-8
            [xopt, ~, ~, ~, ~] = fsolve(computeCapitalTemp, xstart_vec, options);%, strys, strexo, strpar);
            [~, strys,strexo] = computeCapital(xopt, strys, strexo, strpar);
        end
    elseif strpar.lCalibration_p == 2
        if isoctave()
            options = optimset('Display', 'off', 'TolFun', 1e-16, 'TolX', 1e-12, 'Updating', 'on');  
        else
            options = optimset('Display', 'iter', 'TolFun', 1e-16, 'TolX', 1e-12, 'MaxFunEval', 100000);
        end
        [xstart_vec, strys, strpar] = buildInitialGuess(strys, strexo, strpar, 'hybrid');
        computeCapitalTemp = @(x)computeCapital(x,strys,strexo,strpar);
        [Fval_vec, strys, strexo] = computeCapital(xstart_vec, strys, strexo, strpar);
        if max(abs(Fval_vec(:)))>1e-8
            [xopt, ~, ~, ~, ~] = fsolve(computeCapitalTemp, xstart_vec, options);%, strys, strexo, strpar);
            [Fval_vec, strys,strexo] = computeCapital(xopt, strys, strexo, strpar);
        end
        disp(['Maximum absolute residual ' num2str(max(abs(Fval_vec)))])          
        checkAllocationErrors(strys, strpar);
    else 
        % calibrate model
        if isoctave()
            options = optimset('Display', 'off', 'TolFun', 1e-20, 'TolX', 1e-25);  
        else
            options = optimset('Display', 'iter', 'TolFun', 1e-20, 'TolX', 1e-25, 'MaxFunEval', 10000);
        end
        [xstart_vec, strys, strpar] = buildInitialGuess(strys, strexo, strpar, 'calibrate');        
        setupInitialStateTemp = @(x)setupInitialState(x,strys,strexo,strpar);
        [Feval, strpar,strys] = setupInitialState(xstart_vec, strys, strexo, strpar);
        if max(abs(Feval)) > 1e-8
            [xopt, Feval, Info, outtemp, fjac] = fsolve(setupInitialStateTemp, xstart_vec, options);%#ok
            [~, strpar, strys] = setupInitialState(xopt, strys, strexo, strpar);
        end
        checkAllocationErrors(strys, strpar);
        
    end
    %% end own model equations
    
    for iter = 1:length(M_.params) %update parameters set in the file
      M_.params(iter) = strpar.(char(M_.param_names(iter,:)));
    end
    params = M_.params;
    
    NumberOfEndogenousVariables = M_.orig_endo_nbr; %auxiliary variables are set automatically
    for ii = 1:NumberOfEndogenousVariables
      varname = char(M_.endo_names(ii,:));
      ys(ii) = strys.(varname);
    end
    
    NumberOfExogenousVariables = M_.exo_nbr; %auxiliary variables are set automatically
    for ii = 1:NumberOfExogenousVariables
      varname = char(M_.exo_names(ii,:));
      exo(ii) = strexo.(varname);
    end
end

function [errorVA, errorWage] = checkAllocationErrors(strys, strpar)
%CHECKALLOCATIONERRORS Computes max errors in value-added and wage allocation.
%
% Inputs:
%   - strys  : structure of endogenous steady-state variables
%   - strpar : structure of model parameters
%
% Outputs:
%   - errorVA   : maximum absolute error in value-added share
%   - errorWage : maximum absolute error in wage share

    errorVA = 0;
    errorWage = 0;

    for icosec = 1:strpar.inbsectors_p
        ssec = num2str(icosec);
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);

            % Compute actual value-added share
            %actualVA = strys.(['Y_' ssec '_' sreg]) * strys.(['P_' ssec '_' sreg]) / strys.Q;
            actualVA = strys.(['Y_' ssec '_' sreg]) * strpar.(['P0_' ssec '_' sreg '_p']) / strys.Q;
            targetVA = strpar.(['phiY_' ssec '_' sreg '_p']);
            errorVA = max(errorVA, abs(actualVA - targetVA));

            % Compute actual wage share
            actualWage = strys.(['W_' ssec '_' sreg]) * strys.(['N_' ssec '_' sreg]) * ...
                         strys.(['LF_' sreg]) * (1 + strys.(['tauNF_' ssec '_' sreg])) / strys.Q;
            targetWage = strpar.(['phiW_' ssec '_' sreg '_p']);
            errorWage = max(errorWage, abs(actualWage - targetWage));
        end
    end

    % Display summary
    fprintf('Maximum value-added share error: %.4e\n', errorVA);
    fprintf('Maximum wage share error:        %.4e\n', errorWage);
end

