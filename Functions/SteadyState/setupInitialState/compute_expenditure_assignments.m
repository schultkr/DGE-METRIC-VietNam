
function [strys, strpar] = compute_expenditure_assignments(strys, strpar, strexo)
    % Computes all expenditure-share assignments used to calibrate the steady state.
    %
    % SNA-CONSISTENT CALIBRATION CONVENTION:
    %   phiY_s_r = (GO - QI) / GO = basic-price GVA / basic-price GO, from IO table.
    %              D.29 emission taxes ARE included in the GVA numerator.
    %   phiQI, phiW, phiM  are all calibrated against basic-price GO.
    %   strys.Y  = factor-cost GVA (model P_s = P_Q - kappaE*PE*lEndoQ strips
    %              emission taxes, so strys.Y < SNA GVA at basic prices).
    %
    %   SNA basic-price GVA = strys.Y + D.29 = strys.Y + phiEFdirect_p
    %   Q0_p = SNA basic-price GO = (strys.Y + phiEFdirect_p) / phiY_p
    %
    %   All expenditure assignments use Q0_p as the base (basic-price GO):
    %     VAexp_s_r = phiY_s * Q0_p  (SNA GVA at basic prices, includes D.29)
    %     WAexp_s_r = phiW_s * Q0_p  (Compensation of Employees)
    %     QEXP_s_r  = (phiQI_s + phiY_s) * Q0_p  (basic-price gross output)
    %     MEXP      = phiM * Q0_p
    %
    %   Factor-cost GVA for production function calibration is recovered as:
    %     QEXP - QIEXP - EmExp   where EmExp = sE_s * lEndoQ_s * E0_p * PE_r
    %   (subsector-specific direct emission cost, used in compute_pf_parameters)
    %
    %   phiEFdirect_r, phiEFembedded_r, phiEF_r are kept in strpar as diagnostics
    %   and for kappaEI calibration in compute_pf_parameters.

    strpar.phiY_p = 0;
    strpar.phiEF_p = 0;
    strpar.phiEFdirect_p = 0;
    % Derive SRI wedge strength from share of SCC internalized: phiKE_p = chi * PE_ss
    if strpar.chiSRI_p > 0
        strpar.phiKE_p = strpar.chiSRI_p * strpar.PE0_p;
    end

    % --- Loop 1: accumulate phiY and emission expenditure shares ---
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strpar.(['phiEF_' sreg '_p'])         = 0;
        strpar.(['phiEFdirect_' sreg '_p'])   = 0;
        strpar.(['phiEFembedded_' sreg '_p']) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strpar.phiY_p = strpar.phiY_p + strpar.(['phiY_' ssubsec '_' sreg '_p']);

                emDirect = strpar.(['sE_' ssubsec '_' sreg '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.E0_p * strys.(['PE_' sreg]);
                strpar.(['phiEFdirect_' sreg '_p']) = strpar.(['phiEFdirect_' sreg '_p']) + emDirect;
                strpar.(['phiQI_' ssubsec '_' sreg '_p']) = 0;
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);
                    emEmbedded = strpar.(['sEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.E0_p * strys.(['PE_' sreg]);
                    strpar.(['phiEFembedded_' sreg '_p']) = strpar.(['phiEFembedded_' sreg '_p']) + emEmbedded;
                    strpar.(['phiQI_' ssubsec '_' sreg '_p']) = strpar.(['phiQI_' ssubsec '_' sreg '_p']) + strpar.(['phiQI_' ssubsec '_' sreg '_' ssecm '_p']);
                end

                strpar.(['phiEF_' sreg '_p']) = strpar.(['phiEFdirect_' sreg '_p']) + strpar.(['phiEFembedded_' sreg '_p']);
                strpar.(['phiQ_' ssubsec '_' sreg '_p']) = strpar.(['phiQI_' ssubsec '_' sreg '_p']) + strpar.(['phiY_' ssubsec '_' sreg '_p']);
            end
        end
        strpar.phiEF_p = strpar.phiEF_p + strpar.(['phiEF_' sreg '_p']);
        strpar.phiEFdirect_p = strpar.phiEFdirect_p + strpar.(['phiEFdirect_' sreg '_p']);
    end

    % Q0_p = basic-price GO = SNA basic-price GVA / phiY_p
    %      = (factor-cost GVA + D.29) / phiY_p
    %      = (strys.Y + phiEFdirect_p) / phiY_p
    % phiEFdirect_p = Σ_{s,r} sE_s * lEndoQ_s * E0_p * PE_r = total D.29 emission taxes.
    strpar.Q0_p = (strys.Y+strpar.phiEFdirect_p) / strpar.phiY_p;

    % --- Loop 2: subsectoral expenditure assignments ---
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strys.(['MEXP_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);


                

                % SNA GVA at basic prices (includes D.29 emission taxes).
                strpar.(['VAexp_' ssubsec '_' sreg '_p']) = strpar.(['phiY_' ssubsec '_' sreg '_p']) * strpar.Q0_p;

                % Labour income (Compensation of Employees).
                strpar.(['WAexp_' ssubsec '_' sreg '_p']) = strpar.(['phiW_' ssubsec '_' sreg '_p']) * strpar.Q0_p;

                % Basic-price gross output for subsector s in region r.
                % phiQI and phiY are both calibrated against basic-price GO,
                % so no EmExp addback or phiEF subtraction is needed.
                strys.(['QIEXP_' ssubsec '_' sreg]) = 0;
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);
                    strys.(['QIEXP_' ssubsec '_' sreg '_' ssecm]) = strpar.(['phiQI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.Q0_p;
                    strys.(['QIEXP_' ssubsec '_' sreg]) = strys.(['QIEXP_' ssubsec '_' sreg]) + strys.(['QIEXP_' ssubsec '_' sreg '_' ssecm]);
                end

                strys.(['QEXP_' ssubsec '_' sreg]) = strys.(['QIEXP_' ssubsec '_' sreg]) + strpar.(['VAexp_' ssubsec '_' sreg '_p']);
                % Emission intensity: physical emissions per unit real output.
                strpar.(['kappaE_' ssubsec '_' sreg '_p']) = strpar.(['sE_' ssubsec '_' sreg '_p']) * strpar.E0_p / (strys.(['QEXP_' ssubsec '_' sreg]) / strys.(['P_Q_' ssubsec '_' sreg]));
                strys.(['kappaE_' ssubsec '_' sreg]) = strpar.(['kappaE_' ssubsec '_' sreg '_p']);


                % SRI capital rental wedge (phiKE_p = 0 by default, backward compatible)
                strys.(['wedgeKE_' ssubsec '_' sreg]) = (strpar.phiKE_p + strexo.(['exo_wedgeKE_' ssubsec '_' sreg])) * strys.(['kappaE_' ssubsec '_' sreg]) ...
                    * strpar.beta_p * (1 - strpar.(['delta_' ssubsec '_' sreg '_p'])) / (1 - strpar.beta_p * (1 - strpar.(['delta_' ssubsec '_' sreg '_p'])));

                % Non-ETS emission intensity.
                strpar.(['kappaE_NOETS_' ssubsec '_' sreg '_p']) = strpar.(['sE_NOETS_' ssubsec '_' sreg '_p']) * strpar.E0_NOETS_p / (strys.(['QEXP_' ssubsec '_' sreg]) / strys.(['P_Q_' ssubsec '_' sreg]));
                strys.(['kappaE_NOETS_' ssubsec '_' sreg]) = strpar.(['kappaE_NOETS_' ssubsec '_' sreg '_p']);

                % Export shares.
                strys.(['XEXP_' ssubsec '_' sreg]) = strpar.(['phiX_' ssubsec '_' sreg '_p']) * strpar.Q0_p;

                % Import shares (phiM calibrated against basic-price GO = Q0_p).
                strys.(['MEXP_I_' ssubsec '_' sreg]) = strpar.(['phiM_I_' ssubsec '_' sreg '_p']) * strpar.Q0_p;
                strys.(['MEXP_F_' ssubsec '_' sreg]) = strpar.(['phiM_F_' ssubsec '_' sreg '_p']) * strpar.Q0_p;

                for icoregm = 1:strpar.inbregions_p
                    sregm = num2str(icoregm);
                    strys.(['QDEXP_' ssubsec '_' sregm '_' sreg]) = strpar.(['phiQ_D_' ssubsec '_' sreg '_' sregm '_p']) * (strys.(['QEXP_' ssubsec '_' sreg]) - strys.(['XEXP_' ssubsec '_' sreg]));
                end
            end
        end
    end


    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        strys.(['QEXP_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['QEXP_' sreg]) = strys.(['QEXP_' sreg]) + strys.(['QEXP_' ssubsec '_' sreg]);
            end
        end
    end


    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            strys.(['QAEXP_' ssec '_' sreg]) = 0;
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                strys.(['QDEXP_' ssubsec '_' sreg]) = 0;
                for icoregm = 1:strpar.inbregions_p
                    sregm = num2str(icoregm);
                    strys.(['QDEXP_' ssubsec '_' sreg]) = strys.(['QDEXP_' ssubsec '_' sreg]) + strys.(['QDEXP_' ssubsec '_' sreg '_' sregm]);
                end
                strys.(['QDEXP_' ssubsec '_' sreg]) = strys.(['QDEXP_' ssubsec '_' sreg]) + strys.(['MEXP_I_' ssubsec '_' sreg]);
                strys.(['QAEXP_' ssec '_' sreg]) = strys.(['QAEXP_' ssec '_' sreg]) + strys.(['QDEXP_' ssubsec '_' sreg]);
            end
        end
        strys.(['QUEXP_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            strys.(['QAIEXP_' ssec '_' sreg]) = 0;
            for icosecm = 1:strpar.inbsectors_p
                ssecm = num2str(icosecm);
                for icosubsec = strpar.(['substart_' ssecm '_p']):strpar.(['subend_' ssecm '_p'])
                    ssubsec = num2str(icosubsec);
                    strys.(['QAIEXP_' ssec '_' sreg]) = strys.(['QAIEXP_' ssec '_' sreg]) + strys.(['QIEXP_' ssubsec '_' sreg '_' ssec]);
                end
            end
            FinalSectorUse = strys.(['QAEXP_' ssec '_' sreg]) - strys.(['QAIEXP_' ssec '_' sreg]) -...
                (icosec == strpar.iSecHouse_p) * (strpar.(['sH_' sreg '_p']) * strys.Y + strys.(['I_PV_' sreg]));
            if icosec == strpar.iSecEnergy_p
                HomeProdShare = strpar.phiQPV0_p;
            else
                HomeProdShare = 0;
            end
            strys.(['QAFEXP_' ssec '_' sreg]) = FinalSectorUse * 1/(1-HomeProdShare);
            strys.(['QUEXP_' sreg]) = strys.(['QUEXP_' sreg]) + strys.(['QAFEXP_' ssec '_' sreg]);
        end
    end

end
