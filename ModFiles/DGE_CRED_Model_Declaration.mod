% ====================================
% === Declare Endogenous Variables ===
% ====================================
var 
// contemporaneous equations/variables defined by others
@# for z in ClimateVarsNational
    @{z} ${@{z}}$ (long_name = '@{z}')
@# endfor
@# for reg in 1:Regions
    @# for z in ClimateVarsRegional
        @{z}_@{reg} ${@{z}_{r}}$ (long_name = '@{z}')
    @# endfor
@# endfor
@# for sec in 1:Sectors
    @# for subsec in Subsecstart[sec]:Subsecend[sec]
        P_M_@{subsec} ${P^{M}_s}$ (long_name = 'imports sector price index')
    @# endfor
@# endfor
// actual variables
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
///////////////////////////////////////////////
@# for reg in 1:Regions
    @# for sec in 1:Sectors
        @# for subsec in Subsecstart[sec]:Subsecend[sec]
            //KH_@{subsec}_@{reg} ${K_{s,r}}$ (long_name = 'regional sector capital')
            r_@{subsec}_@{reg} ${r_{s,r}}$ (long_name = 'regional rental rate for sector capital')
            I_@{subsec}_@{reg} ${I_{s,r}}$ (long_name = 'regional sector investment')
            omegaI_@{subsec}_@{reg} ${\omega^I_{s,r}}$ (long_name = 'shadow value of regional private sector investment')
            // exogenous variables
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
            // endogenous supply firms
            P_@{subsec}_@{reg} ${P_{s,r}}$ (long_name = 'regional sector price index')
            K_@{subsec}_@{reg} ${K_{s,r}}$ (long_name = 'regional sector capital')            
            Y_@{subsec}_@{reg} ${Y_{s,r}}$ (long_name = 'regional sector GDP')
            N_@{subsec}_@{reg} ${N_{s,r}}$ (long_name = 'regional sector employment')
            Q_I_@{subsec}_@{reg} ${Q^{I}_{s,r}}$ (long_name = 'regional sector intermediate inputs')
            P_I_@{subsec}_@{reg} ${P^{I}_{s,r}}$ (long_name = 'regional sector intermediate inputs price index')
            E_@{subsec}_@{reg} ${E_{s,r}}$ (long_name = 'regional emissions associated with output used in sector k')
            kappaE_@{subsec}_@{reg} ${\kappa^{E}_{s,r}}$ (long_name = 'emission factor associated with production in the subsector and region')            
            @# for secm in 1:Sectors
                A_I_@{subsec}_@{reg}_@{secm} ${A^{I}_{s,r,k}}$ (long_name = 'regional subsector intermediate inputs productivity from aggregate sector k')
                Q_I_@{subsec}_@{reg}_@{secm} ${Q^{I}_{s,r,k}}$ (long_name = 'regional subsector intermediate inputs from aggregate sector k')
                E_I_@{subsec}_@{reg}_@{secm} ${E^I_{s,r,k}}$ (long_name = 'regional emissions associated with inputs used form sector k')
            @# endfor
            X_@{subsec}_@{reg} ${X_{s,r}}$ (long_name = 'sector exports')
            D_X_@{subsec}_@{reg} ${D^{X}_{s,r}}$ (long_name = 'world demand for sector exports')
            Q_@{subsec}_@{reg} ${Q_{s,r}}$ (long_name = 'regional sector Output')
            P_Q_@{subsec}_@{reg} ${P^Q_{s,r}}$ (long_name = 'regional supply sector price index')
            // endogenous supply households
            W_@{subsec}_@{reg} ${W_{s,r}}$ (long_name = 'regional wage rate for sector labour')
            // endogenous demand
            @# for regm in 1:Regions
                Q_D_@{subsec}_@{reg}_@{regm} ${Q^D_{s,r,m}}$ (long_name = 'regional demand for sector Output')
            @# endfor
            Q_D_@{subsec}_@{reg} ${Q^{D}_{s,r}}$ (long_name = 'domestically used sector output')
            P_D_@{subsec}_@{reg} ${P_{s,r}}$ (long_name = 'regional demand sector price index')
            M_I_@{subsec}_@{reg} ${M^I_{s,r}}$ (long_name = 'regional subsectoral imports for intermediates')
            M_F_@{subsec}_@{reg} ${M^F_{s,r}}$ (long_name = 'regional subsectoral imports for final products')
        @# endfor
        // endogenous demand
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
    tauKH_@{reg}  ${\tau^{K,H}_{r}}$ (long_name = 'capital tax')
    G_A_DH_@{reg} ${G^{A,D^H}_{r}}$ (long_name = 'adaptation government expenditure for housing')       
    KG_@{reg} ${K^G_{r}}$ (long_name = 'public good capital stock')
    P_@{reg} ${P_{r}}$ (long_name = 'regional price level')
    P_F_@{reg} ${P^F_{r}}$ (long_name = 'regional imported price level')
    P_Q_@{reg} ${P^Q_{r}}$ (long_name = 'regional produced price level')
    P_D_@{reg} ${P^D_{r}}$ (long_name = 'regional used price level')
    E_@{reg} ${E_r}$ (long_name = 'regional emissions')
    EE_@{reg} ${EE_r}$ (long_name = 'regional energy efficiency')
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
        @# for reg in 1:Regions
            exo_X_@{subsec}_@{reg} ${\eta^{X,s,r}}$ (long_name = 'exogenous demand for sector exports')
            exo_@{subsec}_@{reg} ${\eta^{A,s,r}}$ (long_name = 'exogenous TFP')
            exo_N_@{subsec}_@{reg} ${\eta^{A^{N},k,r}}$ (long_name = 'exogenous labour specific TFP')
            exo_K_@{subsec}_@{reg} ${\eta^{A^{K},k,r}}$ (long_name = 'exogenous capital specific TFP')
            exo_kappaE_@{subsec}_@{reg} ${\eta^{\kappa^{E},s,r}}$ (long_name = 'exogenous emission intensity of the respective sector and region')
            exo_E_@{subsec}_@{reg} ${\eta^{E,s,r}}$ (long_name = 'exogenous emission of the respective sector and region')
            exo_A_I_@{subsec}_@{reg} ${\eta^{A^{I},k,r}}$ (long_name = 'exogenous intermediate specific productivity')
            exo_QI_@{subsec}_@{reg} ${\eta^{Q^{I},k,r}}$ (long_name = 'exogenous intermediate share')
            exo_D_@{subsec}_@{reg} ${\eta^{D,k,r}}$ (long_name = 'exogenous damage induced by climate change for the sector')
            exo_D_N_@{subsec}_@{reg} ${\eta^{D^{N},k,r}}$ (long_name = 'exogenous damage induced by climate change for labour productivity in the sector')
            exo_D_K_@{subsec}_@{reg} ${\eta^{D^{K},k,r}}$ (long_name = 'exogenous damage induced by climate change for capital productivity in the sector')
            exo_Q_@{subsec}_@{reg} ${\eta^{E,s,r}}$ (long_name = 'exogenous share of emissions not part of ETS')
            exo_tauKF_@{subsec}_@{reg} ${\eta^{\tau^{K},k,r}}$ (long_name = 'exogenous sector and region corporate tax rate')
            exo_tauNF_@{subsec}_@{reg} ${\eta^{\tau^{N},k,r}}$ (long_name = 'exogenous sector and region labour tax rate')
            exo_GA_@{subsec}_@{reg} ${\eta^{G^{A,@{z}},k,r}}$ (long_name = 'exogenous sector adaptation expenditure against @{z}')
            @# for secm in 1:Sectors
                exo_EI_@{subsec}_@{reg}_@{secm} ${\eta^{E^{I},s,k,r}}$ (long_name = 'exogenous emissions caused by using intermediate products in subsector s from sector k')
                exo_AI_@{subsec}_@{reg}_@{secm} ${\eta^{A^{I},s,k,r}}$ (long_name = 'exogenous productivity for intermediate products in subsector s from sector k')
            @# endfor
        @# endfor
    @# endfor
@# endfor
exo_G_A_DH ${\eta^{G^{A,H}}}$ (long_name = 'exogenous sector adaptation expenditure for housing')
@# for z in ClimateVarsNational
    exo_@{z} ${\eta^{@{z},n}}$ (long_name = 'exogenous @{z}')
@# endfor
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
    //exo_PoP_@{reg} ${\eta^{PoP}_{r}}$ (long_name = 'exogeneous population')
    exo_H_@{reg} ${\eta^{H}_r}$ (long_name = 'exogeneous housing area to population ratio')
    exo_DH_@{reg} ${\eta^{D^{H}}_r}$ (long_name = 'exogeneous damage to housing stock')
    exo_tauC_@{reg} ${\eta^{\tau^C_{r}}}$ (long_name = 'exogeneous consumption tax')
    exo_tauH_@{reg} ${\eta^{\tau^H_{r}}}$ (long_name = 'exogeneous housing tax')
    exo_tauNH_@{reg} ${\eta^{\tau^{N,H}_{r}}}$ (long_name = 'exogeneous labour income tax paid by households')
    exo_tauKH_@{reg} ${\eta^{\tau^{K,H}_{r}}}$ (long_name = 'exogeneous capital income tax paid by households')
    exo_BG_@{reg} ${\eta^{BG}_{r}}$ (long_name = 'exogenous structural balance')
    exo_Tr_@{reg} ${\eta^{Tr}_r}$ (long_name = 'exogeneous transfer payments')
    exo_NXL_@{reg} ${\eta^{NX}_r}$ (long_name = 'logical exogenous variable to set net exports to GDP ratio')
    exo_BL_@{reg} ${\eta^{B}_r}$ (long_name = 'logical exogenous variable to set foreign asset position relative to GDP')
    exo_NX_@{reg} ${\eta^{NX}_r}$ (long_name = 'exogenous net exports to GDP ratio')
    exo_B_@{reg} ${\eta^{B}_r}$ (long_name = 'exogenous net foreign asset position')
    exo_deltaB_@{reg} ${\eta^{\delta^B}_r}$ (long_name = 'exogenous depreciation rate on net foreign asset position')
    exo_adjB_@{reg} ${\eta^{adj^B}_r}$ (long_name = 'exogenous adjustment cost')
    exo_s_@{reg} ${\eta^{s}_r}$ (long_name = 'exogenous change in net foreign asset position')
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
iSecEnergy_p ${s^{Energy}}$ (long_names = 'integer for fossil')
iSecHouse_p ${k^{Housing}}$ (long_names = 'integer for housing sector')
lEndogenousY_p ${l^{Y}}$ (long_name = 'logical indicator for endogenous or exogenous production')
lTargetY_p ${l^{Y,target}}$ (long_name = 'logical indicator for target on Y or Q in Baseline')
lExoNX_p ${l^{NX}}$ (long_name = 'logical indicator for exogenous net exports')
lCalibration_p  ${l^{Calib}}$ (long_name = 'logical indicator whether model is calibrated or not')
lCapandTrade_p  ${l^{CapandTrade}}$ (long_name = 'logical indicator whether cap and trade or exogenous emissions prices')
lEndoMig_p  ${l^{Endogenous Migration}}$ (long_name = 'logical indicator whether migration is endogenous or not')
TAdjLF_p ${T^{adjustment}}$ (long_name = 'adjustment time of labour supply to change in wage differentials')
etaLF_p ${\eta^{LF}}$ (long_name = 'elasticity of labour force to wage differentials')
h_p ${h}$ (long_name = 'habit persistence')
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
            D_X_@{subsec}_@{reg}_p ${D^{X}_{s,r}}$ (long_name = 'long-run demand for exports')
            lEndoQ_@{subsec}_@{reg}_p ${l^{Q}_{s,r}}$ (long_name = 'logical indicator whether output is endogenous or not')
            lEndoN_@{subsec}_@{reg}_p ${l^{N}_{s,r}}$ (long_name = 'logical indicator whether employment is endogenous or not')
            kappaE_@{subsec}_@{reg}_p ${\kappa^{E}_{s,r}}$ (long_name = 'emission factor associated with production in the subsector and region')
            sE_@{subsec}_@{reg}_p ${\frac{E_{s,r}}{E_0}}$ (long_name = 'share of emissions associated with using the input factor in the subsector and region')
            tauKF_@{subsec}_@{reg}_p ${\tau^{K,F}_{s,r}}$ (long_name = 'region and sector-specific tax rate on capital paid by firms')
            tauNF_@{subsec}_@{reg}_p ${\tau^{N,F}_{s,r}}$ (long_name = 'region and sector-specific tax rate on labour paid by firms')
            phiY_@{subsec}_@{reg}_p $\frac{P_{s,r,0} \, Y_{s,r,0}}{P_{0} \, Y_{0}}$ (long_name = 'share of regional and sectoral output')
            phiYT_@{subsec}_@{reg}_p $\frac{P_{s,r,T} \, Y_{s,r,T}}{P_{T} \, Y_{T}}$ (long_name = 'terminal share of regional and sectoral output')
            Q0_@{subsec}_@{reg}_p ${Q_{s,r,0}}$ (long_name = 'initial emissions')            
            Q_I0_@{subsec}_@{reg}_p ${Q^I_{s,r,0}}$ (long_name = 'initial emissions')            
            P0_Q_@{subsec}_@{reg}_p ${P^Q_{s,r,0}}$ (long_name = 'initial guess for regional supply sector price index')
            P0_@{subsec}_@{reg}_p ${P_{s,r,0}}$ (long_name = 'initial guess for regional value added sector price index')
            phiN_@{subsec}_@{reg}_p ${N_{s,r,0}}$ (long_name = 'long-run share of regional and sectoral employment')
            phiNT_@{subsec}_@{reg}_p ${N_{s,r,T}}$ (long_name = 'terminal share of regional and sectoral employment')
            phiN0_@{subsec}_@{reg}_p ${N_{s,r,0}}$ (long_name = 'initial share of regional and sectoral employment')
            phiW_@{subsec}_@{reg}_p $\frac{W_{s,r,0} \, N_{s,r,0}}{P_{s,r,0} \, Y_{s,r,0}}$ (long_name = 'share of regional and sectoral employment')
            phiL_@{subsec}_@{reg}_p ${\phi^{L}_{s,r}}$ (long_name = 'coefficient of disutility to work')
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
            deltaKA_@{subsec}_@{reg}_p ${\delta^{K^{A}_{s,r}}}$ (long_name = 'depreciation rate of adaptation capital stock against @{z}')
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
    s0_@{reg}_p  ${s_{r,0}}$ (long_name = 'initial exchange rate inflation')
    tauH_@{reg}_p  ${\tau^{H}_{r,0}}$ (long_name = 'tax on housing')
    tauNH_@{reg}_p ${\tau^{N,H}_{r,0}}$ (long_name = 'labour tax')
    tauKH_@{reg}_p  ${\tau^{K,H}_{r,0}}$ (long_name = 'capital tax')
    sH_@{reg}_p ${s_{r,0}^H}$ (long_name = 'share for housing investments')
    N0_@{reg}_p ${N_{r,0}}$ (long_name = 'initial regional employment')
    LF0_@{reg}_p ${LF_{r,0}}$ (long_name = 'initial labour force share')
    omegaLF0_@{reg}_p ${\omega^{LF}_{r,0}}$ (long_name = 'initial labour force preference')
    omegaF_@{reg}_p ${\omega^{F}_{r}}$ (long_name = 'foreign product share')
    P0_MR_@{reg}_p ${P^M_{r,0}}$ (long_name = 'initial price level')
    P0_D_@{reg}_p ${P_0}$ (long_name = 'initial price level')
    Tr0_@{reg}_p ${Tr_0}$ (long_name = 'initial transfer payments')    
    NX0_@{reg}_p ${NX_0}$ (long_name = 'initial net export to value-added ratio')
    gamma_@{reg}_p ${\gamma_r}$ (long_name = 'preferences for housing in utility function in each region')
    PoP0_@{reg}_p ${PoP_{r,0}}$ (long_name = 'initial population')
    H0_@{reg}_p ${H_{r,0}}$ (long_name = 'initial stocks of houses')
    PH0_@{reg}_p ${P^H_{r,0}}$ (long_name = 'initial price of houses')
    PE0_@{reg}_p ${P^E_{r,0}}$ (long_name = 'initial emission price')
    E0_@{reg}_p ${E_{r,0}}$ (long_name = 'initial emissions')
    @# for z in ClimateVarsRegional
        @{z}0_@{reg}_p ${T_{0,n}}$ (long_name = 'initial regional @{z}')
    @# endfor
@# endfor
% === initial values ===
@# for z in ClimateVarsNational
    @{z}0_p ${@{z}_{0}}$ (long_name = 'initial @{z}')
@# endfor
Y0_p ${Y_0}$ (long_name = 'initial GDP')
Q0_p ${Q_0}$ (long_name = 'initial Output')
PE0_p ${P^E_0}$ (long_name = 'initial emission price')
E0_p ${E_0}$ (long_name = 'initial emissions')
rf0_p ${r^f_0}$ (long_name = 'initial world interest rate')
% === terminal values ===
PoPT_p ${PoP_0}$ (long_name = 'terminal population')
YT_p ${Y_T}$ (long_name = 'terminal output')
PT_p ${P_T}$ (long_name = 'terminal price level')
phitauS_p ${\phi^{\tau^S}}$ (long_name = 'share of revenues from ETS spend on subsidies')
;