% ====================================
% === Define Auxiliary Expressions ===
% ====================================
% find number of sectors on subsector level
imaxsec_p = eval(['subend_' num2str(inbsectors_p) '_p']);
% find positions of initial growth parameters of gross value added
temp = arrayfun(@(y) arrayfun(@(x) ['gY0_' num2str(y) '_' num2str(x) '_p'], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casInitGrowthValues = [temp{:}];
[lSelectInitGrowthParams, iposInitGrowthParams] = ismember(casInitGrowthValues,cellstr(M_.param_names));

% find positions of initial growth parameters of employment
temp = arrayfun(@(y) arrayfun(@(x) ['gN0_' num2str(y) '_' num2str(x) '_p'], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casInitGrowthValuesN = [temp{:}];
[lSelectInitGrowthParamsN,iposInitGrowthParamsN]  = ismember(casInitGrowthValuesN,cellstr(M_.param_names));


% find positions of population shocks
casPoPShocks = arrayfun(@(x) ['exo_NLF_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectPopShocks, iposPopShocks] = ismember(casPoPShocks, cellstr(M_.exo_names));

% find positions of labour force shocks
casLFShocks = arrayfun(@(x) ['exo_LF_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectLFShocks, iposLFShocks] = ismember(casLFShocks, cellstr(M_.exo_names));


% find positions of technology shocks
temp = arrayfun(@(y) arrayfun(@(x) ['exo_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casProdShocks = [temp{:}];
[lSelectProdShocks, iposProdShocks] = ismember(casProdShocks, cellstr(M_.exo_names));
[lSelectPShocks,iposPshocks] = ismember('exo_P', cellstr(M_.exo_names));

% find positions of sectoral production
temp = arrayfun(@(y) arrayfun(@(x) ['Y_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casProdVars = [temp{:}];
[lSelectProdVars,iposProdVars] = ismember(casProdVars, cellstr(M_.endo_names));

% find positions of sectoral TFP
temp = arrayfun(@(y) arrayfun(@(x) ['A_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casAVars = [temp{:}];
[lSelectAVars,iposAVars] = ismember(casAVars, cellstr(M_.endo_names));

% find positions of sectoral labour productivity
temp = arrayfun(@(y) arrayfun(@(x) ['A_N_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casANVars = [temp{:}];
[lSelectANVars,iposANVars] = ismember(casANVars, cellstr(M_.endo_names));

% find positions of sectoral labour productivity
temp = arrayfun(@(y) arrayfun(@(x) ['A_I_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casAIVars = [temp{:}];
[lSelectAIVars,iposAIVars] = ismember(casAIVars, cellstr(M_.endo_names));



% find positions of sectoral value added prices
temp = arrayfun(@(y) arrayfun(@(x) ['P_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casPVars = [temp{:}];
[lSelectPVars,iposPVars] = ismember(casPVars, cellstr(M_.endo_names));

% find positions of technology shocks
temp = arrayfun(@(y) arrayfun(@(x) ['exo_N_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casProdNShocks = [temp{:}];
[lSelectProdShocksN, iposProdShocksN] = ismember(casProdNShocks, cellstr(M_.exo_names));

% find positions of technology shocks
temp = arrayfun(@(y) arrayfun(@(x) ['exo_QI_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casQIShocks = [temp{:}];
[lSelectProdShocksQI, iposQIShock] = ismember(casQIShocks, cellstr(M_.exo_names));

% find positions of technology shocks
temp = arrayfun(@(y) arrayfun(@(x) ['exo_A_I_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casAIShocks = [temp{:}];
[lSelectProdShocksAI, iposAIShock] = ismember(casAIShocks, cellstr(M_.exo_names));

% find positions of technology shocks
temp = arrayfun(@(y) arrayfun(@(x) ['exo_kappaE_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
caskapEShocks = [temp{:}];
[lSelectkappaEShocks, iposkapEShock] = ismember(caskapEShocks, cellstr(M_.exo_names));



% find positions of AI shocks
temp = arrayfun(@(y) arrayfun(@(x) arrayfun(@(z) ['exo_AI_' num2str(y) '_' num2str(x) '_'  num2str(z)], 1:inbsectors_p, 'UniformOutput', false), 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
temp = [temp{:}];
casAIShocks = [temp{:}];
[lSelectProdShocksAIsec, iposAIShocksec] = ismember(casAIShocks, cellstr(M_.exo_names));


% find positions of damage shocks
temp = arrayfun(@(y) arrayfun(@(x) ['exo_D_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casDamageShocks = [temp{:}];
[lSelectDamShocks,iposDamShocks] = ismember(casDamageShocks, cellstr(M_.exo_names));

% find positions of capital damage shocks
temp = arrayfun(@(y) arrayfun(@(x) ['exo_D_K_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casDamageShocks = [temp{:}];
[lSelectDamKShocks,iposDamKShocks] = ismember(casDamageShocks, cellstr(M_.exo_names));

% find positions of capital damage shocks
temp = arrayfun(@(y) arrayfun(@(x) ['exo_D_N_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casDamageShocks = [temp{:}];
[lSelectDamNShocks, iposDamNShocks] = ismember(casDamageShocks,cellstr(M_.exo_names));

% find positions of damages
temp = arrayfun(@(y) arrayfun(@(x) ['D_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casDamages = [temp{:}];
[lSelectDamages,iposDamages] = ismember(casDamages,cellstr(M_.endo_names));

% find positions of sectoral labour
temp = arrayfun(@(y) arrayfun(@(x) ['N_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casNVars = [temp{:}];
lSelectNVars = ismember(cellstr(M_.endo_names), casNVars);
[lSelectN,iposN] = ismember('N',cellstr(M_.endo_names));

% find position of price index and price shocks
lSelectPop = ismember(cellstr(M_.endo_names), 'PoP');
[lSelectPoPShock,iposPoPShock] = ismember('exo_PoP', cellstr(M_.exo_names));

% find position of price index and price shocks
casPriceShcoks = arrayfun(@(x)['exo_P_D_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
lSelectP = ismember(cellstr(M_.endo_names), 'P_D');
[lSelectPriceShock, iposPriceShock] = ismember(casPriceShcoks, cellstr(M_.exo_names));

% find position of price index and price shocks
casDHVars = arrayfun(@(x)['DH_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
casDHShocks = arrayfun(@(x)['exo_DH_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectDamH,iposDamH] = ismember(casDHVars, cellstr(M_.endo_names));
[lSelectDamHShock,iposDamHShock] = ismember(casDHShocks, cellstr(M_.exo_names));


% find position of house price index and house price shocks
casPHVars = arrayfun(@(x)['PH_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
casHShocks = arrayfun(@(x)['exo_H_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectPH,iposPH] = ismember(casPHVars, cellstr(M_.endo_names));
[lSelectPriceHShock,iposPriceHShock] = ismember(casHShocks, cellstr(M_.exo_names));

% find position of exchange rate vauation shocks
casadjBVars = arrayfun(@(x)['adjB_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
casadjBShocks = arrayfun(@(x)['exo_adjB_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectadjB,iposadjB] = ismember(casadjBVars, cellstr(M_.endo_names));
[lSelectadjBShock,iposadjBShock] = ismember(casadjBShocks, cellstr(M_.exo_names));

% find position of depreciation shocks
casdeltaBVars = arrayfun(@(x)['deltaB_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
casdeltaBShocks = arrayfun(@(x)['exo_deltaB_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectdeltaB,iposdeltaB] = ismember(casdeltaBVars, cellstr(M_.endo_names));
[lSelectdeltaBShock,iposdeltaBShock] = ismember(casdeltaBShocks, cellstr(M_.exo_names));

% find position of nfa to GDP ratio
casBVars = arrayfun(@(x)['B_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
casBShocks = arrayfun(@(x)['exo_B_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectB,iposB] = ismember(casBVars, cellstr(M_.endo_names));
[lSelectBShock,iposBShock] = ismember(casBShocks, cellstr(M_.exo_names));


% find position of deptreciation shocks
casNXVars = arrayfun(@(x)['NX_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
casNXShocks = arrayfun(@(x)['exo_NX_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectNX,iposNX] = ismember(casNXVars, cellstr(M_.endo_names));
[lSelectNXShock,iposNXShock] = ismember(casNXShocks, cellstr(M_.exo_names));


% find position of emission price and shock
[lSelectPE,iposPE] = ismember('PE', cellstr(M_.endo_names));
[lSelectPEShock,iposPEShock] = ismember('exo_PE', cellstr(M_.exo_names));

% find position of emission price and shoc
[lSelectLFShock,iposLFShock] = ismember('exo_LF', cellstr(M_.exo_names));


% find position of regional emission shocks
casEShocks  = arrayfun(@(x)['exo_E_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectERegShocks,iposERegShocks] = ismember(casEShocks, cellstr(M_.exo_names));

% find position of regional emission shocks
casEEShocks  = arrayfun(@(x)['exo_EE_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectEERegShocks,iposEERegShocks] = ismember(casEEShocks, cellstr(M_.exo_names));


% find position of regional emission shocks
casEShocks  = arrayfun(@(x)['exo_EBase_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectEBaseRegShocks,iposEBaseRegShocks] = ismember(casEShocks, cellstr(M_.exo_names));

% find position of regional emission shocks
casPEShocks  = arrayfun(@(x)['exo_PE_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectPERegShocks,iposPERegShocks] = ismember(casPEShocks, cellstr(M_.exo_names));

% find position of emission price and shock
[lSelectE,iposE] = ismember('E', cellstr(M_.endo_names));
[lSelectEShock,iposEShock] = ismember('exo_E', cellstr(M_.exo_names));



% find position of regional emission shocks
casEReg  = arrayfun(@(x)['E_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectEReg,iposEReg] = ismember(casEReg, cellstr(M_.endo_names));


% find position of regional energy efficiency 
casEEReg  = arrayfun(@(x)['EE_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectEEReg,iposEEReg] = ismember(casEEReg, cellstr(M_.endo_names));


% find positions of emission efficiency shocks
temp = arrayfun(@(y) arrayfun(@(x) ['exo_Q_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casQShocks = [temp{:}];
[lSelectQShocks, iposQShocks] = ismember(casQShocks,cellstr(M_.exo_names));


% find positions of emission efficiency shocks
temp = arrayfun(@(z) arrayfun(@(y) arrayfun(@(x) ['exo_EI_' num2str(y) '_' num2str(x) '_' num2str(z)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false), 1:inbsectors_p, 'UniformOutput', false);
temp = [temp{:}]; casEmiShocks = [temp{:}];
[lSelectEmiShocks, iposEmiShocks] = ismember(casEmiShocks,cellstr(M_.exo_names));

% find positions of export shocks
temp = arrayfun(@(y) arrayfun(@(x) ['exo_X_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casExpShocks = [temp{:}];
[lSelectExpShocks, iposExpShocks] = ismember(casExpShocks,cellstr(M_.exo_names));

% find positions of emission shocks
temp = arrayfun(@(y) arrayfun(@(x) ['exo_E_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casEmiShocks = [temp{:}];
[lSelectEmShocks, iposEmShocks] = ismember(casEmiShocks,cellstr(M_.exo_names));

% find positions of emission intensity shocks
temp = arrayfun(@(y) arrayfun(@(x) ['kappaE_' num2str(y) '_' num2str(x)], 1:inbregions_p, 'UniformOutput', false), 1:imaxsec_p, 'UniformOutput', false);
casEmiIntVars = [temp{:}];
[lSelectkappaE, iposkappaE] = ismember(casEmiIntVars,cellstr(M_.endo_names));


% find subsidies 
castauSTrShocks  = arrayfun(@(x)['exo_tauSTr_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectTauSTrShocks,iposTauSTrShocks] = ismember(castauSTrShocks, cellstr(M_.exo_names));


% find import pricess 
casPMprices  = arrayfun(@(x)['P_M_' num2str(x)], 1:inbsubsectors_p, 'UniformOutput', false);
[lSelectPMPrices,iposPMPrices] = ismember(casPMprices, cellstr(M_.endo_names));

casPMshocks  = arrayfun(@(x)['exo_M_' num2str(x)], 1:inbsubsectors_p, 'UniformOutput', false);
[lSelectPMShocks,iposPMShocks] = ismember(casPMshocks, cellstr(M_.exo_names));


% find transfers
castauSShocks  = arrayfun(@(x)['exo_tauS_' num2str(x)], 1:inbregions_p, 'UniformOutput', false);
[lSelectTauSShocks,iposTauSShocks] = ismember(castauSShocks, cellstr(M_.exo_names));

% find net export shocks
[lSelectrfShock, iposrfShock] = ismember('exo_rf', cellstr(M_.exo_names));

% find net export shocks
[lSelectpiMShock, ipospiMShock] = ismember('exo_piM', cellstr(M_.exo_names));