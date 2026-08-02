// ==========================================
// Block 7: Government
// ==========================================
@# for reg in 1:Regions
    #lhsAggReg_@{reg}_IG = I_G_@{reg} * P_@{reg};
    #rhsAggReg_@{reg}_IG = 
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            + (I_G_@{subsec}_@{reg} + G_A_@{subsec}_@{reg}) * P_INV_@{subsec}_@{reg}
        @# endfor
    @# endfor
    ;
    
    [name = 'regional government investment @{reg}']
    lhsAggReg_@{reg}_IG = rhsAggReg_@{reg}_IG;

    #lhsAggReg_@{reg}_27 = P_@{reg} * G_@{reg} + P_@{reg} * I_G_@{reg} + Tr_@{reg} + BG_@{reg};
    #rhsAggReg_@{reg}_27 = tauC_@{reg} * P_@{reg} * C_@{reg} + IH_@{reg} * PH_@{reg} * tauH_@{reg} + PE_@{reg} * E_@{reg}
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + (tauKF_@{subsec}_@{reg}*r_F_@{subsec}_@{reg}+tauKH_@{subsec}_@{reg}*r_H_@{subsec}_@{reg}) * K_@{subsec}_@{reg}(-1) * P_K_@{subsec}_@{reg}  
                + (tauNF_@{subsec}_@{reg}+tauNH_@{reg}) * W_@{subsec}_@{reg} * N_@{subsec}_@{reg} * LF_@{reg}
                + r_G_@{subsec}_@{reg} * P_K_@{subsec}_@{reg} * K_G_@{subsec}_@{reg}(-1)
            @# endfor
        @# endfor
    + (1 + rf) * ((phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}) * s_@{reg}(-1) + (1 - (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}))) * BG_@{reg}(-1);
    [name = 'regional government budget constraint @{reg}']
    lhsAggReg_@{reg}_27 = rhsAggReg_@{reg}_27;
    #lhsAggReg_@{reg}_28 = Tr_@{reg};
    #rhsAggReg_@{reg}_28 = Tr0_@{reg}_p + exo_Tr_@{reg} + exo_tauSTr_@{reg} * PE_@{reg} * E_@{reg};
    [name = 'regional transfers @{reg}']
    lhsAggReg_@{reg}_28 = rhsAggReg_@{reg}_28;
    #lhsAggNat_7_@{reg} = G_A_DH_@{reg};
    #rhsAggNat_7_@{reg} = exo_G_A_DH * Y0_p;
    [name = 'adaptation measures for housing stock @{reg}']
    lhsAggNat_7_@{reg} = rhsAggNat_7_@{reg};
    #lhsGov_1_@{reg} = BG_@{reg};
    #rhsGov_1_@{reg} = (BG0_@{reg}_p + exo_BG_@{reg})*Y0_p;
    [name = 'Government Budget Constraint @{reg}']
    lhsGov_1_@{reg} = rhsGov_1_@{reg};
    
    #lhsGov_11_@{reg} = KG_@{reg};
    #rhsGov_11_@{reg} = (1 - deltaKG_p) * KG_@{reg}(-1) + G_@{reg};
    [name = 'public goods capital stock @{reg}']
    lhsGov_11_@{reg} = rhsGov_11_@{reg};
    
    #lhsGov_3_@{reg} = tauNH_@{reg};
    #rhsGov_3_@{reg} = tauNH_@{reg}_p + exo_tauNH_@{reg};
    [name = 'taxes on household labour income @{reg}']
    lhsGov_3_@{reg} = rhsGov_3_@{reg};
        
    #lhsGov_5_@{reg} = tauC_@{reg};
    #rhsGov_5_@{reg} = tauC_@{reg}_p + exo_tauC_@{reg};
    [name = 'taxes on consumption @{reg}']
    lhsGov_5_@{reg} = rhsGov_5_@{reg};
    
    #lhsGov_6_@{reg} = tauH_@{reg};
    #rhsGov_6_@{reg} = tauH_@{reg}_p + exo_tauH_@{reg};
    [name = 'taxes on housing @{reg}']
    lhsGov_6_@{reg} = rhsGov_6_@{reg};
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            // ==============================================
            // subsectoral and regional exogenous variables
            // ==============================================
            #lhsGov_tauKH_@{reg}_@{subsec} =  tauKH_@{subsec}_@{reg};
            #rhsGov_tauKH_@{reg}_@{subsec} =  tauKH_@{subsec}_@{reg}_p + exo_tauKH_@{subsec}_@{reg};
            [name = 'taxes on household capital income @{subsec} @{reg}']
            lhsGov_tauKH_@{reg}_@{subsec} = rhsGov_tauKH_@{reg}_@{subsec};


            # lhsExoSubsec_1_@{reg}_@{subsec} = tauKF_@{subsec}_@{reg};
            # rhsExoSubsec_1_@{reg}_@{subsec} = tauKF_@{subsec}_@{reg}_p - tauS_@{reg} * (@{subsec} != iSubsecFossil_p) + exo_tauKF_@{subsec}_@{reg};
            [name = 'sector specific corporate tax rate paid by firms @{subsec} @{reg}']
            lhsExoSubsec_1_@{reg}_@{subsec} = rhsExoSubsec_1_@{reg}_@{subsec};
            # lhsExoSubsec_2_@{reg}_@{subsec} = tauNF_@{subsec}_@{reg};
            # rhsExoSubsec_2_@{reg}_@{subsec} = tauNF_@{subsec}_@{reg}_p + exo_tauNF_@{subsec}_@{reg};
            [name = 'sector specific labour tax rate paid by firms @{subsec} @{reg}']
            lhsExoSubsec_2_@{reg}_@{subsec} = rhsExoSubsec_2_@{reg}_@{subsec};
      
            # lhsExoSubsec_9_@{reg}_@{subsec} = K_A_@{subsec}_@{reg};
            # rhsExoSubsec_9_@{reg}_@{subsec} = exo_GA_@{subsec}_@{reg} * Y0_p;
            [name = 'sector specific adaptation expenditures by the government against climate change @{subsec} @{reg}']
            lhsExoSubsec_9_@{reg}_@{subsec} = rhsExoSubsec_9_@{reg}_@{subsec};

            # lhsExoSubsec_10_@{reg}_@{subsec} = K_A_@{subsec}_@{reg};
            # rhsExoSubsec_10_@{reg}_@{subsec} = (1 - deltaKA_@{subsec}_@{reg}_p) * K_A_@{subsec}_@{reg}(-1) + G_A_@{subsec}_@{reg};
            [name = 'sector specific adaptation capital against climate change @{subsec} @{reg}']
            lhsExoSubsec_10_@{reg}_@{subsec} = rhsExoSubsec_10_@{reg}_@{subsec};

            # phiG_eff_@{reg}_@{subsec} = min(1, max(0, phiG_@{subsec}_@{reg}_p * exp(exo_phiG_@{subsec}_@{reg})));
            # lhsExoSubsec_11_@{reg}_@{subsec} = K_G_@{subsec}_@{reg};
            # rhsExoSubsec_11_@{reg}_@{subsec} = (1 - delta_@{subsec}_@{reg}) * K_G_@{subsec}_@{reg}(-1) + I_G_@{subsec}_@{reg} + phiG_eff_@{reg}_@{subsec} * D_K_@{subsec}_@{reg};
            [name = 'sector specific public capital @{subsec} @{reg}']
            lhsExoSubsec_11_@{reg}_@{subsec} = rhsExoSubsec_11_@{reg}_@{subsec};

            # I0_G_@{subsec}_@{reg} = delta_@{subsec}_@{reg} * K_@{subsec}_@{reg};
            # lhsExoSubsec_12_@{reg}_@{subsec} = I_G_@{subsec}_@{reg};
            # rhsExoSubsec_12_@{reg}_@{subsec} =  phiG_eff_@{reg}_@{subsec} * I_@{subsec}_@{reg}(-1) + (exo_KTargetB_@{subsec}_@{reg}) * (exo_KTarget_@{subsec}_@{reg} * Y/P_K_@{subsec}_@{reg});

            [name = 'sector specific public investment @{subsec} @{reg}']
            lhsExoSubsec_12_@{reg}_@{subsec} = rhsExoSubsec_12_@{reg}_@{subsec};



            # lhsExoSubsec_13_@{reg}_@{subsec} = r_G_@{subsec}_@{reg};
            # rhsExoSubsec_13_@{reg}_@{subsec} = rf0_p  + exo_r_G_@{subsec}_@{reg};
            [name = 'sector specific public rental rate @{subsec} @{reg}']
            lhsExoSubsec_13_@{reg}_@{subsec} = rhsExoSubsec_13_@{reg}_@{subsec};


            @# if BaselineScenario == 1
                # lhsExoSubsec_14_@{reg}_@{subsec} = K_G_@{subsec}_@{reg};
                # rhsExoSubsec_14_@{reg}_@{subsec} = phiG_eff_@{reg}_@{subsec} * exp(exo_K_G_@{subsec}_@{reg}) * K_@{subsec}_@{reg};
                [name = 'baseline sector specific public capital share']
                lhsExoSubsec_14_@{reg}_@{subsec} = rhsExoSubsec_14_@{reg}_@{subsec};
            @# else
                # lhsExoSubsec_14_@{reg}_@{subsec} = (1 - exo_lIGShare_@{subsec}_@{reg}) * K_G_@{subsec}_@{reg}
                                                    + exo_lIGShare_@{subsec}_@{reg} * I_G_@{subsec}_@{reg};
                # rhsExoSubsec_14_@{reg}_@{subsec} = (1 - exo_lIGShare_@{subsec}_@{reg}) * phiG_eff_@{reg}_@{subsec} * K0_@{subsec}_@{reg}_p * exp(exo_K_G_@{subsec}_@{reg})
                                                    + exo_lIGShare_@{subsec}_@{reg} * exo_sIGShare_@{subsec}_@{reg} * I_@{subsec}_@{reg};
                [name = 'scenario sector specific public capital / investment share @{subsec} @{reg}']
                lhsExoSubsec_14_@{reg}_@{subsec} = rhsExoSubsec_14_@{reg}_@{subsec};
            @# endif

            # lhsExoSubsec_15_@{reg}_@{subsec} = r_FDI_@{subsec}_@{reg};
            # rhsExoSubsec_15_@{reg}_@{subsec} = rf0_p + exo_r_FDI_@{subsec}_@{reg};
            [name = 'FDI rental rate (returns to foreign investors) @{subsec} @{reg}']
            lhsExoSubsec_15_@{reg}_@{subsec} = rhsExoSubsec_15_@{reg}_@{subsec};

        @# endfor
    @# endfor
@# endfor

