function strys = set_K_target_and_backout_rG(strys, strpar, strexo, ssubsec, sreg)
% SET_K_TARGET_AND_BACKOUT_RG  Fix total capital to target and back out r_G.
%
% When exo_lKRGTarget = 1 for a subsector, ExoSubsec_13 targets K_ rather
% than setting r_G exogenously.  This function:
%   1. Overrides K_ with K0_p * exp(exo_KRGTarget_)
%   2. Recomputes K_H_ = K_ - K_G_
%   3. Derives r_F_ from the firm FOC for capital
%   4. Backs out r_G_ from the rental clearing identity:
%        r_F_ * K_ = K_H_ * r_H_ + K_G_ * r_G_
%
% Called from compute_production_factors_and_output.m (lCalibration_p == 2
% branch and scenario branch) and from compute_pf_parameters.m.

    stemp  = [ssubsec '_' sreg];
    delta  = strpar.(['delta_'  stemp '_p']);
    dK     = strys.(['D_K_' stemp]);

    % 1. Fix total capital to target
    K0     = strpar.(['K0_' stemp '_p']);
    K_target = K0 * exp(strexo.(['exo_KRGTarget_' stemp]));
    strys.(['K_' stemp]) = K_target;

    % 2. Split into public, FDI, and household capital.
    %    FDI fills the excess of K_target above the no-FDI calibrated baseline K0.
    %    K_H_ stays at its calibrated level K0*(1-phiG), unchanged from the no-FDI SS.
    K_FDI = max(0, K_target - K0);
    K_G   = strys.(['K_G_' stemp]);
    K_H   = max(0, K_target - K_G - K_FDI);

    if K_H == 0
        strys.(['K_' stemp]) = K_G + K_FDI;
    end

    strys.(['K_FDI_' stemp]) = K_FDI;
    strys.(['K_H_'   stemp]) = K_H;

    % 3. Derive r_F_ from the firm FOC for capital
    %    FOC: r_F_ * (1+tauKF) * P_K / P = alphaK^(1/etaNK) * [(1-D)*A*A_K]^rho * [Kserv/Y]^(-1/etaNK)
    %    (In Cobb-Douglas limit etaNK=1: r_F_ = alphaK * Y * P / (Kserv * (1+tauKF) * P_K))
    Kserv      = strys.(['K_' stemp]) * strys.(['u_K_' stemp]);
    etaNK      = strpar.(['etaNK_' stemp '_p']);
    alphaK     = strpar.(['alphaK_' stemp '_p']);
    A          = strys.(['A_'   stemp]);
    A_K        = strys.(['A_K_' stemp]);
    D          = strys.(['D_'   stemp]);
    Y          = strys.(['Y_'   stemp]);
    tauKF      = strys.(['tauKF_' stemp]);
    P          = strys.(['P_'   stemp]);
    P_K        = strys.(['P_K_' stemp]);
    exo_P_K    = strexo.(['exo_P_K_' stemp]);

    if etaNK ~= 1
        rho        = (etaNK - 1) / etaNK;
        rkgross_PK = alphaK^(1/etaNK) ...
                     * (A * (1 - D) * A_K)^rho ...
                     * (Kserv / Y)^(-1/etaNK) ...
                     * P / P_K;
    else
        % Cobb-Douglas
        rkgross_PK = alphaK * Y * P / (P_K * Kserv);
    end
    rkgross = rkgross_PK / exp(exo_P_K);
    strys.(['r_F_' stemp]) = rkgross / (1 + tauKF);

    % 4. Back out r_G_ from rental clearing identity (includes FDI term)
    K_H = strys.(['K_H_'   stemp]);
    r_H = strys.(['r_H_'   stemp]);
    r_F = strys.(['r_F_'   stemp]);
    r_FDI = strpar.rf0_p + strexo.(['exo_r_FDI_' stemp]);
    strys.(['r_FDI_' stemp]) = r_FDI;
    if K_G > 0
        strys.(['r_G_' stemp]) = ...
            (r_F * strys.(['K_' stemp]) - r_H * K_H - r_FDI * K_FDI) / K_G;
    end

    % Update investment consistently with the new K_, K_H_, and K_FDI_
    strys.(['I_H_'   stemp]) = K_H   * delta + dK * (K_H   > 0);
    strys.(['I_FDI_' stemp]) = K_FDI * delta;
    strys.(['ILR_'   stemp]) = strys.(['I_H_' stemp]);
end
