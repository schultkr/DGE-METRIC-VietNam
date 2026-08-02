// ==========================================
// Block 11: Firms
// ==========================================
@# for reg in 1:Regions
    @# for sec in 1:Sectors                                
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            // ==========================================
            // subsectoral and regional production 
            // ==========================================
            #lhsSupplySubsec_Plog_@{subsec}_@{reg} = P_@{subsec}_@{reg};
            #rhsSupplySubsec_Plog_@{subsec}_@{reg} = exp(p_@{subsec}_@{reg});
            [name = 'regional price level ']
            lhsSupplySubsec_Plog_@{subsec}_@{reg} = rhsSupplySubsec_Plog_@{subsec}_@{reg};
    
            #lhsSupplySubsec_1_@{subsec}_@{reg} = Y_@{subsec}_@{reg};
            #rhsSupplySubsec_1_@{subsec}_@{reg} = (1-omegaQI_@{subsec}_@{reg}_p) * (P_@{subsec}_@{reg}/(P_Q_@{subsec}_@{reg} - kappaE_@{subsec}_@{reg} * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p))^(-etaI_@{subsec}_p) * Q_@{subsec}_@{reg};
            [name = 'demand for regional sector value added']
            lhsSupplySubsec_1_@{subsec}_@{reg} = rhsSupplySubsec_1_@{subsec}_@{reg};
            #lhsSupplySubsec_2_@{subsec}_@{reg} = Q_I_@{subsec}_@{reg};
            #rhsSupplySubsec_2_@{subsec}_@{reg} = omegaQI_@{subsec}_@{reg}_p * A_I_@{subsec}_@{reg}^(etaI_@{subsec}_p-1) * (P_I_@{subsec}_@{reg}/(P_Q_@{subsec}_@{reg}-kappaE_@{subsec}_@{reg} * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p))^(-etaI_@{subsec}_p) * Q_@{subsec}_@{reg};
            [name = 'regional sector demand for intermediates']
            lhsSupplySubsec_2_@{subsec}_@{reg} = rhsSupplySubsec_2_@{subsec}_@{reg};
            @# for secm in 1:Sectors
                #lhsSupplySubsecSec_1_@{subsec}_@{reg}_@{secm} = Q_I_@{subsec}_@{reg}_@{secm};
                #rhsSupplySubsecSec_1_@{subsec}_@{reg}_@{secm} = omegaQI_@{subsec}_@{reg}_@{secm}_p * A_I_@{subsec}_@{reg}_@{secm}^(etaIA_@{subsec}_p-1) * ((P_A_@{secm}_@{reg} + kappaEI_@{subsec}_@{reg}_@{secm}_p * exp(exo_EI_@{subsec}_@{reg}_@{secm}) * (Q_D_@{SubsecFossil}_@{reg}/Q_A_@{SecEnergy}_@{reg}) * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p)/P_I_@{subsec}_@{reg})^(-etaIA_@{subsec}_p) * Q_I_@{subsec}_@{reg};
                [name = 'regional sector demand for intermediates from aggregate sector']
                lhsSupplySubsecSec_1_@{subsec}_@{reg}_@{secm} = rhsSupplySubsecSec_1_@{subsec}_@{reg}_@{secm};
                #lhsSupplySubsecSec_2_@{subsec}_@{reg}_@{secm} = E_I_@{subsec}_@{reg}_@{secm};
                #rhsSupplySubsecSec_2_@{subsec}_@{reg}_@{secm} = kappaEI_@{subsec}_@{reg}_@{secm}_p * exp(exo_EI_@{subsec}_@{reg}_@{secm}) * (Q_D_@{SubsecFossil}_@{reg}/Q_A_@{SecEnergy}_@{reg}) * Q_I_@{subsec}_@{reg}_@{secm};
                [name = 'regional emissions caused by using intermediates from aggregate sector']
                lhsSupplySubsecSec_2_@{subsec}_@{reg}_@{secm} = rhsSupplySubsecSec_2_@{subsec}_@{reg}_@{secm};
                # A_I_Eff_@{subsec}_@{reg}_@{secm}=(exo_AI_@{subsec}_@{reg}_@{secm}!=0)*exo_AI_@{subsec}_@{reg}_@{secm};
                #lhsSupplySubsecSec_3_@{subsec}_@{reg}_@{secm} = A_I_@{subsec}_@{reg}_@{secm};
                #rhsSupplySubsecSec_3_@{subsec}_@{reg}_@{secm} = exp(A_I_Eff_@{subsec}_@{reg}_@{secm})*(EE_@{reg})^(exo_lAddEE_@{subsec}_@{reg}*(@{secm}==iSecEnergy_p));
                [name = 'productivity of intermediates in subsector @{subsec} from sector @{secm}']
                lhsSupplySubsecSec_3_@{subsec}_@{reg}_@{secm} = rhsSupplySubsecSec_3_@{subsec}_@{reg}_@{secm};
            @# endfor
            #lhsSupplySubsec_3_@{subsec}_@{reg} = Q_I_@{subsec}_@{reg};
            #rhsSupplySubsec_3_@{subsec}_@{reg} = 
            (etaIA_@{subsec}_p == 1) * exp(
            @# for secm in 1:Sectors
                + log(max(1e-8,Q_I_@{subsec}_@{reg}_@{secm})*A_I_@{subsec}_@{reg}_@{secm})*omegaQI_@{subsec}_@{reg}_@{secm}_p
            @# endfor
            ) +
            (etaIA_@{subsec}_p != 1) * (
            @# for secm in 1:Sectors
                + omegaQI_@{subsec}_@{reg}_@{secm}_p^(1/etaIA_@{subsec}_p) * (max(1e-8,Q_I_@{subsec}_@{reg}_@{secm})*A_I_@{subsec}_@{reg}_@{secm})^((etaIA_@{subsec}_p-1)/etaIA_@{subsec}_p)
            @# endfor
            )^(etaIA_@{subsec}_p/(etaIA_@{subsec}_p-1+(etaIA_@{subsec}_p==1)));
                       
            [name = 'regional sector demand for intermediates']
            lhsSupplySubsec_3_@{subsec}_@{reg} = rhsSupplySubsec_3_@{subsec}_@{reg};
            #lhsSupplySubsec_4_@{subsec}_@{reg} = Y_@{subsec}_@{reg};
            #rhsSupplySubsec_4_@{subsec}_@{reg} = ((etaNK_@{subsec}_@{reg}_p == 1) * (1 - D_@{subsec}_@{reg}) * A_@{subsec}_@{reg} * max(1e-8,A_K_@{subsec}_@{reg} * u_K_@{subsec}_@{reg} * K_@{subsec}_@{reg}(-1))^alphaK_@{subsec}_@{reg}_p * max(1e-8,LF_@{reg} * (1 - D_N_@{subsec}_@{reg}) * A_N_@{subsec}_@{reg}^1 * N_@{subsec}_@{reg})^alphaN_@{subsec}_@{reg}_p
            + (etaNK_@{subsec}_@{reg}_p != 1) * (1 - D_@{subsec}_@{reg}) * A_@{subsec}_@{reg} * (alphaK_@{subsec}_@{reg}_p^(1/etaNK_@{subsec}_@{reg}_p) * max(1e-8,A_K_@{subsec}_@{reg} * u_K_@{subsec}_@{reg} * K_@{subsec}_@{reg}(-1))^((etaNK_@{subsec}_@{reg}_p-1)/etaNK_@{subsec}_@{reg}_p) + alphaN_@{subsec}_@{reg}_p^(1/etaNK_@{subsec}_@{reg}_p) * max(1e-8,LF_@{reg} * (1 - D_N_@{subsec}_@{reg}) * A_N_@{subsec}_@{reg}^1 * N_@{subsec}_@{reg})^((etaNK_@{subsec}_@{reg}_p-1)/etaNK_@{subsec}_@{reg}_p))^(etaNK_@{subsec}_@{reg}_p/(etaNK_@{subsec}_@{reg}_p - 1 + (etaNK_@{subsec}_@{reg}_p == 1) * 1000)));
            [name = 'sector specific gva']
            lhsSupplySubsec_4_@{subsec}_@{reg} = rhsSupplySubsec_4_@{subsec}_@{reg};
            
            #lhsSupplySubsec_Kexp_@{subsec}_@{reg} = r_F_@{subsec}_@{reg} * K_@{subsec}_@{reg}(-1);
            #rhsSupplySubsec_Kexp_@{subsec}_@{reg} = (K_H_@{subsec}_@{reg}(-1) * r_H_@{subsec}_@{reg} + K_G_@{subsec}_@{reg}(-1) * r_G_@{subsec}_@{reg} + K_FDI_@{subsec}_@{reg}(-1) * r_FDI_@{subsec}_@{reg});
            [name = 'effective rental of capital paid by firms']
            lhsSupplySubsec_Kexp_@{subsec}_@{reg} = rhsSupplySubsec_Kexp_@{subsec}_@{reg};

            #lhsSupplySubsec_Keff_@{subsec}_@{reg} = K_@{subsec}_@{reg};
            #rhsSupplySubsec_Keff_@{subsec}_@{reg} = K_H_@{subsec}_@{reg} + K_G_@{subsec}_@{reg} + K_FDI_@{subsec}_@{reg};
            [name = 'capital used by firms']
            lhsSupplySubsec_Keff_@{subsec}_@{reg} = rhsSupplySubsec_Keff_@{subsec}_@{reg};


            #lhsSupplySubsec_Ieff_@{subsec}_@{reg} = I_@{subsec}_@{reg};
                #rhsSupplySubsec_Ieff_@{subsec}_@{reg} = I_H_@{subsec}_@{reg} + I_FDI_@{subsec}_@{reg};

                [name = 'private and FDI investment']
            lhsSupplySubsec_Ieff_@{subsec}_@{reg} = rhsSupplySubsec_Ieff_@{subsec}_@{reg};

            #lhsSupplySubsec_5_@{subsec}_@{reg} = mu_@{subsec}_@{reg}*r_F_@{subsec}_@{reg} / u_K_@{subsec}_@{reg} * (1 + tauKF_@{subsec}_@{reg}) * P_K_@{subsec}_@{reg} / P_@{subsec}_@{reg};
            #rhsSupplySubsec_5_@{subsec}_@{reg} = alphaK_@{subsec}_@{reg}_p^(1/etaNK_@{subsec}_@{reg}_p) * ((1 - D_@{subsec}_@{reg}) * A_@{subsec}_@{reg} * A_K_@{subsec}_@{reg})^((etaNK_@{subsec}_@{reg}_p-1)/(etaNK_@{subsec}_@{reg}_p)) * (u_K_@{subsec}_@{reg} * K_@{subsec}_@{reg}(-1) / Y_@{subsec}_@{reg})^(-1/etaNK_@{subsec}_@{reg}_p);
            [name = 'Firms FOC capital',mcp = 'K_@{subsec}_@{reg} > 0']
            lhsSupplySubsec_5_@{subsec}_@{reg} = rhsSupplySubsec_5_@{subsec}_@{reg};
            
            #lhsSupplySubsec_6_@{subsec}_@{reg} = mu_@{subsec}_@{reg}*W_@{subsec}_@{reg} * (1 + tauNF_@{subsec}_@{reg})/P_@{subsec}_@{reg};
            #rhsSupplySubsec_6_@{subsec}_@{reg} = alphaN_@{subsec}_@{reg}_p^(1/etaNK_@{subsec}_@{reg}_p) * ((1 - D_N_@{subsec}_@{reg}) * A_N_@{subsec}_@{reg}^1 * (1 - D_@{subsec}_@{reg}) * A_@{subsec}_@{reg})^((etaNK_@{subsec}_@{reg}_p-1)/(etaNK_@{subsec}_@{reg}_p)) * ((LF_@{reg} * N_@{subsec}_@{reg}) / Y_@{subsec}_@{reg})^(-1/etaNK_@{subsec}_@{reg}_p);
            [name = 'Firms FOC labour @{subsec} @{reg}',mcp = 'N_@{subsec}_@{reg} > 0']
            lhsSupplySubsec_6_@{subsec}_@{reg} = rhsSupplySubsec_6_@{subsec}_@{reg};
            #lhsSupplySubsec_7_@{subsec}_@{reg} = Q_@{subsec}_@{reg};
            #rhsSupplySubsec_7_@{subsec}_@{reg} = ((etaI_@{subsec}_p!=1)*(omegaQI_@{subsec}_@{reg}_p^(1/etaI_@{subsec}_p) * (A_I_@{subsec}_@{reg} * max(1e-8,Q_I_@{subsec}_@{reg}))^((etaI_@{subsec}_p-1)/etaI_@{subsec}_p) + (1 - omegaQI_@{subsec}_@{reg}_p)^(1/etaI_@{subsec}_p) * max(1e-8,Y_@{subsec}_@{reg})^((etaI_@{subsec}_p-1)/etaI_@{subsec}_p))^(etaI_@{subsec}_p/(etaI_@{subsec}_p-1+(etaI_@{subsec}_p==1)))
                                                  +(etaI_@{subsec}_p==1)*(max(1e-8,Q_I_@{subsec}_@{reg})^(omegaQI_@{subsec}_@{reg}_p) * max(1e-8,Y_@{subsec}_@{reg})^((1 - omegaQI_@{subsec}_@{reg}_p))))
                                                    ;
            [name = 'sector region specific output']
            lhsSupplySubsec_7_@{subsec}_@{reg} = rhsSupplySubsec_7_@{subsec}_@{reg};
            #lhsSupplySubsec_9_@{subsec}_@{reg} = D_X_@{subsec}_@{reg};
            #rhsSupplySubsec_9_@{subsec}_@{reg} = X_@{subsec}_@{reg}/Q_@{subsec}_@{reg};
            [name = 'sector region specific exports share']
            lhsSupplySubsec_9_@{subsec}_@{reg} = rhsSupplySubsec_9_@{subsec}_@{reg};
            #lhsSupplySubsec_10_@{subsec}_@{reg} = Q_@{subsec}_@{reg};
            #rhsSupplySubsec_10_@{subsec}_@{reg} = X_@{subsec}_@{reg}
            @# for regm in 1:Regions
                + Q_D_@{subsec}_@{regm}_@{reg}
            @# endfor
            ;
            [name = 'sector region specific output']
            lhsSupplySubsec_10_@{subsec}_@{reg} = rhsSupplySubsec_10_@{subsec}_@{reg};
            #lhsEmissionsSubsecSec_1_@{subsec}_@{reg} = E_@{subsec}_@{reg};
            #rhsEmissionsSubsecSec_1_@{subsec}_@{reg} = kappaE_@{subsec}_@{reg} * Q_@{subsec}_@{reg};
            [name = 'regional subsector emissions']
            lhsEmissionsSubsecSec_1_@{subsec}_@{reg} = rhsEmissionsSubsecSec_1_@{subsec}_@{reg};
            #lhsEmissionsSubsecSec_2_@{subsec}_@{reg} = E_NOETS_@{subsec}_@{reg};
            #rhsEmissionsSubsecSec_2_@{subsec}_@{reg} = kappaE_NOETS_@{subsec}_@{reg} * Q_@{subsec}_@{reg};
            [name = 'regional subsector emissions not covered by ETS']
            lhsEmissionsSubsecSec_2_@{subsec}_@{reg} = rhsEmissionsSubsecSec_2_@{subsec}_@{reg};
            [name = 'regional subsector emission intensity']
            (lEndogenousY_p == 1) * kappaE_@{subsec}_@{reg} + (lEndogenousY_p == 0) * E_@{subsec}_@{reg} = (lEndogenousY_p ==1) *(kappaE_@{subsec}_@{reg}_p + exo_kappaE_@{subsec}_@{reg}) + (lEndogenousY_p == 0) *exp(exo_E_@{subsec}_@{reg}) * E0_@{reg}_p * sE_@{subsec}_@{reg}_p;
            #kappaE_NOETS_Target_@{subsec}_@{reg} = exp(exo_E_NOETS_@{subsec}_@{reg}) * E0_NOETS_@{reg}_p * sE_NOETS_@{subsec}_@{reg}_p / (Q_@{subsec}_@{reg} + 1e-12);
            [name = 'regional subsector emission intensity not covered by ETS']
            (lEndogenousY_p == 1) * kappaE_NOETS_@{subsec}_@{reg} + (lEndogenousY_p == 0) * E_NOETS_@{subsec}_@{reg} = (lEndogenousY_p == 1) * ((1 - exo_lE_NOETS_Target_@{subsec}_@{reg}) * (kappaE_NOETS_@{subsec}_@{reg}_p + exo_kappaE_NOETS_@{subsec}_@{reg}) + exo_lE_NOETS_Target_@{subsec}_@{reg} * kappaE_NOETS_Target_@{subsec}_@{reg}) + (lEndogenousY_p == 0) * exp(exo_E_NOETS_@{subsec}_@{reg}) * E0_NOETS_@{reg}_p * sE_NOETS_@{subsec}_@{reg}_p;
            [name = 'SRI emission-intensity-based capital rental wedge']
            wedgeKE_@{subsec}_@{reg} = (phiKE_p + exo_wedgeKE_@{subsec}_@{reg}) * kappaE_@{subsec}_@{reg} * beta_p * (1 - delta_@{subsec}_@{reg}) / (1 - beta_p * (1 - delta_@{subsec}_@{reg}));

        @# endfor
    @# endfor
@# endfor

