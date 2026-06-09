% CreateBaselineFromPathDefinitionLite  Build runnable Baseline sheet from path definitions only.
%
% Run from the repository root:
%   run('scripts/maintenance/CreateBaselineFromPathDefinitionLite.m')
%
% Input mode is fixed to dedicated path workbook:
%   ExcelFiles/ScenarioPathDefinition.xlsx (sheet "Baseline")
%
% This lite variant mirrors the baseline-writing behavior of
% CreateBaselineFromUserInputFile in dedicated-path mode, but it disables
% all optional external data dependencies (PDP8, calibration workbook,
% RTS split CSV/workbook refresh, and post-run output checks).

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

% Execution is fixed to dedicated-path mode.

% Keep source strictly limited to ScenarioPathDefinition definitions.
UsePDP8InvestmentTargets = false;

% GDP anchor (MIOUSD) used to convert PDP8 investment levels into shares of GDP.
ProjectedGDPBaseYear = 2025;
ProjectedGDPBaseValueMioUSD = 430000;

% Optional: map industrial rooftop PV deployment to direct EE gains in
% industry/services (subsectors 4 and 5) in the baseline sheet.
EnableIndustrialPVtoEECoupling = false;
IndustrialPVChannelImportKey = "exo_PV_Ind_1"; % falls back to exo_PV_1 when missing
% Use revised PDP8 high path as the reference RTS totals when available.
UseRevisedPDP8HighAsReference = false;
% Optional: create sectoral rooftop-solar shock paths from Vietnam RTS
% assumptions CSV (industry/commercial/residential).
EnableGovernmentRTSSectorPVShocks = false;
% Target subsectors for routing industrial/commercial RTS through exo_GA.
% Defaults: 4=Secondary (industry), 5=Tertiary (commercial/services).
IndustrialPVGATargetSubsector = 4;
CommercialPVGATargetSubsector = 5;
% Fallback split when RTS CSV has only household capacity and no explicit
% commercial/residential split.
RTSCommercialShareOfHousehold = 0.30;
% Keep calibration parameters fixed to local defaults in this lite mode.
UseCalibrationParametersIfAvailable = false;
% Fallback value when calibration parameter cannot be read.
DeltaPVForRTSInvestmentIndex_Default = 0.10;
PhiKPV0ForRTSInvestmentScale_Default = 0.03;
% Fallback demand-reduction caps (used only when RTS generation data are unavailable).
% Primary path uses gen/demand fractions from the RTS CSV directly.
IndustrialPVMaxDemandReduction_Secondary = 0.08;   % legacy fallback (7-9% midpoint)
IndustrialPVMaxDemandReduction_Tertiary  = 0.075;  % legacy fallback (6-9% midpoint)

% Vietnam 2025 sectoral electricity demand anchors for PV coverage fractions.
% Source: PDP8 reference demand ~335 TWh; industry 53%, commercial 17%.
IndustrialElecDemandBase_GWh = 177550;   % 0.53 × 335,000 GWh
CommercialElecDemandBase_GWh = 56950;    % 0.17 × 335,000 GWh
ElecDemandAnnualGrowth_Ind   = 0.040;    % assumed annual demand growth
ElecDemandAnnualGrowth_Com   = 0.040;

% VNEEP3 sector-specific EE targets (Decision 280/QD-TTg, 2019-2030).
% These add to exo_AI_s_1_2 (effectiveness) and exo_GA_s_1 (cost) on top of PV paths.
%
% AI rates: additional log-productivity of energy intermediates from non-PV EE measures
%   (insulation, motors, building management systems, process efficiency).
% GA rates: additional adaptation capital (share of Y0_p per year) for EE investment
%   costs; cumulates linearly into K_A beyond what PV capacity already provides.
% EE mode switch: true  = PV/VNEEP3 are ADDITIVE to exo_EE_r (autonomous trend kept).
%                 false = PV/VNEEP3 are SOLE EE driver; exo_EE_r zeroed in Baseline.
EEAdditiveMode = true;

EnableVNEEP3EETargets = false;
VNEEP3_Ind_AIRate_To2030   = 0.005;   % log-pts/yr, industry 2025-2030 (~0.5%/yr)
VNEEP3_Ind_AIRate_Post2030 = 0.003;   % log-pts/yr, industry post-2030
VNEEP3_Com_AIRate_To2030   = 0.020;   % log-pts/yr, commercial 2025-2030 (~2%/yr)
VNEEP3_Com_AIRate_Post2030 = 0.010;   % log-pts/yr, commercial post-2030
VNEEP3_Ind_GARate_To2030   = 0.003;   % K_A increment/yr as share of Y0_p, industry
VNEEP3_Ind_GARate_Post2030 = 0.002;
VNEEP3_Com_GARate_To2030   = 0.002;   % K_A increment/yr as share of Y0_p, commercial
VNEEP3_Com_GARate_Post2030 = 0.001;

% Lite mode must not pull NOETS paths from external workbooks.
% exo_E_NOETS_* values should come from ScenarioPathDefinition labels only.
EnableNonPowerNOETSBaselinePath = false;
NonPowerNOETSWorkbook = fullfile(repoRoot, 'ExcelFiles', 'PDP8', 'Emissions_IEA_Overall_PDP8.xlsx');
NonPowerNOETSSeriesName = "NonPower_BSL";

dedicatedPathWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ScenarioPathDefinition.xlsx');

% Resolve calibration-backed parameters (fallback to defaults when missing).
DeltaPVForRTSInvestmentIndex = DeltaPVForRTSInvestmentIndex_Default;
PhiKPV0ForRTSInvestmentScale = PhiKPV0ForRTSInvestmentScale_Default;
if UseCalibrationParametersIfAvailable
    calibrationWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelCalibration5Sectorsand1Regions.xlsx');
    [deltaPVCalib, foundDeltaPV] = read_calibration_parameter_value(calibrationWorkbook, 'deltaPV_p');
    [phiKPV0Calib, foundphiKPV0] = read_calibration_parameter_value(calibrationWorkbook, 'phiKPV0_p');
    if foundDeltaPV
        DeltaPVForRTSInvestmentIndex = deltaPVCalib;
        fprintf('  Using calibration parameter deltaPV_p=%.6f for RTS investment-index conversion.\n', deltaPVCalib);
    else
        fprintf('  Calibration parameter deltaPV_p not found; using fallback %.6f.\n', DeltaPVForRTSInvestmentIndex_Default);
    end
    if foundphiKPV0
        PhiKPV0ForRTSInvestmentScale = phiKPV0Calib;
        fprintf('  Using calibration parameter phiKPV0_p=%.6f for RTS investment scaling.\n', phiKPV0Calib);
    else
        fprintf('  Calibration parameter phiKPV0_p not found; using fallback %.6f.\n', PhiKPV0ForRTSInvestmentScale_Default);
    end
end

% Runnable baseline workbook where sheet "Baseline" is rebuilt.
targetWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelBaseline5Sectorsand1Regions.xlsx');

dedicatedInputs = import_dedicated_path_inputs(dedicatedPathWorkbook);
dedicatedInputs.repoRoot = repoRoot;
dedicatedInputs.usePDP8InvestmentTargets = UsePDP8InvestmentTargets;
dedicatedInputs.projectedGDPBaseYear = ProjectedGDPBaseYear;
dedicatedInputs.projectedGDPBaseValueMioUSD = ProjectedGDPBaseValueMioUSD;
dedicatedInputs.enableIndustrialPVtoEECoupling = EnableIndustrialPVtoEECoupling;
dedicatedInputs.industrialPVChannelImportKey = char(IndustrialPVChannelImportKey);
dedicatedInputs.useRevisedPDP8HighAsReference = logical(UseRevisedPDP8HighAsReference);
dedicatedInputs.enableGovernmentRTSSectorPVShocks = EnableGovernmentRTSSectorPVShocks;
dedicatedInputs.industrialPVGATargetSubsector = IndustrialPVGATargetSubsector;
dedicatedInputs.commercialPVGATargetSubsector = CommercialPVGATargetSubsector;
dedicatedInputs.rtsCommercialShareOfHousehold = RTSCommercialShareOfHousehold;
dedicatedInputs.deltaPVForRTSInvestmentIndex = DeltaPVForRTSInvestmentIndex;
dedicatedInputs.phiKPV0ForRTSInvestmentScale = PhiKPV0ForRTSInvestmentScale;
dedicatedInputs.pvPath = dedicatedInputs.pvPath.*dedicatedInputs.phiKPV0ForRTSInvestmentScale;
dedicatedInputs.industrialPVMaxDemandReductionSecondary = IndustrialPVMaxDemandReduction_Secondary;
dedicatedInputs.industrialPVMaxDemandReductionTertiary = IndustrialPVMaxDemandReduction_Tertiary;
dedicatedInputs.industrialElecDemandBaseGWh = IndustrialElecDemandBase_GWh;
dedicatedInputs.commercialElecDemandBaseGWh = CommercialElecDemandBase_GWh;
dedicatedInputs.elecDemandAnnualGrowthInd   = ElecDemandAnnualGrowth_Ind;
dedicatedInputs.elecDemandAnnualGrowthCom   = ElecDemandAnnualGrowth_Com;
dedicatedInputs.eeAdditiveMode              = EEAdditiveMode;
dedicatedInputs.enableVNEEP3EETargets       = EnableVNEEP3EETargets;
dedicatedInputs.vneep3IndAIRateTo2030       = VNEEP3_Ind_AIRate_To2030;
dedicatedInputs.vneep3IndAIRatePost2030     = VNEEP3_Ind_AIRate_Post2030;
dedicatedInputs.vneep3ComAIRateTo2030       = VNEEP3_Com_AIRate_To2030;
dedicatedInputs.vneep3ComAIRatePost2030     = VNEEP3_Com_AIRate_Post2030;
dedicatedInputs.vneep3IndGARateTo2030       = VNEEP3_Ind_GARate_To2030;
dedicatedInputs.vneep3IndGARatePost2030     = VNEEP3_Ind_GARate_Post2030;
dedicatedInputs.vneep3ComGARateTo2030       = VNEEP3_Com_GARate_To2030;
dedicatedInputs.vneep3ComGARatePost2030     = VNEEP3_Com_GARate_Post2030;
dedicatedInputs.enableNonPowerNOETSBaselinePath = EnableNonPowerNOETSBaselinePath;
dedicatedInputs.nonPowerNOETSWorkbook = NonPowerNOETSWorkbook;
dedicatedInputs.nonPowerNOETSSeriesName = char(NonPowerNOETSSeriesName);

if dedicatedInputs.usePDP8InvestmentTargets
    write_pdp8_target_investment_to_path_workbook(dedicatedInputs);
end

existingSheetNames = get_workbook_sheet_names(targetWorkbook);
remove_nan_headers(targetWorkbook, 'Baseline');

try
    summary = update_baseline_excel( ...
        'TargetWorkbook', targetWorkbook, ...
        'HardcodedSheet', 'Baseline', ...
        'RefreshInputSheetsFromSource', false, ...
        'BootstrapFromLegacy', true, ...
        'ForceBootstrap', false, ...
        'Visible', false);
catch ME_ube
    if contains(ME_ube.message, 'duplicate header', 'IgnoreCase', true)
        fprintf(['  Warning: Baseline sheet has duplicate/corrupt headers ' ...
            '(%s); forcing re-bootstrap.\n'], ME_ube.message);
        summary = update_baseline_excel( ...
            'TargetWorkbook', targetWorkbook, ...
            'HardcodedSheet', 'Baseline', ...
            'RefreshInputSheetsFromSource', false, ...
            'BootstrapFromLegacy', true, ...
            'ForceBootstrap', true, ...
            'Visible', false);
    elseif strcmp(ME_ube.identifier, 'update_baseline_excel:SourceNotFound') || ...
           strcmp(ME_ube.identifier, 'update_baseline_excel:MissingImpliedSheet')
        fprintf(['  Note: Baseline_Implied not found and no legacy source workbook; ' ...
            'skipping Baseline_Implied refresh. Existing Baseline sheet structure is used.\n']);
        summary = struct('rowsCopied', 0);
    else
        rethrow(ME_ube);
    end
end

yearsWritten = write_growth_rates_to_baseline(targetWorkbook, dedicatedInputs);

assert_runnable_baseline_sheet(targetWorkbook);
remove_new_sheets(targetWorkbook, existingSheetNames, {'Baseline'});

fprintf('\nCreateBaselineFromPathDefinitionLite complete.\n');
fprintf('  Mode: dedicated_path (fixed)\n');
fprintf('  Source user-input workbook: %s\n', dedicatedPathWorkbook);
fprintf('  Target baseline workbook:   %s\n', targetWorkbook);
fprintf('  Runnable sheet updated:     Baseline\n');
fprintf('  Rows copied to Baseline:    %d\n', summary.rowsCopied);

function dedicatedInputs = import_dedicated_path_inputs(sourceWorkbook)
if ~isfile(sourceWorkbook)
    error('CreateBaselineFromUserInputFile:SourceNotFound', ...
        'Dedicated path workbook not found:\n  %s', sourceWorkbook);
end

% ScenarioPathDefinition layout (Baseline):
% Row 10: total GVA growth, Rows 12:16 VA shares
% Row 22: total employment growth, Rows 24:28 employment shares
% Year columns use E:AD (configured below).
srcSheet = 'Baseline';
srcStartCol = 'E';
srcEndCol = 'AD';

yearHeader = readcell(sourceWorkbook, 'Sheet', srcSheet, 'Range', [srcStartCol '9:' srcEndCol '9']);
years = nan(1, numel(yearHeader));
for iYear = 1:numel(yearHeader)
    v = yearHeader{iYear};
    if isa(v, 'datetime')
        years(iYear) = year(v);
    elseif isnumeric(v)
        if ~isempty(v) && ~isnan(v)
            if v > 1900 && v < 3000
                years(iYear) = v;
            else
                % Excel serial date fallback
                try
                    years(iYear) = year(datetime(v, 'ConvertFrom', 'excel'));
                catch
                end
            end
        end
    elseif isstring(v) || ischar(v)
        sVal = strtrim(string(v));
        numVal = str2double(sVal);
        if ~isnan(numVal)
            if numVal > 1900 && numVal < 3000
                years(iYear) = numVal;
            end
        else
            token = regexp(char(sVal), '(19|20)\d{2}', 'match', 'once');
            if ~isempty(token)
                years(iYear) = str2double(token);
            end
        end
    end
end

if any(isnan(years))
    iValid = find(~isnan(years), 1, 'first');
    if isempty(iValid)
        startYear = 2025;
    else
        startYear = years(iValid) - (iValid - 1);
    end
    years = startYear + (0:(numel(yearHeader) - 1));
    warning('CreateBaselineFromUserInputFile:YearHeaderInferred', ...
        ['Could not parse all year headers in Baseline row 9 (E:AD). ' ...
         'Using inferred sequence %d:%d.'], years(1), years(end));
end

gvaGrowth = readmatrix(sourceWorkbook, 'Sheet', srcSheet, 'Range', [srcStartCol '10:' srcEndCol '10']);
vaShares = readmatrix(sourceWorkbook, 'Sheet', srcSheet, 'Range', [srcStartCol '12:' srcEndCol '16']);
empGrowth = readmatrix(sourceWorkbook, 'Sheet', srcSheet, 'Range', [srcStartCol '22:' srcEndCol '22']);
empShares = readmatrix(sourceWorkbook, 'Sheet', srcSheet, 'Range', [srcStartCol '24:' srcEndCol '28']);

if numel(gvaGrowth) ~= numel(years) || numel(empGrowth) ~= numel(years) || ...
    size(vaShares, 2) ~= numel(years) || size(empShares, 2) ~= numel(years)
    error('CreateBaselineFromUserInputFile:UnexpectedSourceLayout', ...
        'Unexpected Baseline layout in workbook:\n  %s', sourceWorkbook);
end

dedicatedInputs = struct();
dedicatedInputs.gvaGrowth = reshape(gvaGrowth, 1, []);
dedicatedInputs.vaShares = vaShares;
dedicatedInputs.empGrowth = reshape(empGrowth, 1, []);
dedicatedInputs.empShares = empShares;
dedicatedInputs.years = reshape(years, 1, []);
dedicatedInputs.sourceWorkbook = sourceWorkbook;
dedicatedInputs.sourceSheet = srcSheet;
dedicatedInputs.sourceStartCol = srcStartCol;
dedicatedInputs.sourceEndCol = srcEndCol;

% Optional additional dedicated paths identified by row labels in columns A:D.
dedicatedInputs.emissionsBySector = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_E_1_1', 'idx_E_2_1', 'idx_E_3_1', 'idx_E_4_1', 'idx_E_5_1';
     'exo_E_1_1', 'exo_E_2_1', 'exo_E_3_1', 'exo_E_4_1', 'exo_E_5_1';
     'Sector emissions index - Primary', 'Sector emissions index - Fossil', ...
     'Sector emissions index - Renewables', 'Sector emissions index - Secondary', ...
     'Sector emissions index - Tertiary'});
dedicatedInputs.fossilProduction = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_Q_2_1', 'exo_Q_2_1', 'fossil_production', 'fossil production', 'Fossil production index'});
dedicatedInputs.fossilExports = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_X_2_1', 'exo_X_2_1', 'fossil_exports', 'fossil exports', 'Fossil exports index'});
dedicatedInputs.publicCapitalBySector = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_K_G_1_1', 'idx_K_G_2_1', 'idx_K_G_3_1', 'idx_K_G_4_1', 'idx_K_G_5_1';
     'exo_K_G_1_1', 'exo_K_G_2_1', 'exo_K_G_3_1', 'exo_K_G_4_1', 'exo_K_G_5_1';
     'Public capital stock index - Primary', ...
     'Public capital stock index - subsector 2 (fossil)', ...
     'Public capital stock index - subsector 3 (renewables)', ...
     'Public capital stock index - Secondary', ...
     'Public capital stock index - Tertiary'});
dedicatedInputs.targetInvestmentFR = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_I_2_1', 'idx_I_3_1';
     'exo_I_2_1', 'exo_I_3_1';
    'exo_targetIY_2_1', 'exo_targetIY_3_1';
    'Target investment ratio index - fossil', 'Target investment ratio index - renewables';
    'Target investment ratio - fossil', 'Target investment ratio - renewables'});
dedicatedInputs.investmentPriceBySector = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_P_K_1_1', 'idx_P_K_2_1', 'idx_P_K_3_1', 'idx_P_K_4_1', 'idx_P_K_5_1';
     'exo_P_K_1_1', 'exo_P_K_2_1', 'exo_P_K_3_1', 'exo_P_K_4_1', 'exo_P_K_5_1';
     'Investment price index - Primary', ...
     'Investment price index - subsector 2 (fossil)', ...
     'Investment price index - subsector 3 (renewables)', ...
     'Investment price index - Secondary', ...
     'Investment price index - Tertiary'});
dedicatedInputs.publicRateBySector = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_r_G_1_1', 'idx_r_G_2_1', 'idx_r_G_3_1', 'idx_r_G_4_1', 'idx_r_G_5_1';
     'exo_r_G_1_1', 'exo_r_G_2_1', 'exo_r_G_3_1', 'exo_r_G_4_1', 'exo_r_G_5_1';
     'Public capital interest rate index - Primary', ...
     'Public capital interest rate index - subsector 2 (fossil)', ...
     'Public capital interest rate index - subsector 3 (renewables)', ...
     'Public capital interest rate index - Secondary', ...
     'Public capital interest rate index - Tertiary'});
dedicatedInputs.emissionPrice = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_PE', 'idx_PE_1', 'exo_PE', 'exo_PE_1', 'emission_price', 'emission price', ...
     'Global emissions price index', 'Regional emissions price index (region 1)'});
dedicatedInputs.labourForce = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_LF_1', 'exo_LF_1', 'labour_force', 'labor_force', 'labour force', 'labor force', ...
     'Labour force index (region 1)'});
dedicatedInputs.nonLabourForce = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_NLF_1', 'exo_NLF_1', 'nonlabour_force', 'nonlabor_force', 'non-labour force', 'non-labor force', ...
     'Non-labour force index (region 1)'});
dedicatedInputs.energyEfficiencyTargetBySector = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_AI_1_1_2', 'idx_AI_2_1_2', 'idx_AI_3_1_2', 'idx_AI_4_1_2', 'idx_AI_5_1_2';
     'exo_AI_1_1_2', 'exo_AI_2_1_2', 'exo_AI_3_1_2', 'exo_AI_4_1_2', 'exo_AI_5_1_2';
     'Energy-efficiency target index - Primary', ...
     'Energy-efficiency target index - Fossil', ...
     'Energy-efficiency target index - Renewables', ...
     'Energy-efficiency target index - Secondary', ...
     'Energy-efficiency target index - Tertiary'});
dedicatedInputs.pvPath = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_PV_1', 'exo_PV_1', 'pv_path', 'rooftop pv', 'Rooftop PV investment index'});
dedicatedInputs.pvProductionPath = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, ...
    {'idx_PVEff_1', 'exo_PVEff_1', 'pv production', 'rooftop pv production', ...
     'Rooftop PV production index', 'Rooftop PV efficiency index'});

end

function yearsOut = write_growth_rates_to_baseline(targetWorkbook, dedicatedInputs)
targetStartYear = 2026;
[gY, years] = compute_sector_growth_factors( ...
    dedicatedInputs.gvaGrowth, dedicatedInputs.vaShares, dedicatedInputs.years, targetStartYear);
[gN, yearsEmp] = compute_sector_growth_factors( ...
    dedicatedInputs.empGrowth, dedicatedInputs.empShares, dedicatedInputs.years, targetStartYear);

if ~isequal(years, yearsEmp)
    error('CreateBaselineFromUserInputFile:YearAlignmentMismatch', ...
        'GVA and employment growth year ranges are not aligned.');
end

headers = readcell(targetWorkbook, 'Sheet', 'Baseline', 'Range', '1:1');
if isempty(headers)
    error('CreateBaselineFromUserInputFile:MissingBaselineHeaders', ...
        'Sheet "Baseline" has no header row in workbook:\n  %s', targetWorkbook);
end

nYears = size(gY, 2);
[headers, migrationInfo] = ensure_demographic_baseline_columns(targetWorkbook, headers, nYears);
if ~isempty(migrationInfo)
    fprintf('  Baseline demographic columns: %s\n', migrationInfo);
end

headers = ensure_noets_target_switch_columns(targetWorkbook, 'Baseline', headers, nYears);

write_generic_optional_paths(targetWorkbook, 'Baseline', headers, dedicatedInputs, years, nYears);
headers = readcell(targetWorkbook, 'Sheet', 'Baseline', 'Range', '1:1');

headers = apply_nonpower_noets_baseline_path(targetWorkbook, 'Baseline', headers, dedicatedInputs, years, nYears);

headers = apply_government_rts_sector_pv_shocks(targetWorkbook, 'Baseline', headers, dedicatedInputs, years, nYears);

headers = apply_industrial_pv_to_ee_coupling(targetWorkbook, 'Baseline', headers, dedicatedInputs, years, nYears);

headers = apply_vneep3_ee_targets(targetWorkbook, 'Baseline', headers, dedicatedInputs, years, nYears);

for iSub = 1:size(gY, 1)
    gYName = sprintf('gY_%d_1', iSub);
    gNName = sprintf('gN_%d_1', iSub);

    iColGY = find(strcmp(headers, gYName), 1);
    iColGN = find(strcmp(headers, gNName), 1);
    if isempty(iColGY) || isempty(iColGN)
        error('CreateBaselineFromUserInputFile:MissingGrowthColumn', ...
            'Baseline sheet is missing required column(s) "%s" or "%s".', gYName, gNName);
    end

    colGY = excel_col_name(iColGY);
    colGN = excel_col_name(iColGN);
    writematrix(gY(iSub, :)', targetWorkbook, 'Sheet', 'Baseline', ...
        'Range', sprintf('%s2:%s%d', colGY, colGY, nYears + 1));
    writematrix(gN(iSub, :)', targetWorkbook, 'Sheet', 'Baseline', ...
        'Range', sprintf('%s2:%s%d', colGN, colGN, nYears + 1));
end
yearsOut = years;
end

function headersOut = ensure_noets_target_switch_columns(targetWorkbook, targetSheet, headersIn, nYears)
headersOut = headersIn;
headerStr = string(headersOut);

for i = 1:numel(headerStr)
    h = strtrim(headerStr(i));
    if strlength(h) == 0
        continue
    end

    token = regexp(char(h), '^exo_E_NOETS_(\d+)_(\d+)$', 'tokens', 'once');
    if isempty(token)
        continue
    end

    switchVar = sprintf('exo_lE_NOETS_Target_%s_%s', token{1}, token{2});
    [headersOut, wasCreated] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headersOut, ...
        switchVar, nYears, 'binary');
    if wasCreated
        headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
    end
end
end

function headersOut = apply_nonpower_noets_baseline_path(targetWorkbook, targetSheet, headersIn, dedicatedInputs, yearsRef, nYears)
headersOut = headersIn;

if ~isfield(dedicatedInputs, 'enableNonPowerNOETSBaselinePath') || ~dedicatedInputs.enableNonPowerNOETSBaselinePath
    return
end

if ~isfield(dedicatedInputs, 'nonPowerNOETSWorkbook') || isempty(dedicatedInputs.nonPowerNOETSWorkbook)
    warning('CreateBaselineFromUserInputFile:NonPowerNOETSWorkbookMissing', ...
        'No non-power NOETS workbook configured; skipping exo_E_NOETS_1_1 update.');
    return
end

wbPath = dedicatedInputs.nonPowerNOETSWorkbook;
if ~isfile(wbPath)
    warning('CreateBaselineFromUserInputFile:NonPowerNOETSWorkbookNotFound', ...
        'Non-power NOETS workbook not found: %s. Skipping exo_E_NOETS_1_1 update.', wbPath);
    return
end

try
    t = readtable(wbPath, 'Sheet', 1, 'VariableNamingRule', 'preserve');
catch ME
    warning('CreateBaselineFromUserInputFile:NonPowerNOETSReadFailed', ...
        'Failed to read %s: %s. Skipping exo_E_NOETS_1_1 update.', wbPath, ME.message);
    return
end

names = string(t.Properties.VariableNames);
yearCol = find(strcmpi(names, 'Year'), 1);
if isempty(yearCol)
    yearCol = find(strcmpi(names, 'year'), 1);
end
if isempty(yearCol)
    warning('CreateBaselineFromUserInputFile:NonPowerNOETSYearMissing', ...
        'Workbook %s has no Year column. Skipping exo_E_NOETS_1_1 update.', wbPath);
    return
end

seriesName = 'NonPower_BSL';
if isfield(dedicatedInputs, 'nonPowerNOETSSeriesName') && ~isempty(dedicatedInputs.nonPowerNOETSSeriesName)
    seriesName = char(dedicatedInputs.nonPowerNOETSSeriesName);
end

seriesCol = find(strcmpi(names, string(seriesName)), 1);
if isempty(seriesCol)
    fallbackCandidates = ["NonPowerBaseline", "NonPower_Baseline", "NonPower BSL", "NonPowerBaseline_BSL"];
    for iCand = 1:numel(fallbackCandidates)
        seriesCol = find(strcmpi(names, fallbackCandidates(iCand)), 1);
        if ~isempty(seriesCol)
            break
        end
    end
end
if isempty(seriesCol)
    warning('CreateBaselineFromUserInputFile:NonPowerNOETSSeriesMissing', ...
        'Could not find non-power baseline series column (expected %s) in %s. Skipping exo_E_NOETS_1_1 update.', ...
        seriesName, wbPath);
    return
end

ySrc = as_numeric(t{:, yearCol});
vSrc = as_numeric(t{:, seriesCol});
isGood = isfinite(ySrc) & isfinite(vSrc) & (vSrc > 0);
ySrc = ySrc(isGood);
vSrc = vSrc(isGood);

if numel(ySrc) < 2
    warning('CreateBaselineFromUserInputFile:NonPowerNOETSInsufficientData', ...
        'Non-power baseline series in %s has insufficient valid points. Skipping exo_E_NOETS_1_1 update.', wbPath);
    return
end

[ySrc, iSort] = sort(ySrc(:));
vSrc = vSrc(iSort);

% Collapse duplicates by taking the last value for each year.
[yUniq, ~, idxGrp] = unique(ySrc, 'stable');
vUniq = accumarray(idxGrp, vSrc, [], @(x) x(end));

sourceYears = dedicatedInputs.years(:);
vAligned = interp1(yUniq, vUniq, sourceYears, 'linear', 'extrap');
if any(~isfinite(vAligned)) || any(vAligned <= 0)
    warning('CreateBaselineFromUserInputFile:NonPowerNOETSInvalidAlignedSeries', ...
        'Aligned non-power baseline series is invalid after interpolation. Skipping exo_E_NOETS_1_1 update.');
    return
end

anchorYear = 2025;
iAnchor = find(sourceYears == anchorYear, 1, 'first');
if isempty(iAnchor)
    iAnchor = 1;
    anchorYear = sourceYears(1);
end

idxSeries = (vAligned ./ vAligned(iAnchor))';
converted = apply_conversion_rule(idxSeries, 'log(index/index(1))', 'exo_E_NOETS_1_1', 0, dedicatedInputs.years, anchorYear);
[trimmedConverted, yearsRow] = trim_series_to_years(converted, dedicatedInputs.years, yearsRef);

if numel(trimmedConverted) ~= nYears
    warning('CreateBaselineFromUserInputFile:NonPowerNOETSLengthMismatch', ...
        'Aligned exo_E_NOETS_1_1 path length mismatch (%d vs %d). Skipping write.', numel(trimmedConverted), nYears);
    return
end

[headersOut, wasCreated] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headersOut, ...
    'exo_E_NOETS_1_1', nYears, 'log(index/index(1))');
if wasCreated
    headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
end

write_series_to_baseline_column(targetWorkbook, headersOut, 'exo_E_NOETS_1_1', trimmedConverted, yearsRow, nYears);

fprintf(['  Applied non-power baseline NOETS path to exo_E_NOETS_1_1 from %s ' ...
    '(column %s, anchor year %d).\n'], wbPath, names(seriesCol), anchorYear);
end

function headersOut = apply_industrial_pv_to_ee_coupling(targetWorkbook, targetSheet, headersIn, dedicatedInputs, yearsRef, nYears)
headersOut = headersIn;

if ~isfield(dedicatedInputs, 'enableIndustrialPVtoEECoupling') || ~dedicatedInputs.enableIndustrialPVtoEECoupling
    return
end

subsecInd = 4;
subsecCom = 5;
if isfield(dedicatedInputs, 'industrialPVGATargetSubsector')
    subsecInd = dedicatedInputs.industrialPVGATargetSubsector;
end
if isfield(dedicatedInputs, 'commercialPVGATargetSubsector')
    subsecCom = dedicatedInputs.commercialPVGATargetSubsector;
end

aiVarSec = sprintf('exo_AI_%d_1_2', subsecInd);
aiVarTer = sprintf('exo_AI_%d_1_2', subsecCom);

% PRIMARY: compute ΔAI = log((1-φ_0)/(1-φ_t)) from PV generation / sectoral demand.
% φ_t = gen_PV_t / demand_t; φ_0 (2025 base) is absorbed into steady-state calibration.
% exo_GA_s_r (costs) is handled separately by apply_government_rts_sector_pv_shocks.
[rtsOk, plan, rtsMsg] = read_vietnam_rts_sector_plan(dedicatedInputs, yearsRef);

demandSecBase = 177550;  % Vietnam 2025 industrial demand (GWh); 53% × 335 TWh PDP8
demandTerBase = 56950;   % Vietnam 2025 commercial demand (GWh); 17% × 335 TWh PDP8
gInd = 0.040;
gCom = 0.040;
if isfield(dedicatedInputs, 'industrialElecDemandBaseGWh') && isfinite(dedicatedInputs.industrialElecDemandBaseGWh)
    demandSecBase = dedicatedInputs.industrialElecDemandBaseGWh;
end
if isfield(dedicatedInputs, 'commercialElecDemandBaseGWh') && isfinite(dedicatedInputs.commercialElecDemandBaseGWh)
    demandTerBase = dedicatedInputs.commercialElecDemandBaseGWh;
end
if isfield(dedicatedInputs, 'elecDemandAnnualGrowthInd') && isfinite(dedicatedInputs.elecDemandAnnualGrowthInd)
    gInd = dedicatedInputs.elecDemandAnnualGrowthInd;
end
if isfield(dedicatedInputs, 'elecDemandAnnualGrowthCom') && isfinite(dedicatedInputs.elecDemandAnnualGrowthCom)
    gCom = dedicatedInputs.elecDemandAnnualGrowthCom;
end

if rtsOk && isfield(plan, 'genIndustrialGWh') && isfield(plan, 'genCommercialGWh')
    tRel = (0:nYears-1)';
    demandSec = demandSecBase .* (1 + gInd).^tRel;
    demandTer = demandTerBase .* (1 + gCom).^tRel;
    phiSec = min(plan.genIndustrialGWh(:) ./ demandSec, 0.9999);
    phiTer = min(plan.genCommercialGWh(:) ./ demandTer, 0.9999);
    etaAddSec = log((1 - phiSec(1)) ./ (1 - phiSec));
    etaAddTer = log((1 - phiTer(1)) ./ (1 - phiTer));
    srcLabel = sprintf('RTS gen/demand (ind %.0fGWh×(1+%.1f%%)^t, com %.0fGWh×(1+%.1f%%)^t)', ...
        demandSecBase, 100*gInd, demandTerBase, 100*gCom);
else
    % FALLBACK: K_A-progress formula (backward-compatible).
    warning('CreateBaselineFromUserInputFile:RTSGenDataMissing', ...
        'RTS generation data unavailable (%s); using K_A-progress fallback.', rtsMsg);

    gaVarInd = sprintf('exo_GA_%d_1', subsecInd);
    gaVarCom = sprintf('exo_GA_%d_1', subsecCom);
    gaSec = read_baseline_series(targetWorkbook, targetSheet, headersOut, gaVarInd, nYears);
    gaTer = read_baseline_series(targetWorkbook, targetSheet, headersOut, gaVarCom, nYears);

    if ~isempty(gaSec) && ~isempty(gaTer) && all(isfinite(gaSec)) && all(isfinite(gaTer)) && gaSec(1) > 0 && gaTer(1) > 0
        relSec = max(gaSec ./ gaSec(1) - 1, 0);
        relTer = max(gaTer ./ gaTer(1) - 1, 0);
        denSec = max(relSec(end), 1e-12);
        denTer = max(relTer(end), 1e-12);
        progressSec = min(max(relSec ./ denSec, 0), 1);
        progressTer = min(max(relTer ./ denTer, 0), 1);
        srcLabel = sprintf('K_A-progress (%s, %s)', gaVarInd, gaVarCom);
    else
        pvSeries = read_baseline_series(targetWorkbook, targetSheet, headersOut, 'exo_PV_1', nYears);
        if isempty(pvSeries)
            warning('CreateBaselineFromUserInputFile:IndustrialPVPathMissing', ...
                'No RTS gen data, no GA series, no exo_PV_1. Skipping PV->EE coupling.');
            return
        end
        pvMin = min(pvSeries); pvMax = max(pvSeries);
        if ~(isfinite(pvMin) && isfinite(pvMax)) || pvMax <= pvMin + 1e-12
            warning('CreateBaselineFromUserInputFile:IndustrialPVNoVariation', ...
                'Fallback PV path has no usable variation; skipping PV->EE coupling.');
            return
        end
        progressSec = min(max((pvSeries(:) - pvMin) ./ (pvMax - pvMin), 0), 1);
        progressTer = progressSec;
        srcLabel = 'exo_PV_1-progress (fallback)';
    end

    rSec = 0.08;
    rTer = 0.075;
    if isfield(dedicatedInputs, 'industrialPVMaxDemandReductionSecondary')
        rSec = dedicatedInputs.industrialPVMaxDemandReductionSecondary;
    end
    if isfield(dedicatedInputs, 'industrialPVMaxDemandReductionTertiary')
        rTer = dedicatedInputs.industrialPVMaxDemandReductionTertiary;
    end
    etaAddSec = log(1 ./ (1 - rSec .* progressSec));
    etaAddTer = log(1 ./ (1 - rTer .* progressTer));
end

[headersOut, wasCreatedSec] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headersOut, ...
    aiVarSec, nYears, 'log(index)');
[headersOut, wasCreatedTer] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headersOut, ...
    aiVarTer, nYears, 'log(index)');

if wasCreatedSec || wasCreatedTer
    headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
end

etaSec = read_baseline_series(targetWorkbook, targetSheet, headersOut, aiVarSec, nYears);
etaTer = read_baseline_series(targetWorkbook, targetSheet, headersOut, aiVarTer, nYears);
if isempty(etaSec) || isempty(etaTer)
    warning('CreateBaselineFromUserInputFile:MissingEEColumns', ...
        'Could not read %s/%s; skipping PV->EE coupling.', aiVarSec, aiVarTer);
    return
end

etaSecOut = etaSec + etaAddSec(:);
etaTerOut = etaTer + etaAddTer(:);
write_series_to_baseline_column(targetWorkbook, headersOut, aiVarSec, etaSecOut', 1:nYears, nYears);
write_series_to_baseline_column(targetWorkbook, headersOut, aiVarTer, etaTerOut', 1:nYears, nYears);

fprintf('  Applied PV->EE effectiveness coupling via %s.\n', srcLabel);
end

function headersOut = apply_vneep3_ee_targets(targetWorkbook, targetSheet, headersIn, dedicatedInputs, yearsRef, nYears)
% Apply VNEEP3 sector-specific EE targets to exo_AI_s_1_2 (effectiveness) and
% exo_GA_s_1 (cost). Both increments are added on top of whatever PV paths have
% already been written by apply_government_rts_sector_pv_shocks and
% apply_industrial_pv_to_ee_coupling.
%
%   exo_AI_s_1_2 += piecewise log-rate path  (non-PV EE measures: motors, insulation, …)
%   exo_GA_s_1   += linear K_A ramp          (EE investment cost as share of Y0_p)
%
% Piecewise rates:  rate_to2030 * min(t,5)  +  rate_post2030 * max(t-5,0)
% where t = 0 corresponds to the first baseline year.

headersOut = headersIn;

if ~isfield(dedicatedInputs, 'enableVNEEP3EETargets') || ~dedicatedInputs.enableVNEEP3EETargets
    return
end

subsecInd = 4;
subsecCom = 5;
if isfield(dedicatedInputs, 'industrialPVGATargetSubsector')
    subsecInd = dedicatedInputs.industrialPVGATargetSubsector;
end
if isfield(dedicatedInputs, 'commercialPVGATargetSubsector')
    subsecCom = dedicatedInputs.commercialPVGATargetSubsector;
end

% --- Read parameters (fall back to documented VNEEP3 defaults) ---
aiRateIndTo2030   = get_scalar_field(dedicatedInputs, 'vneep3IndAIRateTo2030',   0.005);
aiRateIndPost2030 = get_scalar_field(dedicatedInputs, 'vneep3IndAIRatePost2030', 0.003);
aiRateComTo2030   = get_scalar_field(dedicatedInputs, 'vneep3ComAIRateTo2030',   0.020);
aiRateComPost2030 = get_scalar_field(dedicatedInputs, 'vneep3ComAIRatePost2030', 0.010);
gaRateIndTo2030   = get_scalar_field(dedicatedInputs, 'vneep3IndGARateTo2030',   0.003);
gaRateIndPost2030 = get_scalar_field(dedicatedInputs, 'vneep3IndGARatePost2030', 0.002);
gaRateComTo2030   = get_scalar_field(dedicatedInputs, 'vneep3ComGARateTo2030',   0.002);
gaRateComPost2030 = get_scalar_field(dedicatedInputs, 'vneep3ComGARatePost2030', 0.001);

% --- Build piecewise paths ---
% t=0 is the first path year (2026); t=0 is already 1 year from the 2025 baseline.
% Use (t+1) so that at t=0 the path equals one year's rate, matching exo_EE_1 convention.
t = (0:nYears-1)';
idx2030 = find(yearsRef >= 2030, 1);
nYearsTo2030 = min(idx2030, nYears);  % number of path years up to and including 2030
if isempty(nYearsTo2030), nYearsTo2030 = min(5, nYears); end

pw = @(rTo, rPost) rTo * min(t+1, nYearsTo2030) + rPost * max(t+1 - nYearsTo2030, 0);

aiInd = pw(aiRateIndTo2030, aiRateIndPost2030);
aiCom = pw(aiRateComTo2030, aiRateComPost2030);
gaInd = pw(gaRateIndTo2030, gaRateIndPost2030);
gaCom = pw(gaRateComTo2030, gaRateComPost2030);

% --- Apply to exo_AI_s_1_2 ---
for sInfo = {subsecInd, aiInd; subsecCom, aiCom}'
    sub = sInfo{1};  inc = sInfo{2};
    varName = sprintf('exo_AI_%d_1_2', sub);
    [headersOut, wasCreated] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headersOut, ...
        varName, nYears, 'log(index)');
    if wasCreated
        headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
    end
    existing = read_baseline_series(targetWorkbook, targetSheet, headersOut, varName, nYears);
    if isempty(existing)
        existing = zeros(nYears, 1);
    end
    write_series_to_baseline_column(targetWorkbook, headersOut, varName, (existing(:) + inc)', yearsRef, nYears);
end

% --- Apply to exo_GA_s_1 ---
for sInfo = {subsecInd, gaInd; subsecCom, gaCom}'
    sub = sInfo{1};  inc = sInfo{2};
    varName = sprintf('exo_GA_%d_1', sub);
    [headersOut, wasCreated] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headersOut, ...
        varName, nYears, 'direct (index)');
    if wasCreated
        headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
    end
    existing = read_baseline_series(targetWorkbook, targetSheet, headersOut, varName, nYears);
    if isempty(existing)
        existing = zeros(nYears, 1);
    end
    write_series_to_baseline_column(targetWorkbook, headersOut, varName, (existing(:) + inc)', yearsRef, nYears);
end

% --- Write exo_lAddEE_r and optionally zero exo_EE_r ---
additive = get_scalar_field(dedicatedInputs, 'eeAdditiveMode', true);
lAddEEVal = double(logical(additive));

% Infer region indices from headers (look for any exo_EE_r that exists).
regIdxFound = [];
for rr = 1:20
    if ~isempty(find_header_index(headersOut, sprintf('exo_EE_%d', rr)))
        regIdxFound(end+1) = rr; %#ok<AGROW>
    end
end
if isempty(regIdxFound)
    regIdxFound = 1;  % default: single region
end

% Write exo_lAddEE_s_r for ALL subsectors present in the sheet headers.
% Scan for any existing exo_lAddEE_ column to derive the subsector range,
% then ensure every subsector (for every region found) gets the switch value.
existingSubsecs = [];
for rr = regIdxFound
    for ss = 1:30
        if ~isempty(find_header_index(headersOut, sprintf('exo_lAddEE_%d_%d', ss, rr)))
            existingSubsecs(end+1) = ss; %#ok<AGROW>
        end
    end
end
existingSubsecs = unique([existingSubsecs, subsecInd, subsecCom]);

for rr = regIdxFound
    for ss = existingSubsecs
        switchVar = sprintf('exo_lAddEE_%d_%d', ss, rr);
        [headersOut, wasCreated] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headersOut, ...
            switchVar, nYears, 'binary');
        if wasCreated
            headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
        end
        write_series_to_baseline_column(targetWorkbook, headersOut, switchVar, ...
            repmat(lAddEEVal, 1, nYears), yearsRef, nYears);
    end

    % In sole-driver mode, zero out the autonomous regional EE path so
    % PV/VNEEP3 are the only EE drivers (exo_lAddEE_s_r = 0 suppresses
    % exo_EE_r for each subsector via the model equation).
    if ~additive
        eeVar = sprintf('exo_EE_%d', rr);
        [headersOut, wasCreated] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headersOut, ...
            eeVar, nYears, 'log(index)');
        if wasCreated
            headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
        end
        write_series_to_baseline_column(targetWorkbook, headersOut, eeVar, ...
            zeros(1, nYears), yearsRef, nYears);
    end
end

modeStr = 'additive (exo_EE_r kept)';
if ~additive
    modeStr = 'sole-driver (exo_EE_r zeroed)';
end
fprintf(['  Applied VNEEP3 EE targets [%s]: ' ...
    'ind AI +%.3f/+%.3f log/yr, GA +%.3f/+%.3f per yr; ' ...
    'com AI +%.3f/+%.3f log/yr, GA +%.3f/+%.3f per yr (to2030/post2030).\n'], ...
    modeStr, ...
    aiRateIndTo2030, aiRateIndPost2030, gaRateIndTo2030, gaRateIndPost2030, ...
    aiRateComTo2030, aiRateComPost2030, gaRateComTo2030, gaRateComPost2030);
end

function v = get_scalar_field(s, fname, default)
if isfield(s, fname) && isscalar(s.(fname)) && isfinite(s.(fname))
    v = s.(fname);
else
    v = default;
end
end

function headersOut = apply_government_rts_sector_pv_shocks(targetWorkbook, targetSheet, headersIn, dedicatedInputs, yearsRef, nYears)
headersOut = headersIn;

if ~isfield(dedicatedInputs, 'enableGovernmentRTSSectorPVShocks') || ~dedicatedInputs.enableGovernmentRTSSectorPVShocks
    return
end

[ok, plan, msg] = read_vietnam_rts_sector_plan(dedicatedInputs, yearsRef);
if ~ok
    warning('CreateBaselineFromUserInputFile:RTSSectorPVPlanMissing', '%s', msg);
    return
end

deltaPV = 0.10;
if isfield(dedicatedInputs, 'deltaPVForRTSInvestmentIndex') && isfinite(dedicatedInputs.deltaPVForRTSInvestmentIndex)
    deltaPV = dedicatedInputs.deltaPVForRTSInvestmentIndex;
end
phiKPV0 = 0.03;
if isfield(dedicatedInputs, 'phiKPV0ForRTSInvestmentScale') && isfinite(dedicatedInputs.phiKPV0ForRTSInvestmentScale)
    phiKPV0 = dedicatedInputs.phiKPV0ForRTSInvestmentScale;
end
if ~(deltaPV > 0 && deltaPV <= 1)
    error('CreateBaselineFromUserInputFile:InvalidDeltaPVForRTS', ...
        'deltaPV for RTS investment-index conversion must be in (0,1]. Got %.6f', deltaPV);
end
if ~(phiKPV0 > 0)
    error('CreateBaselineFromUserInputFile:InvalidPhiKPV0ForRTS', ...
        'phiKPV0 for RTS investment scaling must be > 0. Got %.6f', phiKPV0);
end

subsecInd = 4;
subsecCom = 5;
if isfield(dedicatedInputs, 'industrialPVGATargetSubsector')
    subsecInd = dedicatedInputs.industrialPVGATargetSubsector;
end
if isfield(dedicatedInputs, 'commercialPVGATargetSubsector')
    subsecCom = dedicatedInputs.commercialPVGATargetSubsector;
end
if ~(isfinite(subsecInd) && subsecInd == floor(subsecInd) && subsecInd >= 1)
    error('CreateBaselineFromUserInputFile:InvalidIndustrialPVGASubsector', ...
        'industrialPVGATargetSubsector must be a positive integer. Got %.6f', subsecInd);
end
if ~(isfinite(subsecCom) && subsecCom == floor(subsecCom) && subsecCom >= 1)
    error('CreateBaselineFromUserInputFile:InvalidCommercialPVGASubsector', ...
        'commercialPVGATargetSubsector must be a positive integer. Got %.6f', subsecCom);
end

gaVarInd = sprintf('exo_GA_%d_1', subsecInd);
gaVarCom = sprintf('exo_GA_%d_1', subsecCom);
gaIdxVarInd = sprintf('idx_GA_%d_1_plan', subsecInd);
gaIdxVarCom = sprintf('idx_GA_%d_1_plan', subsecCom);

% Residential RTS enters the model through exo_PV_1 (PV investment shock).
exoPVResidential = stock_index_to_investment_index(plan.idxResidential, deltaPV) * deltaPV * phiKPV0;

% Industrial/commercial RTS enters through adaptation-capital stock channels.
% exo_AI_4_1_2/exo_AI_5_1_2 controls the effectiveness of K_A in A_I_Eff.
gaSecBase = read_baseline_series(targetWorkbook, targetSheet, headersOut, gaVarInd, nYears);
gaTerBase = read_baseline_series(targetWorkbook, targetSheet, headersOut, gaVarCom, nYears);
if isempty(gaSecBase) || ~isfinite(gaSecBase(1)) || gaSecBase(1) <= 0
    gaSecLevel0 = phiKPV0;
else
    gaSecLevel0 = gaSecBase(1);
end
if isempty(gaTerBase) || ~isfinite(gaTerBase(1)) || gaTerBase(1) <= 0
    gaTerLevel0 = phiKPV0;
else
    gaTerLevel0 = gaTerBase(1);
end

exoGASec = gaSecLevel0 .* plan.idxIndustrial(:);
exoGATer = gaTerLevel0 .* plan.idxCommercial(:);

cols = {
    'idx_PV_Res_1', stock_index_to_investment_index(plan.idxResidential, deltaPV)
    'exo_PV_1', exoPVResidential
    gaVarInd, exoGASec
    gaVarCom, exoGATer
    };

for i = 1:size(cols, 1)
    varName = cols{i, 1};
    pathVals = cols{i, 2};
    [headersOut, wasCreated] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headersOut, ...
        varName, nYears, 'direct (index)');
    if wasCreated
        headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
    end
    write_series_to_baseline_column(targetWorkbook, headersOut, varName, pathVals(:)', yearsRef, nYears);
end

% Optional helper indices for auditing the GA mapping.
[headersOut, wasCreatedGASecPlan] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headersOut, ...
    gaIdxVarInd, nYears, 'direct (index)');
if wasCreatedGASecPlan
    headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
end
write_series_to_baseline_column(targetWorkbook, headersOut, gaIdxVarInd, plan.idxIndustrial(:)', yearsRef, nYears);

[headersOut, wasCreatedGATerPlan] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headersOut, ...
    gaIdxVarCom, nYears, 'direct (index)');
if wasCreatedGATerPlan
    headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
end
write_series_to_baseline_column(targetWorkbook, headersOut, gaIdxVarCom, plan.idxCommercial(:)', yearsRef, nYears);

% Optional aggregate references for consistency checks (do not overwrite exo_PV_1).
[headersOut, wasCreatedAgg] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headersOut, ...
    'idx_PV_1_plan', nYears, 'direct (index)');
if wasCreatedAgg
    headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
end
write_series_to_baseline_column(targetWorkbook, headersOut, 'idx_PV_1_plan', plan.idxTotal(:)', yearsRef, nYears);

[headersOut, wasCreatedAggInv] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headersOut, ...
    'idx_PV_1_plan_inv', nYears, 'direct (index)');
if wasCreatedAggInv
    headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
end
write_series_to_baseline_column(targetWorkbook, headersOut, 'idx_PV_1_plan_inv', stock_index_to_investment_index(plan.idxTotal, deltaPV)', yearsRef, nYears);

fprintf(['  Applied Vietnam RTS rooftop-solar sector shocks from %s ' ...
    '(residential -> exo_PV_1; industrial/commercial -> %s/%s; deltaPV=%.3f).\n'], ...
    plan.sourceTag, gaVarInd, gaVarCom, deltaPV);
end

function [ok, plan, msg] = read_vietnam_rts_sector_plan(dedicatedInputs, yearsRef)
ok = false;
msg = '';
plan = struct();

if ~isfield(dedicatedInputs, 'repoRoot') || isempty(dedicatedInputs.repoRoot)
    msg = 'Repository root not set; cannot locate RTS split CSV.';
    return
end

csvPath = fullfile(dedicatedInputs.repoRoot, 'ExcelFiles', 'Output', 'RTS_split_assumptions_from_expert_email.csv');
[didRefresh, refreshMsg] = refresh_rts_split_csv_from_expert_workbook(csvPath, dedicatedInputs);
if didRefresh
    fprintf('  %s\n', refreshMsg);
elseif ~isfile(csvPath)
    msg = refreshMsg;
    return
end

try
    t = readtable(csvPath, 'VariableNamingRule', 'preserve');
catch ME
    msg = sprintf('Failed to read RTS split CSV: %s', ME.message);
    return
end

requiredCols = {'year', 'cap_industrial_MW', 'cap_total_MW'};
if ~all(ismember(requiredCols, t.Properties.VariableNames))
    msg = 'RTS split CSV is missing one of required columns: year, cap_industrial_MW, cap_total_MW.';
    return
end

yCsv = as_numeric(t.year);
capInd = as_numeric(t.cap_industrial_MW);
capTot = as_numeric(t.cap_total_MW);

[isIn, idxPos] = ismember(yearsRef(:), yCsv(:));
if ~all(isIn)
    msg = 'RTS split CSV does not cover all baseline years.';
    return
end

capInd = capInd(idxPos);
capTot = capTot(idxPos);

if any(~isfinite(capInd)) || any(~isfinite(capTot)) || any(capTot <= 0) || any(capInd < 0)
    msg = 'RTS split CSV contains invalid capacity values for required years.';
    return
end

if ismember('cap_commercial_MW', t.Properties.VariableNames) && ismember('cap_residential_MW', t.Properties.VariableNames)
    capCom = as_numeric(t.cap_commercial_MW);
    capRes = as_numeric(t.cap_residential_MW);
    capCom = capCom(idxPos);
    capRes = capRes(idxPos);
    sourceTag = 'RTS_split_assumptions_from_expert_email.csv (explicit commercial/residential)';
elseif ismember('cap_household_MW', t.Properties.VariableNames)
    capHH = as_numeric(t.cap_household_MW);
    capHH = capHH(idxPos);
    if any(~isfinite(capHH)) || any(capHH < 0)
        msg = 'RTS split CSV contains invalid cap_household_MW values for required years.';
        return
    end

    shareCom = 0.30;
    if isfield(dedicatedInputs, 'rtsCommercialShareOfHousehold') && isfinite(dedicatedInputs.rtsCommercialShareOfHousehold)
        shareCom = dedicatedInputs.rtsCommercialShareOfHousehold;
    end
    shareCom = min(max(shareCom, 0), 1);

    capCom = shareCom .* capHH;
    capRes = (1 - shareCom) .* capHH;
    sourceTag = sprintf('RTS split CSV (household split with commercial share %.2f)', shareCom);
else
    capCom = max(capTot - capInd, 0);
    capRes = zeros(size(capCom));
    sourceTag = 'RTS split CSV (commercial from non-industrial residual; residential=0 fallback)';
end

if any(capCom < 0) || any(capRes < 0)
    msg = 'Derived commercial/residential capacities are negative after RTS split processing.';
    return
end

sumCaps = capInd + capCom + capRes;
if any(sumCaps <= 0)
    msg = 'Derived RTS sector capacities are non-positive for at least one year.';
    return
end

plan.idxIndustrial = capInd ./ capInd(1);
plan.idxCommercial = capCom ./ max(capCom(1), 1e-8);
plan.idxResidential = capRes ./ max(capRes(1), 1e-8);
plan.idxTotal = capTot ./ capTot(1);
plan.sourceTag = sourceTag;

% Generation data (GWh) for PV->AI coverage-fraction computation.
if ismember('gen_industrial_GWh', t.Properties.VariableNames)
    genInd = as_numeric(t.gen_industrial_GWh);
    genInd = genInd(idxPos);
    if all(isfinite(genInd)) && all(genInd >= 0)
        plan.genIndustrialGWh = genInd;
    end
end

if ismember('gen_commercial_GWh', t.Properties.VariableNames)
    genCom = as_numeric(t.gen_commercial_GWh);
    genCom = genCom(idxPos);
    if all(isfinite(genCom)) && all(genCom >= 0)
        plan.genCommercialGWh = genCom;
    end
elseif ismember('gen_household_GWh', t.Properties.VariableNames)
    genHH = as_numeric(t.gen_household_GWh);
    genHH = genHH(idxPos);
    if all(isfinite(genHH)) && all(genHH >= 0)
        comShr = 0.30;
        if isfield(dedicatedInputs, 'rtsCommercialShareOfHousehold') && isfinite(dedicatedInputs.rtsCommercialShareOfHousehold)
            comShr = min(max(dedicatedInputs.rtsCommercialShareOfHousehold, 0), 1);
        end
        plan.genCommercialGWh = comShr .* genHH;
    end
end

ok = true;
end

function [ok, msg] = refresh_rts_split_csv_from_expert_workbook(csvPath, dedicatedInputs)
ok = false;
msg = '';

if ~isfield(dedicatedInputs, 'repoRoot') || isempty(dedicatedInputs.repoRoot)
    msg = 'Repository root not set; cannot refresh RTS split CSV from expert workbook.';
    return
end

repoRoot = dedicatedInputs.repoRoot;
sheetName = 'PDP8_revised';
cleanRtsCsv = fullfile(repoRoot, 'ExcelFiles', 'Input', 'ExpertClean', 'RTS_PDP8_revised_reference.csv');
workbookCandidates = {
    fullfile(repoRoot, 'ExcelFiles', 'PDP8', 'Vietnam_EnergyExpert_ScenarioInputs - Adjust_2505.xlsx')
    fullfile(repoRoot, 'ExcelFiles', 'Vietnam_EnergyExpert_ScenarioInputs.xlsx')
    fullfile(repoRoot, 'ExcelFiles', 'Vietnam_EnergyExpert_ScenarioInputs_harmonized.xlsx')
    };

expertData = struct();
workbookPath = '';
lastErr = '';

% Preferred source: clean, format-free RTS reference CSV.
if isfile(cleanRtsCsv)
    [okClean, expertData, cleanMsg] = read_rts_totals_from_clean_csv(cleanRtsCsv);
    if okClean
        [capIndustrialShare, genIndustrialShare] = infer_rts_industrial_shares_from_email(expertData.years);
        capTotalMW = 1000 .* expertData.capGW(:);
        genTotalGWh = 1000 .* expertData.genTWh(:);
        capIndustrialMW = capIndustrialShare(:) .* capTotalMW;
        genIndustrialGWh = genIndustrialShare(:) .* genTotalGWh;

        t = table( ...
            expertData.years(:), ...
            capTotalMW, ...
            capIndustrialMW, ...
            max(capTotalMW - capIndustrialMW, 0), ...
            genTotalGWh, ...
            genIndustrialGWh, ...
            max(genTotalGWh - genIndustrialGWh, 0), ...
            'VariableNames', { ...
                'year', ...
                'cap_total_MW', ...
                'cap_industrial_MW', ...
                'cap_household_MW', ...
                'gen_total_GWh', ...
                'gen_industrial_GWh', ...
                'gen_household_GWh'});
        writetable(t, csvPath);
        msg = sprintf('Refreshed RTS split CSV from clean reference input %s.', cleanRtsCsv);
        ok = true;
        return
    end
    lastErr = cleanMsg;
end

for iCandidate = 1:numel(workbookCandidates)
    candidate = workbookCandidates{iCandidate};
    if ~isfile(candidate)
        continue
    end

    useHighReference = true;
    if isfield(dedicatedInputs, 'useRevisedPDP8HighAsReference')
        useHighReference = logical(dedicatedInputs.useRevisedPDP8HighAsReference);
    end

    [okRead, expertData, readMsg] = read_rts_totals_from_expert_workbook(candidate, sheetName, useHighReference);
    if okRead
        workbookPath = candidate;
        break
    end
    lastErr = readMsg;
end

if isempty(workbookPath)
    if isempty(lastErr)
        msg = 'No expert workbook available to refresh RTS split CSV.';
    else
        msg = sprintf('Failed to refresh RTS split CSV from expert workbook: %s', lastErr);
    end
    return
end

[capIndustrialShare, genIndustrialShare] = infer_rts_industrial_shares_from_email(expertData.years);

capTotalMW = 1000 .* expertData.capGW(:);
genTotalGWh = 1000 .* expertData.genTWh(:);
capIndustrialMW = capIndustrialShare(:) .* capTotalMW;
genIndustrialGWh = genIndustrialShare(:) .* genTotalGWh;
capHouseholdMW = max(capTotalMW - capIndustrialMW, 0);
genHouseholdGWh = max(genTotalGWh - genIndustrialGWh, 0);

t = table( ...
    expertData.years(:), ...
    capTotalMW, ...
    capIndustrialMW, ...
    capHouseholdMW, ...
    genTotalGWh, ...
    genIndustrialGWh, ...
    genHouseholdGWh, ...
    'VariableNames', { ...
        'year', ...
        'cap_total_MW', ...
        'cap_industrial_MW', ...
        'cap_household_MW', ...
        'gen_total_GWh', ...
        'gen_industrial_GWh', ...
        'gen_household_GWh'});

try
    writetable(t, csvPath);
catch ME
    msg = sprintf('Failed to write RTS split CSV at %s: %s', csvPath, ME.message);
    return
end

[~, workbookName, workbookExt] = fileparts(workbookPath);
msg = sprintf(['Refreshed RTS split CSV from %s%s/%s using current workbook totals ' ...
    'and email-calibrated industrial shares.'], workbookName, workbookExt, sheetName);
ok = true;
end

function [ok, data, msg] = read_rts_totals_from_expert_workbook(workbookPath, sheetName, useHighReference)
ok = false;
msg = '';
data = struct('years', [], 'capGW', [], 'genTWh', []);

if nargin < 3
    useHighReference = true;
end

try
    raw = readcell(workbookPath, 'Sheet', sheetName);
catch ME
    msg = sprintf('Could not read workbook sheet %s: %s', sheetName, ME.message);
    return
end

if isempty(raw)
    msg = sprintf('Workbook sheet %s is empty.', sheetName);
    return
end

hdrRow = find(cellfun(@(x) (ischar(x) || isstring(x)) && strcmpi(strtrim(string(x)), "Year"), raw(:, 1)), 1, 'first');
if isempty(hdrRow)
    msg = sprintf('Workbook sheet %s does not contain a Year header row.', sheetName);
    return
end

headers = raw(hdrRow, :);
dataRows = raw((hdrRow + 1):end, :);

colYear = find_header_index(headers, 'Year');
colCapBase = find_header_index(headers, 'RTS_Capacity_GW');
colCapHigh = find_header_index(headers, 'Check PDP8 - High scenario');
colGen = find_header_index(headers, 'RTS_Generation_TWh');
colCF = find_header_index(headers, 'RTS_CapacityFactor');

if useHighReference && ~isempty(colCapHigh)
    colCap = colCapHigh;
else
    colCap = colCapBase;
end

if isempty(colYear) || isempty(colCap)
    msg = sprintf(['Workbook sheet %s is missing one of required columns: Year, ' ...
        'RTS_Capacity_GW (or Check PDP8 - High scenario).'], sheetName);
    return
end

years = as_numeric(dataRows(:, colYear));
capGW = as_numeric(dataRows(:, colCap));

if useHighReference
    % The revised high column can be sparse (milestone years only).
    % Fill missing values first from baseline RTS capacity, then interpolate.
    if any(~isfinite(capGW))
        if ~isempty(colCapBase)
            capBaseGW = as_numeric(dataRows(:, colCapBase));
            fillFromBase = ~isfinite(capGW) & isfinite(capBaseGW);
            capGW(fillFromBase) = capBaseGW(fillFromBase);
        end

        missingCap = ~isfinite(capGW);
        validPts = isfinite(years) & isfinite(capGW);
        if any(missingCap)
            if sum(validPts) >= 2
                capInterp = interp1(years(validPts), capGW(validPts), years(missingCap), 'linear', 'extrap');
                capGW(missingCap) = capInterp;
            elseif sum(validPts) == 1
                capGW(missingCap) = capGW(find(validPts, 1, 'first'));
            end
        end
    end
end

if useHighReference && ~isempty(colCF)
    cf = as_numeric(dataRows(:, colCF));
    genTWh = capGW .* cf * 8.76;
else
    if isempty(colGen)
        msg = sprintf(['Workbook sheet %s is missing RTS_Generation_TWh and no usable ' ...
            'RTS_CapacityFactor is available for reconstruction.'], sheetName);
        return
    end
    genTWh = as_numeric(dataRows(:, colGen));
end
isData = isfinite(years) & isfinite(capGW) & isfinite(genTWh);
years = years(isData);
capGW = capGW(isData);
genTWh = genTWh(isData);

if isempty(years)
    msg = sprintf('Workbook sheet %s does not contain any usable RTS data rows.', sheetName);
    return
end
if any(capGW <= 0) || any(genTWh <= 0)
    msg = sprintf('Workbook sheet %s contains nonpositive RTS totals.', sheetName);
    return
end

data.years = years(:)';
data.capGW = capGW(:)';
data.genTWh = genTWh(:)';
ok = true;
end

function [capIndustrialShare, genIndustrialShare] = infer_rts_industrial_shares_from_email(years)
% Expert email (Outlook PDF) provides industrial and residential rooftop-PV
% milestones at 2030 and 2050, but the workbook only carries total RTS paths.
% Interpolate the industrial share across those anchors and let the residual
% flow through the existing household/commercial split logic.

years = reshape(years, 1, []);

capAnchorYears = [2030, 2050];
capAnchorIndustrialMW = [18231, 59000];
capAnchorTotalMW = [36733, 137670];
genAnchorYears = [2030, 2050];
genAnchorIndustrialGWh = [23361, 77676];
genAnchorTotalGWh = [44827, 176936];

capAnchorShare = capAnchorIndustrialMW ./ capAnchorTotalMW;
genAnchorShare = genAnchorIndustrialGWh ./ genAnchorTotalGWh;

capIndustrialShare = interp1(capAnchorYears, capAnchorShare, years, 'linear', 'extrap');
genIndustrialShare = interp1(genAnchorYears, genAnchorShare, years, 'linear', 'extrap');

capIndustrialShare(years <= capAnchorYears(1)) = capAnchorShare(1);
capIndustrialShare(years >= capAnchorYears(end)) = capAnchorShare(end);
genIndustrialShare(years <= genAnchorYears(1)) = genAnchorShare(1);
genIndustrialShare(years >= genAnchorYears(end)) = genAnchorShare(end);

capIndustrialShare = min(max(capIndustrialShare, 0), 1);
genIndustrialShare = min(max(genIndustrialShare, 0), 1);
end

function [ok, data, msg] = read_rts_totals_from_clean_csv(csvPath)
ok = false;
msg = '';
data = struct('years', [], 'capGW', [], 'genTWh', []);

try
    t = readtable(csvPath, 'VariableNamingRule', 'preserve');
catch ME
    msg = sprintf('Could not read clean RTS input CSV: %s', ME.message);
    return
end

required = {'Year', 'RTS_Capacity_GW', 'RTS_Generation_TWh'};
if ~all(ismember(required, t.Properties.VariableNames))
    msg = sprintf('Clean RTS input CSV missing required columns: %s', strjoin(required, ', '));
    return
end

years = as_numeric(t.Year);
capGW = as_numeric(t.RTS_Capacity_GW);
genTWh = as_numeric(t.RTS_Generation_TWh);

isData = isfinite(years) & isfinite(capGW) & isfinite(genTWh);
years = years(isData);
capGW = capGW(isData);
genTWh = genTWh(isData);

if isempty(years)
    msg = 'Clean RTS input CSV contains no usable rows.';
    return
end
if any(capGW <= 0) || any(genTWh <= 0)
    msg = 'Clean RTS input CSV contains nonpositive capacity/generation rows.';
    return
end

data.years = years(:)';
data.capGW = capGW(:)';
data.genTWh = genTWh(:)';
ok = true;
end

function idxInvest = stock_index_to_investment_index(idxStock, deltaPV)
% Convert a normalized PV stock index path into an investment index path
% consistent with K_t = (1-deltaPV)K_{t-1} + I_t and I_0 = deltaPV*K_0.

idxStock = reshape(idxStock, [], 1);
if isempty(idxStock)
    idxInvest = idxStock;
    return
end
if any(~isfinite(idxStock)) || any(idxStock <= 0)
    error('CreateBaselineFromUserInputFile:InvalidPVStockIndex', ...
        'PV stock index must be finite and strictly positive for investment conversion.');
end

idxInvest = ones(size(idxStock));
for t = 2:numel(idxStock)
    idxInvest(t) = (idxStock(t) - (1 - deltaPV) * idxStock(t - 1)) / deltaPV;
end

if any(idxInvest < 0)
    warning('CreateBaselineFromUserInputFile:NegativePVInvestmentIndex', ...
        ['Derived PV investment index is negative in some years after stock-to-investment conversion. ' ...
         'Values are clipped at zero.']);
    idxInvest = max(idxInvest, 0);
end
end

function series = read_baseline_series(targetWorkbook, targetSheet, headers, varName, nYears)
series = [];
iCol = find_header_index(headers, varName);
if isempty(iCol)
    return
end

col = excel_col_name(iCol);
series = readmatrix(targetWorkbook, 'Sheet', targetSheet, ...
    'Range', sprintf('%s2:%s%d', col, col, nYears + 1));
series = reshape(series, [], 1);
if numel(series) ~= nYears
    series = [];
end
end

function [headersOut, migrationInfo] = ensure_demographic_baseline_columns(targetWorkbook, headersIn, nYears)
% Ensure modern demographic columns exist in Baseline header row.
% Legacy files may contain exo_PoP only.

headersOut = headersIn;
migrationSteps = {};

iColPoP = find_header_index(headersOut, 'exo_PoP');
iColLF = find_header_index(headersOut, 'exo_LF_1');

if isempty(iColLF) && ~isempty(iColPoP)
    colPoP = excel_col_name(iColPoP);
    writecell({'exo_LF_1'}, targetWorkbook, 'Sheet', 'Baseline', 'Range', sprintf('%s1', colPoP));
    migrationSteps{end + 1} = 'renamed exo_PoP -> exo_LF_1'; %#ok<AGROW>
end

headersOut = readcell(targetWorkbook, 'Sheet', 'Baseline', 'Range', '1:1');

% Ensure all demographic columns are available for writing optional inputs.
requiredCols = {'exo_LF_1', 'exo_NLF_1', 'idx_LF_1', 'idx_NLF_1'};
for i = 1:numel(requiredCols)
    varName = requiredCols{i};
    if isempty(find_header_index(headersOut, varName))
        % Treat NaN (readcell representation of blank cells) as empty; only count real string headers.
isRealHeader = @(x) (ischar(x) && ~isempty(x)) || (isstring(x) && strlength(x) > 0);
lastNonEmpty = find(cellfun(isRealHeader, headersOut), 1, 'last');
        if isempty(lastNonEmpty)
            lastNonEmpty = 1;
        end
        iNewCol = lastNonEmpty + 1;
        colNew = excel_col_name(iNewCol);
        writecell({varName}, targetWorkbook, 'Sheet', 'Baseline', 'Range', sprintf('%s1', colNew));
        copy_header_format_from_first_column(targetWorkbook, 'Baseline', iNewCol);

        if startsWith(varName, 'idx_')
            defaultVals = ones(nYears, 1);
        else
            defaultVals = zeros(nYears, 1);
        end
        writematrix(defaultVals, targetWorkbook, 'Sheet', 'Baseline', ...
            'Range', sprintf('%s2:%s%d', colNew, colNew, nYears + 1));
        migrationSteps{end + 1} = sprintf('added %s', varName); %#ok<AGROW>

        headersOut = readcell(targetWorkbook, 'Sheet', 'Baseline', 'Range', '1:1');
    end
end

% If exo_NLF_1 was added to a migrated legacy file, copy existing LF path by default.
iColNLF = find_header_index(headersOut, 'exo_NLF_1');
iColLF = find_header_index(headersOut, 'exo_LF_1');
didRenamePoP = any(strcmp(migrationSteps, 'renamed exo_PoP -> exo_LF_1'));
didAddNLF = any(strcmp(migrationSteps, 'added exo_NLF_1'));
if didRenamePoP && didAddNLF && ~isempty(iColLF) && ~isempty(iColNLF)
    colLF = excel_col_name(iColLF);
    colNLF = excel_col_name(iColNLF);
    lfVals = readmatrix(targetWorkbook, 'Sheet', 'Baseline', ...
        'Range', sprintf('%s2:%s%d', colLF, colLF, nYears + 1));
    writematrix(lfVals, targetWorkbook, 'Sheet', 'Baseline', ...
        'Range', sprintf('%s2:%s%d', colNLF, colNLF, nYears + 1));
    migrationSteps{end + 1} = 'initialized exo_NLF_1 from exo_LF_1'; %#ok<AGROW>
end

migrationInfo = strjoin(migrationSteps, ', ');
end

function [seriesOut, yearsOut] = trim_series_to_years(seriesIn, sourceYears, targetYears)
if isempty(seriesIn)
    seriesOut = [];
    yearsOut = [];
    return
end

idx = ismember(sourceYears, targetYears);
yearsOut = sourceYears(idx);
seriesOut = seriesIn(:, idx);
end

function write_series_to_baseline_column(targetWorkbook, headers, varName, seriesRow, yearsSeries, nYearsExpected)
if isempty(seriesRow)
    return
end

iCol = find_header_index(headers, varName);
if isempty(iCol)
    warning('CreateBaselineFromUserInputFile:MissingOptionalBaselineColumn', ...
        'Baseline column "%s" not found; skipping write for this path.', varName);
    return
end

if numel(seriesRow) ~= nYearsExpected
    error('CreateBaselineFromUserInputFile:OptionalPathLengthMismatch', ...
        ['Path "%s" has %d years after alignment, but growth paths use %d years. ' ...
         'Aligned years: [%g .. %g].'], ...
        varName, numel(seriesRow), nYearsExpected, yearsSeries(1), yearsSeries(end));
end

col = excel_col_name(iCol);
writematrix(seriesRow(:), targetWorkbook, 'Sheet', 'Baseline', ...
    'Range', sprintf('%s2:%s%d', col, col, nYearsExpected + 1));
end

function iCol = find_header_index(headers, varName)
iCol = find(strcmpi(string(headers), string(varName)), 1);
end

function write_generic_optional_paths(targetWorkbook, targetSheet, headersIn, dedicatedInputs, yearsRef, nYears)
% Generic updater: read any exo_/idx_ row from ScenarioPathDefinition and
% write converted data into Baseline, creating columns when needed.

headers = headersIn;
rowDefs = read_user_defined_optional_rows( ...
    dedicatedInputs.sourceWorkbook, dedicatedInputs.sourceSheet, ...
    dedicatedInputs.sourceStartCol, dedicatedInputs.sourceEndCol);

if isempty(rowDefs)
    return
end

createdCols = {};
for iRow = 1:numel(rowDefs)
    def = rowDefs(iRow);
    convertedFull = apply_conversion_rule(def.rawSeries, def.conversionRule, def.importKey, def.rowNum, dedicatedInputs.years, 2025);

    [trimmedConverted, yearsRow] = trim_series_to_years(convertedFull, dedicatedInputs.years, yearsRef);
    if isempty(trimmedConverted)
        continue
    end
    if numel(trimmedConverted) ~= nYears
        error('CreateBaselineFromUserInputFile:OptionalPathLengthMismatch', ...
            ['Path "%s" (row %d) has %d years after alignment, but growth paths use %d years. ' ...
             'Aligned years: [%g .. %g].'], ...
            def.importKey, def.rowNum, numel(trimmedConverted), nYears, yearsRow(1), yearsRow(end));
    end

    [headers, wasCreated] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headers, ...
        def.importKey, nYears, def.conversionRule);
    if wasCreated
        createdCols{end + 1} = def.importKey; %#ok<AGROW>
    end
    write_series_to_baseline_column(targetWorkbook, headers, def.importKey, trimmedConverted, yearsRow, nYears);
end

if ~isempty(createdCols)
    fprintf('  Baseline dynamic columns added: %s\n', strjoin(createdCols, ', '));
end
end

function rowDefs = read_user_defined_optional_rows(sourceWorkbook, srcSheet, srcStartCol, srcEndCol)
% Read row definitions from A:D where Import Key is in column B and
% Conversion Rule is in column C.

meta = readcell(sourceWorkbook, 'Sheet', srcSheet, 'Range', 'A1:D300');
rowDefs = struct('rowNum', {}, 'importKey', {}, 'conversionRule', {}, 'rawSeries', {});

for r = 10:size(meta, 1)
    keyCell = meta{r, 2};
    if ~(ischar(keyCell) || isstring(keyCell))
        continue
    end

    key = strtrim(char(string(keyCell)));
    if isempty(key)
        continue
    end

    key = canonicalize_import_key(key);

    keyNorm = normalize_label_text(key);
    if strcmp(keyNorm, 'section header')
        continue
    end

    if ~(startsWith(lower(key), 'exo_') || startsWith(lower(key), 'idx_'))
        % Keep required non-exo rows (e.g., growth/share) out of generic write loop.
        continue
    end

    ruleCell = meta{r, 3};
    if ischar(ruleCell) || isstring(ruleCell)
        rule = strtrim(char(string(ruleCell)));
    else
        rule = '';
    end

    rowRange = sprintf('%s%d:%s%d', srcStartCol, r, srcEndCol, r);
    raw = reshape(readmatrix(sourceWorkbook, 'Sheet', srcSheet, 'Range', rowRange), 1, []);
    if isempty(raw) || all(isnan(raw))
        continue
    end

    rowDefs(end + 1) = struct( ...
        'rowNum', r, ...
        'importKey', key, ...
        'conversionRule', rule, ...
        'rawSeries', raw); %#ok<AGROW>
end
end

function converted = apply_conversion_rule(seriesRow, ruleText, importKey, rowNum, sourceYears, anchorYear)
if any(~isfinite(seriesRow))
    error('CreateBaselineFromUserInputFile:InvalidOptionalPathValues', ...
        'Path %s (row %d) contains non-finite values.', importKey, rowNum);
end

ruleNorm = normalize_rule_text(ruleText);

anchorVal = [];
needsAnchor = contains(ruleNorm, 'additive') || (contains(ruleNorm, 'log') && contains(ruleNorm, 'index index 1'));
if needsAnchor
    iAnchor = find(sourceYears == anchorYear, 1, 'first');
    if isempty(iAnchor)
        error('CreateBaselineFromUserInputFile:MissingAnchorYear', ...
            'Path %s (row %d) requires anchor year %d, but it is missing from source years.', ...
            importKey, rowNum, anchorYear);
    end
    anchorVal = seriesRow(iAnchor);
end

if isempty(ruleNorm) || strcmp(ruleNorm, 'direct') || contains(ruleNorm, 'direct')
    converted = seriesRow;
    return
end

if contains(ruleNorm, 'binary') || contains(ruleNorm, 'value 0')
    if any(seriesRow < 0)
        error('CreateBaselineFromUserInputFile:InvalidBinaryInput', ...
            'Binary rule for %s (row %d) does not allow negative values.', importKey, rowNum);
    end
    converted = double(seriesRow > 0);
    return
end

if contains(ruleNorm, 'additive') || (contains(ruleNorm, 'index') && contains(ruleNorm, 'index 1') && contains(ruleNorm, 'minus'))
    if any(seriesRow <= 0)
        error('CreateBaselineFromUserInputFile:NonPositiveIndex', ...
            'Additive index rule for %s (row %d) requires positive values.', importKey, rowNum);
    end
    converted = seriesRow - anchorVal;
    return
end

if contains(ruleNorm, 'log') && contains(ruleNorm, 'index index 1')
    if any(seriesRow <= 0)
        error('CreateBaselineFromUserInputFile:NonPositiveIndex', ...
            'Log index/index(1) rule for %s (row %d) requires positive values.', importKey, rowNum);
    end
    converted = log(seriesRow ./ anchorVal);
    return
end

if contains(ruleNorm, 'log') && contains(ruleNorm, 'index')
    if any(seriesRow <= 0)
        error('CreateBaselineFromUserInputFile:NonPositiveIndex', ...
            'Log index rule for %s (row %d) requires positive values.', importKey, rowNum);
    end
    converted = log(seriesRow);
    return
end

error('CreateBaselineFromUserInputFile:UnknownConversionRule', ...
    'Unknown conversion rule "%s" for %s (row %d).', ruleText, importKey, rowNum);
end

function out = normalize_rule_text(in)
if isempty(in)
    out = '';
    return
end

out = lower(strtrim(string(in)));
out = regexprep(out, '[^a-z0-9]+', ' ');
out = strtrim(regexprep(out, '\s+', ' '));
end

function keyOut = canonicalize_import_key(keyIn)
% Normalize legacy naming to canonical import keys.
key = string(strtrim(keyIn));
key = regexprep(key, '(?i)^exo_lTargetInv_', 'exo_ltargetIY_');
key = regexprep(key, '(?i)^exo_Targetinv_', 'exo_TargetIY_');
key = regexprep(key, '(?i)^exo_targtiy_', 'exo_targetIY_');
keyOut = char(key);
end

function write_pdp8_target_investment_to_path_workbook(dedicatedInputs)
% Compute PDP8 target-I/Y paths and write them to ScenarioPathDefinition Baseline sheet.

[ok, fossilSeries, renewSeries, msg] = compute_pdp8_target_investment_series( ...
    dedicatedInputs.years, dedicatedInputs.gvaGrowth, dedicatedInputs.repoRoot, ...
    dedicatedInputs.projectedGDPBaseYear, dedicatedInputs.projectedGDPBaseValueMioUSD);
if ~ok
    warning('CreateBaselineFromUserInputFile:PDP8TargetIYWriteSkipped', '%s', msg);
    return
end

targetRows = {'exo_targetIY_2_1', 'exo_targetIY_3_1'};
seriesRows = {fossilSeries, renewSeries};
for i = 1:numel(targetRows)
    key = targetRows{i};
    rowNum = find_path_row_by_import_key(dedicatedInputs.sourceWorkbook, dedicatedInputs.sourceSheet, key);
    if isempty(rowNum)
        warning('CreateBaselineFromUserInputFile:MissingTargetIYRow', ...
            'Could not find row for %s in %s/%s; skipping PDP8 write for this key.', ...
            key, dedicatedInputs.sourceWorkbook, dedicatedInputs.sourceSheet);
        continue
    end

    writecell({key}, dedicatedInputs.sourceWorkbook, 'Sheet', dedicatedInputs.sourceSheet, ...
        'Range', sprintf('B%d', rowNum));
    writecell({'direct (share of GDP from PDP8 investment + maintenance)'}, ...
        dedicatedInputs.sourceWorkbook, 'Sheet', dedicatedInputs.sourceSheet, ...
        'Range', sprintf('C%d', rowNum));

    rowRange = sprintf('%s%d:%s%d', dedicatedInputs.sourceStartCol, rowNum, dedicatedInputs.sourceEndCol, rowNum);
    writematrix(reshape(seriesRows{i}, 1, []), dedicatedInputs.sourceWorkbook, ...
        'Sheet', dedicatedInputs.sourceSheet, 'Range', rowRange);
end

fprintf('  Wrote PDP8 target-I/Y shares to ScenarioPathDefinition Baseline sheet.\n');
end

function rowNum = find_path_row_by_import_key(sourceWorkbook, srcSheet, importKey)
meta = readcell(sourceWorkbook, 'Sheet', srcSheet, 'Range', 'A1:D300');
keyNorm = normalize_label_text(importKey);
rowNum = [];

for r = 1:size(meta, 1)
    keyCell = meta{r, 2};
    if ~(ischar(keyCell) || isstring(keyCell))
        continue
    end

    keyHere = canonicalize_import_key(char(string(keyCell)));
    if strcmp(normalize_label_text(keyHere), keyNorm)
        rowNum = r;
        return
    end
end
end

function [ok, fossilSeries, renewSeries, msg] = compute_pdp8_target_investment_series(sourceYears, gvaGrowth, repoRoot, gdpBaseYear, gdpBaseValueMioUSD)
ok = false;
msg = '';
fossilSeries = [];
renewSeries = [];

if ~isfinite(gdpBaseYear) || ~isfinite(gdpBaseValueMioUSD) || gdpBaseValueMioUSD <= 0
    msg = 'Projected GDP base-year configuration must be finite and positive.';
    return
end

invFile = fullfile(repoRoot, 'ExcelFiles', 'PDP8', 'Investment.csv');
idxFile = fullfile(repoRoot, 'ExcelFiles', 'PDP8', 'IndexedTrajectories_FossilRenewable_Capacity.csv');
if ~isfile(invFile) || ~isfile(idxFile)
    msg = sprintf('Required PDP8 files are missing. Investment=%d, Indexed=%d', isfile(invFile), isfile(idxFile));
    return
end

try
    inv = readtable(invFile, 'VariableNamingRule', 'preserve', 'TreatAsEmpty', {'NA'});
    idx = readtable(idxFile, 'VariableNamingRule', 'preserve', 'TreatAsEmpty', {'NA'});
catch ME
    msg = sprintf('Failed to read PDP8 files: %s', ME.message);
    return
end

if ~ismember('Plan', inv.Properties.VariableNames) || ~ismember('Year', inv.Properties.VariableNames) || ...
        ~ismember('Technology', inv.Properties.VariableNames) || ~ismember('INV_MIOUSD', inv.Properties.VariableNames) || ...
        ~ismember('CAP_MIOUSD', inv.Properties.VariableNames)
    msg = 'Investment.csv does not have required columns Plan, Year, Technology, INV_MIOUSD, CAP_MIOUSD.';
    return
end

if ~ismember('Year', idx.Properties.VariableNames) || ~ismember('TechType', idx.Properties.VariableNames) || ...
        ~ismember('Index_Value', idx.Properties.VariableNames)
    msg = 'IndexedTrajectories file does not have required columns Year, TechType, Index_Value.';
    return
end

invPlan = inv(strcmpi(string(inv.Plan), "PDP8_rev_high"), :);
if isempty(invPlan)
    msg = 'No rows found in Investment.csv for Plan == PDP8.';
    return
end

years = sourceYears(:)';
nY = numel(years);
fossilDirect = zeros(1, nY);
renewDirect = zeros(1, nY);

invYear = as_numeric(invPlan.Year);
invMio = as_numeric(invPlan.INV_MIOUSD);
capMio = as_numeric(invPlan.CAP_MIOUSD);
tech = string(invPlan.Technology);
isFossilTech = is_fossil_tech(tech);
isRenewTech = ~isFossilTech;

for i = 1:nY
    y = years(i);
    m = (invYear == y);
    fossilDirect(i) = nansum(invMio(m & isFossilTech));
    renewDirect(i) = nansum(invMio(m & isRenewTech));
end

% Base-year (2025) capital stock value by type from Investment.csv.
capF2025 = nansum(capMio(invYear == 2025 & isFossilTech));
capR2025 = nansum(capMio(invYear == 2025 & isRenewTech));
if ~isfinite(capF2025) || capF2025 <= 0 || ~isfinite(capR2025) || capR2025 <= 0
    msg = 'Could not determine positive 2025 CAP_MIOUSD for fossil/renewables in Investment.csv.';
    return
end

idxYear = as_numeric(idx.Year);
idxType = string(idx.TechType);
idxVal = as_numeric(idx.Index_Value);

fossilIdx = nan(1, nY);
renewIdx = nan(1, nY);
for i = 1:nY
    y = years(i);
    mf = (idxYear == y) & strcmpi(idxType, "Fossil");
    mr = (idxYear == y) & strcmpi(idxType, "Renewable");
    if any(mf)
        fossilIdx(i) = idxVal(find(mf, 1, 'first'));
    end
    if any(mr)
        renewIdx(i) = idxVal(find(mr, 1, 'first'));
    end
end

if any(~isfinite(fossilIdx)) || any(~isfinite(renewIdx))
    msg = 'Indexed trajectory file is missing Fossil/Renewable index values for one or more source years.';
    return
end

% Capital stock value trajectories (MIOUSD) implied by indexed capacities.
capF = 0.025 .* (fossilIdx ./ 100);
capR = capR2025 .* (renewIdx ./ 100);

% Maintenance investment: depreciation * lagged capital stock value.
deltaMaintFos = 0.025;
deltaMaintRen = 0.05;
maintF = deltaMaintFos .* [capF(1), capF(1:end-1)];
maintR = deltaMaintRen .* [capR(1), capR(1:end-1)];

fossilSeries = fossilDirect + maintF;
renewSeries = renewDirect + maintR;

gdpPath = build_projected_gdp_path(sourceYears, gvaGrowth, gdpBaseYear, gdpBaseValueMioUSD);
if any(~isfinite(gdpPath)) || any(gdpPath <= 0)
    msg = 'Projected GDP path contains invalid values. Check total GVA growth inputs.';
    return
end

fossilSeries = fossilDirect ./ gdpPath + 0.025 .* (fossilIdx ./ 100) ./ (gdpPath./gdpPath(1));
renewSeries = renewDirect ./ gdpPath + 0.005.*(renewIdx ./ 100) ./ (gdpPath./gdpPath(1));

ok = true;
end

function gdpPath = build_projected_gdp_path(sourceYears, gvaGrowth, gdpBaseYear, gdpBaseValueMioUSD)
years = reshape(sourceYears, 1, []);
factors = normalize_growth_to_factors(gvaGrowth);
if numel(factors) ~= numel(years)
    error('CreateBaselineFromUserInputFile:GDPGrowthLengthMismatch', ...
        'GVA growth path length (%d) must match year path length (%d).', numel(factors), numel(years));
end

idxBase = find(years == gdpBaseYear, 1, 'first');
if isempty(idxBase)
    error('CreateBaselineFromUserInputFile:GDPBaseYearMissing', ...
        'GDP base year %d is not present in source years.', gdpBaseYear);
end

gdpPath = nan(1, numel(years));
gdpPath(idxBase) = gdpBaseValueMioUSD;

for i = (idxBase + 1):numel(years)
    gdpPath(i) = gdpPath(i - 1) * factors(i);
end

for i = (idxBase - 1):-1:1
    gdpPath(i) = gdpPath(i + 1) / factors(i + 1);
end
end

function x = as_numeric(v)
if isnumeric(v)
    x = double(v);
else
    x = str2double(string(v));
end
end

function mask = is_fossil_tech(techNames)
t = lower(string(techNames));
mask = contains(t, "coal") | contains(t, "gas") | contains(t, "lng") | contains(t, "oil") | contains(t, "diesel") | contains(t, "nuclear") | contains(t, "ccgt");
end

function [headersOut, wasCreated] = ensure_baseline_column_exists(targetWorkbook, targetSheet, headersIn, varName, nYears, ruleText)
headersOut = headersIn;
wasCreated = false;
if ~isempty(find_header_index(headersOut, varName))
    return
end

% Treat NaN (readcell representation of blank cells) as empty; only count real string headers.
isRealHeader = @(x) (ischar(x) && ~isempty(x)) || (isstring(x) && strlength(x) > 0);
lastNonEmpty = find(cellfun(isRealHeader, headersOut), 1, 'last');
if isempty(lastNonEmpty)
    lastNonEmpty = 1;
end

iNewCol = lastNonEmpty + 1;
colNew = excel_col_name(iNewCol);
writecell({varName}, targetWorkbook, 'Sheet', targetSheet, 'Range', sprintf('%s1', colNew));
copy_header_format_from_first_column(targetWorkbook, targetSheet, iNewCol);

ruleNorm = normalize_rule_text(ruleText);
if startsWith(lower(varName), 'idx_')
    defaultVals = ones(nYears, 1);
elseif startsWith(lower(varName), 'exo_r_g_')
    defaultVals = ones(nYears, 1);
elseif contains(ruleNorm, 'binary')
    defaultVals = zeros(nYears, 1);
else
    defaultVals = zeros(nYears, 1);
end

writematrix(defaultVals, targetWorkbook, 'Sheet', targetSheet, ...
    'Range', sprintf('%s2:%s%d', colNew, colNew, nYears + 1));

headersOut = readcell(targetWorkbook, 'Sheet', targetSheet, 'Range', '1:1');
wasCreated = true;
end

function series = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, labelCandidates, emitWarnings)
% Read one or more optional rows by label in columns A:D.
if nargin < 6
    emitWarnings = true;
end

labelBlock = readcell(sourceWorkbook, 'Sheet', srcSheet, 'Range', 'A1:D300');

if ischar(labelCandidates) || isstring(labelCandidates)
    labelCandidates = {char(labelCandidates)};
end

if iscell(labelCandidates) && ~isempty(labelCandidates) && size(labelCandidates, 1) > 1
    % Multiple alternative label sets (rows). Return first complete set.
    series = [];
    for iSet = 1:size(labelCandidates, 1)
        oneSet = labelCandidates(iSet, :);
        oneSet = oneSet(~cellfun(@isempty, oneSet));
        tempSeries = read_optional_labeled_paths(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, oneSet, false);
        if ~isempty(tempSeries)
            series = tempSeries;
            return
        end
    end
    return
end

if numel(labelCandidates) > 1
    % Try strict multi-row read first: require all labels and preserve row order.
    series = [];
    allFound = true;
    for i = 1:numel(labelCandidates)
        s = read_single_labeled_path(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, labelBlock, labelCandidates{i});
        if isempty(s)
            allFound = false;
            break
        end
        series(i, :) = s; %#ok<AGROW>
    end
    if allFound
        return
    end
end

% Single-row case with fallback labels.
series = [];
for i = 1:numel(labelCandidates)
    s = read_single_labeled_path(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, labelBlock, labelCandidates{i});
    if ~isempty(s)
        series = s;
        return
    end
end

if emitWarnings && ~isempty(labelCandidates)
    warning('CreateBaselineFromUserInputFile:MissingOptionalInputLabel', ...
        'Optional input row(s) were not found. First candidate: "%s".', labelCandidates{1});
end
end

function series = read_single_labeled_path(sourceWorkbook, srcSheet, srcStartCol, srcEndCol, labelBlock, label)
series = [];
labelNorm = normalize_label_text(label);

[nR, nC] = size(labelBlock);
rowFound = [];
for r = 1:nR
    for c = 1:nC
        v = labelBlock{r, c};
        if isstring(v) || ischar(v)
            cellNorm = normalize_label_text(v);
            if strcmp(cellNorm, labelNorm) || contains(cellNorm, labelNorm) || contains(labelNorm, cellNorm)
                rowFound = r;
                break
            end
        end
    end
    if ~isempty(rowFound)
        break
    end
end

if isempty(rowFound)
    return
end

rowRange = sprintf('%s%d:%s%d', srcStartCol, rowFound, srcEndCol, rowFound);
series = reshape(readmatrix(sourceWorkbook, 'Sheet', srcSheet, 'Range', rowRange), 1, []);
end

function out = normalize_label_text(in)
out = lower(strtrim(string(in)));
out = regexprep(out, '[^a-z0-9]+', ' ');
out = strtrim(regexprep(out, '\s+', ' '));
end

function report_terminal_va_share_consistency(dedicatedInputs, yearsWritten, repoRoot)
if isempty(yearsWritten)
    warning('CreateBaselineFromUserInputFile:NoYearsWritten', ...
        'No growth years were written to Baseline, skipping terminal VA-share check.');
    return
end

terminalYear = yearsWritten(end);
idxTerminal = find(dedicatedInputs.years == terminalYear, 1, 'last');
if isempty(idxTerminal)
    warning('CreateBaselineFromUserInputFile:TerminalYearNotInInput', ...
        'Terminal year %d is not present in dedicated input years.', terminalYear);
    return
end

targetShares = dedicatedInputs.vaShares(:, idxTerminal);
outputCsv = fullfile(repoRoot, 'ExcelFiles', 'Output', 'Baseline.csv');
if ~isfile(outputCsv)
    warning('CreateBaselineFromUserInputFile:MissingBaselineOutput', ...
        ['Simulation output not found at %s. Run the Baseline simulation ' ...
         'to compare terminal VA shares.'], outputCsv);
    return
end

sim = readtable(outputCsv, 'VariableNamingRule', 'preserve');
if ~ismember('Year', sim.Properties.VariableNames)
    warning('CreateBaselineFromUserInputFile:MissingYearColumn', ...
        'Baseline output CSV does not contain a Year column.');
    return
end

row = find(sim.Year == terminalYear, 1, 'last');
if isempty(row)
    row = height(sim);
    warning('CreateBaselineFromUserInputFile:TerminalYearMissingInOutput', ...
        ['Terminal year %d not found in output. Using last output row (Year=%g) ' ...
         'for VA-share check.'], terminalYear, sim.Year(row));
end

nSub = size(dedicatedInputs.vaShares, 1);
simNominalVA = nan(nSub, 1);
for iSub = 1:nSub
    yName = sprintf('Y_%d_1', iSub);
    pName = sprintf('P_%d_1', iSub);
    if ismember(yName, sim.Properties.VariableNames) && ismember(pName, sim.Properties.VariableNames)
        simNominalVA(iSub) = sim.(yName)(row) .* sim.(pName)(row);
    elseif ismember(yName, sim.Properties.VariableNames)
        simNominalVA(iSub) = sim.(yName)(row);
    end
end

if any(isnan(simNominalVA)) || sum(simNominalVA) <= 0
    warning('CreateBaselineFromUserInputFile:MissingVAColumnsInOutput', ...
        ['Could not construct simulated terminal VA shares from output columns ' ...
         'Y_s_1/P_s_1.']);
    return
end

simShares = simNominalVA ./ sum(simNominalVA);
absDiff = abs(simShares - targetShares(:));
maxDiff = max(absDiff);

fprintf('\nTerminal VA share consistency check (Year %d)\n', terminalYear);
fprintf('  Max abs difference (sim vs input target): %.6f\n', maxDiff);
for iSub = 1:nSub
    fprintf('  Subsector %d: target=%.6f, simulated=%.6f, abs diff=%.6f\n', ...
        iSub, targetShares(iSub), simShares(iSub), absDiff(iSub));
end

tol = 1e-2;
if maxDiff > tol
    warning('CreateBaselineFromUserInputFile:TerminalVAShareMismatch', ...
        ['Terminal VA shares differ from targets by more than %.4f. ' ...
         'Potential inconsistency: source year range/comment mismatch (currently %s:%s), ' ...
         'or model equilibrium effects moving relative prices.'], tol, 'D', 'AC');
end
end

function [growth, yearsOut] = compute_sector_growth_factors(totalGrowth, shares, years, targetStartYear)
    if size(shares, 2) ~= numel(totalGrowth) || numel(years) ~= numel(totalGrowth)
        error('CreateBaselineFromUserInputFile:GrowthShareLengthMismatch', ...
            ['Share and year path lengths must match growth path length. ' ...
             'Got shares=%d, years=%d, growth=%d.'], ...
            size(shares, 2), numel(years), numel(totalGrowth));
    end

    totalGrowthFactors = normalize_growth_to_factors(totalGrowth);
    if any(totalGrowthFactors <= 0)
        error('CreateBaselineFromUserInputFile:NonPositiveGrowth', ...
            ['Growth input implies nonpositive factors. Provide either factors (>0), ' ...
             'decimal rates (e.g., 0.02), or percent rates (e.g., 2 for 2%%).']);
    end

    if any(shares(:) <= 0)
        error('CreateBaselineFromUserInputFile:NonPositiveShare', ...
            'All sector shares must be strictly positive to compute sector growth rates.');
    end

    shareSums = sum(shares, 1);
    if any(abs(shareSums - 1) > 1e-4)
        error('CreateBaselineFromUserInputFile:InvalidShares', ...
            'Sector shares must sum to 1 in each year.');
    end

    idxStart = find(years >= targetStartYear, 1, 'first');
    if isempty(idxStart)
        error('CreateBaselineFromUserInputFile:NoYearsAfterStart', ...
            'No source years >= %d were found in Baseline.', targetStartYear);
    end
    if idxStart == 1
        error('CreateBaselineFromUserInputFile:MissingPreStartYear', ...
            ['Input must contain one year before the model start year (%d) ' ...
             'to compute growth from actual t-1 shares.'], targetStartYear);
    end

    idxOut = idxStart:numel(years);
    prevIdx = (idxStart - 1):(numel(years) - 1);
    growth = shares(:, idxOut) ./ shares(:, prevIdx);
    growth = growth .* repmat(reshape(totalGrowthFactors(idxOut), 1, []), size(shares, 1), 1);
    yearsOut = years(idxOut);
end

function growthFactors = normalize_growth_to_factors(totalGrowth)
    % Accept three conventions for user input:
    % 1) Factors (e.g., 1.02)
    % 2) Decimal rates (e.g., 0.02 or -0.01)
    % 3) Percent rates (e.g., 2 for 2%%)

    if isempty(totalGrowth)
        growthFactors = totalGrowth;
        return
    end

    v = reshape(totalGrowth, 1, []);
    vMax = max(v);
    vMin = min(v);

    if vMax < 0.5
        % Small magnitudes are interpreted as decimal rates.
        growthFactors = 1 + v;
    elseif vMax > 2.5 || vMin <= 0
        % Large magnitudes (or any nonpositive values) are treated as rates.
        % Values above 1 in this branch are interpreted as percent points.
        growthFactors = v;
        isPercent = abs(v) >= 1;
        growthFactors(isPercent) = 1 + v(isPercent) ./ 100;
        growthFactors(~isPercent) = 1 + v(~isPercent);
    else
        % Typical factor inputs around 1.
        growthFactors = v;
    end
end

function remove_nan_headers(targetWorkbook, sheetName)
% Replace NaN header cells with unique placeholder strings so that
% update_baseline_excel does not flag them as duplicate NaN headers.
% Writing '' leaves the cell blank (readcell still returns NaN), so we
% write a non-empty placeholder that is guaranteed unique per column.
try
    headers = readcell(targetWorkbook, 'Sheet', sheetName, 'Range', '1:1');
catch
    return
end
nFixed = 0;
for iCol = 1:numel(headers)
    h = headers{iCol};
    if (isnumeric(h) && isnan(h)) || isempty(h)
        placeholder = sprintf('_unused_%d', iCol);
        try
            writecell({placeholder}, targetWorkbook, 'Sheet', sheetName, ...
                'Range', sprintf('%s1', excel_col_name(iCol)));
            nFixed = nFixed + 1;
        catch
        end
    end
end
if nFixed > 0
    fprintf('  Cleaned %d blank/NaN header cell(s) in sheet "%s".\n', nFixed, sheetName);
end
end

function col = excel_col_name(iCol)
if iCol < 1
    error('CreateBaselineFromUserInputFile:InvalidColumnIndex', ...
        'Excel column index must be >= 1.');
end

letters = '';
while iCol > 0
    remIdx = mod(iCol - 1, 26);
    letters = [char(65 + remIdx) letters]; %#ok<AGROW>
    iCol = floor((iCol - 1) / 26);
end
col = letters;
end

function copy_header_format_from_first_column(targetWorkbook, targetSheet, iTargetCol)
% Copy only header-cell formatting from A1 to the new header cell.
if iTargetCol <= 1
    return
end

exl = [];
wb = [];

try
    exl = actxserver('excel.application');
    exl.DisplayAlerts = false;
    exl.Visible = false;

    wb = exl.Workbooks.Open(targetWorkbook, 0, false);
    ws = wb.Worksheets.Item(targetSheet);

    srcCell = ws.Range('A1');
    dstCell = ws.Range(sprintf('%s1', excel_col_name(iTargetCol)));

    srcCell.Copy;
    dstCell.PasteSpecial(-4122); % xlPasteFormats
    exl.CutCopyMode = false;

    wb.Save;
    wb.Close(true);
    exl.Quit;
catch ME
    warning('CreateBaselineFromUserInputFile:HeaderFormatCopyFailed', ...
        'Could not copy header formatting to %s!%s1 (%s).', ...
        targetSheet, excel_col_name(iTargetCol), ME.message);
    try
        if ~isempty(wb)
            wb.Close(false);
        end
    catch
    end
    try
        if ~isempty(exl)
            exl.Quit;
        end
    catch
    end
end
end

function assert_runnable_baseline_sheet(targetWorkbook)
baselineTable = readtable(targetWorkbook, 'Sheet', 'Baseline');
if isempty(baselineTable) || width(baselineTable) < 2
    error('CreateBaselineFromUserInputFile:BaselineNotBuilt', ...
        'Runnable sheet "Baseline" appears empty in workbook:\n  %s', targetWorkbook);
end

varNames = string(baselineTable.Properties.VariableNames);
if ~any(strcmpi(varNames, 'Time'))
    error('CreateBaselineFromUserInputFile:BaselineMissingTime', ...
        'Runnable sheet "Baseline" does not contain a "Time" column:\n  %s', targetWorkbook);
end
end

function sheetNames = get_workbook_sheet_names(targetWorkbook)
sheetNames = {};

if ~isfile(targetWorkbook)
    return
end

exl = [];
wb = [];

try
    exl = actxserver('excel.application');
    exl.DisplayAlerts = false;
    wb = exl.Workbooks.Open(targetWorkbook, 0, true);

    sheetNames = cell(1, wb.Worksheets.Count);
    for iSheet = 1:wb.Worksheets.Count
        sheetNames{iSheet} = wb.Worksheets.Item(iSheet).Name;
    end

    wb.Close(false);
    exl.Quit;
catch ME
    try
        if ~isempty(wb)
            wb.Close(false);
        end
    catch
    end
    try
        if ~isempty(exl)
            exl.Quit;
        end
    catch
    end
    rethrow(ME);
end
end

function remove_new_sheets(targetWorkbook, originalSheetNames, alwaysKeepSheetNames)
if ~isfile(targetWorkbook)
    return
end

keepNames = [originalSheetNames(:); alwaysKeepSheetNames(:)];

exl = [];
wb = [];

try
    exl = actxserver('excel.application');
    exl.DisplayAlerts = false;
    wb = exl.Workbooks.Open(targetWorkbook, 0, false);

    for iWs = wb.Worksheets.Count:-1:1
        sName = wb.Worksheets.Item(iWs).Name;
        if ~any(strcmp(keepNames, sName)) && wb.Worksheets.Count > 1
            wb.Worksheets.Item(iWs).Delete;
        end
    end

    wb.Save;
    wb.Close(true);
    exl.Quit;
catch ME
    try
        if ~isempty(wb)
            wb.Close(false);
        end
    catch
    end
    try
        if ~isempty(exl)
            exl.Quit;
        end
    catch
    end
    rethrow(ME);
end

end

function [value, found] = read_calibration_parameter_value(calibrationWorkbook, paramName)
% Read a scalar parameter value from calibration workbook.
% Priority: sheet 'Structural Parameters', then sheet 'Start'.

value = NaN;
found = false;

if ~isfile(calibrationWorkbook)
    return
end

sheetCandidates = {'Structural Parameters', 'Start'};
for iCandidate = 1:numel(sheetCandidates)
    s = sheetCandidates{iCandidate};
    try
        t = readtable(calibrationWorkbook, 'Sheet', s, 'Range', 'A:C', 'VariableNamingRule', 'preserve');
    catch
        continue
    end

    if ~ismember('Parameter', t.Properties.VariableNames) || ~ismember('Value', t.Properties.VariableNames)
        continue
    end

    row = strcmp(string(t.Parameter), string(paramName));
    if any(row)
        v = t.Value(find(row, 1, 'first'));
        if isnumeric(v)
            vNum = double(v);
        else
            vNum = str2double(string(v));
        end
        if isfinite(vNum)
            value = vNum;
            found = true;
            return
        end
    end
end
end
