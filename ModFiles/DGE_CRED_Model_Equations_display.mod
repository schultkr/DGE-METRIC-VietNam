% =============================
% === Declare Model Equations =
% =============================

predetermined_variables
@# for reg in 1:Regions
    B_@{reg}
    @# if Regions > 1
        @# for regm in 1:Regions
            B_@{reg}_@{regm}
        @# endfor
    @# endif
@# endfor
;

model;
// =======================
// Block 1: Expectations =
// =======================
# rfEXP = omegaP_p * rf(+1) + (1 - omegaP_p) * rf;
@# for reg in 1:Regions
    # tauC_@{reg}EXP = omegaP_p * tauC_@{reg}(+1) + (1 - omegaP_p) * tauC_@{reg};
    # tauKH_@{reg}EXP = omegaP_p * tauKH_@{reg}(+1) + (1 - omegaP_p) * tauKH_@{reg};
    # P_@{reg}EXP = omegaP_p * P_@{reg}(+1) + (1 - omegaP_p) * P_@{reg};
    # NX_@{reg}EXP = omegaP_p * NX_@{reg}(+1) + (1 - omegaP_p) * NX_@{reg}; 
    # B_@{reg}EXP = omegaP_p * B_@{reg}(+1) + (1 - omegaP_p) * B_@{reg};
    # B_@{reg}EXPEXP = omegaP_p * B_@{reg}(+2) + (1 - omegaP_p) * B_@{reg}(+1);
    # Y_@{reg}EXP = omegaP_p * Y_@{reg}(+1) + (1 - omegaP_p) * Y_@{reg};
    # C_@{reg}EXP = omegaP_p * C_@{reg}(+1) + (1 - omegaP_p) * C_@{reg};
    # H_@{reg}EXP = omegaP_p * H_@{reg}(+1) + (1 - omegaP_p) * H_@{reg};
    # PoP_@{reg}EXP = omegaP_p * PoP_@{reg}(+1) + (1 - omegaP_p) * PoP_@{reg};
    # lambda_@{reg}EXP = omegaP_p * lambda_@{reg}(+1) + (1 - omegaP_p) * lambda_@{reg};
    # omegaH_@{reg}EXP = omegaP_p * omegaH_@{reg}(+1) + (1 - omegaP_p) * omegaH_@{reg};
    @# if Regions > 0
        @# for regm in 1:Regions            
            # NX_@{reg}_@{regm}EXP = omegaP_p * NX_@{reg}_@{regm}(+1) + (1 - omegaP_p) * NX_@{reg}_@{regm};
            # B_@{reg}_@{regm}EXP = omegaP_p * B_@{reg}_@{regm}(+1) + (1 - omegaP_p) * B_@{reg}_@{regm};
            # B_@{reg}_@{regm}EXPEXP = omegaP_p * B_@{reg}_@{regm}(+2) + (1 - omegaP_p) * B_@{reg}_@{regm}(+1);
        @# endfor
    @# endif
@# endfor
@# for sec in 1:Sectors
    @# for reg in 1:Regions
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            # P_@{subsec}_@{reg}EXP = omegaP_p * P_@{subsec}_@{reg}(+1) + (1 - omegaP_p) * P_@{subsec}_@{reg};
            # r_@{subsec}_@{reg}EXP = omegaP_p * r_@{subsec}_@{reg}(+1) + (1 - omegaP_p) * r_@{subsec}_@{reg};
            # omegaI_@{subsec}_@{reg}EXP = omegaP_p * omegaI_@{subsec}_@{reg}(+1) + (1 - omegaP_p) * omegaI_@{subsec}_@{reg};
            # I_@{subsec}_@{reg}EXP = omegaP_p * I_@{subsec}_@{reg}(+1) + (1 - omegaP_p) * I_@{subsec}_@{reg};
        @# endfor
    @# endfor
@# endfor

// =====================
// Block 2: Identities =
// =====================

[name = 'population']
PoP = 
@# for reg in 1:Regions
    + PoP_@{reg}
@# endfor
;

[name = 'labour force']
LF = 
@# for reg in 1:Regions
    + LF_@{reg}
@# endfor
;

[name = 'wage index']
W = 
@# for reg in 1:Regions
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            + N_@{subsec}_@{reg} * LF_@{reg} / (LF * N) * W_@{subsec}_@{reg}
        @# endfor
    @# endfor
@# endfor
;

[name = 'foreign net asset position']
B = 
@# for reg in 1:Regions
    + B_@{reg}EXP
@# endfor
;

[name = 'Net Exports']
NX = X - M;

[name = 'Government Budget Constraint']
G = 
@# for reg in 1:Regions
    + G_@{reg} * P_@{reg}
@# endfor
;

[name = 'national investment']
I = 
@# for sec in 1:Sectors
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
        @# for reg in 1:Regions
            + max(0, I_@{subsec}_@{reg} * P_@{subsec}_@{reg})
        @# endfor
    @# endfor
@# endfor
;

[name = 'aggregate consumption']
C = 
@# for reg in 1:Regions
    + C_@{reg} * P_@{reg}
@# endfor
;

[name = 'aggregate gross value added']
Y = 
@# for reg in 1:Regions
    + Y_@{reg}
@# endfor
;

[name = 'aggregate output']
Q = 
@# for reg in 1:Regions
    + Q_@{reg}
@# endfor
;

[name = 'aggregate intermediate output']
Q_I = 
@# for reg in 1:Regions
    + Q_I_@{reg}
@# endfor
;

[name = 'aggregate used products']
Q_U = 
@# for reg in 1:Regions
    + Q_U_@{reg} * P_D_@{reg}
@# endfor
;

[name = 'Exports']
X = 
@# for reg in 1:Regions
    + X_@{reg} * P_Q_@{reg}
@# endfor
;

[name = 'Imports']
M = 
@# for reg in 1:Regions
    + M_@{reg}
@# endfor
;

[name = 'aggregate labour']
N * LF = 
@# for reg in 1:Regions
    + N_@{reg} * LF_@{reg}
@# endfor
;

// ==========================================
// Block 3: Regional Identities
// ==========================================
@# for reg in 1:Regions
    # WDiff_@{reg} = exp(
    @# for j in 1:TAdjust
        + @{j}/((@{TAdjust}+1)*@{TAdjust}/2) * log(W_@{reg}(-@{j})/W(-@{j}))
    @# endfor
    );
@# endfor

@# for reg in 1:Regions

[name = 'regional wage index']
W_@{reg} = 
@# for sec in 1:Sectors
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
        + N_@{subsec}_@{reg} / N_@{reg} * W_@{subsec}_@{reg}
    @# endfor
@#endfor
;

[name = 'regional import demand']
M_@{reg} = 
@# for sec in 1:Sectors                                
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
        + P_M_@{subsec} * (M_I_@{subsec}_@{reg} + M_F_@{subsec}_@{reg})
    @# endfor
@#endfor
;

[name = 'regional demand']
P_D_@{reg} = P0_D_@{reg}_p * exp(exo_P_D_@{reg});

[name = 'imported consumption']
P_F_@{reg} * M_F_@{reg}^0 = (
    @# for sec in 1:Sectors
        + omegaMA_F_@{sec}_@{reg}_p * P_M_A_@{sec}_@{reg}^(1-etaQ_p)
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            + P_M_@{subsec} * M_F_@{subsec}_@{reg} * 0
        @# endfor
    @# endfor
)^(1/(1-etaQ_p));

[name = 'regional exchange rate']
s_@{reg} = rhos_p * s_@{reg}(-1) + (1 - rhos_p) * s0_@{reg}_p * exp(exo_s_@{reg});

[name = 'regional exports']
P_Q_@{reg} = (
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec] 
            + D_X_@{subsec}_@{reg}_p * P_Q_@{subsec}_@{reg}^(1-etaX_p)
        @# endfor
    @# endfor
)^(1/(1-etaX_p));

[name = 'regional output']
Q_@{reg} = 
@# for sec in 1:Sectors
    @# for subsec in Subsecstart[sec]:Subsecend[sec] 
        + P_Q_@{subsec}_@{reg} * Q_@{subsec}_@{reg}
    @# endfor
@#endfor
;

[name = 'regional intermediate product demand']
Q_I_@{reg} = 
@# for sec in 1:Sectors
    @# for subsec in Subsecstart[sec]:Subsecend[sec] 
        + P_I_@{subsec}_@{reg} * Q_I_@{subsec}_@{reg}
    @# endfor
@#endfor
;

[name = 'national price level']
P_@{reg} = (
    omegaF_@{reg}_p * P_F_@{reg}^(1 - etaF_p) + (1 - omegaF_@{reg}_p) * P_D_@{reg}^(1 - etaF_p)
)^(1 / (1 - etaF_p));

[name = 'net exports to GDP ratio']
NX_@{reg} = X_@{reg} * P_Q_@{reg} - M_@{reg};

[name = 'regional labour']
N_@{reg} = 
@# for sec in 1:Sectors
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
        + N_@{subsec}_@{reg}
    @# endfor
@#endfor
;

[name = 'regional value added']
Y_@{reg} = 
@# for sec in 1:Sectors
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
        + P_@{subsec}_@{reg} * Y_@{subsec}_@{reg}
    @# endfor
@#endfor
;

[name = 'regional aggregate investment']
I_@{reg} = 
@# for sec in 1:Sectors
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
        + max(0, I_@{subsec}_@{reg}) * P_@{subsec}_@{reg} / P_@{reg}
    @# endfor
@#endfor
;

@#endfor

// ==========================================
// Block 4: Demographics
// ==========================================

@# for reg in 1:Regions

    [name = 'regional labour force']
    LF_@{reg} = (lEndoMig_p == 0) * LF0_@{reg}_p * exp(exo_LF_@{reg}) 
              + (lEndoMig_p == 1) * (
                    omegaLF0_@{reg}_p * exp(exo_LF_@{reg}) * WDiff_@{reg}^(etaLF_p)
                ) / (
        @# for regm in 1:Regions
            + omegaLF0_@{regm}_p * exp(exo_LF_@{regm}) * WDiff_@{regm}^(etaLF_p)
        @# endfor
        ) * (
        @# for regm in 1:Regions
            + LF0_@{regm}_p * exp(exo_LF_@{regm})
        @# endfor
    );
    
    [name = 'Population']
    PoP_@{reg} = LF_@{reg} + (PoP0_@{reg}_p - LF0_@{reg}_p) * exp(exo_NLF_@{reg});

@# endfor

// ==========================================
// Block 5: Rest of the World
// ==========================================
@# for sec in 1:Sectors
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
        [name = 'price for imports']
        P_M_@{subsec} = P_M_@{subsec}_p + exo_M_@{subsec};
    @# endfor
@# endfor

[name = 'World interest rate']
rf = 1 / (beta_p * exp(exo_beta)) - 1 + exo_rf;
// ==========================================
// Block 6: Households
// ==========================================
@# for reg in 1:Regions

[name = 'net export to GDP ratio']
NX_@{reg}/Y_@{reg}*(exo_NXL_@{reg}==1) + adjB_@{reg} * (exo_NX_@{reg}==0) = 
    exo_adjB_@{reg} * (exo_NX_@{reg}==0) + (NX0_@{reg}_p + exo_NX_@{reg}) * (exo_NXL_@{reg}==1);

[name = 'world depreciation rate']
deltaB_@{reg}*(exo_BL_@{reg}==0) + (exo_BL_@{reg}==1)*B_@{reg}EXP/Y_@{reg} = 
    exo_deltaB_@{reg}*(exo_BL_@{reg}==0) + (exo_BL_@{reg}==1)*exo_B_@{reg};

[name = 'FOC Foreign Assets']
lambda_@{reg} * (1 + 2*phiadjB_p*(B_@{reg}EXP - B_@{reg} + adjB_@{reg})) = 
    lambda_@{reg}EXP * beta_p * exp(exo_beta) * (
        s_@{reg}(+1) * (1 + rfEXP) * exp(-phiB_p*(B_@{reg}EXP - (1 - deltaB_p)*B_@{reg}) / Y_@{reg}EXP)
        + 2 * phiadjB_p * (B_@{reg}(+2) - B_@{reg}EXP + adjB_@{reg}(+1))
    );

[name = 'Law of motion foreign bonds']
B_@{reg}EXP = 
    (1 + rf) * s_@{reg} * exp(-phiB_p*(B_@{reg} - (1 - deltaB_p)*B_@{reg}(-1)) / Y_@{reg}) * B_@{reg}
    + NX_@{reg} - phiadjB_p * (B_@{reg}EXP - B_@{reg} + 0.5 * adjB_@{reg})^2 + deltaB_@{reg};

    [name = 'FOC HH consumption']
    lambda_@{reg} * P_@{reg} * (1 + tauC_@{reg}) = (1-gamma_@{reg}_p) * ((C_@{reg}-h_p*C_@{reg}(-1))/PoP_@{reg})^(-gamma_@{reg}_p) * (H_@{reg}/PoP_@{reg})^gamma_@{reg}_p * (((C_@{reg}-h_p*C_@{reg}(-1))/PoP_@{reg})^(1-gamma_@{reg}_p) * (H_@{reg}/PoP_@{reg})^gamma_@{reg}_p)^(-sigmaC_p)
                          - beta_p * exp(exo_beta) * h_p * (1-gamma_@{reg}_p) * ((C_@{reg}EXP-h_p*C_@{reg})/PoP_@{reg}EXP)^(-gamma_@{reg}_p) * (H_@{reg}EXP/PoP_@{reg}EXP)^gamma_@{reg}_p * (((C_@{reg}EXP-h_p*C_@{reg})/PoP_@{reg}EXP)^(1-gamma_@{reg}_p) * (H_@{reg}EXP/PoP_@{reg}EXP)^gamma_@{reg}_p)^(-sigmaC_p);

    [name = 'law of motion for houses']
    H_@{reg}/PoP_@{reg} = (1 - deltaH_p) * (H_@{reg}(-1)/PoP_@{reg}(-1)) + (IH_@{reg}/PoP_@{reg}) - DH_@{reg}/PoP_@{reg};
    @# if YEndogenous == 0
        [name = 'exogenous development of housing area']
        H_@{reg}/PoP_@{reg} = H0_@{reg}_p + exo_H_@{reg};
    @# else
        [name = 'exogenous development of housing area']
        PH_@{reg} = PH0_@{reg}_p * exp(exo_H_@{reg});
    @# endif
    [name = 'FOC HH houses']
    lambda_@{reg}*omegaH_@{reg} = beta_p *exp(exo_beta)*(lambda_@{reg}EXP*omegaH_@{reg}EXP*(1 - deltaH_p) + (((C_@{reg}EXP-h_p*C_@{reg})/PoP_@{reg}EXP)^(1 - gamma_@{reg}_p)*(H_@{reg}/PoP_@{reg}EXP)^(gamma_@{reg}_p - 1)*gamma_@{reg}_p)*(((C_@{reg}EXP-h_p*C_@{reg})/PoP_@{reg}EXP)^(1 - gamma_@{reg}_p)*(H_@{reg}/PoP_@{reg}EXP)^gamma_@{reg}_p)^(-sigmaC_p));

    [name = 'FOC HH investment in houses']
    lambda_@{reg}*omegaH_@{reg} = PH_@{reg} * (1 + tauH_@{reg}) * lambda_@{reg};
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]

            [name = 'HH FOC capital']
            lambda_@{reg}EXP * beta_p * exp(exo_beta) * r_@{subsec}_@{reg}EXP * P_@{subsec}_@{reg}EXP^lEndoQ_@{subsec}_@{reg}_p * (1 - tauKH_@{reg}EXP) + lambda_@{reg}EXP * omegaI_@{subsec}_@{reg}EXP * P_@{subsec}_@{reg}EXP * beta_p * exp(exo_beta) * (1 - delta_p)=lambda_@{reg} * omegaI_@{subsec}_@{reg} * P_@{subsec}_@{reg};
            @# if lSolow == 1
                # lhsCapSub_2_@{reg}_@{subsec} =  0.9*I_@{subsec}_@{reg}(-1) + 0.1*steady_state(I_@{subsec}_@{reg})/steady_state(Y_@{reg})*Y_@{reg};
                # rhsCapSub_2_@{reg}_@{subsec} =  I_@{subsec}_@{reg};
            @# else
                @# if lCapQuad == 1
                    # lhsCapSub_2_@{reg}_@{subsec} =  lambda_@{reg} * P_@{subsec}_@{reg};
                    # rhsCapSub_2_@{reg}_@{subsec} =  lambda_@{reg} * omegaI_@{subsec}_@{reg} * P_@{subsec}_@{reg} * (1-2*phiK_p^2*(I_@{subsec}_@{reg}-I_@{subsec}_@{reg}(-1)))
                                                      +lambda_@{reg}EXP * omegaI_@{subsec}_@{reg}EXP * P_@{subsec}_@{reg}EXP * 2*phiK_p^2*(I_@{subsec}_@{reg}EXP-I_@{subsec}_@{reg});
                @# else 
                    # lhsCapSub_2_@{reg}_@{subsec} =  lambda_@{reg} * P_@{subsec}_@{reg}^lEndoQ_@{subsec}_@{reg}_p;
                    # rhsCapSub_2_@{reg}_@{subsec} =  (lambda_@{reg} * omegaI_@{subsec}_@{reg} * P_@{subsec}_@{reg} * (1 -  (exp(sqrt(phiK_p / 2)*((I_@{subsec}_@{reg})/(I_@{subsec}_@{reg}(-1))*PoP_@{reg}(-1)/PoP_@{reg} -1)) + exp(-sqrt(phiK_p / 2) * ((I_@{subsec}_@{reg})/(I_@{subsec}_@{reg}(-1)) * PoP_@{reg}(-1)/PoP_@{reg}-1)) - 2) - (I_@{subsec}_@{reg})/(I_@{subsec}_@{reg}(-1)) * PoP_@{reg}(-1)/PoP_@{reg} * sqrt(phiK_p / 2) * (exp(sqrt(phiK_p / 2) * ((I_@{subsec}_@{reg})/(I_@{subsec}_@{reg}(-1))-1)) - exp(-sqrt(phiK_p / 2) * ((I_@{subsec}_@{reg})/(I_@{subsec}_@{reg}(-1))*PoP_@{reg}(-1)/PoP_@{reg}-1))))
                                                     + beta_p * exp(exo_beta) * lambda_@{reg}EXP * P_@{subsec}_@{reg}EXP * omegaI_@{subsec}_@{reg}EXP * (I_@{subsec}_@{reg}EXP)^2/(I_@{subsec}_@{reg})^2 * (PoP_@{reg}/PoP_@{reg}EXP)^2 * sqrt(phiK_p / 2) * (exp(sqrt(phiK_p / 2) * ((I_@{subsec}_@{reg}EXP)/(I_@{subsec}_@{reg}) * PoP_@{reg}/PoP_@{reg}EXP-1)) 
                            - exp(-sqrt(phiK_p / 2) * ((I_@{subsec}_@{reg}EXP)/(I_@{subsec}_@{reg})*PoP_@{reg}/PoP_@{reg}EXP-1))));
                @# endif
            @# endif
            [name = 'HH FOC investment']
            (lhsCapSub_2_@{reg}_@{subsec}+1)=(rhsCapSub_2_@{reg}_@{subsec}+1);
            @# if lSolow == 1
                # lhsCapSub_3_@{reg}_@{subsec} = K_@{subsec}_@{reg} / PoP_@{reg};
                # rhsCapSub_3_@{reg}_@{subsec} = (1 - delta_p) * K_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1) + I_@{subsec}_@{reg} / PoP_@{reg}-phiK_p^2*(I_@{subsec}_@{reg} / PoP_@{reg}-I_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1))^2 - D_K_@{subsec}_@{reg} / PoP_@{reg};
                //# rhsCapSub_3_@{reg}_@{subsec} = (1 - delta_p) * K_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1) + I_@{subsec}_@{reg} / PoP_@{reg}-phiK_p^2*(I_@{subsec}_@{reg} / K_@{subsec}_@{reg}(-1)-delta_p)^2 - D_K_@{subsec}_@{reg} / PoP_@{reg};
            @# else 
                # lhsCapSub_3_@{reg}_@{subsec} = K_@{subsec}_@{reg} / PoP_@{reg};
                # rhsCapSub_3_@{reg}_@{subsec} = (1 - delta_p) * K_@{subsec}_@{reg}(-1) / PoP_@{reg}(-1) + max(0,I_@{subsec}_@{reg}) / PoP_@{reg} * (1 -  (exp(sqrt(phiK_p / 2)*((I_@{subsec}_@{reg})/(I_@{subsec}_@{reg}(-1)) * PoP_@{reg}(-1) / PoP_@{reg} -1)) + exp(-sqrt(phiK_p / 2) * ((I_@{subsec}_@{reg})/(I_@{subsec}_@{reg}(-1)) * PoP_@{reg}(-1) / PoP_@{reg} -1)) - 2)) - D_K_@{subsec}_@{reg} / PoP_@{reg};
            @# endif
            [name = 'LOM capital',mcp = 'I_@{subsec}_@{reg} > 0']
            (lhsCapSub_3_@{reg}_@{subsec})/(rhsCapSub_3_@{reg}_@{subsec})=1;
            #lhsSupplySubsec_11_@{reg}_@{subsec} = (1 - tauNH_@{reg}) * W_@{subsec}_@{reg} * LF_@{reg}/PoP_@{reg} * lambda_@{reg} * lEndoN_@{subsec}_@{reg}_p + (1-lEndoN_@{subsec}_@{reg}_p) * N_@{subsec}_@{reg};
            #rhsSupplySubsec_11_@{reg}_@{subsec} = phiL_@{subsec}_@{reg}_p * A_N_@{subsec}_@{reg} * (N_@{subsec}_@{reg})^sigmaL_p * lEndoN_@{subsec}_@{reg}_p + (1-lEndoN_@{subsec}_@{reg}_p) * phiN0_@{subsec}_@{reg}_p * N0_@{reg}_p * exp(exo_Q_@{subsec}_@{reg});
            [name = 'HH FOC labour @{sec} @{reg} ',mcp = 'N_@{sec}_@{reg}>0']
            (lhsSupplySubsec_11_@{reg}_@{subsec}+1) / (rhsSupplySubsec_11_@{reg}_@{subsec}+1) = 1;
        @# endfor
    @# endfor
    @# if Regions > 0
        @# for regm in 1:Regions
           @# if Regions == 1
                #lhsAggReg_@{reg}_@{regm}_2 = B_@{reg}_@{regm};
                #rhsAggReg_@{reg}_@{regm}_2 = 0;
                [name = 'foreign assets']
                (lhsAggReg_@{reg}_@{regm}_2+1)/(1 + rhsAggReg_@{reg}_@{regm}_2) = 1;
                #lhsAggReg_@{reg}_@{regm}_1 = NX_@{reg}_@{regm};
                #rhsAggReg_@{reg}_@{regm}_1 = 0;
                [name = 'bilateral regional net exports']
                (lhsAggReg_@{reg}_@{regm}_1+1) / (rhsAggReg_@{reg}_@{regm}_1+1) = 1;
            @# else
                #lhsAggReg_@{reg}_@{regm}_2 = lambda_@{reg};
                #rhsAggReg_@{reg}_@{regm}_2 = lambda_@{reg}EXP * beta_p * exp(exo_beta) * (1 + rfEXP - deltaB_p) * exp(-phiB_p*(rfEXP*sf_@{reg}*B_@{reg}_@{regm}EXP + NX_@{reg}_@{regm}EXP));
                [name = 'FOC foreign assets']
                (1+lhsAggReg_@{reg}_@{regm}_2)/(1+rhsAggReg_@{reg}_@{regm}_2) = 1;
                #lhsAggReg_@{reg}_@{regm}_1 = NX_@{reg}_@{regm};
                #rhsAggReg_@{reg}_@{regm}_1 = 
                @# for sec in 1:Sectors
                    @# for subsec in Subsecstart[sec]:Subsecend[sec]            
                        + P_Q_@{subsec}_@{reg} * Q_D_@{subsec}_@{regm}_@{reg} - P_Q_@{subsec}_@{regm} * Q_D_@{subsec}_@{reg}_@{regm}
                    @# endfor
                @# endfor
                ;
                [name = 'bilateral regional net exports']
                (lhsAggReg_@{reg}_@{regm}_1+1) / (rhsAggReg_@{reg}_@{regm}_1+1) = 1;
            @# endif
        @# endfor
    @# endif
@# endfor
                  
// ==========================================
// Block 7: Government
// ==========================================
@# for reg in 1:Regions
    [name = 'regional government budget constraint']
    P_@{reg} * G_@{reg} + Tr_@{reg} + BG_@{reg} = 
        tauC_@{reg} * P_@{reg} * C_@{reg}
        + IH_@{reg} * PH_@{reg} * tauH_@{reg}
        + PE_@{reg} * E_@{reg}
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + (tauKF_@{subsec}_@{reg} + tauKH_@{reg}) * K_@{subsec}_@{reg}(-1) * P_@{subsec}_@{reg} * r_@{subsec}_@{reg}
                + (tauNF_@{subsec}_@{reg} + tauNH_@{reg}) * W_@{subsec}_@{reg} * N_@{subsec}_@{reg} * LF_@{reg}
            @# endfor
        @# endfor
        + (1 + rf) * s_@{reg}(-1) * BG_@{reg}(-1);
    
    [name = 'regional transfers']
    Tr_@{reg} = Tr0_@{reg}_p + exo_Tr_@{reg} + exo_tauSTr_@{reg} * PE_@{reg} * E_@{reg};
    
    [name = 'adaptation measures for housing stock']
    G_A_DH_@{reg} = exo_G_A_DH * Y0_p;
    
    [name = 'Government Budget Constraint']
    BG_@{reg} = exo_BG_@{reg};
    
    [name = 'public goods capital stock']
    KG_@{reg} = (1 - deltaKG_p) * KG_@{reg}(-1) + G_@{reg};
    
    [name = 'taxes on household labour income']
    tauNH_@{reg} = tauNH_@{reg}_p + exo_tauNH_@{reg};
    
    [name = 'taxes on household capital income']
    tauKH_@{reg} = tauKH_@{reg}_p + exo_tauKH_@{reg};
    
    [name = 'taxes on consumption']
    tauC_@{reg} = tauC_@{reg}_p + exo_tauC_@{reg};
    
    [name = 'taxes on housing']
    tauH_@{reg} = tauH_@{reg}_p + exo_tauH_@{reg};
    
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
    
            [name = 'sector specific corporate tax rate paid by firms']
            tauKF_@{subsec}_@{reg} = tauKF_@{subsec}_@{reg}_p - tauS_@{reg} + exo_tauKF_@{subsec}_@{reg};
            
            [name = 'sector specific labour tax rate paid by firms']
            tauNF_@{subsec}_@{reg} = tauNF_@{subsec}_@{reg}_p + exo_tauNF_@{subsec}_@{reg};
            
            [name = 'sector specific adaptation expenditures by the government against climate change']
            K_A_@{subsec}_@{reg} = exo_GA_@{subsec}_@{reg} * Y0_p;
            
            [name = 'sector specific adaptation capital against climate change']
            K_A_@{subsec}_@{reg} = (1 - deltaKA_@{subsec}_@{reg}_p) * K_A_@{subsec}_@{reg}(-1) + G_A_@{subsec}_@{reg};

        @# endfor
    @#endfor
@#endfor
// ==========================================
// Block 8: Productivity and damages
// ==========================================
@# for reg in 1:Regions
    @# for sec in 1:Sectors                                
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            @# if YEndogenous == 1
                [name = 'sector-specific TFP']
                log(A_@{subsec}_@{reg} * lEndoQ_@{subsec}_@{reg}_p + Q_@{subsec}_@{reg} * (1 - lEndoQ_@{subsec}_@{reg}_p)) = 
                log(A_@{subsec}_@{reg}_p * KG_@{reg}^phiG_p * exp(exo_@{subsec}_@{reg}) * lEndoQ_@{subsec}_@{reg}_p 
                    + Q0_@{subsec}_@{reg}_p * exp(exo_Q_@{subsec}_@{reg}) * (1 - lEndoQ_@{subsec}_@{reg}_p));

            @# else
                [name = 'sector-specific TFP']
                Y_@{subsec}_@{reg} * P_@{subsec}_@{reg} * lEndoQ_@{subsec}_@{reg}_p + Q_@{subsec}_@{reg} * (1 - lEndoQ_@{subsec}_@{reg}_p) = 
                    phiY0_@{subsec}_@{reg}_p / phiY_p * Y0_p * exp(exo_@{subsec}_@{reg}) * lEndoQ_@{subsec}_@{reg}_p 
                    + Q0_@{subsec}_@{reg}_p * exp(exo_Q_@{subsec}_@{reg}) * (1 - lEndoQ_@{subsec}_@{reg}_p);
            @# endif

            @# if YEndogenous == 1
                [name = 'sector-specific intermediates']
                log(A_I_@{subsec}_@{reg}) = lEndogenousY_p * exo_A_I_@{subsec}_@{reg} + (1 - lEndogenousY_p) * exo_QI_@{subsec}_@{reg};

            @# else
                [name = 'sector-specific intermediates']
                P_I_@{subsec}_@{reg} * Q_I_@{subsec}_@{reg} / ((P_Q_@{subsec}_@{reg} - kappaE_@{subsec}_@{reg}_p * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p) * Q_@{subsec}_@{reg}) = 
                    phiQI_@{subsec}_@{reg}_p / (phiY0_@{subsec}_@{reg}_p + phiQI_@{subsec}_@{reg}_p) 
                    * exp(lEndogenousY_p * exo_A_I_@{subsec}_@{reg} + (1 - lEndogenousY_p) * exo_QI_@{subsec}_@{reg});
            @# endif
                
                [name = 'sector and capital specific productivity shock']
                A_K_@{subsec}_@{reg} = exp(exo_K_@{subsec}_@{reg});

            @# if YEndogenous == 1
                [name = 'sector and labour specific productivity shock']
                log(A_N_@{subsec}_@{reg}) = exo_N_@{subsec}_@{reg};
                
                            @# else
                [name = 'sector and labour specific productivity shock']
                N_@{subsec}_@{reg} = phiN0_@{subsec}_@{reg}_p * N0_@{reg}_p * exp(exo_N_@{subsec}_@{reg});
                            @# endif
                
                [name = 'sector-specific damage function']
                D_@{subsec}_@{reg} = exo_D_@{subsec}_@{reg};
                
                [name = 'sector specific damage function on labour productivity']
                D_N_@{subsec}_@{reg} = exo_D_N_@{subsec}_@{reg};

                [name = 'sector specific damage function on capital formation']
                D_K_@{subsec}_@{reg} = exo_D_K_@{subsec}_@{reg} * Y0_p;

        @# endfor
    @# endfor

[name = 'damages to houses']
DH_@{reg} = exo_DH_@{reg} * Y / PH_@{reg};

@# endfor

// ==========================================
// Block 9: Retailers
// ==========================================
@# for reg in 1:Regions

    [name = 'final demand for domestic production']
    P_D_@{reg} / P_@{reg} = 
        (1 - omegaF_@{reg}_p)^(1 / etaF_p)
        * (Q_U_@{reg} / (C_@{reg} + I_@{reg} + (iSecHouse_p == 0) * PH_@{reg} / P_@{reg} * IH_@{reg} + G_@{reg}))^(-1 / etaF_p);
    
    [name = 'final demand for imports']
    P_F_@{reg} / P_@{reg} = 
        omegaF_@{reg}_p^(1 / etaF_p)
        * (M_F_@{reg} / (C_@{reg} + I_@{reg} + (iSecHouse_p == 0) * PH_@{reg} / P_@{reg} * IH_@{reg} + G_@{reg}))^(-1 / etaF_p);
    
    @# for sec in 1:Sectors
        [name = 'domestic aaggregate sector imports']
        P_M_A_@{sec}_@{reg} = 
            (etaQA_@{sec}_p == 1) * exp(
                @# for subsec in Subsecstart[sec]:Subsecend[sec]
                    + log(P_M_@{subsec} / omegaM_F_@{subsec}_@{reg}_p) * omegaM_F_@{subsec}_@{reg}_p
                @# endfor
            )
            + (etaQA_@{sec}_p != 1) * (
                @# for subsec in Subsecstart[sec]:Subsecend[sec]
                    + omegaM_F_@{subsec}_@{reg}_p * P_M_@{subsec}^(1 - etaQA_@{sec}_p)
                @# endfor
            )^(1 / (1 - etaQA_@{sec}_p + (etaQA_@{sec}_p == 1)));
        
        [name = 'domestic demand for aaggregate final sector output']
        P_A_@{sec}_@{reg} / P_D_@{reg} = 
            omegaQA_@{sec}_@{reg}_p^(1 / etaQ_p) 
            * (Q_A_F_@{sec}_@{reg} / Q_U_@{reg})^(-1 / etaQ_p);

        [name = 'domestic demand for aaggregate final sector imports']
        P_M_A_@{sec}_@{reg} / P_F_@{reg} = 
            omegaMA_F_@{sec}_@{reg}_p^(1 / etaQ_p) 
            * (M_A_F_@{sec}_@{reg} / M_F_@{reg})^(-1 / etaQ_p);

    @# endfor

@# endfor

// ==========================================
// Block 10: Wholesalers
// ==========================================
@# for reg in 1:Regions
    @# for sec in 1:Sectors

        [name = 'domestic aggregate sector output']
        Q_A_@{sec}_@{reg} = 
            (etaQA_@{sec}_p == 1) * exp(
                @# for subsec in Subsecstart[sec]:Subsecend[sec]
                    + log(Q_D_@{subsec}_@{reg}) * omegaQ_@{subsec}_@{reg}_p
                @# endfor
            )
            + (etaQA_@{sec}_p != 1) * (
                @# for subsec in Subsecstart[sec]:Subsecend[sec]
                    + omegaQ_@{subsec}_@{reg}_p^(1/etaQA_@{sec}_p) * Q_D_@{subsec}_@{reg}^((etaQA_@{sec}_p - 1)/etaQA_@{sec}_p)
                @# endfor
            )^(etaQA_@{sec}_p / (etaQA_@{sec}_p - 1 + (etaQA_@{sec}_p == 1)));
        
        [name = 'aggregate final sector output']
        Q_A_@{sec}_@{reg} = 
            Q_A_F_@{sec}_@{reg} + Q_A_I_@{sec}_@{reg} 
            + (iSecHouse_p == @{sec}) * IH_@{reg} * PH_@{reg} / P_A_@{sec}_@{reg};
        
        [name = 'domestic demand for aggregate intermediate sector output']
        Q_A_I_@{sec}_@{reg} * P_A_@{sec}_@{reg} = 
            @# for secm in 1:Sectors 
                @# for subsec in Subsecstart[secm]:Subsecend[secm]
                    + Q_I_@{subsec}_@{reg}_@{sec} * (
                        P_A_@{sec}_@{reg} 
                        + kappaEI_@{subsec}_@{reg}_@{sec}_p * exp(exo_EI_@{subsec}_@{reg}_@{sec}) 
                        * (Q_D_@{SubsecFossil}_@{reg} / Q_A_@{SecEnergy}_@{reg}) * PE_@{reg} 
                        * lEndoQ_@{subsec}_@{reg}_p)
                @# endfor        
            @# endfor
        ;

        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            @# for regm in 1:Regions
                [name = 'demand for regional sector output']
                P_Q_@{subsec}_@{regm} = 
                    omegaQ_@{subsec}_@{reg}_@{regm}_p^(1 / etaQ_@{subsec}_p) 
                    * (Q_D_@{subsec}_@{reg}_@{regm} / Q_D_@{subsec}_@{reg})^(-1 / etaQ_@{subsec}_p) 
                    * P_D_@{subsec}_@{reg};           
            @# endfor
            
            [name = 'demand for regional subsector imports']
            P_M_@{subsec} = 
                omegaM_@{subsec}_@{reg}_p^(1 / etaQ_@{subsec}_p) 
                * (M_I_@{subsec}_@{reg} / Q_D_@{subsec}_@{reg})^(-1 / etaQ_@{subsec}_p) 
                * P_D_@{subsec}_@{reg};
            
            [name = 'demand for regional subsector final imports']
            P_M_@{subsec} / P_M_A_@{sec}_@{reg} = 
                omegaM_F_@{subsec}_@{reg}_p^(1 / etaQA_@{sec}_p) 
                * (M_F_@{subsec}_@{reg} / M_A_F_@{sec}_@{reg})^(-1 / etaQA_@{sec}_p);

            [name = 'aggregate demand for subsector regional output']
            Q_D_@{subsec}_@{reg} = 
                (etaQ_@{subsec}_p == 1) * exp(
                    @# for regm in 1:Regions
                        + log(Q_D_@{subsec}_@{reg}_@{regm}) * omegaQ_@{subsec}_@{reg}_@{regm}_p
                    @# endfor
                    + log(M_I_@{subsec}_@{reg}) * omegaM_@{subsec}_@{reg}_p
                )
                + (etaQ_@{subsec}_p != 1) * (
                    @# for regm in 1:Regions
                        + omegaQ_@{subsec}_@{reg}_@{regm}_p^(1 / etaQ_@{subsec}_p) 
                          * Q_D_@{subsec}_@{reg}_@{regm}^((etaQ_@{subsec}_p - 1)/etaQ_@{subsec}_p)
                    @# endfor
                    + omegaM_@{subsec}_@{reg}_p^(1 / etaQ_@{subsec}_p) 
                      * M_I_@{subsec}_@{reg}^((etaQ_@{subsec}_p - 1)/etaQ_@{subsec}_p)
                )^(etaQ_@{subsec}_p / (etaQ_@{subsec}_p - 1 + (etaQ_@{subsec}_p == 1)));

            [name = 'demand for subsector output']
            P_D_@{subsec}_@{reg} / P_A_@{sec}_@{reg} = 
                omegaQ_@{subsec}_@{reg}_p^(1 / etaQA_@{sec}_p) 
                * (Q_D_@{subsec}_@{reg} / Q_A_@{sec}_@{reg})^(-1 / etaQA_@{sec}_p);

        @# endfor

    @# endfor
@# endfor

// ==========================================
// Block 11: Firms
// ==========================================
@# for reg in 1:Regions
  @# for sec in 1:Sectors
    @# for subsec in Subsecstart[sec]:Subsecend[sec]

        [name = 'demand for regional sector value added']
        P_@{subsec}_@{reg} = 
            (1 - omegaQI_@{subsec}_@{reg}_p)^(1 / etaI_@{subsec}_p) 
            * (Y_@{subsec}_@{reg} / Q_@{subsec}_@{reg})^(-1 / etaI_@{subsec}_p) 
            * (P_Q_@{subsec}_@{reg} - kappaE_@{subsec}_@{reg}_p * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p);
        
        [name = 'regional sector demand for intermediates']
        P_I_@{subsec}_@{reg} = 
            A_I_@{subsec}_@{reg}^((etaI_@{subsec}_p - 1)/etaI_@{subsec}_p)
            * omegaQI_@{subsec}_@{reg}_p^(1 / etaI_@{subsec}_p)
            * (Q_I_@{subsec}_@{reg} / Q_@{subsec}_@{reg})^(-1 / etaI_@{subsec}_p)
            * (P_Q_@{subsec}_@{reg} - kappaE_@{subsec}_@{reg}_p * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p);
        
            @# for secm in 1:Sectors
        
                [name = 'regional sector demand for intermediates from aggregate sector']
                P_A_@{secm}_@{reg} + kappaEI_@{subsec}_@{reg}_@{secm}_p * exp(exo_EI_@{subsec}_@{reg}_@{secm}) * (Q_D_@{SubsecFossil}_@{reg}/Q_A_@{SecEnergy}_@{reg}) * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p =
                    omegaQI_@{subsec}_@{reg}_@{secm}_p^(1 / etaIA_@{subsec}_p)
                    * (Q_I_@{subsec}_@{reg}_@{secm} / Q_I_@{subsec}_@{reg})^(-1 / etaIA_@{subsec}_p)
                    * P_I_@{subsec}_@{reg};
                
                [name = 'regional emissions caused by using intermediates from aggregate sector']
                E_I_@{subsec}_@{reg}_@{secm} =
                    kappaEI_@{subsec}_@{reg}_@{secm}_p * exp(exo_EI_@{subsec}_@{reg}_@{secm})
                    * (Q_D_@{SubsecFossil}_@{reg}/Q_A_@{SecEnergy}_@{reg}) * Q_I_@{subsec}_@{reg}_@{secm};
        
            @# endfor
        
        [name = 'regional sector demand for intermediates']
        Q_I_@{subsec}_@{reg} = 
            (etaIA_@{subsec}_p == 1) * exp(
                @# for secm in 1:Sectors
                    + log(Q_I_@{subsec}_@{reg}_@{secm}) * omegaQI_@{subsec}_@{reg}_@{secm}_p
                @# endfor
            ) + 
            (etaIA_@{subsec}_p != 1) * (
                @# for secm in 1:Sectors
                    + omegaQI_@{subsec}_@{reg}_@{secm}_p^(1 / etaIA_@{subsec}_p)
                      * Q_I_@{subsec}_@{reg}_@{secm}^((etaIA_@{subsec}_p - 1) / etaIA_@{subsec}_p)
                @# endfor
            )^(etaIA_@{subsec}_p / (etaIA_@{subsec}_p - 1 + (etaIA_@{subsec}_p == 1)));
        
        [name = 'sector specific gva']
        Y_@{subsec}_@{reg} = 
            (etaNK_@{subsec}_@{reg}_p == 1) * 
                (1 - D_@{subsec}_@{reg}) * A_@{subsec}_@{reg}
                * (A_K_@{subsec}_@{reg} * K_@{subsec}_@{reg}(-1))^alphaK_@{subsec}_@{reg}_p
                * (LF_@{reg} * (1 - D_N_@{subsec}_@{reg}) * A_N_@{subsec}_@{reg} * N_@{subsec}_@{reg})^alphaN_@{subsec}_@{reg}_p
            + (etaNK_@{subsec}_@{reg}_p != 1) * (1 - D_@{subsec}_@{reg}) * A_@{subsec}_@{reg}
                * (
                    alphaK_@{subsec}_@{reg}_p^(1 / etaNK_@{subsec}_@{reg}_p)
                    * (A_K_@{subsec}_@{reg} * K_@{subsec}_@{reg}(-1))^((etaNK_@{subsec}_@{reg}_p - 1) / etaNK_@{subsec}_@{reg}_p)
                    + alphaN_@{subsec}_@{reg}_p^(1 / etaNK_@{subsec}_@{reg}_p)
                    * (LF_@{reg} * (1 - D_N_@{subsec}_@{reg}) * A_N_@{subsec}_@{reg} * N_@{subsec}_@{reg})^((etaNK_@{subsec}_@{reg}_p - 1) / etaNK_@{subsec}_@{reg}_p)
                )^(etaNK_@{subsec}_@{reg}_p / (etaNK_@{subsec}_@{reg}_p - 1 + (etaNK_@{subsec}_@{reg}_p == 1) * 1000));
        
        [name = 'Firms FOC capital', mcp = 'K_@{subsec}_@{reg} > 0']
        r_@{subsec}_@{reg} * (1 + tauKF_@{subsec}_@{reg}) = 
            alphaK_@{subsec}_@{reg}_p^(1 / etaNK_@{subsec}_@{reg}_p)
            * ((1 - D_@{subsec}_@{reg}) * A_@{subsec}_@{reg} * A_K_@{subsec}_@{reg})^((etaNK_@{subsec}_@{reg}_p - 1) / etaNK_@{subsec}_@{reg}_p)
            * (K_@{subsec}_@{reg}(-1) / Y_@{subsec}_@{reg})^(-1 / etaNK_@{subsec}_@{reg}_p);
        
        [name = 'Firms FOC labour @{subsec} @{reg}', mcp = 'N_@{subsec}_@{reg} > 0']
        W_@{subsec}_@{reg} * (1 + tauNF_@{subsec}_@{reg}) / P_@{subsec}_@{reg} = 
            alphaN_@{subsec}_@{reg}_p^(1 / etaNK_@{subsec}_@{reg}_p)
            * ((1 - D_N_@{subsec}_@{reg}) * A_N_@{subsec}_@{reg} * (1 - D_@{subsec}_@{reg}) * A_@{subsec}_@{reg})^((etaNK_@{subsec}_@{reg}_p - 1) / etaNK_@{subsec}_@{reg}_p)
            * ((LF_@{reg} * N_@{subsec}_@{reg}) / Y_@{subsec}_@{reg})^(-1 / etaNK_@{subsec}_@{reg}_p);
        
        [name = 'sector region specific output']
        Q_@{subsec}_@{reg} = 
            (etaI_@{subsec}_p != 1)
                * (omegaQI_@{subsec}_@{reg}_p^(1 / etaI_@{subsec}_p) * (A_I_@{subsec}_@{reg} * Q_I_@{subsec}_@{reg})^((etaI_@{subsec}_p - 1)/etaI_@{subsec}_p)
                + (1 - omegaQI_@{subsec}_@{reg}_p)^(1 / etaI_@{subsec}_p) * Y_@{subsec}_@{reg}^((etaI_@{subsec}_p - 1)/etaI_@{subsec}_p))^(etaI_@{subsec}_p / (etaI_@{subsec}_p - 1 + (etaI_@{subsec}_p == 1)))
            + (etaI_@{subsec}_p == 1)
                * (Q_I_@{subsec}_@{reg}^omegaQI_@{subsec}_@{reg}_p * Y_@{subsec}_@{reg}^(1 - omegaQI_@{subsec}_@{reg}_p));
        
        [name = 'sector region specific exports']
        X_@{subsec}_@{reg} / X_@{reg} = 
            D_X_@{subsec}_@{reg}_p * exp(exo_X_@{subsec}_@{reg}) 
            * ((P_Q_@{subsec}_@{reg} + 0 * kappaE_@{subsec}_@{reg}_p * PE_@{reg} * lEndoQ_@{subsec}_@{reg}_p) / P_Q_@{reg})^(-etaX_p);
        
        [name = 'sector region specific exports share']
        D_X_@{subsec}_@{reg} = X_@{subsec}_@{reg} / Q_@{subsec}_@{reg};
        
        [name = 'sector region specific output']
        Q_@{subsec}_@{reg} = 
            X_@{subsec}_@{reg}
            @# for regm in 1:Regions
                + Q_D_@{subsec}_@{regm}_@{reg}
            @# endfor
        ;
        
        [name = 'regional subsector emissions']
        E_@{subsec}_@{reg} = kappaE_@{subsec}_@{reg}_p * Q_@{subsec}_@{reg};

    @# endfor
  @# endfor
@# endfor

// ==========================================
// Block 12: Climate Variables and Emissions
// ==========================================
@# for reg in 1:Regions
    @# for z in ClimateVarsRegional
        [name = '@{z}']
        @{z}_@{reg} = @{z}0_@{reg}_p + exo_@{z}_@{reg};
    @# endfor

    [name = 'regional emissions']
    E_@{reg} = 
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + E_@{subsec}_@{reg}
                @# for secm in 1:Sectors
                    + E_I_@{subsec}_@{reg}_@{secm}
                @# endfor
            @# endfor
        @# endfor
    ;
    
    [name = 'regional susbsidies']
    tauS_@{reg} * (
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + K_@{subsec}_@{reg}(-1) * P_@{subsec}_@{reg} * r_@{subsec}_@{reg}
            @# endfor
        @# endfor
    ) = exo_tauS_@{reg} * PE_@{reg} * E_@{reg};
    
    [name = 'regional price of emissions/emission cap']
    exo_CapTradeInternat * PE_@{reg} 
    + (1 - exo_CapTradeInternat) * (E_@{reg} * exo_CapTrade_@{reg} + PE_@{reg} * (1 - exo_CapTrade_@{reg})) 
    = exo_CapTradeInternat * PE 
    + (1 - exo_CapTradeInternat) * (
        E0_@{reg}_p * exp(exo_E_@{reg}) * exo_CapTrade_@{reg}
        + (PE0_@{reg}_p + exo_PE_@{reg} + exo_PE) * (1 - exo_CapTrade_@{reg})
    );

@# endfor

@# for z in ClimateVarsNational

    [name = '@{z}']
    @{z} = @{z}0_p + exo_@{z};

@# endfor

[name = 'aggregate emissions']
E = 
    @# for reg in 1:Regions
        + E_@{reg}
    @# endfor
;

[name = 'price of emissions/emission cap']
E * exo_CapTradeInternat + PE * (1 - exo_CapTradeInternat) = 
    E0_p * exp(exo_E) * exo_CapTradeInternat + PE0_p * (1 - exo_CapTradeInternat);

// ==========================================
// Block 13: Resource Constraints
// ==========================================
@# for reg in 1:Regions        
    [name = 'regional resource constraint']
    Q_@{reg} = P_@{reg} * (G_@{reg} + C_@{reg} + I_@{reg} + IH_@{reg} * PH_@{reg}/P_@{reg}) + Q_I_@{reg} + NX_@{reg}
    @# if Regions > 0
        @# for regm in 1:Regions
             + NX_@{reg}_@{regm}
        @# endfor
    @# endif
    ;
@# endfor
end;