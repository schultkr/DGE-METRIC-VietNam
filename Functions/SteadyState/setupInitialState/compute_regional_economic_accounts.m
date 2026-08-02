function [strys, strpar, strexo, HousingExpenditures] = compute_regional_economic_accounts(strys, strpar, strexo)
    
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
            if icosec == strpar.iSecEnergy_p
                strys.(['Q_AEff_F_' ssec '_' sreg]) = (strys.(['Q_A_F_' ssec '_' sreg]) + strys.(['Q_PV_' sreg])) * ...
                    strys.(['P_A_' ssec '_' sreg]) / strys.(['P_D_' sreg]);
            else
                strys.(['Q_AEff_F_' ssec '_' sreg]) = (strys.(['Q_A_F_' ssec '_' sreg])) * ...
                    strys.(['P_A_' ssec '_' sreg]) / strys.(['P_D_' sreg]);
            end
            strys.(['Q_U_' sreg]) = strys.(['Q_U_' sreg]) + strys.(['Q_AEff_F_' ssec '_' sreg]);
        end

        % regional net exports
        strys.(['NX_' sreg]) = strys.(['X_' sreg])*strys.(['P_Q_' sreg]) - strys.(['M_' sreg]);


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
                strys.(['B_' sreg '_' sregm]) = -strys.(['NX_' sreg '_' sregm])/(strys.rf);
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
        ifdireg = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);  
                % interest rate including taxes 
                % rkgross = strys.(['r_' ssubsec '_' sreg]) * (strys.(['tauKH_' ssubsec '_' sreg]) + strys.(['tauKF_'  ssubsec '_' sreg]));

                invreg = invreg  + strys.(['I_' ssubsec '_' sreg]) * strys.(['P_INV_' ssubsec '_' sreg]);

                % In some scenarios/iterations these fields may still be NaN.
                % Treat missing/non-finite FDI components as zero in setup mode.
                I_FDI_val = 0;
                K_FDI_val = 0;
                r_FDI_val = 0;
                P_INV_val = 0;
                P_K_val   = 0;

                if isfield(strys, ['I_FDI_' ssubsec '_' sreg])
                    temp = strys.(['I_FDI_' ssubsec '_' sreg]);
                    if isfinite(temp)
                        I_FDI_val = temp;
                    end
                end
                if isfield(strys, ['K_FDI_' ssubsec '_' sreg])
                    temp = strys.(['K_FDI_' ssubsec '_' sreg]);
                    if isfinite(temp)
                        K_FDI_val = temp;
                    end
                end
                if isfield(strys, ['r_FDI_' ssubsec '_' sreg])
                    temp = strys.(['r_FDI_' ssubsec '_' sreg]);
                    if isfinite(temp)
                        r_FDI_val = temp;
                    end
                end
                if isfield(strys, ['P_INV_' ssubsec '_' sreg])
                    temp = strys.(['P_INV_' ssubsec '_' sreg]);
                    if isfinite(temp)
                        P_INV_val = temp;
                    end
                end
                if isfield(strys, ['P_K_' ssubsec '_' sreg])
                    temp = strys.(['P_K_' ssubsec '_' sreg]);
                    if isfinite(temp)
                        P_K_val = temp;
                    end
                end

                fdi_income_outflow = 0;
                if P_INV_val > 0
                    fdi_income_outflow = r_FDI_val * P_K_val / P_INV_val * K_FDI_val;
                end
                ifdireg = ifdireg + I_FDI_val * P_INV_val + fdi_income_outflow;

                capincometax = capincometax + strys.(['K_H_' ssubsec '_' sreg]) * strys.(['P_K_' ssubsec '_' sreg]) / strys.(['P_' sreg]) * strys.(['tauKH_' ssubsec '_' sreg]) * strys.(['r_H_' ssubsec '_' sreg]);
                capincometax = capincometax + strys.(['K_' ssubsec '_' sreg]) * strys.(['P_K_' ssubsec '_' sreg]) / strys.(['P_' sreg]) * strys.(['tauKF_' ssubsec '_' sreg]) * strys.(['r_F_' ssubsec '_' sreg]);

                labincometax = labincometax + strys.(['W_' ssubsec '_' sreg]) * strys.(['N_' ssubsec '_' sreg]) * strys.(['LF_' sreg]) * (strys.(['tauNH_' sreg]) +  strys.(['tauNF_'  ssubsec '_' sreg]));
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
        strys.(['I_G_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['CapTradeRev_' sreg]) = strys.(['CapTradeRev_' sreg]) + strys.(['E_' ssubsec '_' sreg]) * strys.(['PE_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']);
                strys.(['I_G_' sreg]) = strys.(['I_G_' sreg]) + ...
                    (strys.(['I_G_' ssubsec '_' sreg]) + strys.(['G_A_' ssubsec '_' sreg])) ...
                    * strys.(['P_INV_' ssubsec '_' sreg]) ...
                    / strys.(['P_' sreg]);
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);
                    strys.(['CapTradeRev_' sreg]) = strys.(['CapTradeRev_' sreg]) + strys.(['E_I_' ssubsec '_' sreg '_' ssecm]) * strys.(['PE_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']);
                end
            end
        end

        strys.CapTradeRev = strys.CapTradeRev + strys.(['CapTradeRev_' sreg]);

        % External-balance NX includes FDI investment and repatriated returns.
        % Keep trade NX (X*P_Q - M) unchanged for goods-market identities.
        if ~isfinite(ifdireg)
            ifdireg = 0;
        end
        nx_external = strys.(['NX_' sreg]) - ifdireg;
        BG_ext = (strpar.(['phi_BG_ext_' sreg '_p']) + strexo.(['exo_phi_BG_ext_' sreg])) * strys.(['BG_' sreg]);
        BG_dom = strys.(['BG_' sreg]) - BG_ext;
        strys.(['B_' sreg]) = -nx_external / (strys.rf) - BG_ext;
        strys.(['s_' sreg]) = exp(strpar.phiB_p * strpar.deltaB_p * (strys.(['B_' sreg]) + BG_ext) / strys.(['Y_' sreg]));
        if strpar.lCalibration_p == 1
            strpar.(['s0_' sreg '_p']) = strys.(['s_' sreg]);
            strexo.(['exo_s_' sreg]) = 0;
        else
            strexo.(['exo_s_' sreg]) = log(strys.(['s_' sreg]) / strpar.(['s0_' sreg '_p']));
        end

        % Transfers: recompute with full formula now that E_reg is available.
        % (assign_predetermined_variables only sets Tr_reg when exo_tauSTr == 0.)
        strys.(['Tr_' sreg]) = strpar.(['Tr0_' sreg '_p']) + strexo.(['exo_Tr_' sreg]) ...
            + strexo.(['exo_tauSTr_' sreg]) * strys.(['PE_' sreg]) * strys.(['E_' sreg]);

        % Public capital rental income r_G*K_G*P_K (government revenue, not household income).
        % compute_tax_income runs before this function, so publiccapitalincome_reg is ready.
        pubCapInc = 0;
        if isfield(strys, ['publiccapitalincome_' sreg])
            pubCapInc = strys.(['publiccapitalincome_' sreg]) / strys.(['P_' sreg]);
        end

        % consumption
        strys.(['C_' sreg]) = (strys.(['Q_' sreg]) + strys.(['Tr_' sreg]) - strys.(['Q_I_' sreg]) - labincometax - capincometax - pubCapInc - invreg - strys.(['I_PV_' sreg]) - strys.(['CapTradeRev_' sreg]) - strys.(['NX_' sreg]) - strys.(['NXD_' sreg]) - strys.(['PH_' sreg]) * strys.(['H_' sreg]) * strpar.deltaH_p * (1 + strys.(['tauH_' sreg])))/(strys.(['P_' sreg]) * (1 + strys.(['tauC_' sreg]))) ...
            - ((1 + strys.rf) * strys.(['s_' sreg]) - 1) * BG_ext / (strys.(['P_' sreg]) * (1 + strys.(['tauC_' sreg]))) ...
            - strys.rf * BG_dom / (strys.(['P_' sreg]) * (1 + strys.(['tauC_' sreg])));


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
        strys.CapTradeRev = strys.CapTradeRev + strys.(['CapTradeRev_' sreg]);
        strys.B = strys.B + strys.(['B_' sreg]);
        strys.Q_U = strys.Q_U + strys.(['Q_U_' sreg]) * strys.(['P_D_' sreg]);
        HousingExpenditures = HousingExpenditures + strys.(['PH_' sreg]) * strys.(['H_' sreg]) * strpar.deltaH_p;
    end
end
