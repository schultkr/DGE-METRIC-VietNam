
function [strys,strpar] = compute_pf_parameters(strys,strpar, strexo)
    % function [strpar, strys] = compute_pf_parameters(strys,strexo,strpar)
    % calibrates the parameters of the production functions of DGE_Model.mod
    % Inputs: 
    %   - strys     [structure]  endogeonous variables of the model
    %   - strpar    [structure]  parameters of the model
    %
    % Output: 
    %   - strys     [structure]  see inputs
    %   - strpar    [structure]  see inputs

    [strys, strpar] = compute_expenditure_assignments(strys, strpar, strexo);



% End of expenditure shares 
for icoreg = 1:strpar.inbregions_p
    sreg = num2str(icoreg);   
    for icosec = 1:strpar.inbsectors_p
        ssec = num2str(icosec);
        % subsectoral interat rate
        for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
            ssubsec = num2str(icosubsec);
            if strpar.(['etaQ_' ssubsec '_p']) ==1
                % intitalize subsectoral price inde
                strys.(['P_D_' ssubsec '_' sreg]) = 1;

            else
                % intitalize subsectoral price index
                strys.(['P_D_' ssubsec '_' sreg]) = 0;
            end 

            for icoregn = 1:strpar.inbregions_p
                sregn = num2str(icoregn);
                % compute distribution parameters across regions in one subsector sectors
                tempdenom = strys.(['P_Q_' ssubsec '_' sregn])^(strpar.(['etaQ_' ssubsec '_p'])-1) * strys.(['QDEXP_' ssubsec '_' sreg '_' sregn]);
                tempnums = zeros(1, strpar.inbregions_p);
                for icoregm = 1:strpar.inbregions_p
                    sregm = num2str(icoregm);
                    % compute numerator for distribution parameters across regions in one subsector
                    tempnum = strys.(['P_Q_' ssubsec '_' sregm])^(strpar.(['etaQ_' ssubsec '_p'])-1) * strys.(['QDEXP_' ssubsec '_' sreg '_' sregm]);
                    tempnums(icoregm) = tempnum;
                end
                % distribution parameters across regions in one subsector sectors                    
                extra_terms = strys.(['P_M_' ssubsec])^(strpar.(['etaQ_' ssubsec '_p'])-1) * strys.(['MEXP_I_' ssubsec '_' sreg]);
                strpar.(['omegaQ_' ssubsec '_' sreg '_' sregn '_p']) = ces_compute_weight(tempdenom, tempnums, extra_terms);

                if strpar.(['etaQ_' ssubsec '_p']) ==1
                    % aggregate price index across region in one sbsector
                    strys.(['P_D_' ssubsec '_' sreg]) = strys.(['P_D_' ssubsec '_' sreg]) * (strys.(['P_Q_' ssubsec '_' sregn])/strpar.(['omegaQ_' ssubsec '_' sreg '_' sregn '_p']))^strpar.(['omegaQ_' ssubsec '_' sreg '_' sregn '_p']);
                else
                    % aggregate price index across region in one sbsector
                    strys.(['P_D_' ssubsec '_' sreg]) = strys.(['P_D_' ssubsec '_' sreg]) + strpar.(['omegaQ_' ssubsec '_' sreg '_' sregn '_p']) * strys.(['P_Q_' ssubsec '_' sregn])^(1 - strpar.(['etaQ_' ssubsec '_p']));
                end                  

            end

            tempdenom = strys.(['P_M_' ssubsec])^(strpar.(['etaQ_' ssubsec '_p'])-1) * strys.(['MEXP_I_' ssubsec '_' sreg]);
            tempnums = zeros(1, strpar.inbregions_p);
            for icoregm = 1:strpar.inbregions_p
                sregm = num2str(icoregm);
                % compute numerator for distribution parameters across regions in one subsector
                tempnum = strys.(['P_Q_' ssubsec '_' sregm])^(strpar.(['etaQ_' ssubsec '_p'])-1) * strys.(['QDEXP_' ssubsec '_' sreg '_' sregm]);
                tempnums(icoregm) = tempnum;
            end
            % distribution parameters across regions in one subsector sectors                    
            extra_terms = strys.(['P_M_' ssubsec])^(strpar.(['etaQ_' ssubsec '_p'])-1) * strys.(['MEXP_I_' ssubsec '_' sreg]);
            strpar.(['omegaM_' ssubsec '_' sreg '_p']) = ces_compute_weight(tempdenom, tempnums, extra_terms);

            if strpar.(['etaQ' '_' ssubsec '_p']) ==1
                % aggregate price index across region in one subsector
                strys.(['P_D_' ssubsec '_' sreg]) = strys.(['P_D_' ssubsec '_' sreg]) * (strys.(['P_M_' ssubsec])/strpar.(['omegaM_' ssubsec '_' sreg '_p']))^strpar.(['omegaM_' ssubsec '_' sreg '_p']);                    

            else
                % aggregate price index across region in one subsector
                strys.(['P_D_' ssubsec '_' sreg]) = strys.(['P_D_' ssubsec '_' sreg]) + strpar.(['omegaM_' ssubsec '_' sreg '_p']) * strys.(['P_M_' ssubsec])^(1 - strpar.(['etaQ_' ssubsec '_p']));

                % aggregate price index across region in one sbsector
                strys.(['P_D_' ssubsec '_' sreg]) = strys.(['P_D_' ssubsec '_' sreg])^(1/(1 - strpar.(['etaQ_' ssubsec '_p'])));
            end
        end
    end
end

% compute sector aggregate price levels and distribution parameters for
% each sub sector in the aggregate sector
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);   
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            if strpar.(['etaQA' '_' ssec '_p'])==1
                strys.(['P_A_' ssec '_' sreg]) = 1;
            else
                strys.(['P_A_' ssec '_' sreg]) = 0;
            end

            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                % compute auxiliary expression to compute distribution
                % parameters across subsectors in one sector (denominator)
                tempdenom = strys.(['P_D_' ssubsec '_' sreg])^(strpar.(['etaQA' '_' ssec '_p'])-1) * strys.(['QDEXP_' ssubsec '_' sreg]);
                tempnums = zeros(1, strpar.(['subend_' ssec '_p'])-strpar.(['substart_' ssec '_p'])+1);
                idx = 1;
                for icosubsecm = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                    ssubsecm = num2str(icosubsecm);
                    % compute auxiliary expression to compute distribution
                    % parameters across subsectors in one sector (numerator)
                    tempnum = strys.(['P_D_' ssubsecm '_' sreg])^(strpar.(['etaQA' '_' ssec '_p'])-1) * strys.(['QDEXP_' ssubsecm '_' sreg]);
                    % compute inverse distribution parameters across subsectors in one sector
                    tempnums(idx) = tempnum;
                    idx = idx + 1;
                end
                % compute distribution parameters across subsectors in one sector
                strpar.(['omegaQ_' ssubsec '_' sreg '_p']) = ces_compute_weight(tempdenom, tempnums, []);
                if strpar.(['etaQA' '_' ssec '_p']) ==1
                    % aggregate  sectoral price level
                    strys.(['P_A_' ssec '_' sreg]) = strys.(['P_A_' ssec '_' sreg]) * (strys.(['P_D_' ssubsec '_' sreg])/(strys.(['A_D_' ssubsec '_' sreg])*strpar.(['omegaQ_' ssubsec '_' sreg '_p'])))^strpar.(['omegaQ_' ssubsec '_' sreg '_p']);                    
                else

                    % aggregate  sectoral price level
                    strys.(['P_A_' ssec '_' sreg]) = strys.(['P_A_' ssec '_' sreg]) + strpar.(['omegaQ_' ssubsec '_' sreg '_p']) * (strys.(['P_D_' ssubsec '_' sreg])/strys.(['A_D_' ssubsec '_' sreg]))^(1 - strpar.(['etaQA' '_' ssec '_p']));
                end
            end
            if strpar.(['etaQA' '_' ssec '_p']) ~=1
                % aggregate  sectoral price level
                strys.(['P_A_' ssec '_' sreg]) = strys.(['P_A_' ssec '_' sreg])^(1/(1 - strpar.(['etaQA' '_' ssec '_p'])));            
            end
        end
    end

    ssubsecfossil = num2str(strpar.iSubsecFossil_p);
    ssecenergy = num2str(strpar.iSecEnergy_p);
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);    
        strys.(['sF_' sreg]) = (strys.(['QDEXP_' strpar.ssubsecfossil '_' sreg])/strys.(['P_D_' ssubsecfossil '_' sreg])) / (strys.(['QAEXP_' ssecenergy '_' sreg])/strys.(['P_A_' strpar.ssecenergy '_' sreg]));
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);        
                % Direct emission expenditure for this subsector: PE * sE * lEndoQ * E0.
                % Using the subsector-specific cost (not the regional aggregate phiEF_r)
                % is required for SNA consistency when multiple sectors have sE > 0.
                EmExp = strpar.(['sE_' ssubsec '_' sreg '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.E0_p * strys.(['PE_' sreg]);
                if strpar.(['etaIA_' ssubsec '_p']) ==1
                    strys.(['P_I_' ssubsec '_' sreg]) = 1;
                else
                    strys.(['P_I_' ssubsec '_' sreg]) = 0;
                end
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);
                    % Embedded emission cost from using sector m intermediates:
                    % sEI_s_m * lEndoQ_s * E0_p * PE_r (subsector-specific, not phiEF_r).
                    strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) = (strpar.(['sEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.E0_p) / (strys.(['sF_' sreg])*(strys.(['QIEXP_' ssubsec '_' sreg '_' ssecm])-strpar.(['sEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.E0_p * strys.(['PE_' sreg]))/strys.(['P_A_' ssecm '_' sreg]));
                    PEefftemp = strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['sF_' sreg]) * strys.(['PE_' sreg]);
                    PAgrosstemp = strys.(['P_A_' ssecm '_' sreg]) + PEefftemp;
                    tempdenom = (PAgrosstemp/strys.(['A_I_' ssubsec '_' sreg '_' ssecm']))^(strpar.(['etaIA_' ssubsec '_p'])-1) * strys.(['QIEXP_' ssubsec '_' sreg '_' ssecm']);        
                    tempnums = zeros(1, strpar.inbsectors_p);
                    for icosecn = 1:strpar.inbsectors_p
                        ssecn = num2str(icosecn);                    
                        PAgrosstemp = strys.(['P_A_' ssecn '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecn '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['sF_' sreg]) * strys.(['PE_' sreg]);
                        % compute sectoral distribution parameters
                        tempnum = (PAgrosstemp/strys.(['A_I_' ssubsec '_' sreg '_' ssecn']))^(strpar.(['etaIA_' ssubsec '_p'])-1) * strys.(['QIEXP_' ssubsec '_' sreg '_' ssecn']);             
                        % compute sectoral distribution parameters
                        tempnums(icosecn) = tempnum;                        
                    end
                    % compute sectoral distribution parameters
                    strpar.(['omegaQI_' ssubsec '_' sreg '_' ssecm '_p']) = ces_compute_weight(tempdenom, tempnums, []);
                    PAgrosstemp = (strys.(['P_A_' ssecm '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['sF_' sreg]) * strys.(['PE_' sreg]))/strys.(['A_I_' ssubsec '_' sreg '_' ssecm']);
                    if strpar.(['etaIA_' ssubsec '_p']) ==1
                        strys.(['P_I_' ssubsec '_' sreg]) = strys.(['P_I_' ssubsec '_' sreg]) * (PAgrosstemp/strpar.(['omegaQI_' ssubsec '_' sreg '_' ssecm '_p']))^strpar.(['omegaQI_' ssubsec '_' sreg '_' ssecm '_p']);
                    else
                        strys.(['P_I_' ssubsec '_' sreg]) = strys.(['P_I_' ssubsec '_' sreg]) + strpar.(['omegaQI_' ssubsec '_' sreg '_' ssecm '_p']) * PAgrosstemp^(1 - strpar.(['etaIA_' ssubsec '_p']));
                    end                        
                end
                if strpar.(['etaIA_' ssubsec '_p']) ~=1
                    strys.(['P_I_' ssubsec '_' sreg]) = strys.(['P_I_' ssubsec '_' sreg])^(1/(1-strpar.(['etaIA_' ssubsec '_p'])));
                end
                if strpar.(['etaI_' ssubsec '_p']) ==1

                    % compute distribution parameter for production function for intermedate products
                    strpar.(['omegaQI_'  ssubsec '_' sreg '_p']) = strys.(['QIEXP_'  ssubsec '_' sreg]) /(strys.(['QEXP_'  ssubsec '_' sreg])*(1 - strys.(['kappaE_' ssubsec '_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]) / strys.(['P_Q_' ssubsec '_' sreg])));

                    % shadow price for gross value added in the subsector and region                    
                    strys.(['P_'  ssubsec '_' sreg]) = (((strys.(['P_Q_'  ssubsec '_' sreg]) - strys.(['kappaE_' ssubsec '_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]))/ ...
                        (strys.(['P_I_'  ssubsec '_' sreg])/strpar.(['omegaQI_'  ssubsec '_' sreg '_p']))^strpar.(['omegaQI_'  ssubsec '_' sreg '_p']))^(1/(1 - strpar.(['omegaQI_'  ssubsec '_' sreg '_p']))))*... 
                        (1 - strpar.(['omegaQI_'  ssubsec '_' sreg '_p']));

                else
                    % shadow price for gross value added in the subsector and region
                    etaI_val   = strpar.(['etaI_' ssubsec '_p']);
                    P_QA_calib = strys.(['P_Q_' ssubsec '_' sreg]) - strys.(['kappaE_' ssubsec '_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]);
                    QEXP_val   = strys.(['QEXP_' ssubsec '_' sreg]);
                    QIEXP_val  = strys.(['QIEXP_' ssubsec '_' sreg]);
                    P_I_val    = strys.(['P_I_' ssubsec '_' sreg]);
                    numerCalib = P_QA_calib^(etaI_val-1) * QEXP_val * (1 - strys.(['kappaE_' ssubsec '_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]) / strys.(['P_Q_' ssubsec '_' sreg])) - ...
                                 P_I_val^(etaI_val-1) * QIEXP_val;
                    denomCalib = QEXP_val - QIEXP_val - EmExp;
                    if numerCalib / denomCalib <= 0
                        fprintf('[DIAG compute_pf_params] subsec=%s reg=%s etaI=%.3f P_QA=%.4f P_I=%.4f QEXP=%.4g QIEXP=%.4g numer/denom=%.6g => P undefined!\n', ...
                            ssubsec, sreg, etaI_val, P_QA_calib, P_I_val, QEXP_val, QIEXP_val, numerCalib/denomCalib);
                    end
                    strys.(['P_'  ssubsec '_' sreg]) = (numerCalib / denomCalib)^(1/(etaI_val-1));

                    % auxiliary variable to compute distribution parameter
                    tempQI = strys.(['P_I_'  ssubsec '_' sreg])^(etaI_val-1) * QIEXP_val;

                    % auxiliary variable to compute distribution parameter
                    tempY = strys.(['P_'  ssubsec '_' sreg])^(etaI_val-1) * denomCalib;

                    % compute distribution parameter for production function for intermedate products
                    strpar.(['omegaQI_'  ssubsec '_' sreg '_p']) = tempQI /(tempQI + tempY);
                    fprintf('[DIAG compute_pf_params] subsec=%s reg=%s etaI=%.3f  P=%.4f  P_I=%.4f  omegaQI=%.4f\n', ...
                        ssubsec, sreg, etaI_val, strys.(['P_' ssubsec '_' sreg]), P_I_val, strpar.(['omegaQI_' ssubsec '_' sreg '_p']));

                end 

                PK_base = strys.(['P_' ssubsec '_' sreg]);
                strys.(['P_K_' ssubsec '_' sreg]) = PK_base;
                if isfield(strpar, 'lCapGoodsSecPrice_p') && strpar.lCapGoodsSecPrice_p == 1
                    strys.(['P_INV_' ssubsec '_' sreg]) = strpar.(['P0_' ssubsec '_' sreg '_p']);% * strys.(['P_Q_' num2str(strpar.iCapGoodsSubsec_p) '_' sreg])/strpar.(['P0_Q_' num2str(strpar.iCapGoodsSubsec_p) '_' sreg '_p']) * exp(strexo.(['exo_P_K_' ssubsec '_' sreg]));
                else
                    strys.(['P_INV_' ssubsec '_' sreg]) = strys.(['P_' ssubsec '_' sreg]);
                end

                strpar.(['P0_'  ssubsec '_' sreg '_p']) = strys.(['P_'  ssubsec '_' sreg]);
            end      
        end
    end    



    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);   
        if strpar.etaQ_p == 1
            strys.(['P_D_' sreg]) = 1;
        else
            strys.(['P_D_' sreg]) = 0;
        end

        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            % compute sectoral distribution parameters
            tempdenom = strys.(['P_A_' ssec '_' sreg])^(strpar.etaQ_p-1) * strys.(['QAFEXP_' ssec '_' sreg]);        
            tempnums = zeros(1, strpar.inbsectors_p);

            for icosecm = 1:strpar.inbsectors_p
                ssecm = num2str(icosecm);
                % compute sectoral distribution parameters
                tempnum = strys.(['P_A_' ssecm '_' sreg])^(strpar.etaQ_p-1) * strys.(['QAFEXP_' ssecm '_' sreg]);        

                % compute sectoral distribution parameters
                tempnums(icosecm) = tempnum;

            end
            % compute sectoral distribution parameters
            strpar.(['omegaQA_' ssec '_' sreg '_p']) = ces_compute_weight(tempdenom, tempnums, []);
            if strpar.etaQ_p == 1
                strys.(['P_D_' sreg]) = strys.(['P_D_' sreg])*(strys.(['P_A_' ssec '_' sreg])/(strys.(['A_F_' ssec '_' sreg]) * strpar.(['omegaQA_' ssec '_' sreg '_p'])))^strpar.(['omegaQA_' ssec '_' sreg '_p']);
            else
                strys.(['P_D_' sreg]) = strys.(['P_D_' sreg]) + strpar.(['omegaQA_' ssec '_' sreg '_p']) * (strys.(['P_A_' ssec '_' sreg])/strys.(['A_F_' ssec '_' sreg]))^((1-strpar.etaQ_p));
            end            

        end
        if strpar.etaQ_p ~= 1
            strys.(['P_D_' sreg]) = strys.(['P_D_' sreg])^(1/(1-strpar.etaQ_p));
        end
        strpar.(['P0_D_' sreg '_p']) = strys.(['P_D_' sreg]);
    end


    % compute sector aggregate import price levels and distribution parameters for
    % each sub sector in the aggregate sector
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);   
        strys.(['MEXPF_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            strys.(['MEXP_A_F_' ssec '_' sreg]) = 0;

            if strpar.(['etaQA' '_' ssec '_p'])==1
                strys.(['P_M_A_' ssec '_' sreg]) = 1;
            else
                strys.(['P_M_A_' ssec '_' sreg]) = 0;
            end

            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                % compute auxiliary expression to compute distribution
                % parameters across subsectors in one sector (denominator)
                tempdenom = strys.(['P_M_' ssubsec])^(strpar.(['etaQA' '_' ssec '_p'])-1) * strys.(['MEXP_F_' ssubsec '_' sreg]);
                strys.(['MEXP_A_F_' ssec '_' sreg]) = strys.(['MEXP_A_F_' ssec '_' sreg]) + strys.(['MEXP_F_' ssubsec '_' sreg]);
                if strys.(['MEXP_F_' ssubsec '_' sreg]) == 0
                    strpar.(['omegaM_F_' ssubsec '_' sreg '_p']) = 0;
                else
                    tempnums = zeros(1, strpar.(['subend_' ssec '_p'])-strpar.(['substart_' ssec '_p'])+1);
                    idx = 1;
                    for icosubsecm = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                        ssubsecm = num2str(icosubsecm);
                        % compute auxiliary expression to compute distribution
                        % parameters across subsectors in one sector (numerator)
                        tempnum = strys.(['P_M_' ssubsecm])^(strpar.(['etaQA' '_' ssec '_p'])-1) * strys.(['MEXP_F_' ssubsecm '_' sreg]);
                        % compute inverse distribution parameters across subsectors in one sector
                        tempnums(idx) = tempnum;
                        idx = idx + 1;
                    end

                    % compute distribution parameters across subsectors in one sector
                    strpar.(['omegaM_F_' ssubsec '_' sreg '_p']) = ces_compute_weight(tempdenom, tempnums, []);
                end
                if strpar.(['etaQA' '_' ssec '_p']) ==1
                    % aggregate  sectoral price level
                    strys.(['P_M_A_' ssec '_' sreg]) = strys.(['P_M_A_' ssec '_' sreg]) * (strys.(['P_M_' ssubsec])/strpar.(['omegaM_F_' ssubsec '_' sreg '_p']))^strpar.(['omegaM_F_' ssubsec '_' sreg '_p']);                    
                else

                    % aggregate  sectoral price level
                    strys.(['P_M_A_' ssec '_' sreg]) = strys.(['P_M_A_' ssec '_' sreg]) + strpar.(['omegaM_F_' ssubsec '_' sreg '_p']) * strys.(['P_M_' ssubsec])^(1 - strpar.(['etaQA' '_' ssec '_p']));
                end
            end
            if strpar.(['etaQA' '_' ssec '_p']) ~=1
                % aggregate  sectoral price level
                strys.(['P_M_A_' ssec '_' sreg]) = strys.(['P_M_A_' ssec '_' sreg])^(1/(1 - strpar.(['etaQA' '_' ssec '_p'])));            
            end
            strys.(['MEXPF_' sreg]) = strys.(['MEXPF_' sreg]) + strys.(['MEXP_A_F_' ssec '_' sreg]);
        end
    end


    %  compute distribution parameters for imports
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);   
        if strpar.etaM_p ==1
            strys.(['P_F_' sreg]) = 1;
        else
            strys.(['P_F_' sreg]) = 0;
        end

        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);           
            % compute sectoral distribution parameters
            tempdenom = strys.(['P_M_A_' ssec '_' sreg])^(strpar.etaQ_p-1) * strys.(['MEXP_A_F_' ssec '_' sreg]);        
            tempnums = zeros(1, strpar.inbsectors_p);

            for icosecm = 1:strpar.inbsectors_p
                ssecm = num2str(icosecm);
                % compute sectoral distribution parameters
                tempnum = strys.(['P_M_A_' ssecm '_' sreg])^(strpar.etaQ_p-1) * strys.(['MEXP_A_F_' ssecm '_' sreg]);        

                % compute sectoral distribution parameters
                tempnums(icosecm) = tempnum;

            end
            % compute sectoral distribution parameters
            strpar.(['omegaMA_F_' ssec '_' sreg '_p']) = ces_compute_weight(tempdenom, tempnums, []);
            if strpar.etaQ_p == 1
                strys.(['P_F_' sreg]) = strys.(['P_F_' sreg])*(strys.(['P_M_A_' ssec '_' sreg])/strpar.(['omegaQA_' ssec '_' sreg '_p']))^strpar.(['omegaQA_' ssec '_' sreg '_p']);
            else
                strys.(['P_F_' sreg]) = strys.(['P_F_' sreg]) + strpar.(['omegaMA_F_' ssec '_' sreg '_p']) * (strys.(['P_M_A_' ssec '_' sreg]))^((1-strpar.etaQ_p));
            end                


        end     
        if strpar.etaQ_p ~= 1
            strys.(['P_F_' sreg]) = strys.(['P_F_' sreg])^(1/(1-strpar.etaQ_p));
        end
    end

    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);   
           % compute regional captial and labour income
        strys.(['capincometax_' sreg]) = 0;
        strys.(['labincometax_' sreg]) = 0;
        invreg = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                % interest rate including taxes
                invreg = invreg  + strys.(['I_' ssubsec '_' sreg]) * strys.(['P_K_' ssubsec '_' sreg]);

                % Factor-cost capital income in the model = P_s*Y_s - wages
                % = QEXP - QIEXP - EmExp - WAexp  (from zero-profit condition).
                % This differs from SNA factor-cost GVA by phiQI/(phiQI+phiY)*emDirect.
                emDirect_cap = strpar.(['sE_' ssubsec '_' sreg '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.E0_p * strys.(['PE_' sreg]);
                FCgva_cap = strys.(['QEXP_' ssubsec '_' sreg]) - strys.(['QIEXP_' ssubsec '_' sreg]) - emDirect_cap;
                strys.(['capincometax_' sreg]) = strys.(['capincometax_' sreg]) + (FCgva_cap - strpar.(['WAexp_' ssubsec '_' sreg '_p'])) * (strys.(['tauKH_'  ssubsec '_' sreg]) + strys.(['tauKF_'  ssubsec '_' sreg]));

                strys.(['labincometax_' sreg]) = strys.(['labincometax_' sreg]) + strpar.(['WAexp_' ssubsec '_' sreg '_p']) * (strys.(['tauNH_' sreg]) +  strys.(['tauNF_'  ssubsec '_' sreg]));
            end
        end
    end

    %  compute distribution parameters for final demand production and imports
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);   
        % compute weight on foreign goods in consumption basket
        strpar.(['omegaF_' sreg '_p']) = strys.(['MEXPF_' sreg]) * strys.(['P_F_' sreg])^(strpar.etaF_p-1) / (strys.(['QUEXP_' sreg]) * strys.(['P_D_' sreg])^(strpar.etaF_p-1) + strys.(['MEXPF_' sreg]) * strys.(['P_F_' sreg])^(strpar.etaF_p-1));   
        if strpar.etaQ_p == 1
            strys.(['P_' sreg]) = (strys.(['P_F_' sreg])/strpar.(['omegaF_' sreg '_p']))^strpar.(['omegaF_' sreg '_p']) * (strys.(['P_D_' sreg])/(1 - strpar.(['omegaF_' sreg '_p'])))^(1 - strpar.(['omegaF_' sreg '_p']));
        else
            strys.(['P_' sreg]) = (strpar.(['omegaF_' sreg '_p']) * strys.(['P_F_' sreg])^(1-strpar.etaF_p) + (1 - strpar.(['omegaF_' sreg '_p'])) * strys.(['P_D_' sreg])^(1-strpar.etaF_p))^(1/(1-strpar.etaF_p));
        end                
    end

    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);

        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);

            for icosubsec = strpar.(['substart_' ssec '_p']) : strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                stemp = [ssubsec '_' sreg];

                % P_s * Y_s = QEXP - QIEXP - EmExp  (zero-profit condition: Pnet*Q = P_s*Y + P_I*Q_I).
                % This is the model factor-cost GVA, consistent with P_s from lines above.
                % NOTE: differs from SNA factor-cost GVA (VAexp - emDirect) by
                %       phiQI/(phiQI+phiY)*emDirect due to emission costs in intermediates.
                emDirect_s  = strpar.(['sE_' ssubsec '_' sreg '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.E0_p * strys.(['PE_' sreg]);
                FCgva_stemp = strys.(['QEXP_' stemp]) - strys.(['QIEXP_' stemp]) - emDirect_s;

                % Interest rate net of taxes
                strys.(['r_H_' stemp]) = strys.(['P_INV_' stemp]) / strys.(['P_K_' stemp]) * (1 / strpar.beta_p - 1 +  strpar.(['delta_' ssubsec '_' sreg '_p'])) / (1 - strys.(['tauKH_'  ssubsec '_' sreg])) + strys.(['wedgeKE_' stemp]);                
                
                strys.(['r_G_' ssubsec '_' sreg]) = strpar.rf0_p + strexo.(['exo_r_G_' ssubsec '_' sreg]);

                % Determine capital shares for weighted rental rate computation.
                % Share mode: use new exo_sKGShare / exo_sFDIShare variables.
                % Default mode: use calibrated phiG (K_FDI share = 0).
                lIGShare = isfield(strexo, ['exo_lIGShare_' stemp]) && strexo.(['exo_lIGShare_' stemp]) == 1;
                if lIGShare
                    sKG_init = strexo.(['exo_sIGShare_' stemp]);
                else
                    sKG_init = strpar.(['phiG_' ssubsec '_' sreg '_p']);
                end


                sFDI_init = min(1, max(0, strpar.(['sFDI0_' stemp '_p']) * (1-strexo.(['exo_sFDIShare_' stemp]))));
                
                r_FDI_init = strpar.rf0_p + strexo.(['exo_r_FDI_' stemp]);
                strys.(['r_F_' stemp]) = strys.(['r_G_' stemp]) * sKG_init ...
                                     + r_FDI_init * sFDI_init ...
                                     + strys.(['r_H_' stemp]) * (1 - sKG_init - sFDI_init);

                % Productivity terms
                strys.(['A_N_' stemp]) = strpar.(['A_N_' stemp '_p']);
                strys.(['A_' stemp])   = strpar.(['A_' stemp '_p']) * strys.(['KG_' sreg])^strpar.phiG_p * exp(strexo.(['exo_' stemp]));
                strys.(['A_I_' stemp]) = exp(strexo.(['exo_A_I_' stemp]));

                % Labor allocation to this subsector
                strys.(['N_' stemp]) = strpar.(['phiN0_' stemp '_p']) * strpar.(['N0_' sreg '_p']) * strpar.(['LF0_' sreg '_p']) / strys.(['LF_' sreg]);

                strys.(['W_' stemp]) = strpar.(['WAexp_' stemp '_p']) / ...
                    (strys.(['LF_' sreg]) * strys.(['N_' stemp]) * (1 + strpar.(['tauNF_' stemp '_p'])));

                % Output and capital: Y_s = (QEXP - QIEXP - EmExp) / P_s from zero-profit condition.
                strys.(['Y_' stemp]) = FCgva_stemp / strys.(['P_' stemp]);
                % Store calibrated real output for use in compute_exogenous_y_production.
                % P0_s * Y0_s = FCgva_s is the correct TFP normalization at any calibration PE.
                strpar.(['Y0_' stemp '_p']) = strys.(['Y_' stemp]);
                rkgross = strys.(['r_F_' stemp]) * (1 + strys.(['tauKF_' stemp])) * exp(strexo.(['exo_P_K_' stemp]));
                strys.(['K_' stemp]) = (1 - strpar.(['WAexp_' stemp '_p']) / FCgva_stemp) * strys.(['Y_' stemp]) / rkgross;
                strpar.(['K0_' ssubsec '_' sreg '_p']) = strys.(['K_' ssubsec '_' sreg]);
                                
                % Allocate K into K_G, K_FDI, K_H using computed shares (sKG_init, sFDI_init).
                K_now  = strys.(['K_' stemp]);
                delta_s = strpar.(['delta_' stemp '_p']);
                strys.(['K_G_' stemp])   = sKG_init  * K_now;
                % Share mode: target K_FDI/K directly in steady state.
                strys.(['K_FDI_' stemp]) = sFDI_init * K_now;
                strys.(['I_FDI_' stemp]) = delta_s * strys.(['K_FDI_' stemp]);
                strpar.(['phiFDI0_' stemp '_p']) = strys.(['I_FDI_' stemp]) * strys.(['P_INV_' stemp]) / strpar.Y0_p - strexo.(['exo_I_FDI_' stemp]);
                % Level mode: exogenous FDI investment flow, then infer K_FDI from SS LOM.
                strys.(['I_FDI_' stemp]) = (strpar.(['phiFDI0_' stemp '_p']) + strexo.(['exo_I_FDI_' stemp])) * strpar.Y0_p / strys.(['P_INV_' stemp]);
                if delta_s > 0
                    strys.(['K_FDI_' stemp]) = strys.(['I_FDI_' stemp]) / delta_s;
                else
                    strys.(['K_FDI_' stemp]) = 0;
                end

                rawKH = K_now - strys.(['K_G_' stemp]) - strys.(['K_FDI_' stemp]);
                epsKH = 1e-8 * max(1, K_now);
                strys.(['K_H_'     stemp]) = 0.5 * (rawKH + sqrt(rawKH^2 + epsKH^2));
                strys.(['slackKH_' stemp]) = strys.(['K_H_' stemp]) - rawKH;
                strys.(['I_G_' stemp])   = delta_s * strys.(['K_G_' stemp]);
                strys.(['I_H_' stemp])   = delta_s * strys.(['K_H_' stemp]);
                strys.(['r_FDI_' stemp]) = r_FDI_init;
                strpar.(['s_G_' ssubsec '_' sreg '_p']) = strys.(['I_G_' stemp]) * strys.(['P_K_' stemp])^0 ./ strpar.Y0_p;
                strys.(['s_G_' stemp]) = strpar.(['s_G_' stemp '_p']) + strexo.(['exo_s_G_' stemp]);
                strys.(['r_F_' stemp]) = (strys.(['r_H_' stemp]) * strys.(['K_H_' stemp]) ...
                                        + strys.(['r_G_'   stemp]) * strys.(['K_G_'   stemp]) ...
                                        + r_FDI_init               * strys.(['K_FDI_' stemp])) / K_now;


                % Gross wage before taxes
                rkgross = strys.(['r_F_' stemp]) * (1 + strys.(['tauKF_' stemp])) * exp(strexo.(['exo_P_K_' stemp]));

                % Production function distribution parameters
                strpar.(['alphaK_' stemp '_p']) = (1 - strpar.(['WAexp_' stemp '_p']) / FCgva_stemp) * ...
                    (rkgross / ((1 - strys.(['D_' stemp])) * strys.(['A_' stemp]) * strys.(['A_K_' stemp]) * (1 - strys.(['D_K_' stemp]))))^(strpar.(['etaNK_' stemp '_p']) - 1);

                strpar.(['alphaN_' stemp '_p']) = strpar.(['WAexp_' stemp '_p']) / FCgva_stemp * ...
                    (strys.(['W_' stemp]) / (strys.(['P_' stemp]) * ...
                    ((1 - strys.(['D_N_' stemp]))^2 * (1 - strys.(['D_' stemp])) * strys.(['A_N_' stemp]) * strys.(['A_' stemp]))))^(strpar.(['etaNK_' stemp '_p']) - 1);


                % Recompute A if Cobb-Douglas (etaNK = 1)
                if strpar.(['etaNK_' stemp '_p']) == 1
                    denom = strys.(['K_' stemp])^strpar.(['alphaK_' stemp '_p']) * ...
                            (strys.(['LF_' sreg]) * (1 - strys.(['D_N_' stemp])) * strys.(['A_N_' stemp]) * strys.(['N_' stemp]))^strpar.(['alphaN_' stemp '_p']);
                    strys.(['A_' stemp]) = strys.(['Y_' stemp]) / denom / (1 - strys.(['D_' stemp]));
                    strpar.(['A_' stemp '_p']) = strys.(['A_' stemp]) / ...
                        (strys.(['KG_' sreg])^strpar.phiG_p * exp(strexo.(['exo_' stemp])));
                end

                % Capital used for housing investment
                rawKH = strys.(['K_' stemp]) - strys.(['K_G_' stemp]);
                epsKH = 1e-8 * max(1, strys.(['K_' stemp]));
                strys.(['K_H_'     stemp]) = 0.5 * (rawKH + sqrt(rawKH^2 + epsKH^2));
                strys.(['slackKH_' stemp]) = strys.(['K_H_' stemp]) - rawKH;

                % Recalculate wage using factor income shares
                strys.(['W_' stemp]) = strpar.(['WAexp_' stemp '_p']) / ...
                    (strys.(['LF_' sreg]) * strys.(['N_' stemp]) * (1 + strys.(['tauNF_' stemp])));

                % Intermediate demand by source sector
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);
                    strys.(['Q_I_' stemp '_' ssecm]) = strys.(['QIEXP_' ssubsec '_' sreg '_' ssecm]) / ...
                        (strys.(['P_A_' ssecm '_' sreg]) + strpar.(['kappaEI_' stemp '_' ssecm '_p']) * strys.(['sF_' sreg]) * ...
                         strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]));
                    strys.(['E_I_' stemp '_' ssecm]) = strys.(['Q_I_' stemp '_' ssecm]) * ...
                        strpar.(['kappaEI_' stemp '_' ssecm '_p']) * strys.(['sF_' sreg]);
                end

                % Total intermediate demand and output
                strys.(['Q_I_' stemp]) = strys.(['QIEXP_' ssubsec '_' sreg]) / strys.(['P_I_' stemp]);
                
                strys.(['Q_' stemp]) = (strys.(['P_' stemp]) * strys.(['Y_' stemp]) + ...
                                        strys.(['P_I_' stemp]) * strys.(['Q_I_' stemp])) / ...
                                       (strys.(['P_Q_' stemp]) - strpar.(['kappaE_' stemp '_p']) * ...
                                        strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]));
                strpar.(['Q_I0_' stemp '_p']) = strys.(['Q_I_' stemp])/strys.(['Q_' stemp]);        
                % Record base quantities
                strpar.(['Q0_' stemp '_p']) = strys.(['Q_' stemp]);
                strys.(['E_' stemp]) = strys.(['Q_' stemp]) * strpar.(['kappaE_' stemp '_p']);
                strpar.(['E0_' stemp '_p']) = strys.(['E_' stemp]);

                % Aggregate output from Y and Q_I via CES or Cobb-Douglas
                rho = (strpar.(['etaI_' ssubsec '_p']) - 1) / strpar.(['etaI_' ssubsec '_p']);
                if strpar.(['etaI_' ssubsec '_p']) ~= 1
                    strys.(['Q_' ssubsec '_' sreg]) = ( ...
                        strpar.(['omegaQI_' ssubsec '_' sreg '_p'])^(1 / strpar.(['etaI_' ssubsec '_p'])) * ...
                        strys.(['Q_I_' ssubsec '_' sreg])^rho + ...
                        (1 - strpar.(['omegaQI_' ssubsec '_' sreg '_p']))^(1 / strpar.(['etaI_' ssubsec '_p'])) * ...
                        strys.(['Y_' ssubsec '_' sreg])^rho )^(1 / rho);
                else
                    strys.(['Q_' ssubsec '_' sreg]) = ...
                        strys.(['Q_I_' ssubsec '_' sreg])^strpar.(['omegaQI_' ssubsec '_' sreg '_p']) * ...
                        strys.(['Y_' ssubsec '_' sreg])^(1 - strpar.(['omegaQI_' ssubsec '_' sreg '_p']));
                end

                % Export volumes
                strys.(['X_' stemp]) = strys.(['XEXP_' stemp]) / strys.(['P_Q_' stemp]);

                for icoregm = 1:strpar.inbregions_p
                    sregm = num2str(icoregm);
                    strys.(['Q_D_' ssubsec '_' sregm '_' sreg]) = ...
                        strpar.(['phiQ_D_' ssubsec '_' sreg '_' sregm '_p']) * ...
                        (strys.(['Q_' stemp]) - strys.(['X_' stemp]));
                end

                strys.(['D_X_' stemp]) = strys.(['X_' stemp]) / strys.(['Q_' stemp]);
            end
        end
    end


end
