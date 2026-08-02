function [fval_vec, strpar, strys] = setup_initial_state(x, strys, strexo, strpar)
% setup_initial_state
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
%   II. Compute production factors and sector-level quantities
%   III.  Aggregate national and regional economic outcomes
%   IV.   Evaluate model residuals for price consistency
% -------------------------------------------------------------------------

    %% I. Assign initial guesses and predetermined variables
    strys.Y = strpar.Y0_p;
    strys.rf = 1 / strpar.beta_p - 1 + strpar.deltaB_p;
    strys = assign_guess_to_strys(strys, x, strpar);
    [strys, strpar, strexo] = assign_predetermined_variables(strys, strpar, strexo);
    
    
    %% II. Compute national price levels
    [strys, strpar] = compute_regional_export_price_index(strys, strpar);
    
    %% III. Production function calibration
    [strys, strpar] = compute_pf_parameters(strys, strpar, strexo);
    
    %% IV. Compute sectoral/regional outputs and factor demands
    [strys, strpar, strexo] = compute_production_factors_and_output(strys, strpar, strexo);
    
    %% V. Aggregate quantities and trade imbalances
    [strys, strpar, strexo] = compute_aggregates(strys, strpar, strexo);
    [strys, strpar] = compute_regional_imports_and_demand(strys, strpar);
    [strys, strpar] = compute_emissions_and_aggregate_output(strys, strpar);
    
    strys.NX = strys.X - strys.M;
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strpar.(['NX0_' sreg '_p']) = strys.(['NX_' sreg]) / strys.(['Y_' sreg]);
    end
    strpar.NX0_p = strys.NX / strys.Y;
    
    %% VI. Fiscal revenues and public finance
    [strys, strpar, strexo] = compute_tax_income(strys, strpar, strexo);
    
    %% VII. Aggregate initialization and regional macro variables
    [strys, strpar, strexo] = compute_regional_economic_accounts(strys, strpar, strexo);
    strys = compute_government_expenditure_and_capital(strys, strpar);
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strpar.(['GY0_' sreg '_p']) = strys.(['G_' sreg]) / strys.(['Y_' sreg]);
    end

    %% VIII. Final parameter adjustments from initialization
    strpar = finalize_calibration_parameters(strys, strpar, strexo);
    
    %% IX. Evaluate residuals from price consistency equations
    fval_vec = evaluate_price_consistency(strys, strpar);
end
