// ==========================================
// Block 12: Climate Variables and Emissions
// ==========================================
@# for reg in 1:Regions
    @# for z in ClimateVarsRegional
        #lhsClim_@{z}_@{reg} = @{z}_@{reg};
        #rhsClim_@{z}_@{reg} = @{z}0_@{reg}_p + exo_@{z}_@{reg};
        [name = '@{z}']
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
    [name = 'regional emissions']
    (lhsAggReg_@{reg}_25+1)/(rhsAggReg_@{reg}_25+1) = 1;

    #lhsAggReg_@{reg}_25_NOETS = E_NOETS_@{reg};
    #rhsAggReg_@{reg}_25_NOETS = 
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + E_NOETS_@{subsec}_@{reg}
            @# endfor
        @# endfor
    ;
    [name = 'regional emissions not covered by ETS']
    (lhsAggReg_@{reg}_25_NOETS+1)/(rhsAggReg_@{reg}_25_NOETS+1) = 1;

    #lhsAggReg_@{reg}_25_ETS = E_ETS_@{reg};
    #rhsAggReg_@{reg}_25_ETS = E_@{reg};
    [name = 'regional emissions covered by ETS']
    (lhsAggReg_@{reg}_25_ETS+1)/(rhsAggReg_@{reg}_25_ETS+1) = 1;

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
    [name = 'regional susbsidies']
    (1+lhsSubsidies_@{reg})/(1 + rhsSubsidies_@{reg}) = 1;
    @# if CapandTrade == 1
        #lhsEmissionPrice_@{reg} = E_@{reg} + (exo_PE_@{reg} + exo_PE+exo_CapTradeInternat+exo_CapTrade_@{reg})*phiG_p;
        #rhsEmissionPrice_@{reg} = E0_@{reg}_p * exp(exo_EBase_@{reg} + exo_E_@{reg});   
    @# else
        #lhsEmissionPrice_@{reg} = PE_@{reg}+(exo_EBase_@{reg} + exo_E_@{reg}+exo_CapTradeInternat+exo_CapTrade_@{reg})*phiG_p;
        #rhsEmissionPrice_@{reg} = PE0_@{reg}_p + exo_PE_@{reg} + exo_PE;
    @# endif


    [name = 'regional price of emissions/emission cap']
    (1+lhsEmissionPrice_@{reg})/(1 + rhsEmissionPrice_@{reg}) = 1;

    #lhsEnergyEfficiency_@{reg} = EE_@{reg}*(lEndogenousY_p==1) + Q_@{SubsecFossil}_@{reg}*(lEndogenousY_p==0);
    #rhsEnergyEfficiency_@{reg} = exp(exo_EE_@{reg})*(lEndogenousY_p==1) + Q0_@{SubsecFossil}_@{reg}_p*exp(exo_Q_@{SubsecFossil}_@{reg})*(lEndogenousY_p==0);


    [name = 'regional energy efficiency']
    (1+lhsEnergyEfficiency_@{reg})/(1 + rhsEnergyEfficiency_@{reg}) = 1;

@# endfor

@# for z in ClimateVarsNational
    #lhsClim_@{z} = @{z};
    #rhsClim_@{z} = @{z}0_p + exo_@{z};
    [name = '@{z}']
    (1+lhsClim_@{z})/(1 + rhsClim_@{z}) = 1;
@# endfor

#lhsEmissions = E;
#rhsEmissions = 
        @# for reg in 1:Regions
            + E_@{reg}
        @# endfor
;
[name = 'aggregate emissions']
(1+lhsEmissions)/(1 + rhsEmissions) = 1;

#lhsEmissionPrice = E*exo_CapTradeInternat + PE*(1-exo_CapTradeInternat);
#rhsEmissionPrice = E0_p * exp(exo_E)*exo_CapTradeInternat + (PE0_p)*(1-exo_CapTradeInternat);
[name = 'price of emissions/emission cap']
(1+lhsEmissionPrice)/(1 + rhsEmissionPrice) = 1;

