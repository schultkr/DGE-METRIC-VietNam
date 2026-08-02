// ==========================================
// Block 11: Firms
// ==========================================

@# for reg in 1:Regions
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            // Subsector and regional production.
            #emissionAdjustedOutputPrice_@{subsec}_@{reg} =
                P_Q_@{subsec}_@{reg}
                - kappaE_@{subsec}_@{reg} * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p;

            #lhsSubsectorPrice_@{subsec}_@{reg} = P_@{subsec}_@{reg};
            #rhsSubsectorPrice_@{subsec}_@{reg} = exp(p_@{subsec}_@{reg});
            [name = 'regional subsector price level @{subsec} @{reg}']
            (lhsSubsectorPrice_@{subsec}_@{reg} + 1) / (rhsSubsectorPrice_@{subsec}_@{reg} + 1) = 1;

            #lhsValueAddedDemand_@{subsec}_@{reg} = Y_@{subsec}_@{reg};
            #rhsValueAddedDemand_@{subsec}_@{reg} =
                (1 - omegaQI_@{subsec}_@{reg}_p)
                * (P_@{subsec}_@{reg} / emissionAdjustedOutputPrice_@{subsec}_@{reg})^(-etaI_@{subsec}_p)
                * Q_@{subsec}_@{reg};
            [name = 'demand for regional sector value added @{subsec} @{reg}']
            (lhsValueAddedDemand_@{subsec}_@{reg} + 1) / (rhsValueAddedDemand_@{subsec}_@{reg} + 1) = 1;

            #lhsIntermediateCompositeDemand_@{subsec}_@{reg} = Q_I_@{subsec}_@{reg};
            #rhsIntermediateCompositeDemand_@{subsec}_@{reg} =
                omegaQI_@{subsec}_@{reg}_p
                * A_I_@{subsec}_@{reg}^(etaI_@{subsec}_p - 1)
                * (P_I_@{subsec}_@{reg} / emissionAdjustedOutputPrice_@{subsec}_@{reg})^(-etaI_@{subsec}_p)
                * Q_@{subsec}_@{reg};
            [name = 'regional sector demand for intermediate composite @{subsec} @{reg}']
            (lhsIntermediateCompositeDemand_@{subsec}_@{reg} + 1) / (rhsIntermediateCompositeDemand_@{subsec}_@{reg} + 1) = 1;

            // Intermediate demand, emissions, and productivity by source sector.
            #fossilEnergyShare_@{subsec}_@{reg} =
                Q_D_@{SubsecFossil}_@{reg} / Q_A_@{SecEnergy}_@{reg};

            @# for secm in 1:Sectors
                #intermediateEmissionIntensity_@{subsec}_@{reg}_@{secm} =
                    kappaEI_@{subsec}_@{reg}_@{secm}_p
                    * exp(exo_EI_@{subsec}_@{reg}_@{secm})
                    * fossilEnergyShare_@{subsec}_@{reg};
                #intermediateUserCost_@{subsec}_@{reg}_@{secm} =
                    P_A_@{secm}_@{reg}
                    + intermediateEmissionIntensity_@{subsec}_@{reg}_@{secm}
                    * PE_@{reg}
                    * lEndoQ_@{subsec}_@{reg}_p;

                #lhsIntermediateDemandBySector_@{subsec}_@{reg}_@{secm} = Q_I_@{subsec}_@{reg}_@{secm};
                #rhsIntermediateDemandBySector_@{subsec}_@{reg}_@{secm} =
                    omegaQI_@{subsec}_@{reg}_@{secm}_p
                    * A_I_@{subsec}_@{reg}_@{secm}^(etaIA_@{subsec}_p - 1)
                    * (intermediateUserCost_@{subsec}_@{reg}_@{secm} / P_I_@{subsec}_@{reg})^(-etaIA_@{subsec}_p)
                    * Q_I_@{subsec}_@{reg};
                [name = 'regional sector demand for intermediates from aggregate sector @{subsec} @{reg} @{secm}']
                (lhsIntermediateDemandBySector_@{subsec}_@{reg}_@{secm} + 1) / (rhsIntermediateDemandBySector_@{subsec}_@{reg}_@{secm} + 1) = 1;

                #lhsIntermediateEmissionsBySector_@{subsec}_@{reg}_@{secm} = E_I_@{subsec}_@{reg}_@{secm};
                #rhsIntermediateEmissionsBySector_@{subsec}_@{reg}_@{secm} =
                    intermediateEmissionIntensity_@{subsec}_@{reg}_@{secm}
                    * Q_I_@{subsec}_@{reg}_@{secm};
                [name = 'regional emissions caused by using intermediates from aggregate sector @{subsec} @{reg} @{secm}']
                (lhsIntermediateEmissionsBySector_@{subsec}_@{reg}_@{secm} + 1) / (rhsIntermediateEmissionsBySector_@{subsec}_@{reg}_@{secm} + 1) = 1;

                #activeIntermediateProductivityShock_@{subsec}_@{reg}_@{secm} =
                    (exo_AI_@{subsec}_@{reg}_@{secm} != 0) * exo_AI_@{subsec}_@{reg}_@{secm};
                #safeIntermediateInput_@{subsec}_@{reg}_@{secm} =
                    max(1e-8, Q_I_@{subsec}_@{reg}_@{secm}) * A_I_@{subsec}_@{reg}_@{secm};
                #lhsIntermediateProductivity_@{subsec}_@{reg}_@{secm} = A_I_@{subsec}_@{reg}_@{secm};
                #rhsIntermediateProductivity_@{subsec}_@{reg}_@{secm} =
                    exp(activeIntermediateProductivityShock_@{subsec}_@{reg}_@{secm})
                    * EE_@{reg}^(exo_lAddEE_@{subsec}_@{reg} * (@{secm} == iSecEnergy_p));
                [name = 'productivity of intermediates in subsector @{subsec} region @{reg} from sector @{secm}']
                (lhsIntermediateProductivity_@{subsec}_@{reg}_@{secm} + 1) / (rhsIntermediateProductivity_@{subsec}_@{reg}_@{secm} + 1) = 1;
            @# endfor

            // Intermediate and factor-input CES aggregators.
            #lhsIntermediateComposite_@{subsec}_@{reg} = Q_I_@{subsec}_@{reg};
            #rhsIntermediateComposite_@{subsec}_@{reg} =
                (etaIA_@{subsec}_p == 1) * exp(
                    @# for secm in 1:Sectors
                        + log(safeIntermediateInput_@{subsec}_@{reg}_@{secm}) * omegaQI_@{subsec}_@{reg}_@{secm}_p
                    @# endfor
                )
                + (etaIA_@{subsec}_p != 1) * (
                    @# for secm in 1:Sectors
                        + omegaQI_@{subsec}_@{reg}_@{secm}_p^(1 / etaIA_@{subsec}_p)
                        * safeIntermediateInput_@{subsec}_@{reg}_@{secm}^((etaIA_@{subsec}_p - 1) / etaIA_@{subsec}_p)
                    @# endfor
                )^(etaIA_@{subsec}_p / (etaIA_@{subsec}_p - 1 + (etaIA_@{subsec}_p == 1)));
            [name = 'regional intermediate composite aggregator @{subsec} @{reg}']
            (lhsIntermediateComposite_@{subsec}_@{reg} + 1) / (rhsIntermediateComposite_@{subsec}_@{reg} + 1) = 1;

            #damageAdjustedTFP_@{subsec}_@{reg} =
                (1 - D_@{subsec}_@{reg}) * A_@{subsec}_@{reg};
            #effectiveCapitalInput_@{subsec}_@{reg} =
                max(1e-8, A_K_@{subsec}_@{reg} * u_K_@{subsec}_@{reg} * K_@{subsec}_@{reg}(-1));
            #effectiveLaborInput_@{subsec}_@{reg} =
                max(1e-8, LF_@{reg} * (1 - D_N_@{subsec}_@{reg}) * A_N_@{subsec}_@{reg}^1 * N_@{subsec}_@{reg});
            #damageAdjustedLaborProductivity_@{subsec}_@{reg} =
                (1 - D_N_@{subsec}_@{reg}) * A_N_@{subsec}_@{reg}^1 * damageAdjustedTFP_@{subsec}_@{reg};

            #lhsGrossValueAdded_@{subsec}_@{reg} = Y_@{subsec}_@{reg};
            #rhsGrossValueAdded_@{subsec}_@{reg} =
                (etaNK_@{subsec}_@{reg}_p == 1)
                * damageAdjustedTFP_@{subsec}_@{reg}
                * effectiveCapitalInput_@{subsec}_@{reg}^alphaK_@{subsec}_@{reg}_p
                * effectiveLaborInput_@{subsec}_@{reg}^alphaN_@{subsec}_@{reg}_p
                + (etaNK_@{subsec}_@{reg}_p != 1)
                * damageAdjustedTFP_@{subsec}_@{reg}
                * (
                    alphaK_@{subsec}_@{reg}_p^(1 / etaNK_@{subsec}_@{reg}_p)
                    * effectiveCapitalInput_@{subsec}_@{reg}^((etaNK_@{subsec}_@{reg}_p - 1) / etaNK_@{subsec}_@{reg}_p)
                    + alphaN_@{subsec}_@{reg}_p^(1 / etaNK_@{subsec}_@{reg}_p)
                    * effectiveLaborInput_@{subsec}_@{reg}^((etaNK_@{subsec}_@{reg}_p - 1) / etaNK_@{subsec}_@{reg}_p)
                )^(etaNK_@{subsec}_@{reg}_p / (etaNK_@{subsec}_@{reg}_p - 1 + (etaNK_@{subsec}_@{reg}_p == 1) * 1000));
            [name = 'sector specific GVA @{subsec} @{reg}']
            (lhsGrossValueAdded_@{subsec}_@{reg} + 1) / (rhsGrossValueAdded_@{subsec}_@{reg} + 1) = 1;

            // Capital and investment aggregation.
            #lhsFirmCapitalRentalPayments_@{subsec}_@{reg} =
                r_F_@{subsec}_@{reg} * K_@{subsec}_@{reg}(-1);
            #rhsFirmCapitalRentalPayments_@{subsec}_@{reg} =
                K_H_@{subsec}_@{reg}(-1) * r_H_@{subsec}_@{reg}
                + K_G_@{subsec}_@{reg}(-1) * r_G_@{subsec}_@{reg}
                + K_FDI_@{subsec}_@{reg}(-1) * r_FDI_@{subsec}_@{reg};
            [name = 'effective rental of capital paid by firms @{subsec} @{reg}']
            (lhsFirmCapitalRentalPayments_@{subsec}_@{reg} + 1) / (rhsFirmCapitalRentalPayments_@{subsec}_@{reg} + 1) = 1;

            #lhsFirmCapitalStock_@{subsec}_@{reg} = K_@{subsec}_@{reg};
            #rhsFirmCapitalStock_@{subsec}_@{reg} =
                K_H_@{subsec}_@{reg}
                + K_G_@{subsec}_@{reg}
                + K_FDI_@{subsec}_@{reg};
            [name = 'capital used by firms @{subsec} @{reg}']
            (lhsFirmCapitalStock_@{subsec}_@{reg} + 1) / (rhsFirmCapitalStock_@{subsec}_@{reg} + 1) = 1;

            #lhsFirmPrivateInvestment_@{subsec}_@{reg} = I_@{subsec}_@{reg};
            #rhsFirmPrivateInvestment_@{subsec}_@{reg} =
                I_H_@{subsec}_@{reg}
                + I_FDI_@{subsec}_@{reg};
            [name = 'private and FDI investment @{subsec} @{reg}']
            (lhsFirmPrivateInvestment_@{subsec}_@{reg} + 1) / (rhsFirmPrivateInvestment_@{subsec}_@{reg} + 1) = 1;

            // Factor first-order conditions.
            #lhsCapitalFOC_@{subsec}_@{reg} =
                mu_@{subsec}_@{reg}
                * r_F_@{subsec}_@{reg} / u_K_@{subsec}_@{reg}
                * (1 + tauKF_@{subsec}_@{reg})
                * P_K_@{subsec}_@{reg} / P_@{subsec}_@{reg};
            #rhsCapitalFOC_@{subsec}_@{reg} =
                alphaK_@{subsec}_@{reg}_p^(1 / etaNK_@{subsec}_@{reg}_p)
                * (damageAdjustedTFP_@{subsec}_@{reg} * A_K_@{subsec}_@{reg})^((etaNK_@{subsec}_@{reg}_p - 1) / etaNK_@{subsec}_@{reg}_p)
                * (u_K_@{subsec}_@{reg} * K_@{subsec}_@{reg}(-1) / Y_@{subsec}_@{reg})^(-1 / etaNK_@{subsec}_@{reg}_p);
            [name = 'firms FOC capital @{subsec} @{reg}']
            (lhsCapitalFOC_@{subsec}_@{reg} + 1) / (rhsCapitalFOC_@{subsec}_@{reg} + 1) = 1;

            #lhsLabourFOC_@{subsec}_@{reg} =
                mu_@{subsec}_@{reg}
                * W_@{subsec}_@{reg}
                * (1 + tauNF_@{subsec}_@{reg}) / P_@{subsec}_@{reg};
            #rhsLabourFOC_@{subsec}_@{reg} =
                alphaN_@{subsec}_@{reg}_p^(1 / etaNK_@{subsec}_@{reg}_p)
                * damageAdjustedLaborProductivity_@{subsec}_@{reg}^((etaNK_@{subsec}_@{reg}_p - 1) / etaNK_@{subsec}_@{reg}_p)
                * ((LF_@{reg} * N_@{subsec}_@{reg}) / Y_@{subsec}_@{reg})^(-1 / etaNK_@{subsec}_@{reg}_p);
            [name = 'firms FOC labour @{subsec} @{reg}']
            (lhsLabourFOC_@{subsec}_@{reg} + 1) / (rhsLabourFOC_@{subsec}_@{reg} + 1) = 1;

            // Output composite and allocation.
            #safeIntermediateComposite_@{subsec}_@{reg} = max(1e-8, Q_I_@{subsec}_@{reg});
            #safeValueAdded_@{subsec}_@{reg} = max(1e-8, Y_@{subsec}_@{reg});

            #lhsGrossOutputComposite_@{subsec}_@{reg} = Q_@{subsec}_@{reg};
            #rhsGrossOutputComposite_@{subsec}_@{reg} =
                (etaI_@{subsec}_p != 1)
                * (
                    omegaQI_@{subsec}_@{reg}_p^(1 / etaI_@{subsec}_p)
                    * (A_I_@{subsec}_@{reg} * safeIntermediateComposite_@{subsec}_@{reg})^((etaI_@{subsec}_p - 1) / etaI_@{subsec}_p)
                    + (1 - omegaQI_@{subsec}_@{reg}_p)^(1 / etaI_@{subsec}_p)
                    * safeValueAdded_@{subsec}_@{reg}^((etaI_@{subsec}_p - 1) / etaI_@{subsec}_p)
                )^(etaI_@{subsec}_p / (etaI_@{subsec}_p - 1 + (etaI_@{subsec}_p == 1)))
                + (etaI_@{subsec}_p == 1)
                * (
                    safeIntermediateComposite_@{subsec}_@{reg}^omegaQI_@{subsec}_@{reg}_p
                    * safeValueAdded_@{subsec}_@{reg}^(1 - omegaQI_@{subsec}_@{reg}_p)
                );
            [name = 'sector region specific output @{subsec} @{reg}']
            (lhsGrossOutputComposite_@{subsec}_@{reg} + 1) / (rhsGrossOutputComposite_@{subsec}_@{reg} + 1) = 1;

            #lhsExportShare_@{subsec}_@{reg} = D_X_@{subsec}_@{reg};
            #rhsExportShare_@{subsec}_@{reg} = X_@{subsec}_@{reg} / Q_@{subsec}_@{reg};
            [name = 'sector region specific exports share @{subsec} @{reg}']
            (lhsExportShare_@{subsec}_@{reg} + 1) / (rhsExportShare_@{subsec}_@{reg} + 1) = 1;


            #lhsExportDemandSubsec_8_@{reg}_@{subsec} = (phiX_@{subsec}_@{reg}_p>0)*X_@{subsec}_@{reg}/X_@{reg} + (phiX_@{subsec}_@{reg}_p==0)*X_@{subsec}_@{reg};
            #rhsExportDemandSubsec_8_@{reg}_@{subsec} = (phiX_@{subsec}_@{reg}_p>0)*(D_X_@{subsec}_@{reg}_p * exp(exo_X_@{subsec}_@{reg})) * (P_Q_@{subsec}_@{reg} /P_Q_@{reg})^(-etaX_p) + (phiX_@{subsec}_@{reg}_p==0)*0;
            [name = 'sector region specific export demand']
            (lhsExportDemandSubsec_8_@{reg}_@{subsec}+1) / (rhsExportDemandSubsec_8_@{reg}_@{subsec}+1) = 1;

            #lhsOutputMarketClearing_@{subsec}_@{reg} = Q_@{subsec}_@{reg};
            #rhsOutputMarketClearing_@{subsec}_@{reg} =
                X_@{subsec}_@{reg}
                @# for regm in 1:Regions
                    + Q_D_@{subsec}_@{regm}_@{reg}
                @# endfor
            ;
            [name = 'sector region specific output market clearing @{subsec} @{reg}']
            (lhsOutputMarketClearing_@{subsec}_@{reg} + 1) / (rhsOutputMarketClearing_@{subsec}_@{reg} + 1) = 1;

            // Emissions and emission intensities.
            #lhsSubsectorEmissions_@{subsec}_@{reg} = E_@{subsec}_@{reg};
            #rhsSubsectorEmissions_@{subsec}_@{reg} =
                kappaE_@{subsec}_@{reg} * Q_@{subsec}_@{reg};
            [name = 'regional subsector emissions @{subsec} @{reg}']
            (lhsSubsectorEmissions_@{subsec}_@{reg} + 1) / (rhsSubsectorEmissions_@{subsec}_@{reg} + 1) = 1;

            #lhsSubsectorEmissionsNOETS_@{subsec}_@{reg} = E_NOETS_@{subsec}_@{reg};
            #rhsSubsectorEmissionsNOETS_@{subsec}_@{reg} =
                kappaE_NOETS_@{subsec}_@{reg} * Q_@{subsec}_@{reg};
            [name = 'regional subsector emissions not covered by ETS @{subsec} @{reg}']
            (lhsSubsectorEmissionsNOETS_@{subsec}_@{reg} + 1) / (rhsSubsectorEmissionsNOETS_@{subsec}_@{reg} + 1) = 1;

            #lhsSubsectorEmissionIntensity_@{subsec}_@{reg} =
                lEndogenousY_p * kappaE_@{subsec}_@{reg}
                + (1 - lEndogenousY_p) * E_@{subsec}_@{reg};
            #rhsSubsectorEmissionIntensity_@{subsec}_@{reg} =
                lEndogenousY_p * (kappaE_@{subsec}_@{reg}_p + exo_kappaE_@{subsec}_@{reg})
                + (1 - lEndogenousY_p) * exp(exo_E_@{subsec}_@{reg}) * E0_@{reg}_p * sE_@{subsec}_@{reg}_p;
            [name = 'regional subsector emission intensity @{subsec} @{reg}']
            lhsSubsectorEmissionIntensity_@{subsec}_@{reg} = rhsSubsectorEmissionIntensity_@{subsec}_@{reg};

            #targetKappaENOETS_@{subsec}_@{reg} =
                exp(exo_E_NOETS_@{subsec}_@{reg})
                * E0_NOETS_@{reg}_p
                * sE_NOETS_@{subsec}_@{reg}_p
                / (Q_@{subsec}_@{reg} + 1e-12);
            #lhsSubsectorEmissionIntensityNOETS_@{subsec}_@{reg} =
                lEndogenousY_p * kappaE_NOETS_@{subsec}_@{reg}
                + (1 - lEndogenousY_p) * E_NOETS_@{subsec}_@{reg};
            #rhsSubsectorEmissionIntensityNOETS_@{subsec}_@{reg} =
                lEndogenousY_p
                * (
                    (1 - exo_lE_NOETS_Target_@{subsec}_@{reg})
                    * (kappaE_NOETS_@{subsec}_@{reg}_p + exo_kappaE_NOETS_@{subsec}_@{reg})
                    + exo_lE_NOETS_Target_@{subsec}_@{reg} * targetKappaENOETS_@{subsec}_@{reg}
                )
                + (1 - lEndogenousY_p)
                * exp(exo_E_NOETS_@{subsec}_@{reg})
                * E0_NOETS_@{reg}_p
                * sE_NOETS_@{subsec}_@{reg}_p;
            [name = 'regional subsector emission intensity not covered by ETS @{subsec} @{reg}']
            lhsSubsectorEmissionIntensityNOETS_@{subsec}_@{reg} = rhsSubsectorEmissionIntensityNOETS_@{subsec}_@{reg};

        @# endfor
    @# endfor
@# endfor

