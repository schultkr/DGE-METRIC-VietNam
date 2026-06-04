// ==========================================
// Investment Adjustment Costs & Capital LOM
// ==========================================
// Included inside @# for reg / @# for subsec loops in households.mod.
// Macro variables @{reg} and @{subsec} are inherited from the caller.
//
// Switch:  lCapPrice == 1  → capital goods supply price curve (no quantity friction)
//          lCapQuad == 1   → normalized quadratic cost on level-differences
//          lCapQuad == 0   → asinh adjustment cost (default)

@# if lCapPrice == 1

    /************************************************************************************
     * Capital goods supply price — alternative to investment adjustment costs
     *
     * P_K = P * (I_H_pos / IRef)^(1/etaKS_p)
     *
     * IRef = replacement investment using lagged endogenous delta and K — fully
     * predetermined, so dIRef/dI_H = 0 (no simultaneity in FOC).
     * Uses endogenous delta_@{subsec}_@{reg} (not parameter delta_p) so IRef tracks
     * the fossil sector's accelerating depreciation during phase-out.
     *
     * SS: I_H = delta*K = IRef  →  I_H_pos ≈ IRef  →  P_K = P  ✓
     * I_H > IRef (investment boom): P_K > P  (supply bottleneck dampens surge)
     * I_H < IRef (winding down):    P_K < P  (excess supply capacity, cheaper capital)
     *
     * omegaI = 1 always (Tobin's q = 1, no quantity friction in LOM).
     * AdjCost = 1 (no efficiency loss — all friction is in the price).
     ************************************************************************************/

    // P_K: rental price of installed capital — always the sector's own value-added price.
    // No supply-curve friction and no exo_P_K here; those shift P_INV only.
    # lhs_PK_@{subsec}_@{reg} = P_K_@{subsec}_@{reg};
    # rhs_PK_@{subsec}_@{reg} = P_@{subsec}_@{reg} * exp(exo_P_K_@{subsec}_@{reg})/exp(A_INV_@{subsec}_@{reg});
    [name = 'Rental price of capital @{subsec} @{reg}']
    (lhs_PK_@{subsec}_@{reg} + 1) / (rhs_PK_@{subsec}_@{reg} + 1) = 1;

    // Base price for investment goods supply curve.
    @# if lCapGoodsSecPrice == 1
        # PINV_base_@{reg}_@{subsec} = P0_@{subsec}_@{reg}_p;// * P_Q_@{CapGoodsSubsec}_@{reg}/P0_Q_@{CapGoodsSubsec}_@{reg}_p;
    @# else
        # PINV_base_@{reg}_@{subsec} = P_@{subsec}_@{reg};
    @# endif

    # epsI_@{reg}_@{subsec} = 1e-3;
    // IRef: replacement investment, predetermined (uses lagged delta and K).
    // Uses endogenous delta_@{subsec}_@{reg} (not parameter) — tracks fossil depreciation acceleration.
    # IRefRaw_@{reg}_@{subsec} = delta_@{subsec}_@{reg}
                                  * K_@{subsec}_@{reg}(-1);
    # IRef_@{reg}_@{subsec} =
        0.5*( IRefRaw_@{reg}_@{subsec} + epsI_@{reg}_@{subsec}
            + sqrt( (IRefRaw_@{reg}_@{subsec} - epsI_@{reg}_@{subsec})^2 + epsI_@{reg}_@{subsec}^2 ) );

    // Smooth floor on I_H numerator — keeps base of power positive for any Newton iterate.
    // At SS: I_H >> epsI  →  I_H_pos ≈ I_H  →  ratio = 1  →  P_K = P  ✓
    # I_pos_@{reg}_@{subsec} = 0.5 * ( (I_@{subsec}_@{reg} + I_G_@{subsec}_@{reg})
                                        + sqrt( (I_@{subsec}_@{reg} + I_G_@{subsec}_@{reg})^2 + epsI_@{reg}_@{subsec}^2 ) );

    [name = 'Investment goods purchase price @{subsec} @{reg}']
    @# if (subsec == SubsecFossil) && EndoInvEn == 0
        // Exogenous fossil: no supply curve friction on P_INV either.
        (P_INV_@{subsec}_@{reg} + 1) / (PINV_base_@{reg}_@{subsec} + 1) = 1;
    @# else
        (P_INV_@{subsec}_@{reg} + 1)
        / ( PINV_base_@{reg}_@{subsec} * (I_pos_@{reg}_@{subsec} / IRef_@{reg}_@{subsec})^(1/etaKS_p) * exp(exo_I_@{subsec}_@{reg}) + 1 ) = 1;
    @# endif

    // dIpos = dI_H_pos/dI_H — derivative of the smooth floor w.r.t. I_H
    # dIpos_@{reg}_@{subsec} = 0.5 * ( 1 + I_@{subsec}_@{reg}
                                       / sqrt( I_@{subsec}_@{reg}^2 + epsI_@{reg}_@{subsec}^2 ) );

    [name = 'HH FOC investment @{subsec} @{reg}']
    @# if lInternalizePK == 1
        // omegaI = P_INV / PINV_base
        // Household internalizes the supply curve on investment goods price P_INV.
        // SS: supply curve → P_INV_SS = PINV_base (ratio = 1 → I_H/IRef = 1 at SS)  ✓
        // Boom: P_INV > PINV_base  →  omegaI > 1  →  higher effective user cost dampens surge  ✓
        // Bust: P_INV < PINV_base  →  omegaI < 1  →  lower effective user cost cushions wind-down  ✓
        omegaI_@{subsec}_@{reg} = P_INV_@{subsec}_@{reg} / PINV_base_@{reg}_@{subsec};
    @# else
        omegaI_@{subsec}_@{reg} = 1;
    @# endif

    [name = 'HH capital scrapping @{subsec} @{reg}']
    scrap_@{subsec}_@{reg} = 0;

    # AdjCost_@{reg}_@{subsec} = 1;

@# elseif lCapQuad == 1

    /************************************************************************************
     * Normalized quadratic investment adjustment cost
     *
     *   xI  = (I_H_t   - I_H_{t-1}) / IRef     (dimensionless level deviation)
     *   xIp = (I_H_{t+1} - I_H_t)   / IRef
     *
     *   AdjCost = 1 - (phiK/2) * xI^2
     *
     * Normalizing by IRef (steady-state investment) keeps phiK dimensionless and
     * avoids dividing by I_H(-1), which may be near zero or negative.
     *
     * FOC (Tobin's q) from first principles:
     *   lambda * P_K = omegaI * lambda * P_K * d(I_H * AdjCost)/dI_H
     *                + beta * omegaI_EXP * lambda_EXP * P_K_EXP * d(I_H_EXP * AdjCost_EXP)/dI_H
     *
     *   d(I_H * AdjCost)/dI_H  = 1 - (phiK/2)*xI^2 - phiK*xI*I_H/IRef
     *   d(I_H_EXP*AdjCost_EXP)/dI_H = phiK * xIp * I_H_EXP / IRef
     *
     * At SS: xI = xIp = 0 → AdjCost = 1, both derivative terms reduce to 1 and 0.
     ************************************************************************************/

    // Scale reference: replacement investment at CURRENT capital stock.
    // Using the initial SS level K0 would freeze IRef at the pre-transition scale, creating
    // massive artificial friction when renewable investment surges during the transition.
    // K_H(-1)/PoP(-1) is predetermined, so dIRef/dI_H_t = 0 — FOC derivatives unchanged.
    // At initial SS: K_H(-1)/PoP(-1) = K0_p, so IRef = (1-phiG)*delta*K0 = I_H,SS (no change).
    # epsI_@{reg}_@{subsec} = 1e-3;
    # phiG_effAdj_@{reg}_@{subsec} = min(1, max(0, phiG_@{subsec}_@{reg}_p * exp(exo_phiG_@{subsec}_@{reg})));
    # IRefRaw_@{reg}_@{subsec} = (1-phiG_effAdj_@{reg}_@{subsec})*delta_@{subsec}_@{reg}_p
                                  * K_H_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1);
    # IRef_@{reg}_@{subsec} =
        0.5*( IRefRaw_@{reg}_@{subsec} + epsI_@{reg}_@{subsec}
            + sqrt( (IRefRaw_@{reg}_@{subsec} - epsI_@{reg}_@{subsec})^2 + epsI_@{reg}_@{subsec}^2 ) );

    // Zero friction for exogenous-fossil sector
    @# if (subsec == SubsecFossil) && EndoInvEn == 0
        # phiKeff_@{reg}_@{subsec} = 0;
    @# else
        # phiKeff_@{reg}_@{subsec} = phiK_@{subsec}_@{reg};
    @# endif

    // Crowding-out taper: fade phiKeff to zero as K_H → 0.
    // When K_G crowds out K_H, IRef → epsI and xI = ΔI_H/IRef would blow up,
    // making AdjCost = 1 − phiK/2·xI² go deeply negative and crashing the LOM.
    //
    // wKHtaper = (K_H/PoP) / sqrt((K_H/PoP)² + IRef²)
    //   → 0  when K_H(-1)/PoP(-1) = 0    (fully crowded out → zero friction) ✓
    //   → 1  when K_H(-1)/PoP(-1) >> IRef (normal investing regime)          ✓
    //
    // At initial SS: K_H/PoP = K0_p, IRef = (1-phiG)·delta·K0_p → wKHtaper ≈ 1/sqrt(1+((1-phiG)delta)²) ≈ 1 ✓
    // At SS xI = 0, so phiKeff·xI terms vanish regardless → calibration unchanged.
    # wKHtaper_@{reg}_@{subsec} =
        K_H_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1)
        / sqrt( (K_H_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1))^2 + IRef_@{reg}_@{subsec}^2 );
    # phiKeff_@{reg}_@{subsec} = phiKeff_@{reg}_@{subsec} * wKHtaper_@{reg}_@{subsec};

    // Dimensionless deviation terms
    # xI_@{reg}_@{subsec}  = (I_H_@{subsec}_@{reg}     - I_H_@{subsec}_@{reg}(-1)) / IRef_@{reg}_@{subsec};
    # xIp_@{reg}_@{subsec} = (I_H_@{subsec}_@{reg}(+1) - I_H_@{subsec}_@{reg}    ) / IRef_@{reg}_@{subsec};

    // Adjustment efficiency (= 1 at SS; used in capital LOM)
    # AdjCost_@{reg}_@{subsec} = 1 - (phiKeff_@{reg}_@{subsec}/2) * xI_@{reg}_@{subsec}^2;

    [name = 'HH FOC investment @{subsec} @{reg}']
    @# if (subsec == SubsecFossil) && EndoInvEn == 0
        omegaI_@{subsec}_@{reg} = 1;
    @# else
        (lambda_@{reg} * P_INV_@{subsec}_@{reg} + 1)
        / ( omegaI_@{subsec}_@{reg} * lambda_@{reg} * P_INV_@{subsec}_@{reg}
            * (1 - (phiKeff_@{reg}_@{subsec}/2)*xI_@{reg}_@{subsec}^2
                  - phiKeff_@{reg}_@{subsec}*xI_@{reg}_@{subsec}*I_H_@{subsec}_@{reg}/IRef_@{reg}_@{subsec})
          + beta_p * exp(exo_beta) * omegaI_@{subsec}_@{reg}EXP * lambda_@{reg}EXP * P_INV_@{subsec}_@{reg}EXP
            * phiKeff_@{reg}_@{subsec} * xIp_@{reg}_@{subsec} * I_H_@{subsec}_@{reg}EXP / IRef_@{reg}_@{subsec}
          + 1 ) = 1;
    @# endif

    [name = 'HH capital scrapping @{subsec} @{reg}']
    scrap_@{subsec}_@{reg} = 0;

@# else

    /************************************************************************************
     * Asinh investment adjustment costs — first-principles FOC
     *
     * Adjustment efficiency:
     *   S(xI) = 1 - [exp(aK*xI) + exp(-aK*xI) - 2]       (= 1 at xI = 0)
     *   xI    = asinh(I_H_t / IScale) - asinh(I_H_{t-1} / IScale)
     *   xIp   = asinh(I_H_{t+1} / IScale) - asinh(I_H_t / IScale)
     *
     * Capital accumulation:  K_{t+1}/n = (1-d)*K_t/n + (I_H_t/n)*S(xI_t) - D_K/n
     *
     * FOC wrt I_H_t (Tobin's q):
     *   lambda * P_K  =  omegaI * lambda * P_K * d(I_H * S(xI))/dI_H
     *                 +  beta * omegaI_EXP * lambda_EXP * P_K_EXP * d(I_H_EXP * S(xIp))/dI_H
     *
     * Derivatives (chain rule via asinh, denom = sqrt(I_H^2 + IScale^2)):
     *   d(I_H * S(xI))/dI_H  =  S(xI) - aK*(e^{aK*xI} - e^{-aK*xI}) * I_H / denom
     *   d(I_H_EXP*S(xIp))/dI_H = aK*(e^{aK*xIp} - e^{-aK*xIp}) * I_H_EXP / denom
     *
     * At SS: xI = xIp = 0, S = 1, both expressions reduce to 1 and 0 → omegaI = 1.
     *
     * aK = sqrt(phiK/2) so the second-order Taylor expansion around xI = 0 matches
     * the standard quadratic adjustment cost with parameter phiK.
     ************************************************************************************/

    // Log-growth adjustment cost, robust to negative investment and near-zero transitions.
    //
    // Deviation:  xI = log(IPos_t) − log(IPos_{t-1})
    // IPos is a smooth-floored version of I_H (smooth_max(I_H, IScale)).
    //
    // IScale = IRef = (1-phiG)*delta*K_H(-1)/PoP(-1)  [transition-proof replacement investment].
    //
    // WHY IScale MUST BE COMPARABLE TO SS INVESTMENT:
    //   When I_H drops from I_H_SS to 0, xI = log(IPos/IPosPrev).
    //   If IScale << I_H_SS: IPos ≈ IScale/2, IPosPrev ≈ I_H_SS, xI ≈ −log(I_H_SS/IScale) → −∞.
    //   If IScale = IRef ≈ I_H_SS: IPos ≈ IScale/2, IPosPrev ≈ IScale, xI ≈ −log(2) ≈ −0.69. Bounded!
    //   This prevents Sraw = exp(aK·|xI|) from exploding and keeps AdjCost well-conditioned.
    //
    // WHY IScale-BASED wPos GIVES 1/I_H² DECAY (needed for phiK < 8):
    //   wPos = 0.5*(1 + I_H/sqrt(I_H²+IScale²)) ∝ IScale²/I_H² for large negative I_H.
    //   wPos·Sraw ∝ |I_H|^(aK−2) → 0 for phiK < 8 (covers all realistic calibrations).
    //   A log-argument floor alone (IPos) only gives 1/I_H decay — not sufficient.
    //
    // At SS: IScale = IRef = I_H_SS, xI = 0, AdjCost = 1, omegaI = 1 (no change to calibration).

    # epsI_@{reg}_@{subsec} = 1e-3;
    // IRef: transition-proof replacement investment (K_H(-1) is predetermined, so dIRef/dI_H = 0).
    // Using K0_p would freeze IRef at initial SS — problematic when investment surges in transition.
    # phiG_effAdj_@{reg}_@{subsec} = min(1, max(0, phiG_@{subsec}_@{reg}_p * exp(exo_phiG_@{subsec}_@{reg})));
    # IRefRaw_@{reg}_@{subsec} = 0.01*(1-phiG_effAdj_@{reg}_@{subsec}) * delta_@{subsec}_@{reg}_p
                                  * K_H_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1);
    # IRef_@{reg}_@{subsec} =
        0.5*( IRefRaw_@{reg}_@{subsec} + epsI_@{reg}_@{subsec}
            + sqrt( (IRefRaw_@{reg}_@{subsec} - epsI_@{reg}_@{subsec})^2 + epsI_@{reg}_@{subsec}^2 ) );
    // IScale = IRef: bounds xI to ≈ −log(2) when I_H → 0, preventing Sraw explosion.
    # IScale_@{reg}_@{subsec} = IRef_@{reg}_@{subsec};

    // aK = sqrt(phiK/2); zero for exogenous-fossil sector
    @# if (subsec == SubsecFossil) && EndoInvEn == 0
        # aK_@{reg}_@{subsec} = 0;
    @# else
        # aK_@{reg}_@{subsec} = sqrt(phiK_@{subsec}_@{reg} / 2);
    @# endif

    // Smooth-floored investment for log argument — prevents log(0) or log(<0).
    // For I_H >> IScale this is ≈ I_H; for I_H << −IScale this is ≈ IScale²/(2|I_H|) → 0.
    # IPos_@{reg}_@{subsec}     = 0.5*( I_H_@{subsec}_@{reg}
                                       + sqrt( I_H_@{subsec}_@{reg}^2    + IScale_@{reg}_@{subsec}^2 ) );
    # IPosEXP_@{reg}_@{subsec}  = 0.5*( I_H_@{subsec}_@{reg}EXP
                                       + sqrt( I_H_@{subsec}_@{reg}EXP^2 + IScale_@{reg}_@{subsec}^2 ) );
    # IPosPrev_@{reg}_@{subsec} = 0.5*( I_H_@{subsec}_@{reg}(-1)
                                       + sqrt( I_H_@{subsec}_@{reg}(-1)^2 + IScale_@{reg}_@{subsec}^2 ) );

    // Log-growth deviations (= 0 at SS where I_H_t = I_H_{t-1})
    # xI_@{reg}_@{subsec}  = log( IPos_@{reg}_@{subsec}    ) - log( IPosPrev_@{reg}_@{subsec} );
    # xIp_@{reg}_@{subsec} = log( IPosEXP_@{reg}_@{subsec} ) - log( IPos_@{reg}_@{subsec}    );

    // Smooth Heaviside weight using IScale-based sigmoid → 1/I_H² decay for large negative I_H.
    //   w = 0.5*(1 + I_H/sqrt(I_H² + IScale²))  ≈ 1 for I_H >> IScale, ≈ 0 for I_H << −IScale
    //   dw/dI_H = 0.5 * IScale² / (I_H² + IScale²)^(3/2)   [decays as IScale²/I_H³]
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

    // Cosh cost (= 0 at xI = 0) and weighted adjustment efficiency for capital LOM
    # Sraw_@{reg}_@{subsec}    = exp(  aK_@{reg}_@{subsec} * xI_@{reg}_@{subsec} )
                                + exp( -aK_@{reg}_@{subsec} * xI_@{reg}_@{subsec} ) - 2;
    # AdjCost_@{reg}_@{subsec} = 1 - wPos_@{reg}_@{subsec} * Sraw_@{reg}_@{subsec};

    // d(I_H * AdjCost)/dI_H  — current-period FOC term
    //   dAdjCost/dI_H = −dwPos/dI_H·Sraw − wPos·dSraw/dxI·dxI/dI_H
    //   dSraw/dxI     = aK·(exp(aK·xI) − exp(−aK·xI))
    //   dxI/dI_H      = dIPos/dI_H / IPos,   dIPos/dI_H = 0.5·(1 + I_H/sqrt(I_H²+IScale²))
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

    // d(I_H_EXP * AdjCost_EXP)/dI_H  — forward FOC term via xIp = log(IPos_EXP) − log(IPos)
    //   w_EXP depends only on I_H_EXP → only the −dIPos/dI_H / IPos chain-rule term survives
    # fwdAdj_@{reg}_@{subsec} =
        wPosEXP_@{reg}_@{subsec} * aK_@{reg}_@{subsec}
        * ( exp(  aK_@{reg}_@{subsec} * xIp_@{reg}_@{subsec} )
          - exp( -aK_@{reg}_@{subsec} * xIp_@{reg}_@{subsec} ) )
        * I_H_@{subsec}_@{reg}EXP * dIPos_dI_@{reg}_@{subsec} / IPos_@{reg}_@{subsec};

    [name = 'HH FOC investment @{subsec} @{reg}']
    @# if (subsec == SubsecFossil) && EndoInvEn == 0
        omegaI_@{subsec}_@{reg} =  1;
    @# else
        (lambda_@{reg} * P_INV_@{subsec}_@{reg} + 1)
        / ( omegaI_@{subsec}_@{reg} * lambda_@{reg} * P_INV_@{subsec}_@{reg} * nowAdj_@{reg}_@{subsec}
          + beta_p * exp(exo_beta) * omegaI_@{subsec}_@{reg}EXP * lambda_@{reg}EXP * P_INV_@{subsec}_@{reg}EXP * fwdAdj_@{reg}_@{subsec}
          + 1 ) = 1;
    @# endif

    [name = 'HH capital scrapping @{subsec} @{reg}']
    scrap_@{subsec}_@{reg} = 0;

@# endif

// ---------------------------------------------------------------------------------
// Capital law of motion
// K_H/PoP = smooth_max( (1-effDelta)*K_H(-1)/PoP(-1) + I_H/PoP*AdjCost - scrap/PoP - D_K/PoP, epsK )
//
// When lEndoUtilization == 1: effDelta = delta * u_K^sigmaU  (endogenous depreciation).
// At SS u_K = 1, so effDelta = delta — no change to steady-state calibration.
// The smooth floor prevents K_H from going negative during Newton iterations.
// ---------------------------------------------------------------------------------
# epsK_@{reg}_@{subsec} = epsI_@{reg}_@{subsec} * K0_@{subsec}_@{reg}_p / max(1, K0_@{subsec}_@{reg}_p);

@# if lEndoUtilization == 1
    // Effective (utilization-adjusted) depreciation rate.
    //
    // Correct SS condition from the capital Euler (omegaI=1, P_K constant):
    //   r_H_SS * (1-tauKH_SS) = 1/beta - 1 + delta_SS  ≡  rKSS
    //
    // For u_K = 1 to be the SS, we need d(delta_eff)/d(u_K)|_{u_K=1} = rKSS.
    // Using delta_eff = delta + (rKSS/sigmaU) * (u_K^sigmaU - 1):
    //   delta_eff(1)             = delta                  ✓ (SS unchanged)
    //   d(delta_eff)/d(u_K)|u=1 = rKSS                   ✓ (FOC satisfied)
    //
    // Note: requires sigmaU > rKSS/delta to keep delta_eff ≥ 0 when u_K → 0.
    // Default sigmaU_p = 2 is safe for typical beta=0.95, delta=0.05-0.15.
    # rKSS_@{reg}_@{subsec} = 1/beta_p - 1 + delta_@{subsec}_@{reg};
    // Smooth floor: u_K_pos = smooth_max(u_K, 0) keeps u_K_pos > 0 for any Newton iterate.
    // eps = 0.01 → u_K_pos(u_K=1) ≈ 1.000025 (negligible SS error); floor ≈ eps²/4|u_K| → 0⁺.
    # u_K_pos_@{reg}_@{subsec} = 0.5 * ( u_K_@{subsec}_@{reg}
                                        + sqrt( u_K_@{subsec}_@{reg}^2 + 1e-4 ) );
    # effDelta_@{reg}_@{subsec} = delta_@{subsec}_@{reg})
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

# lhsCapSub_3_@{reg}_@{subsec} = K_H_@{subsec}_@{reg} / PoP_@{reg}*exp(A_INV_@{subsec}_@{reg});
// No smooth floor here: rawK can touch zero when K_G fully crowds out K_H.
// The floor was removed because smooth_max(0, epsK) ≈ 1.5·epsK ≠ 0, creating a systematic
// SS residual when K_H_ss = 0. Instead, the phiKeff taper below prevents AdjCost blow-up.
// K_H_ is purely domestic household capital. FDI capital accumulates separately as K_FDI_ (see investment_wedge.mod).
# rhsCapSub_3_@{reg}_@{subsec} = rawK_@{reg}_@{subsec};

[name = 'LOM capital']
(lhsCapSub_3_@{reg}_@{subsec}+1)/(rhsCapSub_3_@{reg}_@{subsec}+1)=1;

@# if lEndoUtilization == 1
    // ---------------------------------------------------------------------------------
    // Utilization as slack variable for the investment lower bound
    //
    // u_K = 1 when I_H > 0 (sector is investing normally — no slack needed).
    // u_K < 1 when I_H → 0 (investment floored — utilization absorbs residual reduction).
    //
    // Smooth Heaviside on investment:
    //   wInv ≈ 1  when I_H >> 0   →  equation enforces u_K = 1
    //   wInv ≈ 0  when I_H << 0   →  equation enforces the utilization FOC
    //
    // Blended equation (smooth complementarity):
    //   wInv*(u_K − 1) + (1−wInv)*(r_H*(1−tauKH) − omegaI*rKSS*u_K^sigmaU) = 0
    //
    // In ratio form:
    //   [wInv*u_K + (1−wInv)*r_H*(1−tauKH) + 1]
    //   ─────────────────────────────────────────  = 1
    //   [wInv*1   + (1−wInv)*omegaI*rKSS*u_K^σ + 1]
    //
    // SS: I_H_SS > 0 → wInv = 1 → u_K = 1  ✓  (for any sigmaU_p)
    // Transition (fossil, I_H → 0): wInv → 0, FOC pins u_K < 1 endogenously.
    //
    // Scale IRef_@{reg}_@{subsec} (≈ replacement investment) sets the transition width.
    // ---------------------------------------------------------------------------------
    # wInv_@{reg}_@{subsec} = 0.5 * ( 1 + I_H_@{subsec}_@{reg}
                                      / sqrt( I_H_@{subsec}_@{reg}^2
                                            + IRef_@{reg}_@{subsec}^2 ) );

    [name = 'HH utilization slack @{subsec} @{reg}']
    ( wInv_@{reg}_@{subsec} * u_K_@{subsec}_@{reg}
      + (1 - wInv_@{reg}_@{subsec}) * r_H_@{subsec}_@{reg} * (1 - tauKH_@{subsec}_@{reg})
      + 1 )
    / ( wInv_@{reg}_@{subsec}
        + (1 - wInv_@{reg}_@{subsec}) * omegaI_@{subsec}_@{reg}
          * rKSS_@{reg}_@{subsec} * u_K_pos_@{reg}_@{subsec}^sigmaU_p
        + 1 ) = 1 + exo_u_K_@{subsec}_@{reg};
@# endif
