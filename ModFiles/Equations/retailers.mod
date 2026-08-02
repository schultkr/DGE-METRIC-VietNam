// ==========================================
// Block 9: Retailers
// ==========================================

@# for reg in 1:Regions

    // Total final demand: consumption + investment + government + housing + solar self-consumption.
    // Housing investment PH/P*IH and PV investment I_PV/P enter only when iSecHouse_p == 0
    // (i.e. no explicit housing sector); otherwise the housing sector equation handles them.
    #FinalDemand_@{reg} =
        C_@{reg}
        + I_@{reg}
        + (iSecHouse_p == 0) * (PH_@{reg} / P_@{reg} * IH_@{reg} + I_PV_@{reg} / P_@{reg})
        + G_@{reg}
        + I_G_@{reg}
        + Q_PV_@{reg} * P_A_@{SecEnergy}_@{reg} / P_@{reg};

    // ------------------------------------------------------------------
    // Aggregate final demand split between domestic and imported goods
    // ------------------------------------------------------------------

    // Domestic absorption: CES demand for domestically produced final goods.
    #lhsDomFinalDemand_@{reg} = Q_U_@{reg};
    #rhsDomFinalDemand_@{reg} = (1 - omegaF_@{reg}_p) * (P_D_@{reg} / P_@{reg})^(-etaF_p)
        * FinalDemand_@{reg};
    [name = 'final demand for domestic production @{reg}']
    (lhsDomFinalDemand_@{reg} + 1) / (rhsDomFinalDemand_@{reg} + 1) = 1;

    // Import absorption: CES demand for imported final goods.
    #lhsImportFinalDemand_@{reg} = M_F_@{reg};
    #rhsImportFinalDemand_@{reg} = omegaF_@{reg}_p * (P_F_@{reg} / P_@{reg})^(-etaF_p)
        * FinalDemand_@{reg};
    [name = 'final demand for imports @{reg}']
    (lhsImportFinalDemand_@{reg} + 1) / (rhsImportFinalDemand_@{reg} + 1) = 1;

    // ------------------------------------------------------------------
    // Sector-level demand allocation
    // ------------------------------------------------------------------

    @# for sec in 1:Sectors

        // Sector import price index P_M_A: CES aggregate over subsector import prices.
        // When etaQA == 1 (Cobb-Douglas) use log-linear form; CES otherwise.
        // The +(etaQA==1) term in the CES exponent avoids 1/(1-1) when etaQA==1,
        // which is safe because that branch is multiplied by (etaQA!=1)==0.
        #lhsSectorImportPrice_@{reg}_@{sec} = P_M_A_@{sec}_@{reg};
        #rhsSectorImportPrice_@{reg}_@{sec} =
            (etaQA_@{sec}_p == 1) * exp(
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + omegaM_F_@{subsec}_@{reg}_p * log(P_M_@{subsec} / omegaM_F_@{subsec}_@{reg}_p)
            @# endfor
            )
            + (etaQA_@{sec}_p != 1) * (
            @# for subsec in Subsecstart[sec]:Subsecend[sec]
                + omegaM_F_@{subsec}_@{reg}_p * P_M_@{subsec}^(1 - etaQA_@{sec}_p)
            @# endfor
            )^(1 / (1 - etaQA_@{sec}_p + (etaQA_@{sec}_p == 1)));
        [name = 'sector import price index @{sec} @{reg}']
        (lhsSectorImportPrice_@{reg}_@{sec} + 1) / (rhsSectorImportPrice_@{reg}_@{sec} + 1) = 1;

        // Effective sector output for final demand: adds rooftop solar Q_PV to energy sector.
        #QEffFinal_@{reg}_@{sec} = Q_A_F_@{sec}_@{reg} + (@{sec} == @{SecEnergy}) * Q_PV_@{reg};

        // CES demand for sector sec's domestic output in final demand.
        #lhsSectorFinalDemand_@{reg}_@{sec} = QEffFinal_@{reg}_@{sec};
        #rhsSectorFinalDemand_@{reg}_@{sec} = omegaQA_@{sec}_@{reg}_p * A_F_@{sec}_@{reg}^(etaQ_p - 1)
            * (P_A_@{sec}_@{reg} / P_D_@{reg})^(-etaQ_p) * Q_U_@{reg};
        [name = 'final demand for sector output @{sec} @{reg}']
        (lhsSectorFinalDemand_@{reg}_@{sec} + 1) / (rhsSectorFinalDemand_@{reg}_@{sec} + 1) = 1;

        // CES demand for sector sec's imported goods in final demand.
        #lhsSectorImportDemand_@{reg}_@{sec} = M_A_F_@{sec}_@{reg};
        #rhsSectorImportDemand_@{reg}_@{sec} = omegaMA_F_@{sec}_@{reg}_p
            * (P_M_A_@{sec}_@{reg} / P_F_@{reg})^(-etaQ_p) * M_F_@{reg};
        [name = 'final demand for sector imports @{sec} @{reg}']
        (lhsSectorImportDemand_@{reg}_@{sec} + 1) / (rhsSectorImportDemand_@{reg}_@{sec} + 1) = 1;

    @# endfor

@# endfor
