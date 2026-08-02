// ==========================================
// Block 5: Rest of the World
// ==========================================
@# for sec in 1:Sectors
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
    #lhsImportPrice_@{subsec} = P_M_@{subsec};
    #rhsImportPrice_@{subsec} = (P_Q_@{subsec}_1 + exo_M_@{subsec}) * (exo_lMAmount_@{subsec} == 0) + (P_M_@{subsec}(-1) * exp(exo_MAmt_@{subsec})) * (exo_lMAmount_@{subsec} == 1);
    [name = 'import price @{subsec}']
    (1 + lhsImportPrice_@{subsec}) / (1 + rhsImportPrice_@{subsec}) = 1;
    @# endfor
@# endfor

#lhsWorldInterestRate = rf;
#rhsWorldInterestRate = 1 / (beta_p * exp(exo_beta)) - 1 + exo_rf + deltaB_p;
[name = 'world interest rate']
(lhsWorldInterestRate + 1) / (rhsWorldInterestRate + 1) = 1;

