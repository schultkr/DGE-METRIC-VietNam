function strys = compute_government_expenditure_and_capital(strys, strpar)
    strys.G = 0;
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        Q_U_market = strys.(['Q_U_' sreg]) * strys.(['P_D_' sreg]) - strys.(['Q_PV_' sreg]) * strys.(['P_A_' num2str(strpar.iSecEnergy_p) '_' sreg]);
        strys.(['G_' sreg]) = ...
            Q_U_market / strys.(['P_' sreg]) + ...
            strys.(['M_F_' sreg]) * strys.(['P_F_' sreg]) / strys.(['P_' sreg]) - ...
            strys.(['C_' sreg]) - strys.(['I_' sreg]) - strys.(['I_G_' sreg]) - ...
            (strpar.iSecHouse_p == 0) * (strys.(['PH_' sreg]) / strys.(['P_' sreg]) * strys.(['IH_' sreg])+strys.(['I_PV_' sreg]) / strys.(['P_' sreg]));

        strys.(['KG_' sreg]) = strys.(['G_' sreg]) / strpar.deltaKG_p;
        strys.G = strys.G + strys.(['G_' sreg]) * strys.(['P_' sreg]);
    end

end
