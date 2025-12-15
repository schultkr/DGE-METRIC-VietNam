% ============================================
% === Define number of sectors and regions ===
% ============================================
@# define Subsecstart = [1, 2, 4, 5]
@# define Subsecend = [1, 3, 4, 5]
@# define Sectors = length(Subsecend)
@# define Subsectors = Subsecend[Sectors]
@# define ForwardLooking = 1
@# define YEndogenous = 1
@# define YTarget = 1
@# define CapandTrade = 1
@# define ExoNX = 0
@# define HouseSector = 0
@# define Regions = 1
@# define AggregateCapital = 0
@# define lSolow = 0
@# define lCapQuad = 0
@# define TAdjust = 1
@# define ClimateVarsRegional = ["tas", "cyclpers"]
@# define ClimateVarsNational = ["SL"]
@# define ClimateVars = ClimateVarsRegional + ClimateVarsNational
@# if Sectors > 1
    @# define SubsecFossil = 2
    @# define SecEnergy = 2
@# else
    @# define SubsecFossil = 1
    @# define SecEnergy = 1
@# endif
if ~exist('sSensitivity', 'var')
    sSensitivity = '';
end
% ===================================
% === Define number of iterations ===
% ===================================
options_.iStepSteadyState = 1;
options_.iStepSimulation = 20;
% =====================================================
% === Define excel files names and add search paths ===
% =====================================================
sWorkbookNameInput = ['ExcelFiles/ModelSimulationandCalibration' num2str(@{Subsecend[Sectors]}) 'Sectorsand' num2str(@{Regions}) 'Regions' sSensitivity '.xlsx'];
sWorkbookNameOutput = ['ExcelFiles/ResultsScenarios' num2str(@{Subsecend[Sectors]}) 'Sectorsand' num2str(@{Regions})  'Regions' sSensitivity '.xlsx'];
% =====================
% === Add mod files ===
% =====================
@# include "ModFiles/DGE_CRED_Model_Declaration.mod"
@# if Sectors>1
@# include "ModFiles/DGE_CRED_Model_Equations.mod"
@# else
@# include "ModFiles/DGE_CRED_Model_Equations_display.mod"
@# endif
@# include "ModFiles/DGE_CRED_Model_LatexOutput.mod"
@# if Sectors>1
M_.ClimateVarsRegional = '@{ClimateVarsRegional}';
M_.ClimateVarsNational = '@{ClimateVarsNational}';
if exist(sWorkbookNameInput, 'file')
    @# include "ModFiles/DGE_CRED_Model_Parameters.mod"
    % run script to define expressions used later on. 
    DefineAuxiliaryExpressions
    @# if ForwardLooking == 1
        sVersion = ['Sectors' num2str(imaxsec_p) 'Regions' num2str(inbregions_p) sSensitivity];
    @# else
        sVersion = ['Sectors' num2str(imaxsec_p) 'Regions' num2str(inbregions_p) 'Backward' sSensitivity];
    @# endif
    % run script to compute steady state and calibrate the model.
    SteadyState_Model
    % run script to simulate the model.
    Simulation_Model
    sFieldScenario = strrep(sScenario, '.csv', '');
    if isequal(sScenario, 'Baseline')
        if exist(['structScenarioResults' sSensitivity '.mat'], 'file')
            load(['structScenarioResults' sSensitivity '.mat'], 'structScenarioResults')
            structScenarioResults.(sVersion).(sFieldScenario).oo_ = oo_;
            structScenarioResults.(sVersion).(sFieldScenario).M_ = M_;
            structScenarioResults.(sVersion).(sFieldScenario).options_ = options_;    
            save(['structScenarioResults' sSensitivity '.mat'], 'structScenarioResults', '-append')
        else
            structScenarioResults.(sVersion).(sFieldScenario).oo_ = oo_;
            structScenarioResults.(sVersion).(sFieldScenario).M_ = M_;
            structScenarioResults.(sVersion).(sFieldScenario).options_ = options_; 
            save(['structScenarioResults' sSensitivity '.mat'], 'structScenarioResults')
        end
    end
else
    disp(['Create ' sWorkbookNameInput])
end
@# endif