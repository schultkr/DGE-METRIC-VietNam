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

scenarioGroups = struct();

% Core reference scenarios
scenarioGroups.Reference = {...
    'Baseline', ...
    % 'NZ',...
    };

% Energy-efficiency scenarios
scenarioGroups.EE = {...
    'EE_PDP8', ...
    'EE_Directive10', ...
    'EE_Directive10_NoBESS', ...
    'EE_PDP8_PV_BESS_NoBESS'};

% Green-finance scenarios on PDP8 baseline
scenarioGroups.GF_PDP8 = {...
    'PDP8_GF_A', ...  % Green Finance: Balanced   (WACF 6.43%)
    'PDP8_GF_B', ...  % Green Finance: Market-led (WACF 7.37%)
    'PDP8_GF_C'};     % Green Finance: Public-led (WACF 5.07%)

% Green-finance scenarios on NZ baseline
scenarioGroups.GF_NZ = {...
    'NZ_GF_A', ...
    'NZ_GF_B', ...
    'NZ_GF_C'};


% Select which groups to run.
% Default group set:
activeScenarioGroups = {'Reference', 'EE', 'GF_PDP8', 'GF_NZ'};%, 'NZ_Sensitivity'};

% activeScenarioGroups = {'GF_PDP8'};
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
    casScenarioNames = [casScenarioNames, scenarioGroups.(groupName)]; %#ok<AGROW>
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

%% Define additonal specification ofthe version of the modle for sensitivity analysis.
sWorkbookCalibration = ['ExcelFiles/ModelCalibration' sSubsecend(end-1) 'Sectorsand' sRegions 'Regions.xlsx'];
sWorkbookBaseline    = ['ExcelFiles/ModelBaseline'    sSubsecend(end-1) 'Sectorsand' sRegions 'Regions.xlsx'];
sWorkbookScenarios   = ['ExcelFiles/ModelScenarios'   sSubsecend(end-1) 'Sectorsand' sRegions 'Regions.xlsx'];
iposstart = 1;
iposend =   7;
lBaselineBackward_p = 0;

%% Baseline candidate sweep
% Each entry is the name of a sheet inside ModelBaseline5Sectorsand1Regions.xlsx.
% The first entry must be 'Baseline' (the reference sheet already present).
% Add extra candidate sheets to the same workbook and list their names here.
%
% sSensitivity (used for structScenarioResults<suffix>.mat and sVersion key)
% is derived automatically as strrep(sheetName,'Baseline',''), so:
%   'Baseline'       -> sSensitivity = ''        -> structScenarioResults.mat
%   'Baseline_Cand01'-> sSensitivity = '_Cand01' -> structScenarioResults_Cand01.mat
%
% For every candidate the solver warm-starts oo_.endo_simul from the
% immediately preceding entry's solved Baseline path.
%
% To add a candidate:
%   1. Open ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx
%   2. Duplicate the 'Baseline' sheet and rename it, e.g. 'Baseline_Cand01'
%   3. Edit VA shares / growth rates in that sheet
%   4. Add 'Baseline_Cand01' to casCandidates below.
casCandidates = {'Baseline'};

for icoCand = 1:numel(casCandidates)
    sBaselineSheet = casCandidates{icoCand};           % sheet to read from ModelBaseline*.xlsx
    sSensitivity   = strrep(sBaselineSheet, 'Baseline', '');  % '' for reference, '_Cand01' etc. for candidates
    % Warm-start from the immediately preceding candidate's solved path.
    if icoCand == 1
        sBaselineWarmRef = '';   % no warm-start for the first (reference) run
    else
        sBaselineWarmRef = strrep(casCandidates{icoCand - 1}, 'Baseline', '');
    end

for icoScenario = iposstart:min(iposend,size(casScenarioNames,2))
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
    elseif ismember(sScenario,{'NZ_constEE', 'NZ_constInt', 'NZ_constEEInt', 'NZ_lowphiK', ...
                               'NZ_concessional', 'NZ_conandsub', 'NZ_subsidies', ...
                               'NZ_GF_A', 'NZ_GF_B', 'NZ_GF_C'})
        sBaseline = 'NZ';
        sSimulation = '20';
        sExoNX = '0';% define whether net exports to GDP are constant
        sCapandTrade = '1';
    elseif ismember(sScenario, {'PDP8_GF_A', 'PDP8_GF_B', 'PDP8_GF_C'})
        sBaseline = 'Baseline';
        sSimulation = '5';
        sExoNX = '0';
        sCapandTrade = '1';
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
    catch
        disp([sScenario ' run with higher iteration'])
    end

end  % icoScenario
end  % icoCand
timeend = toc(timestart);
disp(['time for computation ' num2str(timeend/60) ' minutes'])
