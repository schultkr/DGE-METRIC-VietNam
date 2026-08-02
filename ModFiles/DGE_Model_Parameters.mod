% ================================================================
%  DGE_Model_Parameters.mod
%  Dynamic General Equilibrium for Macroeconomic Energy Transition
%  Incorporating Carbon Markets (DGE-METRIC)
% ================================================================
%  Defines all model parameters for the DGE-METRIC Dynare model.
%
%  Structure:
%    1. Model Switches & Flags
%    2. Sector & Region Structure
%    3. Preferences & Macro Scalars
%       3.1 Trade elasticities
%       3.2 Trade shares & persistence
%       3.3 Tax rates
%       3.4 Discount, depreciation & capital
%       3.5 Preferences
%       3.6 Persistence & shock processes
%       3.7 Calibration targets
%       3.8 Adjustment costs
%    4. Climate Variables (National)
%    5. Regional Parameters
%    6. Sectoral & Subsectoral Parameters
%    7. Excel Calibration Overrides
%
%  Parameter naming convention:
%    *_p         = calibrated parameter
%    macro    = Dynare preprocessor macro (replaced at compile time)
%    z0_p     = initial steady-state value for climate variable z
%    zT_p     = target steady-state value for climate variable z
%
%  Dependencies:
%    - sWorkbookCalibration (Excel file with Start & Structural sheets)
%    - DGE_Model_Declaration.mod (variable/parameter declarations)
% ================================================================

% ----------------------------------------------------------------
% ----------------------------------------------------------------
% 1. Model Switches & Flags
% ----------------------------------------------------------------
inbsectors_p = @{Sectors};
lExoNX_p = @{ExoNX};
lCapGoodsSecPrice_p = @{lCapGoodsSecPrice};
iCapGoodsSubsec_p   = @{CapGoodsSubsec};
iSubsecFossil_p = @{SubsecFossil};
iSubsecRE_p = @{SubsecRE};
iSecEnergy_p = @{SecEnergy};
lEndogenousY_p = @{YEndogenous};
lEndogenousN_p = @{NEndogenous};
lTargetY_p = @{YTarget};
lCapandTrade_p = @{CapandTrade};
iSecHouse_p = @{HouseSector};
lEndoMig_p = 0;
TAdjLF_p = @{TAdjust};
etaLF_p = 1/2;

% ----------------------------------------------------------------
% 2. Sector & Region Structure
% ----------------------------------------------------------------

@# for sec in 1:Sectors
    substart_@{sec}_p = @{Subsecstart[sec]};
    subend_@{sec}_p = @{Subsecend[sec]};
@# endfor
inbsubsectors_p = subend_@{Sectors}_p;
inbregions_p = @{Regions};
@# if ForwardLooking == 1
    omegaP_p = 1;
@# else
    omegaP_p = 0.5; // 0.5 is lower bound for simulation to work
@# endif
phiadjB_p = 1;

% ----------------------------------------------------------------
% 3. Preferences & Macro Scalars
% ----------------------------------------------------------------

% 3.1 Trade elasticities
etaX_p = 0.61;
etaQ_p = 1.04;
etaF_p = 1.1;
etaM_p = 0.95;

% 3.2 Trade shares & persistence
omegaNX0_p = 0.03;
omegaNX_p = omegaNX0_p;
omegaNXT_p = 0.03;
rhoNX_p = 0.9;

% 3.3 Tax rates
tauC_p = 0.1;
tauH_p = 0.05;
tauNH_p = 0.2;
tauKH_p = 0.2;
phitauS_p = 1;

% 3.4 Discount, depreciation & capital
beta_p = 0.95;
rf0_p = 1/beta_p - 1;
delta_p = 0.05;
deltaB_p = 0.05;
deltaH_p = 0.05;
deltaKG_p = 0.1;
deltaPV_p = 0.1;
phiG_p = 0;
phiPV_p = 0.1;
phiKPV0_p = 0.013;
phiQPV0_p = 0.02;
phiKPE_p = 0.2;
rhophiK_p = 0.75;
phiKE_p = 0;
chiSRI_p = 0;
gamPEdel_p = 0;

% 3.5 Preferences
sigmaL_p = 0.5;
sigmaC_p = 1;
sigmaU_p = 2;   % utilization curvature (sigmaU > rKSS/delta ensures delta_eff >= 0 at u_K=0)
etaKS_p = 10;   % capital goods supply elasticity; etaKS â†’ âˆž gives P_K = P (no friction)
h_p = 0.7;

% 3.6 Persistence & shock processes
rhoA_p = 0.9;
rhos_p = 0.5;
rhoSL_p = 0.9;
rhoPoP_p = 0.9;
rhoT_p = 0.9;
rhoWS_p = 0.9;
rhoPREC_p = 0.9;

% 3.7 Calibration targets
Y0_p = 1;
Q0_p = 2;
NX0_p = 1;
P0_p = 1;
PE0_p = 0;
E0_p = 1;
E0_NOETS_p = 0;
PoP0_p = 1;
PoPT_p = 1;
YT_p = Y0_p;
PT_p = Y0_p;

% 3.8 Adjustment costs
phiB_p = 10;
phiK_p = 10;
phiY_p = 1/2;
% ----------------------------------------------------------------
% 4. Climate Variables (National)
% ----------------------------------------------------------------

@# for z in ClimateVarsNational
    @{z}0_p = 0;
    @{z}T_p = @{z}0_p;
@# endfor
@# for reg in 1:Regions
    s0_@{reg}_p = 1;
    tauC_@{reg}_p = 0.2;
    sGY0_@{reg}_p = 0.095291; // actual 2019 government-consumption share of GDP (GC/TOTAL, GSO 2019 IO table, GSO_REDUCED sheet); drives the calibration-stage G target/tauC_@{reg}_p back-solve, see compute_regional_economic_accounts.m
    tauH_@{reg}_p = 0;
% ----------------------------------------------------------------
% 5. Regional Parameters
% ----------------------------------------------------------------

    tauNH_@{reg}_p = 0;
    sH_@{reg}_p = 0.01;
    P0_MR_@{reg}_p = 1;
    P0_D_@{reg}_p = 1;
    PE0_@{reg}_p = 0;
    E0_@{reg}_p = 1;
    E0_NOETS_@{reg}_p = 0;
    NX0_@{reg}_p = 0;
    Y0_@{reg}_p = 1;
    Tr0_@{reg}_p = 0;
    BG0_@{reg}_p = 0;
    phi_BG_ext_@{reg}_p = 0.2;
    gamma_@{reg}_p = 0.05;
    omegaF_@{reg}_p = 0.05;
    H0_@{reg}_p = 23;
    PH0_@{reg}_p = 1;
    N0_@{reg}_p = 0.15;
    PoP0_@{reg}_p = 0.95;
    LF0_@{reg}_p = 0.8 * PoP0_@{reg}_p;
    omegaLF0_@{reg}_p = LF0_@{reg}_p;
    @# for z in ClimateVarsRegional
        @{z}0_@{reg}_p = 0;
        @{z}T_@{reg}_p = @{z}0_@{reg}_p;
    @# endfor
@# endfor
PoP0_p = 1;
@# for sec in 1:Sectors
% ----------------------------------------------------------------
% 6. Sectoral & Subsectoral Parameters
% ----------------------------------------------------------------

    omegaQA_@{sec}_p = 1/inbsectors_p;
    omegaMA_F_@{sec}_@{reg}_p = 1/inbsectors_p;
    etaQA_@{sec}_p = 0.01;
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
        omega_@{subsec}_p = 1/(subend_@{sec}_p - substart_@{sec}_p + 1);
        D_X_@{subsec}_p = 1;
        P_M_@{subsec}_p = 1;
        M0_@{subsec}_p = 1;
        etaI_@{subsec}_p = 1.05;
        etaIA_@{subsec}_p = 0.1;
        etaQ_@{subsec}_p = 2;
        iHomeBias_@{subsec}_p = 0.8;
        @# for reg in 1:Regions
            lEndoQ_@{subsec}_@{reg}_p = 1;
            lEndoN_@{subsec}_@{reg}_p = 1;
            @# if YEndogenous == 1
                @# if reg < Regions 
                    @# if subsec == SubsecFossil
                        lEndoQ_@{subsec}_@{reg}_p = 1;
                        lEndoN_@{subsec}_@{reg}_p = 1;
                    @# endif
                @# endif
            @# endif
            P0_Q_@{subsec}_@{reg}_p = 1;
            P0_@{subsec}_@{reg}_p = 1;
            I0_G_@{subsec}_@{reg}_p = 0.05;
            phiQI_@{subsec}_@{reg}_p = 0.5/(subend_@{Sectors}_p*inbregions_p);
            phiM_F_@{subsec}_@{reg}_p = 0.1/(2*inbsubsectors_p);            
            phiM_I_@{subsec}_@{reg}_p = 0.1/(2*inbsubsectors_p);           
            omegaM_@{subsec}_@{reg}_p = 1/subend_@{Sectors}_p;
            omegaM_F_@{subsec}_@{reg}_p = 1/subend_@{Sectors}_p;
            omegaQ_@{subsec}_@{reg}_p = 1/subend_@{Sectors}_p;
            delta_@{subsec}_@{reg}_p = 0.05;
            tauKF_@{subsec}_@{reg}_p = 0;
            tauKH_@{subsec}_@{reg}_p = 0;
            tauNF_@{subsec}_@{reg}_p = 0;
            A_@{subsec}_@{reg}_p = 1;
            phiX_@{subsec}_@{reg}_p = 1/inbregions_p;
            omegaA_@{subsec}_@{reg}_p = 0.025;
            Q0_@{subsec}_@{reg}_p = 1.06;       
            Q_I0_@{subsec}_@{reg}_p = 1.06;                 
            E0_@{subsec}_@{reg}_p = 1.06;            
            gY0_@{subsec}_@{reg}_p = 1.06;
            gN0_@{subsec}_@{reg}_p = 1.06;
            A0_@{subsec}_@{reg}_p = 1;
            K0_@{subsec}_@{reg}_p = 1;
            Y0_@{subsec}_@{reg}_p = 1;
            A_N_@{subsec}_@{reg}_p = 1;
            A_K_@{subsec}_@{reg}_p = 1;
            phiW_@{subsec}_@{reg}_p = 0.5;
            s_G_@{subsec}_@{reg}_p = 0;
            phiN_@{subsec}_@{reg}_p = 1/(subend_@{Sectors}_p*inbregions_p);
            phiN0_@{subsec}_@{reg}_p = phiN_@{subsec}_@{reg}_p;
            phiNT_@{subsec}_@{reg}_p = phiN_@{subsec}_@{reg}_p;
            phiY_@{subsec}_@{reg}_p = 0.5/(subend_@{Sectors}_p*inbregions_p);
            phiY0_@{subsec}_@{reg}_p = phiY_@{subsec}_@{reg}_p;
            phiYT_@{subsec}_@{reg}_p = phiY_@{subsec}_@{reg}_p;
            phiX_@{subsec}_@{reg}_p = 0.15/(subend_@{Sectors}_p*inbregions_p);
            phiL_@{subsec}_@{reg}_p = 1;
            alphaK_@{subsec}_@{reg}_p = 0.5;
            alphaN_@{subsec}_@{reg}_p = 0.5;
            phiG_@{subsec}_@{reg}_p=0;
            // Ceiling on K_G/K(-1): a crowding-out backstop, not a policy target — loose by
            // default (0.85) so it only binds when public capital would otherwise force K_H
            // negative (see ModFiles/Equations/government.mod). Override per scenario/sector
            // via exo_sKGmax_@{subsec}_@{reg} if a tighter or looser cap is needed.
            sKGmax_@{subsec}_@{reg}_p = 0.85;
            sFDI0_@{subsec}_@{reg}_p = 0;
            phiFDI0_@{subsec}_@{reg}_p = 0;
            @# for regm in 1:Regions
                omegaQ_@{subsec}_@{reg}_@{regm}_p = 1/inbregions_p;
                @# if reg == regm
                    phiQ_D_@{subsec}_@{reg}_@{regm}_p = iHomeBias_@{subsec}_p^(inbregions_p>1);
                @# else
                    phiQ_D_@{subsec}_@{reg}_@{regm}_p = (1 - iHomeBias_@{subsec}_p^(inbregions_p>1))/(inbregions_p-1);
                @# endif
            @# endfor
            omegaQI_@{subsec}_@{reg}_p = 1/2;
            kappaE_@{subsec}_@{reg}_p = 0.0;
            kappaE_NOETS_@{subsec}_@{reg}_p = 0.0;
            sE_@{subsec}_@{reg}_p = 1/(subend_@{Sectors}_p*inbregions_p+inbsectors_p*inbregions_p*subend_@{Sectors}_p);
            sE_NOETS_@{subsec}_@{reg}_p = sE_@{subsec}_@{reg}_p;

            @# for secm in 1:Sectors
                omegaQI_@{subsec}_@{reg}_@{secm}_p = 1/inbsectors_p;
                phiQI_@{subsec}_@{reg}_@{secm}_p = 1/inbsectors_p;
                kappaEI_@{subsec}_@{reg}_@{secm}_p = 0;
                sEI_@{subsec}_@{reg}_@{secm}_p = 0;
            @# endfor
            etaNK_@{subsec}_@{reg}_p = 0.95;
            deltaKA_@{subsec}_@{reg}_p = 0.1;
            phiK_@{subsec}_@{reg}_p = 1;
            // TFP coefficients
            @# for z in ClimateVars
                a_@{z}_1_@{subsec}_@{reg}_p = 0;
                a_@{z}_2_@{subsec}_@{reg}_p = 0;
                a_@{z}_3_@{subsec}_@{reg}_p = 2;
                aK_@{z}_1_@{subsec}_@{reg}_p = 0;
                aK_@{z}_2_@{subsec}_@{reg}_p = 0;
                aK_@{z}_3_@{subsec}_@{reg}_p = 2;
                aN_@{z}_1_@{subsec}_@{reg}_p = 0;
                aN_@{z}_2_@{subsec}_@{reg}_p = 0;
                aN_@{z}_3_@{subsec}_@{reg}_p = 2;
                phiGA@{z}_@{subsec}_@{reg}_p = 1;
            @# endfor
        @# endfor
    @# endfor
@# endfor

% ----------------------------------------------------------------
% 7. Excel Calibration Overrides
% ----------------------------------------------------------------
TempValues = readtable(sWorkbookCalibration, 'Sheet', 'Start','Range','A:C');
[lParams,iaMparams] = ismember(cellstr(M_.param_names), TempValues.Parameter);
M_.params(lParams) = TempValues.Value(iaMparams(iaMparams>0));

TempValues = readtable(sWorkbookCalibration, 'Sheet', 'Structural Parameters','Range','A:C');
[lParams,iaMparams] = ismember(cellstr(M_.param_names), TempValues.Parameter);
M_.params(lParams) = TempValues.Value(iaMparams(iaMparams>0));