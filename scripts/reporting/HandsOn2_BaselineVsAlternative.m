%% Hands-on 2: Baseline vs Alternative Runs (participant exercise, ~40 min)
% Tasks covered by this script:
%   1) Implement one assigned scenario (set SCENARIO_NAME below)
%   2) Compare baseline and scenario with identical year window
%   3) Export core outputs for comparison
%   4) Prepare one chart and one policy interpretation template

close all;

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

%% ---------------------- Participant Configuration ----------------------
BASELINE_NAME = "Baseline";

% Replace with your assigned scenario (must match ExcelFiles/Output/<name>.csv)
SCENARIO_NAME = "PDP8_GF_C";
SCENARIO_LABEL = "Assigned Scenario";

PLOT_START_YEAR = 2025;
PLOT_END_YEAR   = 2050;

% Core outputs exported to CSV for comparison
coreSpecs = table( ...
    ["Y_1"; "C_1"; "I_1"; "E_1"; "PE_1"], ...
    ["GDP"; "Consumption"; "Investment"; "Emissions"; "Emission price"], ...
    'VariableNames', {'Variable', 'Label'});

% One chart required by exercise
CHART_VARIABLE = "Y_1";      % Example: "Y_1", "E_1", "I_1"
CHART_LABEL    = "GDP";
CHART_MODE     = "index";    % "index" | "level" | "pct_deviation" | "difference"

% One policy interpretation file required by exercise
POLICY_FOCUS_VARIABLE = "E_1";
POLICY_FOCUS_LABEL    = "Emissions";

%% ---------------------------- Load Outputs -----------------------------
baselineCsv = fullfile(repoRoot, 'ExcelFiles', 'Output', BASELINE_NAME + ".csv");
scenarioCsv = fullfile(repoRoot, 'ExcelFiles', 'Output', SCENARIO_NAME + ".csv");

if ~isfile(baselineCsv)
    error('HandsOn2:missingBaseline', 'Missing baseline CSV: %s', baselineCsv);
end
if ~isfile(scenarioCsv)
    error('HandsOn2:missingScenario', ...
        'Missing scenario CSV for "%s": %s', SCENARIO_NAME, scenarioCsv);
end

baseline = readtable(baselineCsv);
scenario = readtable(scenarioCsv);

requiredVars = unique(["Year"; coreSpecs.Variable; CHART_VARIABLE; POLICY_FOCUS_VARIABLE], 'stable');
require_vars(baseline, requiredVars, 'baseline data');
require_vars(scenario, requiredVars, char(SCENARIO_NAME) + " data");

%% ----------------------- Align Time Window Fairly ----------------------
commonYears = intersect(baseline.Year(:), scenario.Year(:));
commonYears = commonYears(commonYears >= PLOT_START_YEAR & commonYears <= PLOT_END_YEAR);
commonYears = sort(commonYears(:));

if isempty(commonYears)
    error('HandsOn2:noCommonYears', ...
        'No overlapping years in [%d, %d] between baseline and scenario.', ...
        PLOT_START_YEAR, PLOT_END_YEAR);
end

baseline = sortrows(baseline(ismember(baseline.Year, commonYears), :), 'Year');
scenario = sortrows(scenario(ismember(scenario.Year, commonYears), :), 'Year');
years = baseline.Year(:);

%% ---------------------------- Export Tables ----------------------------
outDir = fullfile(repoRoot, 'Figures', 'ScenarioComparisons', 'HandsOn2', char(SCENARIO_NAME));
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

coreTable = table(years, 'VariableNames', {'Year'});
for i = 1:height(coreSpecs)
    varName = string(coreSpecs.Variable(i));
    varStem = matlab.lang.makeValidName(char(varName));

    baseVals = baseline.(char(varName));
    scenVals = scenario.(char(varName));
    pctDev = safe_divide(scenVals, baseVals) .* 100 - 100;
    absDiff = scenVals - baseVals;

    coreTable.([varStem '_Baseline']) = baseVals;
    coreTable.([varStem '_Scenario']) = scenVals;
    coreTable.([varStem '_PctDeviation']) = pctDev;
    coreTable.([varStem '_Difference']) = absDiff;
end

coreCsv = fullfile(outDir, 'core_outputs_comparison.csv');
writetable(coreTable, coreCsv);

summaryTxt = fullfile(outDir, 'exercise_summary.txt');
fid = fopen(summaryTxt, 'w');
if fid < 0
    error('HandsOn2:fileWriteFailed', 'Could not create summary text file: %s', summaryTxt);
end
cleanupSummary = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, 'Hands-on 2 baseline-vs-scenario summary\n');
fprintf(fid, 'Baseline: %s\n', BASELINE_NAME);
fprintf(fid, 'Scenario: %s (%s)\n', SCENARIO_NAME, SCENARIO_LABEL);
fprintf(fid, 'Years compared: %d-%d\n', years(1), years(end));
fprintf(fid, 'Core output table: %s\n', coreCsv);

%% ---------------------------- One Figure -------------------------------
baseChart = baseline.(char(CHART_VARIABLE));
scenChart = scenario.(char(CHART_VARIABLE));

yBase = compute_transform_series(baseChart, baseChart, CHART_MODE);
yScen = compute_transform_series(scenChart, baseChart, CHART_MODE);

fig = figure('Name', 'Hands-on 2 chart', 'NumberTitle', 'off', ...
    'Color', 'w', 'Position', [100 100 900 540]);
ax = axes('Parent', fig);
plot(ax, years, yBase, '-', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.9, ...
    'DisplayName', char(BASELINE_NAME));
hold(ax, 'on');
plot(ax, years, yScen, '-', 'Color', [0.00 0.45 0.70], 'LineWidth', 1.9, ...
    'DisplayName', char(SCENARIO_LABEL));
if CHART_MODE == "pct_deviation" || CHART_MODE == "difference"
    yline(ax, 0, ':', 'Color', [0.45 0.45 0.45], 'HandleVisibility', 'off');
end
hold(ax, 'off');

grid(ax, 'on');
box(ax, 'off');
xlabel(ax, 'Year');
ylabel(ax, build_transform_ylabel(CHART_MODE, years(1)));
title(ax, sprintf('%s: Baseline vs %s', CHART_LABEL, SCENARIO_LABEL), 'Interpreter', 'none');
legend(ax, 'Location', 'best', 'Box', 'off', 'Interpreter', 'none');

chartStem = "hands_on2_chart_" + sanitize_filename(CHART_VARIABLE) + "_" + sanitize_filename(CHART_MODE);
chartPng = fullfile(outDir, char(chartStem + ".png"));
exportgraphics(fig, chartPng, 'Resolution', 300);
close(fig);

%% ---------------------- Policy Interpretation Draft --------------------
focusBase = baseline.(char(POLICY_FOCUS_VARIABLE));
focusScen = scenario.(char(POLICY_FOCUS_VARIABLE));
focusPct = safe_divide(focusScen, focusBase) .* 100 - 100;

gdpBase = baseline.Y_1;
gdpScen = scenario.Y_1;
gdpPct = safe_divide(gdpScen, gdpBase) .* 100 - 100;

finalYear = years(end);
idxFinal = numel(years);

policyMd = fullfile(outDir, 'policy_interpretation_template.md');
fid = fopen(policyMd, 'w');
if fid < 0
    error('HandsOn2:fileWriteFailed', 'Could not create policy template: %s', policyMd);
end
cleanupPolicy = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Hands-on 2 Policy Interpretation\n\n');
fprintf(fid, '- Baseline: **%s**\n', BASELINE_NAME);
fprintf(fid, '- Scenario: **%s** (%s)\n', SCENARIO_NAME, SCENARIO_LABEL);
fprintf(fid, '- Time window: **%d-%d**\n', years(1), years(end));
fprintf(fid, '- Chart file: `%s`\n', chartPng);
fprintf(fid, '- Core outputs file: `%s`\n\n', coreCsv);

fprintf(fid, '## Quick Evidence (auto-generated)\n\n');
fprintf(fid, '- In %d, %s is %.2f%%%% vs baseline.\n', finalYear, POLICY_FOCUS_LABEL, focusPct(idxFinal));
fprintf(fid, '- In %d, GDP is %.2f%%%% vs baseline.\n', finalYear, gdpPct(idxFinal));
fprintf(fid, '- Average GDP deviation over %d-%d is %.2f percentage points.\n\n', ...
    years(1), years(end), mean(gdpPct, 'omitnan'));

fprintf(fid, '## Your 3-5 Sentence Interpretation\n\n');
fprintf(fid, '1. State the policy objective of the assigned scenario.\n');
fprintf(fid, '2. Use the chart to describe the macro pathway vs baseline.\n');
fprintf(fid, '3. Explain the trade-off between GDP and %s.\n', POLICY_FOCUS_LABEL);
fprintf(fid, '4. Add one implementation caveat (timing, financing, or technology constraints).\n\n');
fprintf(fid, '## One-Sentence Recommendation\n\n');
fprintf(fid, '> [Write your policy recommendation here.]\n');

%% -------------------------- Console Checklist --------------------------
fprintf('\nHands-on 2 complete for scenario: %s\n', SCENARIO_NAME);
fprintf('1) Scenario implemented: %s\n', scenarioCsv);
fprintf('2) Baseline/scenario compared on identical years: %d-%d\n', years(1), years(end));
fprintf('3) Core outputs exported: %s\n', coreCsv);
fprintf('4) One chart exported: %s\n', chartPng);
fprintf('5) Policy interpretation template: %s\n\n', policyMd);

%% Local functions
function require_vars(data, vars, dataName)
    vars = cellstr(string(vars));
    missing = vars(~ismember(vars, data.Properties.VariableNames));
    if ~isempty(missing)
        error('HandsOn2:missingVariables', ...
            'Missing required variable(s) in %s: %s', ...
            dataName, strjoin(missing, ', '));
    end
end

function values = compute_transform_series(seriesValues, baselineValues, mode)
    mode = lower(string(mode));
    switch mode
        case "index"
            values = safe_divide(seriesValues, seriesValues(1)) .* 100;
        case "level"
            values = seriesValues;
        case "pct_deviation"
            values = safe_divide(seriesValues, baselineValues) .* 100 - 100;
        case "difference"
            values = seriesValues - baselineValues;
        otherwise
            error('HandsOn2:badChartMode', ...
                'Unsupported CHART_MODE "%s". Use index|level|pct_deviation|difference.', mode);
    end
end

function y = safe_divide(num, den)
    y = num ./ den;
    y(den == 0 | isnan(num) | isnan(den)) = NaN;
end

function yLabel = build_transform_ylabel(mode, baseYear)
    mode = lower(string(mode));
    switch mode
        case "index"
            yLabel = sprintf('Index (%d = 100)', baseYear);
        case "level"
            yLabel = 'Level';
        case "pct_deviation"
            yLabel = '% deviation from baseline';
        case "difference"
            yLabel = 'Scenario - Baseline';
        otherwise
            yLabel = 'Value';
    end
end

function out = sanitize_filename(value)
    out = lower(string(value));
    out = regexprep(out, '[^A-Za-z0-9]+', '_');
    out = regexprep(out, '^_+|_+$', '');
    if strlength(out) == 0
        out = "plot";
    end
end