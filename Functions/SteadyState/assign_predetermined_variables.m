function [strys,strpar, strexo] = assign_predetermined_variables(strys,strpar, strexo)
    % function [strys,strpar, strexo] = assign_predetermined_variables(strys,strpar, strexo)
    % assigns values for predetermined variables of the model. 
    % Inputs: 
    %   - strys     [structure]  structure containing all endogeonous variables of the model
    %   - strexo    [structure]  structure containing all exogeonous variables of the model    
    %   - strpar    [structure]  structure containing all parameters of the model
    %
    % Output: 

    %   - strys     [structure] see inputs
    %   - strexo    [structure] see inputs
    
    %% calculate exogenous variables
    % population stock
    strys.LF = 0;
    strys.PoP = 0;
    strpar.E0_p = 0;
    strpar.E0_NOETS_p = 0;
    strpar.EMIEXP0_p = 0;
    % tax rates
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);    
        strpar.E0_p = strpar.E0_p + strpar.(['E0_' sreg '_p']);
        strpar.E0_NOETS_p = strpar.E0_NOETS_p + strpar.(['E0_NOETS_' sreg '_p']);
        % tax rates
        if strexo.exo_CapTradeInternat == 0
            if strexo.(['exo_CapTrade_' sreg]) == 0
                strys.(['PE_' sreg]) = strpar.(['PE0_' sreg '_p']) + strexo.(['exo_PE_' sreg]) + strexo.exo_PE;
            end
        else
            strys.(['PE_' sreg]) = strpar.(['PE0_' sreg '_p']) + strexo.(['exo_PE_' sreg]) + strexo.exo_PE;
        end 
        strpar.EMIEXP0_p = strpar.EMIEXP0_p + strpar.(['PE0_' sreg '_p']) * strpar.(['E0_' sreg '_p']);
        if strpar.lEndoMig_p == 0 || strpar.lCalibration_p == 1
            % labour force
            strys.(['LF_' sreg]) = strpar.(['LF0_' sreg '_p']) * exp(strexo.(['exo_LF_' sreg]));
        end
        if strpar.lCalibration_p ~= 2
            strys.(['EE_' sreg]) = exp(strexo.(['exo_EE_' sreg]));
        end
        strys.LF = strys.LF + strys.(['LF_' sreg]);
        % population stock
        strys.(['PoP_' sreg]) = strys.(['LF_' sreg]) + (strpar.(['PoP0_' sreg '_p'])-strpar.(['LF0_' sreg '_p'])) * exp(strexo.(['exo_NLF_' sreg]));
        strys.PoP = strys.PoP + strys.(['PoP_' sreg]);
        strys.(['tauNH_' sreg]) = strpar.(['tauNH_' sreg '_p']) + strexo.(['exo_tauNH_' sreg]);
        if strpar.lCalibration_p ~= 2
            strys.(['tauCEndo_' sreg]) = strpar.(['tauC_' sreg '_p']) + strexo.(['exo_tauC_' sreg]) + strexo.(['exo_tauCScen_' sreg]);
        end
        strys.(['tauC_' sreg]) = strys.(['tauCEndo_' sreg]);
        strys.(['tauH_' sreg]) = strpar.(['tauH_' sreg '_p']) + strexo.(['exo_tauH_' sreg]);
        % government foreign debt 
        strys.(['BG_' sreg]) = (strpar.(['BG0_' sreg '_p']) + strexo.(['exo_BG_' sreg]))*strpar.Y0_p;
        strys.(['I_PV_' sreg]) = (strpar.phiKPV0_p*strpar.deltaPV_p + strexo.(['exo_PV_' sreg])) * strpar.Y0_p;
        strys.(['K_PV_' sreg]) = strys.(['I_PV_' sreg])/strpar.deltaPV_p;
        strys.(['Q_PV_' sreg]) = strys.(['K_PV_' sreg])*strpar.phiPV_p*exp(strexo.(['exo_PVEff_' sreg]));

    end

    % In hybrid steady-state calibration we pin subsector emissions via exo_E_{subsec,reg}
    % residuals. Ensure the regional cap shock exo_E_reg is consistent with those pins,
    % otherwise the cap equation can remain structurally nonzero.
    if strpar.lCalibration_p == 2
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);
            lCapActive = strexo.exo_CapTradeInternat == 1;
            if ~lCapActive && isfield(strexo, ['exo_CapTrade_' sreg])
                lCapActive = strexo.(['exo_CapTrade_' sreg]) == 1;
            end
            if ~lCapActive
                continue
            end

            eTargetSector = 0;
            for icosec = 1:strpar.inbsectors_p
                ssec = num2str(icosec);
                for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                    ssubsec = num2str(icosubsec);
                    e0secreg = strpar.(['E0_' sreg '_p']) * strpar.(['sE_' ssubsec '_' sreg '_p']);
                    eTargetSector = eTargetSector + e0secreg * exp(strexo.(['exo_E_' ssubsec '_' sreg]));
                end
            end

            e0reg = strpar.(['E0_' sreg '_p']);
            capShift = (strexo.(['exo_PE_' sreg]) + strexo.exo_PE + strexo.exo_CapTradeInternat + strexo.(['exo_CapTrade_' sreg])) * strpar.phiG_p;
            eTargetReg = eTargetSector + capShift;
            if isfinite(eTargetReg) && eTargetReg > 0 && isfinite(e0reg) && e0reg > 0
                strexo.(['exo_E_' sreg]) = log(eTargetReg / e0reg) - strexo.(['exo_EBase_' sreg]);
            end
        end
    end

    strpar.PE0_p = strpar.EMIEXP0_p /strpar.E0_p;
    % Calibrate SRI wedge parameter from share of SCC internalized:
    % phiKE_p = chiSRI_p * PE_ss/P_ss, with P_ss = 1 in model normalization.
    % wedgeKE_s = phiKE_p * kappaE_s * Gamma_s raises r_H_s proportionally to
    % lifetime emission intensity, where Gamma_s = beta*(1-delta_s)/(1-beta*(1-delta_s))
    % is the capital-lifetime annuity factor (Oehmke-Opp 2025 / SCC lifetime approach).
    if strpar.chiSRI_p > 0
        strpar.phiKE_p = strpar.chiSRI_p * strpar.PE0_p;
    end
    if strpar.lCalibration_p == 1
        strys.PE = strpar.PE0_p;
    end
    if strpar.lCalibration_p == 1
        strys.capitalexp2 = 0;
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);
            strys.(['capitalexp2_' sreg]) = 0;
            for icosec = 1:strpar.inbsectors_p
                ssec = num2str(icosec);
                for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                    ssubsec = num2str(icosubsec);
                    strys.(['capitalexp2_' sreg]) = strys.(['capitalexp2_' sreg]) + strpar.(['phiY_' ssubsec '_' sreg '_p']) * (1-strpar.(['phiW_' ssubsec '_' sreg '_p'])) * strpar.Y0_p;
                end
            end
            strys.(['SE_' sreg]) = strexo.(['exo_tauS_' sreg]) * strpar.phitauS_p * strpar.(['E0_' sreg '_p']) * strys.(['PE_' sreg]);
            strys.(['tauS_' sreg]) = strys.(['SE_' sreg]) /(strys.(['capitalexp2_' sreg]) + strys.(['SE_' sreg]));
            strys.capitalexp2 = strys.capitalexp2 + strys.(['capitalexp2_' sreg]);
            strys.(['adjB_' sreg]) = strexo.(['exo_adjB_' sreg]);
            strys.(['deltaB_' sreg]) = strexo.(['exo_deltaB_' sreg]);
        end

    end
    
    
    for icosec = 1:strpar.inbsectors_p
        ssec = num2str(icosec);
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                if icosubsec ~= strpar.iSubsecFossil_p
                    strys.(['tauKF_' ssubsec '_' sreg]) = strpar.(['tauKF_' ssubsec '_' sreg '_p']) - strys.(['tauS_' sreg]) + strexo.(['exo_tauKF_' ssubsec '_' sreg]);
                else
                    strys.(['tauKF_' ssubsec '_' sreg]) = strpar.(['tauKF_' ssubsec '_' sreg '_p']) + strexo.(['exo_tauKF_' ssubsec '_' sreg]);
                end
                strys.(['tauKH_' ssubsec '_' sreg]) = strpar.(['tauKH_' ssubsec '_' sreg '_p']) + strexo.(['exo_tauKH_' ssubsec '_' sreg]);
                strys.(['tauNF_' ssubsec '_' sreg]) = strpar.(['tauNF_' ssubsec '_' sreg '_p']) + strexo.(['exo_tauNF_' ssubsec '_' sreg]);
                strys.(['s_G_' ssubsec '_' sreg]) = strpar.(['s_G_' ssubsec '_' sreg '_p']) + strexo.(['exo_s_G_' ssubsec '_' sreg]) + strexo.(['exo_s_GScen_' ssubsec '_' sreg]);
            end
        end
    end
    
    
       
    % exogenous sectoral productivity for capital, damages to TFP, capital
    % and labour, adaptation capital stocks and expenditures
    for icosec = 1:strpar.inbsectors_p
        ssec = num2str(icosec);
        strys.(['A_F_' ssec '_' sreg]) = exp(strexo.(['exo_A_F_' ssec '_' sreg]) ...
            +log(strys.(['EE_' sreg]))*(icosec == strpar.iSecEnergy_p) ...
            +0*log(max(1e-3,strys.(['K_PV_' sreg])))*(icosec == strpar.iSecEnergy_p) ...
            );
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);
            strys.(['D_KHelp_' ssec '_' sreg]) = 0;
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])  
                ssubsec = num2str(icosubsec);
                strys.(['A_I_' ssubsec '_' sreg]) = exp(strexo.(['exo_A_I_' ssubsec '_' sreg]));
                strys.(['A_D_' ssubsec '_' sreg]) = exp(strexo.(['exo_A_D_' ssubsec '_' sreg]));

                strys.(['K_A_' ssubsec '_' sreg]) = strexo.(['exo_GA_' ssubsec '_' sreg]) * strpar.Y0_p;
                strys.(['G_A_' ssubsec '_' sreg]) = strpar.(['deltaKA_' ssubsec '_' sreg '_p']) * strys.(['K_A_' ssubsec '_' sreg]);
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);
                    exoAI = strexo.(['exo_AI_' ssubsec '_' sreg '_' ssecm]);
                    lSectorEE = strexo.(['exo_A_I_' ssubsec '_' sreg]) ~= 0;
                    lAddEEKey = ['exo_lAddEE_' ssubsec '_' sreg];
                    lAddEE = 1;
                    if isfield(strexo, lAddEEKey) && isfinite(strexo.(lAddEEKey))
                        lAddEE = strexo.(lAddEEKey);
                    end
                    EEreg = strys.(['EE_' sreg])^(lAddEE * (icosecm == strpar.iSecEnergy_p) * (~lSectorEE));
                    strys.(['A_I_' ssubsec '_' sreg '_' ssecm]) = exp(exoAI)*EEreg;
                end
                strys.(['A_K_' ssubsec '_' sreg]) = strpar.(['A_K_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_K_' ssubsec '_' sreg]));
                phiK_correction = strpar.phiG_p * (strexo.(['exo_I_' ssubsec '_' sreg]) + strexo.(['exo_P_K_' ssubsec '_' sreg]));
                if icosubsec == strpar.iSubsecFossil_p
                    strys.(['phiK_' ssubsec '_' sreg]) = min(1000, strpar.(['phiK_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_phiK_' ssubsec '_' sreg])) * exp(0*strpar.phiKPE_p*(strys.(['PE_' sreg])-strpar.(['PE0_' sreg '_p']))) - phiK_correction);
                else
                    strys.(['phiK_' ssubsec '_' sreg]) = strpar.(['phiK_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_phiK_' ssubsec '_' sreg])) - phiK_correction;
                end

                strys.(['D_' ssubsec '_' sreg]) = strexo.(['exo_D_' ssubsec '_' sreg]);
                strys.(['delta_' ssubsec '_' sreg]) = strpar.(['delta_' ssubsec '_' sreg '_p']);
                strys.(['D_N_' ssubsec '_' sreg]) = strexo.(['exo_D_N_' ssubsec '_' sreg]);
                % strys.(['D_K_' ssubsec '_' sreg]) = strexo.(['exo_D_K_' ssubsec '_' sreg]) * strpar.Y0_p/strpar.(['P0_' ssubsec '_' sreg '_p']);
                strys.(['D_K_' ssubsec '_' sreg]) = strexo.(['exo_D_K_' ssubsec '_' sreg]) * strpar.(['K0_' ssubsec '_' sreg '_p']);
                strys.(['D_KHelp_' ssec '_' sreg]) = strys.(['D_KHelp_' ssec '_' sreg]) + strys.(['D_K_' ssubsec '_' sreg]);
                strys.(['u_K_' ssubsec '_' sreg]) = exp(strexo.(['exo_u_K_' ssubsec '_' sreg]));
                if strpar.lCalibration_p ~= 2
                    strys.(['kappaE_' ssubsec '_' sreg]) = strpar.(['kappaE_' ssubsec '_' sreg '_p']) + strexo.(['exo_kappaE_' ssubsec '_' sreg]);
                    lNOETSTarget = 0;
                    lNOETSTargetKey = ['exo_lE_NOETS_Target_' ssubsec '_' sreg];
                    if isfield(strexo, lNOETSTargetKey) && isfinite(strexo.(lNOETSTargetKey))
                        lNOETSTarget = strexo.(lNOETSTargetKey);
                    end

                    if lNOETSTarget >= 0.5
                        E0secregNOETS = strpar.(['E0_NOETS_' sreg '_p']) * strpar.(['sE_NOETS_' ssubsec '_' sreg '_p']);
                        ETargetNOETS = E0secregNOETS * exp(strexo.(['exo_E_NOETS_' ssubsec '_' sreg]));
                        qDen = strys.(['Q_' ssubsec '_' sreg]);
                        if ~isfinite(qDen) || abs(qDen) < 1e-12
                            qDen = sign(qDen) * 1e-12 + (qDen == 0) * 1e-12;
                        end
                        strys.(['kappaE_NOETS_' ssubsec '_' sreg]) = ETargetNOETS / qDen;
                    else
                        strys.(['kappaE_NOETS_' ssubsec '_' sreg]) = strpar.(['kappaE_NOETS_' ssubsec '_' sreg '_p']) + strexo.(['exo_kappaE_NOETS_' ssubsec '_' sreg]);
                    end
                end
                strys.(['wedgeKE_' ssubsec '_' sreg]) = (strpar.phiKE_p + strexo.(['exo_wedgeKE_' ssubsec '_' sreg])) * strys.(['kappaE_' ssubsec '_' sreg]) ...
                    * strpar.beta_p * (1 - strpar.(['delta_' ssubsec '_' sreg '_p'])) / (1 - strpar.beta_p * (1 - strpar.(['delta_' ssubsec '_' sreg '_p'])));
            end
        end
    end
    
    % climate variables
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        for sClimateVar = strpar.casClimatevarsRegional
            strys.([char(sClimateVar) '_' sreg]) = strpar.([char(sClimateVar) '0_' sreg '_p']) + strexo.(['exo_' char(sClimateVar) '_' sreg]);
        end
        if strexo.(['exo_tauSTr_' sreg]) == 0
            strys.(['Tr_' sreg]) = strpar.(['Tr0_' sreg '_p']) + strexo.(['exo_Tr_' sreg]) + strexo.(['exo_tauSTr_' sreg]) * strys.(['PE_' sreg])*strys.(['E_' sreg])*strys.(['PoP_' sreg]) / strys.PoP;
        end
    end
    for sClimateVar = strpar.casClimatevarsNational
        strys.(char(sClimateVar)) = strpar.([char(sClimateVar) '0_p']) + strexo.(['exo_' char(sClimateVar)]);
    end
    % Assign fixed import prices
    for icosec = 1:strpar.inbsectors_p
        ssec = num2str(icosec);
        for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
            ssubsec = num2str(icosubsec);
            strys.(['P_M_' ssubsec]) = strys.(['P_Q_' ssubsec '_1']) + strexo.(['exo_M_' ssubsec]);
        end
    end
 

end


