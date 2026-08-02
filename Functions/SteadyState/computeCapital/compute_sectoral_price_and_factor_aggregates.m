function strys = compute_sectoral_price_and_factor_aggregates(strys, strpar, strexo)
    % compute_sectoral_price_and_factor_aggregates
% ---------------------------------------------------------
% Computes sectoral and regional aggregates in a multi-sector,
% multi-region economic model. Specifically:
%
% - Calculates sub-sectoral price indices for primary production factors.
% - Computes sub-sectoral regional wages.
% - Initializes physical capital stock.
% - Sets investment Lagrange multipliers.
% - Computes sub-sectoral investments.
%
% These values are used as core components in calibration and steady-state
% computations in DGE or CGE-type macroeconomic models.
%
% Inputs:
%   strys  - Structure with endogenous model variables.
%   strpar - Structure with model parameters, including sectoral/regional
%            mappings, production parameters, and behavioral coefficients.
%
% Output:
%   strys  - Updated structure with sectoral prices, wages, capital,
%            and investment levels.
% ---------------------------------------------------------

    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);    

        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);

            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec); 

                % Elasticity-related transformation for CES production
                rhotemp = ((strpar.(['etaNK_' ssubsec '_' sreg '_p']) - 1) / ...
                           strpar.(['etaNK_' ssubsec '_' sreg '_p']));

                strys.(['muI_' ssubsec '_' sreg]) = 0;

                % P_K: rental price of installed capital = sector's own value-added price.
                strys.(['P_K_' ssubsec '_' sreg]) = strys.(['P_' ssubsec '_' sreg]) *exp(strexo.(['exo_P_K_' ssubsec '_' sreg]));

                % P_INV: purchase price of investment goods (wedge=0 at SS, so exp(exo_P_K) only).
                % Base: P_Q of capital goods sector (lCapGoodsSecPrice=1) or own sector price.
                % if isfield(strpar, 'lCapGoodsSecPrice_p') && strpar.lCapGoodsSecPrice_p == 1
                %     PINV_base = strys.(['P_Q_' num2str(strpar.iCapGoodsSubsec_p) '_' sreg]);
                % else
                %     PINV_base = strys.(['P_' ssubsec '_' sreg]);
                % end
                % strys.(['P_INV_' ssubsec '_' sreg]) = PINV_base .* exp(strexo.(['exo_P_K_' ssubsec '_' sreg]));
                % Compute sub-sectoral wages in region
                strys.(['W_' ssubsec '_' sreg]) = ...
                    strpar.(['alphaN_' ssubsec '_' sreg '_p'])^(1 / strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * ...
                    (strys.(['A_' ssubsec '_' sreg]) * (1 - strys.(['D_' ssubsec '_' sreg])) * ...
                     strys.(['A_N_' ssubsec '_' sreg]) * (1 - strys.(['D_N_' ssubsec '_' sreg])))^rhotemp * ...
                    ((strys.(['N_' ssubsec '_' sreg]) * strys.(['LF_' sreg])) / strys.(['Y_' ssubsec '_' sreg]))^(-1 / strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * ...
                    strys.(['P_' ssubsec '_' sreg]) / ...
                    (1 + strys.(['tauNF_' ssubsec '_' sreg]));

                % Capital stock allocation
                strys.(['KH_' ssubsec '_' sreg]) = strys.(['K_' ssubsec '_' sreg]);

                % Lagrange multiplier for investment (default to 1 in baseline)
                strys.(['omegaI_' ssubsec '_' sreg]) = 1;

                % Investment equation
                strys.(['IH_' ssubsec '_' sreg]) = ...
                     strpar.(['delta_' ssubsec '_' sreg '_p']) * strys.(['KH_' ssubsec '_' sreg]) + strys.(['D_K_' ssubsec '_' sreg]);
            end
        end
    end
end
