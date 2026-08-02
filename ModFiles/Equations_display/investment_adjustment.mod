// ==========================================
// Investment Adjustment Costs & Capital LOM (display version)
// ==========================================
// Direct-equality form for readability / LaTeX export.
// See ModFiles/Equations/investment_adjustment.mod for ratio-form and full commentary.
// Included inside @# for reg / @# for subsec loops in Equations_display/households.mod.
//
// Macro variables @{reg} and @{subsec} are inherited from the caller.

# epsI_@{reg}_@{subsec} = 1e-3;

@# if lCapPrice == 1

    // P_K = sector output price (exo_P_K shifts the sector capital price)
    # lhs_PK_@{reg}_@{subsec} = P_K_@{subsec}_@{reg};
    # rhs_PK_@{reg}_@{subsec} = P_@{subsec}_@{reg} * exp(exo_P_K_@{subsec}_@{reg});
    [name = 'Rental price of capital @{subsec} @{reg}']
    lhs_PK_@{reg}_@{subsec} = rhs_PK_@{reg}_@{subsec};

    @# if lCapGoodsSecPrice == 1
        # PINV_base_@{reg}_@{subsec} = P0_@{subsec}_@{reg}_p;
    @# else
        # PINV_base_@{reg}_@{subsec} = P_@{subsec}_@{reg};
    @# endif

    # IRefRaw_@{reg}_@{subsec} = delta_@{subsec}_@{reg} * K_@{subsec}_@{reg}(-1);
    # IRef_@{reg}_@{subsec} =
        0.5*( IRefRaw_@{reg}_@{subsec} + epsI_@{reg}_@{subsec}
            + sqrt( (IRefRaw_@{reg}_@{subsec} - epsI_@{reg}_@{subsec})^2 + epsI_@{reg}_@{subsec}^2 ) );
    # I_pos_@{reg}_@{subsec} = 0.5 * ( (I_@{subsec}_@{reg} + I_G_@{subsec}_@{reg})
                                        + sqrt( (I_@{subsec}_@{reg} + I_G_@{subsec}_@{reg})^2 + epsI_@{reg}_@{subsec}^2 ) );

    [name = 'Investment goods purchase price @{subsec} @{reg}']
    P_INV_@{subsec}_@{reg} = PINV_base_@{reg}_@{subsec}
        * (I_pos_@{reg}_@{subsec} / IRef_@{reg}_@{subsec})^(1/etaKS_p) * exp(exo_I_@{subsec}_@{reg});

    [name = 'HH FOC investment @{subsec} @{reg}']
    @# if lInternalizePK == 1
        omegaI_@{subsec}_@{reg} = P_INV_@{subsec}_@{reg} / PINV_base_@{reg}_@{subsec};
    @# else
        omegaI_@{subsec}_@{reg} = 1;
    @# endif

    # AdjCost_@{reg}_@{subsec} = 1;

@# elseif lCapQuad == 1

    # phiG_effAdj_@{reg}_@{subsec} = min(1, max(0, phiG_@{subsec}_@{reg}_p * exp(exo_phiG_@{subsec}_@{reg})));
    # IRefRaw_@{reg}_@{subsec} = (1-phiG_effAdj_@{reg}_@{subsec})*delta_@{subsec}_@{reg}_p
                                  * K_H_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1);
    # IRef_@{reg}_@{subsec} =
        0.5*( IRefRaw_@{reg}_@{subsec} + epsI_@{reg}_@{subsec}
            + sqrt( (IRefRaw_@{reg}_@{subsec} - epsI_@{reg}_@{subsec})^2 + epsI_@{reg}_@{subsec}^2 ) );
    # phiKeff_@{reg}_@{subsec} = phiK_@{subsec}_@{reg};
    # wKHtaper_@{reg}_@{subsec} =
        K_H_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1)
        / sqrt( (K_H_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1))^2 + IRef_@{reg}_@{subsec}^2 );
    # phiKeff_@{reg}_@{subsec} = phiKeff_@{reg}_@{subsec} * wKHtaper_@{reg}_@{subsec};
    # xI_@{reg}_@{subsec}  = (I_H_@{subsec}_@{reg}     - I_H_@{subsec}_@{reg}(-1)) / IRef_@{reg}_@{subsec};
    # xIp_@{reg}_@{subsec} = (I_H_@{subsec}_@{reg}(+1) - I_H_@{subsec}_@{reg}    ) / IRef_@{reg}_@{subsec};
    # AdjCost_@{reg}_@{subsec} = 1 - (phiKeff_@{reg}_@{subsec}/2) * xI_@{reg}_@{subsec}^2;

    [name = 'HH FOC investment @{subsec} @{reg}']
    lambda_@{reg} * P_INV_@{subsec}_@{reg}
    = omegaI_@{subsec}_@{reg} * lambda_@{reg} * P_INV_@{subsec}_@{reg}
        * (1 - (phiKeff_@{reg}_@{subsec}/2)*xI_@{reg}_@{subsec}^2
              - phiKeff_@{reg}_@{subsec}*xI_@{reg}_@{subsec}*I_H_@{subsec}_@{reg}/IRef_@{reg}_@{subsec})
      + beta_p * exp(exo_beta) * omegaI_@{subsec}_@{reg}EXP * lambda_@{reg}EXP * P_INV_@{subsec}_@{reg}EXP
        * phiKeff_@{reg}_@{subsec} * xIp_@{reg}_@{subsec} * I_H_@{subsec}_@{reg}EXP / IRef_@{reg}_@{subsec};

@# else

    // Default: asinh log-growth adjustment cost
    # phiG_effAdj_@{reg}_@{subsec} = min(1, max(0, phiG_@{subsec}_@{reg}_p * exp(exo_phiG_@{subsec}_@{reg})));
    # IRefRaw_@{reg}_@{subsec} = 0.01*(1-phiG_effAdj_@{reg}_@{subsec}) * delta_@{subsec}_@{reg}_p
                                  * K_H_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1);
    # IRef_@{reg}_@{subsec} =
        0.5*( IRefRaw_@{reg}_@{subsec} + epsI_@{reg}_@{subsec}
            + sqrt( (IRefRaw_@{reg}_@{subsec} - epsI_@{reg}_@{subsec})^2 + epsI_@{reg}_@{subsec}^2 ) );
    # IScale_@{reg}_@{subsec} = IRef_@{reg}_@{subsec};
    # aK_@{reg}_@{subsec} = sqrt(phiK_@{subsec}_@{reg} / 2);
    # IPos_@{reg}_@{subsec}     = 0.5*( I_H_@{subsec}_@{reg}
                                       + sqrt( I_H_@{subsec}_@{reg}^2    + IScale_@{reg}_@{subsec}^2 ) );
    # IPosEXP_@{reg}_@{subsec}  = 0.5*( I_H_@{subsec}_@{reg}EXP
                                       + sqrt( I_H_@{subsec}_@{reg}EXP^2 + IScale_@{reg}_@{subsec}^2 ) );
    # IPosPrev_@{reg}_@{subsec} = 0.5*( I_H_@{subsec}_@{reg}(-1)
                                       + sqrt( I_H_@{subsec}_@{reg}(-1)^2 + IScale_@{reg}_@{subsec}^2 ) );
    # xI_@{reg}_@{subsec}  = log( IPos_@{reg}_@{subsec}    ) - log( IPosPrev_@{reg}_@{subsec} );
    # xIp_@{reg}_@{subsec} = log( IPosEXP_@{reg}_@{subsec} ) - log( IPos_@{reg}_@{subsec}    );
    @# if lAdjPos == 1
        # wPos_@{reg}_@{subsec}     = 0.5*( 1 + I_H_@{subsec}_@{reg}
                                           / sqrt( I_H_@{subsec}_@{reg}^2    + IScale_@{reg}_@{subsec}^2 ) );
        # wPosEXP_@{reg}_@{subsec}  = 0.5*( 1 + I_H_@{subsec}_@{reg}EXP
                                           / sqrt( I_H_@{subsec}_@{reg}EXP^2 + IScale_@{reg}_@{subsec}^2 ) );
        # dwPos_dI_@{reg}_@{subsec} = 0.5 * IScale_@{reg}_@{subsec}^2
                                      / ( I_H_@{subsec}_@{reg}^2 + IScale_@{reg}_@{subsec}^2 )^(3/2);
    @# else
        # wPos_@{reg}_@{subsec}     = 1;
        # wPosEXP_@{reg}_@{subsec}  = 1;
        # dwPos_dI_@{reg}_@{subsec} = 0;
    @# endif
    # Sraw_@{reg}_@{subsec}    = exp(  aK_@{reg}_@{subsec} * xI_@{reg}_@{subsec} )
                                + exp( -aK_@{reg}_@{subsec} * xI_@{reg}_@{subsec} ) - 2;
    # AdjCost_@{reg}_@{subsec} = 1 - wPos_@{reg}_@{subsec} * Sraw_@{reg}_@{subsec};
    # dIPos_dI_@{reg}_@{subsec} = 0.5*( 1 + I_H_@{subsec}_@{reg}
                                        / sqrt( I_H_@{subsec}_@{reg}^2 + IScale_@{reg}_@{subsec}^2 ) );
    # nowAdj_@{reg}_@{subsec} =
        AdjCost_@{reg}_@{subsec}
        - I_H_@{subsec}_@{reg}
          * ( dwPos_dI_@{reg}_@{subsec} * Sraw_@{reg}_@{subsec}
            + wPos_@{reg}_@{subsec} * aK_@{reg}_@{subsec}
              * ( exp(  aK_@{reg}_@{subsec} * xI_@{reg}_@{subsec} )
                - exp( -aK_@{reg}_@{subsec} * xI_@{reg}_@{subsec} ) )
              * dIPos_dI_@{reg}_@{subsec} / IPos_@{reg}_@{subsec} );
    # fwdAdj_@{reg}_@{subsec} =
        wPosEXP_@{reg}_@{subsec} * aK_@{reg}_@{subsec}
        * ( exp(  aK_@{reg}_@{subsec} * xIp_@{reg}_@{subsec} )
          - exp( -aK_@{reg}_@{subsec} * xIp_@{reg}_@{subsec} ) )
        * I_H_@{subsec}_@{reg}EXP * dIPos_dI_@{reg}_@{subsec} / IPos_@{reg}_@{subsec};

    [name = 'HH FOC investment @{subsec} @{reg}']
    lambda_@{reg} * P_INV_@{subsec}_@{reg}
    = omegaI_@{subsec}_@{reg} * lambda_@{reg} * P_INV_@{subsec}_@{reg} * nowAdj_@{reg}_@{subsec}
      + beta_p * exp(exo_beta) * omegaI_@{subsec}_@{reg}EXP * lambda_@{reg}EXP * P_INV_@{subsec}_@{reg}EXP * fwdAdj_@{reg}_@{subsec};

@# endif

[name = 'HH capital scrapping @{subsec} @{reg}']
scrap_@{subsec}_@{reg} = 0;

// ---------------------------------------------------------------------------------
// Capital law of motion
// ---------------------------------------------------------------------------------
# epsK_@{reg}_@{subsec} = epsI_@{reg}_@{subsec} * K0_@{subsec}_@{reg}_p / max(1, K0_@{subsec}_@{reg}_p);

@# if lEndoUtilization == 1
    # rKSS_@{reg}_@{subsec} = 1/beta_p - 1 + delta_@{subsec}_@{reg};
    # u_K_pos_@{reg}_@{subsec} = 0.5 * ( u_K_@{subsec}_@{reg}
                                        + sqrt( u_K_@{subsec}_@{reg}^2 + 1e-4 ) );
    # effDelta_@{reg}_@{subsec} = delta_@{subsec}_@{reg}
                                + rKSS_@{reg}_@{subsec} / sigmaU_p
                                  * (u_K_pos_@{reg}_@{subsec}^sigmaU_p - 1);
@# else
    # effDelta_@{reg}_@{subsec} = delta_@{subsec}_@{reg};
@# endif

@# if lSolow == 1
    # rawK_@{reg}_@{subsec} = (1 - effDelta_@{reg}_@{subsec}) * K_H_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1)
                            + I_H_@{subsec}_@{reg} / PoP_@{reg}
                            - phiK_@{subsec}_@{reg}_p^2*(I_H_@{subsec}_@{reg} / PoP_@{reg} - (I_H_@{subsec}_@{reg}(-1)) / PoP_@{reg}(-1))^2
                            - scrap_@{subsec}_@{reg} / PoP_@{reg}
                            - (1-phiG_effAdj_@{reg}_@{subsec}) * D_K_@{subsec}_@{reg} / PoP_@{reg};
@# else
    # rawK_@{reg}_@{subsec} = ((1 - effDelta_@{reg}_@{subsec}) * K_H_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1)
                            + (I_H_@{subsec}_@{reg}) / PoP_@{reg} * AdjCost_@{reg}_@{subsec}
                            - scrap_@{subsec}_@{reg} / PoP_@{reg}
                            - D_K_@{subsec}_@{reg} / PoP_@{reg});
@# endif

# lhsCapSub_3_@{reg}_@{subsec} = K_H_@{subsec}_@{reg} / PoP_@{reg};
# rhsCapSub_3_@{reg}_@{subsec} = rawK_@{reg}_@{subsec};

[name = 'LOM capital @{subsec} @{reg}']
lhsCapSub_3_@{reg}_@{subsec} = rhsCapSub_3_@{reg}_@{subsec};

@# if lEndoUtilization == 1
    // wInv ≈ 1 when I_H > 0 (investing normally) → equation pins u_K = 1.
    // wInv ≈ 0 when I_H → 0 (investment floor hit) → FOC pins u_K endogenously.
    # wInv_@{reg}_@{subsec} = 0.5 * ( 1 + I_H_@{subsec}_@{reg}
                                      / sqrt( I_H_@{subsec}_@{reg}^2
                                            + IRef_@{reg}_@{subsec}^2 ) );

    [name = 'HH utilization slack @{subsec} @{reg}']
    wInv_@{reg}_@{subsec} * (u_K_@{subsec}_@{reg} - 1)
    + (1 - wInv_@{reg}_@{subsec})
      * (r_H_@{subsec}_@{reg} * (1 - tauKH_@{subsec}_@{reg})
         - omegaI_@{subsec}_@{reg} * rKSS_@{reg}_@{subsec} * u_K_pos_@{reg}_@{subsec}^sigmaU_p)
    = exo_u_K_@{subsec}_@{reg};
@# endif
