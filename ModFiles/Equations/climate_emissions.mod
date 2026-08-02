// ==========================================
// Block 12: Climate Variables and Emissions
// ==========================================

@# for reg in 1:Regions
    // Regional climate variables.
    @# for z in ClimateVarsRegional
        #lhsRegionalClimate_@{z}_@{reg} = @{z}_@{reg};
        #rhsRegionalClimate_@{z}_@{reg} = @{z}0_@{reg}_p + exo_@{z}_@{reg};
        [name = '@{z} @{reg}']
        lhsRegionalClimate_@{z}_@{reg} = rhsRegionalClimate_@{z}_@{reg};
    @# endfor

    // Direct regional emissions plus emissions from intermediate input use.
    #lhsRegionalEmissions_@{reg} = E_@{reg};
    #rhsRegionalEmissions_@{reg} =
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + E_@{subsec}_@{reg}
                @# for secm in 1:Sectors
                    + E_I_@{subsec}_@{reg}_@{secm}
                @# endfor
            @# endfor
        @# endfor
    ;
    [name = 'regional emissions @{reg}']
    (lhsRegionalEmissions_@{reg} + 1) / (rhsRegionalEmissions_@{reg} + 1) = 1;

    // Regional emissions outside the ETS perimeter.
    #lhsRegionalEmissionsNOETS_@{reg} = E_NOETS_@{reg};
    #rhsRegionalEmissionsNOETS_@{reg} =
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + E_NOETS_@{subsec}_@{reg}
            @# endfor
        @# endfor
    ;
    [name = 'regional emissions not covered by ETS @{reg}']
    (lhsRegionalEmissionsNOETS_@{reg} + 1) / (rhsRegionalEmissionsNOETS_@{reg} + 1) = 1;

    // ETS emissions currently track total regional emissions.
    #lhsRegionalEmissionsETS_@{reg} = E_ETS_@{reg};
    #rhsRegionalEmissionsETS_@{reg} = E_@{reg};
    [name = 'regional emissions covered by ETS @{reg}']
    (lhsRegionalEmissionsETS_@{reg} + 1) / (rhsRegionalEmissionsETS_@{reg} + 1) = 1;

    // Regional capital subsidies, excluding the fossil subsector.
    #lhsRegionalSubsidies_@{reg} =
        tauS_@{reg} * (
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + K_@{subsec}_@{reg}(-1) * P_K_@{subsec}_@{reg} * r_F_@{subsec}_@{reg} * (@{subsec} != iSubsecFossil_p)
            @# endfor
        @# endfor
        );
    #rhsRegionalSubsidies_@{reg} = exo_tauS_@{reg} * PE_@{reg} * E_@{reg};
    [name = 'regional subsidies @{reg}']
    (lhsRegionalSubsidies_@{reg} + 1) / (rhsRegionalSubsidies_@{reg} + 1) = 1;

    @# if CapandTrade == 1
        // Cap-and-trade regime: pin emissions to the exogenous cap path.
        #lhsRegionalEmissionPolicy_@{reg} =
            E_@{reg}
            + (exo_PE_@{reg} + exo_PE + exo_CapTradeInternat + exo_CapTrade_@{reg}) * phiG_p;
        #rhsRegionalEmissionPolicy_@{reg} =
            E0_@{reg}_p * exp(exo_EBase_@{reg} + exo_E_@{reg});
    @# else
        // Exogenous-price regime: pin the regional emissions price.
        #lhsRegionalEmissionPolicy_@{reg} =
            PE_@{reg}
            + (exo_EBase_@{reg} + exo_E_@{reg} + exo_CapTradeInternat + exo_CapTrade_@{reg}) * phiG_p;
        #rhsRegionalEmissionPolicy_@{reg} = PE0_@{reg}_p + exo_PE_@{reg} + exo_PE;
    @# endif

    [name = 'regional price of emissions/emission cap @{reg}']
    (lhsRegionalEmissionPolicy_@{reg} + 1) / (rhsRegionalEmissionPolicy_@{reg} + 1) = 1;

    // Energy efficiency is endogenous when final output is endogenous; otherwise fossil output follows its exogenous path.
    #lhsRegionalEnergyEfficiency_@{reg} =
        EE_@{reg} * (lEndogenousY_p == 1)
        + Q_@{SubsecFossil}_@{reg} * (lEndogenousY_p == 0);
    #rhsRegionalEnergyEfficiency_@{reg} =
        exp(exo_EE_@{reg}) * (lEndogenousY_p == 1)
        + Q0_@{SubsecFossil}_@{reg}_p * exp(exo_Q_@{SubsecFossil}_@{reg}) * (lEndogenousY_p == 0);

    [name = 'regional energy efficiency @{reg}']
    (lhsRegionalEnergyEfficiency_@{reg} + 1) / (rhsRegionalEnergyEfficiency_@{reg} + 1) = 1;
@# endfor

// National climate variables.
@# for z in ClimateVarsNational
    #lhsNationalClimate_@{z} = @{z};
    #rhsNationalClimate_@{z} = @{z}0_p + exo_@{z};
    [name = '@{z}']
    (lhsNationalClimate_@{z} + 1) / (rhsNationalClimate_@{z} + 1) = 1;
@# endfor

// Aggregate emissions and national price/cap closure.
#lhsAggregateEmissions = E;
#rhsAggregateEmissions =
    @# for reg in 1:Regions
        + E_@{reg}
    @# endfor
;
[name = 'aggregate emissions']
(lhsAggregateEmissions + 1) / (rhsAggregateEmissions + 1) = 1;

#lhsAggregateEmissionPolicy =
    E * exo_CapTradeInternat
    + PE * (1 - exo_CapTradeInternat);
#rhsAggregateEmissionPolicy =
    E0_p * exp(exo_E) * exo_CapTradeInternat
    + PE0_p * (1 - exo_CapTradeInternat);
[name = 'price of emissions/emission cap']
(lhsAggregateEmissionPolicy + 1) / (rhsAggregateEmissionPolicy + 1) = 1;

