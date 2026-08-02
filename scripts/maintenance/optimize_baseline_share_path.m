% optimize_baseline_share_path  Outer search for a low-wedge baseline share path.
%
% This is an optional maintenance utility for evaluating Baseline_* variants;
% it is not part of the canonical single-Baseline run flow.
%
% This script searches over the common fossil/renewable VA-share
% interpolation speed used by create_baseline_share_candidates.m between
% user-entered anchor years. For each round it:
%   1. Creates Baseline_FR_gXXX sheets for the current gamma grid.
%   2. Runs RunSimulations.m on those sheets only.
%   3. Reads ExcelFiles/Output/BaselineCandidateScores.csv.
%   4. Refines the gamma grid around the feasible candidate with the lowest
%      max(abs(A_INV)).
%
% Anchor-year VA shares are inherited from the source input sheet:
%   2030, 2035, 2040, 2045, and 2050 by default.
% Services/tertiary (subsector 5) is passed as the residual sector by
% default, so primary and secondary shares remain on their source paths.
%
% Run from repository root:
%   run('scripts/maintenance/optimize_baseline_share_path.m')
%
% Optional environment overrides:
%   DGE_BASELINE_OPT_GAMMAS="0.4,0.8,1,1.8,3"
%   DGE_BASELINE_OPT_ANCHOR_YEARS="2030,2035,2040,2045,2050"
%   DGE_BASELINE_OPT_ROUNDS="3"
%   DGE_BASELINE_OPT_POINTS="5"
%   DGE_BASELINE_OPT_RESIDUAL_SUBSECTOR="5"
%   DGE_BASELINE_GDP_TOL="1e-6"

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

%% Search configuration

initialGammaGrid = [0.35, 0.50, 0.75, 1.00, 1.50, 2.00, 3.00];
nRefinementRounds = 2;
nPointsPerRefinement = 5;
gammaLowerBound = 0.10;
gammaUpperBound = 5.00;
growthTolerance = 1e-6;
includeSmoothCandidate = false;
includeBaselineBenchmark = false;
candidatePrefix = 'Baseline_FR';
residualSubsector = 5;
interpolationAnchorYears = [2030, 2035, 2040, 2045, 2050];

envGrid = strtrim(getenv('DGE_BASELINE_OPT_GAMMAS'));
if ~isempty(envGrid)
    initialGammaGrid = parse_positive_numeric_list(envGrid, 'DGE_BASELINE_OPT_GAMMAS');
end

envAnchorYears = strtrim(getenv('DGE_BASELINE_OPT_ANCHOR_YEARS'));
if ~isempty(envAnchorYears)
    interpolationAnchorYears = parse_positive_numeric_list(envAnchorYears, 'DGE_BASELINE_OPT_ANCHOR_YEARS');
end

envRounds = strtrim(getenv('DGE_BASELINE_OPT_ROUNDS'));
if ~isempty(envRounds)
    nRefinementRounds = parse_positive_integer(envRounds, 'DGE_BASELINE_OPT_ROUNDS');
end

envPoints = strtrim(getenv('DGE_BASELINE_OPT_POINTS'));
if ~isempty(envPoints)
    nPointsPerRefinement = max(3, parse_positive_integer(envPoints, 'DGE_BASELINE_OPT_POINTS'));
end

envResidualSubsector = strtrim(getenv('DGE_BASELINE_OPT_RESIDUAL_SUBSECTOR'));
if ~isempty(envResidualSubsector)
    residualSubsector = parse_positive_integer(envResidualSubsector, 'DGE_BASELINE_OPT_RESIDUAL_SUBSECTOR');
end

envTol = strtrim(getenv('DGE_BASELINE_GDP_TOL'));
if ~isempty(envTol)
    growthTolerance = str2double(envTol);
    if ~isfinite(growthTolerance) || growthTolerance < 0
        error('optimize_baseline_share_path:InvalidGrowthTolerance', ...
            'DGE_BASELINE_GDP_TOL must be a non-negative numeric tolerance.');
    end
end

envIncludeSmooth = lower(strtrim(getenv('DGE_BASELINE_OPT_INCLUDE_SMOOTH')));
if any(strcmp(envIncludeSmooth, {'1', 'true', 'yes'}))
    includeSmoothCandidate = true;
elseif any(strcmp(envIncludeSmooth, {'0', 'false', 'no'}))
    includeSmoothCandidate = false;
end

envIncludeBaseline = lower(strtrim(getenv('DGE_BASELINE_OPT_INCLUDE_BASELINE')));
if any(strcmp(envIncludeBaseline, {'1', 'true', 'yes'}))
    includeBaselineBenchmark = true;
elseif any(strcmp(envIncludeBaseline, {'0', 'false', 'no'}))
    includeBaselineBenchmark = false;
end

initialGammaGrid = normalize_gamma_grid(initialGammaGrid, gammaLowerBound, gammaUpperBound);

%% Run coarse-to-fine search

allScores = table();
gammaGrid = initialGammaGrid;
refreshMainBaseline = true;
bestOverall = table();

totalRounds = 1 + nRefinementRounds;
for iRound = 1:totalRounds
    fprintf('\n=== Baseline share-path optimization round %d of %d ===\n', iRound, totalRounds);
    fprintf('Gamma grid: %s\n', gamma_list_string(gammaGrid));
    fprintf('Anchor years: %s\n', numeric_list_string(interpolationAnchorYears));

    roundScores = run_gamma_round(gammaGrid, iRound, refreshMainBaseline, ...
        includeSmoothCandidate, includeBaselineBenchmark, candidatePrefix, ...
        residualSubsector, interpolationAnchorYears, growthTolerance);
    allScores = [allScores; roundScores]; %#ok<AGROW>

    roundBest = select_best_feasible(roundScores);
    if isempty(roundBest)
        write_optimization_scores(repoRoot, allScores);
        error('optimize_baseline_share_path:NoFeasibleCandidate', ...
            ['No feasible candidate found in round %d. Check BaselineCandidateScores.csv ' ...
             'or relax DGE_BASELINE_GDP_TOL.'], iRound);
    end

    bestOverall = select_best_feasible(allScores);
    fprintf('Round best: %s, gamma=%s, max(abs(muI))=%s, GDP diff=%s\n', ...
        char(roundBest.Sheet), format_metric(roundBest.CandidateGamma), ...
        format_metric(roundBest.MaxAbsMuI), format_metric(roundBest.MaxAbsGrowthDiff));

    if iRound < totalRounds
        gammaGrid = refine_gamma_grid(gammaGrid, roundBest.CandidateGamma, ...
            nPointsPerRefinement, gammaLowerBound, gammaUpperBound);
        refreshMainBaseline = false;
    end
end

scoreFile = write_optimization_scores(repoRoot, allScores);

fprintf('\nOptimizeBaselineSharePath complete.\n');
fprintf('  Best sheet: %s\n', char(bestOverall.Sheet));
fprintf('  Best gamma: %s\n', format_metric(bestOverall.CandidateGamma));
fprintf('  max(abs(muI)): %s\n', format_metric(bestOverall.MaxAbsMuI));
fprintf('  max GDP-growth diff: %s\n', format_metric(bestOverall.MaxAbsGrowthDiff));
fprintf('  Full optimization trace: %s\n', scoreFile);
fprintf('\nTo rerun only the winning baseline (maintenance sweep mode):\n');
fprintf('  setenv(''DGE_BASELINE_SHEETS'', ''%s'')\n', char(bestOverall.Sheet));
fprintf('  run(''RunSimulations.m'')\n');

%% Local functions

function roundScores = run_gamma_round(gammaGrid, iRound, refreshMainBaseline, ...
    includeSmoothCandidate, includeBaselineBenchmark, candidatePrefix, residualSubsector, ...
    interpolationAnchorYears, growthTolerance)

    candidateSheets = gamma_sheet_names(candidatePrefix, gammaGrid);
    if includeSmoothCandidate
        candidateSheets{end + 1} = safe_sheet_name([candidatePrefix '_smooth']); %#ok<AGROW>
    end
    runSheets = candidateSheets;
    if refreshMainBaseline || includeBaselineBenchmark
        runSheets = [{'Baseline'}, runSheets];
    end

    setenv('DGE_BASELINE_SHARE_GAMMAS', gamma_list_string(gammaGrid));
    setenv('DGE_BASELINE_CANDIDATE_PREFIX', candidatePrefix);
    setenv('DGE_BASELINE_ANCHOR_YEARS', numeric_list_string(interpolationAnchorYears));
    setenv('DGE_BASELINE_INCLUDE_SMOOTH', logical_string(includeSmoothCandidate));
    setenv('DGE_BASELINE_RESIDUAL_SUBSECTOR', num2str(residualSubsector));
    setenv('DGE_REFRESH_BASELINE_FIRST', logical_string(refreshMainBaseline));
    setenv('DGE_BASELINE_SHEETS', strjoin(runSheets, ','));
    setenv('DGE_BASELINE_GDP_TOL', num2str(growthTolerance, '%.16g'));
    setenv('DGE_SCENARIO_GROUPS', 'Reference');

    run_script_in_function('scripts/maintenance/create_baseline_share_candidates.m');
    run_script_in_function('RunSimulations.m');

    scorePath = fullfile('ExcelFiles', 'Output', 'BaselineCandidateScores.csv');
    if ~isfile(scorePath)
        error('optimize_baseline_share_path:MissingScoreFile', ...
            'Expected score file was not written:\n  %s', scorePath);
    end

    roundScores = read_table_preserve_names(scorePath);
    roundScores.Sheet = table_text_column(roundScores.Sheet);
    roundScores.SearchRound = repmat(iRound, height(roundScores), 1);
    roundScores.CandidateGamma = sheet_gamma_values(roundScores.Sheet, candidatePrefix);
    roundScores.IsOptimizationCandidate = ismember(roundScores.Sheet, string(candidateSheets));

    roundScores = movevars(roundScores, {'SearchRound', 'CandidateGamma', 'IsOptimizationCandidate'}, ...
        'After', 'Sheet');
end

function run_script_in_function(scriptPath)
    run(scriptPath);
end

function bestRow = select_best_feasible(scores)
    bestRow = table();
    if isempty(scores)
        return
    end

    solved = table_logical_column(scores.Solved);
    growthFeasible = table_logical_column(scores.GrowthFeasible);
    isCandidate = table_logical_column(scores.IsOptimizationCandidate);
    objective = scores.MaxAbsMuI;

    feasible = solved & growthFeasible & isCandidate & isfinite(objective);
    if ~any(feasible)
        return
    end

    feasibleIdx = find(feasible);
    [~, relIdx] = min(objective(feasibleIdx));
    bestRow = scores(feasibleIdx(relIdx), :);
end

function gammaGrid = refine_gamma_grid(previousGrid, bestGamma, nPoints, gammaLowerBound, gammaUpperBound)
    if ~isfinite(bestGamma)
        error('optimize_baseline_share_path:CannotRefineNonGammaCandidate', ...
            'The best candidate does not have a finite gamma, so a gamma refinement cannot continue.');
    end

    sortedGrid = sort(previousGrid(:)');
    [~, idxBest] = min(abs(sortedGrid - bestGamma));

    if idxBest > 1
        left = sortedGrid(idxBest - 1);
    else
        left = max(gammaLowerBound, bestGamma / 2);
    end

    if idxBest < numel(sortedGrid)
        right = sortedGrid(idxBest + 1);
    else
        right = min(gammaUpperBound, bestGamma * 2);
    end

    if left >= bestGamma
        left = max(gammaLowerBound, bestGamma * 0.75);
    end
    if right <= bestGamma
        right = min(gammaUpperBound, bestGamma * 1.25);
    end

    gammaGrid = normalize_gamma_grid([linspace(left, right, nPoints), bestGamma], ...
        gammaLowerBound, gammaUpperBound);
end

function scoreFile = write_optimization_scores(repoRoot, scores)
    outDir = fullfile(repoRoot, 'ExcelFiles', 'Output');
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    scoreFile = fullfile(outDir, 'BaselineSharePathOptimization.csv');
    writetable(scores, scoreFile);
end

function gammas = parse_positive_numeric_list(rawText, envName)
    parts = strsplit(char(rawText), ',');
    gammas = str2double(parts);
    gammas = gammas(isfinite(gammas) & gammas > 0);
    if isempty(gammas)
        error('optimize_baseline_share_path:InvalidNumericList', ...
            '%s must contain at least one positive numeric value.', envName);
    end
end

function value = parse_positive_integer(rawText, envName)
    value = str2double(rawText);
    if ~isfinite(value) || value < 1 || abs(value - round(value)) > 1e-10
        error('optimize_baseline_share_path:InvalidPositiveInteger', ...
            '%s must be a positive integer.', envName);
    end
    value = round(value);
end

function gammaGrid = normalize_gamma_grid(gammaGrid, gammaLowerBound, gammaUpperBound)
    gammaGrid = gammaGrid(:)';
    gammaGrid = gammaGrid(isfinite(gammaGrid) & gammaGrid > 0);
    gammaGrid = min(gammaUpperBound, max(gammaLowerBound, gammaGrid));
    gammaGrid = unique(round(gammaGrid, 6), 'stable');
    gammaGrid = sort(gammaGrid);
end

function sheets = gamma_sheet_names(prefix, gammaGrid)
    sheets = cell(numel(gammaGrid), 1);
    for i = 1:numel(gammaGrid)
        sheets{i} = safe_sheet_name([prefix '_' gamma_tag(gammaGrid(i))]);
    end
end

function gammas = sheet_gamma_values(sheetNames, prefix)
    gammas = nan(numel(sheetNames), 1);
    prefixPattern = regexptranslate('escape', [prefix '_g']);
    for i = 1:numel(sheetNames)
        token = regexp(char(sheetNames(i)), [prefixPattern '(\d+)$'], 'tokens', 'once');
        if ~isempty(token)
            gammas(i) = str2double(token{1}) / 100;
        end
    end
end

function tag = gamma_tag(gamma)
    tag = sprintf('g%03d', round(100 * gamma));
end

function name = safe_sheet_name(rawName)
    name = regexprep(char(rawName), '[:\\/\?\*\[\]]', '_');
    if numel(name) > 31
        name = name(1:31);
    end
end

function s = gamma_list_string(gammas)
    parts = arrayfun(@(x) num2str(x, '%.6g'), gammas(:)', 'UniformOutput', false);
    s = strjoin(parts, ',');
end

function s = numeric_list_string(values)
    parts = arrayfun(@(x) num2str(x, '%.12g'), values(:)', 'UniformOutput', false);
    s = strjoin(parts, ',');
end

function s = logical_string(value)
    if value
        s = 'true';
    else
        s = 'false';
    end
end

function tab = read_table_preserve_names(sFile, varargin)
    try
        tab = readtable(sFile, varargin{:}, 'PreserveVariableNames', true);
    catch
        try
            tab = readtable(sFile, varargin{:}, 'VariableNamingRule', 'preserve');
        catch
            tab = readtable(sFile, varargin{:});
        end
    end
end

function values = table_text_column(values)
    if iscell(values)
        values = string(values);
    elseif ischar(values)
        values = string(cellstr(values));
    else
        values = string(values);
    end
end

function values = table_logical_column(values)
    if islogical(values)
        values = values(:);
    elseif isnumeric(values)
        values = values(:) ~= 0;
    elseif iscell(values)
        values = strcmpi(string(values(:)), "true") | strcmp(string(values(:)), "1");
    else
        values = strcmpi(string(values(:)), "true") | strcmp(string(values(:)), "1");
    end
end

function s = format_metric(x)
    if isfinite(x)
        s = num2str(x, '%.6g');
    else
        s = 'NaN';
    end
end
