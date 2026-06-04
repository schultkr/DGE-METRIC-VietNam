function strys = compute_regional_price_indexes(strys, strpar, strexo)
    %COMPUTE_REGIONAL_PRICE_INDEXES Computes regional price indices for production, imports, and final demand.

    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strys.(['P_Q_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['P_Q_' sreg]) = strys.(['P_Q_' sreg]) + strpar.(['D_X_'  ssubsec '_' sreg '_p']) * exp(strexo.(['exo_X_' ssubsec '_' sreg])) * strys.(['P_Q_' ssubsec '_' sreg])^(1-strpar.etaX_p);
            end
        end
        strys.(['P_Q_' sreg]) = strys.(['P_Q_' sreg])^(1/(1-strpar.etaX_p));    
    end    
    
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        if strpar.etaM_p == 1
            % aggregate sector production
            strys.(['P_F_' sreg])  = 1;
        else
            % aggregate sector production
            strys.(['P_F_' sreg])  = 0;            
        end        
        
        
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec); 
            if strpar.(['etaQA_' ssec '_p']) == 1
                % aggregate sector production
                strys.(['P_A_' ssec '_' sreg])  = 1;
                % import prices
                strys.(['P_M_A_' ssec '_' sreg])  = 1;
            else
                % aggregate sector production
                strys.(['P_A_' ssec '_' sreg])  = 0;                            
                
                % import prices
                strys.(['P_M_A_' ssec '_' sreg])  = 0;            
            end
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);               
                
                if strpar.(['etaQ_' ssubsec '_p']) == 1
                    strys.(['P_D_' ssubsec '_' sreg]) = 1;
                else
                    strys.(['P_D_' ssubsec '_' sreg]) = 0;                        
                end
                for icoregm = 1:strpar.inbregions_p
                    sregm = num2str(icoregm); 
                    if strpar.(['etaQ_' ssubsec '_p']) == 1
                        strys.(['P_D_' ssubsec '_' sreg]) = strys.(['P_D_' ssubsec '_' sreg]) * (strys.(['P_Q_' ssubsec '_' sregm])/strpar.(['omegaQ_' ssubsec '_' sreg '_' sregm '_p']))^strpar.(['omegaQ_' ssubsec '_' sreg '_' sregm '_p']);
                    else
                        strys.(['P_D_' ssubsec '_' sreg]) = strys.(['P_D_' ssubsec '_' sreg]) + strpar.(['omegaQ_' ssubsec '_' sreg '_' sregm '_p']) * (strys.(['P_Q_' ssubsec '_' sregm]))^(1 - strpar.(['etaQ_' ssubsec '_p']));                        
                    end
                end
                if strpar.(['etaQ_' ssubsec '_p']) == 1
                    strys.(['P_D_' ssubsec '_' sreg]) = strys.(['P_D_' ssubsec '_' sreg]) * (strys.(['P_M_' ssubsec])/strpar.(['omegaM_' ssubsec '_' sreg '_p']))^strpar.(['omegaM_' ssubsec '_' sreg '_p']);
                else
                    strys.(['P_D_' ssubsec '_' sreg]) = strys.(['P_D_' ssubsec '_' sreg]) + strpar.(['omegaM_' ssubsec '_' sreg '_p']) * (strys.(['P_M_' ssubsec]))^(1 - strpar.(['etaQ_' ssubsec '_p']));                        
                    strys.(['P_D_' ssubsec '_' sreg]) = strys.(['P_D_' ssubsec '_' sreg])^(1 / (1 - strpar.(['etaQ_' ssubsec '_p'])));                        
                end


                if strpar.(['etaQA_' ssec '_p']) == 1
                    strys.(['P_A_' ssec '_' sreg]) = strys.(['P_A_' ssec '_' sreg]) * (strys.(['P_D_' ssubsec '_' sreg])/(strys.(['A_D_' ssubsec '_' sreg])*strpar.(['omegaQ_' ssubsec '_' sreg '_p'])))^strpar.(['omegaQ_' ssubsec '_' sreg '_p']);
                    strys.(['P_M_A_' ssec '_' sreg]) = strys.(['P_M_A_' ssec '_' sreg]) * (strys.(['P_M_' ssubsec])/strpar.(['omegaQ_' ssubsec '_' sreg '_p']))^strpar.(['omegaQ_' ssubsec '_' sreg '_p']);
                    
                else
                    strys.(['P_A_' ssec '_' sreg]) = strys.(['P_A_' ssec '_' sreg]) + strpar.(['omegaQ_' ssubsec '_' sreg '_p']) * (strys.(['P_D_' ssubsec '_' sreg])/strys.(['A_D_' ssubsec '_' sreg]))^(1 - strpar.(['etaQA_' ssec '_p']));                        
                    strys.(['P_M_A_' ssec '_' sreg]) = strys.(['P_M_A_' ssec '_' sreg]) + strpar.(['omegaM_F_' ssubsec '_' sreg '_p']) * (strys.(['P_M_' ssubsec]))^(1 - strpar.(['etaQA_' ssec '_p']));                        
                end                    


            end
            if strpar.(['etaQA_' ssec '_p']) ~= 1
                % aggregate sector production
                strys.(['P_A_' ssec '_' sreg])  = strys.(['P_A_' ssec '_' sreg])^(1/(1 - strpar.(['etaQA_' ssec '_p'])));
                strys.(['P_M_A_' ssec '_' sreg])  = strys.(['P_M_A_' ssec '_' sreg])^(1/(1 - strpar.(['etaQA_' ssec '_p'])));
            end         
            
            if strpar.etaQ_p == 1
                strys.(['P_F_' sreg]) = strys.(['P_F_' sreg]) * (strys.(['P_M_A_' ssec '_' sreg])/strpar.(['omegaMA_F_' ssec '_' sreg '_p']))^strpar.(['omegaMA_F_' ssec '_' sreg '_p']);
            else
                strys.(['P_F_' sreg]) = strys.(['P_F_' sreg]) + strpar.(['omegaMA_F_' ssec '_' sreg '_p']) * (strys.(['P_M_A_' ssec '_' sreg]))^(1 - strpar.etaQ_p);                        
            end             
        end

        if strpar.etaQ_p ~= 1
            % aggregate sector production
            strys.(['P_F_' sreg])  = strys.(['P_F_' sreg])^(1/(1 - strpar.etaQ_p));
        end

        if strpar.etaF_p ~= 1
            % aggregate sector production
            strys.(['P_' sreg])  = (strpar.(['omegaF_' sreg '_p']) * strys.(['P_F_' sreg])^(1 - strpar.etaF_p) + ...
                (1 - strpar.(['omegaF_' sreg '_p'])) * strys.(['P_D_' sreg])^(1 - strpar.etaF_p))^(1/(1 - strpar.etaF_p));
        else
            strys.(['P_' sreg])  = ((strys.(['P_F_' sreg])/strpar.(['omegaF_' sreg '_p']))^(strpar.(['omegaF_' sreg '_p'])) * ...
             (strys.(['P_D_' sreg])/(1 - strpar.(['omegaF_' sreg '_p'])))^(1 - strpar.(['omegaF_' sreg '_p'])));
        end
    end 
    
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        % compute final imports 
        strys.(['M_F_' sreg]) = (strys.(['P_F_' sreg]) / strys.(['P_D_' sreg]))^(-strpar.etaF_p) * strpar.(['omegaF_' sreg '_p']) / (1 - strpar.(['omegaF_' sreg '_p'])) * strys.(['Q_U_' sreg]);
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec); 
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                
                if strpar.(['etaIA_' ssubsec '_p']) == 1
                    strys.(['P_I_' ssubsec '_' sreg]) = 1;
                else
                    strys.(['P_I_' ssubsec '_' sreg]) = 0;                        
                end
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm); 
                    PAnettemp = strys.(['P_A_' ssecm '_' sreg]);
                    PEtemp = + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strys.(['sF_' sreg]) * exp(strexo.(['exo_EI_' ssubsec '_' sreg '_' ssecm])) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]);
                    PAgrosstemp = (PAnettemp +PEtemp)/strys.(['A_I_' ssubsec '_' sreg '_' ssecm]);                                            
                    if strpar.(['etaIA_' ssubsec '_p']) == 1
                        strys.(['P_I_' ssubsec '_' sreg]) = strys.(['P_I_' ssubsec '_' sreg]) * (PAgrosstemp/strpar.(['omegaQI_' ssubsec '_' sreg '_' ssecm '_p']))^strpar.(['omegaQI_' ssubsec '_' sreg '_' ssecm '_p']);
                    else
                        strys.(['P_I_' ssubsec '_' sreg]) = strys.(['P_I_' ssubsec '_' sreg]) + strpar.(['omegaQI_' ssubsec '_' sreg '_' ssecm '_p']) * (PAgrosstemp)^(1 - strpar.(['etaIA_' ssubsec '_p']));                        
                    end
                end
                if strpar.(['etaIA_' ssubsec '_p']) ~= 1
                    strys.(['P_I_' ssubsec '_' sreg]) = strys.(['P_I_' ssubsec '_' sreg])^(1 / (1 - strpar.(['etaIA_' ssubsec '_p'])));                        
                end
                if strpar.(['etaI_' ssubsec '_p']) == 1
                    % subsectoral price level of primary production factors
                    strys.(['P_' ssubsec '_' sreg]) = ((strys.(['P_Q_' ssubsec '_' sreg])-strys.(['kappaE_' ssubsec '_' sreg])*strys.(['PE_' sreg])) / (strys.(['P_I_' ssubsec '_' sreg])/(strys.(['A_I_' ssubsec '_' sreg])*strpar.(['omegaQI_' ssubsec '_' sreg '_p'])))^(strpar.(['omegaQI_' ssubsec '_' sreg '_p'])))^(1/(1 - strpar.(['omegaQI_' ssubsec '_' sreg '_p']))) * (1 - strpar.(['omegaQI_' ssubsec '_' sreg '_p']));
                else
                    % CES dual price inversion: P_QA^(1-eta) = omegaQI*(P_I/A_I)^(1-eta) + (1-omegaQI)*P^(1-eta)
                    etaI_val  = strpar.(['etaI_'   ssubsec '_p']);
                    omegaQI   = strpar.(['omegaQI_' ssubsec '_' sreg '_p']);
                    P_QA      = strys.(['P_Q_' ssubsec '_' sreg]) - strys.(['kappaE_' ssubsec '_' sreg]) * strys.(['PE_' sreg]);
                    P_I_val   = strys.(['P_I_' ssubsec '_' sreg]) / strys.(['A_I_' ssubsec '_' sreg]);
                    innerExpr = (P_QA^(1-etaI_val) - omegaQI * P_I_val^(1-etaI_val)) / (1-omegaQI);
                    if innerExpr <= 0
                        fprintf('[DIAG compute_exo_y] subsec=%s reg=%s etaI=%.3f omegaQI=%.4f P_QA=%.4f P_I/A_I=%.4f  inner=%.6g  => P complex/negative!\n', ...
                            ssubsec, sreg, etaI_val, omegaQI, P_QA, P_I_val, innerExpr);
                    end
                    strys.(['P_' ssubsec '_' sreg]) = innerExpr^(1/(1-etaI_val));
                end                
                strys.(['p_' ssubsec '_' sreg]) = log(strys.(['P_' ssubsec '_' sreg]));
                if isfield(strpar, 'lCapGoodsSecPrice_p') && strpar.lCapGoodsSecPrice_p == 1
                    strys.(['P_INV_' ssubsec '_' sreg]) = strpar.(['P0_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_I_' ssubsec '_' sreg]));% * strys.(['P_Q_' num2str(strpar.iCapGoodsSubsec_p) '_' sreg])/strpar.(['P0_Q_' num2str(strpar.iCapGoodsSubsec_p) '_' sreg '_p']) * exp(strexo.(['exo_P_K_' ssubsec '_' sreg]));
                else
                    strys.(['P_INV_' ssubsec '_' sreg]) = strys.(['P_' ssubsec '_' sreg]) * exp(strexo.(['exo_I_' ssubsec '_' sreg]));
                end
                strys.(['P_K_' ssubsec '_' sreg]) = strys.(['P_' ssubsec '_' sreg]) * exp(strexo.(['exo_P_K_' ssubsec '_' sreg]));
            end
        end
    end

end
