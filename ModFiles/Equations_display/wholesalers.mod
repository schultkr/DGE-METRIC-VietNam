// ==========================================
// Block 10: Wholesalers
// ==========================================
@# for reg in 1:Regions
    @# for sec in 1:Sectors
        # rhoQA_@{sec} = (etaQA_@{sec}_p-1+(etaQA_@{sec}_p==1))/etaQA_@{sec}_p;
        # lhsDemandsec_4_@{reg}_@{sec} = Q_A_@{sec}_@{reg};
        # rhsDemandsec_4_@{reg}_@{sec} = 
        (etaQA_@{sec}_p == 1) * 
            exp(
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + log(max(1e-8,Q_D_@{subsec}_@{reg})*A_D_@{subsec}_@{reg}) * omegaQ_@{subsec}_@{reg}_p
            @# endfor
            )+
            (etaQA_@{sec}_p != 1) * (
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + omegaQ_@{subsec}_@{reg}_p^(1/etaQA_@{sec}_p) * (A_D_@{subsec}_@{reg} * max(1e-8,Q_D_@{subsec}_@{reg}))^(rhoQA_@{sec})
            @# endfor
            )^(1/rhoQA_@{sec})
            ;
        [name = 'domestic aggregate sector output']
        lhsDemandsec_4_@{reg}_@{sec} = rhsDemandsec_4_@{reg}_@{sec};
 
        # lhsDemandsec_8_@{reg}_@{sec} = Q_A_@{sec}_@{reg};
        # rhsDemandsec_8_@{reg}_@{sec} = Q_A_F_@{sec}_@{reg} + Q_A_I_@{sec}_@{reg} + (iSecHouse_p == @{sec}) * (IH_@{reg} * PH_@{reg}+I_PV_@{reg})/P_A_@{sec}_@{reg};
        [name = 'aggregate final sector output']    
        lhsDemandsec_8_@{reg}_@{sec} = rhsDemandsec_8_@{reg}_@{sec};
        # lhsDemandsec_9_@{reg}_@{sec} = Q_A_I_@{sec}_@{reg} * P_A_@{sec}_@{reg};
        # rhsDemandsec_9_@{reg}_@{sec} = 
        @# for secm in 1:Sectors 
            @# for subsec in Subsecstart[secm]:Subsecend[secm]
                + Q_I_@{subsec}_@{reg}_@{sec} * (P_A_@{sec}_@{reg} + kappaEI_@{subsec}_@{reg}_@{sec}_p * exp(exo_EI_@{subsec}_@{reg}_@{sec}) * (Q_D_@{SubsecFossil}_@{reg}/Q_A_@{SecEnergy}_@{reg}) * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p)
            @# endfor        
        @# endfor        
        ;
        [name = 'domestic demand for aggregate intermediate sector output']    
        lhsDemandsec_9_@{reg}_@{sec} = rhsDemandsec_9_@{reg}_@{sec};
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
           @# for regm in 1:Regions
                #lhsDemandSubsec_1_@{reg}_@{subsec}_@{regm} = Q_D_@{subsec}_@{reg}_@{regm};
                #rhsDemandSubsec_1_@{reg}_@{subsec}_@{regm} = omegaQ_@{subsec}_@{reg}_@{regm}_p * (P_Q_@{subsec}_@{regm}/P_D_@{subsec}_@{reg})^(-etaQ_@{subsec}_p) * Q_D_@{subsec}_@{reg};
                [name = 'demand for regional sector output']
                lhsDemandSubsec_1_@{reg}_@{subsec}_@{regm} = rhsDemandSubsec_1_@{reg}_@{subsec}_@{regm};
            @# endfor
            #lhsDemandSubsec_1M_@{reg}_@{subsec} = M_I_@{subsec}_@{reg};
            #rhsDemandSubsec_1M_@{reg}_@{subsec} = omegaM_@{subsec}_@{reg}_p * (P_M_@{subsec}/P_D_@{subsec}_@{reg})^(-etaQ_@{subsec}_p) * Q_D_@{subsec}_@{reg};
            [name = 'demand for regional subsector imports']
            lhsDemandSubsec_1M_@{reg}_@{subsec} = rhsDemandSubsec_1M_@{reg}_@{subsec};
            #lhsDemandSubsec_2M_@{reg}_@{subsec} = M_F_@{subsec}_@{reg};
            #rhsDemandSubsec_2M_@{reg}_@{subsec} = omegaM_F_@{subsec}_@{reg}_p * (P_M_@{subsec}/P_M_A_@{sec}_@{reg})^(-etaQA_@{sec}_p) * M_A_F_@{sec}_@{reg};
            [name = 'demand for regional subsector final imports']
            lhsDemandSubsec_2M_@{reg}_@{subsec} = rhsDemandSubsec_2M_@{reg}_@{subsec};
            #lhsDemandSubsec_2_@{reg}_@{subsec} = Q_D_@{subsec}_@{reg};
            #rhsDemandSubsec_2_@{reg}_@{subsec} = 
            (etaQ_@{subsec}_p == 1) * 
            exp(
            @# for regm in 1:Regions
                + log(max(1e-8,Q_D_@{subsec}_@{reg}_@{regm})) * omegaQ_@{subsec}_@{reg}_@{regm}_p
            @# endfor
            + log(max(1e-8,M_I_@{subsec}_@{reg})) * omegaM_@{subsec}_@{reg}_p)+
            (etaQ_@{subsec}_p != 1) * (
            @# for regm in 1:Regions
                + omegaQ_@{subsec}_@{reg}_@{regm}_p^(1/etaQ_@{subsec}_p) * max(1e-8,Q_D_@{subsec}_@{reg}_@{regm})^((etaQ_@{subsec}_p-1)/etaQ_@{subsec}_p)
            @# endfor
            + omegaM_@{subsec}_@{reg}_p^(1/etaQ_@{subsec}_p) * max(1e-8,M_I_@{subsec}_@{reg})^((etaQ_@{subsec}_p-1)/etaQ_@{subsec}_p))^(etaQ_@{subsec}_p/(etaQ_@{subsec}_p-1+(etaQ_@{subsec}_p==1)))
            ;
            [name = 'aggregate demand for subsector regional output']
            lhsDemandSubsec_2_@{reg}_@{subsec} = rhsDemandSubsec_2_@{reg}_@{subsec};

            #lhsDemandSubsec_3_@{reg}_@{subsec} = Q_D_@{subsec}_@{reg};
            #rhsDemandSubsec_3_@{reg}_@{subsec} = omegaQ_@{subsec}_@{reg}_p * A_D_@{subsec}_@{reg}^(etaQA_@{sec}_p-1) * (P_D_@{subsec}_@{reg}/P_A_@{sec}_@{reg})^(-etaQA_@{sec}_p) * Q_A_@{sec}_@{reg};
            [name = 'demand for subsector output']
            lhsDemandSubsec_3_@{reg}_@{subsec} = rhsDemandSubsec_3_@{reg}_@{subsec};
        @# endfor
    @# endfor
@# endfor

