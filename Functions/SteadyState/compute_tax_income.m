function [strys,strpar, strexo] = compute_tax_income(strys,strpar, strexo)
    % function [strys,strpar, strexo] = compute_tax_income(strys,strpar, strexo)
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
    strys.publiccapitalincome = 0;
    strys.adaptationcost = 0;
    strys.capitalexp = 0;
    
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strys.(['wagetax_' sreg]) = 0;
        strys.(['capitaltax_' sreg]) = 0;
        strys.(['publiccapitalincome_' sreg]) = 0;
        strys.(['adaptationcost_' sreg]) = 0;
        strys.(['capitalexp_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['wagetax_' sreg]) = strys.(['wagetax_' sreg]) + strys.(['W_' ssubsec '_' sreg]) * strys.(['N_' ssubsec '_' sreg]) * strys.(['LF_' sreg]) * (strys.(['tauNH_' sreg]) + strys.(['tauNF_' ssubsec '_' sreg]));
                strys.(['capitaltax_' sreg]) = strys.(['capitaltax_' sreg]) + strys.(['P_K_' ssubsec '_' sreg]) * strys.(['K_H_' ssubsec '_' sreg]) * strys.(['r_H_' ssubsec '_' sreg]) * strys.(['tauKH_' ssubsec '_' sreg]);
                strys.(['capitaltax_' sreg]) = strys.(['capitaltax_' sreg]) + strys.(['P_K_' ssubsec '_' sreg]) * strys.(['K_' ssubsec '_' sreg]) * strys.(['tauKF_' ssubsec '_' sreg]) * strys.(['r_F_' ssubsec '_' sreg]);
                kgLag = strys.(['K_G_' ssubsec '_' sreg]);
                strys.(['publiccapitalincome_' sreg]) = strys.(['publiccapitalincome_' sreg]) + ...
                    strys.(['P_K_' ssubsec '_' sreg]) ...
                    * kgLag ...
                    * strys.(['r_G_' ssubsec '_' sreg]);
                strys.(['adaptationcost_' sreg]) = strys.(['adaptationcost_' sreg]) + strys.(['G_A_' ssubsec '_' sreg]) * strys.(['P_INV_' ssubsec '_' sreg]);
                strys.(['capitalexp_' sreg]) = strys.(['capitalexp_' sreg]) + strys.(['P_K_' ssubsec '_' sreg]) * strys.(['K_' ssubsec '_' sreg]) * strys.(['r_F_' ssubsec '_' sreg]);
                % strys.(['s_G_' ssubsec '_' sreg]) = strys.(['I_G_' ssubsec '_' sreg]) * strys.(['P_K_' ssubsec '_' sreg]) ./ (strys.(['Y_' sreg]) * strys.(['P_' sreg]));
                % strexo.(['exo_s_G_' ssubsec '_' sreg]) = strys.(['s_G_' ssubsec '_' sreg]) - strpar.(['s_G_' ssubsec '_' sreg '_p']); 
            end
        end
        strys.wagetax = strys.wagetax + strys.(['wagetax_' sreg]);
        strys.capitaltax = strys.capitaltax + strys.(['capitaltax_' sreg]);
        strys.publiccapitalincome = strys.publiccapitalincome + strys.(['publiccapitalincome_' sreg]);
        strys.adaptationcost = strys.adaptationcost + strys.(['adaptationcost_' sreg]) + strys.(['G_A_DH_' sreg]);                    
        strys.capitalexp = strys.capitalexp + strys.(['capitalexp_' sreg]);
    end
end


