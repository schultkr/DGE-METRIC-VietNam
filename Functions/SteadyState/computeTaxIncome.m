function [strys,strpar, strexo] = computeTaxIncome(strys,strpar, strexo)
    % function [strys,strpar, strexo] = computeTaxIncome(strys,strpar, strexo)
    % to compute tax income from different sources.
    % Inputs: 
    %   - strys     [structure]  structure containing all endogeonous variables of the model
    %   - strexo    [structure]  structure containing all exogeonous variables of the model    
    %   - strpar    [structure]  structure containing all parameters of the model
    %
    % Output: 

    %   - strys     [structure] see inputs
    %   - strexo    [structure] see inputs
    
    strys.wagetax = 0;
    strys.capitaltax = 0;
    strys.adaptationcost = 0;
    strys.capitalexp = 0;
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strys.(['wagetax_' sreg]) = 0;
        strys.(['capitaltax_' sreg]) = 0;
        strys.(['adaptationcost_' sreg]) = 0;
        strys.(['capitalexp_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['wagetax_' sreg]) = strys.(['wagetax_' sreg]) + strys.(['W_' ssubsec '_' sreg]) * strys.(['N_' ssubsec '_' sreg]) * strys.(['LF_' sreg]) * (strys.(['tauNH_' sreg]) + strys.(['tauNF_' ssubsec '_' sreg]));
                strys.(['capitaltax_' sreg]) = strys.(['capitaltax_' sreg]) + strys.(['P_' ssubsec '_' sreg]) * strys.(['K_' ssubsec '_' sreg]) * strys.(['r_' ssubsec '_' sreg]) * (strys.(['tauKH_' sreg]) + strys.(['tauKF_' ssubsec '_' sreg]));
                strys.(['adaptationcost_' sreg]) = strys.(['adaptationcost_' sreg]) + strys.(['G_A_' ssubsec '_' sreg]);
                strys.(['capitalexp_' sreg]) = strys.(['capitalexp_' sreg]) + strys.(['P_' ssubsec '_' sreg]) * strys.(['K_' ssubsec '_' sreg]) * strys.(['r_' ssubsec '_' sreg]);
            end
        end
        strys.wagetax = strys.wagetax + strys.(['wagetax_' sreg]);
        strys.capitaltax = strys.capitaltax + strys.(['capitaltax_' sreg]);
        strys.adaptationcost = strys.adaptationcost + strys.(['adaptationcost_' sreg]) + strys.(['G_A_DH_' sreg]);                    
        strys.capitalexp = strys.capitalexp + strys.(['capitalexp_' sreg]);
    end
end


