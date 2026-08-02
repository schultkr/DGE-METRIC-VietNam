% create_green_finance_scenarios  Build PDP8_GF_* and NZ_GF_* scenario sheets.
%
% Run from the repository root:
%   run('scripts/maintenance/create_green_finance_scenarios.m')
%
% Writes a lean scenario sheet for each Green Finance scenario (A/B/C)
% into ModelScenarios5Sectorsand1Regions.xlsx.  Only the financing columns
% are written; all other paths (gY, gN, emissions, EE, ...) are inherited
% from the selected baseline via load_exogenous.m / apply_baseline_shock_structure.
%
% Columns per sheet (sector 3 = renewables, region 1):
%   Time              2 .. T
%   exo_r_G_3_1       WACF − rf0_p
%   exo_r_FDI_3_1     FDI-weighted rate − rf0_p
%   exo_lIGShare_3_1  1  (enable K_G/K share mode)
%   exo_sIGShare_3_1  public instrument share  (K_G = share × K)
%   exo_lFDIShare_3_1 1  (enable K_FDI/K share mode)
%   exo_sFDIShare_3_1 FDI instrument share     (K_FDI → sFDI × K)

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd   = pwd;
cleanupObj = onCleanup(@() cd(oldPwd));
cd(repoRoot);
setup_paths();

%% --- Parameters ----------------------------------------------------------
iSubsecRen = 3;
iReg       = 1;
sSuffix    = [num2str(iSubsecRen) '_' num2str(iReg)];  % '3_1'

% rf0_p = (1/beta_p) - 1 + deltaB_p
beta_p   = 0.97;
deltaB_p = 0.05;
rf0_p    = (1 / beta_p) - 1 + deltaB_p;

% Instrument rows in Assumptions sheet rows 7-13:
%   1=ODA, 2=MDB, 3=BlendedPub, 4=BlendedPriv, 5=SovereignBond,
%   6=CorpBond, 7=BankCredit
iPublicRows = [1, 2, 3, 5];  % → K_G
iFDIRows    = [4, 6];        % → K_FDI  (bank credit stays as K_H residual)

%% --- File paths ----------------------------------------------------------
gfWorkbook = fullfile(repoRoot, 'ExcelFiles', 'PDP8', ...
                      'Vietnam_Green_Finance_Scenarios_April2026.xlsx');
baselineWb = fullfile(repoRoot, 'ExcelFiles', ...
                      'ModelBaseline5Sectorsand1Regions.xlsx');
scenWb     = fullfile(repoRoot, 'ExcelFiles', ...
                      'ModelScenarios5Sectorsand1Regions.xlsx');

for f = {gfWorkbook, baselineWb, scenWb}
    if ~isfile(f{1})
        error('create_green_finance_scenarios:FileNotFound', ...
              'File not found:\n  %s', f{1});
    end
end

%% --- 1. Read GF Excel ----------------------------------------------------
fprintf('Reading Green Finance parameters...\n');

% Assumptions rows 7-13: cols B-D = shares (A/B/C), cols F-H = rates (A/B/C)
sharesRaw = readmatrix(gfWorkbook, 'Sheet', 'Assumptions', 'Range', 'B7:D13');
ratesRaw  = readmatrix(gfWorkbook, 'Sheet', 'Assumptions', 'Range', 'F7:H13');
wacfRaw   = readmatrix(gfWorkbook, 'Sheet', 'Assumptions', 'Range', 'B15:D15');

if numel(wacfRaw) < 3 || any(isnan(wacfRaw(1:3)))
    error('create_green_finance_scenarios:ReadError', ...
          'Cannot read WACF from Assumptions!B15:D15.');
end

kgShares  = sum(sharesRaw(iPublicRows, :), 1);   % 1×3
fdiShares = sum(sharesRaw(iFDIRows,    :), 1);   % 1×3
fdiRatesW = sum(sharesRaw(iFDIRows,:) .* ratesRaw(iFDIRows,:), 1) ...
           ./ max(sum(sharesRaw(iFDIRows,:), 1), 1e-12);
wacfValues = wacfRaw(1:3);

scenarioPrefixes = {'PDP8_GF', 'NZ_GF'};
labels           = {'Balanced', 'Market-led', 'Public-led'};
optionSuffixes   = {'A', 'B', 'C'};

fprintf('  rf0_p = %.4f%%\n', rf0_p * 100);
fprintf('  %-14s  WACF(%%)  exo_rG     sKGShare  sFDIShare\n', 'Scenario');
for i = 1:3
    fprintf('  %-14s  %6.3f   %+.5f  %.4f    %.4f\n', ...
        ['GF_' optionSuffixes{i}], wacfValues(i)*100, wacfValues(i)-rf0_p, ...
        kgShares(i), fdiShares(i));
end
fprintf('\n');

%% --- 2. Determine T from the Baseline sheet ------------------------------
timeCol = readmatrix(baselineWb, 'Sheet', 'Baseline', 'Range', 'A:A');
T       = numel(timeCol);
timeVec = (2:T)';   % scenario rows start at period 2
nSim    = T - 1;

fprintf('T = %d,  scenario rows: %d..%d\n\n', T, timeVec(1), timeVec(end));

%% --- 3. Write each scenario sheet ----------------------------------------
hdrs = { ...
    'Time', ...
    ['exo_r_G_'       sSuffix], ...
    ['exo_r_FDI_'     sSuffix], ...
    ['exo_lIGShare_'  sSuffix], ...
    ['exo_sIGShare_'  sSuffix], ...
    ['exo_lFDIShare_' sSuffix], ...
    ['exo_sFDIShare_' sSuffix], ...
    'exo_CapTrade_1',...
};

writtenSheets = {};
for iPrefix = 1:numel(scenarioPrefixes)
    sPrefix = scenarioPrefixes{iPrefix};

    for i = 1:3
        sName = [sPrefix '_' optionSuffixes{i}];

        mat = [ ...
            timeVec, ...
            repmat(wacfValues(i) - rf0_p,  nSim, 1), ...
            repmat(fdiRatesW(i)  - rf0_p,  nSim, 1), ...
            [ones(nSim-1, 1);0], ...
            repmat(kgShares(i),  nSim, 1), ...
            [ones(nSim-1, 1);0], ...
            repmat(fdiShares(i), nSim, 1), ...
            repmat(1, nSim, 1), ...
        ];

        writecell(hdrs, scenWb, 'Sheet', sName, 'Range', 'A1');
        writematrix(mat, scenWb, 'Sheet', sName, 'Range', 'A2');
        writtenSheets{end+1} = sName; %#ok<AGROW>

        fprintf('Written %s (%s): exo_rG=%+.5f  sKG=%.4f  sFDI=%.4f\n', ...
            sName, labels{i}, wacfValues(i)-rf0_p, kgShares(i), fdiShares(i));
    end
end

fprintf('\nDone.  Sheets: %s\n', strjoin(writtenSheets, ', '));
fprintf('Next: uncomment PDP8_GF_A/B/C and NZ_GF_A/B/C in RunSimulations.m and run.\n');
