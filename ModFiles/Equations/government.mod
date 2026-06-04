// ==========================================
// Block 7: Government
// ==========================================
@# for reg in 1:Regions
    #lhsAggReg_@{reg}_IG = I_G_@{reg} * P_@{reg};
    #rhsAggReg_@{reg}_IG = 
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            + (I_G_@{subsec}_@{reg} * P_INV_@{subsec}_@{reg} - r_G_@{subsec}_@{reg} * P_K_@{subsec}_@{reg} * K_G_@{subsec}_@{reg}(-1) + G_A_@{subsec}_@{reg} * P_INV_@{subsec}_@{reg})
        @# endfor
    @# endfor
    ;
    
    [name = 'regional government investment']
    (1+lhsAggReg_@{reg}_IG) / (1+rhsAggReg_@{reg}_IG) = 1;

    #lhsAggReg_@{reg}_27 = P_@{reg} * G_@{reg} + P_@{reg} * I_G_@{reg} + Tr_@{reg} + BG_@{reg};
    #rhsAggReg_@{reg}_27 = tauC_@{reg} * P_@{reg} * C_@{reg} + IH_@{reg} * PH_@{reg} * tauH_@{reg} + PE_@{reg} * E_@{reg}
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + (tauKF_@{subsec}_@{reg}*r_F_@{subsec}_@{reg} * K_@{subsec}_@{reg}(-1) * P_K_@{subsec}_@{reg}
                + tauKH_@{subsec}_@{reg}*r_H_@{subsec}_@{reg} * K_H_@{subsec}_@{reg}(-1) * P_K_@{subsec}_@{reg})  
                + (tauNF_@{subsec}_@{reg}+tauNH_@{reg}) * W_@{subsec}_@{reg} * N_@{subsec}_@{reg} * LF_@{reg}
            @# endfor
        @# endfor
    + (1 + rf) * s_@{reg}(-1) * BG_@{reg}(-1);
    [name = 'regional government budget constraint']
    (lhsAggReg_@{reg}_27+1)/(rhsAggReg_@{reg}_27+1) = 1;
    #lhsAggReg_@{reg}_28 = Tr_@{reg};
    #rhsAggReg_@{reg}_28 = Tr0_@{reg}_p + exo_Tr_@{reg} + exo_tauSTr_@{reg} * PE_@{reg} * E_@{reg};
    [name = 'regional transfers']
    (1+lhsAggReg_@{reg}_28)/(1+rhsAggReg_@{reg}_28) = 1;
    #lhsAggNat_7_@{reg} = G_A_DH_@{reg};
    #rhsAggNat_7_@{reg} = exo_G_A_DH * Y0_p;
    [name = 'adaptation measures for housing stock']
    (1+lhsAggNat_7_@{reg}) = (1+rhsAggNat_7_@{reg});
    #lhsGov_1_@{reg} = BG_@{reg};
    #rhsGov_1_@{reg} = exo_BG_@{reg}*Y;
    [name = 'Government Budget Constraint']
    (lhsGov_1_@{reg}+1) = (rhsGov_1_@{reg}+1);
    
    #lhsGov_11_@{reg} = KG_@{reg};
    #rhsGov_11_@{reg} = (1 - deltaKG_p) * KG_@{reg}(-1) + G_@{reg};
    [name = 'public goods capital stock']
    (lhsGov_11_@{reg}+1)/(rhsGov_11_@{reg}+1) = 1;
    
    #lhsGov_3_@{reg} = tauNH_@{reg};
    #rhsGov_3_@{reg} = tauNH_@{reg}_p + exo_tauNH_@{reg};
    [name = 'taxes on household labour income']
    (lhsGov_3_@{reg}+1) = (rhsGov_3_@{reg}+1);
        
    #lhsGov_5_@{reg} = tauC_@{reg};
    #rhsGov_5_@{reg} = tauC_@{reg}_p + exo_tauC_@{reg};
    [name = 'taxes on consumption']
    (lhsGov_5_@{reg}+1) = (rhsGov_5_@{reg}+1);
    
    #lhsGov_6_@{reg} = tauH_@{reg};
    #rhsGov_6_@{reg} = tauH_@{reg}_p + exo_tauH_@{reg};
    [name = 'taxes on housing']
    (lhsGov_6_@{reg}+1) = (rhsGov_6_@{reg}+1);
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            // ==============================================
            // subsectoral and regional exogenous variables
            // ==============================================
            #lhsGov_tauKH_@{reg}_@{subsec} =  tauKH_@{subsec}_@{reg};
            #rhsGov_tauKH_@{reg}_@{subsec} =  tauKH_@{subsec}_@{reg}_p + exo_tauKH_@{subsec}_@{reg};
            [name = 'taxes on household capital income']
            (lhsGov_tauKH_@{reg}_@{subsec}+1) = (rhsGov_tauKH_@{reg}_@{subsec}+1);


            # lhsExoSubsec_1_@{reg}_@{subsec} = tauKF_@{subsec}_@{reg};
            # rhsExoSubsec_1_@{reg}_@{subsec} = (tauKF_@{subsec}_@{reg}_p - tauS_@{reg} * (@{subsec} != iSubsecFossil_p) + exo_tauKF_@{subsec}_@{reg});
            [name = 'sector specific corporate tax rate paid by firms']
            (lhsExoSubsec_1_@{reg}_@{subsec}+1)/(rhsExoSubsec_1_@{reg}_@{subsec}+1) = 1;
            # lhsExoSubsec_2_@{reg}_@{subsec} = tauNF_@{subsec}_@{reg};
            # rhsExoSubsec_2_@{reg}_@{subsec} = tauNF_@{subsec}_@{reg}_p + exo_tauNF_@{subsec}_@{reg};
            [name = 'sector specific labour tax rate paid by firms']
            (lhsExoSubsec_2_@{reg}_@{subsec}+1) / (rhsExoSubsec_2_@{reg}_@{subsec}+1) = 1;
      
            # lhsExoSubsec_9_@{reg}_@{subsec} = K_A_@{subsec}_@{reg};
            # rhsExoSubsec_9_@{reg}_@{subsec} = exo_GA_@{subsec}_@{reg} * Y0_p;
            [name = 'sector specific adaptation expenditures by the government against climate change']
            (lhsExoSubsec_9_@{reg}_@{subsec}+1)/(rhsExoSubsec_9_@{reg}_@{subsec}+1) = 1;

            # lhsExoSubsec_10_@{reg}_@{subsec} = K_A_@{subsec}_@{reg};
            # rhsExoSubsec_10_@{reg}_@{subsec} = (1 - deltaKA_@{subsec}_@{reg}_p) * K_A_@{subsec}_@{reg}(-1) + G_A_@{subsec}_@{reg};
            [name = 'sector specific adaptation capital against climate change']
            (lhsExoSubsec_10_@{reg}_@{subsec}+1)/(rhsExoSubsec_10_@{reg}_@{subsec}+1) = 1;

            # phiG_eff_@{reg}_@{subsec} = min(1, max(0, phiG_@{subsec}_@{reg}_p * exp(exo_phiG_@{subsec}_@{reg})));
            # lhsExoSubsec_11_@{reg}_@{subsec} = K_G_@{subsec}_@{reg};
            # rhsExoSubsec_11_@{reg}_@{subsec} = max(0,(1 - delta_@{subsec}_@{reg}) * K_G_@{subsec}_@{reg}(-1) + I_G_@{subsec}_@{reg} + phiG_eff_@{reg}_@{subsec} * D_K_@{subsec}_@{reg});
            [name = 'sector specific public capital']
            (lhsExoSubsec_11_@{reg}_@{subsec}+1)/(rhsExoSubsec_11_@{reg}_@{subsec}+1) = 1;

            # I0_G_@{subsec}_@{reg} = delta_@{subsec}_@{reg} * K_@{subsec}_@{reg};
            # lhsExoSubsec_12_@{reg}_@{subsec} = s_G_@{subsec}_@{reg};
            # rhsExoSubsec_12_@{reg}_@{subsec} = s_G_@{subsec}_@{reg}_p + exo_s_G_@{subsec}_@{reg} + exo_s_GScen_@{subsec}_@{reg} + (exo_KTargetB_@{subsec}_@{reg}) * (exo_KTarget_@{subsec}_@{reg} * Y/P_K_@{subsec}_@{reg});

            [name = 'sector specific public investment']
            (lhsExoSubsec_12_@{reg}_@{subsec}+1)/(rhsExoSubsec_12_@{reg}_@{subsec}+1) = 1;



            # lhsExoSubsec_13_@{reg}_@{subsec} = r_G_@{subsec}_@{reg} * P_K_@{subsec}_@{reg} / P_INV_@{subsec}_@{reg}(-1);
            # rhsExoSubsec_13_@{reg}_@{subsec} = (rf0_p + exo_r_G_@{subsec}_@{reg});
            [name = 'sector specific public rental rate']
            (lhsExoSubsec_13_@{reg}_@{subsec}+1)/(rhsExoSubsec_13_@{reg}_@{subsec}+1) = 1;



            // When lIGShare=0: pin K_G to the exo path (existing behaviour).
            // When lIGShare=1: pin I_G as a share of total I (investment-flow targeting).
            //   K_G then evolves from the LOM (ExoSubsec_11) given I_G.
            # lhsExoSubsec_14_@{reg}_@{subsec} = (1 - exo_lIGShare_@{subsec}_@{reg}) * I_G_@{subsec}_@{reg}
                                                + exo_lIGShare_@{subsec}_@{reg} * I_G_@{subsec}_@{reg};
            # rhsExoSubsec_14_@{reg}_@{subsec} = (1 - exo_lIGShare_@{subsec}_@{reg}) * phiG_@{subsec}_@{reg}_p * delta_@{subsec}_@{reg}_p * K0_@{subsec}_@{reg}_p * exp(exo_K_G_@{subsec}_@{reg})
                                                + exo_lIGShare_@{subsec}_@{reg} * exo_sIGShare_@{subsec}_@{reg} * I_@{subsec}_@{reg};
            [name = 'scenario sector specific public capital / investment share']
            (lhsExoSubsec_14_@{reg}_@{subsec}+1)/(rhsExoSubsec_14_@{reg}_@{subsec}+1) = 1;

            # lhsExoSubsec_15_@{reg}_@{subsec} = r_FDI_@{subsec}_@{reg};
            # rhsExoSubsec_15_@{reg}_@{subsec} = (exo_r_FDI_@{subsec}_@{reg} + rf0_p);
            [name = 'FDI rental rate (returns to foreign investors)']
            (lhsExoSubsec_15_@{reg}_@{subsec}+1)/(rhsExoSubsec_15_@{reg}_@{subsec}+1) = 1;

        @# endfor
    @# endfor
@# endfor

