
function [strys,strpar] = computePFParameters(strys,strpar, strexo)
    % function [strpar, strys] = ComputePFParameters(strys,strexo,strpar)
    % calibrates the parameters of the production functions of the DGE_CRED_Model.mod
    % Inputs: 
    %   - strys     [structure]  endogeonous variables of the model
    %   - strpar    [structure]  parameters of the model
    %
    % Output: 
    %   - strys     [structure]  see inputs
    %   - strpar    [structure]  see inputs

    strpar.phiY_p = 0;
    strpar.phiEF_p = 0;
    for icosec = 1:strpar.inbsectors_p
        ssec = num2str(icosec);
        for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
            ssubsec = num2str(icosubsec);             
            for icoreg = 1:strpar.inbregions_p
                sreg = num2str(icoreg);  
                % revenues from products generated in subsector s and region r
                strpar.phiY_p = strpar.phiY_p + strpar.(['phiY_' ssubsec '_' sreg '_p']);
                strpar.phiEF_p = strpar.phiEF_p + strpar.(['sE_' ssubsec '_' sreg '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.E0_p * strys.(['PE_' sreg]);
                strpar.(['phiQ_' ssubsec '_' sreg '_p']) = strpar.(['phiQI_' ssubsec '_' sreg '_p']) + strpar.(['phiY_' ssubsec '_' sreg '_p']);
            end
        end
    end


    strpar.Q0_p = strys.Y/strpar.phiY_p + strys.PE*strpar.E0_p;
    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);   
        strys.(['MEXP_' sreg]) = 0;
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            % subsectoral interat rate
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);
                EmExp = strpar.(['sE_' ssubsec '_' sreg '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.E0_p * strys.(['PE_' sreg]);
                % revenues from products generated in subsector s and region r
                strys.(['QEXP_' ssubsec '_' sreg]) = (strpar.(['phiQI_' ssubsec '_' sreg '_p']) + strpar.(['phiY_' ssubsec '_' sreg '_p'])) * (strpar.Q0_p - strpar.E0_p * strys.(['PE_' sreg])) + EmExp;                
                % calibrate emission intensity 
                strpar.(['kappaE_' ssubsec '_' sreg '_p']) = strpar.(['sE_' ssubsec '_' sreg '_p']) * strpar.E0_p / (strys.(['QEXP_' ssubsec '_' sreg])/ strys.(['P_Q_' ssubsec '_' sreg]));
                strys.(['kappaE_' ssubsec '_' sreg]) = strpar.(['kappaE_' ssubsec '_' sreg '_p']);
                % export shares
                strys.(['XEXP_' ssubsec '_' sreg]) = strpar.(['phiX_' ssubsec '_' sreg '_p'])/(strpar.(['phiQI_' ssubsec '_' sreg '_p']) + strpar.(['phiY_' ssubsec '_' sreg '_p'])) * strys.(['QEXP_' ssubsec '_' sreg]);
                % intermediate import shares
                strys.(['MEXP_I_' ssubsec '_' sreg]) = strpar.(['phiM_I_' ssubsec '_' sreg '_p']) * (strpar.Q0_p - strpar.E0_p * strys.PE); 
                % final import shares
                strys.(['MEXP_F_' ssubsec '_' sreg]) = (strpar.Q0_p - strpar.E0_p * strys.PE) * strpar.(['phiM_F_' ssubsec '_' sreg '_p']); 
                % intermediate product shares
                tempQI = strpar.(['phiQI_' ssubsec '_' sreg '_p'])/(strpar.(['phiQI_' ssubsec '_' sreg '_p']) + strpar.(['phiY_' ssubsec '_' sreg '_p']));
                strys.(['QIEXP_' ssubsec '_' sreg]) = tempQI * strys.(['QEXP_' ssubsec '_' sreg]) * (1 - strys.(['kappaE_' ssubsec '_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]) / strys.(['P_Q_' ssubsec '_' sreg]));
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);  
                    % intermediate product shares
                    strys.(['QIEXP_' ssubsec '_' sreg '_' ssecm]) = strpar.(['phiQI_' ssubsec '_' sreg '_' ssecm '_p']) * strys.(['QIEXP_' ssubsec '_' sreg]);
                end                
                for icoregm = 1:strpar.inbregions_p
                    sregm = num2str(icoregm);
                    % allocation of regional (sreg) and sectoral (ssubsec)
                    % production to different regions (sregm) using the
                    % product
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
            % subsectoral interat rate
            for icosubsec = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                ssubsec = num2str(icosubsec);

                % revenues from products generated in subsector s and region r
                strys.(['QEXP_' sreg]) = strys.(['QEXP_' sreg]) + strys.(['QEXP_' ssubsec '_' sreg]);                
            end
        end
    end


    for icoreg = 1:strpar.inbregions_p
        sreg = num2str(icoreg);   
        for icosec = 1:strpar.inbsectors_p
            ssec = num2str(icosec);
            strys.(['QAEXP_' ssec '_' sreg]) = 0;           
            % subsectoral interat rate
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
            strys.(['QAFEXP_' ssec '_' sreg]) = strys.(['QAEXP_' ssec '_' sreg]) - strys.(['QAIEXP_' ssec '_' sreg]) - (icosec == strpar.iSecHouse_p) * strpar.(['sH_' sreg '_p']) * strys.Y;
            strys.(['QUEXP_' sreg]) = strys.(['QUEXP_' sreg]) + strys.(['QAFEXP_' ssec '_' sreg]); 
        end
    end



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
                    temp = 0;
                    tempdenom = strys.(['P_Q_' ssubsec '_' sregn])^(strpar.(['etaQ_' ssubsec '_p'])-1) * strys.(['QDEXP_' ssubsec '_' sreg '_' sregn]);
                    for icoregm = 1:strpar.inbregions_p
                        sregm = num2str(icoregm);
                        % compute numerator for distribution parameters across regions in one subsector
                        tempnum = strys.(['P_Q_' ssubsec '_' sregm])^(strpar.(['etaQ_' ssubsec '_p'])-1) * strys.(['QDEXP_' ssubsec '_' sreg '_' sregm]);
                        temp = temp + tempnum / tempdenom;
                    end
                    temp = temp + strys.(['P_M_' ssubsec])^(strpar.(['etaQ_' ssubsec '_p'])-1) * strys.(['MEXP_I_' ssubsec '_' sreg]) / tempdenom;
                    % distribution parameters across regions in one subsector sectors                    
                    strpar.(['omegaQ_' ssubsec '_' sreg '_' sregn '_p']) = 1/temp;

                    if strpar.(['etaQ_' ssubsec '_p']) ==1
                        % aggregate price index across region in one sbsector
                        strys.(['P_D_' ssubsec '_' sreg]) = strys.(['P_D_' ssubsec '_' sreg]) * (strys.(['P_Q_' ssubsec '_' sregn])/strpar.(['omegaQ_' ssubsec '_' sreg '_' sregn '_p']))^strpar.(['omegaQ_' ssubsec '_' sreg '_' sregn '_p']);
                    else
                        % aggregate price index across region in one sbsector
                        strys.(['P_D_' ssubsec '_' sreg]) = strys.(['P_D_' ssubsec '_' sreg]) + strpar.(['omegaQ_' ssubsec '_' sreg '_' sregn '_p']) * strys.(['P_Q_' ssubsec '_' sregn])^(1 - strpar.(['etaQ_' ssubsec '_p']));
                    end                  

                end

                temp = 0;
                tempdenom = strys.(['P_M_' ssubsec])^(strpar.(['etaQ_' ssubsec '_p'])-1) * strys.(['MEXP_I_' ssubsec '_' sreg]);
                for icoregm = 1:strpar.inbregions_p
                    sregm = num2str(icoregm);
                    % compute numerator for distribution parameters across regions in one subsector
                    tempnum = strys.(['P_Q_' ssubsec '_' sregm])^(strpar.(['etaQ_' ssubsec '_p'])-1) * strys.(['QDEXP_' ssubsec '_' sreg '_' sregm]);
                    temp = temp + tempnum / tempdenom;
                end
                temp = temp + strys.(['P_M_' ssubsec])^(strpar.(['etaQ_' ssubsec '_p'])-1) * strys.(['MEXP_I_' ssubsec '_' sreg]) / tempdenom;
                % distribution parameters across regions in one subsector sectors                    
                strpar.(['omegaM_' ssubsec '_' sreg '_p']) = 1/temp;

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
                temp = 0;
                % compute auxiliary expression to compute distribution
                % parameters across subsectors in one sector (denominator)
                tempdenom = strys.(['P_D_' ssubsec '_' sreg])^(strpar.(['etaQA' '_' ssec '_p'])-1) * strys.(['QDEXP_' ssubsec '_' sreg]);
                for icosubsecm = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                    ssubsecm = num2str(icosubsecm);
                    % compute auxiliary expression to compute distribution
                    % parameters across subsectors in one sector (numerator)
                    tempnum = strys.(['P_D_' ssubsecm '_' sreg])^(strpar.(['etaQA' '_' ssec '_p'])-1) * strys.(['QDEXP_' ssubsecm '_' sreg]);
                    % compute inverse distribution parameters across subsectors in one sector
                    temp = temp + tempnum / tempdenom;
                end

                % compute distribution parameters across subsectors in one sector
                strpar.(['omegaQ_' ssubsec '_' sreg '_p']) = 1/temp;
                if strpar.(['etaQA' '_' ssec '_p']) ==1
                    % aggregate  sectoral price level
                    strys.(['P_A_' ssec '_' sreg]) = strys.(['P_A_' ssec '_' sreg]) * (strys.(['P_D_' ssubsec '_' sreg])/strpar.(['omegaQ_' ssubsec '_' sreg '_p']))^strpar.(['omegaQ_' ssubsec '_' sreg '_p']);                    
                else

                    % aggregate  sectoral price level
                    strys.(['P_A_' ssec '_' sreg]) = strys.(['P_A_' ssec '_' sreg]) + strpar.(['omegaQ_' ssubsec '_' sreg '_p']) * strys.(['P_D_' ssubsec '_' sreg])^(1 - strpar.(['etaQA' '_' ssec '_p']));
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
                EmExp = strpar.(['sE_' ssubsec '_' sreg '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.E0_p * strys.(['PE_' sreg]);
                if strpar.(['etaIA_' ssubsec '_p']) ==1
                    strys.(['P_I_' ssubsec '_' sreg]) = 1;
                else
                    strys.(['P_I_' ssubsec '_' sreg]) = 0;
                end
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);
                    strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) = (strpar.(['sEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.E0_p) / (strys.(['sF_' sreg])*(strys.(['QIEXP_' ssubsec '_' sreg '_' ssecm])-strpar.(['sEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.E0_p * strys.(['PE_' sreg]))/strys.(['P_A_' ssecm '_' sreg]));
                    PAgrosstemp = strys.(['P_A_' ssecm '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecm '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['sF_' sreg]) * strys.(['PE_' sreg]);
                    tempdenom = (PAgrosstemp/strys.(['A_I_' ssubsec '_' sreg '_' ssecm']))^(strpar.(['etaIA_' ssubsec '_p'])-1) * strys.(['QIEXP_' ssubsec '_' sreg '_' ssecm']);        
                    temp= 0;
                    for icosecn = 1:strpar.inbsectors_p
                        ssecn = num2str(icosecn);                    
                        PAgrosstemp = strys.(['P_A_' ssecn '_' sreg]) + strpar.(['kappaEI_' ssubsec '_' sreg '_' ssecn '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['sF_' sreg]) * strys.(['PE_' sreg]);
                        % compute sectoral distribution parameters
                        tempnum = (PAgrosstemp/strys.(['A_I_' ssubsec '_' sreg '_' ssecn']))^(strpar.(['etaIA_' ssubsec '_p'])-1) * strys.(['QIEXP_' ssubsec '_' sreg '_' ssecn']);             
                        % compute sectoral distribution parameters
                        temp = temp + tempnum / tempdenom;                        
                    end
                    % compute sectoral distribution parameters
                    strpar.(['omegaQI_' ssubsec '_' sreg '_' ssecm '_p']) = 1/temp;
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
                    strys.(['P_'  ssubsec '_' sreg]) = (((strys.(['P_Q_'  ssubsec '_' sreg]) - strys.(['kappaE_' ssubsec '_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]))^(strpar.(['etaI_' ssubsec '_p'])-1) * strys.(['QEXP_'  ssubsec '_' sreg])*(1 - strys.(['kappaE_' ssubsec '_' sreg]) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strys.(['PE_' sreg]) / strys.(['P_Q_' ssubsec '_' sreg])) - ...
                        strys.(['P_I_'  ssubsec '_' sreg])^(strpar.(['etaI_' ssubsec '_p'])-1) * strys.(['QIEXP_'  ssubsec '_' sreg]))/...
                        (strys.(['QEXP_'  ssubsec '_' sreg])-strys.(['QIEXP_'  ssubsec '_' sreg])-EmExp))^(1/(strpar.(['etaI_' ssubsec '_p'])-1));
                    
                    % auxiliary variable to compute distribution parameter
                    tempQI = strys.(['P_I_'  ssubsec '_' sreg])^(strpar.(['etaI_' ssubsec '_p'])-1) * strys.(['QIEXP_'  ssubsec '_' sreg]);

                    % auxiliary variable to compute distribution parameter
                    tempY = strys.(['P_'  ssubsec '_' sreg])^(strpar.(['etaI_' ssubsec '_p'])-1) * (strys.(['QEXP_'  ssubsec '_' sreg])-strys.(['QIEXP_'  ssubsec '_' sreg])-EmExp);

                    % compute distribution parameter for production function for intermedate products
                    strpar.(['omegaQI_'  ssubsec '_' sreg '_p']) = tempQI /(tempQI + tempY);

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

            temp= 0;

            for icosecm = 1:strpar.inbsectors_p
                ssecm = num2str(icosecm);
                % compute sectoral distribution parameters
                tempnum = strys.(['P_A_' ssecm '_' sreg])^(strpar.etaQ_p-1) * strys.(['QAFEXP_' ssecm '_' sreg]);        

                % compute sectoral distribution parameters
                temp = temp + tempnum / tempdenom;

            end
            % compute sectoral distribution parameters
            strpar.(['omegaQA_' ssec '_' sreg '_p']) = 1/temp;
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
                temp = 0;
                % compute auxiliary expression to compute distribution
                % parameters across subsectors in one sector (denominator)
                tempdenom = strys.(['P_M_' ssubsec])^(strpar.(['etaQA' '_' ssec '_p'])-1) * strys.(['MEXP_F_' ssubsec '_' sreg]);
                strys.(['MEXP_A_F_' ssec '_' sreg]) = strys.(['MEXP_A_F_' ssec '_' sreg]) + strys.(['MEXP_F_' ssubsec '_' sreg]);
                for icosubsecm = strpar.(['substart_' ssec '_p']):strpar.(['subend_' ssec '_p'])
                    ssubsecm = num2str(icosubsecm);
                    % compute auxiliary expression to compute distribution
                    % parameters across subsectors in one sector (numerator)
                    tempnum = strys.(['P_M_' ssubsecm])^(strpar.(['etaQA' '_' ssec '_p'])-1) * strys.(['MEXP_F_' ssubsecm '_' sreg]);
                    % compute inverse distribution parameters across subsectors in one sector
                    temp = temp + tempnum / tempdenom;
                end

                % compute distribution parameters across subsectors in one sector
                strpar.(['omegaM_F_' ssubsec '_' sreg '_p']) = 1/temp;
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

            temp= 0;

            for icosecm = 1:strpar.inbsectors_p
                ssecm = num2str(icosecm);
                % compute sectoral distribution parameters
                tempnum = strys.(['P_M_A_' ssecm '_' sreg])^(strpar.etaQ_p-1) * strys.(['MEXP_A_F_' ssecm '_' sreg]);        

                % compute sectoral distribution parameters
                temp = temp + tempnum / tempdenom;

            end
            % compute sectoral distribution parameters
            strpar.(['omegaMA_F_' ssec '_' sreg '_p']) = 1/temp;
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
                EmExp = strpar.(['sE_' ssubsec '_' sreg '_p']) * strpar.(['lEndoQ_' ssubsec '_' sreg '_p']) * strpar.E0_p * strys.(['PE_' sreg]);
                % interest rate including taxes 
                invreg = invreg  + strys.(['I_' ssubsec '_' sreg]) * strys.(['P_' ssubsec '_' sreg]);                           

                strys.(['capincometax_' sreg]) = strys.(['capincometax_' sreg]) + (strpar.(['phiY_' ssubsec '_' sreg '_p'])-strpar.(['phiW_' ssubsec '_' sreg '_p']))  * (strpar.Q0_p-strys.PE*strpar.E0_p) * (strys.(['tauKH_' sreg]) + strys.(['tauKF_'  ssubsec '_' sreg]));

                strys.(['labincometax_' sreg]) = strys.(['labincometax_' sreg]) + strpar.(['phiW_' ssubsec '_' sreg '_p']) * (strpar.Q0_p-strys.PE*strpar.E0_p) * (strys.(['tauNH_' sreg]));
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

                % Interest rate net of taxes
                strys.(['r_' stemp]) = (1 / strpar.beta_p - 1 +  strpar.(['delta_' ssubsec '_' sreg '_p'])) / (1 - strys.(['tauKH_' sreg]));

                % Productivity terms
                strys.(['A_N_' stemp]) = strpar.(['A_N_' stemp '_p']);
                strys.(['A_' stemp])   = strpar.(['A_' stemp '_p']) * strys.(['KG_' sreg])^strpar.phiG_p * exp(strexo.(['exo_' stemp]));
                strys.(['A_I_' stemp]) = exp(strexo.(['exo_A_I_' stemp]));

                % Labor allocation to this subsector
                strys.(['N_' stemp]) = strpar.(['phiN0_' stemp '_p']) * strpar.(['N0_' sreg '_p']) * strpar.(['LF0_' sreg '_p']) / strys.(['LF_' sreg]);

                % Gross wage before taxes
                rkgross = strys.(['r_' stemp]) * (1 + strys.(['tauKF_' stemp]));

                strys.(['W_' stemp]) = strpar.(['phiW_' stemp '_p']) * ...
                    (strpar.Q0_p - strys.PE * strpar.E0_p) / ...
                    (strys.(['LF_' sreg]) * strys.(['N_' stemp]) * (1 + strpar.(['tauNF_' stemp '_p'])));

                % Production function distribution parameters
                strpar.(['alphaK_' stemp '_p']) = (1 - strpar.(['phiW_' stemp '_p']) / strpar.(['phiY_' stemp '_p'])) * ...
                    (rkgross / ((1 - strys.(['D_' stemp])) * strys.(['A_' stemp]) * strys.(['A_K_' stemp]) * (1 - strys.(['D_K_' stemp]))))^(strpar.(['etaNK_' stemp '_p']) - 1);

                strpar.(['alphaN_' stemp '_p']) = strpar.(['phiW_' stemp '_p']) / strpar.(['phiY_' stemp '_p']) * ...
                    (strys.(['W_' stemp]) / (strys.(['P_' stemp]) * ...
                    ((1 - strys.(['D_N_' stemp]))^2 * (1 - strys.(['D_' stemp])) * strys.(['A_N_' stemp]) * strys.(['A_' stemp]))))^(strpar.(['etaNK_' stemp '_p']) - 1);

                % Output and capital
                strys.(['Y_' stemp]) = strpar.(['phiY_' stemp '_p']) / strpar.phiY_p * strpar.Y0_p / strys.(['P_' stemp]);
                strys.(['K_' stemp]) = (1 - strpar.(['phiW_' stemp '_p']) / strpar.(['phiY_' stemp '_p'])) * strys.(['Y_' stemp]) / rkgross;

                % Recompute A if Cobb-Douglas (etaNK = 1)
                if strpar.(['etaNK_' stemp '_p']) == 1
                    denom = strys.(['K_' stemp])^strpar.(['alphaK_' stemp '_p']) * ...
                            (strys.(['LF_' sreg]) * (1 - strys.(['D_N_' stemp])) * strys.(['A_N_' stemp]) * strys.(['N_' stemp]))^strpar.(['alphaN_' stemp '_p']);
                    strys.(['A_' stemp]) = strys.(['Y_' stemp]) / denom / (1 - strys.(['D_' stemp]));
                    strpar.(['A_' stemp '_p']) = strys.(['A_' stemp]) / ...
                        (strys.(['KG_' sreg])^strpar.phiG_p * exp(strexo.(['exo_' stemp])));
                end

                % Capital used for housing investment
                strys.(['KH_' ssubsec '_' sreg]) = strys.(['K_' stemp]);

                % Recalculate wage using factor income shares
                strys.(['W_' stemp]) = strpar.(['phiW_' stemp '_p']) / strpar.(['phiY_' stemp '_p']) * ...
                    strys.(['Y_' stemp]) * strys.(['P_' stemp]) / ...
                    (strys.(['LF_' sreg]) * strys.(['N_' stemp]) * (1 + strys.(['tauNF_' stemp])));

                % Intermediate demand by source sector
                for icosecm = 1:strpar.inbsectors_p
                    ssecm = num2str(icosecm);
                    strys.(['Q_I_' stemp '_' ssecm]) = strpar.(['phiQI_' ssubsec '_' sreg '_' ssecm '_p']) * ...
                        strys.(['QIEXP_' ssubsec '_' sreg]) / ...
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

                % Investment and auxiliary conditions
                strys.(['omegaI_' ssubsec '_' sreg]) = 1;
                strys.(['I_' ssubsec '_' sreg]) = ...
                    strpar.(['delta_' ssubsec '_' sreg '_p']) * strys.(['KH_' ssubsec '_' sreg]) + strys.(['D_K_' ssubsec '_' sreg]);
            end
        end
    end


end
