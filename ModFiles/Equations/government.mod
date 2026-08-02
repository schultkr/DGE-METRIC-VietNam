// ==========================================
// Block 7: Government
// ==========================================

@# for reg in 1:Regions
    // Regional fiscal aggregates.
    #lhsRegionalGovernmentInvestment_@{reg} = I_G_@{reg} * P_@{reg};
    #rhsRegionalGovernmentInvestment_@{reg} =
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + (
                    I_G_@{subsec}_@{reg} * P_INV_@{subsec}_@{reg}
                    + G_A_@{subsec}_@{reg} * P_INV_@{subsec}_@{reg}
                )
            @# endfor
        @# endfor
    ;
    [name = 'regional government investment @{reg}']
    (lhsRegionalGovernmentInvestment_@{reg} + 1) / (rhsRegionalGovernmentInvestment_@{reg} + 1) = 1;

    #lhsRegionalGovernmentBudget_@{reg} =
        P_@{reg} * G_@{reg}
        + P_@{reg} * I_G_@{reg}
        + Tr_@{reg}
        + BG_@{reg};
    #rhsRegionalGovernmentBudget_@{reg} =
        tauC_@{reg} * P_@{reg} * C_@{reg}
        + IH_@{reg} * PH_@{reg} * tauH_@{reg}
        + PE_@{reg} * E_@{reg}
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + (
                    tauKF_@{subsec}_@{reg} * r_F_@{subsec}_@{reg} * K_@{subsec}_@{reg}(-1) * P_K_@{subsec}_@{reg}
                    + tauKH_@{subsec}_@{reg} * r_H_@{subsec}_@{reg} * K_H_@{subsec}_@{reg}(-1) * P_K_@{subsec}_@{reg}
                )
                + (tauNF_@{subsec}_@{reg} + tauNH_@{reg}) * W_@{subsec}_@{reg} * N_@{subsec}_@{reg} * LF_@{reg}
                + r_G_@{subsec}_@{reg} * P_K_@{subsec}_@{reg} * K_G_@{subsec}_@{reg}(-1)
            @# endfor
        @# endfor
        + (1 + rf) * ((phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}) * s_@{reg}(-1) + (1 - (phi_BG_ext_@{reg}_p + exo_phi_BG_ext_@{reg}))) * BG_@{reg}(-1);
    [name = 'regional government budget constraint @{reg}']
    (lhsRegionalGovernmentBudget_@{reg} + 1) / (rhsRegionalGovernmentBudget_@{reg} + 1) = 1;

    #lhsRegionalTransfers_@{reg} = Tr_@{reg};
    #rhsRegionalTransfers_@{reg} =
        Tr0_@{reg}_p
        + exo_Tr_@{reg}
        + exo_tauSTr_@{reg} * PE_@{reg} * E_@{reg};
    [name = 'regional transfers @{reg}']
    (lhsRegionalTransfers_@{reg} + 1) / (rhsRegionalTransfers_@{reg} + 1) = 1;

    #lhsHousingAdaptationSpending_@{reg} = G_A_DH_@{reg};
    #rhsHousingAdaptationSpending_@{reg} = exo_G_A_DH * Y0_p;
    [name = 'adaptation measures for housing stock @{reg}']
    (lhsHousingAdaptationSpending_@{reg} + 1) = (rhsHousingAdaptationSpending_@{reg} + 1);

    #lhsGovernmentDebtTarget_@{reg} = BG_@{reg};
    #rhsGovernmentDebtTarget_@{reg} = (BG0_@{reg}_p + exo_BG_@{reg}) * Y0_p;
    [name = 'government debt target @{reg}']
    (lhsGovernmentDebtTarget_@{reg} + 1) = (rhsGovernmentDebtTarget_@{reg} + 1);

    #lhsPublicGoodsCapital_@{reg} = KG_@{reg};
    #rhsPublicGoodsCapital_@{reg} =
        (1 - deltaKG_p) * KG_@{reg}(-1)
        + G_@{reg};
    [name = 'public goods capital stock @{reg}']
    (lhsPublicGoodsCapital_@{reg} + 1) / (rhsPublicGoodsCapital_@{reg} + 1) = 1;

    // Regional household tax rates.
    #lhsHouseholdLabourTax_@{reg} = tauNH_@{reg};
    #rhsHouseholdLabourTax_@{reg} = tauNH_@{reg}_p + exo_tauNH_@{reg};
    [name = 'taxes on household labour income @{reg}']
    (lhsHouseholdLabourTax_@{reg} + 1) = (rhsHouseholdLabourTax_@{reg} + 1);

    #lhsConsumptionTax_@{reg} = tauC_@{reg};
    #rhsConsumptionTax_@{reg} = tauCEndo_@{reg};
    [name = 'taxes on consumption @{reg}']
    (lhsConsumptionTax_@{reg} + 1) = (rhsConsumptionTax_@{reg} + 1);

    // tauCEndo mirrors EE_reg/Q_fossil_reg's actual mechanism exactly, reusing the
    // SAME compile-time indicator EE_reg's own equation branches on (lEndogenousY_p,
    // see climate_emissions.mod), not a separate Baseline-specific parameter -- a
    // runtime multiplier, not a preprocessor @#if/@#else branch, since Dynare's strict
    // mode requires every declared exogenous variable to appear textually in the model
    // block, which @#if/@#else would violate (each compiled variant would be missing
    // whichever branch's shocks it doesn't take). change_mod_file.m always sets
    // YEndogenous and BaselineScenario together (Baseline: YEndogenous=0,
    // BaselineScenario=1; every other scenario: YEndogenous=1, BaselineScenario=0), so
    // lEndogenousY_p==0 is exactly equivalent to "Baseline compiled" -- no separate
    // lBaselineScenario_p parameter is needed.
    // Baseline (lEndogenousY_p==0): tauCEndo is absent from its own equation, which
    // instead pins G/Y to a target, freeing tauCEndo (hence tauC) to be resolved by
    // the government budget constraint above.
    // Outside Baseline (lEndogenousY_p==1): tauCEndo follows the ordinary exogenous
    // rule: tauC_p plus exo_tauC (the baseline-required path, set programmatically in
    // scenarios, see apply_baseline_shock_structure) plus exo_tauCScen (free for
    // scenario-specific additional tauC shocks on top of the baseline-required path).
    #lhsTauCEndo_@{reg} =
        (G_@{reg} / Y_@{reg}) * (lEndogenousY_p == 0)
        + tauCEndo_@{reg} * (lEndogenousY_p == 1);
    #rhsTauCEndo_@{reg} =
        (GY0_@{reg}_p + exo_targetGY_@{reg}) * (lEndogenousY_p == 0)
        + (tauC_@{reg}_p + exo_tauC_@{reg} + exo_tauCScen_@{reg}) * (lEndogenousY_p == 1);
    [name = 'endogenous consumption tax / government consumption target @{reg}']
    (lhsTauCEndo_@{reg} + 1) = (rhsTauCEndo_@{reg} + 1);

    #lhsHousingTax_@{reg} = tauH_@{reg};
    #rhsHousingTax_@{reg} = tauH_@{reg}_p + exo_tauH_@{reg};
    [name = 'taxes on housing @{reg}']
    (lhsHousingTax_@{reg} + 1) = (rhsHousingTax_@{reg} + 1);

    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            // Sector-level tax rates.
            #lhsHouseholdCapitalTax_@{reg}_@{subsec} = tauKH_@{subsec}_@{reg};
            #rhsHouseholdCapitalTax_@{reg}_@{subsec} =
                tauKH_@{subsec}_@{reg}_p
                + exo_tauKH_@{subsec}_@{reg};
            [name = 'taxes on household capital income @{subsec} @{reg}']
            (lhsHouseholdCapitalTax_@{reg}_@{subsec} + 1) = (rhsHouseholdCapitalTax_@{reg}_@{subsec} + 1);

            #lhsFirmCapitalTax_@{reg}_@{subsec} = tauKF_@{subsec}_@{reg};
            #rhsFirmCapitalTax_@{reg}_@{subsec} =
                tauKF_@{subsec}_@{reg}_p
                - tauS_@{reg} * (@{subsec} != iSubsecFossil_p)
                + exo_tauKF_@{subsec}_@{reg};
            [name = 'sector specific corporate tax rate paid by firms @{subsec} @{reg}']
            (lhsFirmCapitalTax_@{reg}_@{subsec} + 1) / (rhsFirmCapitalTax_@{reg}_@{subsec} + 1) = 1;

            #lhsFirmLabourTax_@{reg}_@{subsec} = tauNF_@{subsec}_@{reg};
            #rhsFirmLabourTax_@{reg}_@{subsec} =
                tauNF_@{subsec}_@{reg}_p
                + exo_tauNF_@{subsec}_@{reg};
            [name = 'sector specific labour tax rate paid by firms @{subsec} @{reg}']
            (lhsFirmLabourTax_@{reg}_@{subsec} + 1) / (rhsFirmLabourTax_@{reg}_@{subsec} + 1) = 1;

            // Sector adaptation and public capital.
            #lhsSectorAdaptationCapitalTarget_@{reg}_@{subsec} = K_A_@{subsec}_@{reg};
            #rhsSectorAdaptationCapitalTarget_@{reg}_@{subsec} =
                exo_GA_@{subsec}_@{reg} * Y0_p;
            [name = 'sector specific adaptation capital target from government expenditure @{subsec} @{reg}']
            (lhsSectorAdaptationCapitalTarget_@{reg}_@{subsec} + 1) / (rhsSectorAdaptationCapitalTarget_@{reg}_@{subsec} + 1) = 1;

            #lhsSectorAdaptationCapital_@{reg}_@{subsec} = K_A_@{subsec}_@{reg};
            #rhsSectorAdaptationCapital_@{reg}_@{subsec} =
                (1 - deltaKA_@{subsec}_@{reg}_p) * K_A_@{subsec}_@{reg}(-1)
                + G_A_@{subsec}_@{reg};
            [name = 'sector specific adaptation capital against climate change @{subsec} @{reg}']
            (lhsSectorAdaptationCapital_@{reg}_@{subsec} + 1) / (rhsSectorAdaptationCapital_@{reg}_@{subsec} + 1) = 1;

            #effectivePublicDamageShare_@{reg}_@{subsec} =
                min(1, max(0, phiG_@{subsec}_@{reg}_p * exp(exo_phiG_@{subsec}_@{reg})));
            // Crowding-out backstop: K_G cannot structurally exceed sKGmax_eff * K(-1). Without
            // this, the level-mode I_G target below is anchored to K0_p (base-year capital) and
            // grows independently of the sector's *current* capital demand — in a shrinking
            // sector (e.g. fossil under decarbonization) K_G can outgrow total firm-demanded K
            // and force K_H = K - K_G - K_FDI negative (see firms.mod capital aggregation).
            // Uses K(-1) (predetermined) as the reference to avoid same-period simultaneity with
            // the K = K_H + K_G + K_FDI identity. This is a backstop, not a policy target — kept
            // loose (default 0.85) so it only binds in the pathological crowding-out case.
            #lhsSectorPublicCapital_@{reg}_@{subsec} = K_G_@{subsec}_@{reg} / PoP_@{reg};
            #rhsSectorPublicCapital_@{reg}_@{subsec} =
                    max(
                        0,
                        (1 - delta_@{subsec}_@{reg}) * K_G_@{subsec}_@{reg}(-1) /PoP_@{reg}(-1)
                        + I_G_@{subsec}_@{reg} / PoP_@{reg}
                        + D_K_@{subsec}_@{reg} / PoP_@{reg}
                    )
                ;
            [name = 'sector specific public capital @{subsec} @{reg}']
            (lhsSectorPublicCapital_@{reg}_@{subsec} + 1) / (rhsSectorPublicCapital_@{reg}_@{subsec} + 1) = 1;

            #lhsSectorPublicInvestmentShare_@{reg}_@{subsec} = s_G_@{subsec}_@{reg};
            #rhsSectorPublicInvestmentShare_@{reg}_@{subsec} =
                s_G_@{subsec}_@{reg}_p
                + exo_s_G_@{subsec}_@{reg}
                + exo_s_GScen_@{subsec}_@{reg}
                + exo_KTargetB_@{subsec}_@{reg} * (exo_KTarget_@{subsec}_@{reg} * Y / P_K_@{subsec}_@{reg});
            [name = 'sector specific public investment @{subsec} @{reg}']
            (lhsSectorPublicInvestmentShare_@{reg}_@{subsec} + 1) / (rhsSectorPublicInvestmentShare_@{reg}_@{subsec} + 1) = 1;

            #lhsPublicRentalRate_@{reg}_@{subsec} =
                r_G_@{subsec}_@{reg} * P_K_@{subsec}_@{reg} / P_INV_@{subsec}_@{reg}(-1);
            #rhsPublicRentalRate_@{reg}_@{subsec} =
                rf0_p
                + exo_r_G_@{subsec}_@{reg};
            [name = 'sector specific public rental rate @{subsec} @{reg}']
            (lhsPublicRentalRate_@{reg}_@{subsec} + 1) / (rhsPublicRentalRate_@{reg}_@{subsec} + 1) = 1;

            // When lIGShare=0: pin I_G to the exogenous public-capital replacement path.
            // When lIGShare=1: pin I_G as a share of total I.
            // K_G then evolves from the law of motion above.
            #lhsSectorPublicCapitalInvestmentTarget_@{reg}_@{subsec} =
                (1 - exo_lIGShare_@{subsec}_@{reg}) * I_G_@{subsec}_@{reg}
                + exo_lIGShare_@{subsec}_@{reg} * I_G_@{subsec}_@{reg};
            #rhsSectorPublicCapitalInvestmentTarget_@{reg}_@{subsec} =
                (1 - exo_lIGShare_@{subsec}_@{reg})
                * phiG_@{subsec}_@{reg}_p
                * delta_@{subsec}_@{reg}_p
                * K0_@{subsec}_@{reg}_p
                * exp(exo_K_G_@{subsec}_@{reg})
                + exo_lIGShare_@{subsec}_@{reg} * exo_sIGShare_@{subsec}_@{reg} * I_@{subsec}_@{reg};
            [name = 'scenario sector specific public capital / investment share @{subsec} @{reg}']
            (lhsSectorPublicCapitalInvestmentTarget_@{reg}_@{subsec} + 1) / (rhsSectorPublicCapitalInvestmentTarget_@{reg}_@{subsec} + 1) = 1;

            #lhsFDIRentalRate_@{reg}_@{subsec} =
                r_FDI_@{subsec}_@{reg}
                * (P_K_@{subsec}_@{reg} / P_INV_@{subsec}_@{reg}(-1))^(exo_lIGShare_@{subsec}_@{reg});
            #rhsFDIRentalRate_@{reg}_@{subsec} =
                exo_r_FDI_@{subsec}_@{reg}
                + rf0_p;
            [name = 'FDI rental rate (returns to foreign investors) @{subsec} @{reg}']
            (lhsFDIRentalRate_@{reg}_@{subsec} + 1) / (rhsFDIRentalRate_@{reg}_@{subsec} + 1) = 1;

        @# endfor
    @# endfor
@# endfor
