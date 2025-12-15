function exo_simul_start = computeLFShocks(endosimbau, oo_, M_, options_)
    % function sColumn = GetExcelColumn(ipos)
    % finds the corresponding alphanumerical repsentation of a column in excel for ipos
    %
    % Inputs: 
    %   - endosimbau      [structure] simulation results of BAU scenario
    %
    % Output: 
    %   - exo_simul_start [character] exogenous simulation results 
	%
	inbregions_p = M_.params(ismember(M_.param_names, 'inbregions_p'));
    TAdjLF_p = M_.params(ismember(M_.param_names, 'TAdjLF_p'));
    etaLF_p = M_.params(ismember(M_.param_names, 'etaLF_p'));
    exo_simul_start = oo_.exo_simul_start;
    iposW = find(ismember(M_.endo_names, 'W'));
    iposLF = find(ismember(M_.endo_names, 'LF'));
    for icotime = 2:(options_.periods+2)
        denominator = 0;    
        for icoreg = 1:inbregions_p
            sreg = num2str(icoreg);
            sWage_reg = ['W_' sreg];
            sLF_reg = ['LF_' sreg];
            sExo_reg = ['exo_LF_' sreg];
            iposWreg = find(ismember(M_.endo_names, sWage_reg));
            iposLFreg = find(ismember(M_.endo_names, sLF_reg));            
            iposetaF = find(ismember(M_.param_names, 'etaF_p'));
            iposomegaReg = find(ismember(M_.param_names, ['omegaLF0_' sreg '_p']));            
            WDiff = 0;
            for iadtime = 1:TAdjLF_p
                if iadtime > 1
                    iposWregLag = find(ismember(M_.endo_names, ['AUX_ENDO_LAG_' num2str(iposWreg-1) '_' num2str(iadtime-1)]));
                    iposWLag = find(ismember(M_.endo_names, ['AUX_ENDO_LAG_' num2str(iposW-1) '_' num2str(iadtime-1)]));
                    WDifftemp = endosimbau(iposWregLag,icotime-1) / endosimbau(iposWLag,icotime-1);                                       
                else
                    iposWregLag = iposWreg;
                    iposWLag = iposW;
                    WDifftemp = endosimbau(iposWregLag,icotime-1) / endosimbau(iposWLag, icotime-1);
                end
                WDiff = WDiff + iadtime/((TAdjLF_p+1)*TAdjLF_p/2) * WDifftemp;
            end
            denominator = denominator + WDiff^(-etaLF_p) * endosimbau(iposLFreg, icotime) / M_.params(iposomegaReg);    
        end
        for icoreg = 1:inbregions_p
            sreg = num2str(icoreg);
            sWage_reg = ['W_' sreg];
            sLF_reg = ['LF_' sreg];
            sExo_reg = ['exo_LF_' sreg];
            iposWreg = find(ismember(M_.endo_names, sWage_reg));
            iposLFreg = find(ismember(M_.endo_names, sLF_reg));            
            iposexoLFreg = find(ismember(M_.exo_names, sExo_reg));            
            iposomegaReg = find(ismember(M_.param_names, ['omegaLF0_' sreg '_p']));            
            WDiff = 0;
            for iadtime = 1:TAdjLF_p
                if iadtime > 1
                    iposWregLag = find(ismember(M_.endo_names, ['AUX_ENDO_LAG_' num2str(iposWreg-1) '_' num2str(iadtime-1)]));
                    iposWLag = find(ismember(M_.endo_names, ['AUX_ENDO_LAG_' num2str(iposW-1) '_' num2str(iadtime-1)]));
                    WDifftemp = endosimbau(iposWregLag,icotime-1) / endosimbau(iposWLag, icotime-1);                                       
                else
                    iposWregLag = iposWreg;
                    iposWLag = iposW;
                    WDifftemp = endosimbau(iposWregLag, icotime-1) / endosimbau(iposWLag,icotime-1);
                end
                WDiff = WDiff + iadtime/((TAdjLF_p+1)*TAdjLF_p/2) * WDifftemp;
            end
            %exo_simul_start(icotime, iposexoLFreg) = log((WDiff^(-etaLF_p) * endosimbau(iposLFreg, icotime) / M_.params(iposomegaReg))/denominator);    
            exo_simul_start(icotime, iposexoLFreg) = log((WDiff^(-etaLF_p) * endosimbau(iposLFreg, icotime) / M_.params(iposomegaReg)));                
        end
    end
end