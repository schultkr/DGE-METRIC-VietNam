function [strys, strexo] = initializeSectoralAggregation(strys, strpar, strexo)
    % Initialize aggregate variables
    strys.M_I = 0;
    strys.E   = 0;
    strys.Tr  = 0;

    % Loop over all regions
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strys.(['M_I_' sreg]) = 0;
        strys.(['E_' sreg])   = 0;

        % Loop over all sectors
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);

            % Final demand component of sectoral production
            rho_p  = (strpar.etaQ_p-1)/strpar.etaQ_p;
            strys.(['Q_A_F_' ssec '_' sreg]) = strpar.(['omegaQA_' ssec '_' sreg '_p']) *  strys.(['A_F_' ssec '_' sreg])^(strpar.etaQ_p-1) * ...
                (strys.(['P_A_' ssec '_' sreg]) / strys.(['P_D_' sreg]))^(-strpar.etaQ_p) * ...
                strys.(['Q_U_' sreg]);

            % Initialize intermediate input component
            strys.(['Q_A_I_' ssec '_' sreg]) = 0;

            % Loop over intermediate input sources
            for icosecm = 1:strpar.inbsectors_p
                ssecm = num2str(icosecm);
                for icosubsec = strpar.(['substart_' ssecm '_p']):strpar.(['subend_' ssecm '_p'])
                    ssubsec = num2str(icosubsec);

                    % Adjusted price including emissions cost
                    PAgrosstemp = strys.(['P_A_' ssec '_' sreg]) + ...
                        strpar.(['kappaEI_' ssubsec '_' sreg '_' ssec '_p']) * ...
                        strys.(['sF_' sreg]) * ...
                        exp(strexo.(['exo_EI_' ssubsec '_' sreg '_' ssec])) * ...
                        strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * ...
                        strys.(['PE_' sreg]);

                    % Add intermediate input value
                    strys.(['Q_A_I_' ssec '_' sreg]) = strys.(['Q_A_I_' ssec '_' sreg]) + ...
                        strys.(['Q_I_' ssubsec '_' sreg '_' ssec]) * PAgrosstemp / strys.(['P_A_' ssec '_' sreg]);

                    % Accumulate emissions
                    strys.(['E_' sreg]) = strys.(['E_' sreg]) + strys.(['E_I_' ssubsec '_' sreg '_' ssec]);
                end
            end

            % Total sectoral production = intermediate + final + household (if matching)
            strys.(['Q_A_' ssec '_' sreg]) = strys.(['Q_A_I_' ssec '_' sreg]) + ...
                strys.(['Q_A_F_' ssec '_' sreg]) + ...
                (strpar.iSecHouse_p == icosec) * strys.(['IH_' sreg]) * strys.(['PH_' sreg]) / strys.(['P_A_' ssec '_' sreg]);

            % Subsector-level disaggregation
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);

                % Add direct emissions from subsector
                strys.(['E_' sreg]) = strys.(['E_' sreg]) + strys.(['E_' ssubsec '_' sreg]);

                % Subsector output demand
                strys.(['Q_D_' ssubsec '_' sreg]) = strpar.(['omegaQ_' ssubsec '_' sreg '_p']) * ...
                    (strys.(['P_D_' ssubsec '_' sreg]) / strys.(['P_A_' ssec '_' sreg]))^(-strpar.(['etaQA_' ssec '_p'])) * ...
                    strys.(['Q_A_' ssec '_' sreg]);

                % Regional demand disaggregation
                for icoregm = 1:strpar.inbregions_p
                    sregm = num2str(icoregm);
                    strys.(['Q_D_' ssubsec '_' sreg '_' sregm]) = strpar.(['omegaQ_' ssubsec '_' sreg '_' sregm '_p']) * ...
                        (strys.(['P_Q_' ssubsec '_' sregm]) / strys.(['P_D_' ssubsec '_' sreg]))^(-strpar.(['etaQ_' ssubsec '_p'])) * ...
                        strys.(['Q_D_' ssubsec '_' sreg]);
                end

                % Imports for subsector
                strys.(['M_I_' ssubsec '_' sreg]) = strpar.(['omegaM_' ssubsec '_' sreg '_p']) * ...
                    (strys.(['P_M_' ssubsec]) / strys.(['P_D_' ssubsec '_' sreg]))^(-strpar.(['etaQ_' ssubsec '_p'])) * ...
                    strys.(['Q_D_' ssubsec '_' sreg]);

                % Aggregate regional imports
                strys.(['M_I_' sreg]) = strys.(['M_I_' sreg]) + strys.(['M_I_' ssubsec '_' sreg]) * strys.(['P_M_' ssubsec]);
            end
        end
        % if strpar.lCalibration_p == 2 && strexo.(['exo_CapTrade_' sreg])~=0
        %     strexo.(['exo_EBase_' sreg]) = log(strys.(['E_' sreg])/strpar.(['E0_' sreg '_p']));
        % end

        % Aggregate total imports and emissions across all regions
        strys.M_I = strys.M_I + strys.(['M_I_' sreg]);
        strys.E   = strys.E   + strys.(['E_' sreg]);
    end
end
