// ==========================================
// Block 5: Rest of the World
// ==========================================
@# for sec in 1:Sectors
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
            #lhsSubsec_19_@{subsec} = P_M_@{subsec};
            #rhsSubsec_19_@{subsec} = P_Q_@{subsec}_1 + exo_M_@{subsec};
            [name = 'price for imports']
            lhsSubsec_19_@{subsec} = rhsSubsec_19_@{subsec};
    @# endfor
@# endfor

#lhsAggNat_2 = rf;
#rhsAggNat_2 = 1/(beta_p*exp(exo_beta))-1 + exo_rf + deltaB_p;
[name = 'World interest rate']
lhsAggNat_2 = rhsAggNat_2;

