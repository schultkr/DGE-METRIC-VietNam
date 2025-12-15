function [strys,strpar, strexo] = assignPredeterminedVariables(strys,strpar, strexo)
    % function [strys,strpar, strexo] = AssignPredeterminedVariables(strys,strpar, strexo)
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
    strpar.EMIEXP0_p = 0;
    % tax rates
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);    
        strpar.E0_p = strpar.E0_p + strpar.(['E0_' sreg '_p']);
        % tax rates
        if strexo.exo_CapTradeInternat == 0
            if strexo.(['exo_CapTrade_' sreg]) == 0
                strys.(['PE_' sreg]) = strpar.(['PE0_' sreg '_p']) + strexo.(['exo_PE_' sreg]) + strexo.exo_PE;
            end
        else
            strys.(['PE_' sreg]) = strys.PE;
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
        strys.(['tauKH_' sreg]) = strpar.(['tauKH_' sreg '_p']) + strexo.(['exo_tauKH_' sreg]);
        strys.(['tauNH_' sreg]) = strpar.(['tauNH_' sreg '_p']) + strexo.(['exo_tauNH_' sreg]);
        strys.(['tauC_' sreg]) = strpar.(['tauC_' sreg '_p']) + strexo.(['exo_tauC_' sreg]);
        strys.(['tauH_' sreg]) = strpar.(['tauH_' sreg '_p']) + strexo.(['exo_tauH_' sreg]);
        % government foreign debt 
        strys.(['BG_' sreg]) = strexo.(['exo_BG_' sreg]);

    end
    strpar.PE0_p = strpar.EMIEXP0_p /strpar.E0_p;
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
                strys.(['tauKF_' ssubsec '_' sreg]) = strpar.(['tauKF_' ssubsec '_' sreg '_p']) - strys.(['tauS_' sreg]) + strexo.(['exo_tauKF_' ssubsec '_' sreg]);
                strys.(['tauNF_' ssubsec '_' sreg]) = strpar.(['tauNF_' ssubsec '_' sreg '_p']) + strexo.(['exo_tauNF_' ssubsec '_' sreg]);
            end
        end
    end
    
    
       
    % exogenous sectoral productivity for capital, damages to TFP, capital
    % and labour, adaptation capital stocks and expenditures
    for icosec = 1:strpar.inbsectors_p
        ssec = num2str(icosec);
        strys.(['A_F_' ssec '_' sreg]) = exp(strexo.(['exo_A_F_' ssec '_' sreg]))*strys.(['EE_' sreg])^((icosec == strpar.iSecEnergy_p));
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);
            strys.(['D_KHelp_' ssec '_' sreg]) = 0;
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])  
                ssubsec = num2str(icosubsec);
                strys.(['A_I_' ssubsec '_' sreg]) = exp(strexo.(['exo_A_I_' ssubsec '_' sreg]));
                    for icosecm = 1:strpar.inbsectors_p
                        ssecm = num2str(icosecm);       
                        EEreg = strys.(['EE_' sreg])^((icosecm == strpar.iSecEnergy_p));
                        exoAI = strexo.(['exo_AI_' ssubsec '_' sreg '_' ssecm]);
                        strys.(['A_I_' ssubsec '_' sreg '_' ssecm]) = exp(exoAI)*EEreg;
                    end
                strys.(['A_K_' ssubsec '_' sreg]) = strpar.(['A_K_' ssubsec '_' sreg '_p']) * exp(strexo.(['exo_K_' ssubsec '_' sreg]));
                strys.(['D_' ssubsec '_' sreg]) = strexo.(['exo_D_' ssubsec '_' sreg]);
                strys.(['D_N_' ssubsec '_' sreg]) = strexo.(['exo_D_N_' ssubsec '_' sreg]);
                strys.(['D_K_' ssubsec '_' sreg]) = strexo.(['exo_D_K_' ssubsec '_' sreg]) * strpar.Y0_p;
                strys.(['D_KHelp_' ssec '_' sreg]) = strys.(['D_KHelp_' ssec '_' sreg]) + strys.(['D_K_' ssubsec '_' sreg]);
                strys.(['K_A_' ssubsec '_' sreg]) = strexo.(['exo_GA_' ssubsec '_' sreg]) * strpar.Y0_p;
                strys.(['G_A_' ssubsec '_' sreg]) = strpar.(['deltaKA_' ssubsec '_' sreg '_p']) * strys.(['K_A_' ssubsec '_' sreg]);
                if strpar.lCalibration_p ~= 2
                    strys.(['kappaE_' ssubsec '_' sreg]) = strpar.(['kappaE_' ssubsec '_' sreg '_p']) + strexo.(['exo_kappaE_' ssubsec '_' sreg]);
                end
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
            % if strpar.lCalibration_p ~= 2 
                % strys.(['P_M_' ssubsec]) = strpar.(['P_M_' ssubsec '_p']) + strexo.(['exo_M_' ssubsec]);
            % else 
                strys.(['P_M_' ssubsec]) = strys.(['P_Q_' ssubsec '_1']) + strexo.(['exo_M_' ssubsec]);
                % strexo.(['exo_M_' ssubsec]) = strys.(['P_M_' ssubsec]) - strpar.(['P_M_' ssubsec '_p']);
            % end
        end
    end
 

end


