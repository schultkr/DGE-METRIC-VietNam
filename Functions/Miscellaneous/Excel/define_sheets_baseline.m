% define_sheets_baseline  —  Script called by create_baseline_excel_file.m
% Defines strSheet for the ModelBaseline workbook containing:
%   Baseline | Content

%% Define Baseline Sheet
icosheet = 0;

icosheet = icosheet + 1;
strSheet(icosheet).Name = 'Baseline';
strSheet(icosheet).Description = 'a sheet for the baseline scenario growth paths';
temp = arrayfun(@(x) arrayfun(@(y) ['gY_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casGrowthRatesY = [temp{:}];
temp = arrayfun(@(x) arrayfun(@(y) ['gN_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casGrowthRatesN = [temp{:}];
temp = arrayfun(@(x) arrayfun(@(y) ['exo_lKRGTarget_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casLKRGTarget = [temp{:}];
temp = arrayfun(@(x) arrayfun(@(y) ['exo_KRGTarget_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casKRGTarget = [temp{:}];

temp = arrayfun(@(x) arrayfun(@(y) ['exo_E_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casSectorEmissions = [temp{:}];
temp = arrayfun(@(x) arrayfun(@(y) ['idx_E_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casSectorEmissionsIdx = [temp{:}];

iSubsecFossil = find(strcmpi(casSubSectors, 'Fossil'), 1, 'first');
if isempty(iSubsecFossil)
    iSubsecFossil = 2;
end
casFossilProd = arrayfun(@(r) ['exo_Q_' num2str(iSubsecFossil) '_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);
casFossilExp = arrayfun(@(r) ['exo_X_' num2str(iSubsecFossil) '_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);
casFossilProdIdx = arrayfun(@(r) ['idx_Q_' num2str(iSubsecFossil) '_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);
casFossilExpIdx = arrayfun(@(r) ['idx_X_' num2str(iSubsecFossil) '_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);

temp = arrayfun(@(x) arrayfun(@(y) ['exo_K_G_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casPublicCapital = [temp{:}];
temp = arrayfun(@(x) arrayfun(@(y) ['idx_K_G_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casPublicCapitalIdx = [temp{:}];

iSubsecRenew = find(strcmpi(casSubSectors, 'Renewables'), 1, 'first');
if isempty(iSubsecRenew)
    iSubsecRenew = min(iSubsecFossil + 1, inbsubsectors_p);
end
casTargetInv = arrayfun(@(r) ['exo_I_' num2str(iSubsecFossil) '_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);
casTargetInv = [casTargetInv, arrayfun(@(r) ['exo_I_' num2str(iSubsecRenew) '_' num2str(r)], 1:inbregions_p, 'UniformOutput', false)];
casTargetInvIdx = arrayfun(@(r) ['idx_I_' num2str(iSubsecFossil) '_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);
casTargetInvIdx = [casTargetInvIdx, arrayfun(@(r) ['idx_I_' num2str(iSubsecRenew) '_' num2str(r)], 1:inbregions_p, 'UniformOutput', false)];
casTargetIY = arrayfun(@(r) ['exo_targetIY_' num2str(iSubsecFossil) '_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);
casTargetIY = [casTargetIY, arrayfun(@(r) ['exo_targetIY_' num2str(iSubsecRenew) '_' num2str(r)], 1:inbregions_p, 'UniformOutput', false)];
casLTargetIY = arrayfun(@(r) ['exo_ltargetIY_' num2str(iSubsecFossil) '_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);
casLTargetIY = [casLTargetIY, arrayfun(@(r) ['exo_ltargetIY_' num2str(iSubsecRenew) '_' num2str(r)], 1:inbregions_p, 'UniformOutput', false)];
casLTargetInv = arrayfun(@(r) ['exo_lTargetInv_' num2str(iSubsecFossil) '_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);
casLTargetInv = [casLTargetInv, arrayfun(@(r) ['exo_lTargetInv_' num2str(iSubsecRenew) '_' num2str(r)], 1:inbregions_p, 'UniformOutput', false)];
% Switch: 1 = PV/EE gains are additive to exo_EE (autonomous trend kept);
%         0 = PV/EE are sole EE driver (exo_EE zeroed in Baseline).
temp = arrayfun(@(x) arrayfun(@(y) ['exo_lAddEE_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casLAddEE = [temp{:}];

temp = arrayfun(@(x) arrayfun(@(y) ['exo_P_K_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casInvestmentPrices = [temp{:}];
temp = arrayfun(@(x) arrayfun(@(y) ['idx_P_K_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casInvestmentPricesIdx = [temp{:}];

temp = arrayfun(@(x) arrayfun(@(y) ['exo_r_G_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casPublicRates = [temp{:}];
temp = arrayfun(@(x) arrayfun(@(y) ['idx_r_G_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casPublicRatesIdx = [temp{:}];

casEmissionPrice = [{'exo_PE'}, arrayfun(@(r) ['exo_PE_' num2str(r)], 1:inbregions_p, 'UniformOutput', false)];
casEmissionPriceIdx = [{'idx_PE'}, arrayfun(@(r) ['idx_PE_' num2str(r)], 1:inbregions_p, 'UniformOutput', false)];

casLabourForce = arrayfun(@(r) ['exo_LF_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);
casLabourForceIdx = arrayfun(@(r) ['idx_LF_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);
casNonLabourForce = arrayfun(@(r) ['exo_NLF_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);
casNonLabourForceIdx = arrayfun(@(r) ['idx_NLF_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);

temp = arrayfun(@(x) arrayfun(@(y) ['exo_AI_' num2str(x) '_' num2str(y) '_2'], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casEnergyEffSector = [temp{:}];
temp = arrayfun(@(x) arrayfun(@(y) ['idx_AI_' num2str(x) '_' num2str(y) '_2'], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casEnergyEffSectorIdx = [temp{:}];

casPVEffIdx = arrayfun(@(r) ['idx_PVEff_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);
casPVEff = arrayfun(@(r) ['exo_PVEff_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);
casPVIdx = arrayfun(@(r) ['idx_PV_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);
casPV = arrayfun(@(r) ['exo_PV_' num2str(r)], 1:inbregions_p, 'UniformOutput', false);

temp = arrayfun(@(x) arrayfun(@(y) ['exo_lIGShare_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casIGShareFlag = [temp{:}];
temp = arrayfun(@(x) arrayfun(@(y) ['exo_sIGShare_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casIGShare = [temp{:}];
temp = arrayfun(@(x) arrayfun(@(y) ['exo_lFDIShare_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casFDIShareFlag = [temp{:}];
temp = arrayfun(@(x) arrayfun(@(y) ['exo_sFDIShare_' num2str(x) '_' num2str(y)], 1:inbregions_p, 'UniformOutput', false), 1:inbsubsectors_p, 'UniformOutput', false);
casFDIShare = [temp{:}];

casCategoriesHeader = [{'Time'}, {'Year'}, {'exo_LF_1'}, {'exo_NLF_1'}, casGrowthRatesY, casGrowthRatesN, ...
    casSectorEmissionsIdx, casFossilProdIdx, casFossilExpIdx, ...
    casPublicCapitalIdx, casTargetInvIdx, casInvestmentPricesIdx, casPublicRatesIdx, casEmissionPriceIdx, ...
    casLabourForceIdx, casNonLabourForceIdx, casEnergyEffSectorIdx, casPVIdx, casPVEffIdx, ...
    casSectorEmissions, casFossilProd, casFossilExp, ...
    casPublicCapital, casTargetInv, casTargetIY, casLTargetIY, casLTargetInv, casLAddEE, casInvestmentPrices, casPublicRates, casEmissionPrice, ...
    casEnergyEffSector, casPV, casPVEff, ...
    casLKRGTarget, casKRGTarget, ...
    casIGShareFlag, casIGShare, casFDIShareFlag, casFDIShare];

nRows = 25;
if ~exist('baseYear', 'var'), baseYear = 2025; end
nBaseCols = 3; % Time + exo_LF_1 + exo_NLF_1
nGrowthCols = numel(casGrowthRatesY) + numel(casGrowthRatesN);
nIndexCols = numel(casSectorEmissionsIdx) + numel(casFossilProdIdx) + numel(casFossilExpIdx) + ...
    numel(casPublicCapitalIdx) + numel(casTargetInvIdx) + numel(casInvestmentPricesIdx) + numel(casPublicRatesIdx) + numel(casEmissionPriceIdx) + ...
    numel(casLabourForceIdx) + numel(casNonLabourForceIdx) + numel(casEnergyEffSectorIdx) + numel(casPVIdx) + numel(casPVEffIdx);
nExoPathCols = numel(casSectorEmissions) + numel(casFossilProd) + numel(casFossilExp) + ...
    numel(casPublicCapital) + numel(casTargetInv) + numel(casTargetIY) + numel(casLTargetIY) + numel(casLTargetInv) + numel(casLAddEE) + ...
    numel(casInvestmentPrices) + numel(casPublicRates) + numel(casEmissionPrice) + numel(casEnergyEffSector) + numel(casPV) + numel(casPVEff);
nTargetCols = numel(casLKRGTarget) + numel(casKRGTarget);
nShareCols = numel(casIGShareFlag) + numel(casIGShare) + numel(casFDIShareFlag) + numel(casFDIShare);

baseBlock = zeros(nRows, nBaseCols - 1);
growthBlock = ones(nRows, nGrowthCols);
indexBlock = ones(nRows, nIndexCols);
exoPathBlock = [ ...
    zeros(nRows, numel(casSectorEmissions)), ...
    zeros(nRows, numel(casFossilProd)), ...
    zeros(nRows, numel(casFossilExp)), ...
    zeros(nRows, numel(casPublicCapital)), ...
    zeros(nRows, numel(casTargetInv)), ...
    zeros(nRows, numel(casTargetIY)), ...
    zeros(nRows, numel(casLTargetIY)), ...
    ones(nRows, numel(casLTargetInv)), ...
    ones(nRows, numel(casLAddEE)), ...
    zeros(nRows, numel(casInvestmentPrices)), ...
    zeros(nRows, numel(casPublicRates)), ...
    zeros(nRows, numel(casEmissionPrice)), ...
    zeros(nRows, numel(casEnergyEffSector)), ...
    zeros(nRows, numel(casPV)), ...
    zeros(nRows, numel(casPVEff)) ...
    ];
targetBlock = zeros(nRows, nTargetCols);
shareBlock = zeros(nRows, nShareCols);
yearVals = ((2:(nRows + 1))' + baseYear - 1);
casDataNumeric = [(2:(nRows + 1))' yearVals baseBlock growthBlock indexBlock exoPathBlock targetBlock shareBlock];
casData = arrayfun(@(x) num2str(x), casDataNumeric, 'UniformOutput', false);

if size(casData, 2) ~= numel(casCategoriesHeader)
    error('define_sheets_baseline:ColumnMismatch', ...
        'Baseline header/data width mismatch: header has %d columns, data has %d columns.', ...
        numel(casCategoriesHeader), size(casData, 2));
end

casCategories = [casCategoriesHeader; casData];
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
