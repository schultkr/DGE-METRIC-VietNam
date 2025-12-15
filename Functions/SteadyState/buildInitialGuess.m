function [xstart_vec, strys, strpar] = buildInitialGuess(strys, strexo, strpar, mode)
%BUILDINITIALGUESS Constructs initial guess vector for the steady state solver.
%
% Inputs:
%   - strys : structure of endogenous variable values
%   - strexo : structure of exogenous variable values
%   - strpar : structure of model parameters
%   - mode : string flag, one of {'fullSS', 'hybrid', 'calibrate'}
%
% Output:
%   - xstart_vec : concatenated vector of initial guesses

    sMaxsec = num2str(strpar.inbsectors_p);
    subend_max = strpar.(['subend_' sMaxsec '_p']);
    R = strpar.inbregions_p;
    strpar.InitGuess = cell2struct(num2cell(NaN(size(fieldnames(strys)))), fieldnames(strys), 1);
    icoguess = 0;
    switch mode
        case 'calibrate'
            % === Simplified calibration mode: only phiY guesses ===
            
            for icoreg = 1:R
                sreg = num2str(icoreg);
                for icosec = 1:strpar.inbsectors_p
                    ssec = num2str(icosec);
                    for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                        ssubsec = num2str(icosubsec);
                        icoguess = icoguess + 1;
                        % Set initial guess = 1 for all phiY entries
                        strpar.(['phiY_' ssubsec '_' sreg '_p']) = strpar.(['phiY0_' ssubsec '_' sreg '_p']);
                        strpar.InitGuess.(['P_Q_' ssubsec '_' sreg]) = strpar.(['P0_Q_' ssubsec '_' sreg '_p']);
                    end
                end
            end

        otherwise
            % === Shared core logic for fullSS and hybrid ===
            icoguess = 0;
            for icosec = 1:strpar.inbsectors_p
                ssec = num2str(icosec);
                for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                    ssubsec = num2str(icosubsec);
                    for icoreg = 1:R
                        sreg = num2str(icoreg);
                        icoguess = icoguess + 1;

                        switch mode
                            case 'fullSS'
                                strpar.InitGuess.(['K_' ssubsec '_' sreg]) = strys.(['K_' ssubsec '_' sreg]);
                                strpar.InitGuess.(['Q_I_' ssubsec '_' sreg]) = strys.(['Q_I_' ssubsec '_' sreg]);
                                strpar.InitGuess.(['X_' ssubsec '_' sreg]) = strys.(['X_' ssubsec '_' sreg]);
                            case 'hybrid'
                                if strpar.(['etaNK_' ssubsec '_' sreg '_p']) ~= 1
                                    strpar.InitGuess.(['K_' ssubsec '_' sreg]) = strys.(['K_' ssubsec '_' sreg]);
                                else
                                    strpar.InitGuess.(['A_N_' ssubsec '_' sreg]) = strys.(['A_N_' ssubsec '_' sreg]);
                                end
                                % strpar.InitGuess.(['A_I_' ssubsec '_' sreg]) = strys.(['A_I_' ssubsec '_' sreg]);
                                %strpar.InitGuess.(['Q_I_' ssubsec '_' sreg]) = strys.(['Q_I_' ssubsec '_' sreg]);   
                                strpar.InitGuess.(['D_X_' ssubsec '_' sreg]) = strys.(['D_X_' ssubsec '_' sreg]);                                
                                strpar.InitGuess.(['kappaE_' ssubsec '_' sreg]) = strys.(['kappaE_' ssubsec '_' sreg]);                                
                        end
                        strpar.InitGuess.(['P_Q_' ssubsec '_' sreg]) = strys.(['P_Q_' ssubsec '_' sreg]);
                    end
                end
            end

            for icoreg = 1:R
                sreg = num2str(icoreg);
                strpar.InitGuess.(['sF_' sreg]) = strys.(['Q_D_' strpar.ssubsecfossil '_' sreg])/ strys.(['Q_A_' strpar.ssecenergy '_' sreg]);
                switch mode
                    case 'fullSS'
                        strpar.InitGuess.(['Q_U_' sreg]) = strys.(['Q_U_' sreg]);
                    case 'hybrid'
                        strpar.InitGuess.(['Q_U_' sreg]) = strys.(['Q_U_' sreg]);
                        strpar.InitGuess.(['EE_' sreg]) = strys.(['EE_' sreg]);
                end
            end

            % === Optional A vector (lEndoQ == 0) ===
            strys.lEndoQvec = false(subend_max * R, 1);
            for icosec = 1:strpar.inbsectors_p
                ssec = num2str(icosec);
                for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                    ssubsec = num2str(icosubsec);
                    for icoreg = 1:R
                        sreg = num2str(icoreg);
                        icoguess = icoreg + (icosubsec - 1) * R;
                        strys.lEndoQvec(icoguess) = strpar.(['lEndoQ_' ssubsec '_' sreg '_p']);
                        if ~strys.lEndoQvec(icoguess)
                            strpar.InitGuess.(['A_' ssubsec '_' sreg]) = strys.(['A_' ssubsec '_' sreg]);
                        end
                    end
                end
            end

            % === Optional LF vector ===
            if strpar.lEndoMig_p == 1
                for icoreg = 1:R
                    sreg = num2str(icoreg);
                    strpar.InitGuess.(['LF_' sreg]) = strys.(['LF_' sreg]);
                end
            end

            % === Optional final elements: G, PE, Tr, tauS, H ===

            % Government spending
            if strpar.phiG_p > 0
                for icoreg = 1:R
                    sreg = num2str(icoreg);
                    strpar.InitGuess.(['G_' sreg]) = strys.(['G_' sreg]);
                end
            end

            % Emissions pricing
            if strexo.exo_CapTradeInternat == 1 && strpar.lEndogenousY_p == 1
                strpar.InitGuess.PE = strys.PE;
            else
                for icoreg = 1:R
                    sreg = num2str(icoreg);
                    if strexo.(['exo_CapTrade_' sreg]) == 1% && strpar.lEndogenousY_p == 1
                        strpar.InitGuess.(['PE_' sreg]) = strys.(['PE_' sreg]);
                    end
                end
            end

            % Transfers and taxes
            for icoreg = 1:R
                sreg = num2str(icoreg);
                if strexo.(['exo_tauSTr_' sreg]) > 0
                    strpar.InitGuess.(['Tr_' sreg]) = strys.(['Tr_' sreg]);
                end
                if strexo.(['exo_tauS_' sreg]) > 0
                    strpar.InitGuess.(['tauS_' sreg]) = strys.(['tauS_' sreg]);
                end
            end

            % Housing
            if strpar.iSecHouse_p ~= 0
                for icoreg = 1:R
                    sreg = num2str(icoreg);
                    if strpar.lEndogenousY_p == 1
                        strpar.InitGuess.(['H_' sreg]) = strys.(['H_' sreg]);
                    else
                        strpar.InitGuess.(['PH_' sreg]) = strys.(['PH_' sreg]);
                    end
                end
            end
    end
    fn = fieldnames(strpar.InitGuess);
    toRemove = fn(structfun(@(x) isnumeric(x) && isscalar(x) && isnan(x), strpar.InitGuess));
    strpar.InitGuess = rmfield(strpar.InitGuess, toRemove);
    xstart_vec = struct2array(strpar.InitGuess);
end
