// ==========================================
// Block 8: Productivity and damages
// ==========================================
@# for reg in 1:Regions
    @# for sec in 1:Sectors  
        # lhsDemandsec_AF_@{reg}_@{sec} = A_F_@{sec}_@{reg};
        # rhsDemandsec_AF_@{reg}_@{sec} = exp(exo_A_F_@{sec}_@{reg})*EE_@{reg}^((@{sec}==iSecEnergy_p));
        [name = 'productivity for final consumption']    
        lhsDemandsec_AF_@{reg}_@{sec} = rhsDemandsec_AF_@{reg}_@{sec};                              

        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            @# if YEndogenous == 1
                # lhsExoSubsec_3_@{reg}_@{subsec} = log(A_@{subsec}_@{reg}*(lEndoQ_@{subsec}_@{reg}_p)+Q_@{subsec}_@{reg}*(1-lEndoQ_@{subsec}_@{reg}_p));
                # rhsExoSubsec_3_@{reg}_@{subsec} = log(A_@{subsec}_@{reg}_p * KG_@{reg}^phiG_p * exp(exo_A_@{subsec}_@{reg}+exo_@{subsec}_@{reg}))*(lEndoQ_@{subsec}_@{reg}_p) + log(Q0_@{subsec}_@{reg}_p * exp(exo_Q_@{subsec}_@{reg}))*(1-lEndoQ_@{subsec}_@{reg}_p);

                [name = 'sector-specific TFP']
                lhsExoSubsec_3_@{reg}_@{subsec} = rhsExoSubsec_3_@{reg}_@{subsec};
            @# else


                @# if YTarget == 1
                    # lhsExoSubsec_3_@{reg}_@{subsec} = Y_@{subsec}_@{reg} * P_@{subsec}_@{reg}*(lEndoQ_@{subsec}_@{reg}_p)+Q_@{subsec}_@{reg}*(1-lEndoQ_@{subsec}_@{reg}_p);
                    # rhsExoSubsec_3_@{reg}_@{subsec} = P0_@{subsec}_@{reg}_p * Y0_@{subsec}_@{reg}_p * exp(exo_@{subsec}_@{reg}+exo_A_@{subsec}_@{reg})*(lEndoQ_@{subsec}_@{reg}_p) +(Q0_@{subsec}_@{reg}_p * exp(exo_Q_@{subsec}_@{reg}))*(1-lEndoQ_@{subsec}_@{reg}_p);
                @# elseif YTarget == 2
                    # lhsExoSubsec_3_@{reg}_@{subsec} = Y_@{subsec}_@{reg}*(lEndoQ_@{subsec}_@{reg}_p)+Q_@{subsec}_@{reg}*(1-lEndoQ_@{subsec}_@{reg}_p);
                    # rhsExoSubsec_3_@{reg}_@{subsec} = Y0_@{subsec}_@{reg}_p * exp(exo_@{subsec}_@{reg}+exo_A_@{subsec}_@{reg})*(lEndoQ_@{subsec}_@{reg}_p) +(Q0_@{subsec}_@{reg}_p * exp(exo_Q_@{subsec}_@{reg}))*(1-lEndoQ_@{subsec}_@{reg}_p);
                @# else                 
                    # lhsExoSubsec_3_@{reg}_@{subsec} = Q_@{subsec}_@{reg}*(lEndoQ_@{subsec}_@{reg}_p)+Q_@{subsec}_@{reg}*(1-lEndoQ_@{subsec}_@{reg}_p);
                    # rhsExoSubsec_3_@{reg}_@{subsec} = Q0_@{subsec}_@{reg}_p * exp(exo_@{subsec}_@{reg}+exo_A_@{subsec}_@{reg})*(lEndoQ_@{subsec}_@{reg}_p) +(Q0_@{subsec}_@{reg}_p * exp(exo_Q_@{subsec}_@{reg}))*(1-lEndoQ_@{subsec}_@{reg}_p);
                @# endif

                [name = 'sector-specific TFP']
                lhsExoSubsec_3_@{reg}_@{subsec} = rhsExoSubsec_3_@{reg}_@{subsec};

            @# endif
 
            # lhsExoSubsec_300_@{reg}_@{subsec} = log(A_I_@{subsec}_@{reg});
            # rhsExoSubsec_300_@{reg}_@{subsec} = exo_A_I_@{subsec}_@{reg} + (1-lEndogenousY_p)*exo_QI_@{subsec}_@{reg};
            [name = 'sector-specific intermediates sector @{subsec} and region @{reg}']
            lhsExoSubsec_300_@{reg}_@{subsec} = rhsExoSubsec_300_@{reg}_@{subsec};
            

            # lhsExoSubsec_4_@{reg}_@{subsec} = A_K_@{subsec}_@{reg};
            # rhsExoSubsec_4_@{reg}_@{subsec} = exp(exo_K_@{subsec}_@{reg});
            [name = 'sector and capital specific productivity shock']
            lhsExoSubsec_4_@{reg}_@{subsec} = rhsExoSubsec_4_@{reg}_@{subsec};
            
            @# if NEndogenous == 1
                # lhsExoSubsec_5_@{reg}_@{subsec} = log(A_N_@{subsec}_@{reg});
                # rhsExoSubsec_5_@{reg}_@{subsec} = exo_N_@{subsec}_@{reg};
                [name = 'sector and labour specific productivity shock']
                lhsExoSubsec_5_@{reg}_@{subsec} = rhsExoSubsec_5_@{reg}_@{subsec};
            @# else
                # lhsExoSubsec_5_@{reg}_@{subsec} = N_@{subsec}_@{reg};
                # rhsExoSubsec_5_@{reg}_@{subsec} = phiN0_@{subsec}_@{reg}_p * N0_@{reg}_p * exp(exo_N_@{subsec}_@{reg});
                [name = 'sector and labour specific productivity shock']
                lhsExoSubsec_5_@{reg}_@{subsec} = rhsExoSubsec_5_@{reg}_@{subsec};
            @# endif
            # lhsExoSubsec_6_@{reg}_@{subsec} = D_@{subsec}_@{reg};
            # rhsExoSubsec_6_@{reg}_@{subsec} = exo_D_@{subsec}_@{reg};
            [name = 'sector-specific damage function']
            lhsExoSubsec_6_@{reg}_@{subsec} = rhsExoSubsec_6_@{reg}_@{subsec};
            
            # lhsExoSubsec_7_@{reg}_@{subsec} = D_N_@{subsec}_@{reg};
            # rhsExoSubsec_7_@{reg}_@{subsec} = exo_D_N_@{subsec}_@{reg};
            [name = 'sector specific damage function on labour productivity']
            lhsExoSubsec_7_@{reg}_@{subsec} = rhsExoSubsec_7_@{reg}_@{subsec};
            
            // --- Smooth floor and tuned parameters
            // You need around 5 percent to get enough scrapping during the NZ scenario
            // Otherwise the model does not converge. An Alternative might be to do the scrapping manually in the Excel File. 
            // The result of the simulation run can help to identify the necessary scrapping. 
            # epsIDam_@{reg}_@{subsec} = 1e-3;
            # phiG_effDam_@{reg}_@{subsec} = min(1, max(0, phiG_@{subsec}_@{reg}_p * exp(exo_phiG_@{subsec}_@{reg})));
            # IDamRefRaw_@{reg}_@{subsec} = (1-phiG_effDam_@{reg}_@{subsec})*delta_@{subsec}_@{reg}_p*K0_@{subsec}_@{reg}_p;
            # IDamRef_@{reg}_@{subsec} =
                0.5*( IDamRefRaw_@{reg}_@{subsec} + epsIDam_@{reg}_@{subsec}
                    + sqrt( (IDamRefRaw_@{reg}_@{subsec} - epsIDam_@{reg}_@{subsec})^2 + epsIDam_@{reg}_@{subsec}^2 ) );
            # Ibar_@{reg}_@{subsec} = 0.05*IDamRef_@{reg}_@{subsec};
            # epsISw_@{reg}_@{subsec} = 0.02*IDamRef_@{reg}_@{subsec} + epsIDam_@{reg}_@{subsec};
            
            // Smooth switch: ~0 if I<Ibar, ~1 if I>Ibar
            # zI_@{reg}_@{subsec} =
                min(1, max(0, (I_@{subsec}_@{reg} - Ibar_@{reg}_@{subsec}) / epsISw_@{reg}_@{subsec}));
            # sI_@{reg}_@{subsec} =
                zI_@{reg}_@{subsec}^2 * (3 - 2*zI_@{reg}_@{subsec});
            
            // --- LHS and RHS blended smoothly (always defined)
            # lhsExoSubsec_8_@{reg}_@{subsec} = D_K_@{subsec}_@{reg};
/*
            # lhsExoSubsec_8_@{reg}_@{subsec} =
                  sI_@{reg}_@{subsec} * D_K_@{subsec}_@{reg}
                + (1 - sI_@{reg}_@{subsec}) * (I_@{subsec}_@{reg} - Ibar_@{reg}_@{subsec});
*/
            # scrabbage_@{subsec}_@{reg} = (@{subsec} == @{SubsecFossil})* -min(0,0*(E_@{reg}/E_@{reg}(-1)-1))*K_@{subsec}_@{reg}(-1);
            # rhsExoSubsec_8_raw_@{reg}_@{subsec} = 0.75*D_K_@{subsec}_@{reg}(-1) + 0.25*(exo_D_K_@{subsec}_@{reg} * K0_@{subsec}_@{reg}_p + scrabbage_@{subsec}_@{reg});
            # rhsExoSubsec_8_@{reg}_@{subsec} = sI_@{reg}_@{subsec} * rhsExoSubsec_8_raw_@{reg}_@{subsec};
            [name = 'sector specific damage function on capital formation']  
            lhsExoSubsec_8_@{reg}_@{subsec} = rhsExoSubsec_8_@{reg}_@{subsec};        


            @# if lCapPrice == 0
                // P_K: rental price = sector's own value-added price (no wedge/exo_P_K).
                [name = 'Rental price of capital @{subsec} @{reg}']
                P_K_@{subsec}_@{reg} = P_@{subsec}_@{reg};

                // P_INV: purchase price of investment goods (supply wedge + exo shock apply here).
                @# if lCapGoodsSecPrice == 1
                    # rhsExoSubsec_PINV_@{reg}_@{subsec} = P_Q_@{CapGoodsSubsec}_@{reg} * exp(exo_P_K_@{subsec}_@{reg}) + phiG_p*exo_I_@{subsec}_@{reg};
                @# else
                    # rhsExoSubsec_PINV_@{reg}_@{subsec} = P_@{subsec}_@{reg} * exp(exo_P_K_@{subsec}_@{reg}) + phiG_p*exo_I_@{subsec}_@{reg};
                @# endif

                [name = 'Price of investment goods @{subsec} @{reg}']
                P_INV_@{subsec}_@{reg} = rhsExoSubsec_PINV_@{reg}_@{subsec};
            @# endif

            # lhsExoSubsec_phiK_@{reg}_@{subsec} = phiK_@{subsec}_@{reg};
            # rhsExoSubsec_phiK_@{reg}_@{subsec} = rhophiK_p*phiK_@{subsec}_@{reg}(-1) + (1-rhophiK_p)*(min(1000,phiK_@{subsec}_@{reg}_p * exp(exo_phiK_@{subsec}_@{reg}) * exp(phiKPE_p*(steady_state(PE_@{reg})-PE0_@{reg}_p)*((@{subsec} == @{SubsecFossil})))));
 
            [name = 'investment adjustment cost curvature']
            lhsExoSubsec_phiK_@{reg}_@{subsec} = rhsExoSubsec_phiK_@{reg}_@{subsec};



            # lhsExoSubsec_mu_@{reg}_@{subsec} = mu_@{subsec}_@{reg};
            # rhsExoSubsec_mu_@{reg}_@{subsec} = exp(exo_mu_@{subsec}_@{reg});               
            [name = 'mark-up over wages and rental rate']
            lhsExoSubsec_mu_@{reg}_@{subsec} = rhsExoSubsec_mu_@{reg}_@{subsec};
            

            #lhsDemandSubsec_AD_@{reg}_@{subsec} = A_D_@{subsec}_@{reg};
            #rhsDemandSubsec_AD_@{reg}_@{subsec} = exp(exo_A_D_@{subsec}_@{reg});
            [name = 'demand for subsector output']
            lhsDemandSubsec_AD_@{reg}_@{subsec} = rhsDemandSubsec_AD_@{reg}_@{subsec};

            @# if lEndoUtilization == 0
                #lhsSupplySubsec_12_@{subsec}_@{reg} = u_K_@{subsec}_@{reg};
                #rhsSupplySubsec_12_@{subsec}_@{reg} = exp(exo_u_K_@{subsec}_@{reg});

                [name = 'regional subsector utilization rate']
                lhsSupplySubsec_12_@{subsec}_@{reg} = rhsSupplySubsec_12_@{subsec}_@{reg};
            @# endif



        @# endfor
    @# endfor
    #lhsAggReg_@{reg}_14 = DH_@{reg};
    #rhsAggReg_@{reg}_14 = exo_DH_@{reg}  * Y / PH_@{reg};
    [name = 'damages to houses']
    lhsAggReg_@{reg}_14 = rhsAggReg_@{reg}_14;
@# endfor

