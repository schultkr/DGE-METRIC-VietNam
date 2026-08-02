// ==========================================
// Block 6: Households
// ==========================================

@# for reg in 1:Regions

    // ------------------------------------------------------------------
    // External balance: net exports and bond depreciation rate
    // ------------------------------------------------------------------

    #lhsNetExportRatio_@{reg} = NX_@{reg} / Y_@{reg} * (exo_NXL_@{reg} == 1)
                               + adjB_@{reg} * (exo_NX_@{reg} == 0);
    #rhsNetExportRatio_@{reg} = exo_adjB_@{reg} * (exo_NX_@{reg} == 0)
                               + (NX0_@{reg}_p + exo_NX_@{reg}) * (exo_NXL_@{reg} == 1);
    [name = 'net export to GDP ratio @{reg}']
    (lhsNetExportRatio_@{reg} + 1) = (rhsNetExportRatio_@{reg} + 1);

    #lhsExternalDeprRate_@{reg} = deltaB_@{reg} * (exo_BL_@{reg} == 0)
                                 + (exo_BL_@{reg} == 1) * B_@{reg}EXP / Y_@{reg};
    #rhsExternalDeprRate_@{reg} = exo_deltaB_@{reg} * (exo_BL_@{reg} == 0)
                                 + (exo_BL_@{reg} == 1) * exo_B_@{reg};
    [name = 'world depreciation rate @{reg}']
    (lhsExternalDeprRate_@{reg} + 1) / (rhsExternalDeprRate_@{reg} + 1) = 1;

    // FOC with respect to total external position (B + phi*BG).
    // Only the externally-held share phi_BG_ext of government debt enters the external position.
    #lhsFocForeignBonds_@{reg} = lambda_@{reg}
        * (1 + 2 * phiadjB_p * (B_@{reg}EXP + (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}) * BG_@{reg}EXP - (B_@{reg} + (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}) * BG_@{reg}) + adjB_@{reg}));
    #rhsFocForeignBonds_@{reg} = lambda_@{reg}EXP * beta_p * exp(exo_beta)
        * (  s_@{reg}EXP * (1 + rfEXP - deltaB_p)
               * exp(-phiB_p * (B_@{reg}EXP + (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}) * BG_@{reg}EXP - (1 - deltaB_p) * (B_@{reg} + (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}) * BG_@{reg})) / Y_@{reg}EXP)
           + 2 * phiadjB_p
               * ((B_@{reg}(+2) + (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}) * BG_@{reg}(+2)) - (B_@{reg}EXP + (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}) * BG_@{reg}EXP) + adjB_@{reg}EXP)  );
    [name = 'FOC foreign bonds @{reg}']
    (1 + lhsFocForeignBonds_@{reg}) / (1 + rhsFocForeignBonds_@{reg}) = 1;

    // Law of motion for total external position (B + phi*BG).
    // FDI: I_FDI*P_INV (capital inflow) and r_FDI*K_FDI(-1)*P_K (income outflow) both reduce B.
    #lhsLomForeignBonds_@{reg} = B_@{reg}EXP + (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}) * BG_@{reg}EXP;
    #rhsLomForeignBonds_@{reg} =
        (1 + rf) * s_@{reg}
            * exp(-phiB_p * (B_@{reg} + (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}) * BG_@{reg} - (1 - deltaB_p) * (B_@{reg}(-1) + (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}) * BG_@{reg}(-1))) / Y_@{reg})
            * (B_@{reg} + (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}) * BG_@{reg})
        + NX_@{reg}
        - phiadjB_p * (B_@{reg}EXP + (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}) * BG_@{reg}EXP - (B_@{reg} + (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}) * BG_@{reg}) + 1/2 * adjB_@{reg})^2
        + deltaB_@{reg}
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                - I_FDI_@{subsec}_@{reg} * P_INV_@{subsec}_@{reg}
                - r_FDI_@{subsec}_@{reg} * P_K_@{subsec}_@{reg} / P_INV_@{subsec}_@{reg}(-1) * K_FDI_@{subsec}_@{reg}(-1)
            @# endfor
        @# endfor
        ;
    [name = 'law of motion foreign bonds @{reg}']
    lhsLomForeignBonds_@{reg} = rhsLomForeignBonds_@{reg};

    // ------------------------------------------------------------------
    // Consumption and housing
    // ------------------------------------------------------------------

    // Per-capita habit-adjusted consumption and housing, reused across FOCs below.
    #cHab_@{reg}    = (C_@{reg}     - h_p * C_@{reg}(-1)) / PoP_@{reg};
    #cHabEXP_@{reg} = (C_@{reg}EXP  - h_p * C_@{reg})    / PoP_@{reg}EXP;
    #hpc_@{reg}     =  H_@{reg}     / PoP_@{reg};
    #hpcEXP_@{reg}  =  H_@{reg}EXP  / PoP_@{reg}EXP;
    // H_t normalized by next-period population — enters FOC for housing stock chosen at t.
    #hpcFwd_@{reg}  =  H_@{reg}     / PoP_@{reg}EXP;

    // Cobb-Douglas utility bundle: u = c^(1-gamma) * h^gamma.
    #uBundle_@{reg}     = cHab_@{reg}^(1    - gamma_@{reg}_p) * hpc_@{reg}^gamma_@{reg}_p;
    #uBundleEXP_@{reg}  = cHabEXP_@{reg}^(1 - gamma_@{reg}_p) * hpcEXP_@{reg}^gamma_@{reg}_p;
    // Bundle for FOC housing: uses H_t (chosen now) with next-period normalisation.
    #uBundleFwdH_@{reg} = cHabEXP_@{reg}^(1 - gamma_@{reg}_p) * hpcFwd_@{reg}^gamma_@{reg}_p;

    // FOC: consumption — marginal utility of wealth equals marginal utility of consumption.
    #lhsFocConsumption_@{reg} = lambda_@{reg} * P_@{reg} * (1 + tauC_@{reg});
    #rhsFocConsumption_@{reg} =
        (1 - gamma_@{reg}_p) * cHab_@{reg}^(-gamma_@{reg}_p) * hpc_@{reg}^gamma_@{reg}_p
            * uBundle_@{reg}^(-sigmaC_p)
        - beta_p * exp(exo_beta) * h_p
            * (1 - gamma_@{reg}_p) * cHabEXP_@{reg}^(-gamma_@{reg}_p) * hpcEXP_@{reg}^gamma_@{reg}_p
            * uBundleEXP_@{reg}^(-sigmaC_p);
    [name = 'FOC consumption @{reg}']
    (lhsFocConsumption_@{reg} + 1) / (rhsFocConsumption_@{reg} + 1) = 1;

    // Law of motion for per-capita housing stock.
    #lhsLomHousing_@{reg} = H_@{reg} / PoP_@{reg};
    #rhsLomHousing_@{reg} = (1 - deltaH_p) * (H_@{reg}(-1) / PoP_@{reg}(-1))
                            + IH_@{reg} / PoP_@{reg} - DH_@{reg} / PoP_@{reg};
    [name = 'law of motion housing @{reg}']
    (lhsLomHousing_@{reg} + 1) / (rhsLomHousing_@{reg} + 1) = 1;

    // Exogenous housing path: pins H/PoP (YEndogenous == 0) or PH (YEndogenous == 1).
    @# if YEndogenous == 0
        #lhsHousingTarget_@{reg} = H_@{reg} / PoP_@{reg};
        #rhsHousingTarget_@{reg} = H0_@{reg}_p + exo_H_@{reg};
        [name = 'exogenous housing area @{reg}']
        (lhsHousingTarget_@{reg} + 1) / (rhsHousingTarget_@{reg} + 1) = 1;
    @# else
        #lhsHousingTarget_@{reg} = PH_@{reg};
        #rhsHousingTarget_@{reg} = PH0_@{reg}_p * exp(exo_H_@{reg});
        [name = 'exogenous housing price @{reg}']
        (lhsHousingTarget_@{reg} + 1) / (rhsHousingTarget_@{reg} + 1) = 1;
    @# endif

    // FOC: housing stock — shadow value of housing equals discounted continuation value.
    #lhsFocHousing_@{reg} = lambda_@{reg} * omegaH_@{reg};
    #rhsFocHousing_@{reg} = beta_p * exp(exo_beta)
        * (  lambda_@{reg}EXP * omegaH_@{reg}EXP * (1 - deltaH_p)
           + gamma_@{reg}_p
               * cHabEXP_@{reg}^(1 - gamma_@{reg}_p) * hpcFwd_@{reg}^(gamma_@{reg}_p - 1)
               * uBundleFwdH_@{reg}^(-sigmaC_p)  );
    [name = 'FOC housing stock @{reg}']
    (lhsFocHousing_@{reg} + 1) / (rhsFocHousing_@{reg} + 1) = 1;

    // FOC: housing investment — shadow price of housing equals after-tax house price.
    #lhsFocHousingInvestment_@{reg} = lambda_@{reg} * omegaH_@{reg};
    #rhsFocHousingInvestment_@{reg} = PH_@{reg} * (1 + tauH_@{reg}) * lambda_@{reg};
    [name = 'FOC housing investment @{reg}']
    (1 + lhsFocHousingInvestment_@{reg}) / (1 + rhsFocHousingInvestment_@{reg}) = 1;

    // ------------------------------------------------------------------
    // Rooftop PV (household solar home production)
    // ------------------------------------------------------------------

    #lhsLomPvCapital_@{reg} = K_PV_@{reg};
    #rhsLomPvCapital_@{reg} = (1 - deltaPV_p) * K_PV_@{reg}(-1) + I_PV_@{reg};
    [name = 'law of motion PV capital @{reg}']
    (1 + lhsLomPvCapital_@{reg}) / (1 + rhsLomPvCapital_@{reg}) = 1;

    #lhsPvInvestment_@{reg} = I_PV_@{reg};
    #rhsPvInvestment_@{reg} = (deltaPV_p * phiKPV0_p + exo_PV_@{reg}) * Y0_p;
    [name = 'PV investment @{reg}']
    (1 + lhsPvInvestment_@{reg}) / (1 + rhsPvInvestment_@{reg}) = 1;

    #lhsPvProduction_@{reg} = Q_PV_@{reg};
    #rhsPvProduction_@{reg} = phiPV_p * K_PV_@{reg} * exp(exo_PVEff_@{reg});
    [name = 'PV home production @{reg}']
    (1 + lhsPvProduction_@{reg}) / (1 + rhsPvProduction_@{reg}) = 1;

    // ------------------------------------------------------------------
    // Sectoral capital and labour supply
    // ------------------------------------------------------------------

    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]

            // Endogenous depreciation: fossil subsector only, accelerates when carbon price rises.
            #fossilMult_@{subsec}_@{reg} = 1 + (@{subsec} == @{SubsecFossil})
                * min(1, max(0, exp(gamPEdel_p * (PE_@{reg}(-1) - PE_@{reg}(-2))) - 1));
            delta_@{subsec}_@{reg} = rhophiK_p * delta_@{subsec}_@{reg}(-1)
                + (1 - rhophiK_p) * delta_@{subsec}_@{reg}_p * fossilMult_@{subsec}_@{reg};

            // Log rental rate auxiliary variable (max guard prevents log(0) at boundary).
            #lhsLogRentalRate_@{reg}_@{subsec} = rlog_H_@{subsec}_@{reg};
            #rhsLogRentalRate_@{reg}_@{subsec} = log(max(1e-6, r_H_@{subsec}_@{reg}));
            [name = 'log household rental rate @{subsec} @{reg}']
            (lhsLogRentalRate_@{reg}_@{subsec} + 1) = (rhsLogRentalRate_@{reg}_@{subsec} + 1);

            // Effective forward depreciation: augmented by utilization cost when lEndoUtilization == 1.
            @# if lEndoUtilization == 1
                #rKSS_@{reg}_@{subsec}     = 1 / beta_p - 1 + delta_@{subsec}_@{reg}EXP;
                #uKPos_@{reg}_@{subsec}    = 0.5 * (  u_K_@{subsec}_@{reg}EXP
                                                     + sqrt(u_K_@{subsec}_@{reg}EXP^2 + 1e-4)  );
                #effDeltaFwd_@{reg}_@{subsec} = delta_@{subsec}_@{reg}EXP
                    + rKSS_@{reg}_@{subsec} / sigmaU_p * (uKPos_@{reg}_@{subsec}^sigmaU_p - 1);
            @# else
                #effDeltaFwd_@{reg}_@{subsec} = delta_@{subsec}_@{reg}EXP;
            @# endif

            // FOC: household-owned capital (Euler equation for K_H).
            #lhsFocHhCapital_@{reg}_@{subsec} =
                lambda_@{reg}EXP * beta_p * exp(exo_beta + exo_beta_@{subsec}_@{reg})
                    * (exp(rlog_H_@{subsec}_@{reg}EXP) - wedgeKE_@{subsec}_@{reg}EXP)
                    * P_K_@{subsec}_@{reg}EXP * (1 - tauKH_@{subsec}_@{reg}EXP)
                + lambda_@{reg}EXP * omegaI_@{subsec}_@{reg}EXP * P_INV_@{subsec}_@{reg}EXP
                    * beta_p * exp(exo_beta) * (1 - effDeltaFwd_@{reg}_@{subsec})
                + muI_@{subsec}_@{reg} * P_INV_@{subsec}_@{reg};
            #rhsFocHhCapital_@{reg}_@{subsec} =
                lambda_@{reg} * omegaI_@{subsec}_@{reg} * P_INV_@{subsec}_@{reg};
            [name = 'FOC household capital @{subsec} @{reg}']
            (lhsFocHhCapital_@{reg}_@{subsec} + 1) / (rhsFocHhCapital_@{reg}_@{subsec} + 1) = 1;

            @#include "ModFiles/Equations/investment_adjustment.mod"

            // FOC: labour supply — endogenous N when lEndoN == 1, pinned to calibration otherwise.
            #lhsFocLabour_@{reg}_@{subsec} =
                (1 - tauNH_@{reg}) * W_@{subsec}_@{reg} * LF_@{reg} / PoP_@{reg}
                    * lambda_@{reg} * lEndoN_@{subsec}_@{reg}_p
                + (1 - lEndoN_@{subsec}_@{reg}_p) * N_@{subsec}_@{reg};
            #rhsFocLabour_@{reg}_@{subsec} =
                phiL_@{subsec}_@{reg}_p * A_N_@{subsec}_@{reg} * N_@{subsec}_@{reg}^sigmaL_p
                    * lEndoN_@{subsec}_@{reg}_p
                + (1 - lEndoN_@{subsec}_@{reg}_p) * phiN0_@{subsec}_@{reg}_p * N0_@{reg}_p;
            [name = 'FOC labour supply @{subsec} @{reg}']
            (lhsFocLabour_@{reg}_@{subsec} + 1) / (rhsFocLabour_@{reg}_@{subsec} + 1) = 1;

            // SRI wedge: emission-intensity capital rental premium (zero when phiKE_p == 0).
            #lhsSriWedge_@{reg}_@{subsec} = wedgeKE_@{subsec}_@{reg};
            #rhsSriWedge_@{reg}_@{subsec} =
                phiKE_p * kappaE_@{subsec}_@{reg}
                    * beta_p * (1 - delta_@{subsec}_@{reg}) / (1 - beta_p * (1 - delta_@{subsec}_@{reg}))
                + exo_wedgeKE_@{subsec}_@{reg};
            [name = 'SRI capital rental wedge @{subsec} @{reg}']
            (lhsSriWedge_@{reg}_@{subsec} + 1) = (rhsSriWedge_@{reg}_@{subsec} + 1);

        @# endfor
    @# endfor

    // ------------------------------------------------------------------
    // Bilateral inter-regional bonds and net exports
    // ------------------------------------------------------------------

    @# for regm in 1:Regions
        @# if Regions == 1
            // Single-region model: bilateral foreign assets and net exports are trivially zero.
            #lhsRegBonds_@{reg}_@{regm} = B_@{reg}_@{regm};
            #rhsRegBonds_@{reg}_@{regm} = 0;
            [name = 'bilateral foreign assets @{reg} @{regm}']
            (lhsRegBonds_@{reg}_@{regm} + 1) / (1 + rhsRegBonds_@{reg}_@{regm}) = 1;

            #lhsRegNX_@{reg}_@{regm} = NX_@{reg}_@{regm};
            #rhsRegNX_@{reg}_@{regm} = 0;
            [name = 'bilateral regional net exports @{reg} @{regm}']
            (lhsRegNX_@{reg}_@{regm} + 1) / (rhsRegNX_@{reg}_@{regm} + 1) = 1;
        @# else
            // Multi-region model: FOC for inter-regional bond holdings.
            #lhsRegBonds_@{reg}_@{regm} = lambda_@{reg};
            #rhsRegBonds_@{reg}_@{regm} = lambda_@{reg}EXP * beta_p * exp(exo_beta)
                * (1 + rfEXP - deltaB_p)
                * exp(-phiB_p * (rfEXP * sf_@{reg} * B_@{reg}_@{regm}EXP + NX_@{reg}_@{regm}EXP));
            [name = 'FOC inter-regional bonds @{reg} @{regm}']
            (1 + lhsRegBonds_@{reg}_@{regm}) / (1 + rhsRegBonds_@{reg}_@{regm}) = 1;

            // Bilateral net exports: value of goods shipped from regm to reg minus reverse flow.
            #lhsRegNX_@{reg}_@{regm} = NX_@{reg}_@{regm};
            #rhsRegNX_@{reg}_@{regm} =
                @# for sec in 1:Sectors
                    @# for subsec in Subsecstart[sec]:Subsecend[sec]
                        + P_Q_@{subsec}_@{reg}  * Q_D_@{subsec}_@{regm}_@{reg}
                        - P_Q_@{subsec}_@{regm} * Q_D_@{subsec}_@{reg}_@{regm}
                    @# endfor
                @# endfor
                ;
            [name = 'bilateral regional net exports @{reg} @{regm}']
            (lhsRegNX_@{reg}_@{regm} + 1) / (rhsRegNX_@{reg}_@{regm} + 1) = 1;
        @# endif
    @# endfor

@# endfor
