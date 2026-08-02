function [strys, strexo, HousingExpenditures] = compute_regional_macro_aggregates(strys, strpar, strexo)
    % products used domestically
    strys.Q_U = 0;
    
    % aggregate debt
    strys.B = 0;
    
    % aggregate used products
    strys.Q_U = 0;
       
    % initiliaze housing expenditures for aggregation
    HousingExpenditures = 0;
    
    % initiliaze housing expenditures for aggregation
    strexo.exo_DH = 0;
    
    % initiliaze imports
    strys.M = 0;

    % initiliaze consumption
    strys.C = 0;

    % initiliaze government expenditure
        strys.G = 0;
    
    strys.CapTradeRev = 0;
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);   
        
        strys.Q_U =  strys.Q_U + strys.(['Q_U_' sreg]) * strys.(['P_D_' sreg]);
                
        % compute regional captial and labour income
        capincometaxes = 0;
        labincometaxes = 0;
        invreg = 0;
        ifdireg = 0; 
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
  
                % interest rate including taxes 
                % rkgross = strys.(['r_H_' ssubsec '_' sreg]) * (strys.(['tauKH_' ssubsec '_' sreg]) + strys.(['tauKF_' ssubsec '_' sreg]));

                invreg = invreg  + strys.(['I_' ssubsec '_' sreg]) * strys.(['P_INV_' ssubsec '_' sreg]);                           
                fdi_income_outflow = strys.(['r_FDI_' ssubsec '_' sreg]) ...
                    * strys.(['P_K_' ssubsec '_' sreg]) ...
                    / strys.(['P_INV_' ssubsec '_' sreg]) ...
                    * strys.(['K_FDI_' ssubsec '_' sreg]);
                ifdireg = ifdireg + strys.(['I_FDI_' ssubsec '_' sreg]) * strys.(['P_INV_' ssubsec '_' sreg]) + fdi_income_outflow;                           
                % capincometaxes = capincometaxes + strys.(['K_' ssubsec '_' sreg]) * strys.(['P_K_' ssubsec '_' sreg]) * rkgross;
                capincometaxes = capincometaxes + strys.(['K_H_' ssubsec '_' sreg]) * strys.(['P_K_' ssubsec '_' sreg]) * strys.(['tauKH_' ssubsec '_' sreg]) * strys.(['r_H_' ssubsec '_' sreg]);
                capincometaxes = capincometaxes + strys.(['K_' ssubsec '_' sreg]) * strys.(['P_K_' ssubsec '_' sreg]) * strys.(['tauKF_' ssubsec '_' sreg]) * strys.(['r_F_' ssubsec '_' sreg]);
                
                labincometaxes = labincometaxes + strys.(['W_' ssubsec '_' sreg]) * strys.(['N_' ssubsec '_' sreg]) * strys.(['LF_' sreg]) * (strys.(['tauNH_' sreg]) +  strys.(['tauNF_' ssubsec '_' sreg]));
            end
        end
        
        strys.(['NXD_' sreg]) =0;        
        for icoregm = 1:strpar.inbregions_p
            sregm = num2str(icoregm);
            strys.(['NX_' sreg '_' sregm]) =0;

            for icosec = 1:strpar.inbsectors_p
                ssec = num2str(icosec);
                for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                    ssubsec = num2str(icosubsec);
                    strys.(['NX_' sreg '_' sregm]) = strys.(['NX_' sreg '_' sregm]) + (strys.(['Q_D_' ssubsec '_' sregm '_' sreg]) * strys.(['P_Q_' ssubsec '_' sreg]) - strys.(['Q_D_' ssubsec '_' sreg '_' sregm]) * strys.(['P_Q_' ssubsec '_' sregm]));
                end
            end
            strys.(['B_' sreg '_' sregm]) = -strys.(['NX_' sreg '_' sregm])/(strys.rf);
            strys.(['NXD_' sreg]) = strys.(['NXD_' sreg]) + strys.(['NX_' sreg '_' sregm]);
        end
        
        strys.(['CapTradeRev_' sreg]) = 0;
        strys.(['I_G_' sreg]) = 0;
         
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['CapTradeRev_' sreg]) = strys.(['CapTradeRev_' sreg]) + strys.(['E_' ssubsec '_' sreg]) * strys.(['PE_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']);
                strys.(['I_G_' sreg]) = strys.(['I_G_' sreg]) + ...
                    1 / strys.(['P_' sreg]) ...
                    * (strys.(['I_G_' ssubsec '_' sreg]) + strys.(['G_A_' ssubsec '_' sreg])) ...
                    * strys.(['P_INV_' ssubsec '_' sreg]);
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);
                    strys.(['CapTradeRev_' sreg]) = strys.(['CapTradeRev_' sreg]) + strys.(['E_I_' ssubsec '_' sreg '_' ssecm]) * strys.(['PE_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']);
                end
            end
        end
        
        strys.CapTradeRev = strys.CapTradeRev + strys.(['CapTradeRev_' sreg]);
        
        strys.(['M_' sreg]) = strys.(['M_I_' sreg]) + strys.(['P_F_' sreg]) * strys.(['M_F_' sreg]);
        
        % Only the externally-held share of public debt enters the external balance.
        BG_ext = (strpar.(['phi_BG_ext_' sreg '_p']) + strexo.(['exo_phi_BG_ext_' sreg])) * strys.(['BG_' sreg]);
        BG_dom = strys.(['BG_' sreg]) - BG_ext;

        % Solve the foreign-asset block in terms of total external position
        % T = B + BG_ext, then back out private foreign assets B.
        discount_factor = strpar.beta_p * exp(strexo.exo_beta);
        adjustment_ss = 0.5 * strys.(['adjB_' sreg]);

        if strexo.(['exo_lNXTarget_' sreg]) == 1
            % Baseline: net exports are pinned to the calibrated target ratio.
            % premium_term is identically 1 along the total_external_position/
            % s_reg locus used below (s_reg = exp(phiB_p*deltaB_p*T/Y) makes
            % s_reg*exp(-phiB_p*deltaB_p*T/Y) = 1), so the law-of-motion
            % identity collapses to NX = -rf*T + phiadjB_p*adjustment_ss^2
            % - deltaB + ifdireg, which is linear in T and can be inverted
            % directly for the external position, then for s_reg.
            strys.(['NX_' sreg]) = (strpar.(['NX0_' sreg '_p']) / strpar.(['Y0_' sreg '_p']) + strexo.(['exo_NX_' sreg])) * strys.(['Y_' sreg]);

            total_external_position = ( ...
                strpar.phiadjB_p * adjustment_ss^2 ...
                - strys.(['deltaB_' sreg]) ...
                + ifdireg ...
                - strys.(['NX_' sreg]) ...
            ) / strys.rf;

            strys.(['B_' sreg]) = total_external_position - BG_ext;
            strys.(['s_' sreg]) = exp(strpar.phiB_p * strpar.deltaB_p * total_external_position / strys.(['Y_' sreg]));
        else
            total_external_guess = log(max(1e-12, strys.(['s_' sreg])))/(strpar.phiB_p * strpar.deltaB_p)*strys.(['Y_' sreg]);

            % foc_total_external = @(total_external_position) ...
            %     1 + 2 * strpar.phiadjB_p * strys.(['adjB_' sreg]) ...
            %     - discount_factor * ( ...
            %         strys.(['s_' sreg]) * (1 + strys.rf - strpar.deltaB_p) * exp(-strpar.phiB_p * strpar.deltaB_p * total_external_position / strys.(['Y_' sreg])) ...
            %         + 2 * strpar.phiadjB_p * strys.(['adjB_' sreg]) ...
            %     );

            %if abs(foc_total_external(total_external_guess)) < 1e-12
                total_external_position = total_external_guess;
            %else
             %   total_external_position = fzero(foc_total_external, total_external_guess);
            %end

            strys.(['B_' sreg]) = total_external_position - BG_ext;

            premium_term = strys.(['s_' sreg]) * exp(-strpar.phiB_p * strpar.deltaB_p * total_external_position / strys.(['Y_' sreg]));

            % Net exports implied by the steady-state law of motion for (B+BG).
            strys.(['NX_' sreg]) = total_external_position ...
                - (1 + strys.rf) * premium_term * total_external_position ...
                + strpar.phiadjB_p * adjustment_ss^2 ...
                - strys.(['deltaB_' sreg]) ...
                + ifdireg;
        end

        % regional exports
        strys.(['X_' sreg]) = (strys.(['NX_' sreg])+strys.(['M_' sreg]))/strys.(['P_Q_' sreg]);
        
        % resources available for consumption and housing
        tempresources = strys.(['Q_' sreg]) + strys.(['Tr_' sreg]) + ...
            strys.(['M_I_' sreg]) +  strys.(['P_F_' sreg]) * strys.(['M_F_' sreg]);
        publiccapitalincome = 0;
        if isfield(strys, ['publiccapitalincome_' sreg])
            publiccapitalincome = strys.(['publiccapitalincome_' sreg]);
        end
        temptaxincome = labincometaxes + capincometaxes + publiccapitalincome + strys.(['CapTradeRev_' sreg]);

        tempuses = temptaxincome + strys.(['Q_I_' sreg]) + ...
            strys.(['X_' sreg]) * strys.(['P_Q_' sreg]) + ...
            invreg + strys.(['I_PV_' sreg]) + ...
            strys.(['Y_' sreg]) * strexo.(['exo_DH_' sreg]) * (1 + strys.(['tauH_' sreg]));

        tempnum = tempresources - tempuses;
        
        tempCIH = (1-strpar.h_p)*strpar.(['gamma_' sreg '_p'])/...
            ((1 - strpar.(['gamma_' sreg '_p']))* (1-strpar.beta_p * exp(strexo.exo_beta) * strpar.h_p)) * strpar.deltaH_p * strpar.beta_p * exp(strexo.exo_beta) / (1-strpar.beta_p * exp(strexo.exo_beta)*(1-strpar.deltaH_p));
        tempdenom = (1 + strys.(['tauC_' sreg]))*strys.(['P_' sreg]) * (1 + tempCIH);
        % consumption
        strys.(['C_' sreg])  = (tempnum - ((1 + strys.rf) * strys.(['s_' sreg]) - 1) * BG_ext - strys.rf * BG_dom) / tempdenom;
        
        
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            strys.(['M_A_F_' ssec '_' sreg]) = strpar.(['omegaMA_F_' ssec '_' sreg '_p']) * (strys.(['P_M_A_' ssec '_' sreg])/strys.(['P_F_' sreg]))^(-strpar.etaQ_p)*strys.(['M_F_' sreg]); 
            
            
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['M_F_' ssubsec '_' sreg]) = strpar.(['omegaM_F_' ssubsec '_' sreg '_p']) * (strys.(['P_M_' ssubsec])/strys.(['P_M_A_' ssec '_' sreg]))^(-strpar.(['etaQA_' ssec '_p']))*strys.(['M_A_F_' ssec '_' sreg]); 
            end            
        end                
        
        
        if strpar.iSecHouse_p == 0
            if strpar.lEndogenousY_p == 0
                % house prices
                strys.(['PH_' sreg]) = (strpar.(['gamma_' sreg '_p'])/((1 - strpar.(['gamma_' sreg '_p'])) * (1-strpar.beta_p * exp(strexo.exo_beta) * strpar.h_p))  * strpar.beta_p * exp(strexo.exo_beta) / (1 - strpar.beta_p * exp(strexo.exo_beta) * (1 - strpar.deltaH_p)) * (1-strpar.h_p)*strys.(['C_' sreg]) * strys.(['P_' sreg]) * (1 + strys.(['tauC_' sreg]))) / (strys.(['H_' sreg]) * (1 + strys.(['tauH_' sreg])));    
            else
                % housing stock
                strys.(['H_' sreg])  = (strpar.(['gamma_' sreg '_p'])/((1 - strpar.(['gamma_' sreg '_p']))* (1-strpar.beta_p * exp(strexo.exo_beta) * strpar.h_p))  * strpar.beta_p * exp(strexo.exo_beta) / (1 - strpar.beta_p * exp(strexo.exo_beta) * (1 - strpar.deltaH_p)) * (1-strpar.h_p)*strys.(['C_' sreg]) * strys.(['P_' sreg]) * (1 + strys.(['tauC_' sreg]))) / (strys.(['PH_' sreg]) * (1 + strys.(['tauH_' sreg])));    
            
            end
        end
        % Lagrange multiplier for the evolution of the household stock
        strys.(['omegaH_' sreg]) = strys.(['PH_' sreg]) * (1 + strys.(['tauH_' sreg]));

        % damages to the housing stock
        strys.(['DH_' sreg]) = strexo.(['exo_DH_' sreg]) * strys.Y / strys.(['PH_' sreg]);

        % investments into the housing stock
        strys.(['IH_' sreg]) = strpar.deltaH_p * strys.(['H_' sreg]) + strys.(['DH_' sreg]);
        Q_U_market = strys.(['Q_U_' sreg]) * strys.(['P_D_' sreg]) - strys.(['Q_PV_' sreg]) * strys.(['P_A_' num2str(strpar.iSecEnergy_p) '_' sreg]);
        % regional government expenditure
        strys.(['G_' sreg]) = Q_U_market / strys.(['P_' sreg]) +...
            strys.(['M_F_' sreg]) * strys.(['P_F_' sreg]) / strys.(['P_' sreg]) - ...
            strys.(['C_' sreg]) - strys.(['I_G_' sreg]) - strys.(['I_' sreg]) -...
            (strpar.iSecHouse_p == 0) * (strys.(['IH_' sreg]) * strys.(['PH_' sreg])+ ...
            strys.(['I_PV_' sreg])) / strys.(['P_' sreg]);

        % aggregate housing expenditures 
        HousingExpenditures = HousingExpenditures + strys.(['PH_' sreg]) * strys.(['IH_' sreg]);
        
        % Lagrange multiplier for the budget constraint
        strys.(['lambda_' sreg]) = (1-strpar.(['gamma_' sreg '_p'])) * (1-strpar.beta_p * exp(strexo.exo_beta) * strpar.h_p) * ((1-strpar.h_p)*strys.(['C_' sreg])/strys.(['PoP_' sreg]))^(-strpar.(['gamma_' sreg '_p'])) * (strys.(['H_' sreg])/strys.(['PoP_' sreg]))^strpar.(['gamma_' sreg '_p']) * (((1-strpar.h_p)*strys.(['C_' sreg])/strys.(['PoP_' sreg]))^(1-strpar.(['gamma_' sreg '_p'])) * (strys.(['H_' sreg])/strys.(['PoP_' sreg]))^strpar.(['gamma_' sreg '_p']))^(-strpar.sigmaC_p) / (strys.(['P_' sreg]) * (1 + strys.(['tauC_' sreg])));
  
        strexo.exo_DH = strexo.exo_DH + strexo.(['exo_DH_' sreg]);
        
               
        % Keep B from the total-position solution above.
        
        % net foreign asset position
        strys.B = strys.B + strys.(['B_' sreg]);
        
        % imports
        strys.M = strys.M + strys.(['M_' sreg]);

        % transfers
        strys.Tr = strys.Tr + strys.(['Tr_' sreg]);

        % consumption
        strys.C = strys.C + strys.(['P_' sreg]) * strys.(['C_' sreg]);
        
        % consumption
        strys.G = strys.G + strys.(['P_' sreg]) * strys.(['G_' sreg]);
    end
end
