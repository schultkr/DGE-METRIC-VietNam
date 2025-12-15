function strys = computeEmissionsAndAggregateOutput(strys, strpar)
%COMPUTEEMISSIONSANDAGGREGATEOUTPUT Computes regional and national emissions and aggregate outputs Q_A.
%
% Inputs:
%   - strys  : structure containing endogenous variables
%   - strpar : structure containing parameters
%
% Output:
%   - strys  : updated with Q_A and E values at sectoral, regional, and national level

    strys.E = 0;  % National total emissions

    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strys.(['E_' sreg]) = 0;

        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);

            % Initialize Q_A sectoral aggregate
            if strpar.(['etaQA_' ssec '_p']) == 1
                strys.(['Q_A_' ssec '_' sreg]) = 1;
            else
                strys.(['Q_A_' ssec '_' sreg]) = 0;
            end

            for icosubsec = strpar.(['substart_' ssec '_p']) : strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);

                % Aggregate Q_A (sectoral output index)
                if strpar.(['etaQA_' ssec '_p']) == 1
                    strys.(['Q_A_' ssec '_' sreg]) = strys.(['Q_A_' ssec '_' sreg]) * ...
                        strys.(['Q_D_' ssubsec '_' sreg])^strpar.(['omegaQ_' ssubsec '_' sreg '_p']);
                else
                    strys.(['Q_A_' ssec '_' sreg]) = strys.(['Q_A_' ssec '_' sreg]) + ...
                        strpar.(['omegaQ_' ssubsec '_' sreg '_p'])^(1/strpar.(['etaQA_' ssec '_p'])) * ...
                        strys.(['Q_D_' ssubsec '_' sreg])^((strpar.(['etaQA_' ssec '_p']) - 1) / strpar.(['etaQA_' ssec '_p']));
                end

                % Add direct emissions
                strys.(['E_' sreg]) = strys.(['E_' sreg]) + strys.(['E_' ssubsec '_' sreg]);

                % Add emissions from intermediate input use
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);
                    strys.(['E_' sreg]) = strys.(['E_' sreg]) + strys.(['E_I_' ssubsec '_' sreg '_' ssecm]);
                end
            end

            % Final aggregation for Q_A if eta ≠ 1
            if strpar.(['etaQA_' ssec '_p']) ~= 1
                strys.(['Q_A_' ssec '_' sreg]) = strys.(['Q_A_' ssec '_' sreg])^( ...
                    strpar.(['etaQA_' ssec '_p']) / (strpar.(['etaQA_' ssec '_p']) - 1));
            end
        end

        % Add regional emissions to national total
        strys.E = strys.E + strys.(['E_' sreg]);
    end

    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);    
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            strys.(['Q_A_I_' ssec '_' sreg]) = 0;
            for icosecm = 1:strpar.inbsectors_p
                ssecm = num2str(icosecm);
                for icosubsec = strpar.(['substart_' ssecm '_p']):strpar.(['subend_' ssecm '_p'])
                    ssubsec = num2str(icosubsec);
                    strys.(['Q_A_I_' ssec '_' sreg]) = strys.(['Q_A_I_' ssec '_' sreg]) + strys.(['Q_I_' ssubsec '_' sreg '_' ssec]) * (strys.(['P_A_' ssec '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssec '_p'])*strys.(['sF_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p'])* strys.(['PE_' sreg])) / strys.(['P_A_' ssec '_' sreg]);
                end
            end
            strys.(['Q_A_F_' ssec '_' sreg]) = strys.(['Q_A_' ssec '_' sreg]) - strys.(['Q_A_I_' ssec '_' sreg]) - strpar.(['sH_' sreg '_p']) * strys.Y / strys.(['P_A_' ssec '_' sreg]) * (icosec == strpar.iSecHouse_p);
        end

    end
    
end
