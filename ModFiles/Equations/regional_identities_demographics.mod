// ==========================================
// Block 3: Regional Identities
// Block 4: Demographics
// ==========================================

// Pre-compute wage-competitiveness index WDiff for every region before the
// main loop, because the labour-force equation for each region needs WDiff
// of ALL other regions in the denominator.
// WDiff is the (back-weighted) geometric-average relative wage W_reg / W.
@# for reg in 1:Regions
    #WDiff_@{reg} = exp(
    @# for j in 1:TAdjust
        + @{j} / ((@{TAdjust} + 1) * @{TAdjust} / 2) * log(W_@{reg}(-@{j}) / W(-@{j}))
    @# endfor
    );
@# endfor

@# for reg in 1:Regions

    // ------------------------------------------------------------------
    // Wages and prices
    // ------------------------------------------------------------------

    // Regional employment-weighted wage index.
    #lhsRegWageIndex_@{reg} = W_@{reg};
    #rhsRegWageIndex_@{reg} =
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            + N_@{subsec}_@{reg} / N_@{reg} * W_@{subsec}_@{reg}
        @# endfor
    @# endfor
    ;
    [name = 'regional wage index @{reg}']
    (1 + lhsRegWageIndex_@{reg}) / (1 + rhsRegWageIndex_@{reg}) = 1;

    // Regional domestic price (exogenous or calibrated).
    #lhsRegDomPrice_@{reg} = P_D_@{reg};
    #rhsRegDomPrice_@{reg} = P0_D_@{reg}_p * exp(exo_P_D_@{reg});
    [name = 'regional domestic price @{reg}']
    (lhsRegDomPrice_@{reg} + 1) / (rhsRegDomPrice_@{reg} + 1) = 1;

    // CES price index for imported final consumption goods.
    #lhsImportPriceIndex_@{reg} = P_F_@{reg} * M_F_@{reg}^0;
    #rhsImportPriceIndex_@{reg} = (
        @# for sec in 1:Sectors
            + omegaMA_F_@{sec}_@{reg}_p * P_M_A_@{sec}_@{reg}^(1 - etaQ_p)
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + P_M_@{subsec} * M_F_@{subsec}_@{reg} * 0
            @# endfor
        @# endfor
    )^(1 / (1 - etaQ_p));
    [name = 'import price index @{reg}']
    (lhsImportPriceIndex_@{reg} + 1) / (rhsImportPriceIndex_@{reg} + 1) = 1;

    // Regional consumer price level: CES composite of domestic and import prices.
    #lhsRegPriceLevel_@{reg} = P_@{reg};
    #rhsRegPriceLevel_@{reg} = (omegaF_@{reg}_p * P_F_@{reg}^(1 - etaF_p)
        + (1 - omegaF_@{reg}_p) * P_D_@{reg}^(1 - etaF_p))^(1 / (1 - etaF_p));
    [name = 'regional consumer price level @{reg}']
    (lhsRegPriceLevel_@{reg} + 1) / (rhsRegPriceLevel_@{reg} + 1) = 1;

    // ------------------------------------------------------------------
    // Trade
    // ------------------------------------------------------------------

    // Aggregate regional import demand.
    #lhsRegImports_@{reg} = M_@{reg};
    #rhsRegImports_@{reg} =
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            + P_M_@{subsec} * (M_I_@{subsec}_@{reg} + M_F_@{subsec}_@{reg})
        @# endfor
    @# endfor
    ;
    [name = 'regional import demand @{reg}']
    (lhsRegImports_@{reg} + 1) / (rhsRegImports_@{reg} + 1) = 1;

    // CES export price index (weights D_X allow sector-specific export shares).
    #lhsExportPriceIndex_@{reg} = P_Q_@{reg};
    #rhsExportPriceIndex_@{reg} = (
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + D_X_@{subsec}_@{reg}_p * exp(exo_X_@{subsec}_@{reg}) * P_Q_@{subsec}_@{reg}^(1 - etaX_p)
            @# endfor
        @# endfor
    )^(1 / (1 - etaX_p));
    [name = 'regional export price index @{reg}']
    (1 + lhsExportPriceIndex_@{reg}) / (1 + rhsExportPriceIndex_@{reg}) = 1;

    // Nominal exchange rate: AR(1) around steady-state level by default
    // (exo_lNXTarget_@{reg}=0, pre-defined path — used for every scenario
    // other than Baseline). When exo_lNXTarget_@{reg}=1 (Baseline), s_@{reg}
    // instead becomes the variable that clears so net exports match the
    // target ratio NX0_@{reg}_p / Y0_@{reg}_p + exo_NX_@{reg}.
    #lhsExchangeRate_@{reg} =
        s_@{reg} * (exo_lNXTarget_@{reg} == 0)
        + NX_@{reg} / Y_@{reg} * (exo_lNXTarget_@{reg} == 1);
    #rhsExchangeRate_@{reg} =
        (rhos_p * s_@{reg}(-1) + (1 - rhos_p) * s0_@{reg}_p * exp(exo_s_@{reg})) * (exo_lNXTarget_@{reg} == 0)
        + (NX0_@{reg}_p / Y0_@{reg}_p + exo_NX_@{reg}) * (exo_lNXTarget_@{reg} == 1);
    [name = 'regional exchange rate / net export target @{reg}']
    (1 + lhsExchangeRate_@{reg}) / (1 + rhsExchangeRate_@{reg}) = 1;

    // Regional net exports.
    #lhsRegNetExports_@{reg} = NX_@{reg};
    #rhsRegNetExports_@{reg} = X_@{reg} * P_Q_@{reg} - M_@{reg};
    [name = 'regional net exports @{reg}']
    (lhsRegNetExports_@{reg}) = (rhsRegNetExports_@{reg});

    // ------------------------------------------------------------------
    // Real aggregates
    // ------------------------------------------------------------------

    // Nominal regional output: sum of subsector outputs at producer prices.
    #lhsRegOutput_@{reg} = Q_@{reg};
    #rhsRegOutput_@{reg} =
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + P_Q_@{subsec}_@{reg} * Q_@{subsec}_@{reg}
            @# endfor
        @# endfor
    ;
    [name = 'regional nominal output @{reg}']
    (1 + lhsRegOutput_@{reg}) / (1 + rhsRegOutput_@{reg}) = 1;

    // Nominal regional intermediate input demand.
    #lhsRegIntermedInput_@{reg} = Q_I_@{reg};
    #rhsRegIntermedInput_@{reg} =
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + P_I_@{subsec}_@{reg} * Q_I_@{subsec}_@{reg}
            @# endfor
        @# endfor
    ;
    [name = 'regional intermediate input demand @{reg}']
    (1 + lhsRegIntermedInput_@{reg}) / (1 + rhsRegIntermedInput_@{reg}) = 1;

    // Regional GVA: sum of sectoral value added at sectoral prices.
    #lhsRegGVA_@{reg} = Y_@{reg};
    #rhsRegGVA_@{reg} =
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + P_@{subsec}_@{reg} * Y_@{subsec}_@{reg}
            @# endfor
        @# endfor
    ;
    [name = 'regional gross value added @{reg}']
    (lhsRegGVA_@{reg} + 1) / (rhsRegGVA_@{reg} + 1) = 1;

    // Regional aggregate investment (private: household + FDI, at replacement cost).
    #lhsRegInvestment_@{reg} = I_@{reg};
    #rhsRegInvestment_@{reg} =
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            + (max(0, I_H_@{subsec}_@{reg}) + max(0, I_FDI_@{subsec}_@{reg})) * P_INV_@{subsec}_@{reg} / P_@{reg}
        @# endfor
    @# endfor
    ;
    [name = 'regional aggregate investment @{reg}']
    (lhsRegInvestment_@{reg} + 1) / (rhsRegInvestment_@{reg} + 1) = 1;

    // Regional total employment: sum of subsector hours.
    #lhsRegEmployment_@{reg} = N_@{reg};
    #rhsRegEmployment_@{reg} =
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + N_@{subsec}_@{reg}
            @# endfor
        @# endfor
    ;
    [name = 'regional total employment @{reg}']
    (lhsRegEmployment_@{reg} + 1) / (rhsRegEmployment_@{reg} + 1) = 1;

    // ------------------------------------------------------------------
    // Demographics
    // ------------------------------------------------------------------

    // Regional labour force: exogenous growth or migration equilibrium (lEndoMig == 1).
    // When lEndoMig == 1, workers allocate across regions according to WDiff (wage gravity).
    #lhsRegLabourForce_@{reg} = LF_@{reg};
    #rhsRegLabourForce_@{reg} =
        (lEndoMig_p == 0) * LF0_@{reg}_p * exp(exo_LF_@{reg})
        + (lEndoMig_p == 1) * (omegaLF0_@{reg}_p * exp(exo_LF_@{reg}) * WDiff_@{reg}^(etaLF_p))
            / (
            @# for regm in 1:Regions
                + omegaLF0_@{regm}_p * exp(exo_LF_@{regm}) * WDiff_@{regm}^(etaLF_p)
            @# endfor
            ) * (
            @# for regm in 1:Regions
                + LF0_@{regm}_p * exp(exo_LF_@{regm})
            @# endfor
            );
    [name = 'regional labour force @{reg}']
    (1 + lhsRegLabourForce_@{reg}) / (1 + rhsRegLabourForce_@{reg}) = 1;

    // Regional population: labour force plus non-participants, growing exogenously.
    #lhsRegPopulation_@{reg} = PoP_@{reg};
    #rhsRegPopulation_@{reg} = LF_@{reg} + (PoP0_@{reg}_p - LF0_@{reg}_p) * exp(exo_NLF_@{reg});
    [name = 'regional population @{reg}']
    (1 + lhsRegPopulation_@{reg}) / (1 + rhsRegPopulation_@{reg}) = 1;

@# endfor
