// ==========================================
// Investment Wedge & FDI Capital
// ==========================================
// Included from DGE_Model_Equations.mod via @#include (no loops of its own).
//
// Exogenous switches (shocks; SS value = 0 in all cases):
//   exo_ltargetIY_@{subsec}_@{reg}  — 1 = muI endogenous (I/Y targeting); 0 = muI exogenous
//   exo_targetIY_@{subsec}_@{reg}   — I/Y target path (active when ltargetIY = 1)
//   exo_muI_@{subsec}_@{reg}        — baseline muI path pre-loaded for scenarios (ltargetIY = 0)
//   exo_lFDIShare_@{subsec}_@{reg}  — 1 = K_FDI/K share mode; 0 = exo_I_FDI level mode
//   exo_sFDIShare_@{subsec}_@{reg}  — additive deviation to baseline K_FDI/K share (active when lFDIShare = 1)
//   exo_I_FDI_@{subsec}_@{reg}      — exogenous FDI flow scaled by Y0_p (active when lFDIShare = 0)
//
// ---- muI shadow value ----------------------------------------------------------
// Smooth blended switch (no recompilation needed):
//   ltargetIY = 1: muI endogenous; adjusts the capital user cost until
//                  (I_priv + I_pub) * P_INV / (Y_reg * P_reg) = exo_targetIY
//   ltargetIY = 0: muI = exo_muI (exogenous, pre-loaded from baseline path)
//   SS: exo_ltargetIY = 0, exo_targetIY = 0, muI_SS = exo_muI_SS = 0
//
// ---- K_FDI ---------------------------------------------------------------------
// K_FDI is foreign-owned capital; its rental return r_FDI flows abroad via the B (NFA) LOM.
// K_ = K_H_ + K_G_ + K_FDI_  (capital aggregation in firms.mod). K_FDI_SS = 0.
//
// K_FDI LOM:
//   K_FDI/PoP = (1−delta)*K_FDI(-1)/PoP(-1) + I_FDI/PoP
//
// I_FDI target (blended switch):
//   lFDIShare = 0: P_INV * I_FDI = exo_I_FDI * Y0_p   (exogenous FDI level)
//   lFDIShare = 1: K_FDI/K target with sFDI_eff = clamp(sFDI0 + exo_sFDIShare)
//                   and I_FDI implied by the K_FDI law of motion.

@# for reg in 1:Regions
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]

            // --- muI shadow value ---
            # lhs_muI_@{subsec}_@{reg} = exo_ltargetIY_@{subsec}_@{reg}
                                          * (I_@{subsec}_@{reg} + I_G_@{subsec}_@{reg})
                                          * P_INV_@{subsec}_@{reg} / (Y_@{reg} * P_@{reg})
                                        + (1 - exo_ltargetIY_@{subsec}_@{reg}) * muI_@{subsec}_@{reg};
            # rhs_muI_@{subsec}_@{reg} = exo_ltargetIY_@{subsec}_@{reg} * exo_targetIY_@{subsec}_@{reg}
                                        + (1 - exo_ltargetIY_@{subsec}_@{reg}) * exo_muI_@{subsec}_@{reg};
            [name = 'Investment-to-GDP wedge @{subsec} @{reg}']
            (lhs_muI_@{subsec}_@{reg} + 1) / (rhs_muI_@{subsec}_@{reg} + 1) = 1;

            // --- K_FDI law of motion ---
            # lhs_K_FDI_@{subsec}_@{reg} = K_FDI_@{subsec}_@{reg} / PoP_@{reg};
            # rhs_K_FDI_@{subsec}_@{reg} = (1 - delta_@{subsec}_@{reg}) * K_FDI_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1)
                                          + I_FDI_@{subsec}_@{reg} / PoP_@{reg};
            [name = 'K_FDI LOM @{subsec} @{reg}']
            (lhs_K_FDI_@{subsec}_@{reg} + 1) / (rhs_K_FDI_@{subsec}_@{reg} + 1) = 1;

            // --- I_FDI target ---
            // In share mode, target K_FDI as a share of total K and back out I_FDI from the K_FDI LOM.
            # sFDI_eff_@{subsec}_@{reg} = exo_sFDIShare_@{subsec}_@{reg};
            # lhs_I_FDI_@{subsec}_@{reg} = (1-exo_lFDIShare_@{subsec}_@{reg}) * I_FDI_@{subsec}_@{reg} * P_INV_@{subsec}_@{reg} + (exo_lFDIShare_@{subsec}_@{reg}) * I_FDI_@{subsec}_@{reg};
            # rhs_I_FDI_@{subsec}_@{reg} = (1-exo_lFDIShare_@{subsec}_@{reg}) * (phiFDI0_@{subsec}_@{reg}_p *(1-exo_I_FDI_@{subsec}_@{reg})) * Y0_p
                                                                        + (exo_lFDIShare_@{subsec}_@{reg}) * sFDI_eff_@{subsec}_@{reg} / (1-phiG_@{subsec}_@{reg}_p) * (I_@{subsec}_@{reg});
            [name = 'I-FDI target @{subsec} @{reg}']
            (lhs_I_FDI_@{subsec}_@{reg} + 1) / (rhs_I_FDI_@{subsec}_@{reg} + 1) = 1;

        @# endfor
    @# endfor
@# endfor
