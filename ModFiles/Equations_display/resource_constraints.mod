// ==========================================
// Block 13: Resource Constraints
// ==========================================
@# for reg in 1:Regions        
    #lhsAggReg_@{reg}_21 = Q_@{reg};
    #rhsAggReg_@{reg}_21 =
    P_@{reg} * (G_@{reg} + I_G_@{reg} + C_@{reg} + I_@{reg} + IH_@{reg} * PH_@{reg}/P_@{reg}) + I_PV_@{reg} + Q_I_@{reg} + NX_@{reg}
    @# if Regions > 0
        @# for regm in 1:Regions
             + NX_@{reg}_@{regm}
        @# endfor
    @# endif
    ;
    
    [name = 'regional resource constraint']
    lhsAggReg_@{reg}_21 = rhsAggReg_@{reg}_21;
@# endfor

