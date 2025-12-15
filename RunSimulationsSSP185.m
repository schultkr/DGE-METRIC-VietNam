% RunSimulations is          a Matlab script to run different scenarios stored in
% ModelSimulationandCalibration<Number of Subsectors>Sectorsand<Number of
% Regions>Regions.xlsx  workbook. The DGE_CRED_Model.mod file is changed 
% in the script.

% addpath('C:\dynare\5.4\matlab')
% addpath('C:\dynare\4.6.3\matlab')
addpath('C:\dynare\6.1\matlab')
%% Specify scenario names
casScenarioNames = {...
                    'Baseline', ...
                    'NZ', ...
                    'NZ_constEE', ...
                    'NZ_constInt', ...
                    'NZ_constEEInt', ...
                    };

casSSPs = {...
                    % 'ssp119', ...
                    % 'ssp585', ...
                    'ssp185', ...
                    % 'ssp519', ...
                    };
%% Define sector strucutre
sSubsecstart = '[1, 2, 3]';                 
sSubsecend =   '[1, 2, 3]';

sSubsecstart = '[1, 2, 4, 5]';                 
sSubsecend =   '[1, 3, 4, 5]';

% sSubsecstart = '[1]';                 
% sSubsecend =   '[1]';
sClimRegional = '["tas", "cyclpers"]';
sClimNational = '["SL"]';
sTargetBase = '1';
lSteadyState = false;
%% Define number of regions
sRegions = '1';
%% Execute dynare to run the model
addpath([pwd() '/Functions'])
addpath([pwd() '/Functions/Miscallenous'])
addpath([pwd() '/Functions/SteadyState'])
addpath([pwd() '/Functions/SteadyState/setupInitialState'])
addpath([pwd() '/Functions/SteadyState/computeCapital'])
if isoctave()
    error('Octave is currently not supported please use Matlab 2019 or above')
end

timestart = tic;

for icoSSP = 1:size(casSSPs,2)
    %% Define additonal specification ofthe version of the modle for sensitivity analysis.
    sSensitivity = char(casSSPs(icoSSP));
    sWorkbookNameInput = ['ExcelFiles/ModelSimulationandCalibration' sSubsecend(end-1) 'Sectorsand' sRegions 'Regions' sSensitivity '.xlsx'];
    %casScenarioNames = sheetnames(sWorkbookNameInput)';
    % casfiles = {dir('ExcelFiles/Input').name};
    % casScenarioNamesAll = ['Baseline' casfiles(cellfun(@(x) contains(x, sSensitivity), casfiles))];
    iposstart = 1;
    % casfilesexist = {dir('ExcelFiles/Output').name};
    % casScenarioNames dy= casScenarioNamesAll(~ismember(casScenarioNamesAll,casfilesexist));

    for icoScenario = iposstart:size(casScenarioNames,2)
        sScenario = char(casScenarioNames(icoScenario));
        % This function allows to switch between endogenous production or
        % productivity shocks.
        if ismember(sScenario,{'Baseline'})
            sSimulation = '20';
            sExoNX = '0'; % exogenous net exports does not work with LOM for foreign assets.
            sCapandTrade = '0';
        elseif any(cellfun(@(x) contains(sScenario, x), {'ssp119'})) 
            sSimulation = '20';
            sExoNX = '0';
            sCapandTrade = '0';% define whether net exports to GDP are constant
        else
            sSimulation = '20';
            sExoNX = '0';
            sCapandTrade = '1';% define whether net exports to GDP are constant
        end
        ChangeModFile(sScenario,sSubsecstart,sSubsecend,sRegions,sSimulation, sExoNX, sCapandTrade, sClimRegional, sClimNational, sTargetBase);
        % Model is called each time. We need to run the preprocessor to update
        % all .m files depending on whether productivity shocks are endogenous or
        % exogenous.
        try
            dynare DGE_CRED_Model noclearall       
        catch
            disp([sScenario ' run with higher iteration'])
        end

    end
end
timeend = toc(timestart);
disp(['time for computation ' num2str(timeend/60) ' minutes'])