% DefineSheetsInputFile is a Matlab script called by CreateRawExcelInputFile
% to define the sheets of the ModelSimulationandCalibration<Number of Subsectors>Sectorsand<Number of
% Regions>Regions.xlsx  workbook for parameter and scenario definitions of the
% model. The sheets are:
% - Data
% - Start
% - Structural Parameters
% - Baseline
% - Scenario
% - Content

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
strSubSheet(icosubsheet)  = AddSubSheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);
                           
% icosubsheet = icosubsheet + 1;
% casVariables = {'export share', 'intermediate import share', 'final use import share', 'intermediate products'};
% casCellNames = {'phiX', 'phiM_I', 'phiM_F', 'phiQI'};
% lSectoral = true;
% lRegional = false;
% lSectoralOrigin = false;
% lRegionalOrigin = false;
% strSubSheet(icosubsheet)  = AddSubSheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);

icosubsheet = icosubsheet + 1;
casVariables = {'intermediate input share', 'share of emissions'};
casCellNames = {'phiQI', 'sEI'};
lSectoral = true;
lRegional = true;
lSectoralOrigin = true;
lRegionalOrigin = false;
strSubSheet(icosubsheet)  = AddSubSheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);

icosubsheet = icosubsheet + 1;
casVariables = {'demand of products from different regions'};
casCellNames = {'phiQ_D'};
lSectoral = true;
lRegional = true;
lSectoralOrigin = false;
lRegionalOrigin = true;
strSubSheet(icosubsheet)  = AddSubSheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);

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
strSubSheet(icosubsheet)  = AddSubSheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);

icosubsheet = icosubsheet + 1;
casVariables = cellfun(@(x) ['initial ' x ], casClimateVarsRegionalName, 'UniformOutput', false);
casCellNames = cellfun(@(x) [x '0'], casClimateVarsRegional, 'UniformOutput', false);
lSectoral = false;
lRegional = true;
lSectoralOrigin = false;
lRegionalOrigin = false;
strSubSheet(icosubsheet)  = AddSubSheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);

icosubsheet = icosubsheet + 1;
casVariables = cellfun(@(x) ['initial ' x ], casClimateVarsNationalName, 'UniformOutput', false);
casCellNames = cellfun(@(x) [x '0_p'], casClimateVarsNational, 'UniformOutput', false);
lSectoral = false;
lRegional = false;
lSectoralOrigin = false;
lRegionalOrigin = false;
strSubSheet(icosubsheet)  = AddSubSheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);

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
strSubSheet(icosubsheet)  = AddSubSheet(casVariables, casCellNames, casSubSectors(:), casSectors(:), casRegions(:), lSectoral, lRegional, lSectoralOrigin, lRegionalOrigin, inbsectors_p, inbsubsectors_p, inbregions_p);

strSheet(icosheet).Categories = strSubSheet;      

%% Define Start Sheet with initial values for Simulation
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
casCategories = DefineSheetsInputFileHelp1(casParams, inbregions_p, inbsubsectors_p, inbsectors_p);
strSheet(icosheet).Categories = casCategories;                

%% Define Strucutral Parameter Sheet
icosheet = icosheet + 1;
strSheet(icosheet).Name = 'Structural Parameters';
strSheet(icosheet).Description = 'a sheet to assign values for structural parameters';
% Here we define the parameters we want to assign values in the excel sheet
% structural parameters. Column 1 assigns the symbol as used in the DGE
% CRED model, column 2 asssigns the value, column 3 assigns the description,
% in column 4 we define whether this parameter is sector specific, in
% column 5 we defien whether this parameter is subsector specific, in
% column 6 we define whether this parameter is region specific. 
casParams = [{'beta'; '=9606/10000'; 'discount factor'; false; false; false; false; false} ...
             {'delta'; '=45/1000'; 'depreciation rate'; false; false; false; false; false} ...
             {'phiB'; '=10'; 'foreign bond adjustment cost'; false; false; false; false; false}... 
             {'phiK'; '=10'; 'investment adjustment cost'; false; false; false; false; false}... 
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
             {'etaIA'; '=7/10'; 'elasticity of subsitution between intermeidates'; false; true; false; false; false}... 
             {'phiW'; ['=1/' num2str(4*inbregions_p * inbsubsectors_p)]; 'labour cost share'; false; true; true; false; false} ...
             {'etaNK'; '=1'; 'elasticity of subsitution between labour and captial'; false; true; true; false; false}... 
             {'tauKF'; '=0'; 'tax rate on capital expenditures'; false; true; true; false; false}... 
             {'tauNF'; '=0'; 'tax rate on labour costs'; false; true; true; false; false}... 
             {'sE'; ['=1/(' num2str(inbsectors_p*inbregions_p*inbsubsectors_p + inbregions_p*inbsubsectors_p) ')']; 'share of emissions on total emissions for each sector'; false; true; true; false; false}... 
             {'phiQI'; ['=1/' num2str(inbsectors_p)]; 'share of inputs from another sector for each subsector'; false; true; true; true; false}...
             {'sEI'; ['=1/(' num2str(inbsectors_p*inbregions_p*inbsubsectors_p + inbregions_p*inbsubsectors_p) ')']; 'share of emissions on total emissions for each sector using prdoucts from another sector as input'; false; true; true; true; false}... 
             {'phiQ_D'; ['=1/' num2str(inbregions_p)]; 'share of production used in one region from another region in the subsector'; false; true; true; false; true}...
             ];

casCategories = DefineSheetsInputFileHelp1(casParams, inbregions_p, inbsubsectors_p, inbsectors_p);
% collect infornation in structure
strSheet(icosheet).Categories = casCategories;                
                    
%% Define Baseline scenario sheet
icosheet = icosheet + 1;
strSheet(icosheet).Name = 'Baseline';
strSheet(icosheet).Description = 'a sheet for the baseline scenario';
temp = arrayfun(@(x) arrayfun(@(y) ['gY_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casGrowthRatesY = [temp{:}];
temp = arrayfun(@(x) arrayfun(@(y) ['gN_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casGrowthRatesN = [temp{:}];

casCategoriesHeader = [{'Time'}, {'exo_PoP'}, casGrowthRatesY, casGrowthRatesN];
casData = arrayfun(@(x) num2str(x), [(2:100)' zeros(99, size(casCategoriesHeader,2)-1-size(casGrowthRatesY,2)-size(casGrowthRatesN,2)) ones(99, size(casGrowthRatesY,2)+size(casGrowthRatesN,2))],'UniformOutput', false);
casCategories = [casCategoriesHeader; casData];
strSheet(icosheet).Categories = casCategories;

%% Define Example scenario sheet
icosheet = icosheet + 1;
strSheet(icosheet).Name = 'Scenario';
strSheet(icosheet).Description = 'a sheet for a specific scenario you want to run';
temp = cellfun(@(x) arrayfun(@(y) ['exo_' x '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), casClimateVarsRegional, 'UniformOutput', false);
casClimExoReg = [temp{:}];
temp = cellfun(@(x) ['exo_' x], casClimateVarsNational, 'UniformOutput', false);
casClimExoNat = [temp{:}];
% temp = arrayfun(@(x) arrayfun(@(y) ['exo_D_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
% casDam = [temp{:}];
% temp = arrayfun(@(x) arrayfun(@(y) ['exo_D_N_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
% casDamN = [temp{:}];
% temp = arrayfun(@(x) arrayfun(@(y) ['exo_D_K_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
% casDamK = [temp{:}];
% temp = arrayfun(@(x) arrayfun(@(y) ['exo_GA_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
% casAdapt = [temp{:}];

% casCategoriesHeader = [{'Time'}, {'exo_PoP'}, {'exo_E'}, {'exo_PE'}, casClimExoReg, casClimExoNat, casAdapt, casDam, casDamN, casDamK, {'exo_DH'},{'exo_G_A_DH'}];
casCategoriesHeader = [{'Time'}, {'exo_PoP'}, {'exo_E'}, {'exo_PE'}, {'exo_DH'},{'exo_G_A_DH'}];
casData = arrayfun(@(x) num2str(x), [(2:100)' zeros(99, size(casCategoriesHeader,2)-1)],'UniformOutput', false);
casCategories = [casCategoriesHeader; casData];
strSheet(icosheet).Categories = casCategories;

%% Define Content Sheet
icosheet = icosheet + 1;
casSheets = cellfun(@(x) ['=HYPERLINK("#''' x '''!A1";"' x '")'], {strSheet.Name}', 'UniformOutput', false);
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




