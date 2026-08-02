// ==========================================
// Block 10: Wholesalers
// ==========================================

@# for reg in 1:Regions
    @# for sec in 1:Sectors

        // ------------------------------------------------------------------
        // Sector-level aggregation
        // ------------------------------------------------------------------

        // CES exponent rho = (eta-1)/eta. The +(eta==1) term prevents rho==0
        // (which would make the CES exponent 1/rho blow up); safe because the
        // Cobb-Douglas branch is multiplied by (eta==1) and the CES branch by (eta!=1).
        #rhoQA_@{sec} = (etaQA_@{sec}_p - 1 + (etaQA_@{sec}_p == 1)) / etaQA_@{sec}_p;

        // Sector aggregate output Q_A: CES / Cobb-Douglas over subsector outputs.
        // max(1e-8,.) prevents log(0) in the Cobb-Douglas branch.
        #lhsSectorAggrOutput_@{reg}_@{sec} = Q_A_@{sec}_@{reg};
        #rhsSectorAggrOutput_@{reg}_@{sec} =
            (etaQA_@{sec}_p == 1) * exp(
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + omegaQ_@{subsec}_@{reg}_p * log(max(1e-8, Q_D_@{subsec}_@{reg}) * A_D_@{subsec}_@{reg})
            @# endfor
            )
            + (etaQA_@{sec}_p != 1) * (
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + omegaQ_@{subsec}_@{reg}_p^(1 / etaQA_@{sec}_p)
                    * (A_D_@{subsec}_@{reg} * max(1e-8, Q_D_@{subsec}_@{reg}))^(rhoQA_@{sec})
            @# endfor
            )^(1 / rhoQA_@{sec});
        [name = 'sector aggregate output @{sec} @{reg}']
        (lhsSectorAggrOutput_@{reg}_@{sec} + 1) / (rhsSectorAggrOutput_@{reg}_@{sec} + 1) = 1;

        // Sector market clearing: Q_A = final demand + intermediate demand + housing/PV.
        // The housing/PV term enters only for the designated housing sector (iSecHouse_p == sec).
        #lhsSectorMarketClearing_@{reg}_@{sec} = Q_A_@{sec}_@{reg};
        #rhsSectorMarketClearing_@{reg}_@{sec} = Q_A_F_@{sec}_@{reg} + Q_A_I_@{sec}_@{reg}
            + (iSecHouse_p == @{sec}) * (IH_@{reg} * PH_@{reg} + I_PV_@{reg}) / P_A_@{sec}_@{reg};
        [name = 'sector market clearing @{sec} @{reg}']
        (lhsSectorMarketClearing_@{reg}_@{sec} + 1) / (rhsSectorMarketClearing_@{reg}_@{sec} + 1) = 1;

        // Nominal intermediate demand for sector sec output: sum over all using subsectors.
        // The kappaEI term adds an energy-intensity carbon cost when a subsector draws on
        // fossil inputs (fossil share Q_D_fossil/Q_A_energy times the carbon price PE).
        #lhsSectorIntermedDemand_@{reg}_@{sec} = Q_A_I_@{sec}_@{reg} * P_A_@{sec}_@{reg};
        #rhsSectorIntermedDemand_@{reg}_@{sec} =
        @# for secm in 1:Sectors
            @# for subsec in Subsecstart[secm]:Subsecend[secm]
                + Q_I_@{subsec}_@{reg}_@{sec} * (P_A_@{sec}_@{reg}
                    + kappaEI_@{subsec}_@{reg}_@{sec}_p * exp(exo_EI_@{subsec}_@{reg}_@{sec})
                        * (Q_D_@{SubsecFossil}_@{reg} / Q_A_@{SecEnergy}_@{reg})
                        * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p)
            @# endfor
        @# endfor
        ;
        [name = 'sector intermediate demand @{sec} @{reg}']
        (lhsSectorIntermedDemand_@{reg}_@{sec} + 1) / (rhsSectorIntermedDemand_@{reg}_@{sec} + 1) = 1;

        // ------------------------------------------------------------------
        // Subsector demand allocation (Armington structure)
        // ------------------------------------------------------------------

        @# for subsec in Subsecstart[sec]:Subsecend[sec]

            // CES demand for output sourced from each supply region regm.
            @# for regm in 1:Regions
                #lhsRegionalSupplySource_@{reg}_@{subsec}_@{regm} = Q_D_@{subsec}_@{reg}_@{regm};
                #rhsRegionalSupplySource_@{reg}_@{subsec}_@{regm} =
                    omegaQ_@{subsec}_@{reg}_@{regm}_p
                    * (P_Q_@{subsec}_@{regm} / P_D_@{subsec}_@{reg})^(-etaQ_@{subsec}_p)
                    * Q_D_@{subsec}_@{reg};
                [name = 'demand for subsector output from region @{regm} @{subsec} @{reg}']
                (lhsRegionalSupplySource_@{reg}_@{subsec}_@{regm} + 1)
                    / (rhsRegionalSupplySource_@{reg}_@{subsec}_@{regm} + 1) = 1;
            @# endfor

            // CES demand for imported intermediates M_I (substitutable with regional supply).
            #lhsIntermedImports_@{reg}_@{subsec} = M_I_@{subsec}_@{reg};
            #rhsIntermedImports_@{reg}_@{subsec} =
                (omegaM_@{subsec}_@{reg}_p
                * (P_M_@{subsec} / P_D_@{subsec}_@{reg})^(-etaQ_@{subsec}_p)
                * Q_D_@{subsec}_@{reg});
            [name = 'intermediate import demand @{subsec} @{reg}']
            (lhsIntermedImports_@{reg}_@{subsec} + 1) / (rhsIntermedImports_@{reg}_@{subsec} + 1) = 1;

            // CES demand for imported final goods M_F (substitutable within import basket).
            #lhsFinalImports_@{reg}_@{subsec} = M_F_@{subsec}_@{reg};
            #rhsFinalImports_@{reg}_@{subsec} =
                (omegaM_F_@{subsec}_@{reg}_p
                * (P_M_@{subsec} / P_M_A_@{sec}_@{reg})^(-etaQA_@{sec}_p)
                * M_A_F_@{sec}_@{reg});
            [name = 'final import demand @{subsec} @{reg}']
            (lhsFinalImports_@{reg}_@{subsec} + 1) / (rhsFinalImports_@{reg}_@{subsec} + 1) = 1;

            // Aggregate supply available to region reg for subsector subsec:
            // CES aggregate over regional sources and imported intermediates.
            // Same zero-avoidance trick as rhoQA for the CES exponent.
            #lhsSubsecSupplyAggregate_@{reg}_@{subsec} = Q_D_@{subsec}_@{reg};
            #rhsSubsecSupplyAggregate_@{reg}_@{subsec} =
                (etaQ_@{subsec}_p == 1) * exp(
                @# for regm in 1:Regions
                    + omegaQ_@{subsec}_@{reg}_@{regm}_p * log(max(1e-8, Q_D_@{subsec}_@{reg}_@{regm}))
                @# endfor
                    + omegaM_@{subsec}_@{reg}_p * log(max(1e-8, M_I_@{subsec}_@{reg})))
                + (etaQ_@{subsec}_p != 1) * (
                @# for regm in 1:Regions
                    + omegaQ_@{subsec}_@{reg}_@{regm}_p^(1 / etaQ_@{subsec}_p)
                        * max(1e-8, Q_D_@{subsec}_@{reg}_@{regm})^((etaQ_@{subsec}_p - 1) / etaQ_@{subsec}_p)
                @# endfor
                    + omegaM_@{subsec}_@{reg}_p^(1 / etaQ_@{subsec}_p)
                        * max(1e-8, M_I_@{subsec}_@{reg})^((etaQ_@{subsec}_p - 1) / etaQ_@{subsec}_p)
                )^(etaQ_@{subsec}_p / (etaQ_@{subsec}_p - 1 + (etaQ_@{subsec}_p == 1)));
            [name = 'subsector supply aggregate @{subsec} @{reg}']
            (lhsSubsecSupplyAggregate_@{reg}_@{subsec} + 1)
                / (rhsSubsecSupplyAggregate_@{reg}_@{subsec} + 1) = 1;

            // CES demand allocation: share of sector aggregate Q_A directed to subsector.
            // Together with the supply aggregate above, this clears the subsector market.
            #lhsSubsecDemandAlloc_@{reg}_@{subsec} = Q_D_@{subsec}_@{reg};
            #rhsSubsecDemandAlloc_@{reg}_@{subsec} =
                omegaQ_@{subsec}_@{reg}_p * A_D_@{subsec}_@{reg}^(etaQA_@{sec}_p - 1)
                * (P_D_@{subsec}_@{reg} / P_A_@{sec}_@{reg})^(-etaQA_@{sec}_p)
                * Q_A_@{sec}_@{reg};
            [name = 'subsector demand allocation @{subsec} @{reg}']
            (lhsSubsecDemandAlloc_@{reg}_@{subsec} + 1)
                / (rhsSubsecDemandAlloc_@{reg}_@{subsec} + 1) = 1;

        @# endfor
    @# endfor
@# endfor
