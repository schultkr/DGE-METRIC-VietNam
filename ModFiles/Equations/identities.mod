// ==========================================
// Block 2: National Identities
// ==========================================

// ------------------------------------------------------------------
// Labour and population aggregates
// ------------------------------------------------------------------

#lhsPopulation =
    @# for reg in 1:Regions
        + PoP_@{reg}
    @# endfor
    ;
[name = 'aggregate population']
(1 + PoP) / (1 + lhsPopulation) = 1;

#lhsLabourForce =
    @# for reg in 1:Regions
        + LF_@{reg}
    @# endfor
    ;
[name = 'aggregate labour force']
(1 + LF) / (1 + lhsLabourForce) = 1;

// Employment-weighted average wage across all sectors and regions.
#lhsWageIndex =
    @# for reg in 1:Regions
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + N_@{subsec}_@{reg} * LF_@{reg} / (LF * N) * W_@{subsec}_@{reg}
            @# endfor
        @# endfor
    @# endfor
    ;
[name = 'aggregate wage index']
(1 + W) / (1 + lhsWageIndex) = 1;

// Total employment (hours) summed across regions and weighted by labour force.
#lhsTotalEmployment =
    @# for reg in 1:Regions
        + N_@{reg} * LF_@{reg}
    @# endfor
    ;
[name = 'aggregate employment']
(1 + N * LF) / (1 + lhsTotalEmployment) = 1;

// ------------------------------------------------------------------
// National accounts aggregates
// ------------------------------------------------------------------

#lhsNatGVA =
    @# for reg in 1:Regions
        + Y_@{reg}
    @# endfor
    ;
[name = 'aggregate gross value added']
(1 + Y) / (1 + lhsNatGVA) = 1;

#lhsNatOutput =
    @# for reg in 1:Regions
        + Q_@{reg}
    @# endfor
    ;
[name = 'aggregate output']
(1 + Q) / (1 + lhsNatOutput) = 1;

#lhsNatIntermediateInput =
    @# for reg in 1:Regions
        + Q_I_@{reg}
    @# endfor
    ;
[name = 'aggregate intermediate input']
(1 + Q_I) / (1 + lhsNatIntermediateInput) = 1;

// Total domestic absorption valued at domestic prices.
#lhsNatFinalDemand =
    @# for reg in 1:Regions
        + Q_U_@{reg} * P_D_@{reg}
    @# endfor
    ;
[name = 'aggregate final demand']
(1 + Q_U) / (1 + lhsNatFinalDemand) = 1;

#lhsNatConsumption =
    @# for reg in 1:Regions
        + C_@{reg} * P_@{reg}
    @# endfor
    ;
[name = 'aggregate consumption']
(1 + C) / (1 + lhsNatConsumption) = 1;

// National government consumption: sum of regional G valued at regional prices.
#lhsNatGovConsumption =
    @# for reg in 1:Regions
        + G_@{reg} * P_@{reg}
    @# endfor
    ;
[name = 'aggregate government consumption']
(1 + G) / (1 + lhsNatGovConsumption) = 1;

// National investment: max(0,.) guards against numerical undershoots at zero.
#lhsNatInvestment =
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            @# for reg in 1:Regions
                + max(0, I_@{subsec}_@{reg} * P_INV_@{subsec}_@{reg})
            @# endfor
        @# endfor
    @# endfor
    ;
[name = 'aggregate investment']
(1 + I) / (1 + lhsNatInvestment) = 1;

// ------------------------------------------------------------------
// External trade aggregates
// ------------------------------------------------------------------

#lhsNatExports =
    @# for reg in 1:Regions
        + X_@{reg} * P_Q_@{reg}
    @# endfor
    ;
[name = 'aggregate exports']
(1 + X) / (1 + lhsNatExports) = 1;

#lhsNatImports =
    @# for reg in 1:Regions
        + M_@{reg}
    @# endfor
    ;
[name = 'aggregate imports']
(1 + M) / (1 + lhsNatImports) = 1;

[name = 'aggregate net exports']
(1 + NX) = (1 + X - M);

// National net foreign assets: forward positions summed across regions.
#lhsNetForeignAssets =
    @# for reg in 1:Regions
        + B_@{reg}EXP
    @# endfor
    ;
[name = 'aggregate net foreign asset position']
(1 + B) = (1 + lhsNetForeignAssets);
