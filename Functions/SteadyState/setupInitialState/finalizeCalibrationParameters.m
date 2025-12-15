function strpar = finalizeCalibrationParameters(strys, strpar, strexo)
%FINALIZECALIBRATIONPARAMETERS Computes final model parameters for emissions, interest, labor utility, and productivity.
%
% Inputs:
%   - strys  : structure of endogenous variables
%   - strpar : structure of parameters (to be updated)
%   - strexo : structure of exogenous variables (for productivity shocks)
%
% Output:
%   - strpar : updated parameter structure with final calibration values

    % 1. Initial emissions level
    strpar.E0_p = strys.E;

    % 2. Foreign interest rate in steady state
    strpar.rf0_p = (1 / strpar.beta_p) - 1 + strpar.deltaB_p;

    % 3. Labor disutility weights ω_LF
    denominator = 0;
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        denominator = denominator + ...
            strys.(['LF_' sreg]) * strys.(['W_' sreg])^(-strpar.etaLF_p);
    end

    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strpar.(['omegaLF0_' sreg '_p']) = ...
            strys.(['LF_' sreg]) * strys.(['W_' sreg])^(-strpar.etaLF_p) / denominator;
    end

    % 4. Labor share in utility function and productivity decomposition
    for icosec = 1:strpar.inbsectors_p
        ssec = num2str(icosec);
        for icoreg = 1:strpar.inbregions_p
            sreg = num2str(icoreg);
            for icosubsec = strpar.(['substart_' ssec '_p']) : strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);

                % Labor disutility scaling parameter
                strpar.(['phiL_' ssubsec '_' sreg '_p']) = ...
                    (1 - strys.(['tauNH_' sreg])) * ...
                    strys.(['W_' ssubsec '_' sreg]) * ...
                    strys.(['LF_' sreg]) / strys.(['PoP_' sreg]) * ...
                    strys.(['lambda_' sreg]) / ...
                    (strys.(['A_N_' ssubsec '_' sreg]) * strys.(['N_' ssubsec '_' sreg])^strpar.sigmaL_p);

                % Productivity decomposition (A = A_p * KG^φ_G * exp(shock))
                strpar.(['A_' ssubsec '_' sreg '_p']) = ...
                    strys.(['A_' ssubsec '_' sreg]) / ...
                    (strys.(['KG_' sreg])^strpar.phiG_p * exp(strexo.(['exo_' ssubsec '_' sreg])));
            end
        end
    end
end
