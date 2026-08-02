// ==========================================
// Block 9: Retailers
// ==========================================
@# for reg in 1:Regions
    #FinalDemand_@{reg} = (C_@{reg} + I_@{reg} + (iSecHouse_p == 0) * (PH_@{reg} / P_@{reg} * IH_@{reg}+
                            I_PV_@{reg} / P_@{reg}) + G_@{reg} + I_G_@{reg} + 
                            Q_PV_@{reg} * P_A_@{SecEnergy}_@{reg} / P_@{reg});

    #lhsAggReg_@{reg}_26 = Q_U_@{reg};
    #rhsAggReg_@{reg}_26 = (1-omegaF_@{reg}_p) * (P_D_@{reg}/P_@{reg})^(-etaF_p) * FinalDemand_@{reg};
    [name = 'final demand for domestic production']
    lhsAggReg_@{reg}_26 = rhsAggReg_@{reg}_26;
    #lhsAggReg_@{reg}_9 = M_F_@{reg};
    #rhsAggReg_@{reg}_9 = omegaF_@{reg}_p * (P_F_@{reg}/P_@{reg})^(-etaF_p) * FinalDemand_@{reg};
    [name = 'final demand for imports']
    lhsAggReg_@{reg}_9 = rhsAggReg_@{reg}_9;
    @# for sec in 1:Sectors
       # lhsDemandsec_5_@{reg}_@{sec} = P_M_A_@{sec}_@{reg};//M_A_F_@{sec}_@{reg};
        # rhsDemandsec_5_@{reg}_@{sec} = 
        (etaQA_@{sec}_p == 1) * 
            exp(
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + log(P_M_@{subsec}/omegaM_F_@{subsec}_@{reg}_p) * omegaM_F_@{subsec}_@{reg}_p
            @# endfor
            )+
            (etaQA_@{sec}_p != 1) * (
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + omegaM_F_@{subsec}_@{reg}_p * P_M_@{subsec}^(1-etaQA_@{sec}_p)
            @# endfor
            )^(1/(1-etaQA_@{sec}_p+(etaQA_@{sec}_p==1)))
            ;
        [name = 'domestic aggregate sector imports']
        lhsDemandsec_5_@{reg}_@{sec} = rhsDemandsec_5_@{reg}_@{sec};
        # Q_Eff_A_F_@{sec}_@{reg} = Q_A_F_@{sec}_@{reg} + (@{sec} == @{SecEnergy})*Q_PV_@{reg};
        # lhsDemandsec_6_@{reg}_@{sec} = Q_Eff_A_F_@{sec}_@{reg};
        # rhsDemandsec_6_@{reg}_@{sec} = omegaQA_@{sec}_@{reg}_p * A_F_@{sec}_@{reg}^(etaQ_p-1) * (P_A_@{sec}_@{reg}/P_D_@{reg})^(-etaQ_p) * Q_U_@{reg};
        [name = 'domestic demand for aggregate final sector output']    
        lhsDemandsec_6_@{reg}_@{sec} = rhsDemandsec_6_@{reg}_@{sec};
        # lhsDemandsec_7_@{reg}_@{sec} = M_A_F_@{sec}_@{reg};
        # rhsDemandsec_7_@{reg}_@{sec} = omegaMA_F_@{sec}_@{reg}_p * (P_M_A_@{sec}_@{reg}/P_F_@{reg})^(-etaQ_p) * M_F_@{reg};
        [name = 'domestic demand for aggregate final sector imports']
        lhsDemandsec_7_@{reg}_@{sec} = rhsDemandsec_7_@{reg}_@{sec};
    @# endfor
@# endfor

