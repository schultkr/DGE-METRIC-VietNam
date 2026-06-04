// =====================
// Block 2: Identities =
// =====================
#lhsBlock2_1 = PoP;
#rhsBlock2_1 = 
@# for reg in 1:Regions
    + PoP_@{reg}
@# endfor
;
[name = 'population']
lhsBlock2_1 = rhsBlock2_1;
#lhsBlock2_2 = LF;
#rhsBlock2_2 = 
@# for reg in 1:Regions
    + LF_@{reg}
@# endfor
;
[name = 'labour force']
lhsBlock2_2 = rhsBlock2_2;
# lhsBlock2_3 = W;
# rhsBlock2_3 =   
@# for reg in 1:Regions
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            + N_@{subsec}_@{reg} * LF_@{reg}/(LF * N) * W_@{subsec}_@{reg}
        @# endfor
    @# endfor
@# endfor
;
[name = 'wage index']
lhsBlock2_3 = rhsBlock2_3;
#lhsBlock2_4 = B;
#rhsBlock2_4 =  
        @# for reg in 1:Regions
            + B_@{reg}EXP
        @# endfor
;
[name = 'foreign net asset position']
lhsBlock2_4 = rhsBlock2_4;
#lhsBlock2_5 = NX;
#rhsBlock2_5 = X - M;
[name = 'Net Exports']
lhsBlock2_5 = rhsBlock2_5;
#lhsBlock2_6 = G;
#rhsBlock2_6 = 
@# for reg in 1:Regions
    + G_@{reg} * P_@{reg}
@# endfor
;
[name = 'Government Budget Constraint']
lhsBlock2_6 = rhsBlock2_6;
#lhsBlock2_7 = I;
#rhsBlock2_7 = 
@# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            @# for reg in 1:Regions
                + max(0,I_@{subsec}_@{reg} * P_INV_@{subsec}_@{reg})
            @# endfor
        @# endfor
@# endfor
;
[name = 'national investment']
lhsBlock2_7 = rhsBlock2_7;

#lhsBlock2_8 = C;
#rhsBlock2_8 = 
@# for reg in 1:Regions
 + C_@{reg} * P_@{reg} 
@# endfor
;
[name = 'aggregate consumption']
lhsBlock2_8 = rhsBlock2_8;

#lhsBlock2_9 = Y;
#rhsBlock2_9 = 
    @# for reg in 1:Regions
        + Y_@{reg}
    @# endfor
;
[name = 'aggregate gross value added']
lhsBlock2_9 = rhsBlock2_9;
#lhsBlock2_10 = Q;
#rhsBlock2_10 = 
    @# for reg in 1:Regions
        + Q_@{reg}
    @# endfor
;
[name = 'aggregate output']
lhsBlock2_10 = rhsBlock2_10;
#lhsBlock2_11 = Q_I;
#rhsBlock2_11 = 
    @# for reg in 1:Regions
        + Q_I_@{reg}
    @# endfor
;
[name = 'aggregate intermediate output']
lhsBlock2_11 = rhsBlock2_11;
#lhsBlock2_12 = Q_U;
#rhsBlock2_12 = 
@# for reg in 1:Regions
    + Q_U_@{reg} * P_D_@{reg}
@# endfor
;
[name = 'aggregate used products']
lhsBlock2_12 = rhsBlock2_12;
#lhsBlock2_13 = X;
#rhsBlock2_13 = 
@# for reg in 1:Regions
    + X_@{reg} * P_Q_@{reg}
@# endfor
;
[name = 'Exports']
lhsBlock2_13 = rhsBlock2_13;
#lhsBlock2_14 = M;
#rhsBlock2_14 = 
@# for reg in 1:Regions
    + M_@{reg}
@# endfor
;
[name = 'Imports']
lhsBlock2_14 = rhsBlock2_14;
#lhsBlock2_15 = N * LF;
#rhsBlock2_15 = 
@# for reg in 1:Regions
    + N_@{reg} * LF_@{reg}
@# endfor
;
[name = 'aggregate labour']
lhsBlock2_15 = rhsBlock2_15;

