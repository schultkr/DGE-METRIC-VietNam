%% ComputeTerminalSS.m
% Evaluates the terminal steady state implied by the Baseline scenario
% sheet WITHOUT computing the full transition path.
%
% The terminal state is fully defined by parameters already in the Excel
% "Start" sheet:
%   phiYT_s_r_p — terminal sectoral VA shares   (vs. phiY0 initial)
%   phiNT_s_r_p — terminal sectoral labor shares (vs. phiN0 initial)
%   YT_p        — terminal aggregate GDP
%   omegaNXT_p  — terminal net-export share
%
% Exogenous driving variables (EE_r, LF_r, …) are set to their terminal
% values from oo_.exo_simul (last row of the Baseline simulation path).
%
% Pipeline (mirrors RunSimulations / DGE_Model_steadystate.m):
%   Step 1  Load DGE_Model_results.mat → M_, oo_
%   Step 2  Build strpar_T  by replacing *0* params with *T* params
%   Step 3  Build strexo_T  from oo_.exo_simul(end,:)
%   Step 4  Calibration mode (lCalibration_p=1) → recalibrates alphaK, A
%   Step 5  Hybrid mode     (lCalibration_p=2) → solves for K from alphaK
%   Step 6  Print comparison table and figure
%
% Prerequisites:
%   Run RunSimulations.m (Baseline) first so
%   DGE_Model/Output/DGE_Model_results.mat exists.

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd));
cd(repoRoot);
setup_paths();

optCal = optimset('Display','off','TolFun',1e-14,'TolX',1e-14,'MaxFunEval',50000);
optHyb = optimset('Display','off','TolFun',1e-12,'TolX',1e-10,'MaxFunEval',100000);

% =========================================================================
%% 1. LOAD DYNARE BASELINE RESULTS
% =========================================================================
matFile = fullfile(repoRoot, 'DGE_Model', 'Output', 'DGE_Model_results.mat');
if ~exist(matFile, 'file')
    error('ComputeTerminalSS:missingMat', ...
          'File not found:\n  %s\nRun RunSimulations.m (Baseline) first.', matFile);
end
load(matFile, 'M_', 'oo_', 'options_'); %#ok<NODEF>
fprintf('Loaded %s\n', matFile);

% ---- Reconstruct strpar (mirrors DGE_Model_steadystate.m lines 36-50) ---
strpar = struct('Init', nan);
strpar.casClimatevarsNational = strsplit( ...
    strrep(strrep(M_.ClimateVarsNational,'[',''),']',''), ', ');
strpar.casClimatevarsRegional = strsplit( ...
    strrep(strrep(M_.ClimateVarsRegional,'[',''),']',''), ', ');
strpar.casClimatevars = [strpar.casClimatevarsNational strpar.casClimatevarsRegional];
for ii = 1:M_.param_nbr
    strpar.(strtrim(char(M_.param_names(ii,:)))) = M_.params(ii);
end
strpar.ssubsecfossil = num2str(strpar.iSubsecFossil_p);
strpar.ssecenergy    = num2str(strpar.iSecEnergy_p);

% ---- Reconstruct strys from initial steady state -------------------------
strys_init = struct('Init', nan);
ys0 = oo_.steady_state;
for ii = 1:M_.endo_nbr
    strys_init.(strtrim(char(M_.endo_names(ii,:)))) = ys0(ii);
end

% ---- Reconstruct strexo from initial exo steady state -------------------
strexo_init = struct('Init', nan);
exo0 = oo_.exo_steady_state;
for ii = 1:M_.exo_nbr
    strexo_init.(strtrim(char(M_.exo_names(ii,:)))) = exo0(ii);
end

nS = strpar.(['subend_' num2str(strpar.inbsectors_p) '_p']);
nR = strpar.inbregions_p;
snames = {'Primary','Fossil','Renewables','Secondary','Tertiary'};

% =========================================================================
%% 2. BUILD TERMINAL STRUCTURAL PARAMETERS (strpar_T)
% =========================================================================
strpar_T = strpar;
strpar_T.Y0_p = strpar.YT_p;   % terminal aggregate GDP

% Net-export share
if isfield(strpar, 'omegaNXT_p')
    strpar_T.omegaNX0_p = strpar.omegaNXT_p;
    strpar_T.omegaNX_p  = strpar.omegaNXT_p;
end

% Sectoral shares: swap phiY0→phiYT, phiN0→phiNT for all subsectors
for s = 1:nS
    ss = num2str(s);
    for r = 1:nR
        sr = num2str(r);

        % VA shares
        fYT = ['phiYT_' ss '_' sr '_p'];
        if isfield(strpar, fYT)
            strpar_T.(['phiY_'  ss '_' sr '_p']) = strpar.(fYT);
            strpar_T.(['phiY0_' ss '_' sr '_p']) = strpar.(fYT);
        end

        % Labor shares
        fNT = ['phiNT_' ss '_' sr '_p'];
        if isfield(strpar, fNT)
            strpar_T.(['phiN_'  ss '_' sr '_p']) = strpar.(fNT);
            strpar_T.(['phiN0_' ss '_' sr '_p']) = strpar.(fNT);
        end
    end
end

% Climate terminal values (e.g., tasT_r_p → tas0_r_p)
for iv = 1:numel(strpar.casClimatevars)
    vname = strpar.casClimatevars{iv};
    % check for regional terminal parameters
    for r = 1:nR
        sr = num2str(r);
        fT = [vname 'T_' sr '_p'];
        f0 = [vname '0_' sr '_p'];
        if isfield(strpar, fT) && isfield(strpar_T, f0)
            strpar_T.(f0) = strpar.(fT);
        end
    end
    % national terminal parameter
    fT = [vname 'T_p'];
    f0 = [vname '0_p'];
    if isfield(strpar, fT) && isfield(strpar_T, f0)
        strpar_T.(f0) = strpar.(fT);
    end
end

% =========================================================================
%% 3. BUILD TERMINAL EXOGENOUS VARIABLES (strexo_T)
% =========================================================================
strexo_T = strexo_init;

if isfield(oo_, 'exo_simul') && ~isempty(oo_.exo_simul)
    T_sim = size(oo_.exo_simul, 1);
    exo_terminal = oo_.exo_simul(T_sim, :);
    for ii = 1:M_.exo_nbr
        strexo_T.(strtrim(char(M_.exo_names(ii,:)))) = exo_terminal(ii);
    end
    fprintf('Terminal exo values from oo_.exo_simul  (T = %d periods).\n', T_sim);
else
    fprintf('[WARNING] oo_.exo_simul not found — terminal exo = initial exo.\n');
end

% =========================================================================
%% 4. CALIBRATION STEP: lCalibration_p = 1
%    Recalibrates alphaK, production function parameters from phiYT
% =========================================================================
strpar_T.lCalibration_p = 1;

[xCal, strys_T, strpar_T] = ss_build_initial_guess(strys_init, strexo_T, strpar_T, 'calibrate');
calFun = @(x) ss_setup_initial_state(x, strys_T, strexo_T, strpar_T);

[Fcal, strpar_T, strys_T] = ss_setup_initial_state(xCal, strys_T, strexo_T, strpar_T);
if max(abs(Fcal)) > 1e-8
    fprintf('Calibration: running fsolve (initial max residual %.1e)…\n', max(abs(Fcal)));
    [xCalOpt, ~, exitFlag] = fsolve(calFun, xCal, optCal);
    if exitFlag < 1
        fprintf('[WARNING] Calibration fsolve: exitFlag = %d\n', exitFlag);
    end
    [~, strpar_T, strys_T] = ss_setup_initial_state(xCalOpt, strys_T, strexo_T, strpar_T);
end

% =========================================================================
%% 5. HYBRID STEP: lCalibration_p = 2
%    Solves for K consistent with the recalibrated alphaK and terminal Y0
% =========================================================================
strpar_T.lCalibration_p = 2;

[xHyb, strys_T, strpar_T] = ss_build_initial_guess(strys_T, strexo_T, strpar_T, 'hybrid');
hybFun = @(x) ss_compute_capital(x, strys_T, strexo_T, strpar_T);

[Fhyb, strys_T, ~] = ss_compute_capital(xHyb, strys_T, strexo_T, strpar_T);
if max(abs(Fhyb)) > 1e-8
    fprintf('Hybrid:       running fsolve (initial max residual %.1e)…\n', max(abs(Fhyb)));
    [xHybOpt, ~, exitFlag] = fsolve(hybFun, xHyb, optHyb);
    if exitFlag < 1
        fprintf('[WARNING] Hybrid fsolve: exitFlag = %d\n', exitFlag);
    end
    [Fhyb, strys_T, ~] = ss_compute_capital(xHybOpt, strys_T, strexo_T, strpar_T);
end
fprintf('Terminal SS solved.  Max residual: %.2e\n\n', max(abs(Fhyb)));

% =========================================================================
%% 6. COLLECT AND COMPARE
% =========================================================================
vars = {'phiY','phiN0','alphaK','K','A','N','P_Q','kappaE'};

res = struct();
for v = vars
    res.(v{1}).init = zeros(nS,1);
    res.(v{1}).term = zeros(nS,1);
end
res.VAexp.init = zeros(nS,1);
res.VAexp.term = zeros(nS,1);
res.EE.init    = zeros(nR,1);
res.EE.term    = zeros(nR,1);

for s = 1:nS
    ss = num2str(s);
    res.phiY.init(s)   = strpar.(['phiY0_' ss '_1_p']);
    res.phiY.term(s)   = strpar.(['phiYT_' ss '_1_p']);
    res.phiN0.init(s)  = strpar.(['phiN0_' ss '_1_p']);
    if isfield(strpar,['phiNT_' ss '_1_p'])
        res.phiN0.term(s) = strpar.(['phiNT_' ss '_1_p']);
    end
    res.alphaK.init(s) = strpar.(['alphaK_' ss '_1_p']);
    res.alphaK.term(s) = strpar_T.(['alphaK_' ss '_1_p']);
    res.K.init(s)      = strys_init.(['K_' ss '_1']);
    res.K.term(s)      = strys_T.(['K_' ss '_1']);
    res.A.init(s)      = strys_init.(['A_' ss '_1']);
    res.A.term(s)      = strys_T.(['A_' ss '_1']);
    res.N.init(s)      = strys_init.(['N_' ss '_1']);
    res.N.term(s)      = strys_T.(['N_' ss '_1']);
    res.P_Q.init(s)    = strys_init.(['P_Q_' ss '_1']);
    res.P_Q.term(s)    = strys_T.(['P_Q_' ss '_1']);
    res.kappaE.init(s) = strys_init.(['kappaE_' ss '_1']);
    res.kappaE.term(s) = strys_T.(['kappaE_' ss '_1']);
    if isfield(strpar,'VAexp_s_1_p')  % stored by compute_expenditure_assignments
        res.VAexp.init(s) = strpar.(['VAexp_' ss '_1_p']);
        res.VAexp.term(s) = strpar_T.(['VAexp_' ss '_1_p']);
    end
end
for r = 1:nR
    sr = num2str(r);
    res.EE.init(r) = strys_init.(['EE_' sr]);
    res.EE.term(r) = strys_T.(['EE_'  sr]);
end

% =========================================================================
%% 7. CONSOLE TABLE
% =========================================================================
sep = repmat('=', 1, 80);
fprintf('%s\n', sep);
fprintf('TERMINAL STEADY STATE  vs  INITIAL STEADY STATE  (Baseline)\n');
fprintf('%s\n', sep);

hdr = '  %-12s   %10s  %10s  %10s  %10s  %10s\n';
row = '  %-12s   %10.5f  %10.5f  %10.5f  %10.5f  %10.5f\n';
pct = '  %-12s   %10.2f  %10.2f  %10.2f  %10.2f  %10.2f  [%%]\n';

fprintf(hdr, '', snames{1:nS});

fprintf('\n-- Structural parameters --\n');
fprintf(row, 'phiY0 (init)', res.phiY.init');
fprintf(row, 'phiYT (term)', res.phiY.term');
fprintf(row, 'phiN0 (init)', res.phiN0.init');
fprintf(row, 'phiNT (term)', res.phiN0.term');
fprintf(row, 'alphaK init',  res.alphaK.init');
fprintf(row, 'alphaK term',  res.alphaK.term');

fprintf('\n-- Endogenous outcomes --\n');
Ki = sum(res.K.init);  Kt = sum(res.K.term);
fprintf(pct, 'K share init', res.K.init' / Ki * 100);
fprintf(pct, 'K share term', res.K.term' / Kt * 100);
fprintf(row, 'K ratio T/0',  res.K.term' ./ max(res.K.init', 1e-12));
fprintf(row, 'TFP init',     res.A.init');
fprintf(row, 'TFP term',     res.A.term');
fprintf(row, 'TFP ratio',    res.A.term' ./ max(res.A.init', 1e-12));
fprintf(row, 'N init',       res.N.init');
fprintf(row, 'N term',       res.N.term');
fprintf(row, 'P_Q init',     res.P_Q.init');
fprintf(row, 'P_Q term',     res.P_Q.term');
fprintf(row, 'kappaE init',  res.kappaE.init');
fprintf(row, 'kappaE term',  res.kappaE.term');

fprintf('\n-- Energy efficiency  EE_r --\n');
for r = 1:nR
    fprintf('  Region %d:  EE_init = %.4f   EE_term = %.4f   ratio = %.3f\n', ...
        r, res.EE.init(r), res.EE.term(r), res.EE.term(r)/max(res.EE.init(r),1e-12));
end

% Fossil/RE energy share
sF = num2str(strpar.iSubsecFossil_p);
sR = num2str(strpar.iSubsecRE_p);
K_ener_i = res.K.init(strpar.iSubsecFossil_p) + res.K.init(strpar.iSubsecRE_p);
K_ener_t = res.K.term(strpar.iSubsecFossil_p) + res.K.term(strpar.iSubsecRE_p);
if K_ener_i > 0
    fprintf('\nEnergy-sector capital split:\n');
    fprintf('  Fossil share  init: %.1f%%    term: %.1f%%\n', ...
        res.K.init(strpar.iSubsecFossil_p)/K_ener_i*100, ...
        res.K.term(strpar.iSubsecFossil_p)/K_ener_t*100);
    fprintf('  RE     share  init: %.1f%%    term: %.1f%%\n', ...
        res.K.init(strpar.iSubsecRE_p)/K_ener_i*100, ...
        res.K.term(strpar.iSubsecRE_p)/K_ener_t*100);
end

fprintf('%s\n\n', sep);

% =========================================================================
%% 8. FIGURE — side-by-side bars
% =========================================================================
close all;
set(groot,'defaultAxesFontSize',12,'defaultTextFontSize',12, ...
          'defaultLegendFontSize',10,'defaultAxesFontName','Arial');

grp   = categorical(snames(1:nS), snames(1:nS));
lw    = 1.5;
c_init = [0.25 0.55 0.85];
c_term = [0.95 0.45 0.15];

figure('Name','Terminal vs Initial Steady State','NumberTitle','off', ...
       'Position',[60 60 1200 820]);

%% Panel 1 — VA shares
subplot(2,2,1);
bar(grp, [res.phiY.init, res.phiY.term]);
legend({'Initial (phiY0)','Terminal (phiYT)'},'Location','northeast');
ylabel('phiY_{s,1}');
title('Sectoral VA Shares');
grid on;

%% Panel 2 — Capital stocks (index: initial=100)
subplot(2,2,2);
base = max(res.K.init, 1e-12);
bar(grp, [ones(nS,1)*100, res.K.term./base*100]);
yline(100,'k--','LineWidth',1);
legend({'Initial (= 100)','Terminal'},'Location','northeast');
ylabel('Index (initial = 100)');
title('Sectoral Capital  K_{s,1}');
grid on;

%% Panel 3 — TFP (index)
subplot(2,2,3);
base = max(res.A.init, 1e-12);
bar(grp, [ones(nS,1)*100, res.A.term./base*100]);
yline(100,'k--','LineWidth',1);
legend({'Initial (= 100)','Terminal'},'Location','northeast');
ylabel('Index (initial = 100)');
title('Sectoral TFP  A_{s,1}');
grid on;

%% Panel 4 — Capital income shares alphaK
subplot(2,2,4);
bar(grp, [res.alphaK.init, res.alphaK.term]);
legend({'Initial','Terminal'},'Location','northeast');
ylabel('\alpha_K');
ylim([0 1]);
title('Capital Income Shares  \alpha_{K,s,1}');
grid on;

sgtitle(sprintf('Terminal vs Initial Steady State  (Baseline)\nEE_1: %.3f → %.3f  |  max residual: %.1e', ...
    res.EE.init(1), res.EE.term(1), max(abs(Fhyb))), ...
    'FontSize',13,'FontWeight','bold');
