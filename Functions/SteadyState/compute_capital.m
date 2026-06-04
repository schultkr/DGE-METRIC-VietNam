function [fval_vec, strys, strexo] = compute_capital(x, strys, strexo, strpar)
% compute_capital
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
    strysinit = strys;
    strexoinit = strexo;
    strparinit = strpar;
    %% I. Assign input guess to endogenous variables
    strys = assign_guess_to_strys(strys, x, strpar);
    %% II. If calibration is output-based, compute exogenous output
    [strys, strpar, strexo] = assign_predetermined_variables(strys, strpar, strexo);
    strys = assign_exogenous_climate_and_prices(strys, strexo, strpar);
    %% III. Recompute regional prices, production factors, sectoral aggregates, and macroeconomic quantities.
    strys = compute_regional_price_indexes(strys, strpar, strexo);

    if strpar.lCalibration_p == 2    
        [strys, strpar, strexo] = compute_exogenous_y_production(strys, strpar, strexo);
    end
    [strys, strpar, strexo] = compute_production_factors_and_output(strys, strpar, strexo);

    % Sectoral aggregates and prices
    [strys, strexo] = initialize_sectoral_aggregation(strys, strpar, strexo);
    strys = compute_sectoral_price_and_factor_aggregates(strys, strpar, strexo);

    % National aggregates (consumption, investment, imports, emissions, etc.)
    [strys, strpar, strexo] = compute_aggregates(strys, strpar, strexo);

    % Government tax revenue
    [strys, strpar, strexo] = compute_tax_income(strys, strpar, strexo);

    % Macro aggregates by region (C, I, M, G, NX, PH, H, etc.)
    [strys, strexo, ~] = compute_regional_macro_aggregates(strys, strpar, strexo);

    % Re-compute updated aggregates post-macro adjustments
    [strys, strpar, strexo] = compute_aggregates(strys, strpar, strexo);

    

    %% IV. Evaluate the residuals
    [fval_vec, strys] = evaluate_capital_steady_state_residuals(strys, strpar, strexo);
end