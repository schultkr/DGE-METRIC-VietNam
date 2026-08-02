// ==========================================
// Block 12: Climate Variables and Emissions
// ==========================================
@# for reg in 1:Regions
    @# for z in ClimateVarsRegional
        #lhsClim_@{z}_@{reg} = @{z}_@{reg};
        #rhsClim_@{z}_@{reg} = @{z}0_@{reg}_p + exo_@{z}_@{reg};
        [name = '@{z} @{reg}']
        lhsClim_@{z}_@{reg} = rhsClim_@{z}_@{reg};
    @# endfor
    #lhsAggReg_@{reg}_25 = E_@{reg};
    #rhsAggReg_@{reg}_25 = 
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
    lhsAggReg_@{reg}_25 = rhsAggReg_@{reg}_25;

    #lhsAggReg_@{reg}_25_NOETS = E_NOETS_@{reg};
    #rhsAggReg_@{reg}_25_NOETS = 
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + E_NOETS_@{subsec}_@{reg}
            @# endfor
        @# endfor
    ;
    [name = 'regional emissions not covered by ETS @{reg}']
    lhsAggReg_@{reg}_25_NOETS = rhsAggReg_@{reg}_25_NOETS;

    #lhsAggReg_@{reg}_25_ETS = E_ETS_@{reg};
    #rhsAggReg_@{reg}_25_ETS = E_@{reg};
    [name = 'regional emissions covered by ETS @{reg}']
    lhsAggReg_@{reg}_25_ETS = rhsAggReg_@{reg}_25_ETS;

    #lhsSubsidies_@{reg} = tauS_@{reg} * 
     (
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                    + K_@{subsec}_@{reg}(-1) * P_K_@{subsec}_@{reg} * r_F_@{subsec}_@{reg} * (@{subsec}!=iSubsecFossil_p)
            @# endfor
        @# endfor
    )
    ;
    #rhsSubsidies_@{reg} = exo_tauS_@{reg} * PE_@{reg} * E_@{reg};
    [name = 'regional subsidies @{reg}']
    lhsSubsidies_@{reg} = rhsSubsidies_@{reg};
    @# if CapandTrade == 1
        #lhsEmissionPrice_@{reg} = E_@{reg} + (exo_PE_@{reg} + exo_PE+exo_CapTradeInternat+exo_CapTrade_@{reg})*phiG_p;
        #rhsEmissionPrice_@{reg} = E0_@{reg}_p * exp(exo_EBase_@{reg} + exo_E_@{reg});   
    @# else
        #lhsEmissionPrice_@{reg} = PE_@{reg}+(exo_EBase_@{reg} + exo_E_@{reg}+exo_CapTradeInternat+exo_CapTrade_@{reg})*phiG_p;
        #rhsEmissionPrice_@{reg} = PE0_@{reg}_p + exo_PE_@{reg} + exo_PE;
    @# endif


    [name = 'regional price of emissions/emission cap @{reg}']
    lhsEmissionPrice_@{reg} = rhsEmissionPrice_@{reg};

    #lhsEnergyEfficiency_@{reg} = EE_@{reg}*(lEndogenousY_p==1) + Q_@{SubsecFossil}_@{reg}*(lEndogenousY_p==0);
    #rhsEnergyEfficiency_@{reg} = exp(exo_EE_@{reg})*(lEndogenousY_p==1) + Q0_@{SubsecFossil}_@{reg}_p*exp(exo_Q_@{SubsecFossil}_@{reg})*(lEndogenousY_p==0);


    [name = 'regional energy efficiency @{reg}']
    lhsEnergyEfficiency_@{reg} = rhsEnergyEfficiency_@{reg};

@# endfor

@# for z in ClimateVarsNational
    #lhsClim_@{z} = @{z};
    #rhsClim_@{z} = @{z}0_p + exo_@{z};
    [name = '@{z}']
    lhsClim_@{z} = rhsClim_@{z};
@# endfor

#lhsEmissions = E;
#rhsEmissions = 
        @# for reg in 1:Regions
            + E_@{reg}
        @# endfor
;
[name = 'aggregate emissions']
lhsEmissions = rhsEmissions;

#lhsEmissionPrice = E*exo_CapTradeInternat + PE*(1-exo_CapTradeInternat);
#rhsEmissionPrice = E0_p * exp(exo_E)*exo_CapTradeInternat + (PE0_p)*(1-exo_CapTradeInternat);
[name = 'price of emissions/emission cap']
lhsEmissionPrice = rhsEmissionPrice;

