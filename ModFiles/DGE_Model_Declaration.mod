
% ====================================
% === Declare Endogenous Variables ===
% ====================================
var 
% contemporaneous equations/variables defined by others
@# if ClimateVarsNational != []
    @# for z in ClimateVarsNational
        @{z} ${@{z}}$ (long_name = '@{z}')
    @# endfor
@# endif
@# if ClimateVarsRegional != []
    @# for reg in 1:Regions
        @# for z in ClimateVarsRegional
            @{z}_@{reg} ${@{z}_{r}}$ (long_name = '@{z}')
        @# endfor
    @# endfor
@# endif
@# for sec in 1:Sectors
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
        P_M_@{subsec} ${P^{M}_s}$ (long_name = 'imports sector price index')
    @# endfor
@# endfor

% === National aggregate variables ===
% actual variables
B $B$ (long_name = 'international traded bonds')
NX $NX$ (long_name = 'net exports')
rf ${r^{f}}$ (long_name = 'foreign interest rate')
G $G$ (long_name = 'government expenditure')
I $I$ (long_name = 'private investment')
Y $Y$ (long_name = 'GDP')
W $W$ (long_name = 'national wage level')
Q_U $Q^{U}$ (long_name = 'domestic used output')
Q_I $Q^{I}$ (long_name = 'demand for intermediate products')
Q $Q$ (long_name = 'total production')
M $M$ (long_name = 'Imports')
X $X$ (long_name = 'Exports')
N $N$ (long_name = 'labour')
C $C$ (long_name = 'consumption')
E $E$ (long_name = 'emissions')
PE $PE$ (long_name = 'emissions price')
LF $LF$ (long_name = 'labour force')
PoP $PoP$ (long_name = 'population')

% === Regional and sectoral variables ===
@# for reg in 1:Regions
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            % Capital rental rates and investment
            rlog_H_@{subsec}_@{reg} ${r_{s,r}}$ (long_name = 'log regional rental rate for sector capital recieved by households')
            r_H_@{subsec}_@{reg} ${r_{s,r}}$ (long_name = 'regional rental rate for sector capital recieved by households')
            r_G_@{subsec}_@{reg} ${r^G_{s,r}}$ (long_name = 'regional rental rate for government sector capital')
            r_F_@{subsec}_@{reg} ${r^F_{s,r}}$ (long_name = 'regional rental rate for sector capital paid by the firm')
            u_K_@{subsec}_@{reg} ${u^K_{s,r}}$ (long_name = 'utilization rate')
            P_K_@{subsec}_@{reg} ${P^K_{s,r}}$ (long_name = 'rental price of installed capital')
            P_INV_@{subsec}_@{reg} ${P^{INV}_{s,r}}$ (long_name = 'purchase price of investment goods')
            phiK_@{subsec}_@{reg} ${\phi^K_{s,r}}$ (long_name = 'price for investment goods')
            I_@{subsec}_@{reg} ${I_{s,r}}$ (long_name = 'regional sector investment')
            I_G_@{subsec}_@{reg} ${I^G_{s,r}}$ (long_name = 'regional public sector investment')
            I_H_@{subsec}_@{reg} ${I^H_{s,r}}$ (long_name = 'regional household sector investment')
            omegaI_@{subsec}_@{reg} ${\omega^I_{s,r}}$ (long_name = 'shadow value of regional private sector investment')
            scrap_@{subsec}_@{reg}  ${\varsigma_{s,r}}$ (long_name = 'capital scrapping when investment hits floor')
            % Damage variables
            D_@{subsec}_@{reg} ${D_{s,r}}$ (long_name = 'regional sector damages')
            D_N_@{subsec}_@{reg} ${D^N_{s,r}}$ (long_name = 'regional sector damages to labour productivity')
            D_K_@{subsec}_@{reg} ${D^K_{s,r}}$ (long_name = 'regional sector destruction of capital stock')
            G_A_@{subsec}_@{reg} ${G^{A}_{s,r}}$ (long_name = 'regional sector adaptation government expenditure')       
            K_A_@{subsec}_@{reg} ${K^{A}_{s,r}}$ (long_name = 'regional sector adaptation capital stock')
            A_@{subsec}_@{reg} ${A_{s,r}}$ (long_name = 'regional sector TFP')
            A_N_@{subsec}_@{reg} ${A^{N}_{s,r}}$ (long_name = 'regional sector labour specific TFP')
            A_K_@{subsec}_@{reg} ${A^{K}_{s,r}}$ (long_name = 'regional sector capital specific TFP')
            A_I_@{subsec}_@{reg} ${A^{I}_{s,r}}$ (long_name = 'regional sector intermediate productivity')
            tauKF_@{subsec}_@{reg} ${\tau^{K,F}_{s,r}}$ (long_name = 'regional sector corporate tax rate on capital')
            tauNF_@{subsec}_@{reg} ${\tau^{N,F}_{s,r}}$ (long_name = 'regional sector labour tax rate on capital')
            tauKH_@{subsec}_@{reg}  ${\tau^{K,H}_{s,r}}$ (long_name = 'regional sector capital income tax rate on capital')
            % Endogenous supply - firms
            mu_@{subsec}_@{reg} ${\mu_{s,r}}$ (long_name = 'regional sector markup')
            P_@{subsec}_@{reg} ${P_{s,r}}$ (long_name = 'regional sector price index')
            p_@{subsec}_@{reg} ${p_{s,r}}$ (long_name = 'regional sector log price index')
            K_@{subsec}_@{reg} ${K_{s,r}}$ (long_name = 'regional sector capital')            
            K_G_@{subsec}_@{reg} ${K^G_{s,r}}$ (long_name = 'regional public owned sector capital')            
            s_G_@{subsec}_@{reg} ${s^G_{s,r}}$ (long_name = 'regional public savings rate sector capital')            
            K_H_@{subsec}_@{reg} ${K^H_{s,r}}$ (long_name = 'regional household owned sector capital')
            slackKH_@{subsec}_@{reg} ${\sigma^{KH}_{s,r}}$ (long_name = 'non-negativity slack for K_H: K_H/PoP = rawK + slackKH, slackKH = smooth_max(-rawK,0)')
            delta_@{subsec}_@{reg} ${\delta^{K}_{s,r}}$ (long_name = 'depreciation rate for capital')
            Y_@{subsec}_@{reg} ${Y_{s,r}}$ (long_name = 'regional sector GDP')
            N_@{subsec}_@{reg} ${N_{s,r}}$ (long_name = 'regional sector employment')
            Q_I_@{subsec}_@{reg} ${Q^{I}_{s,r}}$ (long_name = 'regional sector intermediate inputs')
            P_I_@{subsec}_@{reg} ${P^{I}_{s,r}}$ (long_name = 'regional sector intermediate inputs price index')
            E_@{subsec}_@{reg} ${E_{s,r}}$ (long_name = 'regional emissions associated with output used in sector k')
            E_NOETS_@{subsec}_@{reg} ${E^{NOETS}_{s,r}}$ (long_name = 'regional emissions in subsector and region not covered by ETS')
            kappaE_@{subsec}_@{reg} ${\kappa^{E}_{s,r}}$ (long_name = 'emission factor associated with production in the subsector and region')            
            kappaE_NOETS_@{subsec}_@{reg} ${\kappa^{E,NOETS}_{s,r}}$ (long_name = 'emission factor not covered by ETS in the subsector and region')
            wedgeKE_@{subsec}_@{reg} ${\psi^{KE}_{s,r}}$ (long_name = 'emission-intensity-based interest rate wedge on capital rental for SRI')
            muI_@{subsec}_@{reg} ${\mu^{I}_{s,r}}$ (long_name = 'shadow value of investment constraint in household intertemporal optimization')
            K_FDI_@{subsec}_@{reg} ${K^{FDI}_{s,r}}$ (long_name = 'FDI capital stock in subsector, foreign-owned')
            I_FDI_@{subsec}_@{reg} ${I^{FDI}_{s,r}}$ (long_name = 'FDI investment flow into subsector per period')
            r_FDI_@{subsec}_@{reg} ${r^{FDI}_{s,r}}$ (long_name = 'rental rate on FDI capital, paid to foreign investors')
            @# for secm in 1:Sectors
                A_I_@{subsec}_@{reg}_@{secm} ${A^{I}_{s,r,k}}$ (long_name = 'regional subsector intermediate inputs productivity from aggregate sector k')
                Q_I_@{subsec}_@{reg}_@{secm} ${Q^{I}_{s,r,k}}$ (long_name = 'regional subsector intermediate inputs from aggregate sector k')
                E_I_@{subsec}_@{reg}_@{secm} ${E^I_{s,r,k}}$ (long_name = 'regional emissions associated with inputs used form sector k')
            @# endfor
            X_@{subsec}_@{reg} ${X_{s,r}}$ (long_name = 'sector exports')
            D_X_@{subsec}_@{reg} ${D^{X}_{s,r}}$ (long_name = 'world demand for sector exports')
            Q_@{subsec}_@{reg} ${Q_{s,r}}$ (long_name = 'regional sector Output')
            P_Q_@{subsec}_@{reg} ${P^Q_{s,r}}$ (long_name = 'regional supply sector price index')
            % Endogenous supply - households
            W_@{subsec}_@{reg} ${W_{s,r}}$ (long_name = 'regional wage rate for sector labour')
            % Endogenous demand
            @# for regm in 1:Regions
                Q_D_@{subsec}_@{reg}_@{regm} ${Q^D_{s,r,m}}$ (long_name = 'regional demand for sector Output')
            @# endfor
            A_D_@{subsec}_@{reg} ${A^{D}_{s,r}}$ (long_name = 'regional sector wholesaler productivity')
            Q_D_@{subsec}_@{reg} ${Q^{D}_{s,r}}$ (long_name = 'domestically used sector output')
            P_D_@{subsec}_@{reg} ${P_{s,r}}$ (long_name = 'regional demand sector price index')
            M_I_@{subsec}_@{reg} ${M^I_{s,r}}$ (long_name = 'regional subsectoral imports for intermediates')
            M_F_@{subsec}_@{reg} ${M^F_{s,r}}$ (long_name = 'regional subsectoral imports for final products')
        @# endfor
        % Sectoral aggregates
        Q_A_@{sec}_@{reg} ${Q^{A}_{k,r}}$ (long_name = 'domestically used sector output')
        Q_A_I_@{sec}_@{reg} ${Q^{A,I}_{k,r}}$ (long_name = 'domestically used sector output for intermediates')
        Q_A_F_@{sec}_@{reg} ${Q^{A,F}_{k,r}}$ (long_name = 'domestically used sector output for final use')
        A_F_@{sec}_@{reg} ${A^{F}_{k,r}}$ (long_name = 'sector productivity for final use')
        P_A_@{sec}_@{reg} ${P^{A}_{k,r}}$ (long_name = 'price index for domestically used sector output')
        M_A_F_@{sec}_@{reg} ${Q^{A,M^F}_{k,r}}$ (long_name = 'domestically used sector output for final use')
        P_M_A_@{sec}_@{reg} ${P^{A,M}_{k,r}}$ (long_name = 'price index for domestically used sector output')
    @# endfor
    Q_U_@{reg} ${Q^{U}_{r}}$ (long_name = 'regionally used products')
    I_@{reg} ${I_{r}}$ (long_name = 'regional investments')
    W_@{reg} ${W_{r}}$ (long_name = 'regional wage level')
    G_@{reg} ${G_{r}}$ (long_name = 'regional government expenditure')
    BG_@{reg} ${B^G_{r}}$ (long_name = 'government debt')
    tauC_@{reg}  ${\tau^{C}_{r}}$ (long_name = 'consumption tax')
    tauH_@{reg}  ${\tau^{H}_{r}}$ (long_name = 'tax on housing')
    tauNH_@{reg} ${\tau^{N,H}_{r}}$ (long_name = 'labour tax')
    G_A_DH_@{reg} ${G^{A,D^H}_{r}}$ (long_name = 'adaptation government expenditure for housing')       
    KG_@{reg} ${K^G_{r}}$ (long_name = 'public good capital stock')
    I_G_@{reg} ${I^G_{r}}$ (long_name = 'public investment and adaptation expenditure')
    P_@{reg} ${P_{r}}$ (long_name = 'regional price level')
    P_F_@{reg} ${P^F_{r}}$ (long_name = 'regional imported price level')
    P_Q_@{reg} ${P^Q_{r}}$ (long_name = 'regional produced price level')
    P_D_@{reg} ${P^D_{r}}$ (long_name = 'regional used price level')
    E_@{reg} ${E_r}$ (long_name = 'regional emissions')
    E_NOETS_@{reg} ${E^{NOETS}_r}$ (long_name = 'regional emissions not covered by ETS')
    E_ETS_@{reg} ${E^{ETS}_r}$ (long_name = 'regional emissions covered by ETS')
    EE_@{reg} ${EE_r}$ (long_name = 'regional energy efficiency')
    tauCEndo_@{reg} ${\tau^{C,Endo}_{r}}$ (long_name = 'endogenous consumption tax (floats in Baseline to hit G/Y target)')
    M_@{reg} ${M_{r}}$ (long_name = 'regional imports')
    B_@{reg} ${B_r}$ (long_name = 'international traded bonds')
    lambda_@{reg} $\lambda_r$ (long_name = 'budget constraint lagrange multiplier')
    H_@{reg} ${H_r}$ (long_name = 'houses')
    PH_@{reg} ${P^H_r}$ (long_name = 'prices for houses')
    DH_@{reg} ${D^H_r}$ (long_name = 'damages to the housing stock')
    omegaH_@{reg} ${\omega^H_r}$ (long_name = 'Lagrange multiplier for the law of motion of houses')
    PoP_@{reg} ${PoP_r}$ (long_name = 'population')
    LF_@{reg} ${LF_r}$ (long_name = 'labour force')
    IH_@{reg} ${I^H_r}$ (long_name = 'investment in houses')
    N_@{reg} ${N_r}$ (long_name = 'aggregate regional labour')
    Y_@{reg} ${Y_r}$ (long_name = 'aggregate regional value added')
    X_@{reg} ${X_r}$ (long_name = 'regional exports')
    Q_@{reg} ${Q^S_r}$ (long_name = 'regional output supplied')
    Q_I_@{reg} ${Q^I_r}$ (long_name = 'regional intermediate input demand')
    C_@{reg} ${C_r}$ (long_name = 'consumption')
    M_F_@{reg} ${M^F_r}$ (long_name = 'imports for final demand')
    NX_@{reg} ${NX_r}$ (long_name = 'net exports to the rest of the world')
    Tr_@{reg} ${Tr_r}$ (long_name = 'transfers')
    tauS_@{reg}  ${\tau^{S}_{r}}$ (long_name = 'firm subsidies')
    PE_@{reg} ${P^E_r}$ (long_name = 'price for emissions')
    s_@{reg} ${s_r}$ (long_name = 'change in exchange rate to the rest of the world')
    adjB_@{reg} $a^B_r$ (long_name = 'region specific adjsutment cost shock to foreign bond holdings')
    deltaB_@{reg} ${\delta^{B}_r}$ (long_name = 'depreciation rate of foreign assets')
    // Policy Variables to implement different scenarios
    I_PV_@{reg} ${I^PV_r}$ (long_name = 'regional RTS PV investment')
    K_PV_@{reg} ${I^PV_r}$ (long_name = 'regional RTS PV capital stock')
    Q_PV_@{reg} ${Q^PV_r}$ (long_name = 'regional RTS PV production stock')

    % Inter-regional trade (if multiple regions)
    @# if  Regions > 0
        @# for regm in 1:Regions
            NX_@{reg}_@{regm} ${NX_{r,m}}$ (long_name = 'net exports of region $r$toregion $m$')
            B_@{reg}_@{regm} ${B_{r,m}}$ (long_name = 'net asset position of region $r$ to region $m$')
        @# endfor
    @# endif
@# endfor
;
% ====================================
% === Declare Exogenous Variables ===
% ====================================
varexo 
exo_rf ${\eta^{r^f}}$ (long_name = 'exogenous world interest rate')
exo_beta ${\eta^{\beta}}$ (long_name = 'exogenous discount factor')

@# for sec in 1:Sectors
    exo_A_F_@{sec}_@{reg} ${\eta^{A^F,k,r}}$ (long_name = 'exogenous final productivity')
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
        exo_M_@{subsec} ${\eta^{M,k}}$ (long_name = 'exogenous price development of sector imports')
        exo_lMAmount_@{subsec} ${\ell^{M,Amount,k}}$ (long_name = 'switch: 1=temporary import amount shock, 0=import price shock')
        exo_MAmt_@{subsec} ${\eta^{M,Amount,k}}$ (long_name = 'temporary import amount shock as log growth relative to previous value')
        @# for reg in 1:Regions
            exo_X_@{subsec}_@{reg} ${\eta^{X,s,r}}$ (long_name = 'exogenous demand for sector exports')
            exo_beta_@{subsec}_@{reg} ${\eta^{beta,s,r}}$ (long_name = 'exogenous discount shock')
            exo_I_@{subsec}_@{reg} ${\eta^{I,s,r}}$ (long_name = 'exogenous investment growth')
            exo_K_G_@{subsec}_@{reg} ${\eta^{K^G,s,r}}$ (long_name = 'exogenous public capital stock for sector, log multiplier')
            exo_phiG_@{subsec}_@{reg} ${\eta^{\phi^{G},s,r}}$ (long_name = 'exogenous public capital share for sector, log multiplier')
            exo_r_G_@{subsec}_@{reg} ${\eta^{r^G,s,r}}$ (long_name = 'exogenous government rental rate for sector')
            exo_r_FDI_@{subsec}_@{reg} ${\eta^{r^{FDI},s,r}}$ (long_name = 'exogenous deviation of FDI rental rate from rf0')
            exo_I_FDI_@{subsec}_@{reg} ${\eta^{I^{FDI},s,r}}$ (long_name = 'exogenous FDI investment to initial GDP ratio')
            exo_lIGShare_@{subsec}_@{reg} ${\ell^{IG,s,r}}$ (long_name = 'switch: 0=absolute K_G formula, 1=I_G/I share mode')
            exo_sIGShare_@{subsec}_@{reg} ${\eta^{s^{IG},s,r}}$ (long_name = 'I_G/I target share in [0,1] — used when exo_lIGShare=1')
            exo_lFDIShare_@{subsec}_@{reg} ${\ell^{FDI,s,r}}$ (long_name = 'switch: 0=K_FDI zero or K-target (existing), 1=K_FDI/K share mode')
            exo_sFDIShare_@{subsec}_@{reg} ${\eta^{s^{FDI},s,r}}$ (long_name = 'additive deviation to baseline K_FDI/K share — used when exo_lFDIShare=1')
            exo_s_G_@{subsec}_@{reg} ${\eta^{s^G,s,r}}$ (long_name = 'exogenous government saving rate')
            exo_s_GScen_@{subsec}_@{reg} ${\eta^{s^{G,Scen},s,r}}$ (long_name = 'exogenous government scenario saving rate')
            exo_@{subsec}_@{reg} ${\eta^{A,s,r}}$ (long_name = 'exogenous TFP')
            exo_u_K_@{subsec}_@{reg} ${\eta^{u^K,s,r}}$ (long_name = 'exogenous capital utilization rate')
            exo_A_@{subsec}_@{reg} ${\eta^{A,s,r}}$ (long_name = 'exogenous TFP')
            exo_N_@{subsec}_@{reg} ${\eta^{A^{N},k,r}}$ (long_name = 'exogenous labour specific TFP')
            exo_K_@{subsec}_@{reg} ${\eta^{A^{K},k,r}}$ (long_name = 'exogenous capital specific TFP')
            exo_KTarget_@{subsec}_@{reg} ${\eta^{K^{target,Binary},k,r}}$ (long_name = 'exogenous capital target binary according to plan')
            exo_KTargetB_@{subsec}_@{reg} ${\eta^{K^{target},k,r}}$ (long_name = 'exogenous capital target according to plan')
            exo_kappaE_@{subsec}_@{reg} ${\eta^{\kappa^{E},s,r}}$ (long_name = 'exogenous emission intensity of the respective sector and region')
            exo_kappaE_NOETS_@{subsec}_@{reg} ${\eta^{\kappa^{E,No ETS},s,r}}$ (long_name = 'exogenous emission intensity outside ETS of the respective sector and region')
            exo_lE_NOETS_Target_@{subsec}_@{reg} ${\ell^{E^{NOETS},s,r}}$ (long_name = 'switch: 0=use exo_kappaE_NOETS, 1=set kappaE_NOETS to match exo_E_NOETS emissions path when output is endogenous')
            exo_E_NOETS_@{subsec}_@{reg} ${\eta^{E^{NOETS},s,r}}$ (long_name = 'exogenous emission intensity not covered by ETS of the respective sector and region')
            exo_E_@{subsec}_@{reg} ${\eta^{E,s,r}}$ (long_name = 'exogenous emission of the respective sector and region')
            exo_A_I_@{subsec}_@{reg} ${\eta^{A^{I},k,r}}$ (long_name = 'exogenous intermediate specific productivity')
            exo_A_D_@{subsec}_@{reg} ${\eta^{A^{D},k,r}}$ (long_name = 'exogenous efficiency specific productivity')
            exo_QI_@{subsec}_@{reg} ${\eta^{Q^{I},k,r}}$ (long_name = 'exogenous intermediate share')
            exo_D_@{subsec}_@{reg} ${\eta^{D,k,r}}$ (long_name = 'exogenous damage induced by climate change for the sector')
            exo_D_N_@{subsec}_@{reg} ${\eta^{D^{N},k,r}}$ (long_name = 'exogenous damage induced by climate change for labour productivity in the sector')
            exo_D_K_@{subsec}_@{reg} ${\eta^{D^{K},k,r}}$ (long_name = 'exogenous damage induced by climate change for capital productivity in the sector')
            exo_Q_@{subsec}_@{reg} ${\eta^{E,s,r}}$ (long_name = 'exogenous share of emissions not part of ETS')
            exo_P_K_@{subsec}_@{reg} ${\eta^{P^k,s,r}}$ (long_name = 'exogenous price of capital goods')
            exo_targetIY_@{subsec}_@{reg} ${\eta^{IY,s,r}}$ (long_name = 'investment-to-GDP target deviation from SS (additive, read from Excel)')
            exo_muI_@{subsec}_@{reg} ${\eta^{\mu^{I},s,r}}$ (long_name = 'shadow value of investment constraint path from baseline (set programmatically in scenarios)')
            exo_ltargetIY_@{subsec}_@{reg} ${\ell^{IY}_{s,r}}$ (long_name = 'binary: 1=endogenous wedge targets I/Y in baseline, 0=exogenous wedge (always 0 at SS)')
            exo_lAddEE_@{subsec}_@{reg} ${\ell^{EE}_{s,r}}$ (long_name = 'switch: 1=exo_EE_r additive to sector EE gains, 0=PV/VNEEP3 sole EE driver (exo_EE_r suppressed for this subsector)')
            exo_phiK_@{subsec}_@{reg} ${\eta^{\phi^{K},{s,r}}}$ (long_name = 'exogenous investment adjustment cost')
            exo_tauKF_@{subsec}_@{reg} ${\eta^{\tau^{K,F},k,r}}$ (long_name = 'exogenous sector and region corporate tax rate')
            exo_wedgeKE_@{subsec}_@{reg} ${\eta^{\psi^{KE},s,r}}$ (long_name = 'exogenous emission-intensity interest rate wedge on capital (SRI)')
            exo_tauKH_@{subsec}_@{reg} ${\eta^{\tau^{K,H},k,r}}$ (long_name = 'exogenous sector and region capital income tax rate')
            exo_tauNF_@{subsec}_@{reg} ${\eta^{\tau^{N},k,r}}$ (long_name = 'exogenous sector and region labour tax rate')
            exo_mu_@{subsec}_@{reg} ${\eta^{\mu^{N},k,r}}$ (long_name = 'exogenous mark-up')
            @# if ClimateVarsRegional != []
                @# for z in ClimateVarsRegional
                    exo_GA_@{subsec}_@{reg} ${\eta^{G^{A,@{z}},k,r}}$ (long_name = 'exogenous sector adaptation expenditure against @{z}')
                @# endfor
            @# endif            
            @# for secm in 1:Sectors
                exo_EI_@{subsec}_@{reg}_@{secm} ${\eta^{E^{I},s,k,r}}$ (long_name = 'exogenous emissions caused by using intermediate products in subsector s from sector k')
                exo_AI_@{subsec}_@{reg}_@{secm} ${\eta^{A^{I},s,k,r}}$ (long_name = 'exogenous productivity for intermediate products in subsector s from sector k')
            @# endfor
        @# endfor
    @# endfor
@# endfor
exo_G_A_DH ${\eta^{G^{A,H}}}$ (long_name = 'exogenous sector adaptation expenditure for housing')
@# if ClimateVarsRegional != []
    @# for z in ClimateVarsNational
        exo_@{z} ${\eta^{@{z},n}}$ (long_name = 'exogenous @{z}')
    @# endfor
@# endif
exo_CapTradeInternat ${\eta^{Cap and Trade International}}$ (long_name = 'exogenous indicator wether there is a Cap and trade international')
exo_E ${\eta^{E}}$ (long_name = 'exogenous emissions')
exo_PE ${\eta^{P^E}}$ (long_name = 'exogenous emission price')
@# for reg in 1:Regions
    exo_tauS_@{reg} ${\eta^{\tau^{S}}_r}$ (long_name = 'exogenous subsidy share of revenues from ETS')
    exo_tauSTr_@{reg} ${\eta^{\tau^{S,Tr}}_r}$ (long_name = 'exogenous subsidy share of revenues for transfers')
    exo_E_@{reg} ${\eta^{E}_r}$ (long_name = 'exogenous emissions')
    exo_EE_@{reg} ${\eta^{EE}_r}$ (long_name = 'exogenous energy efficiency')
    exo_EBase_@{reg} ${\eta^{E,Base}_r}$ (long_name = 'exogenous emissions in Baseline Scenario')
    exo_PE_@{reg} ${\eta^{P^E}_r}$ (long_name = 'exogenous emission price')
    exo_CapTrade_@{reg} ${\eta^{CapTrade}_r}$ (long_name = 'exogenous indicator wehter there is a Cap and trade or a emission price')
    @# for z in ClimateVarsRegional
        exo_@{z}_@{reg} ${\eta^{@{z},n}}$ (long_name = 'exogenous regional @{z}')
    @# endfor
    exo_LF_@{reg} ${\eta^{LF}_{r}}$ (long_name = 'exogenous change in the labour force')
    exo_NLF_@{reg} ${\eta^{NLF}_{r}}$ (long_name = 'exogenous change in the population outside of the labour force')
    exo_P_D_@{reg} ${\eta^{P^D}_{r}}$ (long_name = 'exogenous price level')
    exo_H_@{reg} ${\eta^{H}_r}$ (long_name = 'exogeneous housing area to population ratio')
    exo_DH_@{reg} ${\eta^{D^{H}}_r}$ (long_name = 'exogeneous damage to housing stock')
    exo_tauC_@{reg} ${\eta^{\tau^C_{r}}}$ (long_name = 'exogeneous consumption tax (baseline-required path, set programmatically in scenarios)')
    exo_tauCScen_@{reg} ${\eta^{\tau^{C,Scen}_{r}}}$ (long_name = 'scenario-specific additional consumption tax shock, layered on top of exo_tauC_@{reg}')
    exo_tauH_@{reg} ${\eta^{\tau^H_{r}}}$ (long_name = 'exogeneous housing tax')
    exo_tauNH_@{reg} ${\eta^{\tau^{N,H}_{r}}}$ (long_name = 'exogeneous labour income tax paid by households')
    exo_BG_@{reg} ${\eta^{BG}_{r}}$ (long_name = 'exogenous structural balance')
    exo_phi_BG_ext_@{reg} ${\eta^{\phi^{BG,ext}}_{r}}$ (long_name = 'exogenous shock to share of public debt held externally')
    exo_Tr_@{reg} ${\eta^{Tr}_r}$ (long_name = 'exogeneous transfer payments')
    exo_NXL_@{reg} ${\eta^{NX}_r}$ (long_name = 'logical exogenous variable to set net exports to GDP ratio')
    exo_BL_@{reg} ${\eta^{B}_r}$ (long_name = 'logical exogenous variable to set foreign asset position relative to GDP')
    exo_NX_@{reg} ${\eta^{NX}_r}$ (long_name = 'exogenous net exports to GDP ratio')
    exo_lNXTarget_@{reg} ${\ell^{NX,s}_r}$ (long_name = 'switch: 0=s_@{reg} follows its AR(1) path (pre-defined), 1=s_@{reg} solved so net exports to GDP ratio matches NX0_p/Y0_p (Baseline)')
    exo_targetGY_@{reg} ${\eta^{GY,r}}$ (long_name = 'deviation from initial government-consumption-to-GDP ratio (additive, read from Excel; active in Baseline)')
    exo_B_@{reg} ${\eta^{B}_r}$ (long_name = 'exogenous net foreign asset position')
    exo_deltaB_@{reg} ${\eta^{\delta^B}_r}$ (long_name = 'exogenous depreciation rate on net foreign asset position')
    exo_adjB_@{reg} ${\eta^{adj^B}_r}$ (long_name = 'exogenous adjustment cost')
    exo_s_@{reg} ${\eta^{s}_r}$ (long_name = 'exogenous change in net foreign asset position')
    exo_PV_@{reg} ${\eta^{PV}_r}$ (long_name = 'exogenous PV investment')
    exo_PVEff_@{reg} ${\eta^{PV,Eff}_r}$ (long_name = 'exogenous PV Efficiency shock')
@# endfor
;
% ==========================
% === Declare Parameters ===
% ==========================
parameters 
% =======================
% === meta parameters ===
% =======================
inbsectors_p  ${K}$ (long_name = 'number of sectors')
inbsubsectors_p  ${S}$ (long_name = 'number of subsectors')
inbregions_p  ${R}$ (long_name = 'number of regions')
iSubsecFossil_p ${s^{Fossil}}$ (long_names = 'integer for fossil')
iSubsecRE_p ${s^{RE}}$ (long_names = 'integer for RE')
iSecEnergy_p ${s^{Energy}}$ (long_names = 'integer for fossil')
iSecHouse_p ${k^{Housing}}$ (long_names = 'integer for housing sector')
lEndogenousY_p ${l^{Y}}$ (long_name = 'logical indicator for endogenous or exogenous production')
lEndogenousN_p ${l^{N}}$ (long_name = 'logical indicator for endogenous or exogenous employment')
lTargetY_p ${l^{Y,target}}$ (long_name = 'logical indicator for target on Y or Q in Baseline')
lExoNX_p ${l^{NX}}$ (long_name = 'logical indicator for exogenous net exports')
lCalibration_p  ${l^{Calib}}$ (long_name = 'logical indicator whether model is calibrated or not')
lCapandTrade_p  ${l^{CapandTrade}}$ (long_name = 'logical indicator whether cap and trade or exogenous emissions prices')
lCapGoodsSecPrice_p  ${l^{P_K,Q}}$ (long_name = 'flag: 1=P_K base from CapGoodsSubsec output price P_Q, 0=own sector value-added price')
iCapGoodsSubsec_p  ${s^{capgoods}}$ (long_name = 'subsector index used for capital goods base price when lCapGoodsSecPrice_p=1')
lEndoMig_p  ${l^{Endogenous Migration}}$ (long_name = 'logical indicator whether migration is endogenous or not')
TAdjLF_p ${T^{adjustment}}$ (long_name = 'adjustment time of labour supply to change in wage differentials')
etaLF_p ${\eta^{LF}}$ (long_name = 'elasticity of labour force to wage differentials')
h_p ${h}$ (long_name = 'habit persistence')
deltaPV_p ${\delta^{PV}}$ (long_name = 'depreciation rate of PV')
phiPV_p ${\phi^{PV}}$ (long_name = 'scaling factor for PV production')
phiKPV0_p ${\phi^{K^PV}}$ (long_name = 'initial installed value of PV capital')
phiQPV0_p ${\phi^{Q_0^PV}}$ (long_name = 'initial share of PV on final energy')
phiKPE_p ${\phi^{K,P^E}}$ (long_name = 'elasticity of adjustment cost to emission price')
gamPEdel_p ${\gamma^{\delta,P^E}}$ (long_name = 'elasticity of depreciation rate to prices')
rhophiK_p ${\rho^{\phi^{K,P^E}}}$ (long_name = 'persistency of adjustment cost curvature')
@# for sec in 1:Sectors
    substart_@{sec}_p
    subend_@{sec}_p
@# endfor
% ========================
% === model parameters ===
% ========================
@# for sec in 1:Sectors
    etaQA_@{sec}_p ${\eta^{Q^A}_{k}}$ (long_name = 'elasticity of substitution between products from different subsectors in one sector')
    @# for reg in 1:Regions
        omegaQA_@{sec}_@{reg}_p ${\omega^{Q^A}_{k}}$ (long_name = 'distribution parameter for aggregate output from one sector')
        omegaMA_F_@{sec}_@{reg}_p ${\omega^{M,A}_{k,r}}$ (long_name = 'distribution parameter for final demand imports from one sector')
    @# endfor
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
        P_M_@{subsec}_p ${P^{M}_{s}}$ (long_name = 'long-run price of sector imports')
        M0_@{subsec}_p ${M^{0}_{s}}$ (long_name = 'long-run price of sector imports')
        etaQ_@{subsec}_p ${\eta^{Q}_{s}}$ (long_name = 'elasticity of substitution between regional production')
        etaI_@{subsec}_p ${\eta^{I}_{s}}$ (long_name = 'elasticity of substitution between value added and intermediate products')
        etaIA_@{subsec}_p ${\eta^{I,A}_{s}}$ (long_name = 'elasticity of substitution between intermediate products from different sectors')
        iHomeBias_@{subsec}_p ${\iota^{Home}_{s}}$ (long_name = 'Home bias in subsector')
        @# for reg in 1:Regions
            phiM_I_@{subsec}_@{reg}_p $\frac{M_{s,r,0} \, P^{M}_{k,r,0}}{P_{0} \, Q_{0}}$ (long_name = 'share of sector imports on total output for intermediates')
            phiM_F_@{subsec}_@{reg}_p $\frac{M_{s,r,0} \, P^{M}_{k,r,0}}{P_{0} \, Q_{0}}$ (long_name = 'share of sector imports on total output for final products')
            phiQI_@{subsec}_@{reg}_p $\frac{Q^{I}_{s,0} \, P_{0}}{P_{k,0} \, Q_{k,0}}$ (long_name = 'share of intermediate inputs on total production')
            phiY0_@{subsec}_@{reg}_p $\frac{P_{s,r,0} \, Y_{s,r,0}}{P_{0} \, Y_{0}}$ (long_name = 'initial share of regional and sectoral output')
            phiX_@{subsec}_@{reg}_p $\frac{X_{s,r,0} \, P_{s,r,0}}{P_{s,r,0} \, Y_{s,r,0}}$ (long_name = 'share of exports on gross value added')
            phiK_@{subsec}_@{reg}_p ${\phi^{K}_{s,r}}$ (long_name = 'coefficient of investment adjustment cost')
            delta_@{subsec}_@{reg}_p ${\delta^{K}_{s,r}}$ (long_name = 'depreciation rate for capital')
            s_G_@{subsec}_@{reg}_p ${s^{G}_{s,r}}$ (long_name = 'initial savings rate for public sector investment')
            sFDI0_@{subsec}_@{reg}_p ${s^{FDI,0}_{s,r}}$ (long_name = 'baseline share of foreign-owned capital in total capital')
            phiFDI0_@{subsec}_@{reg}_p ${\phi^{FDI,0}_{s,r}}$ (long_name = 'baseline share of foreign-owned capital in total initial GDP')
            D_X_@{subsec}_@{reg}_p ${D^{X}_{s,r}}$ (long_name = 'long-run demand for exports')
            lEndoQ_@{subsec}_@{reg}_p ${l^{Q}_{s,r}}$ (long_name = 'logical indicator whether output is endogenous or not')
            lEndoN_@{subsec}_@{reg}_p ${l^{N}_{s,r}}$ (long_name = 'logical indicator whether employment is endogenous or not')
            kappaE_@{subsec}_@{reg}_p ${\kappa^{E}_{s,r}}$ (long_name = 'emission factor associated with production in the subsector and region')
            kappaE_NOETS_@{subsec}_@{reg}_p ${\kappa^{E,NOETS}_{s,r}}$ (long_name = 'emission factor not covered by ETS in the subsector and region')
            sE_@{subsec}_@{reg}_p ${\frac{E_{s,r}}{E_0}}$ (long_name = 'share of emissions associated with using the input factor in the subsector and region')
            sE_NOETS_@{subsec}_@{reg}_p ${\frac{E^{NOETS}_{s,r}}{E^{NOETS}_0}}$ (long_name = 'share of non-ETS emissions attributed to subsector and region')
            tauKF_@{subsec}_@{reg}_p ${\tau^{K,F}_{s,r}}$ (long_name = 'region and sector-specific tax rate on capital paid by firms')
            tauKH_@{subsec}_@{reg}_p ${\tau^{K,H}_{s,r}}$ (long_name = 'region and sector-specific tax rate on capital income by HHs')
            tauNF_@{subsec}_@{reg}_p ${\tau^{N,F}_{s,r}}$ (long_name = 'region and sector-specific tax rate on labour paid by firms')
            phiY_@{subsec}_@{reg}_p $\frac{P_{s,r,0} \, Y_{s,r,0}}{P_{0} \, Y_{0}}$ (long_name = 'share of regional and sectoral output')
            phiYT_@{subsec}_@{reg}_p $\frac{P_{s,r,T} \, Y_{s,r,T}}{P_{T} \, Y_{T}}$ (long_name = 'terminal share of regional and sectoral output')
            Q0_@{subsec}_@{reg}_p ${Q_{s,r,0}}$ (long_name = 'initial emissions')            
            Q_I0_@{subsec}_@{reg}_p ${Q^I_{s,r,0}}$ (long_name = 'initial emissions')            
            I0_G_@{subsec}_@{reg}_p ${I^G_{s,r,0}}$ (long_name = 'initial shre of public investment')            
            P0_Q_@{subsec}_@{reg}_p ${P^Q_{s,r,0}}$ (long_name = 'initial guess for regional supply sector price index')
            P0_@{subsec}_@{reg}_p ${P_{s,r,0}}$ (long_name = 'initial guess for sector and region value added price index')
            Y0_@{subsec}_@{reg}_p ${Y_{s,r,0}}$ (long_name = 'initial guess for sector and region value added stock')
            K0_@{subsec}_@{reg}_p ${K_{s,r,0}}$ (long_name = 'initial guess for sector and region capital stock')
            A0_@{subsec}_@{reg}_p ${A_{s,r,0}}$ (long_name = 'initial guess for regional tfp')
            phiN_@{subsec}_@{reg}_p ${N_{s,r,0}}$ (long_name = 'long-run share of regional and sectoral employment')
            phiNT_@{subsec}_@{reg}_p ${N_{s,r,T}}$ (long_name = 'terminal share of regional and sectoral employment')
            phiN0_@{subsec}_@{reg}_p ${N_{s,r,0}}$ (long_name = 'initial share of regional and sectoral employment')
            phiW_@{subsec}_@{reg}_p $\frac{W_{s,r,0} \, N_{s,r,0}}{P_{s,r,0} \, Y_{s,r,0}}$ (long_name = 'share of regional and sectoral employment')
            phiL_@{subsec}_@{reg}_p ${\phi^{L}_{s,r}}$ (long_name = 'coefficient of disutility to work')
            phiG_@{subsec}_@{reg}_p ${\phi^{G}_{s,r}}$ (long_name = 'share of government owned capital')
            sKGmax_@{subsec}_@{reg}_p ${s^{KG,max}_{s,r}}$ (long_name = 'ceiling on K_G/K(-1) — crowding-out backstop, not a policy target')
            @# for regm in 1:Regions
                omegaQ_@{subsec}_@{reg}_@{regm}_p ${\omega^{Q}_{s,r,m}}$ (long_name = 'distribution parameter for regional production')
                phiQ_D_@{subsec}_@{reg}_@{regm}_p ${\phi^{Q}_{s,r,m}}$ (long_name = 'share of production used in region regm and produced in region reg')
            @# endfor
            omegaQI_@{subsec}_@{reg}_p ${\omega^{Q^{I}}_{s,r}}$ (long_name = 'distribution parameter for intermediate products')
            @# for secm in 1:Sectors
                omegaQI_@{subsec}_@{reg}_@{secm}_p ${\omega^{Q}_{s,r,k}}$ (long_name = 'distribution parameter for intermediate products from different sectors')
                phiQI_@{subsec}_@{reg}_@{secm}_p ${\phi^{Q}_{s,r,k}}$ (long_name = 'share of expenditures for intermediate products')
                kappaEI_@{subsec}_@{reg}_@{secm}_p ${\kappa^{E,I}_{s,r,k}}$ (long_name = 'emission factor associated with using the input factor in the subsector and region')
                sEI_@{subsec}_@{reg}_@{secm}_p ${\frac{E^{I}_{s,r,k}}{E_0}}$ (long_name = 'share of emissions associated with using the input factor in the subsector and region')
            @# endfor            
            alphaK_@{subsec}_@{reg}_p ${\alpha^{K}_{s,r}}$ (long_name = 'distribution parameter capital share')
            alphaN_@{subsec}_@{reg}_p ${\alpha^{N}_{s,r}}$ (long_name = 'distribution parameter labour share')
            etaNK_@{subsec}_@{reg}_p ${\eta^{N,K}_{s,r}}$ (long_name = 'elasticity of substitution between labour and capital')
            A_@{subsec}_@{reg}_p ${A_{s,r}}$ (long_name = 'sector long-run TFP')
            @# if ClimateVarsNational != []
                deltaKA_@{subsec}_@{reg}_p ${\delta^{K^{A}_{s,r}}}$ (long_name = 'depreciation rate of adaptation capital stock against @{z}')
            @# endif
            gY0_@{subsec}_@{reg}_p ${\frac{Y_{2,k,r}}{Y_{1,k,r}}}$ (long_name = 'initial sector growth')
            gN0_@{subsec}_@{reg}_p ${\frac{\frac{N_{2,k,r}}{N_{2}}}{\frac{N_{1,k,r}}{N_{1}}}}$ (long_name = 'initial sector labour growth')
            omegaM_@{subsec}_@{reg}_p ${\omega^{M}_{s,r}}$ (long_name = 'distribution parameter for imports from one sector')
            omegaM_F_@{subsec}_@{reg}_p ${\omega^{M,F}_{s,r}}$ (long_name = 'distribution parameter for imports from one sector')
            omegaQ_@{subsec}_@{reg}_p ${\omega^{Q}_{s,r}}$ (long_name = 'distribution parameter for output from one sector')
            omegaA_@{subsec}_@{reg}_p ${\omega^{A}_{s,r}}$ (long_name = 'exponent for productivity growth')
            // coefficients for damage functions to TFP
            A_N_@{subsec}_@{reg}_p ${A^{N}_{s,r}}$ (long_name = 'sector labour specific TFP')
            A_K_@{subsec}_@{reg}_p ${A^{K}_{s,r}}$ (long_name = 'sector capital specific TFP')
        @# endfor
    @# endfor
@# endfor
beta_p ${\beta}$ (long_name = 'discount factor')
omegaP_p ${\omega^{P}}$ (long_name = 'share of rational agents')
delta_p ${\delta}$ (long_name = 'capital depreciation rate')
deltaB_p ${\delta^B}$ (long_name = 'foreign assets depreciation rate')
phiadjB_p ${\phi^{adj^B}}$ (long_name = 'adjustment cost parameter to foreign assets')
deltaH_p ${\delta^H}$ (long_name = 'housing depreciation rate')
deltaKG_p ${\delta^{K^{G}}}$ (long_name = 'public capital depreciation rate')
phiG_p ${\phi^{G}}$ (long_name = 'elasticity of TFP to public capital')
sigmaL_p ${\sigma^{L}}$ (long_name = 'inverse Frisch elasticity')
sigmaC_p ${\sigma^{C}}$ (long_name = 'intertemporal elasticity of substitution')
sigmaU_p ${\sigma^{U}}$ (long_name = 'utilization elasticity of depreciation (endogenous utilization)')
etaKS_p ${\eta^{KS}}$ (long_name = 'capital goods supply elasticity (lCapPrice = 1; large = flat supply)')
etaQ_p ${\eta^{Q}}$ (long_name = 'elasticity of substitution between sectoral production')
etaM_p ${\eta^{M}}$ (long_name = 'elasticity of substitution between sectoral imports')
etaF_p ${\eta^{F}}$ (long_name = 'elasticity of substitution between foreign and domestic products')
phiY_p ${\frac{Y}{Q}}$ (long_name = 'share GDP to Output')
phiB_p ${\phi^{B}}$ (long_name = 'coefficient of foreign adjustment cost')
etaX_p   ${\eta^{X}}$ (long_name = 'export price elasticity')
rhos_p  ${\rho^{s}}$ (long_name = 'persistence in exchange rate valuation shocks to net foreign asset position')
omegaNX_p  ${\omega^{NX}}$ (long_name = 'share of net exports relative to domestic GDP')
omegaNX0_p  ${\omega^{NX,0}}$ (long_name = 'initial share of net exports relative to domestic GDP')
omegaNXT_p  ${\omega^{NX,T}}$ (long_name = 'terminal share of net exports relative to domestic GDP')
@# for reg in 1:Regions
    tauC_@{reg}_p  ${\tau^{C}_{r,0}}$ (long_name = 'consumption tax')
    sGY0_@{reg}_p ${sGY^0_r}$ (long_name = 'actual government-consumption-to-GDP share from national accounts data; G_@{reg} is pinned to this target and tauC_@{reg}_p is back-solved from the government budget constraint at the calibration stage')
    s0_@{reg}_p  ${s_{r,0}}$ (long_name = 'initial exchange rate inflation')
    tauH_@{reg}_p  ${\tau^{H}_{r,0}}$ (long_name = 'tax on housing')
    tauNH_@{reg}_p ${\tau^{N,H}_{r,0}}$ (long_name = 'labour tax')
    sH_@{reg}_p ${s_{r,0}^H}$ (long_name = 'share for housing investments')
    N0_@{reg}_p ${N_{r,0}}$ (long_name = 'initial regional employment')
    LF0_@{reg}_p ${LF_{r,0}}$ (long_name = 'initial labour force share')
    omegaLF0_@{reg}_p ${\omega^{LF}_{r,0}}$ (long_name = 'initial labour force preference')
    omegaF_@{reg}_p ${\omega^{F}_{r}}$ (long_name = 'foreign product share')
    P0_MR_@{reg}_p ${P^M_{r,0}}$ (long_name = 'initial price level')
    P0_D_@{reg}_p ${P_0}$ (long_name = 'initial price level')
    Tr0_@{reg}_p ${Tr_0}$ (long_name = 'initial transfer payments')
    BG0_@{reg}_p ${BG^0_r}$ (long_name = 'initial public debt to GDP ratio')
    phi_BG_ext_@{reg}_p ${\phi^{BG,ext}_r}$ (long_name = 'share of public debt held externally')
    NX0_@{reg}_p ${NX_0}$ (long_name = 'initial net export to value-added ratio')
    GY0_@{reg}_p ${GY^0_r}$ (long_name = 'initial government-consumption-to-GDP ratio')
    Y0_@{reg}_p ${Y_{r,0}}$ (long_name = 'initial regional GDP / value added, used with NX0_@{reg}_p as the net-export target ratio')
    gamma_@{reg}_p ${\gamma_r}$ (long_name = 'preferences for housing in utility function in each region')
    PoP0_@{reg}_p ${PoP_{r,0}}$ (long_name = 'initial population')
    H0_@{reg}_p ${H_{r,0}}$ (long_name = 'initial stocks of houses')
    PH0_@{reg}_p ${P^H_{r,0}}$ (long_name = 'initial price of houses')
    PE0_@{reg}_p ${P^E_{r,0}}$ (long_name = 'initial emission price')
    E0_@{reg}_p ${E_{r,0}}$ (long_name = 'initial emissions')
    RE0_@{reg}_p ${RE_{r,0}}$ (long_name = 'initial RE share')
    E0_NOETS_@{reg}_p ${E^{NOETS}_{r,0}}$ (long_name = 'initial emissions not covered by ETS')
    @# if ClimateVarsRegional != []
        @# for z in ClimateVarsRegional
            @{z}0_@{reg}_p ${T_{0,n}}$ (long_name = 'initial regional @{z}')
        @# endfor
    @# endif
@# endfor
% === initial values ===
@# if ClimateVarsNational != []
    @# for z in ClimateVarsNational
        @{z}0_p ${@{z}_{0}}$ (long_name = 'initial @{z}')
    @# endfor
@# endif
Y0_p ${Y_0}$ (long_name = 'initial GDP')
Q0_p ${Q_0}$ (long_name = 'initial Output')
PE0_p ${P^E_0}$ (long_name = 'initial emission price')
E0_p ${E_0}$ (long_name = 'initial emissions')
E0_NOETS_p ${E^{NOETS}_0}$ (long_name = 'initial emissions not covered by ETS')
rf0_p ${r^f_0}$ (long_name = 'initial world interest rate')
% === terminal values ===
PoPT_p ${PoP_0}$ (long_name = 'terminal population')
YT_p ${Y_T}$ (long_name = 'terminal output')
PT_p ${P_T}$ (long_name = 'terminal price level')
phitauS_p ${\phi^{\tau^S}}$ (long_name = 'share of revenues from ETS spend on subsidies')
phiKE_p ${\phi^{KE}}$ (long_name = 'sensitivity of capital rental wedge to emission intensity (SRI parameter, Oehmke-Opp 2025)')chiSRI_p ${\chi^{SRI}}$ (long_name = 'share of social cost of carbon internalized by households (green taxonomy depth, 0=none, 1=full SCC)');
