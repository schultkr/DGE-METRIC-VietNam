% ============================================
% === Define number of sectors and regions ===
% ============================================
@# define ASubsecstart = [1, 2, 4, 5]
@# define ASubsecend = [1, 3, 4, 5]
@# define Subsecstart = [1, 2, 4, 5]
@# define Subsecend = [1, 3, 4, 5]
@# define Sectors = length(Subsecend)
@# define Subsectors = Subsecend[Sectors]
@# define ForwardLooking = 1
@# define YEndogenous = 1
@# define NEndogenous = 1
@# define YTarget = 1
@# define BaselineScenario = 0
@# define CapandTrade = 1
@# define ExoNX = 0
@# define HouseSector = 0
@# define Regions = 1
@# define lSolow = 0
@# define lCapQuad = 0
@# define lAdjPos = 1    // 1 = shut off adjustment costs when I_H < 0 (smooth Heaviside weight)
@# define lEndoUtilization = 0    // 1 = endogenous utilization (u_K < 1 when capital can't shrink fast enough)
@# define lCapPrice = 1    // 0 = investment adjustment costs, 1 = capital goods supply price curve
@# define lInternalizePK = 0   // 0 = price-taker, 1 = household internalizes dP_K/dI_H (only when lCapPrice=1)
@# define lCapGoodsSecPrice = 1   // 0 = P_K based on sector's own P, 1 = P_K based on P_Q of CapGoodsSubsec
@# define CapGoodsSubsec = 0      // subsector index used for capital goods base price when lCapGoodsSecPrice=1 (sector 4 = subsector 5)
@# define TAdjust = 1
@# define EndoInvEn = 1
@# define InvExo = ["I_3_1"]
@# define ClimateVarsRegional = ["tas"]
@# define ClimateVarsNational = ["tas"]
@# define ClimateVars = ClimateVarsRegional + ClimateVarsNational
@# if Sectors > 1
    @# define SubsecFossil = 2
    @# define SubsecRE = 3
    @# define SecEnergy = 2
@# else
    @# define SubsecFossil = 1
    @# define SubsecRE = 1
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
sWorkbookCalibration = ['ExcelFiles/ModelCalibration' num2str(@{Subsecend[Sectors]}) 'Sectorsand' num2str(@{Regions}) 'Regions.xlsx'];
sWorkbookBaseline    = ['ExcelFiles/ModelBaseline'    num2str(@{Subsecend[Sectors]}) 'Sectorsand' num2str(@{Regions}) 'Regions.xlsx'];
if ~exist('sBaselineSheet', 'var') || isempty(sBaselineSheet)
    sBaselineSheet = 'Baseline';
end
sWorkbookScenarios   = ['ExcelFiles/ModelScenarios'   num2str(@{Subsecend[Sectors]}) 'Sectorsand' num2str(@{Regions}) 'Regions.xlsx'];
sWorkbookNameOutput = ['ExcelFiles/ResultsScenarios' num2str(@{Subsecend[Sectors]}) 'Sectorsand' num2str(@{Regions})  'Regions.xlsx'];
% =====================
% === Add mod files ===
% =====================
@# include "ModFiles/DGE_Model_Declaration.mod"
@# if Sectors>1
@# include "ModFiles/DGE_Model_Equations.mod"
@# else
@# include "ModFiles/DGE_Model_Equations_display.mod"
@# endif
@# include "ModFiles/DGE_Model_LatexOutput.mod"
@# if Sectors>1
M_.ClimateVarsRegional = '@{ClimateVarsRegional}';
M_.ClimateVarsNational = '@{ClimateVarsNational}';
if exist(sWorkbookCalibration, 'file')
    @# include "ModFiles/DGE_Model_Parameters.mod"
    % run script to define expressions used later on. 
    //define_auxiliary_expressions
    define_auxiliary_expressions_looped
    @# if ForwardLooking == 1
        sVersion = ['Sectors' num2str(imaxsec_p) 'Regions' num2str(inbregions_p) sSensitivity];
    @# else
        sVersion = ['Sectors' num2str(imaxsec_p) 'Regions' num2str(inbregions_p) 'Backward' sSensitivity];
    @# endif
    % run script to compute steady state and calibrate the model.
    steadystate_model
    % run script to simulate the model.
    simulation_model_refactored
    sFieldScenario = strrep(sScenario, '.csv', '');
    if exist(['structScenarioResults' sSensitivity '.mat'], 'file')
        load(['structScenarioResults' sSensitivity '.mat'], 'structScenarioResults')
        structScenarioResults.(sVersion).(sFieldScenario).oo_ = oo_;
        structScenarioResults.(sVersion).(sFieldScenario).M_ = M_;
        structScenarioResults.(sVersion).(sFieldScenario).options_ = options_;    
        save(['structScenarioResults' sSensitivity '.mat'], 'structScenarioResults', '-append')
    else
        structScenarioResults = [];
        structScenarioResults.(sVersion).(sFieldScenario).oo_ = oo_;
        structScenarioResults.(sVersion).(sFieldScenario).M_ = M_;
        structScenarioResults.(sVersion).(sFieldScenario).options_ = options_; 
        save(['structScenarioResults' sSensitivity '.mat'], 'structScenarioResults')
    end
else
    disp(['Create ' sWorkbookCalibration])
end
@# endif
