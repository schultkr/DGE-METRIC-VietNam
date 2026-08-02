// ==========================================
// Investment-to-GDP wedge equation (display version)
// ==========================================
// See ModFiles/Equations/investment_wedge.mod for full documentation.
// Display version uses assignment-style equations (no ratio form).
//
// exo_ltargetIY is a shock (default=0), so wedge is always exogenous at SS.

@# for reg in 1:Regions
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]

            [name = 'Investment-to-GDP wedge @{subsec} @{reg}']
            exo_ltargetIY_@{subsec}_@{reg} * (I_@{subsec}_@{reg}+I_G_@{subsec}_@{reg}) * P_INV_@{subsec}_@{reg} / (Y_@{reg} * P_@{reg})
            + (1 - exo_ltargetIY_@{subsec}_@{reg}) * muI_@{subsec}_@{reg}
            =
            exo_ltargetIY_@{subsec}_@{reg} * (exo_targetIY_@{subsec}_@{reg})
            + (1 - exo_ltargetIY_@{subsec}_@{reg}) * exo_muI_@{subsec}_@{reg};

        @# endfor
    @# endfor
@# endfor

// FDI capital LOM and K-target (display version)
@# for reg in 1:Regions
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]

            [name = 'K_FDI LOM @{subsec} @{reg}']
            K_FDI_@{subsec}_@{reg} / PoP_@{reg}
            = (1 - delta_@{subsec}_@{reg}) * K_FDI_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1)
            + I_FDI_@{subsec}_@{reg} / PoP_@{reg};

                        // When lFDIShare=0: I_FDI follows exo_I_FDI (existing behaviour).
                        // When lFDIShare=1: target K_FDI/K with sFDI_eff = clamp(sFDI0 + exo_sFDIShare)
                        // and infer I_FDI from the K_FDI LOM.
            [name = 'I-FDI target @{subsec} @{reg}']
            P_INV_@{subsec}_@{reg} * I_FDI_@{subsec}_@{reg}
            =
            (1 - exo_lFDIShare_@{subsec}_@{reg}) * exo_I_FDI_@{subsec}_@{reg} * Y0_p
                        + exo_lFDIShare_@{subsec}_@{reg} * P_INV_@{subsec}_@{reg}
                            * (min(1, max(0, sFDI0_@{subsec}_@{reg}_p + exo_sFDIShare_@{subsec}_@{reg})) * K_@{subsec}_@{reg}
                                 - (1 - delta_@{subsec}_@{reg}) * K_FDI_@{subsec}_@{reg}(-1) * PoP_@{reg} / PoP_@{reg}(-1));

        @# endfor
    @# endfor
@# endfor
