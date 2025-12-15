function [strys, strpar, strexo] = computeAggregates(strys, strpar, strexo)
    % function [strys,strpar, strexo] = computeAggregates(strys,strpar, strexo)
    % computes aggreate variables from regional and sectoral level.
    % Inputs: 
    %   - strys     [structure]  structure containing all endogeonous variables of the model
    %   - strexo    [structure]  structure containing all exogeonous variables of the model    
    %   - strpar    [structure]  structure containing all parameters of the model
    %
    % Output: 

    %   - strys     [structure] see inputs
    %   - strexo    [structure] see inputs
    
    % tax rates

    % output
    strys.Q = 0;
    for icoreg = 1:strpar.inbregions_p
        sreg =num2str(icoreg);
        strys.(['Q_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['Q_' sreg]) = strys.(['Q_' sreg]) + strys.(['Q_' ssubsec '_' sreg]) * strys.(['P_Q_' ssubsec '_' sreg]);
            end
        end
        strys.Q = strys.Q + strys.(['Q_' sreg]);
    end
    % intermediate products
    strys.Q_I = 0;
    for icoreg = 1:strpar.inbregions_p
        sreg =num2str(icoreg);
        strys.(['Q_I_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['Q_I_' sreg]) = strys.(['Q_I_' sreg]) + strys.(['P_I_' ssubsec '_' sreg]) * strys.(['Q_I_' ssubsec '_' sreg]);
            end
        end
        strys.Q_I = strys.Q_I + strys.(['Q_I_' sreg]);
    end
        
    % investments
    strys.I = 0;
    for icoreg = 1:strpar.inbregions_p
        sreg =num2str(icoreg);
        strys.(['I_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['I_' sreg]) = strys.(['I_' sreg]) + strys.(['I_' ssubsec '_' sreg])*strys.(['P_' ssubsec '_' sreg])/strys.(['P_' sreg]);
            end
        end
        strys.I = strys.I + strys.(['I_' sreg]) * strys.(['P_' sreg]);
    end
    
    % gross value added
    strys.Y = 0;
    for icoreg = 1:strpar.inbregions_p
        sreg =num2str(icoreg);
        strys.(['Y_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['Y_' sreg]) = strys.(['Y_' sreg]) + strys.(['P_' ssubsec '_' sreg]) * strys.(['Y_' ssubsec '_' sreg]);
            end
        end
        strys.Y = strys.Y + strys.(['Y_' sreg]);
    end

    % employment
    strys.N = 0;
    for icoreg = 1:strpar.inbregions_p
        sreg =num2str(icoreg);
        strys.(['N_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['N_' sreg]) = strys.(['N_' sreg]) + strys.(['N_' ssubsec '_' sreg]);
            end
        end
        strys.N = strys.N + strys.(['N_' sreg]) * strys.(['LF_' sreg])/strys.LF;
    end
    
    % exports
    strys.X = 0;
    for icoreg = 1:strpar.inbregions_p
        sreg =num2str(icoreg);
        strys.X = strys.X + strys.(['X_' sreg])*strys.(['P_Q_' sreg]);
    end
  
    
    % wages
    strys.W = 0;
    for icoreg = 1:strpar.inbregions_p
        sreg =num2str(icoreg);
        strys.(['W_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['W_' sreg]) = strys.(['W_' sreg]) + strys.(['N_' ssubsec '_' sreg]) * strys.(['W_' ssubsec '_' sreg]) / strys.(['N_' sreg]);
                strys.W = strys.W + strys.(['N_' ssubsec '_' sreg]) * strys.(['W_' ssubsec '_' sreg]) * strys.(['LF_' sreg])/ (strys.N * strys.LF);
            end
        end
    end     

    % Final national net exports
    strys.NX = strys.X - strys.M;
end


