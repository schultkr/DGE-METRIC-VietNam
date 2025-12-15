function [strys, strpar, strexo] = computeProductionFactorsAndOutput(strys, strpar, strexo)
%COMPUTEPRODUCTIONFACTORSANDOUTPUT Calculates productivity, capital, labor, and output for all sectors and regions
% calculate sectoral and regional production factors and output
    % Public capital stock from government investment
    strys.KG = strys.G / strpar.deltaKG_p;

    % Regional housing and population-based stocks
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);            
        if strpar.lEndogenousY_p == 0
            % Housing area is fixed per capita
            strys.(['H_' sreg]) = (strpar.(['H0_' sreg '_p']) + strexo.(['exo_H_' sreg])) * strys.(['PoP_' sreg]);
        else
            % House price is exogenously given
            strys.(['PH_' sreg]) = strpar.(['PH0_' sreg '_p']) * exp(strexo.(['exo_H_' sreg]));
        end
    end

    % Government expenditure on housing services
    strys.G_A_DH = strexo.exo_G_A_DH * strpar.Q0_p;

    for icosec = 1:strpar.inbsectors_p
        ssec = num2str(icosec);      
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);           


            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);       

                % subsectoral interat rate
                strys.(['r_' ssubsec '_' sreg]) = (1/(strpar.beta_p * exp(strexo.exo_beta)) - 1 + strpar.(['delta_' ssubsec '_' sreg '_p']))/(1 - strys.(['tauKH_' sreg]));                    
                rkgross = strys.(['r_' ssubsec '_' sreg]) * (1 + strys.(['tauKF_' ssubsec '_' sreg]));


                % auxiliary variable to define the degree of substitutability
                % between capital and labour in the sector
                rhotemp = ((strpar.(['etaNK_' ssubsec '_' sreg '_p'])-1)/strpar.(['etaNK_' ssubsec '_' sreg '_p']));


                if strpar.lEndogenousY_p == 1
                    % compute regional and sub-sectoral productivity 
                    if strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) == 1
                        strys.(['A_' ssubsec '_' sreg]) = strpar.(['A_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_' ssubsec '_' sreg])) * strys.KG^strpar.phiG_p;
                    end
                end

                if strpar.lEndogenousY_p == 1
                    % compute regional and sub-sectoral labour productivity 
                    strys.(['A_N_' ssubsec '_' sreg]) = strpar.(['A_N_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_N_' ssubsec '_' sreg]));
                end



                if strpar.lCalibration_p == 2 % Baseline / exogenous Y
                    if strpar.(['etaNK_' ssubsec '_' sreg '_p']) ~= 1
                        % compute regional and sub-sectoral productivity 
                        strys.(['A_' ssubsec '_' sreg]) = (rkgross / (strpar.(['alphaK_' ssubsec '_' sreg '_p'])^(1/ strpar.(['etaNK_' ssubsec '_' sreg '_p'])) *  (strys.(['A_K_' ssubsec '_' sreg]) * (1 - strys.(['D_' ssubsec '_' sreg])))^rhotemp * (strys.(['K_' ssubsec '_' sreg])/strys.(['Y_' ssubsec '_' sreg]))^(-1/strpar.(['etaNK_' ssubsec '_' sreg '_p']))))^(1/rhotemp);

                    else
                        % compute the capital stock
                        strys.(['K_' ssubsec '_' sreg]) = strpar.(['alphaK_' ssubsec '_' sreg '_p']) * strys.(['Y_' ssubsec '_' sreg]) / rkgross;

                        % compute the gross wage
                        wgross = strpar.(['alphaN_' ssubsec '_' sreg '_p']) / strpar.(['alphaK_' ssubsec '_' sreg '_p']) * strys.(['K_' ssubsec '_' sreg]) / (strys.(['LF_' sreg]) * strys.(['N_' ssubsec '_' sreg])) * rkgross * strys.(['P_' ssubsec '_' sreg]);

                        % compute auxiliary variable to compute
                        % productivity
                        temp = (rkgross/(strpar.(['alphaK_' ssubsec '_' sreg '_p']) * strys.(['A_K_' ssubsec '_' sreg])))^strpar.(['alphaK_' ssubsec '_' sreg '_p']) * ...
                               (wgross/(strpar.(['alphaN_' ssubsec '_' sreg '_p']) * strys.(['A_N_' ssubsec '_' sreg]) * (1 - strys.(['D_N_' ssubsec '_' sreg])))^strpar.(['alphaK_' ssubsec '_' sreg '_p']));

                        % compute subsectoral and regional productivity
                        strys.(['A_' ssubsec '_' sreg]) = strys.(['P_' ssubsec '_' sreg]) / temp;                        

                    end

                    % recompute the exogenous disturbances to productivity
                    % should be unneccary if everything is correct
                    if strpar.lEndogenousY_p == 1                       
                        strexo.(['exo_' ssubsec '_' sreg]) = log(strys.(['A_' ssubsec '_' sreg]) / (strys.KG^strpar.phiG_p * strpar.(['A_' ssubsec '_' sreg '_p'])));                        

                    else
                        if strpar.iSubsecFossil_p <0                       
                            strexo.(['exo_' ssubsec '_' sreg]) = log(strys.(['Y_' ssubsec '_' sreg]) .* strys.(['P_' ssubsec '_' sreg]) ./ (strpar.Y0_p .* strpar.(['phiY0_' ssubsec '_' sreg '_p'])/strpar.phiY_p));                        
                            %strexo.(['exo_' ssubsec '_' sreg]) = log(strys.(['Y_' ssubsec '_' sreg]) .* strpar.(['P0_' ssubsec '_' sreg '_p']) ./ (strpar.Y0_p .* strpar.(['phiY0_' ssubsec '_' sreg '_p'])/strpar.phiY_p));                        
                        else
                            if strpar.lTargetY_p == 1                       
                                strexo.(['exo_' ssubsec '_' sreg]) = log(strys.(['Y_' ssubsec '_' sreg]) .* strys.(['P_' ssubsec '_' sreg]) ./ (strpar.Y0_p .* strpar.(['phiY0_' ssubsec '_' sreg '_p'])/strpar.phiY_p));                        
                            elseif strpar.lTargetY_p == 2                      
                                strexo.(['exo_' ssubsec '_' sreg]) = log(strys.(['Y_' ssubsec '_' sreg]) .* strpar.(['P0_' ssubsec '_' sreg '_p']) ./ (strpar.Y0_p .* strpar.(['phiY0_' ssubsec '_' sreg '_p'])/strpar.phiY_p));                        
                            else
                                strexo.(['exo_' ssubsec '_' sreg]) = log(strys.(['Q_' ssubsec '_' sreg]) ./ strpar.(['Q0_' ssubsec '_' sreg '_p'])); 
                            end
                        end
                    end
                    % compute exogenous labour productivity
                    if strpar.(['etaNK_' ssubsec '_' sreg '_p']) ~= 1 % CES
                        temp1 = (strys.(['K_' ssubsec '_' sreg]) * rkgross^strpar.(['etaNK_' ssubsec '_' sreg '_p']) / (strpar.(['alphaK_' ssubsec '_' sreg '_p']) * strys.(['A_K_' ssubsec '_' sreg])^(strpar.(['etaNK_' ssubsec '_' sreg '_p'])-1) * (strys.(['A_' ssubsec '_' sreg]) * (1 - strys.(['D_' ssubsec '_' sreg])))^(strpar.(['etaNK_' ssubsec '_' sreg '_p']))))^rhotemp;

                        temp2 = strpar.(['alphaK_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * strys.(['A_K_' ssubsec '_' sreg])^rhotemp * strys.(['K_' ssubsec '_' sreg])^rhotemp;

                        temp = ((temp1 - temp2) / (strpar.(['alphaN_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * (strys.(['LF_' sreg]) .* strys.(['N_' ssubsec '_' sreg]))^rhotemp))^(1/rhotemp);                                    

                        strys.(['A_N_' ssubsec '_' sreg]) = temp / (1 - strys.(['D_N_' ssubsec '_' sreg]));

                        if strpar.lEndogenousY_p == 1
                            strexo.(['exo_N_' ssubsec '_' sreg]) = log(strys.(['A_N_' ssubsec '_' sreg])/strpar.(['A_N_' ssubsec '_' sreg '_p']));
                        end                        
                    else % Cobb-Douglas
                        if strpar.lEndogenousY_p == 1
                            strexo.(['exo_N_' ssubsec '_' sreg]) = log(strys.(['A_N_' ssubsec '_' sreg])/strpar.(['A_N_' ssubsec '_' sreg '_p']));

                        end
                    end      
                else  % Climate Change Scenarios / endogenous Y
                    if strpar.(['etaNK_' ssubsec '_' sreg '_p']) ~= 1
                        temp1 = (strys.(['K_' ssubsec '_' sreg]) * rkgross^strpar.(['etaNK_' ssubsec '_' sreg '_p']) / (strpar.(['alphaK_' ssubsec '_' sreg '_p']) * strys.(['A_K_' ssubsec '_' sreg])^(strpar.(['etaNK_' ssubsec '_' sreg '_p'])-1) * (strys.(['A_' ssubsec '_' sreg]) * (1 - strys.(['D_' ssubsec '_' sreg])))^(strpar.(['etaNK_' ssubsec '_' sreg '_p']))))^rhotemp;

                        temp2 = strpar.(['alphaK_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * strys.(['A_K_' ssubsec '_' sreg])^rhotemp * strys.(['K_' ssubsec '_' sreg])^rhotemp;

                        temp = ((temp1 - temp2) / (strpar.(['alphaN_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p']))))^(1/rhotemp);

                        if strpar.lEndogenousY_p == 1
                            % compute labour
                            strys.(['N_' ssubsec '_' sreg]) = temp / (strys.(['LF_' sreg]) * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['A_N_' ssubsec '_' sreg]));                        

                        else
                            % compute labour productivity
                            strys.(['A_N_' ssubsec '_' sreg]) = temp / (strys.(['LF_' sreg]) * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['N_' ssubsec '_' sreg]));

                        end
                    else
                        % compute labour demand
                        strys.(['N_' ssubsec '_' sreg]) = (strys.(['K_' ssubsec '_' sreg]) * rkgross / (strpar.(['alphaK_' ssubsec '_' sreg '_p']) * strys.(['A_' ssubsec '_' sreg]) *  (1 - strys.(['D_' ssubsec '_' sreg])) * (strys.(['A_K_' ssubsec '_' sreg]) * ...
                                                           strys.(['K_' ssubsec '_' sreg]))^strpar.(['alphaK_' ssubsec '_' sreg '_p'])))^(1/strpar.(['alphaN_' ssubsec '_' sreg '_p'])) / (strys.(['A_N_' ssubsec '_' sreg]) * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['LF_' sreg]));


                    end 
                end
                if strpar.(['etaNK_' ssubsec '_' sreg '_p']) ~= 1 % CES
                    if strpar.lEndogenousY_p == 1
                        % compute gross vlaue added
                        strys.(['Y_' ssubsec '_' sreg]) = strys.(['A_' ssubsec '_' sreg]) * (1 - strys.(['D_' ssubsec '_' sreg])) * (strpar.(['alphaK_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * (strys.(['A_K_' ssubsec '_' sreg]) * strys.(['K_' ssubsec '_' sreg]))^rhotemp + strpar.(['alphaN_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * (strys.(['LF_' sreg]) * strys.(['A_N_' ssubsec '_' sreg]) * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['N_' ssubsec '_' sreg]))^rhotemp)^(1/rhotemp);

                    else
                        % compute productivity
                        strys.(['A_' ssubsec '_' sreg]) = strys.(['Y_' ssubsec '_' sreg]) /((1 - strys.(['D_' ssubsec '_' sreg])) * (strpar.(['alphaK_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * (strys.(['A_K_' ssubsec '_' sreg]) * strys.(['K_' ssubsec '_' sreg]))^rhotemp + strpar.(['alphaN_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * (strys.(['LF_' sreg]) * strys.(['A_N_' ssubsec '_' sreg]) * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['N_' ssubsec '_' sreg]))^rhotemp)^(1/rhotemp));

                    end
                else
                    if strpar.lEndogenousY_p == 1
                        % compute gross vlaue added % Cobb Douglas
                        strys.(['Y_' ssubsec '_' sreg]) = strys.(['A_' ssubsec '_' sreg]) * (1 - strys.(['D_' ssubsec '_' sreg])) *  (strys.(['A_K_' ssubsec '_' sreg]) * strys.(['K_' ssubsec '_' sreg]))^strpar.(['alphaK_' ssubsec '_' sreg '_p']) * (strys.(['LF_' sreg]) * strys.(['A_N_' ssubsec '_' sreg]) * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['N_' ssubsec '_' sreg]))^strpar.(['alphaN_' ssubsec '_' sreg '_p']);

                    else
                        % compute productivity
                        strys.(['A_' ssubsec '_' sreg]) = strys.(['Y_' ssubsec '_' sreg]) / ((1 - strys.(['D_' ssubsec '_' sreg])) *  (strys.(['A_K_' ssubsec '_' sreg]) * strys.(['K_' ssubsec '_' sreg]))^strpar.(['alphaK_' ssubsec '_' sreg '_p']) * (strys.(['LF_' sreg]) * strys.(['A_N_' ssubsec '_' sreg]) * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['N_' ssubsec '_' sreg]))^strpar.(['alphaN_' ssubsec '_' sreg '_p']));

                    end
                end
                % compute substitutability between intermediate goods and
                % gross value added
                rhotemp = (strpar.(['etaI_' ssubsec '_p']) - 1)/strpar.(['etaI_' ssubsec '_p']);

                % compute outputs
                if strpar.(['etaI_' ssubsec '_p']) ~= 1
                    strys.(['Q_' ssubsec '_' sreg]) = (strpar.(['omegaQI_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaI_' ssubsec '_p'])) * (strys.(['A_I_' ssubsec '_' sreg]) * strys.(['Q_I_' ssubsec '_' sreg]))^rhotemp + ...
                                                (1 - strpar.(['omegaQI_' ssubsec '_' sreg '_p']))^(1/strpar.(['etaI_' ssubsec '_p'])) * strys.(['Y_' ssubsec '_' sreg])^rhotemp)^(1/rhotemp);
                else
                    strys.(['Q_' ssubsec '_' sreg]) = strys.(['A_I_' ssubsec '_' sreg]) * strys.(['Q_I_' ssubsec '_' sreg])^strpar.(['omegaQI_' ssubsec '_' sreg '_p']) * strys.(['Y_' ssubsec '_' sreg])^(1 - strpar.(['omegaQI_' ssubsec '_' sreg '_p']));                     
                end

                strys.(['E_' ssubsec '_' sreg]) = strys.(['kappaE_' ssubsec '_' sreg]) * strys.(['Q_' ssubsec '_' sreg]);
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);
                    PAgrosstemp = strys.(['P_A_' ssecm '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strys.(['sF_' sreg]) * exp(strexo.(['exo_EI_' ssubsec '_' sreg '_' ssecm])) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]);
                    strys.(['Q_I_' ssubsec '_' sreg '_' ssecm]) = strpar.(['omegaQI_' ssubsec '_' sreg '_' ssecm '_p']) * strys.(['A_I_' ssubsec '_' sreg '_' ssecm])^(strpar.(['etaIA_' ssubsec '_p'])-1) * (PAgrosstemp/strys.(['P_I_' ssubsec '_' sreg]))^(-strpar.(['etaIA_' ssubsec '_p'])) .* strys.(['Q_I_' ssubsec '_' sreg]);                     
                    strys.(['E_I_' ssubsec '_' sreg '_' ssecm]) = strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strys.(['sF_' sreg])  * exp(strexo.(['exo_EI_' ssubsec '_' sreg '_' ssecm])) * strys.(['Q_I_' ssubsec '_' sreg '_' ssecm]);
                end


                if strpar.lCalibration_p == 2                   
                    % compute exports
                    strys.(['X_' ssubsec '_' sreg]) = strys.(['Q_' ssubsec '_' sreg]) * strys.(['D_X_' ssubsec '_' sreg]);
                else
                    % compute export share
                    strys.(['D_X_' ssubsec '_' sreg]) = strys.(['X_' ssubsec '_' sreg]) / strys.(['Q_' ssubsec '_' sreg]);
                end
            end
        end
    end
end