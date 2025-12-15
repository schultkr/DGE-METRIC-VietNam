function fval_vec = evaluatePriceConsistency(strys, strpar)
%EVALUATEPRICECONSISTENCY Computes residuals between implied and observed price levels.
%
% Inputs:
%   - strys  : structure of endogenous variables (including prices)
%   - strpar : structure of parameters
%
% Output:
%   - fval_vec : residual vector indicating inconsistency between implied and given P_Q

    numSubsec = strpar.(['subend_' num2str(strpar.inbsectors_p) '_p']);
    numRegions = strpar.inbregions_p;
    fval_vec = nan(numRegions * numSubsec, 1);

    for icoreg = 1:numRegions
        sreg = num2str(icoreg);
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                icovec = icosubsec + (icoreg - 1) * numSubsec;

                rhs = strys.(['P_Q_' ssubsec '_' sreg]) - ...
                      strpar.(['kappaE_' ssubsec '_' sreg '_p']) * ...
                      strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * ...
                      strys.(['PE_' sreg]);

                if strpar.(['etaI_' ssubsec '_p']) == 1
                    lhs = (strys.(['P_I_' ssubsec '_' sreg]) / strpar.(['omegaQI_' ssubsec '_' sreg '_p']))^strpar.(['omegaQI_' ssubsec '_' sreg '_p']) * ...
                          (strys.(['P_' ssubsec '_' sreg]) / (1 - strpar.(['omegaQI_' ssubsec '_' sreg '_p'])))^(1 - strpar.(['omegaQI_' ssubsec '_' sreg '_p']));
                else
                    lhs = (strys.(['P_I_' ssubsec '_' sreg])^(1 - strpar.(['etaI_' ssubsec '_p'])) * strpar.(['omegaQI_' ssubsec '_' sreg '_p']) + ...
                          strys.(['P_' ssubsec '_' sreg])^(1 - strpar.(['etaI_' ssubsec '_p'])) * (1 - strpar.(['omegaQI_' ssubsec '_' sreg '_p'])))^(1 / (1 - strpar.(['etaI_' ssubsec '_p'])));
                end

                fval_vec(icovec) = 1 - lhs / rhs;
            end
        end
    end
end