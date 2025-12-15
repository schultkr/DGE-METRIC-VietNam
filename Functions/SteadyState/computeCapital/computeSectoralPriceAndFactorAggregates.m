function strys = computeSectoralPriceAndFactorAggregates(strys, strpar)
% computeSectoralPriceAndFactorAggregates
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

                % Compute price of sub-sectoral output net of emissions cost
                if strpar.lCalibration_p ~= 2
                    strys.(['P_' ssubsec '_' sreg]) = ...
                        (1 - strpar.(['omegaQI_' ssubsec '_' sreg '_p']))^(1 / strpar.(['etaI_' ssubsec '_p'])) * ...
                        (strys.(['Y_' ssubsec '_' sreg]) / strys.(['Q_' ssubsec '_' sreg]))^(-1 / strpar.(['etaI_' ssubsec '_p'])) * ...
                        (strys.(['P_Q_' ssubsec '_' sreg]) - ...
                         strys.(['kappaE_' ssubsec '_' sreg]) * ...
                         strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * ...
                         strys.(['PE_' sreg]));
                end

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
                strys.(['I_' ssubsec '_' sreg]) = ...
                     strpar.(['delta_' ssubsec '_' sreg '_p']) * strys.(['KH_' ssubsec '_' sreg]) + strys.(['D_K_' ssubsec '_' sreg]);
            end
        end
    end
end
