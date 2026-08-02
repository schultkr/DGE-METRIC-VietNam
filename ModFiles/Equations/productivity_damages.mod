// ==========================================
// Block 8: Productivity and Damages
// ==========================================

@# for reg in 1:Regions
    @# for sec in 1:Sectors

        // ------------------------------------------------------------------
        // Sector-level TFP for final demand aggregation (A_F).
        // Energy efficiency EE enters only for the energy sector.
        // ------------------------------------------------------------------

        #lhsSectorTfpFinal_@{reg}_@{sec} = A_F_@{sec}_@{reg};
        #rhsSectorTfpFinal_@{reg}_@{sec} = exp(exo_A_F_@{sec}_@{reg})
            * EE_@{reg}^(@{sec} == iSecEnergy_p);
        [name = 'sector TFP final demand @{sec} @{reg}']
        (lhsSectorTfpFinal_@{reg}_@{sec} + 1) / (rhsSectorTfpFinal_@{reg}_@{sec} + 1) = 1;

        @# for subsec in Subsecstart[sec]:Subsecend[sec]

            // --------------------------------------------------------------
            // TFP / output target (mode set by YEndogenous and YTarget)
            // --------------------------------------------------------------

            @# if YEndogenous == 1
                // Endogenous Y: pin TFP (A) or output (Q) in log space.
                #lhsTfp_@{reg}_@{subsec} = log(
                    A_@{subsec}_@{reg}   *      lEndoQ_@{subsec}_@{reg}_p
                    + Q_@{subsec}_@{reg} * (1 - lEndoQ_@{subsec}_@{reg}_p));
                #rhsTfp_@{reg}_@{subsec} =
                    log(A_@{subsec}_@{reg}_p * KG_@{reg}^phiG_p
                        * exp(exo_A_@{subsec}_@{reg} + exo_@{subsec}_@{reg}))
                        *      lEndoQ_@{subsec}_@{reg}_p
                    + log(Q0_@{subsec}_@{reg}_p * exp(exo_Q_@{subsec}_@{reg}))
                        * (1 - lEndoQ_@{subsec}_@{reg}_p);
                [name = 'sector TFP @{subsec} @{reg}']
                (lhsTfp_@{reg}_@{subsec} + 1) / (rhsTfp_@{reg}_@{subsec} + 1) = 1;
            @# else
                // Exogenous Y: output pinned to an exogenous path in levels.
                // YTarget == 1: nominal GVA target; YTarget == 2: real GVA target; else: gross output.
                @# if YTarget == 1
                    #lhsTfp_@{reg}_@{subsec} =
                        Y_@{subsec}_@{reg} * P_@{subsec}_@{reg} *      lEndoQ_@{subsec}_@{reg}_p
                        + Q_@{subsec}_@{reg}                    * (1 - lEndoQ_@{subsec}_@{reg}_p);
                    #rhsTfp_@{reg}_@{subsec} =
                        P0_@{subsec}_@{reg}_p * Y0_@{subsec}_@{reg}_p
                            * exp(exo_@{subsec}_@{reg} + exo_A_@{subsec}_@{reg})
                            *      lEndoQ_@{subsec}_@{reg}_p
                        + Q0_@{subsec}_@{reg}_p * exp(exo_Q_@{subsec}_@{reg})
                            * (1 - lEndoQ_@{subsec}_@{reg}_p);
                @# elseif YTarget == 2
                    #lhsTfp_@{reg}_@{subsec} =
                        Y_@{subsec}_@{reg} *      lEndoQ_@{subsec}_@{reg}_p
                        + Q_@{subsec}_@{reg} * (1 - lEndoQ_@{subsec}_@{reg}_p);
                    #rhsTfp_@{reg}_@{subsec} =
                        Y0_@{subsec}_@{reg}_p
                            * exp(exo_@{subsec}_@{reg} + exo_A_@{subsec}_@{reg})
                            *      lEndoQ_@{subsec}_@{reg}_p
                        + Q0_@{subsec}_@{reg}_p * exp(exo_Q_@{subsec}_@{reg})
                            * (1 - lEndoQ_@{subsec}_@{reg}_p);
                @# else
                    #lhsTfp_@{reg}_@{subsec} = Q_@{subsec}_@{reg};
                    #rhsTfp_@{reg}_@{subsec} =
                        Q0_@{subsec}_@{reg}_p
                            * exp(exo_@{subsec}_@{reg} + exo_A_@{subsec}_@{reg})
                            *      lEndoQ_@{subsec}_@{reg}_p
                        + Q0_@{subsec}_@{reg}_p * exp(exo_Q_@{subsec}_@{reg})A_I_
                            * (1 - lEndoQ_@{subsec}_@{reg}_p);
                @# endif
                [name = 'sector TFP @{subsec} @{reg}']
                (lhsTfp_@{reg}_@{subsec} + 1) / (rhsTfp_@{reg}_@{subsec} + 1) = 1;
            @# endif

            // --------------------------------------------------------------
            // Production factor productivity shocks
            // --------------------------------------------------------------

            // Intermediate input productivity (log).
            #lhsTfpIntermediates_@{reg}_@{subsec} = log(A_I_@{subsec}_@{reg});
            #rhsTfpIntermediates_@{reg}_@{subsec} = exo_A_I_@{subsec}_@{reg}
                + (1 - lEndogenousY_p) * exo_QI_@{subsec}_@{reg};
            [name = 'intermediate input productivity @{subsec} @{reg}']
            (lhsTfpIntermediates_@{reg}_@{subsec} + 1) / (rhsTfpIntermediates_@{reg}_@{subsec} + 1) = 1;

            // Capital-augmenting productivity shock.
            #lhsCapitalProductivity_@{reg}_@{subsec} = A_K_@{subsec}_@{reg};
            #rhsCapitalProductivity_@{reg}_@{subsec} = exp(exo_K_@{subsec}_@{reg});
            [name = 'capital productivity shock @{subsec} @{reg}']
            (lhsCapitalProductivity_@{reg}_@{subsec} + 1) / (rhsCapitalProductivity_@{reg}_@{subsec} + 1) = 1;

            // Labour productivity: endogenous A_N (NEndogenous == 1) or exogenous N.
            @# if NEndogenous == 1
                #lhsLabourProductivity_@{reg}_@{subsec} = log(A_N_@{subsec}_@{reg});
                #rhsLabourProductivity_@{reg}_@{subsec} = exo_N_@{subsec}_@{reg};
                [name = 'labour productivity shock @{subsec} @{reg}']
                (lhsLabourProductivity_@{reg}_@{subsec} + 1) / (rhsLabourProductivity_@{reg}_@{subsec} + 1) = 1;
            @# else
                #lhsLabourProductivity_@{reg}_@{subsec} = N_@{subsec}_@{reg};
                #rhsLabourProductivity_@{reg}_@{subsec} = phiN0_@{subsec}_@{reg}_p * N0_@{reg}_p
                    * exp(exo_N_@{subsec}_@{reg});
                [name = 'exogenous labour input @{subsec} @{reg}']
                (lhsLabourProductivity_@{reg}_@{subsec} + 1) / (rhsLabourProductivity_@{reg}_@{subsec} + 1) = 1;
            @# endif

            // --------------------------------------------------------------
            // Damage functions
            // --------------------------------------------------------------

            // TFP damage.
            [name = 'TFP damage @{subsec} @{reg}']
            (D_@{subsec}_@{reg} + 1) = (exo_D_@{subsec}_@{reg} + 1);

            // Labour productivity damage.
            #lhsLabourDamage_@{reg}_@{subsec} = D_N_@{subsec}_@{reg};
            #rhsLabourDamage_@{reg}_@{subsec} = exo_D_N_@{subsec}_@{reg};
            [name = 'labour damage @{subsec} @{reg}']
            (lhsLabourDamage_@{reg}_@{subsec} + 1) / (rhsLabourDamage_@{reg}_@{subsec} + 1) = 1;

            // Capital damage with smooth investment floor.
            // The smooth switch suppresses D_K when investment falls below ~5% of replacement
            // to prevent scrapping from stalling convergence under deep decarbonisation scenarios.
            #epsIDam_@{reg}_@{subsec}    = 1e-3;
            #phiGEff_@{reg}_@{subsec}    = min(1, max(0, phiG_@{subsec}_@{reg}_p * exp(exo_phiG_@{subsec}_@{reg})));
            #iDamRefRaw_@{reg}_@{subsec} = 0.01 * (1 - phiGEff_@{reg}_@{subsec})
                * delta_@{subsec}_@{reg}_p * K0_@{subsec}_@{reg}_p;
            // Smooth max(iDamRefRaw, epsIDam) to keep IDamRef strictly positive.
            #iDamRef_@{reg}_@{subsec} = 0.5 * (
                iDamRefRaw_@{reg}_@{subsec} + epsIDam_@{reg}_@{subsec}
                + sqrt((iDamRefRaw_@{reg}_@{subsec} - epsIDam_@{reg}_@{subsec})^2
                       + epsIDam_@{reg}_@{subsec}^2));
            #iFloor_@{reg}_@{subsec}    = 0.05 * iDamRef_@{reg}_@{subsec};
            #epsISwitch_@{reg}_@{subsec} = 0.02 * iDamRef_@{reg}_@{subsec} + epsIDam_@{reg}_@{subsec};
            // Cubic smooth indicator: ~0 when I < iFloor, ~1 when I > iFloor.
            #zSmooth_@{reg}_@{subsec} = min(1, max(0,
                (I_@{subsec}_@{reg} - iFloor_@{reg}_@{subsec}) / epsISwitch_@{reg}_@{subsec}));
            #sSmooth_@{reg}_@{subsec} = zSmooth_@{reg}_@{subsec}^2 * (3 - 2 * zSmooth_@{reg}_@{subsec});

            #lhsCapitalDamage_@{reg}_@{subsec} = D_K_@{subsec}_@{reg};
            #rhsCapitalDamage_@{reg}_@{subsec} = sSmooth_@{reg}_@{subsec}
                * exo_D_K_@{subsec}_@{reg} * K0_@{subsec}_@{reg}_p;
            [name = 'capital damage @{subsec} @{reg}']
            (lhsCapitalDamage_@{reg}_@{subsec} + 1) / (rhsCapitalDamage_@{reg}_@{subsec} + 1) = 1;

            // --------------------------------------------------------------
            // Capital prices
            // --------------------------------------------------------------

            @# if lCapPrice == 0
                // Rental price of capital equals the sector's own value-added price.
                [name = 'rental price of capital @{subsec} @{reg}']
                (P_K_@{subsec}_@{reg} + 1) / (P_@{subsec}_@{reg} * exp(exo_P_K_@{subsec}_@{reg}) + 1) = 1;

                // Investment goods price: sector-specific capital good (lCapGoodsSecPrice == 1)
                // or same as value-added price.
                @# if lCapGoodsSecPrice == 1
                    #rhsInvPrice_@{reg}_@{subsec} = P_Q_@{CapGoodsSubsec}_@{reg} * exp(exo_I_@{subsec}_@{reg});
                @# else
                    #rhsInvPrice_@{reg}_@{subsec} = P_@{subsec}_@{reg} * exp(exo_P_K_@{subsec}_@{reg});
                @# endif
                [name = 'investment goods price @{subsec} @{reg}']
                (P_INV_@{subsec}_@{reg} + 1) / (rhsInvPrice_@{reg}_@{subsec} + 1) = 1;
            @# endif

            // --------------------------------------------------------------
            // Adjustment cost curvature and mark-up
            // --------------------------------------------------------------

            #lhsInvAdjCost_@{reg}_@{subsec} = phiK_@{subsec}_@{reg}
                + phiG_p * (exo_I_@{subsec}_@{reg} + exo_P_K_@{subsec}_@{reg});
            #rhsInvAdjCost_@{reg}_@{subsec} = phiK_@{subsec}_@{reg}_p * exp(exo_phiK_@{subsec}_@{reg});
            [name = 'investment adjustment cost curvature @{subsec} @{reg}']
            (lhsInvAdjCost_@{reg}_@{subsec} + 1) / (rhsInvAdjCost_@{reg}_@{subsec} + 1) = 1;

            // Mark-up over wages and rental rate.
            #lhsMarkup_@{reg}_@{subsec} = mu_@{subsec}_@{reg};
            #rhsMarkup_@{reg}_@{subsec} = exp(exo_mu_@{subsec}_@{reg});
            [name = 'mark-up @{subsec} @{reg}']
            (lhsMarkup_@{reg}_@{subsec} + 1) / (rhsMarkup_@{reg}_@{subsec} + 1) = 1;

            // Demand shifter for subsector output.
            #lhsDemandShift_@{reg}_@{subsec} = A_D_@{subsec}_@{reg};
            #rhsDemandShift_@{reg}_@{subsec} = exp(exo_A_D_@{subsec}_@{reg});
            [name = 'demand shifter @{subsec} @{reg}']
            (lhsDemandShift_@{reg}_@{subsec} + 1) / (rhsDemandShift_@{reg}_@{subsec} + 1) = 1;

            // --------------------------------------------------------------
            // Capital utilization rate (exogenous case only; endogenous in households.mod)
            // --------------------------------------------------------------

            @# if lEndoUtilization == 0
                #lhsCapUtilization_@{reg}_@{subsec} = u_K_@{subsec}_@{reg};
                #rhsCapUtilization_@{reg}_@{subsec} = exp(exo_u_K_@{subsec}_@{reg})
                    + exo_lIGShare_@{subsec}_@{reg} * (rf0_p + exo_r_G_@{subsec}_@{reg});
                [name = 'capital utilization rate @{subsec} @{reg}']
                (lhsCapUtilization_@{reg}_@{subsec} + 1) / (rhsCapUtilization_@{reg}_@{subsec} + 1) = 1;
            @# endif

        @# endfor
    @# endfor

    // ------------------------------------------------------------------
    // Regional housing damage
    // ------------------------------------------------------------------

    #lhsHousingDamage_@{reg} = DH_@{reg};
    #rhsHousingDamage_@{reg} = exo_DH_@{reg} * Y / PH_@{reg};
    [name = 'housing damage @{reg}']
    (lhsHousingDamage_@{reg} + 1) = (rhsHousingDamage_@{reg} + 1);

@# endfor
