// ============================================================
// Block 15: Exogenous Private Investment  [display version]
// ============================================================

@# for reg in 1:Regions
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            #lhsIP_@{subsec}_@{reg} = I_P_@{subsec}_@{reg};
            #rhsIP_@{subsec}_@{reg} = (phiKP0_@{subsec}_@{reg}_p + exo_I_P_@{subsec}_@{reg}) * Y0_p;
            [name = 'Exogenous private investment s=@{subsec} r=@{reg}']
            lhsIP_@{subsec}_@{reg} = rhsIP_@{subsec}_@{reg};
        @# endfor
    @# endfor
@# endfor
