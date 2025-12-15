function [strys, strpar] = computeRegionalExportPriceIndex(strys, strpar)
%COMPUTEREGIONALEXPORTPRICEINDEX Computes regional CES export price indices and normalized export weights (DX).
%
% This function:
%   - Computes CES aggregate export price levels (P_Q_reg) per region
%   - Normalizes export share weights (DX) per subsector and region
%   - Stores both results in the model structures
%
% Inputs:
%   - strys  : structure of endogenous variables (must contain P_Q_subsec_reg)
%   - strpar : structure of model parameters (must contain phiX and etaX)
%
% Outputs:
%   - strys  : updated with P_Q_reg and Xshare_reg
%   - strpar : updated with DX_subsec_reg_p

    etaX = strpar.etaX_p;

    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        % Initialize share sums
        denomExportWeights = 0;
    
        % --- First pass: sum export shares and weighted price terms
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']) : strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                phiX = strpar.(['phiX_' ssubsec '_' sreg '_p']);
                P_Q = strys.(['P_Q_' ssubsec '_' sreg]);
                denomExportWeights = denomExportWeights + phiX * P_Q^(1 - etaX);
            end
        end
        % --- Second pass: compute DX weights and aggregate P_Q for region
        P_Q_reg = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']) : strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                phiX = strpar.(['phiX_' ssubsec '_' sreg '_p']);
                P_Q = strys.(['P_Q_' ssubsec '_' sreg]);
                DX = phiX * P_Q^(1 - etaX) / denomExportWeights;
                if strpar.lCalibration_p == 1
                    strpar.(['D_X_' ssubsec '_' sreg '_p']) = DX;
                end
                

                P_Q_reg = P_Q_reg + DX * P_Q^(1 - etaX);
            end
        end

        % --- Final CES aggregation
        strys.(['P_Q_' sreg]) = P_Q_reg^(1 / (1 - etaX));
    end
end
