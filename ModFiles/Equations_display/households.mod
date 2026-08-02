// ==========================================
// Block 6: Households
// ==========================================
@# for reg in 1:Regions

    #lhsNX_@{reg} = NX_@{reg}/Y_@{reg}*(exo_NXL_@{reg}==1) + adjB_@{reg} * (exo_NX_@{reg}==0);
    #rhsNX_@{reg} = exo_adjB_@{reg} * (exo_NX_@{reg}==0) + (NX0_@{reg}_p+exo_NX_@{reg}) * (exo_NXL_@{reg}==1);
    [name = 'net export to GDP ratio']
    lhsNX_@{reg} = rhsNX_@{reg};

    #lhsdeltaB_@{reg} = deltaB_@{reg}*(exo_BL_@{reg}==0) + (exo_BL_@{reg}==1)*B_@{reg}EXP/Y_@{reg};
    #rhsdeltaB_@{reg} = (exo_deltaB_@{reg})*(exo_BL_@{reg}==0) + (exo_BL_@{reg}==1)*exo_B_@{reg};
    [name = 'world depreciation rate']
    lhsdeltaB_@{reg} = rhsdeltaB_@{reg};


    #lhsAggReg_@{reg}_7 = lambda_@{reg} * (1 + 2*phiadjB_p*(B_@{reg}EXP+(phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg})*BG_@{reg}EXP-(1-deltaB_p)*(B_@{reg}+(phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg})*BG_@{reg}) + adjB_@{reg}));
    #rhsAggReg_@{reg}_7 = lambda_@{reg}EXP * beta_p * exp(exo_beta) * (s_@{reg}(+1) * (1 + rfEXP -deltaB_p)*exp(-phiB_p*(B_@{reg}EXP+(phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg})*BG_@{reg}EXP-(1-deltaB_p)*(B_@{reg}+(phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg})*BG_@{reg}))/Y_@{reg}EXP) + 2*phiadjB_p*((B_@{reg}(+2)+(phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg})*BG_@{reg}(+2))-(1-deltaB_p)*(B_@{reg}EXP+(phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg})*BG_@{reg}EXP) + adjB_@{reg}(+1)));
    [name = 'FOC Foreign Assets']
    lhsAggReg_@{reg}_7 = rhsAggReg_@{reg}_7;

    #lhsAggReg_@{reg}_107 = (B_@{reg}EXP + (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg})*BG_@{reg}EXP);
    #rhsAggReg_@{reg}_107 = (1 + rf)*s_@{reg}*exp(-phiB_p*(B_@{reg}+(phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg})*BG_@{reg}-(1-deltaB_p)*(B_@{reg}(-1)+(phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg})*BG_@{reg}(-1)))/Y_@{reg}) * (B_@{reg}+(phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg})*BG_@{reg}) + NX_@{reg} - phiadjB_p*(B_@{reg}EXP+(phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg})*BG_@{reg}EXP-(1-deltaB_p)*(B_@{reg}+(phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg})*BG_@{reg}) + 1/2*adjB_@{reg})^2 + deltaB_@{reg}
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            - I_FDI_@{subsec}_@{reg} * P_INV_@{subsec}_@{reg}
            - r_FDI_@{subsec}_@{reg} * K_FDI_@{subsec}_@{reg}(-1)
        @# endfor
    @# endfor
    ;

    [name = 'Law of motion foreign bonds']
    lhsAggReg_@{reg}_107 = rhsAggReg_@{reg}_107;

    #lhsAggReg_@{reg}_8 = lambda_@{reg} * P_@{reg} * (1 + tauC_@{reg});
    #rhsAggReg_@{reg}_8 = (1-gamma_@{reg}_p) * ((C_@{reg}-h_p*C_@{reg}(-1))/PoP_@{reg})^(-gamma_@{reg}_p) * (H_@{reg}/PoP_@{reg})^gamma_@{reg}_p * (((C_@{reg}-h_p*C_@{reg}(-1))/PoP_@{reg})^(1-gamma_@{reg}_p) * (H_@{reg}/PoP_@{reg})^gamma_@{reg}_p)^(-sigmaC_p)
                          - beta_p * exp(exo_beta) * h_p * (1-gamma_@{reg}_p) * ((C_@{reg}EXP-h_p*C_@{reg})/PoP_@{reg}EXP)^(-gamma_@{reg}_p) * (H_@{reg}EXP/PoP_@{reg}EXP)^gamma_@{reg}_p * (((C_@{reg}EXP-h_p*C_@{reg})/PoP_@{reg}EXP)^(1-gamma_@{reg}_p) * (H_@{reg}EXP/PoP_@{reg}EXP)^gamma_@{reg}_p)^(-sigmaC_p);
    [name = 'FOC HH consumption']
    lhsAggReg_@{reg}_8 = rhsAggReg_@{reg}_8;
    #lhsAggReg_@{reg}_12 = (H_@{reg}/PoP_@{reg});
    #rhsAggReg_@{reg}_12 = (1 - deltaH_p) * (H_@{reg}(-1)/PoP_@{reg}(-1)) + (IH_@{reg}/PoP_@{reg}) - DH_@{reg}/PoP_@{reg};
    [name = 'law of motion for houses']
    lhsAggReg_@{reg}_12 = rhsAggReg_@{reg}_12;
    @# if YEndogenous == 0
        #lhsAggReg_@{reg}_13 = (H_@{reg}/PoP_@{reg});
        #rhsAggReg_@{reg}_13 = H0_@{reg}_p + exo_H_@{reg};
        [name = 'exogenous development of housing area']
        lhsAggReg_@{reg}_13 = rhsAggReg_@{reg}_13;
    @# else
        #lhsAggReg_@{reg}_13 = PH_@{reg};
        #rhsAggReg_@{reg}_13 = PH0_@{reg}_p * exp(exo_H_@{reg});
        [name = 'exogenous development of housing area']
        lhsAggReg_@{reg}_13 = rhsAggReg_@{reg}_13;
    @# endif
    #lhsAggReg_@{reg}_15 = lambda_@{reg}*omegaH_@{reg};
    #rhsAggReg_@{reg}_15 = beta_p *exp(exo_beta)*(lambda_@{reg}EXP*omegaH_@{reg}EXP*(1 - deltaH_p) + (((C_@{reg}EXP-h_p*C_@{reg})/PoP_@{reg}EXP)^(1 - gamma_@{reg}_p)*(H_@{reg}/PoP_@{reg}EXP)^(gamma_@{reg}_p - 1)*gamma_@{reg}_p)*(((C_@{reg}EXP-h_p*C_@{reg})/PoP_@{reg}EXP)^(1 - gamma_@{reg}_p)*(H_@{reg}/PoP_@{reg}EXP)^gamma_@{reg}_p)^(-sigmaC_p));
    [name = 'FOC HH houses']
    lhsAggReg_@{reg}_15 = rhsAggReg_@{reg}_15;
    #lhsAggReg_@{reg}_16 = lambda_@{reg}*omegaH_@{reg};
    #rhsAggReg_@{reg}_16 = PH_@{reg} * (1 + tauH_@{reg}) * lambda_@{reg};
    [name = 'FOC HH investment in houses']
    lhsAggReg_@{reg}_16 = rhsAggReg_@{reg}_16;

    #lhsAggReg_@{reg}_KPV = K_PV_@{reg};
    #rhsAggReg_@{reg}_KPV = (1-deltaPV_p) * K_PV_@{reg}(-1) + I_PV_@{reg};
    [name = 'PV RTS capital stock']
    lhsAggReg_@{reg}_KPV = rhsAggReg_@{reg}_KPV;

    #lhsAggReg_@{reg}_IPV = I_PV_@{reg};
    #rhsAggReg_@{reg}_IPV = (deltaPV_p*phiKPV0_p + exo_PV_@{reg}) * Y0_p;
    [name = 'Investment into PV capital stock']
    lhsAggReg_@{reg}_IPV = rhsAggReg_@{reg}_IPV;

    #lhsAggReg_@{reg}_QPV = Q_PV_@{reg};
    #rhsAggReg_@{reg}_QPV = phiPV_p * K_PV_@{reg} * exp(exo_PVEff_@{reg});
    [name = 'PV home production']
    lhsAggReg_@{reg}_QPV = rhsAggReg_@{reg}_QPV;

    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
             // endogenous depreciation
            #mult_@{subsec}_@{reg} =
              1 + (@{subsec}==@{SubsecFossil}) * min(1,
                    max(0, exp(gamPEdel_p*(PE_@{reg}(-1)-PE_@{reg}(-2))) - 1) );
            delta_@{subsec}_@{reg} = rhophiK_p*delta_@{subsec}_@{reg}(-1) + (1-rhophiK_p)*delta_@{subsec}_@{reg}_p * mult_@{subsec}_@{reg};
            # lhsCapSub_rlog_@{reg}_@{subsec} = rlog_H_@{subsec}_@{reg};
            # rhsCapSub_rlog_@{reg}_@{subsec} = log(r_H_@{subsec}_@{reg});
            [name = 'log interest rates hosueholds']
            lhsCapSub_rlog_@{reg}_@{subsec} = rhsCapSub_rlog_@{reg}_@{subsec};
             
                
            @# if lEndoUtilization == 1
                # rKSSFwd_@{reg}_@{subsec} = 1/beta_p - 1 + delta_@{subsec}_@{reg}(+1);
                # u_K_pos_fwd_@{reg}_@{subsec} = 0.5 * ( u_K_@{subsec}_@{reg}(+1)
                                                        + sqrt( u_K_@{subsec}_@{reg}(+1)^2 + 1e-4 ) );
                # effDeltaFwd_@{reg}_@{subsec} = delta_@{subsec}_@{reg}(+1)
                    + rKSSFwd_@{reg}_@{subsec} / sigmaU_p
                      * (u_K_pos_fwd_@{reg}_@{subsec}^sigmaU_p - 1);
            @# else
                # effDeltaFwd_@{reg}_@{subsec} = delta_@{subsec}_@{reg}(+1);
            @# endif

            # lhsCapSub_1_@{reg}_@{subsec} = (lambda_@{reg}EXP * beta_p * exp(exo_beta+exo_beta_@{subsec}_@{reg}) * (exp(rlog_H_@{subsec}_@{reg}EXP) - wedgeKE_@{subsec}_@{reg}(+1)) * P_K_@{subsec}_@{reg}EXP * (1 - tauKH_@{subsec}_@{reg}EXP) + lambda_@{reg}EXP * omegaI_@{subsec}_@{reg}EXP * P_INV_@{subsec}_@{reg}EXP * beta_p * exp(exo_beta) * (1 - effDeltaFwd_@{reg}_@{subsec}));
            # rhsCapSub_1_@{reg}_@{subsec} = lambda_@{reg} * omegaI_@{subsec}_@{reg} * P_INV_@{subsec}_@{reg} * exp(muI_@{subsec}_@{reg});

            [name = 'HH FOC capital @{subsec} @{reg}']
            lhsCapSub_1_@{reg}_@{subsec} = rhsCapSub_1_@{reg}_@{subsec};                    

            @#include "ModFiles/Equations_display/investment_adjustment.mod"
            #lhsSupplySubsec_11_@{reg}_@{subsec} = (1 - tauNH_@{reg}) * W_@{subsec}_@{reg} * LF_@{reg}/PoP_@{reg} * lambda_@{reg} * lEndoN_@{subsec}_@{reg}_p + (1-lEndoN_@{subsec}_@{reg}_p) * N_@{subsec}_@{reg};
            #rhsSupplySubsec_11_@{reg}_@{subsec} = phiL_@{subsec}_@{reg}_p * A_N_@{subsec}_@{reg} * (N_@{subsec}_@{reg})^sigmaL_p * lEndoN_@{subsec}_@{reg}_p + (1-lEndoN_@{subsec}_@{reg}_p) * phiN0_@{subsec}_@{reg}_p * N0_@{reg}_p;
            [name = 'HH FOC labour @{subsec} @{reg} ',mcp = 'N_@{sec}_@{reg}>0']
            lhsSupplySubsec_11_@{reg}_@{subsec} = rhsSupplySubsec_11_@{reg}_@{subsec};
        @# endfor
    @# endfor
    @# if Regions > 0
        @# for regm in 1:Regions
           @# if Regions == 1
                #lhsAggReg_@{reg}_@{regm}_2 = B_@{reg}_@{regm};
                #rhsAggReg_@{reg}_@{regm}_2 = 0;
                [name = 'foreign assets']
                (lhsAggReg_@{reg}_@{regm}_2+1)/(1 + rhsAggReg_@{reg}_@{regm}_2) = 1;
                #lhsAggReg_@{reg}_@{regm}_1 = NX_@{reg}_@{regm};
                #rhsAggReg_@{reg}_@{regm}_1 = 0;
                [name = 'bilateral regional net exports']
                lhsAggReg_@{reg}_@{regm}_1 = rhsAggReg_@{reg}_@{regm}_1;
            @# else
                #lhsAggReg_@{reg}_@{regm}_2 = lambda_@{reg};
                #rhsAggReg_@{reg}_@{regm}_2 = lambda_@{reg}EXP * beta_p * exp(exo_beta) * (1 + rfEXP - deltaB_p) * exp(-phiB_p*(rfEXP*sf_@{reg}*B_@{reg}_@{regm}EXP + NX_@{reg}_@{regm}EXP));
                [name = 'FOC foreign assets']
                lhsAggReg_@{reg}_@{regm}_2 = rhsAggReg_@{reg}_@{regm}_2;
                #lhsAggReg_@{reg}_@{regm}_1 = NX_@{reg}_@{regm};
                #rhsAggReg_@{reg}_@{regm}_1 = 
                @# for sec in 1:Sectors
                    @# for subsec in Subsecstart[sec]:Subsecend[sec]            
                        + P_Q_@{subsec}_@{reg} * Q_D_@{subsec}_@{regm}_@{reg} - P_Q_@{subsec}_@{regm} * Q_D_@{subsec}_@{reg}_@{regm}
                    @# endfor
                @# endfor
                ;
                [name = 'bilateral regional net exports']
                lhsAggReg_@{reg}_@{regm}_1 = rhsAggReg_@{reg}_@{regm}_1;
            @# endif
        @# endfor
    @# endif
@# endfor
                               
