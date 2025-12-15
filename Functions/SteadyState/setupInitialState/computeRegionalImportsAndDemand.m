function [strys, strpar] = computeRegionalImportsAndDemand(strys, strpar)
%COMPUTEREGIONALIMPORTSANDDEMAND Computes regional and sectoral imports, demand, and updates export shares.
%
% Inputs:
%   - strys  : structure of endogenous variables (to be updated)
%   - strpar : structure of parameters (some export shares will be updated)
%
% Output:
%   - strys  : updated structure with import and demand values
%   - strpar : updated structure with D_X export share parameters

    strys.M = 0;  % total imports

    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strys.(['M_' sreg]) = 0;
        strys.(['M_F_' sreg]) = 0;
        strys.(['MEXP_I_' sreg]) = 0;

        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            strys.(['M_A_F_' ssec '_' sreg]) = 0;

            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);

                % Subsectoral final goods imports
                strys.(['M_F_' ssubsec '_' sreg]) = strpar.(['phiM_F_' ssubsec '_' sreg '_p']) * ...
                    (strpar.Q0_p - strys.PE * strpar.E0_p) / strys.(['P_M_' ssubsec]);

                % Add to regional final demand imports
                strys.(['M_F_' sreg]) = strys.(['M_F_' sreg]) + ...
                    strys.(['M_F_' ssubsec '_' sreg]) * strys.(['P_M_' ssubsec]) / strys.(['P_F_' sreg]);

                % Subsectoral intermediate imports
                strys.(['M_I_' ssubsec '_' sreg]) = strpar.(['phiM_I_' ssubsec '_' sreg '_p']) * ...
                    (strpar.Q0_p - strys.PE * strpar.E0_p) / strys.(['P_M_' ssubsec]);

                % Add to regional intermediate imports
                strys.(['MEXP_I_' sreg]) = strys.(['MEXP_I_' sreg]) + ...
                    strys.(['M_I_' ssubsec '_' sreg]) * strys.(['P_M_' ssubsec]);

                % Aggregate domestic demand Q_D
                strys.(['Q_D_' ssubsec '_' sreg]) = 0;
                for icoregn = 1:strpar.inbregions_p
                    sregn = num2str(icoregn);
                    strys.(['Q_D_' ssubsec '_' sreg]) = strys.(['Q_D_' ssubsec '_' sreg]) + ...
                        (strys.(['Q_D_' ssubsec '_' sreg '_' sregn]) * strys.(['P_Q_' ssubsec '_' sregn])) / strys.(['P_D_' ssubsec '_' sreg]);
                end
                % Add intermediate imports to total domestic demand
                strys.(['Q_D_' ssubsec '_' sreg]) = strys.(['Q_D_' ssubsec '_' sreg]) + ...
                    (strys.(['M_I_' ssubsec '_' sreg]) * strys.(['P_M_' ssubsec])) / strys.(['P_D_' ssubsec '_' sreg]);

                % Export share parameter
                strpar.(['D_X_' ssubsec '_' sreg '_p']) = strys.(['X_' ssubsec '_' sreg]) / strys.(['X_' sreg]) * ...
                    ((strys.(['P_Q_' ssubsec '_' sreg]) + ...
                      0 * strys.(['kappaE_' ssubsec '_' sreg]) * ...
                      strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * ...
                      strys.(['PE_' sreg])) / strys.(['P_M_' ssubsec]))^strpar.etaX_p;

                % Sectoral imports of final goods
                strys.(['M_A_F_' ssec '_' sreg]) = strys.(['M_A_F_' ssec '_' sreg]) + ...
                    strys.(['M_F_' ssubsec '_' sreg]) * strys.(['P_M_' ssubsec]) / strys.(['P_M_A_' ssec '_' sreg]);

                % Add to total regional imports
                strys.(['M_' sreg]) = strys.(['M_' sreg]) + ...
                    (strys.(['M_F_' ssubsec '_' sreg]) + strys.(['M_I_' ssubsec '_' sreg])) * strys.(['P_M_' ssubsec]);
            end
        end

        % Add to national total imports
        strys.M = strys.M + strys.(['M_' sreg]);
    end
end
