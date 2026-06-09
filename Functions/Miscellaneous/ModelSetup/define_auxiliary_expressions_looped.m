% =======================================================
% === Define Auxiliary Expressions (Looped Refactor) ====
% =======================================================
% This script reduces repetition by using a spec table and
% looping through variable/shock definitions.

% cached name lists
paramNames = cellstr(M_.param_names);
endoNames  = cellstr(M_.endo_names);
exoNames   = cellstr(M_.exo_names);

% find number of sectors on subsector level
imaxsec_p = eval(['subend_' num2str(inbsectors_p) '_p']);

% === Spec table for generated names ===
% fields:
%   prefix: string prefix
%   dims:   [y x z] dimension sizes (use 0 for unused)
%   target: 'param' | 'endo' | 'exo'
%   outNamesVar: name of variable to store generated names
%   outSelectVar: name of logical selection output
%   outPosVar: name of index output
specs = {
    % initial growth parameters
    'gY0_',   [imaxsec_p, inbregions_p, 0],  'param', 'casInitGrowthValues',  'lSelectInitGrowthParams',  'iposInitGrowthParams'
    'gN0_',   [imaxsec_p, inbregions_p, 0],  'param', 'casInitGrowthValuesN', 'lSelectInitGrowthParamsN', 'iposInitGrowthParamsN'
    'phiG_',   [imaxsec_p, inbregions_p, 0],  'param', 'casIGShares', 'lSelectIGShares', 'iposIGShares'

    % population and labour force shocks
    'exo_NLF_', [inbregions_p, 0, 0], 'exo', 'casPoPShocks',  'lSelectPopShocks', 'iposPopShocks'
    'exo_LF_',  [inbregions_p, 0, 0], 'exo', 'casLFShocks',   'lSelectLFShocks',  'iposLFShocks'
    'exo_REShare_',  [inbregions_p, 0, 0], 'exo', 'casREShocks',   'lSelectREShocks',  'iposREShocks'
    'exo_PV_',  [inbregions_p, 0, 0], 'exo', 'casPVShocks',   'lSelectPVShocks',  'iposPVShocks'
    'exo_PVEff_',  [inbregions_p, 0, 0], 'exo', 'casPVEffShocks',   'lSelectPVEffShocks',  'iposPVEffShocks'
    % technology and production
    'exo_',   [imaxsec_p, inbregions_p, 0],  'exo',  'casProdShocks', 'lSelectProdShocks', 'iposProdShocks'
    'exo_A_',   [imaxsec_p, inbregions_p, 0],  'exo',  'casProdAShocks', 'lSelectProdAShocks', 'iposProdAShocks'
    'exo_I_',   [imaxsec_p, inbregions_p, 0],  'exo',  'casProdIShocks',  'lSelectProdIShocks',  'iposProdIShocks'
    'exo_I_P_', [imaxsec_p, inbregions_p, 0],  'exo',  'casProdIPShocks', 'lSelectProdIPShocks', 'iposProdIPShocks'
    'exo_u_K_',   [imaxsec_p, inbregions_p, 0],  'exo',  'casUShocks', 'lSelectUShocks', 'iposUShocks'
    'exo_KTarget_',   [imaxsec_p, inbregions_p, 0],  'exo',  'casKTarShocks', 'lSelectKTarShocks', 'iposKTarShocks'
    'exo_KTargetB_',   [imaxsec_p, inbregions_p, 0],  'exo',  'casKTarBShocks', 'lSelectKTarBShocks', 'iposKTarBShocks'
    'Y_',     [imaxsec_p, inbregions_p, 0],  'endo', 'casProdVars',   'lSelectProdVars',   'iposProdVars'
    'I_H_',     [imaxsec_p, inbregions_p, 0],  'endo', 'casIHVars',   'lSelectIHVars',   'iposIHVars'
    'I_G_',     [imaxsec_p, inbregions_p, 0],  'endo', 'casIGVars',   'lSelectIGVars',   'iposIGVars'
    'K_G_',     [imaxsec_p, inbregions_p, 0],  'endo', 'casKGVars',   'lSelectKGVars',   'iposKGVars'
    'I_',     [imaxsec_p, inbregions_p, 0],  'endo', 'casIVars',   'lSelectIVars',   'iposIVars'
    'I_P_',   [imaxsec_p, inbregions_p, 0],  'endo', 'casIPVars',  'lSelectIPVars',  'iposIPVars'
    'A_',     [imaxsec_p, inbregions_p, 0],  'endo', 'casAVars',      'lSelectAVars',      'iposAVars'
    'A_N_',   [imaxsec_p, inbregions_p, 0],  'endo', 'casANVars',     'lSelectANVars',     'iposANVars'
    'A_D_',   [imaxsec_p, inbregions_p, 0],  'endo', 'casADVars',     'lSelectADVars',     'iposADVars'
    'A_I_',   [imaxsec_p, inbregions_p, 0],  'endo', 'casAIVars',     'lSelectAIVars',     'iposAIVars'
    'P_',     [imaxsec_p, inbregions_p, 0],  'endo', 'casPVars',      'lSelectPVars',      'iposPVars'

    % factor-specific tech shocks
    'exo_N_',     [imaxsec_p, inbregions_p, 0], 'exo', 'casProdNShocks', 'lSelectProdShocksN', 'iposProdShocksN'
    'exo_QI_',    [imaxsec_p, inbregions_p, 0], 'exo', 'casQIShocks',    'lSelectProdShocksQI', 'iposQIShock'
    'exo_A_I_',   [imaxsec_p, inbregions_p, 0], 'exo', 'casAIShocks',    'lSelectProdShocksAI', 'iposAIShock'
    'exo_A_D_',   [imaxsec_p, inbregions_p, 0], 'exo', 'casADShocks',    'lSelectProdShocksAD', 'iposADShock'
    'exo_kappaE_', [imaxsec_p, inbregions_p, 0], 'exo', 'caskapEShocks', 'lSelectkappaEShocks', 'iposkapEShock'
    'exo_kappaE_NOETS_', [imaxsec_p, inbregions_p, 0], 'exo', 'caskapENOETSShocks', 'lSelectkappaENOETSShocks', 'iposkapENOETSShock'
    'exo_E_NOETS_', [imaxsec_p, inbregions_p, 0], 'exo', 'casENOETSShocks', 'lSelectENOETSShocks', 'iposENOETSShocks'
    'wedgeKE_',    [imaxsec_p, inbregions_p, 0], 'endo', 'casWedgeVars',   'lSelectWedgeVars',   'iposWedgeVars'
    'exo_wedgeKE_',[imaxsec_p, inbregions_p, 0], 'exo',  'casWedgeShocks', 'lSelectWedgeShocks', 'iposWedgeShocks'

    % AI shocks (3d)
    'exo_AI_', [imaxsec_p, inbregions_p, inbsectors_p], 'exo', 'casAIShocksSec', 'lSelectProdShocksAIsec', 'iposAIShocksec'
    'exo_A_F_',   [inbsectors_p, inbregions_p, 0], 'exo', 'casAFShocks',    'lSelectProdShocksAF', 'iposAFShock'
    % damage shocks and damages
    'exo_D_',   [imaxsec_p, inbregions_p, 0], 'exo',  'casDamageShocks', 'lSelectDamShocks',  'iposDamShocks'
    'exo_D_K_', [imaxsec_p, inbregions_p, 0], 'exo',  'casDamageKShocks', 'lSelectDamKShocks', 'iposDamKShocks'
    'exo_D_N_', [imaxsec_p, inbregions_p, 0], 'exo',  'casDamageNShocks', 'lSelectDamNShocks', 'iposDamNShocks'
    'D_',       [imaxsec_p, inbregions_p, 0], 'endo', 'casDamages',      'lSelectDamages',    'iposDamages'

    % sectoral labour
    'N_', [imaxsec_p, inbregions_p, 0], 'endo', 'casNVars', 'lSelectNVarsByName', 'iposNVars'

    % price shocks (regional)
    'exo_P_D_', [inbregions_p, 0, 0], 'exo', 'casPriceShocks', 'lSelectPriceShock', 'iposPriceShock'

    % housing damages and shocks
    'DH_',     [inbregions_p, 0, 0], 'endo', 'casDHVars',   'lSelectDamH',      'iposDamH'
    'exo_DH_', [inbregions_p, 0, 0], 'exo',  'casDHShocks', 'lSelectDamHShock', 'iposDamHShock'

    % house prices and shocks
    'PH_',   [inbregions_p, 0, 0], 'endo', 'casPHVars',  'lSelectPH',          'iposPH'
    'exo_H_', [inbregions_p, 0, 0], 'exo', 'casHShocks', 'lSelectPriceHShock', 'iposPriceHShock'

    % exchange rate valuation and depreciation
    'adjB_',      [inbregions_p, 0, 0], 'endo', 'casadjBVars',   'lSelectadjB',      'iposadjB'
    'exo_adjB_',  [inbregions_p, 0, 0], 'exo',  'casadjBShocks', 'lSelectadjBShock', 'iposadjBShock'
    'deltaB_',    [inbregions_p, 0, 0], 'endo', 'casdeltaBVars',   'lSelectdeltaB',      'iposdeltaB'
    'exo_deltaB_', [inbregions_p, 0, 0], 'exo', 'casdeltaBShocks', 'lSelectdeltaBShock', 'iposdeltaBShock'

    % nfa to GDP, net exports
    'B_',     [inbregions_p, 0, 0], 'endo', 'casBVars',   'lSelectB',      'iposB'
    'exo_B_', [inbregions_p, 0, 0], 'exo',  'casBShocks', 'lSelectBShock', 'iposBShock'
    'NX_',     [inbregions_p, 0, 0], 'endo', 'casNXVars',   'lSelectNX',      'iposNX'
    'exo_NX_', [inbregions_p, 0, 0], 'exo',  'casNXShocks', 'lSelectNXShock', 'iposNXShock'

    % regional emissions and energy efficiency
    'exo_E_',     [inbregions_p, 0, 0], 'exo',  'casERegShocks',     'lSelectERegShocks',     'iposERegShocks'
    'exo_EE_',    [inbregions_p, 0, 0], 'exo',  'casEERegShocks',    'lSelectEERegShocks',    'iposEERegShocks'
    'exo_lAddEE_',[imaxsec_p, inbregions_p, 0], 'exo', 'casLAddEEShocks', 'lSelectLAddEEShocks', 'iposLAddEEShocks'
    'exo_EBase_', [inbregions_p, 0, 0], 'exo',  'casEBaseRegShocks', 'lSelectEBaseRegShocks', 'iposEBaseRegShocks'
    'exo_PE_',    [inbregions_p, 0, 0], 'exo',  'casPERegShocks',    'lSelectPERegShocks',    'iposPERegShocks'
    'E_',         [inbregions_p, 0, 0], 'endo', 'casEReg',           'lSelectEReg',           'iposEReg'
    'EE_',        [inbregions_p, 0, 0], 'endo', 'casEEReg',          'lSelectEEReg',          'iposEEReg'

    % emission efficiency and export shocks
    'exo_Q_',  [imaxsec_p, inbregions_p, 0], 'exo', 'casQShocks',     'lSelectQShocks',  'iposQShocks'
    'exo_EI_', [imaxsec_p, inbregions_p, inbsectors_p], 'exo', 'casEmiShocks3d', 'lSelectEmiShocks', 'iposEmiShocks'
    'exo_X_',  [imaxsec_p, inbregions_p, 0], 'exo', 'casExpShocks',   'lSelectExpShocks', 'iposExpShocks'
    'exo_E_',  [imaxsec_p, inbregions_p, 0], 'exo', 'casEmiShocks2d', 'lSelectEmShocks',  'iposEmShocks'
    'kappaE_', [imaxsec_p, inbregions_p, 0], 'endo', 'casEmiIntVars', 'lSelectkappaE', 'iposkappaE'
    'kappaE_NOETS_', [imaxsec_p, inbregions_p, 0], 'endo', 'casEmiIntNOETSVars', 'lSelectkappaENOETS', 'iposkappaENOETS'

    % tax and interest rate shocks
    'exo_tauKH_', [imaxsec_p, inbregions_p, 0], 'exo', 'castauKHShocks',  'lSelecttauKFShocks',  'ipostauKHShocks'
    'exo_tauKF_', [imaxsec_p, inbregions_p, 0], 'exo', 'castauKFShocks',  'lSelecttauKFShocks',  'ipostauKFShocks'
    'exo_phiK_',  [imaxsec_p, inbregions_p, 0], 'exo', 'castauphiKShocks','lSelectphiKShocks',   'iposphiKShocks'
    'exo_r_',     [imaxsec_p, inbregions_p, 0], 'exo', 'casrShocksR',     'lSelectrShocks',      'iposrShocks'
    'exo_r_G_',        [imaxsec_p, inbregions_p, 0], 'exo', 'casrShocksrG',       'lSelectrGShocks',        'iposrGShocks'
    'exo_K_G_',        [imaxsec_p, inbregions_p, 0], 'exo', 'casKGShocks',        'lSelectKGShocks',        'iposKGShocks'
    'exo_GA_',        [imaxsec_p, inbregions_p, 0], 'exo', 'casGAShocks',        'lSelectGAShocks',        'iposGAShocks'
    'exo_lKRGTarget_', [imaxsec_p, inbregions_p, 0], 'exo', 'casLKRGTargetShocks','lSelectLKRGTargetShocks', 'iposLKRGTargetShocks'
    'exo_KRGTarget_',  [imaxsec_p, inbregions_p, 0], 'exo', 'casKRGTargetShocks', 'lSelectKRGTargetShocks',  'iposKRGTargetShocks'
    'exo_lIGShare_',   [imaxsec_p, inbregions_p, 0], 'exo', 'casLIGShareShocks',  'lSelectLIGShareShocks',   'iposLIGShareShocks'
    'exo_sIGShare_',   [imaxsec_p, inbregions_p, 0], 'exo', 'cassIGShareShocks',  'lSelectsIGShareShocks',   'ipossIGShareShocks'
    'exo_lFDIShare_',  [imaxsec_p, inbregions_p, 0], 'exo', 'casLFDIShareShocks', 'lSelectLFDIShareShocks',  'iposLFDIShareShocks'
    'exo_sFDIShare_',  [imaxsec_p, inbregions_p, 0], 'exo', 'cassFDIShareShocks', 'lSelectsFDIShareShocks',  'ipossFDIShareShocks'
    'exo_phiG_',  [imaxsec_p, inbregions_p, 0], 'exo', 'casphiGShocks',   'lSelectphiGShocks',   'iposphiGShocks'
    'exo_s_G_',   [imaxsec_p, inbregions_p, 0], 'exo', 'casrShockssG',    'lSelectsGShocks',     'ipossGShocks'
    'exo_s_GScen_',   [imaxsec_p, inbregions_p, 0], 'exo', 'casrShockssGScen',    'lSelectsGScenShocks',     'ipossGScenShocks'
    'exo_P_K_',   [imaxsec_p, inbregions_p, 0], 'exo', 'casrShocksPK',    'lSelectPKShocks',     'iposPKShocks'
    'P_K_',   [imaxsec_p, inbregions_p, 0], 'endo', 'casVarsPK',    'lSelectPKVars',     'iposPKVars'
    'exo_targetIY_',    [imaxsec_p, inbregions_p, 0], 'exo', 'casTargetIYShocks',   'lSelectTargetIYShocks',  'iposTargetIYShocks'
    'exo_A_INV_',       [imaxsec_p, inbregions_p, 0], 'exo', 'casAINVShocks',       'lSelectAINVShocks',      'iposAINVShocks'
    'exo_ltargetIY_',  [imaxsec_p, inbregions_p, 0], 'exo', 'casLTargetIYShocks',  'lSelectLTargetIYShocks', 'iposLTargetIYShocks'
    'A_INV_',           [imaxsec_p, inbregions_p, 0], 'endo', 'casAINVVars',         'lSelectAINVVars',        'iposAINVVars'
    'K_FDI_',    [imaxsec_p, inbregions_p, 0], 'endo', 'casKFDIVars',   'lSelectKFDIVars',   'iposKFDIVars'
    'I_FDI_',    [imaxsec_p, inbregions_p, 0], 'endo', 'casIFDIVars',   'lSelectIFDIVars',   'iposIFDIVars'
    'r_FDI_',    [imaxsec_p, inbregions_p, 0], 'endo', 'casrFDIVars',   'lSelectrFDIVars',   'iposrFDIVars'
    'exo_r_FDI_',[imaxsec_p, inbregions_p, 0], 'exo',  'casrFDIShocks', 'lSelectrFDIShocks', 'iposrFDIShocks'
    'exo_rexo_',  [imaxsec_p, inbregions_p, 0], 'exo', 'casrShocksRexo',  'lSelectrexoShocks',   'iposrexoShocks'

    % sectoral labour (r_H)
    'r_H_', [imaxsec_p, inbregions_p, 0], 'endo', 'casrVars', 'lSelectrVars', 'iposrVars'

    % subsidies and transfers
    'exo_tauSTr_', [inbregions_p, 0, 0], 'exo', 'castauSTrShocks', 'lSelectTauSTrShocks', 'iposTauSTrShocks'
    'exo_tauS_',   [inbregions_p, 0, 0], 'exo', 'castauSShocks',   'lSelectTauSShocks',   'iposTauSShocks'

    % import prices and shocks
    'P_M_',   [inbsubsectors_p, 0, 0], 'endo', 'casPMprices', 'lSelectPMPrices', 'iposPMPrices'
    'exo_M_', [inbsubsectors_p, 0, 0], 'exo',  'casPMshocks', 'lSelectPMShocks', 'iposPMShocks'
    
    % single-name lookups (dims [0,0,0] means use prefix as exact name)
    'exo_P',    [0, 0, 0], 'exo',  'casPShocks_single',   'lSelectPShocks',   'iposPshocks'
    'N',        [0, 0, 0], 'endo', 'casN_single',         'lSelectN',         'iposN'
    'PoP',      [0, 0, 0], 'endo', 'casPop_single',       'lSelectPop',       'iposPop'
    'exo_PoP',  [0, 0, 0], 'exo',  'casPoPShock_single',  'lSelectPoPShock',  'iposPoPShock'
    'P_D',      [0, 0, 0], 'endo', 'casP_single',         'lSelectP',         'iposP'
    'PE',       [0, 0, 0], 'endo', 'casPE_single',        'lSelectPE',        'iposPE'
    'exo_PE',   [0, 0, 0], 'exo',  'casPEShock_single',   'lSelectPEShock',   'iposPEShock'
    'exo_LF',   [0, 0, 0], 'exo',  'casLFShock_single',   'lSelectLFShock',   'iposLFShock'
    'E',        [0, 0, 0], 'endo', 'casE_single',         'lSelectE',         'iposE'
    'exo_E',    [0, 0, 0], 'exo',  'casEShock_single',    'lSelectEShock',    'iposEShock'
    'exo_rf',   [0, 0, 0], 'exo',  'casrfShock_single',   'lSelectrfShock',   'iposrfShock'
    'exo_piM',  [0, 0, 0], 'exo',  'caspiMShock_single',  'lSelectpiMShock',  'ipospiMShock'
};

% === Initialize position index structure ===
posIdx = struct();

% === Execute specs ===
for i = 1:size(specs, 1)
    prefix = specs{i, 1};
    dims = specs{i, 2};
    target = specs{i, 3};
    outNamesVar = specs{i, 4};
    outSelectVar = specs{i, 5};
    outPosVar = specs{i, 6};

    % Check if this is a single-name lookup (all dims are 0)
    if all(dims == 0)
        names = {prefix};  % Use prefix as exact name
    else
        names = build_names(prefix, dims(1), dims(2), dims(3));
    end
    assignin('caller', outNamesVar, names);

    switch target
        case 'param'
            namespar = cellfun(@(x) [x '_p'], names, 'UniformOutput',false);
            [lSelect, ipos] = ismember(namespar, paramNames);
        case 'endo'
            [lSelect, ipos] = ismember(names, endoNames);
        otherwise
            [lSelect, ipos] = ismember(names, exoNames);
    end

    assignin('caller', outSelectVar, lSelect);
    assignin('caller', outPosVar, ipos);
    
    % Store in structure
    posIdx.(outPosVar) = ipos;
end

% match original lSelectNVars behavior (logical mask over endo names)
if exist('casNVars', 'var')
    lSelectNVars = ismember(endoNames, casNVars);
end

% Backward-compatible aliases for older scripts/configs that referred to
% the public-capital stock shock as a public-investment shock.
if isfield(posIdx, 'iposKGShocks')
    posIdx.iposIGShocks = posIdx.iposKGShocks;
    iposIGShocks = posIdx.iposKGShocks;
    lSelectIGShocks = lSelectKGShocks;
    casIGShocks = casKGShocks;
end

% === Assign position index structure to caller workspace ===
assignin('caller', 'posIdx', posIdx);

% =====================
% === Local helpers ===
% =====================
function names = build_names(prefix, yMax, xMax, zMax)
    if zMax > 0
        temp = arrayfun(@(z) arrayfun(@(y) arrayfun(@(x) [prefix num2str(y) '_' num2str(x) '_' num2str(z)], 1:xMax, 'UniformOutput', false), 1:yMax, 'UniformOutput', false), 1:zMax, 'UniformOutput', false);
        temp = [temp{:}];
        names = [temp{:}];
    elseif xMax > 0
        temp = arrayfun(@(y) arrayfun(@(x) [prefix num2str(y) '_' num2str(x)], 1:xMax, 'UniformOutput', false), 1:yMax, 'UniformOutput', false);
        names = [temp{:}];
    else
        names = arrayfun(@(x) [prefix num2str(x)], 1:yMax, 'UniformOutput', false);
    end
end
