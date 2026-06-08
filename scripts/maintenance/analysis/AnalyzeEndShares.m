%% AnalyzeEndShares.m
%  Runs the Baseline scenario via the RunSimulations setup (lSteadyState = true)
%  for different Baseline candidates and compares the resulting transition paths.
%
%  Two complementary ways to define candidates (combinable per row):
%    1. baselineSheetNames  — sheet in ModelBaseline*.xlsx that provides the
%                             exogenous growth paths (gY, gN, exo_*).  Use
%                             different sheets to test entirely different
%                             Baseline projections from the Excel workbook.
%    2. phiYT_deltas        — additive shift to phiYT_s_1_p applied on top
%                             of whatever the sheet provides, e.g. to probe
%                             different terminal sector shares.
%
%  The script calls change_mod_file + dynare DGE_Model noclearall once, then
%  re-runs simulation_model_refactored for each candidate by patching
%  sBaselineSheet and M_.params before each call.

%% ====================================================================
%  USER-EDITABLE
%  ====================================================================
%  Each row defines one candidate.  All three arrays must have the same
%  number of rows.
%
%  baselineSheetNames : sheet to read from ModelBaseline*.xlsx.
%                       Run scripts/maintenance/CreateBaselineModelSheets.m
%                       to generate the model-variant sheets below.
%  candidateNames     : display label for plots and tables.
%  phiYT_deltas       : additive shift per subsector (must sum to 0).
%                       Set all zeros to use the sheet values as-is.
%
%  Subsectors: 1=Primary  2=Fossil  3=RE  4=Secondary  5=Tertiary

baselineSheetNames = {
    'Baseline';                  % reference sheet
    'Baseline_Model_RESmooth';   % smoother exo_I path, baseline exo_K_G scale
    'Baseline_Model_REEarly';    % front-loaded RE path, higher RE exo_K_G
    'Baseline_Model_RELate';     % back-loaded RE path, lower RE exo_K_G
};

candidateNames = {'Baseline', 'RESmooth', 'REEarly', 'RELate'};

%                Prim    Fossil    RE      Sec     Tert
% Legacy examples retained for quick phiYT experiments. The default
% sheet-only comparison resets this matrix to zeros immediately below.
phiYT_deltas = [
    0,            0,      0,       0,      0;      % no change
    0,          -0.05,  +0.05,    0,      0;      % 5 pp Fossil → RE
    0,          -0.02,   0,      -0.02,  +0.04;   % 4 pp → Tertiary
];

% The model-sheet comparison keeps terminal value-added shares unchanged;
% each candidate differs through the Excel exogenous paths instead.
phiYT_deltas = zeros(numel(candidateNames), 5);

% Example: add an extra row that uses an alternative Excel sheet
%   baselineSheetNames{end+1} = 'Baseline_Alt';
%   candidateNames{end+1}     = 'AltSheet';
%   phiYT_deltas(end+1,:)     = [0, 0, 0, 0, 0];

%% ====================================================================
%  SETUP  —  mirrors RunSimulations.m for the Baseline case
%  ====================================================================
repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd));
cd(repoRoot);
setup_paths();

% --- RunSimulations.m sector/region configuration --------------------
sSubsecstart  = '[1, 2, 4, 5]';
sSubsecend    = '[1, 3, 4, 5]';
sClimRegional = '["tas"]';
sClimNational = '["tas"]';
sTargetBase   = '1';
sRegions      = '1';
lSteadyState  = true;
sSimulation   = '5';    % homotopy steps (matches RunSimulations Baseline branch)
sExoNX        = '0';
sCapandTrade  = '0';
lBaselineBackward_p = 0;

sWorkbookCalibration = ['ExcelFiles/ModelCalibration' sSubsecend(end-1) 'Sectorsand' sRegions 'Regions.xlsx'];
sWorkbookBaseline    = ['ExcelFiles/ModelBaseline'    sSubsecend(end-1) 'Sectorsand' sRegions 'Regions.xlsx'];
sWorkbookScenarios   = ['ExcelFiles/ModelScenarios'   sSubsecend(end-1) 'Sectorsand' sRegions 'Regions.xlsx'];

% Fail early if the model-variant sheets have not been generated yet.
[~, workbookSheets] = xlsfinfo(sWorkbookBaseline);
missingSheets = setdiff(unique(baselineSheetNames), workbookSheets);
if ~isempty(missingSheets)
    error('AnalyzeEndShares:MissingBaselineSheets', ...
        ['Missing sheet(s) in %s: %s\n' ...
         'Run scripts/maintenance/CreateBaselineModelSheets.m first.'], ...
        sWorkbookBaseline, strjoin(missingSheets, ', '));
end

sScenario = 'Baseline';

% --- Run reference Baseline (dynare preprocessor + simulation) -------
fprintf('\n=== Running reference Baseline via dynare DGE_Model noclearall ===\n');
change_mod_file(sScenario, sSubsecstart, sSubsecend, sRegions, sSimulation, ...
    sExoNX, sCapandTrade, sClimRegional, sClimNational, sTargetBase);
dynare DGE_Model noclearall

%% ====================================================================
%  POST-DYNARE SNAPSHOT
%  ====================================================================
nSubsec = 5;
nReg    = 1;
nCand   = numel(candidateNames);

assert(numel(baselineSheetNames) == nCand && size(phiYT_deltas,1) == nCand, ...
    'baselineSheetNames, candidateNames and phiYT_deltas must all have the same number of rows.');

getParam = @(n) M_.params(ismember(M_.param_names, n));
inbregions_p   = getParam('inbregions_p');
inbsectors_p   = getParam('inbsectors_p');
lCapandTrade_p = getParam('lCapandTrade_p');
lEndoMig_p     = getParam('lEndoMig_p');
lEndogenousN_p = getParam('lEndogenousN_p');

params_backup  = M_.params;
oo_backup      = oo_;
options_backup = options_;

endoNames = cellstr(M_.endo_names);
ys_init   = oo_.endo_simul(:, 1);
nT        = size(oo_.endo_simul, 2);

% Read baseline phiYT from M_.params
phiYT_base = zeros(nSubsec, nReg);
for s = 1:nSubsec
    for r = 1:nReg
        idx = ismember(M_.param_names, sprintf('phiYT_%d_%d_p', s, r));
        if any(idx), phiYT_base(s, r) = M_.params(idx); end
    end
end

fprintf('\nBaseline phiYT_s_1: ');
fprintf('%7.4f', phiYT_base(:,1)'); fprintf('\n');

% Storage: full transition path and terminal SS per candidate
transPaths = zeros(M_.endo_nbr, nT, nCand);
terminalSS = zeros(M_.endo_nbr, nCand);

%% ====================================================================
%  CANDIDATE LOOP
%  ====================================================================
for isc = 1:nCand
    sName = candidateNames{isc};
    fprintf('\n====== %d/%d : %s ======\n', isc, nCand, sName);

    if abs(sum(phiYT_deltas(isc,:))) > 1e-10
        warning('"%s": phiYT_deltas row sums to %.4g (expected 0).', ...
            sName, sum(phiYT_deltas(isc,:)));
    end

    % Restore reference state
    M_.params = params_backup;
    oo_       = oo_backup;
    options_  = options_backup;

    % Patch phiY0, phiY, phiYT for this candidate
    for s = 1:nSubsec
        for r = 1:nReg
            newVal = phiYT_base(s, r) + phiYT_deltas(isc, s);
            for pname = {sprintf('phiY0_%d_%d_p', s, r), ...
                         sprintf('phiY_%d_%d_p',  s, r), ...
                         sprintf('phiYT_%d_%d_p', s, r)}
                idx = ismember(M_.param_names, pname{1});
                if any(idx), M_.params(idx) = newVal; end
            end
        end
    end

    sSensitivity    = ['ES_' sName '_'];
    sBaselineSheet  = baselineSheetNames{isc};

    % Re-run simulation with patched parameters and sheet
    run('simulation_model_refactored.m')

    transPaths(:, :, isc) = oo_.endo_simul;
    terminalSS(:, isc)    = oo_.endo_simul(:, end);

    fprintf('  -> done. Output: ExcelFiles/Output/%sBaseline.csv\n', sSensitivity);
end

% Restore reference state after all candidates
M_.params = params_backup;
oo_       = oo_backup;
options_  = options_backup;

%% ====================================================================
%  CONSOLE TABLE  —  K, N, Q at initial and terminal SS
%  ====================================================================
snames   = {'Primary','Fossil','RE','Secondary','Tertiary'};
getIdx   = @(nm) find(strcmp(endoNames, nm), 1);

fprintf('\n%s\n', repmat('=',1,88));
fprintf('Initial and Terminal Steady State  (terminal / initial ratio in brackets)\n');
fprintf('%s\n', repmat('=',1,88));

for vbase = {'K','N','Q'}
    b = vbase{1};
    switch b
        case 'K', hdr = 'Capital  K_{s,1}';
        case 'N', hdr = 'Employment  N_{s,1}';
        case 'Q', hdr = 'Output  Q_{s,1}';
    end
    fprintf('\n  %s\n', hdr);
    fprintf('  %-12s  %10s', 'Subsector', 'Initial SS');
    for iC = 1:nCand, fprintf('  %14s', candidateNames{iC}); end
    fprintf('\n  %s\n', repmat('-', 1, 14 + nCand*16));

    for s = 1:nSubsec
        ipos = getIdx(sprintf('%s_%d_1', b, s));
        if isempty(ipos)
            fprintf('  %-12s  (not found)\n', snames{s}); continue
        end
        v0 = ys_init(ipos);
        fprintf('  %-12s  %10.4f', snames{s}, v0);
        for iC = 1:nCand
            vT = terminalSS(ipos, iC);
            fprintf('  %7.4f (%5.2f)', vT, vT/max(abs(v0),1e-12));
        end
        fprintf('\n');
    end
end

% Aggregate rows
fprintf('\n  Aggregate\n');
fprintf('  %-12s  %10s', 'Variable', 'Initial SS');
for iC = 1:nCand, fprintf('  %14s', candidateNames{iC}); end
fprintf('\n  %s\n', repmat('-', 1, 14 + nCand*16));

iQ2 = getIdx('Q_2_1'); iQ3 = getIdx('Q_3_1');
for vn = {'Y_1','EE_1','Q_2_1','Q_3_1'}
    ipos = getIdx(vn{1});
    if isempty(ipos), continue; end
    v0 = ys_init(ipos);
    fprintf('  %-12s  %10.4f', vn{1}, v0);
    for iC = 1:nCand
        vT = terminalSS(ipos, iC);
        fprintf('  %7.4f (%5.2f)', vT, vT/max(abs(v0),1e-12));
    end
    fprintf('\n');
end

% RE share
if ~isempty(iQ2) && ~isempty(iQ3)
    v0 = ys_init(iQ3)/(ys_init(iQ2)+ys_init(iQ3))*100;
    fprintf('  %-12s  %9.2f%%', 'RE share', v0);
    for iC = 1:nCand
        q2 = terminalSS(iQ2,iC); q3 = terminalSS(iQ3,iC);
        vT = q3/(q2+q3)*100;
        fprintf('  %6.2f%% (%4.2f)', vT, vT/v0);
    end
    fprintf('\n');
end
fprintf('\n%s\n\n', repmat('=',1,88));

%% ====================================================================
%  FIGURE 1  —  Terminal SS bar chart: K, N, Q per candidate
%  ====================================================================
close all
set(groot,'defaultAxesFontSize',12,'defaultAxesFontName','Arial');
colInit = [0.6 0.6 0.6];
colCand = lines(nCand);

fig1 = figure('Name','End Shares: Initial vs Terminal SS', ...
    'NumberTitle','off','Position',[60 60 1300 920]);

varDef = {'K','Capital  K_{s,1}'; 'N','Employment  N_{s,1}'; 'Q','Output  Q_{s,1}'};

for ip = 1:size(varDef,1)
    b_char = varDef{ip,1};
    vals   = nan(nSubsec, 1+nCand);
    for s = 1:nSubsec
        ipos = getIdx(sprintf('%s_%d_1', b_char, s));
        if ~isempty(ipos)
            vals(s,1) = ys_init(ipos);
            for iC = 1:nCand
                vals(s,1+iC) = terminalSS(ipos,iC);
            end
        end
    end

    ax = subplot(3,1,ip);
    bh = bar(vals, 0.82);
    bh(1).FaceColor = colInit;
    for iC = 1:nCand, bh(1+iC).FaceColor = colCand(iC,:); end
    set(ax,'XTick',1:nSubsec,'XTickLabel',snames);
    title(varDef{ip,2}); ylabel('Level'); grid on;
    if ip == 1
        legend(['Initial SS', candidateNames], ...
            'Location','northoutside','Orientation','horizontal');
    end
end
sgtitle('End Share Candidates — Initial and Terminal Steady State', ...
    'FontSize',14,'FontWeight','bold');

%% ====================================================================
%  FIGURE 2  —  Transition paths: K, N, Q across candidates
%  ====================================================================
tAxis = 1:nT;

fig2 = figure('Name','End Shares: Transition Paths', ...
    'NumberTitle','off','Position',[80 80 1400 960]);

nVarPath = size(varDef,1);
nRows    = nVarPath;
nCols    = nSubsec;
iPl      = 0;

for ip = 1:nVarPath
    b_char = varDef{ip,1};
    for s = 1:nSubsec
        iPl  = iPl + 1;
        ipos = getIdx(sprintf('%s_%d_1', b_char, s));
        ax   = subplot(nRows, nCols, iPl);
        hold on; grid on;

        if ~isempty(ipos)
            for iC = 1:nCand
                plot(tAxis, squeeze(transPaths(ipos,:,iC)), ...
                    'Color', colCand(iC,:), 'LineWidth', 1.5);
            end
            yline(ys_init(ipos), '--', 'Color', colInit, 'LineWidth', 1);
        end

        if s == 1
            ylabel(b_char, 'FontWeight','bold');
        end
        if ip == 1
            title(snames{s});
        end
        if ip == nVarPath && s == ceil(nCols/2)
            legend(candidateNames, 'Location','south','Orientation','horizontal');
        end
    end
end

sgtitle('Transition Paths by End-Share Candidate  (dashed = initial SS)', ...
    'FontSize',14,'FontWeight','bold');
