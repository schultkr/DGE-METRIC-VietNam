
function [strys, strpar, strexo] = computeExogenousYProduction(strys, strpar, strexo)
    % function [fval_vec,strys] = 
    % setupExoYSteadyState(strys, strpar, strexo, x, x_start_vec_1,
    %                             x_start_vec_2)
    % finds capital stock vector to fulfill the static equations of the 
    % model
    % Inputs: 
    %   - x         [vector]     vector of initial values for the steady
    %                            state of the regional and sectoral capital
    %                            stock
    %   - strys     [structure]  structure containing all endogeonous 
    %                            variables of the model
    %   - strexo    [structure]  structure containing all exogeonous 
    %                            variables of the model    
    %   - strpar    [structure]  structure containing all parameters of the
    %                            model
    %
    % Output: 
    %   - fval_vec  [vector]     residuals of regional and sector specific 
    %                            for FOC of Households with respect to 
    %                            regional labour
    %   - strys     [structure]  see inputs
    %   - strexo    [structure]  see inputs
    for icosec = 1:strpar.inbsectors_p
        ssec = num2str(icosec);                  
        for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
            ssubsec = num2str(icosubsec);

            for icoreg = 1:strpar.inbregions_p
                sreg = num2str(icoreg);
                if strpar.(['etaI_' ssubsec '_p']) == 1
                    % subsectoral price level of primary production factors
                    strys.(['P_' ssubsec '_' sreg]) = ((strys.(['P_Q_' ssubsec '_' sreg])-strys.(['kappaE_' ssubsec '_' sreg])*strys.(['PE_' sreg])) / (strys.(['P_I_' ssubsec '_' sreg])/(strys.(['A_I_' ssubsec '_' sreg])*strpar.(['omegaQI_' ssubsec '_' sreg '_p'])))^(strpar.(['omegaQI_' ssubsec '_' sreg '_p'])))^(1/(1 - strpar.(['omegaQI_' ssubsec '_' sreg '_p']))) * (1 - strpar.(['omegaQI_' ssubsec '_' sreg '_p']));                    
                else
                    % subsectoral price level of primary production factors
                    strys.(['P_' ssubsec '_' sreg]) = (((strys.(['P_Q_' ssubsec '_' sreg])-strys.(['kappaE_' ssubsec '_' sreg])*strys.(['PE_' sreg]))^(1 - strpar.(['etaI_' ssubsec '_p'])) - strpar.(['omegaQI_' ssubsec '_' sreg '_p']) * (strys.(['P_I_' ssubsec '_' sreg])/strys.(['A_I_' ssubsec '_' sreg]))^(1 - strpar.(['etaI_' ssubsec '_p'])))/(1 - strpar.(['omegaQI_' ssubsec '_' sreg '_p'])))^(1/(1 - strpar.(['etaI_' ssubsec '_p'])));                    
                end
                if icosubsec >0%~= strpar.iSubsecFossil_p
                    if strpar.lTargetY_p == 1
                        % subsectoral gross vlaue added
                        strys.(['Y_' ssubsec '_' sreg]) = strpar.Y0_p .* strpar.(['phiY0_' ssubsec '_' sreg '_p']) / strpar.phiY_p * exp(strexo.(['exo_' ssubsec '_' sreg])) / strys.(['P_' ssubsec '_' sreg]);
                    elseif strpar.lTargetY_p == 2
                        strys.(['Y_' ssubsec '_' sreg]) = strpar.Y0_p .* strpar.(['phiY0_' ssubsec '_' sreg '_p']) / strpar.phiY_p * exp(strexo.(['exo_' ssubsec '_' sreg])) / strpar.(['P0_' ssubsec '_' sreg '_p']);
    
                    else
                        strys.(['Q_' ssubsec '_' sreg]) = strpar.(['Q0_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_' ssubsec '_' sreg]));
                    end
                else
                    strys.(['Y_' ssubsec '_' sreg]) = strpar.Y0_p .* strpar.(['phiY0_' ssubsec '_' sreg '_p']) / strpar.phiY_p * exp(strexo.(['exo_' ssubsec '_' sreg])) / strys.(['P_' ssubsec '_' sreg]);
                end

            end
        end
    end

    for icosec = 1:strpar.inbsectors_p
        ssec = num2str(icosec);       
        for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
            ssubsec = num2str(icosubsec);
            for icoreg = 1:strpar.inbregions_p
                sreg = num2str(icoreg);
                % labour 
                strys.(['N_' ssubsec '_' sreg]) = strpar.(['phiN0_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_N_' ssubsec '_' sreg])) * strpar.(['N0_' sreg '_p']);
                
                if icosubsec >0 %~= strpar.iSubsecFossil_p
                    % intermediate goods
                    if strpar.lTargetY_p == 1 || strpar.lTargetY_p == 2
                        strys.(['Q_I_' ssubsec '_' sreg])  = strys.(['A_I_' ssubsec '_' sreg])^((strpar.(['etaI_' ssubsec '_p'])-1)) * (strys.(['P_I_' ssubsec '_' sreg]) / strys.(['P_' ssubsec '_' sreg]))^(-strpar.(['etaI_' ssubsec '_p'])) * strpar.(['omegaQI_' ssubsec '_' sreg '_p']) / (1- strpar.(['omegaQI_' ssubsec '_' sreg '_p'])) * strys.(['Y_' ssubsec '_' sreg]); 
                    else
                        strys.(['Q_I_' ssubsec '_' sreg])  = strys.(['A_I_' ssubsec '_' sreg])^((strpar.(['etaI_' ssubsec '_p'])-1)) * (strys.(['P_I_' ssubsec '_' sreg]) / (strys.(['P_Q_' ssubsec '_' sreg])-strys.(['PE_' sreg]) * strys.(['kappaE_' ssubsec '_' sreg])))^(-strpar.(['etaI_' ssubsec '_p'])) * strpar.(['omegaQI_' ssubsec '_' sreg '_p']) * strys.(['Q_' ssubsec '_' sreg]); 
    
                        strys.(['Y_' ssubsec '_' sreg])  = (strys.(['P_' ssubsec '_' sreg]) / (strys.(['P_Q_' ssubsec '_' sreg])-strys.(['PE_' sreg]) * strys.(['kappaE_' ssubsec '_' sreg])))^(-strpar.(['etaI_' ssubsec '_p'])) * (1-strpar.(['omegaQI_' ssubsec '_' sreg '_p'])) * strys.(['Q_' ssubsec '_' sreg]); 
                    end
                else
                    strys.(['Q_I_' ssubsec '_' sreg])  = strys.(['A_I_' ssubsec '_' sreg])^((strpar.(['etaI_' ssubsec '_p'])-1)) * (strys.(['P_I_' ssubsec '_' sreg]) / (strys.(['P_Q_' ssubsec '_' sreg])-strys.(['PE_' sreg]) * strys.(['kappaE_' ssubsec '_' sreg])))^(-strpar.(['etaI_' ssubsec '_p'])) * strpar.(['omegaQI_' ssubsec '_' sreg '_p']) * strys.(['Q_' ssubsec '_' sreg]); 

                    strys.(['Y_' ssubsec '_' sreg])  = (strys.(['P_' ssubsec '_' sreg]) / (strys.(['P_Q_' ssubsec '_' sreg])-strys.(['PE_' sreg]) * strys.(['kappaE_' ssubsec '_' sreg])))^(-strpar.(['etaI_' ssubsec '_p'])) * (1-strpar.(['omegaQI_' ssubsec '_' sreg '_p'])) * strys.(['Q_' ssubsec '_' sreg]); 
                end
                

                tempnum = strys.(['Q_I_' ssubsec '_' sreg]) * strys.(['P_I_' ssubsec '_' sreg]) + strys.(['Y_' ssubsec '_' sreg]) * strys.(['P_' ssubsec '_' sreg]);
                strys.(['Q_' ssubsec '_' sreg]) = tempnum/(strys.(['P_Q_' ssubsec '_' sreg])-strys.(['PE_' sreg]) * strys.(['kappaE_' ssubsec '_' sreg]));
                
            end                      
        end
    end      
end


