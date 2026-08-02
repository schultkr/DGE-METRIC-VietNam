% RunSimulations is a MATLAB script to run scenarios stored in
% ModelSimulationandCalibration<Number of Subsectors>Sectorsand<Number of
% Regions>Regions.xlsx workbook. The DGE_Model.mod file is changed
% in the script.

repoRoot = fileparts(mfilename('fullpath'));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd));
cd(repoRoot);
setup_paths();
%% Specify scenario names (grouped)
lSteadyState = false;
sSensitivity = '_replication';
scenarioGroups = struct();

sversion = '';
% Core reference scenarios
scenarioGroups.Reference = {...
   % 'Baseline', ...
   'NZ',...
    };

% Energy-efficiency scenarios
scenarioGroups.EE = {...
    'EE_Directive10', ...
    'EE_Directive10_NoBESS', ...
    'EE_PDP8_PV_BESS_NoBESS',...
    };

% Green-finance scenarios on PDP8 baseline
scenarioGroups.GF_PDP8 = {...
    'PDP8_GF_A', ...  % Green Finance: Balanced   (WACF 6.43%)
    'PDP8_GF_B', ...  % Green Finance: Market-led (WACF 7.37%)
    'PDP8_GF_C'};     % Green Finance: Public-led (WACF 5.07%)

% Green-finance scenarios on NZ baseline
scenarioGroups.GF_NZ = {...
    'NZ_GF_A', ...
    'NZ_GF_B', ...
    'NZ_GF_C', ...
    'NZ_GF_C_EE'};

% NZ sensitivity / policy variants
scenarioGroups.NZ_Sensitivity = {...
    % 'NZ_constEE', ...
    % 'NZ_constInt', ...
    % 'NZ_constEEInt',...
    % 'NZ_subsidy',...
    'NZ_subsidy_direct',...
    };

% Temporary import-amount shock scenario
scenarioGroups.ImportShock = {...
    % 'ImportShock_Fossil2_P10',...
    'REN_EXPORTS', ...
    };


% Select which groups to run.
% Default group set:
% activeScenarioGroups = {'Reference', 'EE', 'GF_PDP8', 'GF_NZ'};%, 'NZ_Sensitivity'};
% activeScenarioGroups = {'Reference', 'EE', 'GF_PDP8', 'GF_NZ', 'NZ_Sensitivity', 'ImportShock'};
% activeScenarioGroups = {'EE', 'GF_PDP8', 'GF_NZ'};
% activeScenarioGroups = {'Reference'};%, 'EE'};
% activeScenarioGroups = {'NZ_Sensitivity'};%, 'EE'};
% activeScenarioGroups = {'Reference', 'ImportShock'};
% activeScenarioGroups = {'EE', 'GF_PDP8', 'GF_NZ', 'NZ_Sensitivity'};
%activeScenarioGroups = {'ImportShock'};%'GF_NZ'};%, 'EE'};
activeScenarioGroups = {'GF_NZ', 'EE'};
% Optional override via environment variable, e.g.:
%   set DGE_SCENARIO_GROUPS=Reference,GF_NZ
envGroups = strtrim(getenv('DGE_SCENARIO_GROUPS'));
if ~isempty(envGroups)
    activeScenarioGroups = strtrim(strsplit(envGroups, ','));
end

casScenarioNames = {};
for iGroup = 1:numel(activeScenarioGroups)
    groupName = activeScenarioGroups{iGroup};
    if ~isfield(scenarioGroups, groupName)
        error('RunSimulations:UnknownScenarioGroup', ...
            'Unknown scenario group "%s". Check activeScenarioGroups.', groupName);
    end
    casScenarioNames = [casScenarioNames scenarioGroups.(groupName)]; %#ok<AGROW>
end

if isempty(casScenarioNames)
    error('RunSimulations:NoScenariosSelected', ...
        'No scenarios selected. Add at least one group to activeScenarioGroups.');
end

% Define sector strucutre
sSubsecstart = '[1, 2, 4, 5]';                 
sSubsecend =   '[1, 3, 4, 5]';

% sSubsecstart = '[1]';                 
% sSubsecend =   '[1]';
sClimRegional = '["tas"]';
sClimNational = '["tas"]';
sTargetBase = '1';
%% Define number of regions
sRegions = '1';
%% Execute dynare to run the model
if isoctave()
    error('Octave is currently not supported please use Matlab 2019 or above')
end

timestart = tic;

%% Define additonal specification of the version of the model for sensitivity analysis.
sWorkbookCalibration = ['ExcelFiles/ModelCalibration' sSubsecend(end-1) 'Sectorsand' sRegions 'Regions' sSensitivity '.xlsx'];
sWorkbookBaseline    = ['ExcelFiles/ModelBaseline'    sSubsecend(end-1) 'Sectorsand' sRegions 'Regions' sSensitivity '.xlsx'];
sWorkbookScenarios   = ['ExcelFiles/ModelScenarios'   sSubsecend(end-1) 'Sectorsand' sRegions 'Regions' sSensitivity '.xlsx'];
iposstart = 1;
iposend =   Inf;
lBaselineBackward_p = 0;
lReshuffleInitial_p = 1;
% When lReshuffleInitial_p == 1, Functions/simulation_model_refactored.m calls
% reshuffle_initial_period.m to rescale the Baseline initial period's investment
% (by economic activity/subsector and by source: private/FDI/public, each as a
% share of nominal regional GDP) and re-derive consumption, government
% expenditure, net exports and public debt bottom-up to match those targets.
% Two ways to supply targets:
%   1) Point sInvestmentTargetsCsv at a GSO
%      investment_gdp_by_ownership_and_sector.csv (columns: aggregate_sector,
%      public_gdp_ratio, fdi_gdp_ratio_proxy, domestic_private_gdp_ratio_residual,
%      ...) and build_investment_targets_from_gso.m builds tabtargets
%      automatically (Primary+MiningEnergy -> subsector 1, Utilities split
%      Fossil/Renewables by existing K0 shares -> subsectors 2/3,
%      Secondary+Refinery -> subsector 4, Tertiary -> subsector 5).
%      The ownership CSV's total (public+private+FDI summed across sectors,
%      ~34.6% of 2019 GDP) is GSO's "Investment_Activity" survey total --
%      realized investment capital by industry -- which does NOT reconcile
%      with SNA gross fixed capital formation (see docs/data_sources.md and
%      generate_gdp_components_start_end_vs_actual.m's "Actual" column, ~23.3% of
%      GDP for non-housing I in 2019). Left unscaled, the Baseline's
%      simulated investment path runs ~11pp of GDP above that IO-table
%      benchmark. Set sInvestmentTargetsIoTableXlsx (+ optionally
%      sInvestmentTargetsIoTableSheet) to rescale every target
%      proportionally so the aggregate lands on the IO table's total
%      instead, preserving the ownership CSV's relative sector/source
%      shares (see "Rescaling rationale" in build_investment_targets_from_gso.m).
%
% Paths below are personal (outside the repo, under each user's Dropbox),
% so they are derived from %USERPROFILE% rather than hardcoded, and can be
% overridden entirely via DGE_INVESTMENT_TARGETS_CSV /
% DGE_INVESTMENT_TARGETS_IOTABLE_XLSX env vars. If the
% resolved file isn't found, the target is left empty (with a warning) and
% simulation_model_refactored.m skips the reshuffle-from-GSO step rather
% than failing on a bad path.
sInvestmentTargetsCsv = strtrim(getenv('DGE_INVESTMENT_TARGETS_CSV'));
if isempty(sInvestmentTargetsCsv)
    sInvestmentTargetsCsv = fullfile(getenv('USERPROFILE'), 'Dropbox', '2025_GIZ_Vietnam', ...
        'Data', 'GSO', 'data', 'output', 'investment_gdp_by_ownership_and_sector.csv');
end
if ~isfile(sInvestmentTargetsCsv)
    warning('RunSimulations:InvestmentTargetsCsvNotFound', ...
        'sInvestmentTargetsCsv not found at "%s"; skipping GSO investment-target reshuffle.', sInvestmentTargetsCsv);
    sInvestmentTargetsCsv = '';
end

sInvestmentTargetsIoTableXlsx = strtrim(getenv('DGE_INVESTMENT_TARGETS_IOTABLE_XLSX'));
if isempty(sInvestmentTargetsIoTableXlsx)
    sInvestmentTargetsIoTableXlsx = fullfile(getenv('USERPROFILE'), 'Dropbox', '2025_GIZ_Vietnam', ...
        'Data', 'GSO', 'data', 'raw', 'IO-2019.xlsx');
end
if ~isfile(sInvestmentTargetsIoTableXlsx)
    warning('RunSimulations:InvestmentTargetsIoTableNotFound', ...
        'sInvestmentTargetsIoTableXlsx not found at "%s"; investment targets will not be rescaled to the IO-table total.', sInvestmentTargetsIoTableXlsx);
    sInvestmentTargetsIoTableXlsx = '';
end
sInvestmentTargetsIoTableSheet = 'Calibration for GDP Components';  % default; only needed if the sheet name changes
%   2) Define a 'tabtargets' struct here directly, e.g.:
%   tabtargets.IFDI_3_1 = 0.015;  % FDI into region 1 Renewables = 1.5% of regional GDP
%   tabtargets.IG_1_1   = 0.02;   % Public investment into region 1 Primary = 2% of regional GDP
% See Functions/SteadyState/reshuffle_initial_period.m for the full field
% convention. Any (subsector, region, source) left undefined keeps its
% pre-reshuffle model value.

% Optional: additionally reconcile fossil/renewables (subsector 2/3)
% investment against the empirical PDP8 investment/capital-stock ratio
% (first two PDP8 years), holding K_2_1/K_3_1 fixed and letting P_INV
% absorb the reconciliation via tabtargets.IK_2_1/IK_3_1. See
% Functions/SteadyState/reshuffle_initial_period.m step 1b and
% Functions/Miscellaneous/Simulation/compute_pdp8_capital_investment_ratio.m
% for why this ratio must reuse the same New + Maintenance decomposition as
% exo_targetIY_2_1/exo_targetIY_3_1, not a raw INV_MIOUSD/CAP_MIOUSD ratio.
lReshuffleIK_p = 1;
sBaselineSheet = 'Baseline';
lBaselineWarmStart_p = false;
sBaselineWarmRef = '';
iPerfectForesightMaxit_p = NaN;
iStepSimulationOverride_p = NaN;

scenarioStart = max(1, iposstart);
scenarioEnd = min(iposend, numel(casScenarioNames));
for icoScenario = scenarioStart:scenarioEnd
    sScenario = char(casScenarioNames(icoScenario));
    % This function allows to switch between endogenous production or
    % productivity shocks.
    if contains(sScenario,{'Baseline'})
        sBaseline = 'Baseline';
        if lSteadyState
            sSimulation = '5'; %#ok<UNRCH>
        else
            sSimulation = '20';
        end
        sExoNX = '0'; % exogenous net exports does not work with LOM for foreign assets.
        sCapandTrade = '0';
    elseif ismember(sScenario,{'NZ_constEE', 'NZ_constInt', 'NZ_constEEInt', ...
                               'NZ_concessional', 'NZ_conandsub', 'NZ_subsidy',...
                               'NZ_subsidy_direct', 'NZ_GF_A', 'NZ_GF_B', 'NZ_GF_C', 'NZ_GF_C_EE'})
        sBaseline = 'NZ';
        sSimulation = '40';
        sExoNX = '0';% define whether net exports to GDP are constant
        sCapandTrade = '1';
    elseif ismember(sScenario, {'PDP8_GF_A', 'PDP8_GF_B', 'PDP8_GF_C'})
        sBaseline = 'Baseline';
        sSimulation = '5';
        sExoNX = '0';
        sCapandTrade = '1';
    elseif ismember(sScenario, {'EE_Directive10_nocap'})
        sBaseline = 'Baseline';
        sSimulation = '5';
        sExoNX = '0';
        sCapandTrade = '0';        
    else
        sBaseline = 'Baseline';
        sSimulation = '20';
        sExoNX = '0';% define whether net exports to GDP are constant
        sCapandTrade = '1';
    end

    change_mod_file(sScenario,sSubsecstart,sSubsecend,sRegions,sSimulation, sExoNX, sCapandTrade, sClimRegional, sClimNational, sTargetBase);
    % Model is called each time. We need to run the preprocessor to update
    % all .m files depending on whether productivity shocks are endogenous or
    % exogenous.
    try
        dynare DGE_Model noclearall
    catch ME
        disp([sScenario ' run with higher iteration'])
        disp(['Run error: ' ME.message])
    end

end  % icoScenario

timeend = toc(timestart);
disp(['time for computation ' num2str(timeend/60) ' minutes'])
