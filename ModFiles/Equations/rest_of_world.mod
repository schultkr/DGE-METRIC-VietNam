// ==========================================
// Block 5: Rest of the World
// ==========================================

@# for sec in 1:Sectors
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
        // Import block: default is the import price wedge; when exo_lMAmount=1,
        // use exo_MAmt as a temporary growth shock to the import wedge level.
        #lhsImportPrice_@{subsec} = P_M_@{subsec} * (exo_lMAmount_@{subsec} == 0) +
                                    (M_F_@{subsec}_@{reg} + M_I_@{subsec}_@{reg}) * (exo_lMAmount_@{subsec} == 1);
        #rhsImportPrice_@{subsec} =
            (P_Q_@{subsec}_@{reg} + exo_M_@{subsec}) * (exo_lMAmount_@{subsec} == 0)
            + ((M_F_@{subsec}_@{reg}(-1) + M_I_@{subsec}_@{reg}(-1)) * exp(exo_MAmt_@{subsec})) * (exo_lMAmount_@{subsec} == 1);
        [name = 'import price @{subsec}']
        (1 + lhsImportPrice_@{subsec}) / (1 + rhsImportPrice_@{subsec}) = 1;
    @# endfor
@# endfor

// World risk-free interest rate: patience rate (1/beta - 1) plus risk premium deltaB.
#lhsWorldInterestRate = rf;
#rhsWorldInterestRate = 1 / (beta_p * exp(exo_beta)) - 1 + exo_rf + deltaB_p;
[name = 'world interest rate']
(lhsWorldInterestRate + 1) / (rhsWorldInterestRate + 1) = 1;
