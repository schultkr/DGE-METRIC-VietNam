// ============================================================
// Block 15: Exogenous Private Investment
//
// I_P_@{subsec}_@{reg} is a pure accounting flow driven by
// exo_I_P_@{subsec}_@{reg} (shock expressed as fraction of
// base-year output Y0_p, net of the base-period steady-state
// level phiKP0_@{subsec}_@{reg}_p).
//
// At exo_I_P = 0:  I_P = phiKP0 * Y0   (base-period level)
// Positive shock:  I_P rises above base level
// The variable enters the household resource constraint as
// an investment expenditure without generating productive output.
// ============================================================

@# for reg in 1:Regions
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            //#lhsIP_@{subsec}_@{reg} = exo_ltargetIY_@{subsec}_@{reg} * (I_@{subsec}_@{reg}) * P_INV_@{subsec}_@{reg} / (Y_@{reg} * P_@{reg}) + (1-exo_ltargetIY_@{subsec}_@{reg}) * I_P_@{subsec}_@{reg};
            //#rhsIP_@{subsec}_@{reg} = exo_ltargetIY_@{subsec}_@{reg} * (exo_targetIY_@{subsec}_@{reg}) + (1-exo_ltargetIY_@{subsec}_@{reg}) * (phiKP0_@{subsec}_@{reg}_p + exo_I_P_@{subsec}_@{reg}) * Y0_p;
            #lhsIP_@{subsec}_@{reg} = I_P_@{subsec}_@{reg};
            #rhsIP_@{subsec}_@{reg} = (phiKP0_@{subsec}_@{reg}_p + exo_I_P_@{subsec}_@{reg}) * Y0_p;
            [name = 'Exogenous private investment s=@{subsec} r=@{reg}']
            (1 + lhsIP_@{subsec}_@{reg}) / (1 + rhsIP_@{subsec}_@{reg}) = 1;
            #lhsKP_@{subsec}_@{reg} = K_P_@{subsec}_@{reg};
            #rhsKP_@{subsec}_@{reg} = (1-delta_@{subsec}_@{reg}) * K_P_@{subsec}_@{reg}(-1) + I_P_@{subsec}_@{reg};
            [name = 'Exogenous private capital s=@{subsec} r=@{reg}']
            (1 + lhsKP_@{subsec}_@{reg}) / (1 + rhsKP_@{subsec}_@{reg}) = 1;
        @# endfor
    @# endfor
@# endfor
