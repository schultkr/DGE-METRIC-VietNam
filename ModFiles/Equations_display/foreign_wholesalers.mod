// ==========================================
// Block 11: Foreign Wholesalers
// ==========================================
@# for reg in 1:Regions
    @# for sec in 1:Sectors                                
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            #lhsSupplySubsec_8_@{reg}_@{subsec} = (phiX_@{subsec}_@{reg}_p>0)*X_@{subsec}_@{reg}/X_@{reg} + (phiX_@{subsec}_@{reg}_p==0)*X_@{subsec}_@{reg};
            #rhsSupplySubsec_8_@{reg}_@{subsec} = (phiX_@{subsec}_@{reg}_p>0)*(D_X_@{subsec}_@{reg}_p * exp(exo_X_@{subsec}_@{reg})) * (P_Q_@{subsec}_@{reg} /P_Q_@{reg})^(-etaX_p) + (phiX_@{subsec}_@{reg}_p==0)*0;
            [name = 'sector region specific exports']
            lhsSupplySubsec_8_@{reg}_@{subsec} = rhsSupplySubsec_8_@{reg}_@{subsec};
        @# endfor
    @# endfor
@# endfor

