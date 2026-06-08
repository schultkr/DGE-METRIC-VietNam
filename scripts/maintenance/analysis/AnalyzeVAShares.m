%% AnalyzeVAShares.m
% Sensitivity analysis: how sectoral value-added shares (phiY_s_r_p)
% affect the model's steady-state calibration (alphaK, K, TFP, employment).
%
% phiY_s_r_p = basic-price GVA share of subsector s in region r
%            = (Gross Output_s - Intermediate Inputs_s) / Gross Output_aggregate
%
% Purpose : help identify the correct Baseline path for DGE-METRIC
%           by comparing named calibration configurations side by side.
%
% Prerequisites:
%   Run the Baseline scenario via RunSimulations.m first so that
%   DGE_Model/Output/DGE_Model_results.mat exists.
%
% Pipeline per scenario:
%   1. Calibration step (lCalibration_p=1): updates alphaK from new phiY.
%   2. Hybrid step     (lCalibration_p=2): solves for K from new alphaK.
%
% =========================================================================
%% USER SETTINGS — edit this section
% =========================================================================
% Subsector labels (s = 1..5)
snames = {'Primary', 'Fossil', 'Renewables', 'Secondary', 'Tertiary'};

% Scenario names
scenarioNames = {'Baseline', 'HighFossil', 'HighRE', 'HighServices'};

% phiY deltas relative to the Baseline loaded from the MAT file.
% Each row corresponds to one scenario; each column to one subsector.
% Constraint: sum of each row should be 0 so the aggregate phiY_p is
% preserved and Q0_p = (Y + phiEFdirect) / phiY_p stays constant.
% Row 1 must be all zeros (Baseline = no change).
%
%              Primary   Fossil    RE        Secondary Tertiary
phiY_delta = [  0.000,   0.000,   0.000,    0.000,    0.000 ;  % Baseline
                0.000,  +0.010,  -0.005,    0.000,   -0.005 ;  % HighFossil
                0.000,  -0.010,  +0.010,    0.000,    0.000 ;  % HighRE
                0.000,   0.000,  -0.005,   -0.005,   +0.010 ]; % HighServices

% =========================================================================
%% SETUP
% =========================================================================
repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd));
cd(repoRoot);
setup_paths();

% Solver tolerances
optCal = optimset('Display', 'off', 'TolFun', 1e-14, 'TolX', 1e-14, ...
                  'MaxFunEval', 50000);
optHyb = optimset('Display', 'off', 'TolFun', 1e-12, 'TolX', 1e-10, ...
                  'MaxFunEval', 100000);

% =========================================================================
%% LOAD DYNARE BASELINE
% =========================================================================
matFile = fullfile(repoRoot, 'DGE_Model', 'Output', 'DGE_Model_results.mat');
if ~exist(matFile, 'file')
    error('AnalyzeVAShares:missingMat', ...
          'File not found: %s\nRun RunSimulations.m (Baseline) first.', matFile);
end
load(matFile, 'M_', 'oo_', 'options_'); %#ok<NODEF>

% Reconstruct strpar (mirrors DGE_Model_steadystate.m lines 36-50)
strpar = struct('Init', nan);
strpar.casClimatevarsNational = strsplit( ...
    strrep(strrep(M_.ClimateVarsNational, '[', ''), ']', ''), ', ');
strpar.casClimatevarsRegional = strsplit( ...
    strrep(strrep(M_.ClimateVarsRegional, '[', ''), ']', ''), ', ');
strpar.casClimatevars = [strpar.casClimatevarsNational, strpar.casClimatevarsRegional];
for ii = 1:M_.param_nbr
    strpar.(strtrim(char(M_.param_names(ii,:)))) = M_.params(ii);
end
strpar.ssubsecfossil = num2str(strpar.iSubsecFossil_p);
strpar.ssecenergy    = num2str(strpar.iSecEnergy_p);

% Reconstruct strys from Dynare steady state
strys_base = struct('Init', nan);
ys = oo_.steady_state;
for ii = 1:M_.endo_nbr
    strys_base.(strtrim(char(M_.endo_names(ii,:)))) = ys(ii);
end

% Reconstruct strexo
strexo_base = struct('Init', nan);
exo = oo_.exo_steady_state;
for ii = 1:M_.exo_nbr
    strexo_base.(strtrim(char(M_.exo_names(ii,:)))) = exo(ii);
end

% =========================================================================
%% READ BASELINE phiY VALUES AND BUILD SCENARIO MATRIX
% =========================================================================
nS = strpar.inbsectors_p + 1;   % total subsectors (subend of last sector)
sMaxSec = num2str(strpar.inbsectors_p);
nS = strpar.(['subend_' sMaxSec '_p']);
nR = strpar.inbregions_p;
nScen = numel(scenarioNames);

% Read baseline phiY for each subsector
phiY_base = zeros(nS, nR);
for s = 1:nS
    for r = 1:nR
        phiY_base(s, r) = strpar.(['phiY_' num2str(s) '_' num2str(r) '_p']);
    end
end
phiY_p_base = sum(phiY_base(:));

% Validate delta matrix dimensions
assert(size(phiY_delta, 1) == nScen, ...
    'phiY_delta must have %d rows (one per scenario).', nScen);
assert(size(phiY_delta, 2) == nS, ...
    'phiY_delta must have %d columns (one per subsector).', nS);

% Build full phiY matrix per scenario
phiY_scen = zeros(nS, nR, nScen);
for isc = 1:nScen
    for s = 1:nS
        for r = 1:nR
            phiY_scen(s, r, isc) = phiY_base(s, r) + phiY_delta(isc, s);
        end
    end
    scenSum = sum(phiY_scen(:, :, isc), 'all');
    if abs(scenSum - phiY_p_base) > 1e-5
        fprintf('[WARNING] Scenario "%s": sum(phiY)=%.6f vs baseline %.6f (delta=%.2e)\n', ...
            scenarioNames{isc}, scenSum, phiY_p_base, scenSum - phiY_p_base);
    end
end

% Print baseline values for reference
fprintf('\nBaseline phiY_s_1 (from loaded MAT file):\n');
for s = 1:nS
    fprintf('  phiY_%d_1 = %8.6f  (%s)\n', s, phiY_base(s,1), snames{s});
end
fprintf('  phiY_p   = %8.6f  (aggregate VA share)\n\n', phiY_p_base);

% =========================================================================
%% RUN SCENARIOS
% =========================================================================
res_alphaK = zeros(nS, nScen);
res_K      = zeros(nS, nScen);
res_A      = zeros(nS, nScen);
res_N      = zeros(nS, nScen);
res_VAexp  = zeros(nS, nScen);   % SNA GVA at basic prices = phiY_s * Q0
res_kappaE = zeros(nS, nScen);
res_P_Q    = zeros(nS, nScen);
res_maxRes = zeros(1, nScen);    % max hybrid residual

for isc = 1:nScen
    fprintf('--- Scenario %d/%d: %s\n', isc, nScen, scenarioNames{isc});

    %% Step 1: Calibration (lCalibration_p = 1)
    % Recalibrates alphaK, omegaQ, P_D etc. from the new phiY values.
    strpar_i = strpar;
    strpar_i.lCalibration_p = 1;

    for s = 1:nS
        ss = num2str(s);
        for r = 1:nR
            sr = num2str(r);
            val = phiY_scen(s, r, isc);
            strpar_i.(['phiY_'  ss '_' sr '_p']) = val;
            % phiY0 is what build_initial_guess (calibrate mode) reads back
            strpar_i.(['phiY0_' ss '_' sr '_p']) = val;
        end
    end

    [xCal, strys_i, strpar_i] = ss_build_initial_guess(strys_base, strexo_base, strpar_i, 'calibrate');
    calFun = @(x) ss_setup_initial_state(x, strys_i, strexo_base, strpar_i);
    [Fcal, strpar_i, strys_i] = ss_setup_initial_state(xCal, strys_i, strexo_base, strpar_i);

    if max(abs(Fcal)) > 1e-8
        [xCalOpt, ~, exitFlag] = fsolve(calFun, xCal, optCal);
        if exitFlag < 1
            fprintf('  [WARNING] Calibration fsolve: exitFlag = %d\n', exitFlag);
        end
        [~, strpar_i, strys_i] = ss_setup_initial_state(xCalOpt, strys_i, strexo_base, strpar_i);
    end

    %% Step 2: Hybrid solver (lCalibration_p = 2) — solves for K
    % alphaK is now updated from Step 1; hybrid mode computes K from alphaK.
    strpar_i.lCalibration_p = 2;

    [xHyb, strys_i, strpar_i] = ss_build_initial_guess(strys_i, strexo_base, strpar_i, 'hybrid');
    hybFun = @(x) ss_compute_capital(x, strys_i, strexo_base, strpar_i);
    [Fhyb, strys_i, ~] = ss_compute_capital(xHyb, strys_i, strexo_base, strpar_i);

    if max(abs(Fhyb)) > 1e-8
        [xHybOpt, ~, exitFlag] = fsolve(hybFun, xHyb, optHyb);
        if exitFlag < 1
            fprintf('  [WARNING] Hybrid fsolve: exitFlag = %d\n', exitFlag);
        end
        [Fhyb, strys_i, ~] = ss_compute_capital(xHybOpt, strys_i, strexo_base, strpar_i);
    end

    res_maxRes(isc) = max(abs(Fhyb));
    fprintf('  Max hybrid residual: %.2e\n', res_maxRes(isc));

    %% Collect results
    for s = 1:nS
        ss = num2str(s);
        res_alphaK(s, isc) = strpar_i.(['alphaK_' ss '_1_p']);
        res_K(s, isc)      = strys_i.(['K_' ss '_1']);
        res_A(s, isc)      = strys_i.(['A_' ss '_1']);
        res_N(s, isc)      = strys_i.(['N_' ss '_1']);
        res_P_Q(s, isc)    = strys_i.(['P_Q_' ss '_1']);
        res_VAexp(s, isc)  = strpar_i.(['VAexp_' ss '_1_p']);
        if isfield(strys_i, ['kappaE_' ss '_1'])
            res_kappaE(s, isc) = strys_i.(['kappaE_' ss '_1']);
        end
    end
end

% =========================================================================
%% CONSOLE TABLE
% =========================================================================
lw_sep = repmat('=', 1, 88);
fprintf('\n%s\n', lw_sep);
fprintf('SECTORAL VA SHARE ANALYSIS — Steady-State Comparison\n');
fprintf('%s\n', lw_sep);

hdrFmt = '  %-12s  %10s  %10s  %10s  %10s  %10s\n';
rowFmt = '  %-12s  %10.5f  %10.5f  %10.5f  %10.5f  %10.5f\n';
pctFmt = '  %-12s  %10.2f  %10.2f  %10.2f  %10.2f  %10.2f   [%%]\n';

for isc = 1:nScen
    fprintf('\n--- %s  (max residual: %.1e) ---\n', scenarioNames{isc}, res_maxRes(isc));
    fprintf(hdrFmt, '', snames{:});

    fprintf(rowFmt, 'phiY',   phiY_scen(:,1,isc)');
    fprintf(rowFmt, 'alphaK', res_alphaK(:,isc)');

    totVA = sum(res_VAexp(:,isc));
    fprintf(pctFmt, 'VA / total', res_VAexp(:,isc)' / totVA * 100);

    totK = sum(res_K(:,isc));
    fprintf(pctFmt, 'K / total',  res_K(:,isc)'  / totK  * 100);

    basA = res_A(:,1);
    basA(basA == 0) = 1;
    fprintf(rowFmt, 'TFP index', res_A(:,isc)' ./ basA' * 100);

    fprintf(rowFmt, 'P_Q',    res_P_Q(:,isc)');
end

% Cross-scenario comparison: capital stocks indexed to Baseline
fprintf('\n%s\n', lw_sep);
fprintf('Capital stocks  K_s_1  (Baseline = 100)\n');
fprintf('%s\n', lw_sep);
fprintf(hdrFmt, 'Scenario', snames{:});
for isc = 1:nScen
    base_K = res_K(:,1);
    base_K(base_K == 0) = 1;
    fprintf(pctFmt, scenarioNames{isc}, res_K(:,isc)' ./ base_K' * 100);
end

% =========================================================================
%% FIGURE
% =========================================================================
close all;
set(groot, 'defaultAxesFontSize',  12, 'defaultTextFontSize',  12, ...
           'defaultLegendFontSize', 10, 'defaultAxesFontName', 'Arial');

colors = lines(nS);
xpos   = 1:nScen;
lw_fig = 1.8;

figure('Name', 'VA Share Sensitivity', 'NumberTitle', 'off', ...
       'Position', [60 60 1250 820]);

%% Panel 1 — Sectoral VA composition (stacked bar)
subplot(2, 2, 1);
va_pct = res_VAexp ./ sum(res_VAexp, 1) * 100;
bar(xpos, va_pct', 'stacked');
colormap(gca, lines(nS));
set(gca, 'XTick', xpos, 'XTickLabel', scenarioNames, 'XTickLabelRotation', 15);
ylabel('% of total VA');
title('Sectoral VA Composition');
legend(snames, 'Location', 'eastoutside', 'FontSize', 9);
grid on; ylim([0 110]);

%% Panel 2 — Capital stocks (index relative to Baseline)
subplot(2, 2, 2);
hold on;
base_K = res_K(:,1);  base_K(base_K == 0) = 1;
K_idx  = res_K ./ base_K * 100;
for s = 1:nS
    plot(xpos, K_idx(s,:), '-o', 'Color', colors(s,:), 'LineWidth', lw_fig, ...
         'DisplayName', snames{s});
end
hold off;
set(gca, 'XTick', xpos, 'XTickLabel', scenarioNames, 'XTickLabelRotation', 15);
yline(100, 'k--', 'LineWidth', 1);
ylabel('Index (Baseline = 100)');
title('Sectoral Capital Stocks  K_{s,1}');
legend('Location', 'eastoutside', 'FontSize', 9);
grid on;

%% Panel 3 — TFP (index relative to Baseline)
subplot(2, 2, 3);
hold on;
base_A = res_A(:,1);  base_A(base_A == 0) = 1;
A_idx  = res_A ./ base_A * 100;
for s = 1:nS
    plot(xpos, A_idx(s,:), '-s', 'Color', colors(s,:), 'LineWidth', lw_fig, ...
         'DisplayName', snames{s});
end
hold off;
set(gca, 'XTick', xpos, 'XTickLabel', scenarioNames, 'XTickLabelRotation', 15);
yline(100, 'k--', 'LineWidth', 1);
ylabel('Index (Baseline = 100)');
title('Sectoral TFP  A_{s,1}');
legend('Location', 'eastoutside', 'FontSize', 9);
grid on;

%% Panel 4 — Capital income shares alphaK
subplot(2, 2, 4);
hold on;
for s = 1:nS
    plot(xpos, res_alphaK(s,:), '-^', 'Color', colors(s,:), 'LineWidth', lw_fig, ...
         'DisplayName', snames{s});
end
hold off;
set(gca, 'XTick', xpos, 'XTickLabel', scenarioNames, 'XTickLabelRotation', 15, ...
         'YLim', [0 1]);
ylabel('\alpha_K  (capital income share)');
title('Capital Income Shares  \alpha_{K,s,1}');
legend('Location', 'eastoutside', 'FontSize', 9);
grid on;

sgtitle('Steady-State Sensitivity to Sectoral VA Shares  (phiY_{s,1})', ...
        'FontSize', 14, 'FontWeight', 'bold');
