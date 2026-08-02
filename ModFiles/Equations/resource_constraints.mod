// ==========================================
// Block 13: Resource Constraints
// ==========================================

@# for reg in 1:Regions

    #lhsRegResourceConstraint_@{reg} = Q_@{reg};
    #rhsRegResourceConstraint_@{reg} =
        P_@{reg} * (G_@{reg} + I_G_@{reg} + C_@{reg} + I_@{reg} + IH_@{reg} * PH_@{reg} / P_@{reg})
        + I_PV_@{reg}
        + Q_I_@{reg}
        + NX_@{reg}
        @# for regm in 1:Regions
            + NX_@{reg}_@{regm}
        @# endfor
    ;

    [name = 'regional resource constraint @{reg}']
    (1 + lhsRegResourceConstraint_@{reg}) / (1 + rhsRegResourceConstraint_@{reg}) = 1;

@# endfor
