function [fval_vec, strpar, strys] = setupInitialState(x, strys, strexo, strpar)
% setupInitialState
% -------------------------------------------------------------------------
% Initializes the steady-state guess for the DGE-CRED model under the
% assumption of exogenous output (Y). This routine is typically used at
% the beginning of calibration or simulation workflows.
%
% The function assigns initial values for key macroeconomic aggregates,
% calibrates sectoral production factors, computes implied prices, and
% evaluates residuals from the price system consistency equations.
%
% Inputs:
%   - x        [vector]     Initial guess vector for steady-state values
%                           (e.g., capital, labor, housing)
%   - strys    [struct]     Structure with endogenous model variables
%                           (to be updated internally)
%   - strexo   [struct]     Structure with exogenous shocks (e.g., transfers,
%                           housing, public investment)
%   - strpar   [struct]     Structure with fixed model parameters
%
% Outputs:
%   - fval_vec [vector]     Residuals from price consistency conditions
%                           (used in root-finding or calibration)
%   - strpar   [struct]     Updated parameter structure after calibration
%   - strys    [struct]     Updated structure of endogenous variables
%
% Method:
%   I.   Assign guess vector and predetermined values
%   II.  Initialize macroeconomic quantities and price levels
%   III. Compute production factors and sector-level quantities
%   IV.  Aggregate national and regional economic outcomes
%   V.   Evaluate model residuals for price consistency
% -------------------------------------------------------------------------

    %% I. Assign initial guesses and predetermined variables
    strys = assignGuessToStrys(strys, x, strpar);
    [strys, strpar, strexo] = assignPredeterminedVariables(strys, strpar, strexo);
    
    %% II. Base macro quantities and national assumptions
    strys.Y = strpar.Y0_p;
    strys.rf = 1 / strpar.beta_p - 1;
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strys.(['Tr_' sreg]) = strpar.(['Tr0_' sreg '_p']) + strexo.(['exo_Tr_' sreg]);
        strys.(['H_' sreg]) = strpar.(['H0_' sreg '_p']) * strys.(['PoP_' sreg]);
    end
    strpar.PoP0_p = strys.PoP;
    strpar.LF0_p = strys.LF;
    
    %% III. Labor allocation and regional adaptation investment
    strys.N = 0;
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strys.(['N_' sreg]) = strpar.(['N0_' sreg '_p']);
        strys.N = strys.N + strys.(['N_' sreg]);
        strys.(['G_A_DH_' sreg]) = strexo.exo_G_A_DH * strpar.Y0_p;
    end
    
    %% IV. Compute national price levels
    [strys, strpar] = computeRegionalExportPriceIndex(strys, strpar);
    
    %% V. Production function calibration
    [strys, strpar] = computePFParameters(strys, strpar, strexo);
    
    %% VI. Compute sectoral/regional outputs and factor demands
    [strys, strpar, strexo] = computeProductionFactorsAndOutput(strys, strpar, strexo);
    
    %% VII. Aggregate quantities and trade imbalances
    [strys, strpar, strexo] = computeAggregates(strys, strpar, strexo);
    [strys, strpar] = computeRegionalImportsAndDemand(strys, strpar);
    strys = computeEmissionsAndAggregateOutput(strys, strpar);
    
    strys.NX = strys.X - strys.M;
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strpar.(['NX0_' sreg '_p']) = strys.(['NX_' sreg]) / strys.(['Y_' sreg]);
    end
    strpar.NX0_p = strys.NX / strys.Y;
    
    %% VIII. Fiscal revenues and public finance
    [strys, strpar, strexo] = computeTaxIncome(strys, strpar, strexo);
    
    %% IX. Aggregate initialization and regional macro variables
    [strys, strpar, ~] = computeRegionalEconomicAccounts(strys, strpar, strexo);
    strys = computeGovernmentExpenditureAndCapital(strys, strpar);
    
    %% X. Final parameter adjustments from initialization
    strpar = finalizeCalibrationParameters(strys, strpar, strexo);
    
    %% XI. Evaluate residuals from price consistency equations
    fval_vec = evaluatePriceConsistency(strys, strpar);
end
