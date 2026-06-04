function [errorVA, errorWage] = check_allocation_errors(strys, strpar)
%CHECK_ALLOCATION_ERRORS Computes max errors in value-added and wage allocation.
%
% Calibration convention: VAexp = phiY * (Q0_p - phiEF_r) = factor-cost GVA.
% The model's Y * P0 should equal VAexp at the calibrated steady state.
% WAexp = phiW * (Q0_p - phiEF_r) = labour income (Compensation of Employees).
%
% Inputs:
%   - strys  : structure of endogenous steady-state variables
%   - strpar : structure of model parameters
%
% Outputs:
%   - errorVA   : maximum absolute error in value-added allocation (nominal)
%   - errorWage : maximum absolute error in wage allocation (nominal)

errorVA = 0;
errorWage = 0;
strpar.phiFE_p = 0;
for icoreg = 1:strpar.inbregions_p
    sreg = num2str(icoreg);
    for icosec = 1:strpar.inbsectors_p
        ssec = num2str(icosec);
        for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
            ssubsec = num2str(icosubsec);
            strpar.phiFE_p = strpar.phiFE_p + strys.(['E_' ssubsec '_' sreg]) * strys.(['PE_' sreg]);
        end
    end
end


for icoreg = 1:strpar.inbregions_p
    sreg = num2str(icoreg);
    for icosec = 1:strpar.inbsectors_p
        ssec = num2str(icosec);
        for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
            ssubsec = num2str(icosubsec);

            % Factor-cost GVA: model's Y * P0 should equal VAexp = phiY*(Q0_p-phiEF_r).
            actualVA = strys.(['Y_' ssubsec '_' sreg]) * strpar.(['P0_' ssubsec '_' sreg '_p']) + strys.(['E_' ssubsec '_' sreg]) * strys.(['PE_' sreg]);
            targetVA = strpar.(['phiY_' ssubsec '_' sreg '_p']) * (strpar.Q0_p);
            errorVA = max(errorVA, abs(actualVA - targetVA));

            % Wage check: gross nominal labour cost vs WAexp calibration target.
            actualWage = strys.(['W_' ssubsec '_' sreg]) * strys.(['N_' ssubsec '_' sreg]) * ...
                         strys.(['LF_' sreg]) * (1 + strys.(['tauNF_' ssubsec '_' sreg]));
            targetWage = strpar.(['phiW_' ssubsec '_' sreg '_p']) * (strpar.Q0_p);
            errorWage = max(errorWage, abs(actualWage - targetWage));
        end
    end
end

% Display summary
fprintf('Maximum value-added allocation error (nominal): %.4e\n', errorVA);
fprintf('Maximum wage allocation error (nominal):        %.4e\n', errorWage);

