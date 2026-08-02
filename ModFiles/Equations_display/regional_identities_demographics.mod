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
    # lhsBlock3_@{reg}_1 = W_@{reg};
    # rhsBlock3_@{reg}_1 = 
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            + N_@{subsec}_@{reg} / N_@{reg} * W_@{subsec}_@{reg}
        @# endfor
    @# endfor
    ;
    [name = 'regional wage index']
    lhsBlock3_@{reg}_1 = rhsBlock3_@{reg}_1;
    #lhsBlock3_@{reg}_2 = M_@{reg};
    #rhsBlock3_@{reg}_2 = 
    @# for sec in 1:Sectors                                
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            + P_M_@{subsec} * (M_I_@{subsec}_@{reg} + M_F_@{subsec}_@{reg})
        @# endfor
    @# endfor
    ;
    [name = 'regional import demand']
    lhsBlock3_@{reg}_2 = rhsBlock3_@{reg}_2;
    #lhsBlock3_@{reg}_3 = P_D_@{reg};
    #rhsBlock3_@{reg}_3 = P0_D_@{reg}_p * exp(exo_P_D_@{reg});
    [name = 'regional demand']
    lhsBlock3_@{reg}_3 = rhsBlock3_@{reg}_3;
    #lhsAggReg_@{reg}_11 = P_F_@{reg} * M_F_@{reg}^0;
    #rhsAggReg_@{reg}_11 = (
        @# for sec in 1:Sectors
            +omegaMA_F_@{sec}_@{reg}_p * P_M_A_@{sec}_@{reg}^(1-etaQ_p)
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + P_M_@{subsec} * M_F_@{subsec}_@{reg}*0
            @# endfor
        @# endfor
    )^(1/(1-etaQ_p));
    [name = 'imported consumption']
    lhsAggReg_@{reg}_11 = rhsAggReg_@{reg}_11;
    #lhsAggReg_@{reg}_18 = s_@{reg} * (exo_lNXTarget_@{reg} == 0) + NX_@{reg} / Y_@{reg} * (exo_lNXTarget_@{reg} == 1);
    #rhsAggReg_@{reg}_18 = (rhos_p*s_@{reg}(-1) + (1-rhos_p)*s0_@{reg}_p*exp(exo_s_@{reg})) * (exo_lNXTarget_@{reg} == 0) + (NX0_@{reg}_p / Y0_@{reg}_p + exo_NX_@{reg}) * (exo_lNXTarget_@{reg} == 1);

    [name = 'regional exchange rate / net export target']
    lhsAggReg_@{reg}_18 = rhsAggReg_@{reg}_18;


    #lhsAggReg_@{reg}_EXP = P_Q_@{reg};
    #rhsAggReg_@{reg}_EXP = (
                    @# for sec in 1:Sectors
                            @# for subsec in Subsecstart[sec]:Subsecend[sec] 
                                + D_X_@{subsec}_@{reg}_p * P_Q_@{subsec}_@{reg}^(1-etaX_p)
                            @# endfor
                    @# endfor
    )^(1/(1-etaX_p));
    [name = 'regional exports']
    lhsAggReg_@{reg}_EXP = rhsAggReg_@{reg}_EXP;


    #lhsAggReg_@{reg}_19 = Q_@{reg};
    #rhsAggReg_@{reg}_19 = 
                        @# for sec in 1:Sectors
                            @# for subsec in Subsecstart[sec]:Subsecend[sec] 
                                + P_Q_@{subsec}_@{reg} * Q_@{subsec}_@{reg}
                            @# endfor
                        @# endfor
    ;
    [name = 'regional output']
    lhsAggReg_@{reg}_19 = rhsAggReg_@{reg}_19;
    #lhsAggReg_@{reg}_20 = Q_I_@{reg};
    #rhsAggReg_@{reg}_20 = 
                        @# for sec in 1:Sectors
                            @# for subsec in Subsecstart[sec]:Subsecend[sec] 
                                + P_I_@{subsec}_@{reg} * Q_I_@{subsec}_@{reg}
                            @# endfor
                        @# endfor
    ;
    [name = 'regional intermediate product demand']
    lhsAggReg_@{reg}_20 = rhsAggReg_@{reg}_20;

    #lhsAggReg_@{reg}_6 = P_@{reg};
    #rhsAggReg_@{reg}_6 = (omegaF_@{reg}_p * P_F_@{reg}^(1-etaF_p) + (1-omegaF_@{reg}_p) * P_D_@{reg}^(1-etaF_p))^(1/(1-etaF_p));// * M_F_@{reg} + P_D_@{reg}*Q_U_@{reg};
    [name = 'national price level']
    lhsAggReg_@{reg}_6 = rhsAggReg_@{reg}_6;
 
    #lhsAggReg_@{reg}_22 = NX_@{reg};
    #rhsAggReg_@{reg}_22 = X_@{reg} * P_Q_@{reg} - M_@{reg};
    [name = 'net exports to GDP ratio']
    lhsAggReg_@{reg}_22 = rhsAggReg_@{reg}_22;
    #lhsAggReg_@{reg}_23 = N_@{reg};
    #rhsAggReg_@{reg}_23 = 
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + N_@{subsec}_@{reg}
            @# endfor
        @# endfor
    ;
    [name = 'regional labour']
    lhsAggReg_@{reg}_23 = rhsAggReg_@{reg}_23;
    #lhsAggReg_@{reg}_24 = Y_@{reg};
    #rhsAggReg_@{reg}_24 = 
        @# for sec in 1:Sectors
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + P_@{subsec}_@{reg} * Y_@{subsec}_@{reg}
            @# endfor
        @# endfor
    ;
    [name = 'regional value added']
    lhsAggReg_@{reg}_24 = rhsAggReg_@{reg}_24;

    #lhsAggReg_@{reg}_10 = I_@{reg};
    #rhsAggReg_@{reg}_10 = 
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
             + (max(0,I_H_@{subsec}_@{reg})+max(0,I_FDI_@{subsec}_@{reg})) * P_INV_@{subsec}_@{reg} / P_@{reg}
        @# endfor
    @# endfor
    ;
    [name = 'regional aggregate investment']
    lhsAggReg_@{reg}_10 = rhsAggReg_@{reg}_10;


// ==========================================
// Block 4: Demographics
// ==========================================
    #lhsAggReg_@{reg}_29 = LF_@{reg};
    #rhsAggReg_@{reg}_29 = (lEndoMig_p == 0) * LF0_@{reg}_p * exp(exo_LF_@{reg}) + (lEndoMig_p == 1) * (omegaLF0_@{reg}_p * exp(exo_LF_@{reg})*WDiff_@{reg}^(etaLF_p)) /
    (
    @# for regm in 1:Regions
        + omegaLF0_@{regm}_p * exp(exo_LF_@{regm})*WDiff_@{regm}^(etaLF_p)
    @# endfor
    ) * (
    @# for regm in 1:Regions
        + LF0_@{regm}_p * exp(exo_LF_@{regm})
    @# endfor
    );
    [name = 'regional labour force']
    lhsAggReg_@{reg}_29 = rhsAggReg_@{reg}_29;
    #lhsAggReg_@{reg}_17 = PoP_@{reg};
    #rhsAggReg_@{reg}_17 = LF_@{reg} + (PoP0_@{reg}_p-LF0_@{reg}_p) * exp(exo_NLF_@{reg});
    [name = 'Population']
    lhsAggReg_@{reg}_17 = rhsAggReg_@{reg}_17;
@# endfor

