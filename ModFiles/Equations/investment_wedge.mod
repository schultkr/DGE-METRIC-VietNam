// ==========================================
// Investment-to-GDP wedge equation
// ==========================================
// Included from DGE_CRED_Model_Equations.mod (defines its own loops).
//
// The switch exo_ltargetIY_@{subsec}_@{reg} is an EXOGENOUS shock (default = 0).
// Because it is a shock (not a parameter), its SS value is always 0 — the wedge is
// therefore always exogenous at steady state: A_INV_SS = exo_A_INV_SS = 0.
//
// Modes (set via exo_ltargetIY in the simulation paths):
//
//   exo_ltargetIY = 1  (Baseline transition path):
//       A_INV_ is endogenous; it adjusts the capital user cost until I/Y_reg equals the target:
//           I_@{subsec}_@{reg} / Y_@{reg}  =  targetIY0_@{subsec}_@{reg}_p + exo_targetIY_@{subsec}_@{reg}
//       Y_@{reg} = price-weighted aggregate regional GDP in the model numeraire
//                  (sum of P_s*Y_s over subsectors)
//       targetIY0_p is calibrated to SS ratio → exo_targetIY = 0 at SS
//
//   exo_ltargetIY = 0  (SS and Scenarios):
//       A_INV_ is exogenous: A_INV_@{subsec}_@{reg} = exo_A_INV_@{subsec}_@{reg}
//       In scenarios, exo_A_INV_ is pre-loaded with the baseline A_INV_ path.
//
// Blended equation (smooth switching, no recompilation):
//   exo_ltargetIY * (I/Y_reg - targetIY0 - exo_targetIY)
//   + (1 - exo_ltargetIY) * (A_INV_ - exo_A_INV_) = 0

@# for reg in 1:Regions
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]

            [name = 'Investment-to-GDP wedge @{subsec} @{reg}']
            //exo_ltargetIY_@{subsec}_@{reg} * ((I_@{subsec}_@{reg}+I_G_@{subsec}_@{reg}) * P_INV_@{subsec}_@{reg} / (Y_@{reg} * P_@{reg})) + (1-exo_ltargetIY_@{subsec}_@{reg}) * A_INV_@{subsec}_@{reg} = exo_ltargetIY_@{subsec}_@{reg} * exo_targetIY_@{subsec}_@{reg} + (1-exo_ltargetIY_@{subsec}_@{reg}) * exo_A_INV_@{subsec}_@{reg};
            exo_ltargetIY_@{subsec}_@{reg} * (I_@{subsec}_@{reg}+I_G_@{subsec}_@{reg}) * P_INV_@{subsec}_@{reg} / (Y_@{reg} * P_@{reg}) + (1-exo_ltargetIY_@{subsec}_@{reg}) * A_INV_@{subsec}_@{reg} = exo_ltargetIY_@{subsec}_@{reg} * (exo_targetIY_@{subsec}_@{reg}) + (1-exo_ltargetIY_@{subsec}_@{reg}) * exo_A_INV_@{subsec}_@{reg};

        @# endfor
    @# endfor
@# endfor

// ==========================================
// FDI capital stock: LOM and K-targeting
// ==========================================
// K_FDI_@{subsec}_@{reg} is foreign-owned capital. Its rental return r_FDI_ flows
// abroad via the B (net foreign asset position) LOM. At steady state K_FDI_=0.
//
// K_H_ is purely domestic household capital (LOM = rawK, Euler FOC unchanged).
// K_ = K_H_ + K_G_ + K_FDI_  (firms.mod capital aggregation).
//
// Loop A — K_FDI_ law of motion (always active):
//   K_FDI_(t)/PoP = (1-delta)*K_FDI_(t-1)/PoP(-1) + I_FDI_(t)/PoP
//
// Loop B — K-target blended equation (flip-switch pattern, same as exo_ltargetIY):
//   exo_lKRGTarget = 0: I_FDI_ = 0  (no FDI; K_FDI_ depreciates to zero)
//   exo_lKRGTarget = 1: K_FDI_/PoP = max(0, K0*exp(exo_KRGTarget) - K_H_ - K_G_) / PoP
//                        K_FDI_ absorbs the gap; LOM determines I_FDI_ residually
//
// No singularity: K-target equation pins K_FDI_ (switch=1) or I_FDI_=0 (switch=0);
//   LOM pins I_FDI_ (switch=1) or K_FDI_ (switch=0); Euler FOC pins I_H_ always.

@# for reg in 1:Regions
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            # lhs_K_FDI_@{subsec}_@{reg} = K_FDI_@{subsec}_@{reg} / PoP_@{reg} + exo_lKRGTarget_@{subsec}_@{reg} * exo_KRGTarget_@{subsec}_@{reg};
            # rhs_K_FDI_@{subsec}_@{reg} = (1 - delta_@{subsec}_@{reg}) * K_FDI_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1) + I_FDI_@{subsec}_@{reg} / PoP_@{reg};
            [name = 'K_FDI LOM @{subsec} @{reg}']
            ( lhs_K_FDI_@{subsec}_@{reg} + 1 ) / ( rhs_K_FDI_@{subsec}_@{reg} + 1 ) = 1;

        @# endfor
    @# endfor
@# endfor

@# for reg in 1:Regions
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            // When lFDIShare=0: I_FDI is set by exo_I_FDI (existing behaviour).
            // When lFDIShare=1: I_FDI = sFDIShare × I (investment-flow targeting).
            //   K_FDI then evolves from the LOM (lhs_K_FDI) given I_FDI.
            # lhs_I_FDI_@{subsec}_@{reg} = P_INV_@{subsec}_@{reg} * I_FDI_@{subsec}_@{reg};
            # rhs_I_FDI_@{subsec}_@{reg} = (1 - exo_lFDIShare_@{subsec}_@{reg}) * exo_I_FDI_@{subsec}_@{reg} * Y0_p
                                          + exo_lFDIShare_@{subsec}_@{reg} * P_INV_@{subsec}_@{reg}
                                            * exo_sFDIShare_@{subsec}_@{reg} * I_@{subsec}_@{reg};
            [name = 'I-FDI target @{subsec} @{reg}']
            (lhs_I_FDI_@{subsec}_@{reg} + 1) / (rhs_I_FDI_@{subsec}_@{reg} + 1) = 1;

        @# endfor
    @# endfor
@# endfor
