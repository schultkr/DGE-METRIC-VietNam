function [strys, strpar, HousingExpenditures] = computeRegionalEconomicAccounts(strys, strpar, strexo)
    
    strys.B = 0;
    strys.Q_U = 0;
    strys.CapTradeRev = 0;
    HousingExpenditures = 0;
    strys.C = 0;
    strys.G = 0;

    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);

        % regional output
        strys.(['Q_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['Q_' sreg]) = strys.(['Q_' sreg]) + strys.(['Q_' ssubsec '_' sreg]) * strys.(['P_Q_' ssubsec '_' sreg]);
            end
        end

        % regional exports
        strys.(['X_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['X_' sreg]) = strys.(['X_' sreg]) + strys.(['X_' ssubsec '_' sreg]) * strys.(['P_Q_' ssubsec '_' sreg]);
            end
        end

        strys.(['Q_U_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            strys.(['Q_U_' sreg]) = strys.(['Q_U_' sreg]) + strys.(['Q_A_F_' ssec '_' sreg]) * strys.(['P_A_' ssec '_' sreg]) / strys.(['P_D_' sreg]);
        end

        % regional net exports
        strys.(['NX_' sreg]) = strys.(['X_' sreg])*strys.(['P_Q_' sreg]) - strys.(['M_' sreg]);

        % foreign debt / (B > 0 debitor vs. B < 0 creditor)
        strys.(['B_' sreg]) = -strys.(['NX_' sreg])/(strys.rf) - strys.(['BG_' sreg]);

        % compute exchange rate
        strys.(['s_' sreg]) = exp(strpar.phiB_p*strpar.deltaB_p * strys.(['B_' sreg])/strys.(['Y_' sreg]));

        % set initial erxchange rate
        strpar.(['s0_' sreg '_p']) = strys.(['s_' sreg]);

        if strpar.inbregions_p > 1
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
            end
        end

        % lagrange multiplier for houses
        strys.(['omegaH_' sreg]) = strys.(['PH_' sreg]) * (1 + strys.(['tauH_' sreg]));

        % house prices
        strys.(['PH_' sreg]) = strpar.(['sH_' sreg '_p'])*strys.(['PoP_' sreg])/strys.PoP * strys.Y / (strpar.deltaH_p * strys.(['H_' sreg]) * (1 + strys.(['tauH_' sreg])));

        % aggregate housing expenditures 
        HousingExpenditures = HousingExpenditures + strys.(['PH_' sreg]) * strys.(['H_' sreg]) * strpar.deltaH_p;

        % compute regional captial and labour income
        capincometax = 0;
        labincometax = 0;
        invreg = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);  
                % interest rate including taxes 
                rkgross = strys.(['r_' ssubsec '_' sreg]) * (strys.(['tauKH_' sreg]) + strys.(['tauKF_'  ssubsec '_' sreg]));

                invreg = invreg  + strys.(['I_' ssubsec '_' sreg]) * strys.(['P_' ssubsec '_' sreg]);                           

                capincometax = capincometax + strys.(['K_' ssubsec '_' sreg]) * strys.(['P_' ssubsec '_' sreg]) / strys.(['P_' sreg]) * rkgross;

                labincometax = labincometax + strys.(['W_' ssubsec '_' sreg]) * strys.(['N_' ssubsec '_' sreg]) * strys.(['LF_' sreg]) * strys.(['tauNH_' sreg]);
            end
        end

        % regional demand for intermediate input
        strys.(['Q_I_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['Q_I_' sreg]) = strys.(['Q_I_' sreg]) + strys.(['Q_I_' ssubsec '_' sreg]) * strys.(['P_I_' ssubsec '_' sreg]);
            end
        end

        strys.(['NXD_' sreg]) = 0;
        if strpar.inbregions_p > 1
            for icoregm = 1:strpar.inbregions_p
                sregm = num2str(icoregm);
                strys.(['NXD_' sreg]) = strys.(['NXD_' sreg]) + strys.(['NX_' sreg '_' sregm]);
            end
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

        % consumption
        strys.(['C_' sreg]) = (strys.(['Q_' sreg]) - strys.(['Q_I_' sreg]) - labincometax - capincometax - invreg - strys.(['CapTradeRev_' sreg]) - strys.(['NX_' sreg]) - strys.(['NXD_' sreg]) - strys.(['PH_' sreg]) * strys.(['H_' sreg]) * strpar.deltaH_p * (1 + strys.(['tauH_' sreg])))/(strys.(['P_' sreg]) * (1 + strys.(['tauC_' sreg])));


        % auxiliary variable to compute gamma
        tempgam = (1-strpar.beta_p * strpar.h_p) * strys.(['H_' sreg]) * strys.(['PH_' sreg]) * (1 + strys.(['tauH_' sreg])) / ((1-strpar.h_p)*strys.(['C_' sreg]) * strys.(['P_' sreg]) * (1 + strys.(['tauC_' sreg]))) *  (1 - strpar.beta_p * (1 - strpar.deltaH_p)) / (strpar.beta_p);

        % preference parameter for houses to ensure housing share
        strpar.(['gamma_' sreg '_p']) = tempgam / (1 + tempgam);   

        % house price level
        strpar.(['PH0_' sreg '_p']) = strys.(['PH_' sreg]);

        % damages to houses induced by climate change
        strys.(['DH_' sreg]) = strexo.(['exo_DH_' sreg]) * strpar.Y0_p /strys.(['PH_' sreg]);

        % Lagrange multiplier of budget constraint HH
        strys.(['lambda_' sreg]) = (1-strpar.(['gamma_' sreg '_p'])) * (1-strpar.beta_p * strpar.h_p) * ((1-strpar.h_p)*strys.(['C_' sreg])/strys.(['PoP_' sreg]))^(-strpar.(['gamma_' sreg '_p'])) * (strys.(['H_' sreg])/strys.(['PoP_' sreg]))^strpar.(['gamma_' sreg '_p']) * (((1-strpar.h_p)*strys.(['C_' sreg])/strys.(['PoP_' sreg]))^(1-strpar.(['gamma_' sreg '_p'])) * (strys.(['H_' sreg])/strys.(['PoP_' sreg]))^strpar.(['gamma_' sreg '_p']))^(-strpar.sigmaC_p) / (strys.(['P_' sreg]) * (1 + strys.(['tauC_' sreg])));

        % investment into housing 
        strys.(['IH_' sreg]) = strpar.deltaH_p * strys.(['H_' sreg]);

        % accumulate national aggregates
        strys.C = strys.C + strys.(['P_' sreg]) * strys.(['C_' sreg]);
        strys.G = strys.G + strys.(['P_' sreg]) * strys.(['G_' sreg]);
        strys.CapTradeRev = strys.CapTradeRev + strys.(['CapTradeRev_' sreg]);
        strys.B = strys.B + strys.(['B_' sreg]);
        strys.Q_U = strys.Q_U + strys.(['Q_U_' sreg]) * strys.(['P_D_' sreg]);
        HousingExpenditures = HousingExpenditures + strys.(['PH_' sreg]) * strys.(['H_' sreg]) * strpar.deltaH_p;
    end
end
