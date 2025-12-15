function [fval_vec, strys] = evaluateCapitalSteadyStateResiduals(strys, strpar, strexo)
% EVALUATECAPITALSTEADYSTATERESIDUALS
% Computes residuals for steady-state conditions in DGE-CRED:
% - Household FOC (labor)
% - Firm FOC (intermediates)
% - Export demand
% - Goods market balance
% - Regional price indices
% - Energy input ratios
% - Net export constraints
% - Migration
% - Cap-and-trade
% - Tax balance and housing condition

    %% government budget constraint
    fval_vec_G = nan(strpar.inbregions_p,1);
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        lhs_G = ((strys.(['wagetax_' sreg]) + strys.(['capitaltax_' sreg]) + strys.(['tauC_' sreg]) * strys.(['P_' sreg]) * strys.(['C_' sreg]) + strys.(['tauH_' sreg]) *  strys.(['PH_' sreg]) * strys.(['IH_' sreg]) + strys.(['PE_' sreg]) * strys.(['E_' sreg])) - (strys.rf) *  strys.(['BG_' sreg]) - strys.(['adaptationcost_' sreg]))/strys.(['P_' sreg]) - strys.(['Tr_' sreg]);
        if strpar.phiG_p > 0
            rhs_G = strys.(['G_' sreg]);
            fval_vec_G(icoreg) = 1 - rhs_G / lhs_G;
        else
            % strys.(['G_' sreg]) = lhs_G;
            strys.(['KG_' sreg]) = strys.(['G_' sreg])/strpar.deltaKG_p;
            % government expenditure
            strys.G = strys.G + strys.(['P_' sreg]) * strys.(['G_' sreg]);
        end
    end
    %% evaluate resiudals for: 
    % - HH FOC w.r.t. labour in each region and subsector
    % - Firms FOC w.r.t. intermediate goods in each region and subsector
    % - Export demand for each region and subsector

    strpar.sMaxsec = num2str(strpar.inbsectors_p);

    fval_vec_1 = nan(strpar.(['subend_' strpar.sMaxsec '_p'])*strpar.inbregions_p,1);

    fval_vec_2 = nan(strpar.(['subend_' strpar.sMaxsec '_p'])*strpar.inbregions_p,1);

    fval_vec_3 = nan(strpar.(['subend_' strpar.sMaxsec '_p'])*strpar.inbregions_p,1);

    fval_vec_4 = nan(strpar.(['subend_' strpar.sMaxsec '_p'])*strpar.inbregions_p,1);

    fval_vec_5 = nan(strpar.inbregions_p,1);            

    fval_vec_6 = nan(strpar.inbregions_p,1);            

    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);       
        strys.(['Xhelp_' sreg ]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                temp=(strpar.(['D_X_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_X_' ssubsec '_' sreg]))) * ((strys.(['P_Q_' ssubsec '_' sreg]))/strys.(['P_Q_' sreg])^1)^(-strpar.etaX_p);
                strys.(['Xhelp_' sreg ]) = strys.(['Xhelp_' sreg ]) + temp;
            end
        end

        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);

                icovec = icosubsec + strpar.(['subend_' num2str(strpar.inbsectors_p) '_p']) * (icoreg-1);



                if strpar.(['lEndoN_'  ssubsec '_' sreg '_p']) == 1
                    lhs = (1 - strys.(['tauNH_' sreg])) * strys.(['W_' ssubsec '_' sreg]) * strys.(['LF_' sreg]) / strys.(['PoP_' sreg]) * strys.(['lambda_' sreg]);
                    rhs = strpar.(['phiL_' ssubsec '_' sreg '_p']) * strys.(['A_N_' ssubsec '_' sreg]) * (strys.(['N_' ssubsec '_' sreg]))^(strpar.sigmaL_p);
                else
                    lhs = strys.(['N_' ssubsec '_' sreg]);
                    rhs = strpar.(['phiN0_' ssubsec '_' sreg '_p']) * strpar.(['N0_' sreg '_p']) * exp(strexo.(['exo_Q_' ssubsec '_' sreg]));
                end
                fval_vec_1(icovec) = 1 - lhs./rhs;

                lhs = strys.(['P_I_' ssubsec '_' sreg]) / (strys.(['P_Q_' ssubsec '_' sreg]) - strys.(['kappaE_' ssubsec '_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]));
                % lhs = strys.(['P_I_' ssubsec '_' sreg]) / strys.(['P_' ssubsec '_' sreg]);

                rhs = strys.(['A_I_' ssubsec '_' sreg])^((strpar.(['etaI_' ssubsec '_p'])-1)/strpar.(['etaI_' ssubsec '_p'])) * (strpar.(['omegaQI_' ssubsec '_' sreg '_p']))^(1/strpar.(['etaI_' ssubsec '_p'])) * (strys.(['Q_I_' ssubsec '_' sreg])/strys.(['Q_' ssubsec '_' sreg]))^(-1/strpar.(['etaI_' ssubsec '_p']));
                % rhs = strys.(['A_I_' ssubsec '_' sreg])^((strpar.(['etaI_' ssubsec '_p'])-1)/strpar.(['etaI_' ssubsec '_p'])) * (strpar.(['omegaQI_' ssubsec '_' sreg '_p'])/(1-strpar.(['omegaQI_' ssubsec '_' sreg '_p'])))^(1/strpar.(['etaI_' ssubsec '_p'])) * (strys.(['Q_I_' ssubsec '_' sreg])/strys.(['Y_' ssubsec '_' sreg]))^(-1/strpar.(['etaI_' ssubsec '_p']));



                fval_vec_2(icovec) = 1 - lhs./rhs;               

                lhs = strys.(['X_' ssubsec '_' sreg])/strys.(['X_' sreg])^1;
                rhs = strpar.(['D_X_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_X_' ssubsec '_' sreg])) * ((strys.(['P_Q_' ssubsec '_' sreg]) + 0*strys.(['kappaE_' ssubsec '_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]))/strys.(['P_Q_' sreg]))^(-strpar.etaX_p);

                fval_vec_3(icovec) = 1 - (1+lhs)/(1+rhs);

                lhs = strys.(['Q_' ssubsec '_' sreg]) - strys.(['X_' ssubsec '_' sreg]);

                temp = 0;
                for icoregm = 1:strpar.inbregions_p
                    sregm = num2str(icoregm);
                    temp = temp  + strys.(['Q_D_' ssubsec '_' sregm '_' sreg]);                

                end
                rhs = temp;

                fval_vec_4(icovec) = 1 - lhs/rhs;

            end

        end
        if strpar.etaQ_p == 1
            lhs = strys.(['P_D_' sreg]);
            rhs = 1;
            for icosec = 1:strpar.inbsectors_p
                ssec = num2str(icosec);
                rhs = rhs*(strys.(['P_A_' ssec '_' sreg])/(strys.(['A_F_' ssec '_' sreg])*strpar.(['omegaQA_' ssec '_' sreg '_p'])))^strpar.(['omegaQA_' ssec '_' sreg '_p']);
            end
        else
            lhs = strys.(['P_D_' sreg]);
            rhs = 0;
            for icosec = 1:strpar.inbsectors_p
                ssec = num2str(icosec);
                rhs = rhs + strpar.(['omegaQA_' ssec '_' sreg '_p']) * (strys.(['P_A_' ssec '_' sreg])/strys.(['A_F_' ssec '_' sreg]))^((1-strpar.etaQ_p));
            end
            rhs = rhs^(1/(1-strpar.etaQ_p));
        end
        fval_vec_5(icoreg) = 1 - lhs/rhs;
        rhs = strys.(['sF_' sreg]);
        lhs = strys.(['Q_D_' strpar.ssubsecfossil '_' sreg])/ strys.(['Q_A_' strpar.ssecenergy '_' sreg]);
        fval_vec_6(icoreg) = 1 - lhs/rhs;

    end




    if strpar.lCalibration_p ==2
        if strpar.phiG_p > 0
            fval_vec = [fval_vec_1(:); fval_vec_3(:); fval_vec_4(:); fval_vec_5(:); fval_vec_6(:); fval_vec_G(:)];
        else
            fval_vec = [fval_vec_1(:); fval_vec_3(:); fval_vec_4(:); fval_vec_5(:); fval_vec_6(:)];
        end
    else

        if strpar.phiG_p > 0
            fval_vec = [fval_vec_1(:); fval_vec_2(:); fval_vec_3(:); fval_vec_4(:); fval_vec_5(:); fval_vec_6(:); fval_vec_G(:)];

        else
            fval_vec = [fval_vec_1(:); fval_vec_2(:); fval_vec_3(:); fval_vec_4(:); fval_vec_5(:); fval_vec_6(:)];

        end
    end
    if strpar.lExoNX_p == 1 
%        evaluation of the net export to gross value added ratio
        if strpar.lEndogenousY_p == 0
            fval_vec_NX = strys.NX./strys.Y - (strpar.NX0_p + strexo.exo_NX);
        else
            fval_vec_NX = strys.NX/(strpar.NX0_p * strys.Y)-1;
        end
        fval_vec = [fval_vec; fval_vec_NX];
    end

    if any(strys.lEndoQvec(:) == 0)
        fval_vec_8 = nan(sum(strys.lEndoQvec==0)*1, 1);
        icomatch = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                for icoreg = 1:strpar.inbregions_p
                    sreg = num2str(icoreg);
                    if strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) == 0
                        icomatch = icomatch + 1;
                        lhs1 = strys.(['Q_' ssubsec '_' sreg]);
                        rhs1 = strpar.(['Q0_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_Q_' ssubsec '_' sreg])); %# ok
                        fval_vec_8(icomatch) = 1-lhs1/rhs1;
                    end
                end
            end
        end
        fval_vec = [fval_vec; fval_vec_8];
    end

   if strpar.lEndoMig_p == 1
        fval_vec_10 = nan(strpar.inbregions_p, 1);
        denominator = 0;
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);
            denominator = denominator + strpar.(['omegaLF0_' sreg '_p']) * exp(strexo.(['exo_LF_' sreg])) * (strys.(['W_' sreg]) / strys.W)^(strpar.etaLF_p);
        end

        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);
            lhs = strys.(['LF_' sreg]);
            rhs = strpar.(['omegaLF0_' sreg '_p']) * exp(strexo.(['exo_LF_' sreg])) * (strys.(['W_' sreg]) / strys.W)^(strpar.etaLF_p) / denominator * strys.LF;
            fval_vec_10(icoreg) = 1-lhs/rhs;
        end
        fval_vec = [fval_vec; fval_vec_10];
    end

    % find subsisdy rate to distribute respective share of emission
    % certificates
    if strexo.exo_CapTradeInternat == 1 && strpar.lEndogenousY_p == 1
        % evaluation of the emissions
        fval_vec_E = (1 + strys.E) / (1 + strpar.E0_p * exp(strexo.exo_E))-1;
        fval_vec = [fval_vec; fval_vec_E];
    else
        strys.EMIEXP = 0;
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);
            if strexo.(['exo_CapTrade_' sreg]) == 1% && strpar.lEndogenousY_p == 1
                fval_vec_E = strys.(['E_' sreg]) / (strpar.(['E0_' sreg '_p']) * exp(strexo.(['exo_EBase_' sreg])+strexo.(['exo_E_' sreg])))-1;
                fval_vec = [fval_vec(:); fval_vec_E];
            end
            strys.EMIEXP = strys.EMIEXP + strys.(['PE_' sreg]) * strys.(['E_' sreg]);
        end
        % strys.PE = strpar.PE0_p;
    end


    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        if strexo.(['exo_tauSTr_' sreg]) > 0
            lhs = strys.(['Tr_' sreg]);
            rhs = strpar.(['Tr0_' sreg '_p'])  + strexo.(['exo_Tr_' sreg]) + strexo.(['exo_tauSTr_' sreg]) * strys.(['PE_' sreg]) * strys.(['E_' sreg]);
            fval_vec = [fval_vec(:); lhs/rhs-1];
        end
    end

    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        if strexo.(['exo_tauS_' sreg]) > 0
            lhs = strys.(['capitalexp_' sreg]) * strys.(['tauS_' sreg]);
            rhs = strexo.(['exo_tauS_' sreg]) * strys.(['PE_' sreg]) * strys.(['E_' sreg]);
            fval_vec = [fval_vec(:); lhs/rhs-1];
        end
    end

    if strpar.iSecHouse_p ~= 0
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);
            if strpar.lEndogenousY_p == 0
                % house prices
                lhs = strys.(['PH_' sreg]);
                rhs = (strpar.(['gamma_' sreg '_p'])/((1 - strpar.(['gamma_' sreg '_p'])) * (1-strpar.beta_p * exp(strexo.exo_beta) * strpar.h_p))  * strpar.beta_p * exp(strexo.exo_beta) / (1 - strpar.beta_p * exp(strexo.exo_beta) * (1 - strpar.deltaH_p)) * (1-strpar.h_p)*strys.(['C_' sreg]) * strys.(['P_' sreg]) * (1 + strys.(['tauC_' sreg]))) / (strys.(['H_' sreg]) * (1 + strys.(['tauH_' sreg])));    
            else
                % housing stock
                lhs = strys.(['H_' sreg]);
                rhs = (strpar.(['gamma_' sreg '_p'])/((1 - strpar.(['gamma_' sreg '_p']))* (1-strpar.beta_p * exp(strexo.exo_beta) * strpar.h_p))  * strpar.beta_p * exp(strexo.exo_beta) / (1 - strpar.beta_p * exp(strexo.exo_beta) * (1 - strpar.deltaH_p)) * (1-strpar.h_p)*strys.(['C_' sreg]) * strys.(['P_' sreg]) * (1 + strys.(['tauC_' sreg]))) / (strys.(['PH_' sreg]) * (1 + strys.(['tauH_' sreg])));    
            end
            fval_vec = [fval_vec(:); lhs/rhs-1];
        end
    end

    if ismember('A_I_1_1', fieldnames(strpar.InitGuess))
        fval_vec_9 = nan(strpar.(['subend_' strpar.sMaxsec '_p'])*strpar.inbregions_p,1);
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                for icoreg = 1:strpar.inbregions_p
                    sreg = num2str(icoreg);
                    icomatch = icomatch + 1;
                    lhs1 = strys.(['Q_I_' ssubsec '_' sreg])/strys.(['Q_' ssubsec '_' sreg]);
                    rhs1 = strpar.(['Q_I0_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_QI_' ssubsec '_' sreg])); %# ok
                    fval_vec_9(icomatch) = 1-lhs1/rhs1;
                end
            end
        end
        fval_vec = [fval_vec(:); fval_vec_9(:)];
    end
    if strpar.lCalibration_p == 2
        fval_vec_10 = [];
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);
            for icosec = 1:strpar.inbsectors_p
                ssec = num2str(icosec);
                for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                    ssubsec = num2str(icosubsec);
                    lhs = strys.(['E_' ssubsec '_' sreg'])+1;
                    E0secreg = strpar.(['E0_' sreg' '_p']) * strpar.(['sE_' ssubsec '_' sreg' '_p']);
                    rhs = E0secreg * exp(strexo.(['exo_E_' ssubsec '_'  sreg]))+1;
                    fval_vec_10 = [fval_vec_10; 1-lhs/rhs];%#ok
                end
            end
        end
        fval_vec = [fval_vec(:); fval_vec_10(:)];

        fval_vec_11 = [];
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);
            ssubsec = num2str(strpar.iSubsecFossil_p);
            lhs = strys.(['Q_' ssubsec '_' sreg])+1;
            Q0secreg = strpar.(['Q0_'  ssubsec '_' sreg '_p']);
            rhs =  Q0secreg * exp(strexo.(['exo_Q_' ssubsec '_'  sreg]))+1;
            fval_vec_11 = [fval_vec_11; 1-lhs/rhs];%#ok
        end
        fval_vec = [fval_vec(:); fval_vec_11(:)];
    end
    
    


end