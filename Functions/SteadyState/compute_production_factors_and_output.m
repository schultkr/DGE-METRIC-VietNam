function [strys, strpar, strexo] = compute_production_factors_and_output(strys, strpar, strexo)
%COMPUTE_PRODUCTION_FACTORS_AND_OUTPUT Calculates productivity, capital, labor, and output for all sectors and regions
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
                % P_INV/P_K ratio scales r_H: when investment goods are priced off a
                % different sector (lCapGoodsSecPrice=1), HH needs a higher nominal return.
                PI_PK_ratio = strys.(['P_INV_' ssubsec '_' sreg]) / strys.(['P_K_' ssubsec '_' sreg]);
                strys.(['r_H_' ssubsec '_' sreg]) = PI_PK_ratio * (1/(strpar.beta_p * exp(strexo.exo_beta)) - 1 + strpar.(['delta_' ssubsec '_' sreg '_p']))/(1 - strys.(['tauKH_' ssubsec '_' sreg])) + strys.(['wedgeKE_' ssubsec '_' sreg]);
                strys.(['r_FDI_' ssubsec '_' sreg]) = (strpar.rf0_p + strexo.(['exo_r_FDI_' ssubsec '_' sreg]));
                strys.(['r_G_' ssubsec '_' sreg]) = PI_PK_ratio* (strpar.rf0_p + strexo.(['exo_r_G_' ssubsec '_' sreg]));
                    
                % When exo_lKRGTarget == 1, r_G_ is backed out later after K_G_ is known.


                % auxiliary variable to define the degree of substitutability
                % between capital and labour in the sector
                rhotemp = ((strpar.(['etaNK_' ssubsec '_' sreg '_p'])-1)/strpar.(['etaNK_' ssubsec '_' sreg '_p']));


                if strpar.lEndogenousY_p == 1
                    % compute regional and sub-sectoral productivity 
                    if strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) == 1
                        strys.(['A_' ssubsec '_' sreg]) = strpar.(['A_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_' ssubsec '_' sreg])) * strys.KG^strpar.phiG_p;
                    end
                end

                if strpar.lEndogenousN_p == 1
                    % compute regional and sub-sectoral labour productivity 
                    strys.(['A_N_' ssubsec '_' sreg]) = strpar.(['A_N_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_N_' ssubsec '_' sreg]));
                end
                


                if strpar.lCalibration_p == 2 % Baseline / exogenous Y
                    % strys = set_baseline_public_capital(strys, strpar, strexo, ssubsec, sreg);
                    strys = set_scenario_public_capital(strys, strpar, strexo, ssubsec, sreg);
                    strys = set_scenario_fdi_capital(strys, strpar, strexo, ssubsec, sreg);

                    if strpar.(['etaNK_' ssubsec '_' sreg '_p']) ~= 1

                        % Floor K_H at zero: K_G may fully crowd out household capital.
                        % When K_G >= K, K_H = 0, I_H = 0, and total K adjusts to K_G.
                        strys.(['K_H_' ssubsec '_' sreg]) = max(0, strys.(['K_' ssubsec '_' sreg]) - strys.(['K_G_' ssubsec '_' sreg]) - strys.(['K_FDI_' ssubsec '_' sreg]));

                        strys.(['Kserv_' ssubsec '_' sreg]) = strys.(['K_' ssubsec '_' sreg]) * strys.(['u_K_' ssubsec '_' sreg]);
                        strys.(['I_H_' ssubsec '_' sreg]) = strys.(['K_H_' ssubsec '_' sreg]) * strpar.(['delta_' ssubsec '_' sreg '_p']) + strys.(['D_K_' ssubsec '_' sreg]) * (strys.(['K_H_' ssubsec '_' sreg]) > 0);
                        strys.(['ILR_' ssubsec '_' sreg]) = strys.(['I_H_' ssubsec '_' sreg]);
                        strys.(['r_F_' ssubsec '_' sreg]) = (strys.(['r_H_' ssubsec '_' sreg]) * strys.(['K_H_' ssubsec '_' sreg]) + strys.(['r_G_' ssubsec '_' sreg]) * strys.(['K_G_' ssubsec '_' sreg]) + strys.(['r_FDI_' ssubsec '_' sreg]) * strys.(['K_FDI_' ssubsec '_' sreg])) / strys.(['K_' ssubsec '_' sreg]);

                        rkgross    = strys.(['r_F_' ssubsec '_' sreg]) * (1 + strys.(['tauKF_' ssubsec '_' sreg]));
                        rkgross_PK = rkgross * exp(strexo.(['exo_P_K_' ssubsec '_' sreg]));

                        % compute regional and sub-sectoral productivity
                        strys.(['A_' ssubsec '_' sreg]) = (rkgross_PK / (strpar.(['alphaK_' ssubsec '_' sreg '_p'])^(1/ strpar.(['etaNK_' ssubsec '_' sreg '_p'])) *  (strys.(['A_K_' ssubsec '_' sreg]) * (1 - strys.(['D_' ssubsec '_' sreg])))^rhotemp * (strys.(['K_' ssubsec '_' sreg])/strys.(['Y_' ssubsec '_' sreg]))^(-1/strpar.(['etaNK_' ssubsec '_' sreg '_p']))))^(1/rhotemp);

                    else
                        % compute the capital stock
                        capexp = strpar.(['alphaK_' ssubsec '_' sreg '_p']) * strys.(['Y_' ssubsec '_' sreg]);
                        capexo = 0;%strexo.(['exo_KTarget_' ssubsec '_' sreg]) * strpar.Y0_p/strpar.(['P0_' ssubsec '_' sreg '_p'])/strpar.(['delta_' ssubsec '_' sreg '_p']);
                        capnom = capexp / ((1 + strys.(['tauKF_' ssubsec '_' sreg]))) + capexo * (strys.(['r_G_' ssubsec '_' sreg]) - strys.(['r_H_' ssubsec '_' sreg]));
                        if strexo.(['exo_lKRGTarget_' ssubsec '_' sreg]) == 0
                            strys = set_baseline_public_capital_from_capnom(strys, strpar, strexo, ssubsec, sreg, capnom);
                        end
                        strys.(['Kserv_' ssubsec '_' sreg]) = strys.(['K_' ssubsec '_' sreg]) * strys.(['u_K_' ssubsec '_' sreg]);
                        % strys = set_scenario_public_capital(strys, strpar, strexo, ssubsec, sreg);
                        % strys.(['I_G_' ssubsec '_' sreg]) = strys.(['s_G_' ssubsec '_' sreg])*strpar.Y0_p/strys.(['P_K_' ssubsec '_' sreg])^0;
                        % strys.(['K_G_' ssubsec '_' sreg]) = strys.(['I_G_' ssubsec '_' sreg])/strpar.(['delta_' ssubsec '_' sreg '_p']);
                        strys.(['K_H_' ssubsec '_' sreg]) = strys.(['K_' ssubsec '_' sreg]) - strys.(['K_G_' ssubsec '_' sreg]) - strys.(['K_FDI_' ssubsec '_' sreg]);
                        strys.(['I_H_' ssubsec '_' sreg]) = strys.(['K_H_' ssubsec '_' sreg]) * strpar.(['delta_' ssubsec '_' sreg '_p']) + strys.(['D_K_' ssubsec '_' sreg]) * (strys.(['K_H_' ssubsec '_' sreg]) > 0);
                        strys.(['ILR_' ssubsec '_' sreg]) = strys.(['I_H_' ssubsec '_' sreg]);
                        strys.(['r_F_' ssubsec '_' sreg]) = (strys.(['r_H_' ssubsec '_' sreg]) * strys.(['K_H_' ssubsec '_' sreg]) + strys.(['r_G_' ssubsec '_' sreg]) * strys.(['K_G_' ssubsec '_' sreg]) + strys.(['r_FDI_' ssubsec '_' sreg]) * strys.(['K_FDI_' ssubsec '_' sreg])) / strys.(['K_' ssubsec '_' sreg]);
                        rkgross    = strys.(['r_F_' ssubsec '_' sreg]) * (1 + strys.(['tauKF_' ssubsec '_' sreg]));
                        rkgross_PK = rkgross * exp(strexo.(['exo_P_K_' ssubsec '_' sreg]));
                        % wgross uses rkgross*P_K which already carries exp(exo_P_K) via P_K
                        wgross = strpar.(['alphaN_' ssubsec '_' sreg '_p']) / strpar.(['alphaK_' ssubsec '_' sreg '_p']) * strys.(['K_' ssubsec '_' sreg]) / (strys.(['LF_' sreg]) * strys.(['N_' ssubsec '_' sreg])) * rkgross * strys.(['P_K_' ssubsec '_' sreg]);

                        % compute auxiliary variable to compute
                        % productivity
                        temp = (rkgross_PK/(strpar.(['alphaK_' ssubsec '_' sreg '_p']) * strys.(['A_K_' ssubsec '_' sreg])))^strpar.(['alphaK_' ssubsec '_' sreg '_p']) * ...
                               (wgross/(strpar.(['alphaN_' ssubsec '_' sreg '_p']) * strys.(['A_N_' ssubsec '_' sreg])^1 * (1 - strys.(['D_N_' ssubsec '_' sreg])))^strpar.(['alphaK_' ssubsec '_' sreg '_p']));

                        % compute subsectoral and regional productivity
                        strys.(['A_' ssubsec '_' sreg]) = strys.(['P_' ssubsec '_' sreg]) / temp;                        

                    end

                    % recompute the exogenous disturbances to productivity
                    % should be unneccary if everything is correct
                    if strpar.lEndogenousY_p == 1                       
                        strexo.(['exo_' ssubsec '_' sreg]) = log(strys.(['A_' ssubsec '_' sreg]) / (strys.KG^strpar.phiG_p * strpar.(['A_' ssubsec '_' sreg '_p'])));                        
                        % strexo.(['exo_A_' ssubsec '_' sreg]) = log(strys.(['A_' ssubsec '_' sreg]) / (strys.KG^strpar.phiG_p * strpar.(['A_' ssubsec '_' sreg '_p'])));                        
                    else
                        if strpar.iSubsecFossil_p <0
                            strexo.(['exo_' ssubsec '_' sreg]) = log(strys.(['Y_' ssubsec '_' sreg]) .* strys.(['P_' ssubsec '_' sreg]) ./ (strpar.(['P0_' ssubsec '_' sreg '_p']) .* strpar.(['Y0_' ssubsec '_' sreg '_p'])));
                        else
                            if strpar.lTargetY_p == 1
                                strexo.(['exo_' ssubsec '_' sreg]) = log(strys.(['Y_' ssubsec '_' sreg]) .* strys.(['P_' ssubsec '_' sreg]) ./ (strpar.(['P0_' ssubsec '_' sreg '_p']) .* strpar.(['Y0_' ssubsec '_' sreg '_p'])));
                            elseif strpar.lTargetY_p == 2
                                strexo.(['exo_' ssubsec '_' sreg]) = log(strys.(['Y_' ssubsec '_' sreg]) ./ strpar.(['Y0_' ssubsec '_' sreg '_p']));
                            else
                                strexo.(['exo_' ssubsec '_' sreg]) = log(strys.(['Q_' ssubsec '_' sreg]) ./ strpar.(['Q0_' ssubsec '_' sreg '_p']));
                            end
                        end
                        % strexo.(['exo_A_' ssubsec '_' sreg]) = log(strys.(['A_' ssubsec '_' sreg]) / (strys.KG^strpar.phiG_p * strpar.(['A_' ssubsec '_' sreg '_p'])));                        
                    end
                    % compute exogenous labour productivity
                    if strpar.(['etaNK_' ssubsec '_' sreg '_p']) ~= 1 % CES

                        if strpar.lEndogenousN_p == 1

                            temp1 = (strys.(['Kserv_' ssubsec '_' sreg]) * rkgross_PK^strpar.(['etaNK_' ssubsec '_' sreg '_p']) / (strpar.(['alphaK_' ssubsec '_' sreg '_p']) * strys.(['A_K_' ssubsec '_' sreg])^(strpar.(['etaNK_' ssubsec '_' sreg '_p'])-1) * (strys.(['A_' ssubsec '_' sreg]) * (1 - strys.(['D_' ssubsec '_' sreg])))^(strpar.(['etaNK_' ssubsec '_' sreg '_p']))))^rhotemp;

                            temp2 = strpar.(['alphaK_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * strys.(['A_K_' ssubsec '_' sreg])^rhotemp * strys.(['Kserv_' ssubsec '_' sreg])^rhotemp;

                            temp = ((temp1 - temp2) / (strpar.(['alphaN_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p']))))^(1/rhotemp);
                            % compute labour
                            strys.(['N_' ssubsec '_' sreg]) = temp / (strys.(['LF_' sreg]) * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['A_N_' ssubsec '_' sreg]));

                        else
                            temp1 = (strys.(['Kserv_' ssubsec '_' sreg]) * rkgross_PK^strpar.(['etaNK_' ssubsec '_' sreg '_p']) / (strpar.(['alphaK_' ssubsec '_' sreg '_p']) * strys.(['A_K_' ssubsec '_' sreg])^(strpar.(['etaNK_' ssubsec '_' sreg '_p'])-1) * (strys.(['A_' ssubsec '_' sreg]) * (1 - strys.(['D_' ssubsec '_' sreg])))^(strpar.(['etaNK_' ssubsec '_' sreg '_p']))))^rhotemp;

                            temp2 = strpar.(['alphaK_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * strys.(['A_K_' ssubsec '_' sreg])^rhotemp * strys.(['Kserv_' ssubsec '_' sreg])^rhotemp;

                            temp = ((temp1 - temp2) / (strpar.(['alphaN_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * (strys.(['LF_' sreg]) .* strys.(['N_' ssubsec '_' sreg]))^rhotemp))^(1/rhotemp);

                            strys.(['A_N_' ssubsec '_' sreg]) = temp / (1 - strys.(['D_N_' ssubsec '_' sreg]));

                        end

                        if strpar.lEndogenousN_p == 1
                            strexo.(['exo_N_' ssubsec '_' sreg]) = log(strys.(['A_N_' ssubsec '_' sreg])^1/strpar.(['A_N_' ssubsec '_' sreg '_p']));
                        end                        
                    else % Cobb-Douglas
                        if strpar.lEndogenousN_p == 1
                            strexo.(['exo_N_' ssubsec '_' sreg]) = log(strys.(['A_N_' ssubsec '_' sreg])^1/strpar.(['A_N_' ssubsec '_' sreg '_p']));

                        end
                    end      
                else  % Climate Change Scenarios / endogenous Y
                        strys = set_scenario_public_capital(strys, strpar, strexo, ssubsec, sreg);
                        % strys.(['I_G_' ssubsec '_' sreg]) = strys.(['s_G_' ssubsec '_' sreg])*strpar.Y0_p / strys.(['P_K_' ssubsec '_' sreg])^0;
                        % strys.(['K_G_' ssubsec '_' sreg]) = strys.(['I_G_' ssubsec '_' sreg])/strpar.(['delta_' ssubsec '_' sreg '_p']);
                        if strexo.(['exo_lKRGTarget_' ssubsec '_' sreg]) == 1
                            strys = set_K_target_and_backout_rG(strys, strpar, strexo, ssubsec, sreg);
                            % Keep ExoSubsec_13 consistent: r_G_ = rf0_p + exo_r_G_
                            strexo.(['exo_r_G_' ssubsec '_' sreg]) = strys.(['r_G_' ssubsec '_' sreg]) - strpar.rf0_p;
                        end
                        strys.(['K_H_' ssubsec '_' sreg]) = max(0, strys.(['K_' ssubsec '_' sreg]) - strys.(['K_G_' ssubsec '_' sreg]) - strys.(['K_FDI_' ssubsec '_' sreg]));
                        if strys.(['K_H_' ssubsec '_' sreg]) == 0
                            strys.(['K_' ssubsec '_' sreg]) = strys.(['K_G_' ssubsec '_' sreg]) + strys.(['K_FDI_' ssubsec '_' sreg]);
                        end
                        strys.(['Kserv_' ssubsec '_' sreg]) = strys.(['K_' ssubsec '_' sreg]) * strys.(['u_K_' ssubsec '_' sreg]);
                        strys.(['I_H_' ssubsec '_' sreg]) = strys.(['K_H_' ssubsec '_' sreg]) * strpar.(['delta_' ssubsec '_' sreg '_p']) + strys.(['D_K_' ssubsec '_' sreg]) * (strys.(['K_H_' ssubsec '_' sreg]) > 0);
                        strys.(['ILR_' ssubsec '_' sreg]) = strys.(['I_H_' ssubsec '_' sreg]);
                        strys.(['r_F_' ssubsec '_' sreg]) = (strys.(['r_H_' ssubsec '_' sreg]) * strys.(['K_H_' ssubsec '_' sreg]) + strys.(['r_G_' ssubsec '_' sreg]) * strys.(['K_G_' ssubsec '_' sreg]) + strys.(['r_FDI_' ssubsec '_' sreg]) * strys.(['K_FDI_' ssubsec '_' sreg])) / strys.(['K_' ssubsec '_' sreg]);
                
                        rkgross    = strys.(['r_F_' ssubsec '_' sreg]) * (1 + strys.(['tauKF_' ssubsec '_' sreg]));
                        rkgross_PK = rkgross * exp(strexo.(['exo_P_K_' ssubsec '_' sreg]));


                    if strpar.(['etaNK_' ssubsec '_' sreg '_p']) ~= 1
                        temp1 = (strys.(['Kserv_' ssubsec '_' sreg]) * rkgross_PK^strpar.(['etaNK_' ssubsec '_' sreg '_p']) / (strpar.(['alphaK_' ssubsec '_' sreg '_p']) * strys.(['A_K_' ssubsec '_' sreg])^(strpar.(['etaNK_' ssubsec '_' sreg '_p'])-1) * (strys.(['A_' ssubsec '_' sreg]) * (1 - strys.(['D_' ssubsec '_' sreg])))^(strpar.(['etaNK_' ssubsec '_' sreg '_p']))))^rhotemp;

                        temp2 = strpar.(['alphaK_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * strys.(['A_K_' ssubsec '_' sreg])^rhotemp * strys.(['Kserv_' ssubsec '_' sreg])^rhotemp;

                        temp = ((temp1 - temp2) / (strpar.(['alphaN_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p']))))^(1/rhotemp);

                        if strpar.lEndogenousN_p == 1
                            % compute labour
                            strys.(['N_' ssubsec '_' sreg]) = temp / (strys.(['LF_' sreg]) * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['A_N_' ssubsec '_' sreg])^1);                        

                        else
                            % compute labour productivity
                            strys.(['A_N_' ssubsec '_' sreg]) = temp / (strys.(['LF_' sreg]) * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['N_' ssubsec '_' sreg]));

                        end
                    else
                        % compute labour demand
                        strys.(['N_' ssubsec '_' sreg]) = (strys.(['Kserv_' ssubsec '_' sreg]) * rkgross_PK / (strpar.(['alphaK_' ssubsec '_' sreg '_p']) * strys.(['A_' ssubsec '_' sreg]) *  (1 - strys.(['D_' ssubsec '_' sreg])) * (strys.(['A_K_' ssubsec '_' sreg]) * ...
                                                           strys.(['Kserv_' ssubsec '_' sreg]))^strpar.(['alphaK_' ssubsec '_' sreg '_p'])))^(1/strpar.(['alphaN_' ssubsec '_' sreg '_p'])) / (strys.(['A_N_' ssubsec '_' sreg]) * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['LF_' sreg]));


                    end 
                end
                if strpar.(['etaNK_' ssubsec '_' sreg '_p']) ~= 1 % CES
                    if strpar.lEndogenousY_p == 1
                        % compute gross vlaue added
                        strys.(['Y_' ssubsec '_' sreg]) = strys.(['A_' ssubsec '_' sreg]) * (1 - strys.(['D_' ssubsec '_' sreg])) * (strpar.(['alphaK_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * (strys.(['A_K_' ssubsec '_' sreg]) * strys.(['Kserv_' ssubsec '_' sreg]))^rhotemp + strpar.(['alphaN_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * (strys.(['LF_' sreg]) * strys.(['A_N_' ssubsec '_' sreg])^1 * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['N_' ssubsec '_' sreg]))^rhotemp)^(1/rhotemp);

                    else
                        % compute productivity
                        strys.(['A_' ssubsec '_' sreg]) = strys.(['Y_' ssubsec '_' sreg]) /((1 - strys.(['D_' ssubsec '_' sreg])) * (strpar.(['alphaK_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * (strys.(['A_K_' ssubsec '_' sreg]) * strys.(['Kserv_' ssubsec '_' sreg]))^rhotemp + strpar.(['alphaN_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaNK_' ssubsec '_' sreg '_p'])) * (strys.(['LF_' sreg]) * strys.(['A_N_' ssubsec '_' sreg])^1 * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['N_' ssubsec '_' sreg]))^rhotemp)^(1/rhotemp));

                    end
                else
                    if strpar.lEndogenousY_p == 1
                        % compute gross vlaue added % Cobb Douglas
                        strys.(['Y_' ssubsec '_' sreg]) = strys.(['A_' ssubsec '_' sreg]) * (1 - strys.(['D_' ssubsec '_' sreg])) *  (strys.(['A_K_' ssubsec '_' sreg]) * strys.(['Kserv_' ssubsec '_' sreg]))^strpar.(['alphaK_' ssubsec '_' sreg '_p']) * (strys.(['LF_' sreg]) * strys.(['A_N_' ssubsec '_' sreg])^1 * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['N_' ssubsec '_' sreg]))^strpar.(['alphaN_' ssubsec '_' sreg '_p']);

                    else
                        % compute productivity
                        strys.(['A_' ssubsec '_' sreg]) = strys.(['Y_' ssubsec '_' sreg]) / ((1 - strys.(['D_' ssubsec '_' sreg])) *  (strys.(['A_K_' ssubsec '_' sreg]) * strys.(['Kserv_' ssubsec '_' sreg]))^strpar.(['alphaK_' ssubsec '_' sreg '_p']) * (strys.(['LF_' sreg]) * strys.(['A_N_' ssubsec '_' sreg])^1 * (1 - strys.(['D_N_' ssubsec '_' sreg])) * strys.(['N_' ssubsec '_' sreg]))^strpar.(['alphaN_' ssubsec '_' sreg '_p']));

                    end
                end
                % strexo.(['exo_A_' ssubsec '_' sreg]) = log(strys.(['A_' ssubsec '_' sreg]) / (strys.KG^strpar.phiG_p * strpar.(['A_' ssubsec '_' sreg '_p'])));                        
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
                
                strys.(['E_NOETS_' ssubsec '_' sreg]) = strys.(['kappaE_NOETS_' ssubsec '_' sreg]) * strys.(['Q_' ssubsec '_' sreg]);
                
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
                strys.(['p_' ssubsec '_' sreg]) = log(strys.(['P_' ssubsec '_' sreg]));
                strys.(['rlog_H_' ssubsec '_' sreg]) = log(strys.(['r_H_' ssubsec '_' sreg]));
                strys.(['mu_' ssubsec '_' sreg]) = exp(strexo.(['exo_mu_' ssubsec '_' sreg]));
                strys.(['omegaI_' ssubsec '_' sreg]) = 1;
                
                % When K-target is ON, K_FDI_, I_FDI_, r_FDI_ were set by set_K_target_and_backout_rG.
                    strys.(['I_' ssubsec '_' sreg]) = strys.(['I_H_' ssubsec '_' sreg]) + strys.(['I_FDI_' ssubsec '_' sreg]);

                if strpar.lCalibration_p == 1
                    strpar.(['K0_' ssubsec '_' sreg '_p']) = strys.(['K_' ssubsec '_' sreg]);
                    strpar.(['Y0_' ssubsec '_' sreg '_p']) = strys.(['Y_' ssubsec '_' sreg]);
                end
            end
        end
    end
end

function strys = set_baseline_public_capital(strys, strpar, strexo, ssubsec, sreg)
    stemp = [ssubsec '_' sreg];
    phiG = get_effective_phiG(strpar, strexo, stemp, true);
    kGScale = exp(strexo.(['exo_K_G_' stemp]));
    delta = strpar.(['delta_' stemp '_p']);
    dK = strys.(['D_K_' stemp]);

    strys.(['K_G_' stemp]) = phiG * kGScale * strys.(['K_' stemp]);
    strys.(['I_G_' stemp]) = delta * strys.(['K_G_' stemp]) - phiG * dK;
end

function strys = set_baseline_public_capital_from_capnom(strys, strpar, strexo, ssubsec, sreg, capnom)
    stemp = [ssubsec '_' sreg];
    phiG = get_effective_phiG(strpar, strexo, stemp, true);
    kGScale = exp(strexo.(['exo_K_G_' stemp]));
    rH = strys.(['r_H_' stemp]);
    rG = strys.(['r_G_' stemp]);
    rFDI = strys.(['r_FDI_' stemp]);
    % denom = (1 - phiG * kGScale) * rH + (phiG * kGScale) * rG;
    % 
    % if denom > 0
    %     strys.(['K_' stemp]) = capnom / denom;
    % end
    % 
    % strys = set_baseline_public_capital(strys, strpar, strexo, ssubsec, sreg);
    strys = set_scenario_public_capital(strys, strpar, strexo, ssubsec, sreg);
    strys = set_scenario_fdi_capital(strys, strpar, strexo, ssubsec, sreg);
    strys.(['K_H_' stemp]) = max(0, capnom - strys.(['K_G_' stemp])  * rG - strys.(['K_FDI_' stemp]) * rFDI)/(rH);
    strys.(['K_' stemp]) = strys.(['K_H_' stemp]) + strys.(['K_G_' stemp]) + strys.(['K_FDI_' stemp]);
end

function strys = set_scenario_public_capital(strys, strpar, strexo, ssubsec, sreg)
    stemp = [ssubsec '_' sreg];
    phiG  = get_effective_phiG(strpar, strexo, stemp, false);
    delta = strpar.(['delta_' stemp '_p']);
    dK    = strys.(['D_K_' stemp]);

    if isfield(strexo, ['exo_lIGShare_' stemp]) && strexo.(['exo_lIGShare_' stemp]) == 1
        % Share mode: K_G is a fixed fraction of total K
        strys.(['K_G_' stemp]) = strexo.(['exo_sIGShare_' stemp]) * strys.(['K_' stemp]);
    else
        % Absolute mode (default): phiG calibrated × baseline K0 × log multiplier
        strys.(['K_G_' stemp]) = strpar.(['phiG_' stemp '_p']) * strpar.(['K0_' stemp '_p']) * exp(strexo.(['exo_K_G_' stemp]));
    end
    strys.(['I_G_' stemp]) = delta * strys.(['K_G_' stemp]) - phiG * dK;
end

function strys = set_scenario_fdi_capital(strys, strpar, strexo, ssubsec, sreg)
    stemp = [ssubsec '_' sreg];
    phiG  = get_effective_phiG(strpar, strexo, stemp, false);
    delta = strpar.(['delta_' stemp '_p']);
    dK    = strys.(['D_K_' stemp]);

    if strexo.(['exo_lFDIShare_' stemp]) == 1
        % Share mode: K_G is a fixed fraction of total K
        strys.(['K_FDI_' stemp]) = strexo.(['exo_sFDIShare_' stemp]) * strys.(['K_' stemp]);
    else
        % Absolute mode (default): phiG calibrated × baseline K0 × log multiplier
        strys.(['I_FDI_' stemp]) = strexo.(['exo_I_FDI_' stemp]) * strpar.Y0_p / strys.(['P_INV_' stemp]);
        strys.(['K_FDI_' stemp]) = 1/strpar.(['delta_' stemp '_p']) * strys.(['I_FDI_' stemp]);
    end
    strys.(['I_FDI_' stemp]) = delta * strys.(['K_FDI_' stemp]);
end

function phiG = get_effective_phiG(strpar, strexo, stemp, useExoPhiG)
    phiG = strpar.(['phiG_' stemp '_p']);
    if useExoPhiG
        exoField = ['exo_phiG_' stemp];
        if isfield(strexo, exoField)
            phiG = phiG * exp(strexo.(exoField));
        end
    end
    phiG = min(1, max(0, phiG));
end
