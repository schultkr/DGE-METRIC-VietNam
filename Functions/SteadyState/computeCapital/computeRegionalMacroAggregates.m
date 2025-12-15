function [strys, strexo, HousingExpenditures] = computeRegionalMacroAggregates(strys, strpar, strexo)
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
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
  
                % interest rate including taxes 
                rkgross = strys.(['r_' ssubsec '_' sreg]) * (strys.(['tauKH_' sreg]) + strys.(['tauKF_' ssubsec '_' sreg]));

                invreg = invreg  + strys.(['I_' ssubsec '_' sreg]) * strys.(['P_' ssubsec '_' sreg]);                           

                capincometaxes = capincometaxes + strys.(['K_' ssubsec '_' sreg]) * strys.(['P_' ssubsec '_' sreg]) * rkgross;
                
                labincometaxes = labincometaxes + strys.(['W_' ssubsec '_' sreg]) * strys.(['N_' ssubsec '_' sreg]) * strys.(['LF_' sreg]) * (strys.(['tauNH_' sreg]));
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
            strys.(['B_' sreg '_' sregm]) = -strys.(['NX_' sreg '_' sregm])/(strys.rf) - strys.(['BG_' sreg]);
            strys.(['NXD_' sreg]) = strys.(['NXD_' sreg]) + strys.(['NX_' sreg '_' sregm]);
        end
        
        strys.(['CapTradeRev_' sreg]) = 0;
         
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['CapTradeRev_' sreg]) = strys.(['CapTradeRev_' sreg]) + strys.(['E_' ssubsec '_' sreg]) * strys.(['PE_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']);
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);
                    strys.(['CapTradeRev_' sreg]) = strys.(['CapTradeRev_' sreg]) + strys.(['E_I_' ssubsec '_' sreg '_' ssecm]) * strys.(['PE_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']);
                end
            end
        end
        
        strys.CapTradeRev = strys.CapTradeRev + strys.(['CapTradeRev_' sreg]);
        
        strys.(['M_' sreg]) = strys.(['M_I_' sreg]) + strys.(['P_F_' sreg]) * strys.(['M_F_' sreg]);
        
        % regional nfa due to exchange rate
        strys.(['B_' sreg]) = log(strys.(['s_' sreg]))/(strpar.phiB_p * strpar.deltaB_p)*strys.(['Y_' sreg]);        
        % net exports
        strys.(['NX_' sreg]) = -strys.(['B_' sreg])*(strys.rf);
        
        % regional net exports
        strys.(['X_' sreg]) = (strys.(['NX_' sreg])+strys.(['M_' sreg]))/strys.(['P_Q_' sreg]);        
        % consumption
        tempMF = strpar.(['omegaF_' sreg '_p']) * (strys.(['P_F_' sreg])/strys.(['P_' sreg]))^(-strpar.etaF_p);
        tempnum = strys.(['Q_' sreg]) + strys.(['Tr_' sreg]) - strys.(['Q_I_' sreg]) - capincometaxes - labincometaxes - strys.(['X_' sreg]) * strys.(['P_Q_' sreg]) + strys.(['M_I_' sreg]) +  strys.(['P_F_' sreg]) * strys.(['M_F_' sreg]) - strys.(['CapTradeRev_' sreg]) - strys.(['NXD_' sreg]) - invreg - strys.(['Y_' sreg]) * strexo.(['exo_DH_' sreg]) * (1 + strys.(['tauH_' sreg]));
        
        tempCIH = (1-strpar.h_p)*strpar.(['gamma_' sreg '_p'])/...
            ((1 - strpar.(['gamma_' sreg '_p']))* (1-strpar.beta_p * exp(strexo.exo_beta) * strpar.h_p)) * strpar.deltaH_p * strpar.beta_p * exp(strexo.exo_beta) / (1-strpar.beta_p * exp(strexo.exo_beta)*(1-strpar.deltaH_p));
        tempdenom = (1 + strys.(['tauC_' sreg]))*strys.(['P_' sreg]) * (1 + tempCIH);
        strys.(['C_' sreg])  = tempnum / tempdenom ;
        
        
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

        % regional government expenditure
        strys.(['G_' sreg]) = strys.(['Q_U_' sreg]) * strys.(['P_D_' sreg]) / strys.(['P_' sreg]) + strys.(['M_F_' sreg]) * strys.(['P_F_' sreg]) / strys.(['P_' sreg]) - strys.(['C_' sreg]) - strys.(['I_' sreg]) - (strpar.iSecHouse_p == 0) * strys.(['IH_' sreg]) * strys.(['PH_' sreg]) / strys.(['P_' sreg]);        

        % aggregate housing expenditures 
        HousingExpenditures = HousingExpenditures + strys.(['PH_' sreg]) * strys.(['IH_' sreg]);
        
        % Lagrange multiplier for the budget constraint
        strys.(['lambda_' sreg]) = (1-strpar.(['gamma_' sreg '_p'])) * (1-strpar.beta_p * exp(strexo.exo_beta) * strpar.h_p) * ((1-strpar.h_p)*strys.(['C_' sreg])/strys.(['PoP_' sreg]))^(-strpar.(['gamma_' sreg '_p'])) * (strys.(['H_' sreg])/strys.(['PoP_' sreg]))^strpar.(['gamma_' sreg '_p']) * (((1-strpar.h_p)*strys.(['C_' sreg])/strys.(['PoP_' sreg]))^(1-strpar.(['gamma_' sreg '_p'])) * (strys.(['H_' sreg])/strys.(['PoP_' sreg]))^strpar.(['gamma_' sreg '_p']))^(-strpar.sigmaC_p) / (strys.(['P_' sreg]) * (1 + strys.(['tauC_' sreg])));
  
        strexo.exo_DH = strexo.exo_DH + strexo.(['exo_DH_' sreg]);
        
               
        % foreign debt / (B > 0 debitor vs. B < 0 creditor)
        strys.(['B_' sreg]) = -strys.(['NX_' sreg])/(strys.rf) - strys.(['BG_' sreg]);
        
        % net foreign asset position
        strys.B = strys.B + strys.(['B_' sreg]);
        
        % imports
        strys.M = strys.M + strys.(['M_' sreg]);

        % transfers
        strys.Tr = strys.Tr + strys.(['Tr_' sreg]);

        % consumption
        strys.C = strys.C + strys.(['P_' sreg]) * strys.(['C_' sreg]);
    end
end
