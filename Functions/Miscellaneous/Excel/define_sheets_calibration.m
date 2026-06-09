% define_sheets_calibration  —  Script called by create_calibration_excel_file.m
% Defines strSheet for the ModelCalibration workbook containing:
%   Data | Start | Structural Parameters | Content

%% Define Data Sheet
icosheet = 0;

icosheet = icosheet + 1;
strSheet(icosheet).Name = 'Data';
strSheet(icosheet).Description = 'a sheet to store data used for calibration';

icosubsheet = 0;
icosubsheet = icosubsheet + 1;
casVariables = {'Initial Employment', 'Initial Value Added', 'Labour Cost', 'Exports', 'Import Intermediate', 'Import final', 'Intermediate', 'emission share'};
casCellNames = {'phiN0', 'phiY0', 'phiW', 'phiX', 'phiM_I', 'phiM_F', 'phiQI','sE'};
lSectoral = true;
lRegional = true;
lSectoralOrigin = false;
lRegionalOrigin = false;
strSubSheet(icosubsheet)  = add_sub_sheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);

icosubsheet = icosubsheet + 1;
casVariables = {'intermediate input share', 'share of emissions'};
casCellNames = {'phiQI', 'sEI'};
lSectoral = true;
lRegional = true;
lSectoralOrigin = true;
lRegionalOrigin = false;
strSubSheet(icosubsheet)  = add_sub_sheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);

icosubsheet = icosubsheet + 1;
casVariables = {'demand of products from different regions'};
casCellNames = {'phiQ_D'};
lSectoral = true;
lRegional = true;
lSectoralOrigin = false;
lRegionalOrigin = true;
strSubSheet(icosubsheet)  = add_sub_sheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);

icosubsheet = icosubsheet + 1;
casVariables = cellfun(@(x) ['initial ' x ], {'price level imports', 'domestic price level',...
                        'population', 'labour force', 'employment'...
                        'stocks of houses'},...
                        'UniformOutput', false);
casCellNames = cellfun(@(x) [x], {'P0_MR', 'P0_D', 'PoP0', 'LF0', 'N0', 'H0'}, 'UniformOutput', false);
lSectoral = false;
lRegional = true;
lSectoralOrigin = false;
lRegionalOrigin = false;
strSubSheet(icosubsheet)  = add_sub_sheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);

icosubsheet = icosubsheet + 1;
casVariables = cellfun(@(x) ['initial ' x ], casClimateVarsRegionalName, 'UniformOutput', false);
casCellNames = cellfun(@(x) [x '0'], casClimateVarsRegional, 'UniformOutput', false);
lSectoral = false;
lRegional = true;
lSectoralOrigin = false;
lRegionalOrigin = false;
strSubSheet(icosubsheet)  = add_sub_sheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);

icosubsheet = icosubsheet + 1;
casVariables = cellfun(@(x) ['initial ' x ], casClimateVarsNationalName, 'UniformOutput', false);
casCellNames = cellfun(@(x) [x '0_p'], casClimateVarsNational, 'UniformOutput', false);
lSectoral = false;
lRegional = false;
lSectoralOrigin = false;
lRegionalOrigin = false;
strSubSheet(icosubsheet)  = add_sub_sheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);

icosubsheet = icosubsheet + 1;
casVariables = {'initial employment', 'initial value added', 'import share',...
                'investmetns in residential building relative to GDP',...
                'tax on labour', 'tax on capital income', 'tax on consumption'...
                };
casCellNames = {'N0_p', 'Y0_p', 'phiM_p',...
                'sH_p',...
                'tauNH_p', 'tauKH_p', 'tauC_p'...
                };
lSectoral = false;
lRegional = false;
lSectoralOrigin = false;
lRegionalOrigin = false;
strSubSheet(icosubsheet)  = add_sub_sheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);

strSheet(icosheet).Categories = strSubSheet;

%% Define Start Sheet
icosheet = icosheet + 1;
strSheet(icosheet).Name = 'Start';
strSheet(icosheet).Description = 'a sheet to assign values for the initial conditions';
casParams = [{'Y0'; '=1'; 'initial GDP'; false; false; false; false; false} ...
             {'N0'; '=15/100'; 'initial sum of hours worked to potential hours worked'; false; false; true; false; false}...
             {'P0'; '=0/100'; 'initial emission price'; false; false; true; false; false}...
             {'E0'; '=1'; 'initial emissionss'; false; false; true; false; false}...
             {'sH'; '=1/100'; 'investmetns in residential building relative to GDP'; false; false; true; false; false}...
             {'PoP0'; ['=100/(100 *' num2str(inbregions_p) ')']; 'initial population'; false; false; true; false; false}...
             {'LF0'; ['=96/(100 *' num2str(inbregions_p) ')']; 'initial labour force'; false; false; true; false; false}...
             {'H0'; '=25'; 'initial housing '; false; false; true; false; false}...
             [cellfun(@(x) [x '0'], casClimateVarsRegional, 'UniformOutput', false)'...
             arrayfun(@(x) ['=' num2str(x)], zeros(length(casClimateVarsRegional),1), 'UniformOutput', false)...
             cellfun(@(x) ['initial value for ' x], casClimateVarsRegional, 'UniformOutput', false)'...
             repmat({false}, length(casClimateVarsRegional), 1) repmat({false}, length(casClimateVarsRegional), 1) repmat({true}, length(casClimateVarsRegional), 1) repmat({false}, length(casClimateVarsRegional), 1) repmat({false}, length(casClimateVarsRegional), 1)]' ....
             [cellfun(@(x) [x '0'], casClimateVarsNational, 'UniformOutput', false)'...
             arrayfun(@(x) ['=' num2str(x)], zeros(length(casClimateVarsNational),1), 'UniformOutput', false)...
             cellfun(@(x) ['initial value for ' x], casClimateVarsNational, 'UniformOutput', false)'...
             repmat({false}, length(casClimateVarsNational), 1) repmat({false}, length(casClimateVarsNational), 1) repmat({false}, length(casClimateVarsNational), 1) repmat({false}, length(casClimateVarsNational), 1) repmat({false}, length(casClimateVarsNational), 1)]' ....
             {'phiY0'; ['= 1/' num2str(2*inbregions_p * inbsubsectors_p)]; 'initial share of value added'; false; true; true; false; false} ...
             {'phiN0'; ['= 1/' num2str(inbsubsectors_p)]; 'initial share of employment'; false; true; true; false; false} ...
             ];
casCategories = define_sheets_input_file_help1(casParams, inbregions_p, inbsubsectors_p, inbsectors_p);
casCategories = apply_start_defaults_source_truth_static(casCategories);
strSheet(icosheet).Categories = casCategories;

%% Define Structural Parameters Sheet
icosheet = icosheet + 1;
strSheet(icosheet).Name = 'Structural Parameters';
strSheet(icosheet).Description = 'a sheet to assign values for structural parameters';
casParams = [{'beta'; '=9606/10000'; 'discount factor'; false; false; false; false; false} ...
             {'delta'; '=50/1000'; 'depreciation rate'; false; false; false; false; false} ...
             {'phiB'; '=0.10'; 'foreign bond adjustment cost'; false; false; false; false; false}...
             {'sigmaL'; '=5/10'; 'inverse Frisch elasticity'; false; false; false; false; false}...
             {'sigmaC'; '=1'; 'intertemporal elasticity of substitution for consumption'; false; false; false; false; false}...
             {'etaQ'; '=1/10'; 'elasticity of substitution between sectors'; false; false; false; false; false}...
             {'etaF'; '=9/10'; 'elasticity of substitution between imports and domestic products'; false; false; false; false; false}...
             {'etaX'; '=1'; 'supply price elasticity of exports'; false; false; false; false; false}...
             {'tauC'; '=2/10'; 'consumption tax rate'; false; false; false; false; false}...
             {'tauNH'; '=0'; 'tax rate on labour income'; false; false; false; false; false}...
             {'tauKH'; '=0'; 'tax rate on capital income'; false; false; false; false; false}...
             {'etaQA'; '=1/10'; 'elasticity of substitution between subsectors in one sector'; false; true; false; false; false}...
             {'etaQ'; '=2'; 'elasticity of substitution between regions in one subsector'; false; true; false; false; false}...
             {'phiQI'; ['=1/' num2str(2*inbsubsectors_p*inbregions_p)]; 'cost share of intermediate goods'; false; true; true; false; false}...
             {'phiM_F'; ['=1/' num2str(9*inbsubsectors_p*inbregions_p)]; 'final use import shares'; false; true; true; false; false}...
             {'phiM_I'; ['=1/' num2str(9*inbsubsectors_p*inbregions_p)]; 'intermediate import shares'; false; true; true; false; false}...
             {'phiX'; ['=1/' num2str(4*inbsubsectors_p*inbregions_p)]; 'share of exports on revenues '; false; true; true; false; false}...
             {'etaI'; '=1'; 'elasticity of subsitution between primary production factors and intermediate products'; false; true; false; false; false}...
             {'etaIA'; '=1/10'; 'elasticity of subsitution between intermeidates'; false; true; false; false; false}...
             {'phiW'; ['=1/' num2str(4*inbregions_p * inbsubsectors_p)]; 'labour cost share'; false; true; true; false; false} ...
             {'etaNK'; '=1'; 'elasticity of subsitution between labour and captial'; false; true; true; false; false}...
             {'tauKF'; '=0'; 'tax rate on capital expenditures'; false; true; true; false; false}...
             {'tauNF'; '=0'; 'tax rate on labour costs'; false; true; true; false; false}...
             {'sE'; ['=1/(' num2str(inbsectors_p*inbregions_p*inbsubsectors_p + inbregions_p*inbsubsectors_p) ')']; 'share of emissions on total emissions for each sector'; false; true; true; false; false}...
             {'phiQI'; ['=1/' num2str(inbsectors_p)]; 'share of inputs from another sector for each subsector'; false; true; true; true; false}...
             {'sEI'; ['=1/(' num2str(inbsectors_p*inbregions_p*inbsubsectors_p + inbregions_p*inbsubsectors_p) ')']; 'share of emissions on total emissions for each sector using prdoucts from another sector as input'; false; true; true; true; false}...
             {'phiQ_D'; ['=1/' num2str(inbregions_p)]; 'share of production used in one region from another region in the subsector'; false; true; true; false; true}...
             ];
casCategories = define_sheets_input_file_help1(casParams, inbregions_p, inbsubsectors_p, inbsectors_p);
casCategories = apply_structural_defaults_source_truth_static(casCategories);
strSheet(icosheet).Categories = casCategories;

%% Define Content Sheet
icosheet = icosheet + 1;
casSheets = cellfun(@(x) ['=HYPERLINK("#''' x '''!A1","' x '")'], {strSheet.Name}', 'UniformOutput', false);
casSheetDescriptions = {strSheet.Description}';
strSheet(icosheet).Name = 'Content';
casContentSheet = [{'Sheets', '', ''};...
                  [casSheets casSheetDescriptions, repmat({''}, length(casSheets),1)];...
                  {'Regions', '', ''};...
                  [arrayfun(@(x) num2str(x), 1:inbregions_p, 'UniformOutput', false)' , casRegions repmat({''}, length(casRegions),1)];...
                  {'Sectors', '', ''};...
                  [arrayfun(@(x) num2str(x), 1:inbsubsectors_p, 'UniformOutput', false)' , casSubSectors repmat({''}, length(casSubSectors),1)];...
                  ];
strSheet(icosheet).Categories = casContentSheet;

function casCategoriesOut = apply_structural_defaults_source_truth_static(casCategoriesIn)
% Apply source-of-truth structural defaults using static in-code values.

casCategoriesOut = casCategoriesIn;
sourcePairs = get_source_truth_structural_pairs();
currentParams = casCategoriesOut(2:end, 1);

for i = 1:size(sourcePairs, 1)
    pair = sourcePairs{i};
    paramName = pair{1};
    paramValue = pair{2};

    idx = find(strcmp(currentParams, paramName), 1, 'first');
    if ~isempty(idx)
        casCategoriesOut{idx + 1, 2} = paramValue;
    else
        casCategoriesOut(end + 1, :) = {paramName, paramValue, 'Imported from source-of-truth static defaults'}; %#ok<AGROW>
        currentParams = casCategoriesOut(2:end, 1);
    end
end

end

function sourcePairs = get_source_truth_structural_pairs()
% Parameter/value pairs copied from Training/Day3_Calibration source workbook.
sourcePairs = {
    {'beta_p', '0.97'};
    {'delta_1_1_p', '0.05'};
    {'delta_2_1_p', '0.025'};
    {'delta_3_1_p', '0.05'};
    {'delta_4_1_p', '0.05'};
    {'delta_5_1_p', '0.05'};
    {'delta_p', '0.05'};
    {'deltaB_p', '0.05'};
    {'etaF_p', '0.6'};
    {'etaI_1_p', '1'};
    {'etaI_2_p', '1'};
    {'etaI_3_p', '1'};
    {'etaI_4_p', '1'};
    {'etaI_5_p', '1'};
    {'etaIA_1_p', '0.1'};
    {'etaIA_2_p', '0.1'};
    {'etaIA_3_p', '0.1'};
    {'etaIA_4_p', '0.1'};
    {'etaIA_5_p', '0.1'};
    {'etaNK_1_1_p', '1'};
    {'etaNK_2_1_p', '1'};
    {'etaNK_3_1_p', '1'};
    {'etaNK_4_1_p', '1'};
    {'etaNK_5_1_p', '1'};
    {'etaQ_1_p', '2'};
    {'etaQ_2_p', '2'};
    {'etaQ_3_p', '2'};
    {'etaQ_4_p', '2'};
    {'etaQ_5_p', '2'};
    {'etaQ_p', '0.6'};
    {'etaQA_1_p', '1'};
    {'etaQA_2_p', '5'};
    {'etaQA_3_p', '1'};
    {'etaQA_4_p', '1'};
    {'etaQA_5_p', '1'};
    {'etaX_p', '0.6'};
    {'phiadjB_p', '1.00E-01'};
    {'phiB_p', '1.00E-01'};
    {'phiK_1_1_p', '5'};
    {'phiK_2_1_p', '5'};
    {'phiK_3_1_p', '5'};
    {'phiK_4_1_p', '5'};
    {'phiK_5_1_p', '5'};
    {'phiM_F_1_1_p', '0.0035541'};
    {'phiM_F_2_1_p', '0.00163033'};
    {'phiM_F_3_1_p', '0.001'};
    {'phiM_F_4_1_p', '0.03826289'};
    {'phiM_F_5_1_p', '0.00318516'};
    {'phiM_I_1_1_p', '0.0213454'};
    {'phiM_I_2_1_p', '0.01904601'};
    {'phiM_I_3_1_p', '0.00035363'};
    {'phiM_I_4_1_p', '0.18111131'};
    {'phiM_I_5_1_p', '0.02552624'};
    {'phiQ_D_1_1_1_p', '1'};
    {'phiQ_D_2_1_1_p', '1'};
    {'phiQ_D_3_1_1_p', '1'};
    {'phiQ_D_4_1_1_p', '1'};
    {'phiQ_D_5_1_1_p', '1'};
    {'phiQI_1_1_1_p', '0.01442223'};
    {'phiQI_1_1_2_p', '0.0040982'};
    {'phiQI_1_1_3_p', '0.02704607'};
    {'phiQI_1_1_4_p', '0.0049752'};
    {'phiQI_1_1_p', '0.0505417'};
    {'phiQI_2_1_1_p', '0.00064131'};
    {'phiQI_2_1_2_p', '0.01224437'};
    {'phiQI_2_1_3_p', '0.00342081'};
    {'phiQI_2_1_4_p', '0.00266446'};
    {'phiQI_2_1_p', '0.01897095'};
    {'phiQI_3_1_1_p', '0.0001281'};
    {'phiQI_3_1_2_p', '0.00172095'};
    {'phiQI_3_1_3_p', '0.00055383'};
    {'phiQI_3_1_4_p', '0.00039025'};
    {'phiQI_3_1_p', '0.00267784'};
    {'phiQI_4_1_1_p', '0.06828906'};
    {'phiQI_4_1_2_p', '0.02408755'};
    {'phiQI_4_1_3_p', '0.33230489'};
    {'phiQI_4_1_4_p', '0.05253432'};
    {'phiQI_4_1_p', '0.47721582'};
    {'phiQI_5_1_1_p', '0.00589791'};
    {'phiQI_5_1_2_p', '0.0143778'};
    {'phiQI_5_1_3_p', '0.0371544'};
    {'phiQI_5_1_4_p', '0.05067853'};
    {'phiQI_5_1_p', '0.10810864'};
    {'phiW_1_1_p', '0.03952593'};
    {'phiW_2_1_p', '0.00622251'};
    {'phiW_3_1_p', '0.00072204'};
    {'phiW_4_1_p', '0.07632894'};
    {'phiW_5_1_p', '0.09175963'};
    {'phiX_1_1_p', '0.00696061'};
    {'phiX_2_1_p', '0.004'};
    {'phiX_3_1_p', '0.0001'};
    {'phiX_4_1_p', '0.26208945'};
    {'phiX_5_1_p', '0.03365086'};
    {'sE_1_1_p', '0'};
    {'sE_2_1_p', '1'};
    {'sE_3_1_p', '0'};
    {'sE_4_1_p', '0'};
    {'sE_5_1_p', '0'};
    {'sE_NOETS_1_1_p', '1'};
    {'sE_NOETS_2_1_p', '0'};
    {'sE_NOETS_3_1_p', '0'};
    {'sE_NOETS_4_1_p', '0'};
    {'sE_NOETS_5_1_p', '0'};
    {'sEI_1_1_1_p', '0'};
    {'sEI_1_1_2_p', '0'};
    {'sEI_1_1_3_p', '0'};
    {'sEI_1_1_4_p', '0'};
    {'sEI_2_1_1_p', '0'};
    {'sEI_2_1_2_p', '0'};
    {'sEI_2_1_3_p', '0'};
    {'sEI_2_1_4_p', '0'};
    {'sEI_3_1_1_p', '0'};
    {'sEI_3_1_2_p', '0'};
    {'sEI_3_1_3_p', '0'};
    {'sEI_3_1_4_p', '0'};
    {'sEI_4_1_1_p', '0'};
    {'sEI_4_1_2_p', '0'};
    {'sEI_4_1_3_p', '0'};
    {'sEI_4_1_4_p', '0'};
    {'sEI_5_1_1_p', '0'};
    {'sEI_5_1_2_p', '0'};
    {'sEI_5_1_3_p', '0'};
    {'sEI_5_1_4_p', '0'};
    {'sigmaC_p', '1'};
    {'sigmaL_p', '1'};
    {'tauC_p', '0.2'};
    {'tauKF_1_1_p', '0'};
    {'tauKF_2_1_p', '0'};
    {'tauKF_3_1_p', '0'};
    {'tauKF_4_1_p', '0'};
    {'tauKF_5_1_p', '0'};
    {'tauKH_p', '0'};
    {'tauNF_1_1_p', '0'};
    {'tauNF_2_1_p', '0'};
    {'tauNF_3_1_p', '0'};
    {'tauNF_4_1_p', '0'};
    {'tauNF_5_1_p', '0'};
    {'tauNH_p', '0'};
};
end

function casCategoriesOut = apply_start_defaults_source_truth_static(casCategoriesIn)
% Apply source-of-truth Start sheet defaults using static in-code values.

casCategoriesOut = casCategoriesIn;
sourcePairs = get_source_truth_start_pairs();
currentParams = casCategoriesOut(2:end, 1);

for i = 1:size(sourcePairs, 1)
    pair = sourcePairs{i};
    paramName = pair{1};
    paramValue = pair{2};

    idx = find(strcmp(currentParams, paramName), 1, 'first');
    if ~isempty(idx)
        casCategoriesOut{idx + 1, 2} = paramValue;
    else
        casCategoriesOut(end + 1, :) = {paramName, paramValue, 'Imported from source-of-truth static defaults'}; %#ok<AGROW>
        currentParams = casCategoriesOut(2:end, 1);
    end
end

end

function sourcePairs = get_source_truth_start_pairs()
% Start-sheet parameter/value pairs from Training/Day3_Calibration source workbook.
sourcePairs = {
    {'deltaPV_p', '0.1'};
    {'E0_1_p', '0.78'};
    {'E0_NOETS_1_p', '0.22'};
    {'H0_1_p', '25'};
    {'LF0_1_p', '0.68'};
    {'N0_1_p', '0.15'};
    {'P0_1_p', '0'};
    {'PE0_1_p', '0'};
    {'phiG_1_1_p', '0.48'};
    {'phiG_2_1_p', '0.5'};
    {'phiG_3_1_p', '0.01'};
    {'phiG_4_1_p', '0.08'};
    {'phiG_5_1_p', '0.3'};
    {'phiKPV0_p', '0.013'};
    {'phiN0_1_1_p', '0.184'};
    {'phiN0_2_1_p', '0.029'};
    {'phiN0_3_1_p', '0.003'};
    {'phiN0_4_1_p', '0.356'};
    {'phiN0_5_1_p', '0.428'};
    {'phiQPV0_p', '0.036'};
    {'phiY0_1_1_p', '0.044'};
    {'phiY0_2_1_p', '0.019'};
    {'phiY0_3_1_p', '0.003'};
    {'phiY0_4_1_p', '0.112'};
    {'phiY0_5_1_p', '0.1642731910413037'};
    {'PoP0_1_p', '1'};
    {'sH_1_p', '0.05'};
    {'SL0_p', '0'};
    {'tas0_1_p', '0'};
    {'Y0_p', '5'};
};
end
