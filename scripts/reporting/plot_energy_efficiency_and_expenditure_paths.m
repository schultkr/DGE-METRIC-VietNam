%% Compare energy efficiency and cumulative expenditure paths across Baseline and EE scenarios
% This script reads the output CSVs written by the model and plots:
%   1) sectoral energy-efficiency paths A_I_4_1_2 and A_I_5_1_2
%   2) cumulative expenditure / adaptation-cost paths G_A_4_1, G_A_5_1, and G_A_3_1
%
% Typical usage:
%   run('scripts/reporting/plot_energy_efficiency_and_expenditure_paths.m')
%
% Output saved under:
%   Figures/EE/

close all;
clearvars;
clc;

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

% -------------------------------------------------------------------------
% User configuration
% -------------------------------------------------------------------------
scenarioNames = {'EE_Dir10_full', 'EE_Dir10_RTSslice'};
scenarioLabels = {'Directive 10 (full)', 'Directive 10 rooftop slice'};

outputDir = fullfile(repoRoot, 'Figures', 'EE');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% -------------------------------------------------------------------------
% Load baseline and selected scenarios
% -------------------------------------------------------------------------
sversion = report_version_suffix();  % "" unless DGE_WORKBOOK_VERSION overrides
baseFile = fullfile(repoRoot, 'ExcelFiles', 'Output', ['Baseline' sversion '.csv']);
if ~isfile(baseFile)
    error('Baseline CSV not found: %s', baseFile);
end
baseline = readtable(baseFile);

datasets = struct('Baseline', baseline);
for i = 1:numel(scenarioNames)
    f = fullfile(repoRoot, 'ExcelFiles', 'Output', [scenarioNames{i} sversion '.csv']);
    if ~isfile(f)
        warning('Skipping missing scenario CSV: %s', f);
        continue;
    end
    datasets.(scenarioNames{i}) = readtable(f);
end

% Use common years across all loaded series.
allYears = baseline.Year(:);
fnames = fieldnames(datasets);
for i = 1:numel(fnames)
    ds = datasets.(fnames{i});
    if isfield(ds, 'Year')
        allYears = intersect(allYears, ds.Year(:));
    end
end
allYears = sort(allYears);

% Filter to same years and keep 2025 onward.
allYears = allYears(allYears >= 2025);

for i = 1:numel(fnames)
    ds = datasets.(fnames{i});
    datasets.(fnames{i}) = sortrows(ds(ismember(ds.Year, allYears), :), 'Year');
end

% -------------------------------------------------------------------------
% 1) Energy efficiency by sector: A_I_4_1_2 and A_I_5_1_2
% -------------------------------------------------------------------------
fig = figure('Color', 'w', 'Position', [100 100 1200 700]);
ax = axes('Parent', fig);
hold(ax, 'on');

baseAI4 = get_series(datasets.Baseline, 'A_I_4_1_2');
baseAI5 = get_series(datasets.Baseline, 'A_I_5_1_2');

plot(ax, datasets.Baseline.Year, index_to_base(baseAI4, baseAI4(1)), 'k-', 'LineWidth', 2.2, 'DisplayName', 'Baseline industry');
plot(ax, datasets.Baseline.Year, index_to_base(baseAI5, baseAI5(1)), 'k--', 'LineWidth', 2.2, 'DisplayName', 'Baseline services');

colors = lines(numel(scenarioNames)+2);
for i = 1:numel(scenarioNames)
    sname = scenarioNames{i};
    ds = datasets.(sname);
    ai4 = get_series(ds, 'A_I_4_1_2');
    ai5 = get_series(ds, 'A_I_5_1_2');

    plot(ax, ds.Year, index_to_base(ai4, baseAI4(1)), 'Color', colors(i,:), 'LineWidth', 1.8, 'DisplayName', [scenarioLabels{i} ' industry']);
    plot(ax, ds.Year, index_to_base(ai5, baseAI5(1)), 'Color', colors(i,:), 'LineStyle', '--', 'LineWidth', 1.8, 'DisplayName', [scenarioLabels{i} ' services']);
end

ylabel(ax, {'Energy-efficiency evolution by sector', 'Index (Baseline 2025 = 100)'});
grid(ax, 'on');
legend(ax, 'Location', 'best', 'Interpreter', 'none', 'Box', 'off');

saveas(fig, fullfile(outputDir, 'energy_efficiency_by_sector.png'));
saveas(fig, fullfile(outputDir, 'energy_efficiency_by_sector.fig'));

% -------------------------------------------------------------------------
% 2) Cumulative expenditure / cost stock by sector and BESS
% -------------------------------------------------------------------------
fig2 = figure('Color', 'w', 'Position', [100 100 1200 700]);
ax2 = axes('Parent', fig2);
hold(ax2, 'on');

baseGA4 = get_series(datasets.Baseline, 'G_A_4_1');
baseGA5 = get_series(datasets.Baseline, 'G_A_5_1');
baseGA3 = get_series(datasets.Baseline, 'G_A_3_1');

plot(ax2, datasets.Baseline.Year, baseGA4, 'k-', 'LineWidth', 2.2, 'DisplayName', 'Baseline industry cumulative cost');
plot(ax2, datasets.Baseline.Year, baseGA5, 'k--', 'LineWidth', 2.2, 'DisplayName', 'Baseline services cumulative cost');
plot(ax2, datasets.Baseline.Year, baseGA3, 'k:', 'LineWidth', 2.2, 'DisplayName', 'Baseline BESS cumulative cost');

for i = 1:numel(scenarioNames)
    sname = scenarioNames{i};
    ds = datasets.(sname);
    ga4 = get_series(ds, 'G_A_4_1');
    ga5 = get_series(ds, 'G_A_5_1');
    ga3 = get_series(ds, 'G_A_3_1');

    plot(ax2, ds.Year, ga4, 'Color', colors(i,:), 'LineWidth', 1.8, 'DisplayName', [scenarioLabels{i} ' industry']);
    plot(ax2, ds.Year, ga5, 'Color', colors(i,:), 'LineStyle', '--', 'LineWidth', 1.8, 'DisplayName', [scenarioLabels{i} ' services']);
    plot(ax2, ds.Year, ga3, 'Color', colors(i,:), 'LineStyle', ':', 'LineWidth', 1.8, 'DisplayName', [scenarioLabels{i} ' BESS']);
end

ylabel(ax2, {'Cumulative expenditure paths', 'Cumulative expenditure / adaptation-capital stock'});
grid(ax2, 'on');
legend(ax2, 'Location', 'best', 'Interpreter', 'none', 'Box', 'off');

saveas(fig2, fullfile(outputDir, 'cumulative_expenditure_paths.png'));
saveas(fig2, fullfile(outputDir, 'cumulative_expenditure_paths.fig'));

fprintf('Saved EE comparison figures to: %s\n', outputDir);

function value = get_series(ds, varName)
    if ismember(varName, ds.Properties.VariableNames)
        value = ds.(varName);
    else
        error('Variable %s not found in output table.', varName);
    end
end

function y = index_to_base(x, x0)
    y = x ./ x0 * 100;
end
