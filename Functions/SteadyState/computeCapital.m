function [fval_vec, strys, strexo] = computeCapital(x, strys, strexo, strpar)
% computeCapital
% -------------------------------------------------------------------------
% Solves for the sectoral and regional capital stock that satisfies the
% household first-order conditions (FOCs) in the steady state of the model.
%
% This function is typically called as part of a steady-state solver or 
% calibration routine in a multi-sector, multi-region DGE/CGE model.
%
% Inputs:
%   - x       [vector]     Initial guess for the capital stock in each
%                          region and subsector (ordered to match strys).
%   - strys   [struct]     Structure containing all endogenous model
%                          variables (e.g., prices, wages, outputs).
%   - strexo  [struct]     Structure of exogenous shocks (e.g., climate,
%                          technology, demographics).
%   - strpar  [struct]     Structure with all fixed model parameters.
%
% Outputs:
%   - fval_vec [vector]    Vector of residuals from the first-order
%                          conditions of households w.r.t. capital.
%                          (used for root-finding/calibration)
%   - strys    [struct]    Updated structure with solved endogenous
%                          variables.
%   - strexo   [struct]    Updated structure with potentially adjusted
%                          exogenous variables.
%
% Method:
%   I.   Assign the capital guess to the model state.
%   II.  Update predetermined and exogenous variables.
%   III. Recompute regional prices, production factors, sectoral
%        aggregates, and macroeconomic quantities.
%   IV.  Evaluate the residuals
% -------------------------------------------------------------------------

    %% I. Assign input guess to endogenous variables
    strys = assignGuessToStrys(strys, x, strpar);
    %% II. If calibration is output-based, compute exogenous output
    [strys, strpar, strexo] = assignPredeterminedVariables(strys, strpar, strexo);
    strys = assignExogenousClimateAndPrices(strys, strexo, strpar);
    %% III. Recompute regional prices, production factors, sectoral aggregates, and macroeconomic quantities.
    strys = computeRegionalPriceIndexes(strys, strpar, strexo);

    if strpar.lCalibration_p == 2    
        [strys, strpar, strexo] = computeExogenousYProduction(strys, strpar, strexo);
    end
    [strys, strpar, strexo] = computeProductionFactorsAndOutput(strys, strpar, strexo);

    % Sectoral aggregates and prices
    [strys, strexo] = initializeSectoralAggregation(strys, strpar, strexo);
    strys = computeSectoralPriceAndFactorAggregates(strys, strpar);

    % National aggregates (consumption, investment, imports, emissions, etc.)
    [strys, strpar, strexo] = computeAggregates(strys, strpar, strexo);

    % Government tax revenue
    [strys, strpar, strexo] = computeTaxIncome(strys, strpar, strexo);

    % Macro aggregates by region (C, I, M, G, NX, PH, H, etc.)
    [strys, strexo, ~] = computeRegionalMacroAggregates(strys, strpar, strexo);

    % Re-compute updated aggregates post-macro adjustments
    [strys, strpar, strexo] = computeAggregates(strys, strpar, strexo);

    

    %% IV. Evaluate the residuals
    [fval_vec, strys] = evaluateCapitalSteadyStateResiduals(strys, strpar, strexo);
end
