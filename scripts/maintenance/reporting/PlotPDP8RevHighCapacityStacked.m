%% PlotPDP8RevHighCapacityStacked.m
%  Stacked installed-capacity plots for the PDP8_rev_high capacity pathway.
%
%  Data source:
%    ExcelFiles/PDP8/Capacity_Inter.csv

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd));
cd(repoRoot);

planName = "PDP8_rev_high";
yearRange = [2025, 2050];

csvFile = fullfile(repoRoot, 'ExcelFiles', 'PDP8', 'Capacity_Inter.csv');
outDir  = fullfile(repoRoot, 'Figures', 'PDP8');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

raw = readtable(csvFile, 'TreatAsEmpty', {'NA'}, 'TextType', 'string');
raw.Technology = string(raw.Technology);
raw.Plan       = string(raw.Plan);

if ~isnumeric(raw.Capacity_MW)
    raw.Capacity_MW = str2double(string(raw.Capacity_MW));
end

if ~ismember(planName, unique(raw.Plan))
    error('PlotPDP8RevHighCapacityStacked:missingPlan', ...
          'Plan "%s" not found in %s.', planName, csvFile);
end

raw = raw(raw.Plan == planName & ...
          raw.Year >= yearRange(1) & raw.Year <= yearRange(2), :);

% Component technologies only. Aggregate/trade rows are intentionally left
% out: Coal, Coal_conv_biomassNH3, TOTAL, Total capacity, Import, Export,
% and Pumped_storagehydro_BESS.
fossilTechs = [
    "Coal_PVC"
    "Coal_CFB"
    "Coal_conv_biomassNH3_PVC"
    "Coal_conv_biomassNH3_CFB"
    "Gas"
    "LNG"
    "LNG_CCS"
    "LNG_GH2"
    "LNG_H2"
    "GAS_H2"
    "Nuclear"
];

renewableTechs = [
    "PV"
    "Wind"
    "Wind_offshore"
    "Hydro"
    "Pumped_Hydro"
    "Biomass"
    "Bioenergy"
    "Batteries"
];

[years, fossilGW, fossilLabels] = capacity_matrix(raw, fossilTechs);
[~,     renewGW,  renewLabels]  = capacity_matrix(raw, renewableTechs);

set(groot, 'defaultAxesFontSize', 12, ...
           'defaultTextFontSize', 12, ...
           'defaultLegendFontSize', 10, ...
           'defaultAxesFontName', 'Arial');

fig = figure('Name', 'PDP8_rev_high installed capacity by technology', ...
             'NumberTitle', 'off', 'Color', 'w', ...
             'Position', [70 70 1200 780]);
tlo = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile(tlo);
plot_stacked_capacity(ax1, years, fossilGW, fossilLabels, ...
    'Fossil and non-renewable technologies');

ax2 = nexttile(tlo);
plot_stacked_capacity(ax2, years, renewGW, renewLabels, ...
    'Renewable and storage technologies');

sgtitle(tlo, sprintf('%s installed capacity by technology (%d-%d)', ...
    planName, yearRange(1), yearRange(2)), ...
    'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'none');

outPng = fullfile(outDir, 'PDP8_rev_high_installed_capacity_stacked.png');
outPdf = fullfile(outDir, 'PDP8_rev_high_installed_capacity_stacked.pdf');
exportgraphics(fig, outPng, 'Resolution', 300);
exportgraphics(fig, outPdf, 'ContentType', 'vector');

fprintf('Saved stacked capacity plot:\n  %s\n  %s\n', outPng, outPdf);

%% Recompute and save IndexedTrajectories_FossilRenewable_Capacity.csv
rawFull = readtable(csvFile, 'TreatAsEmpty', {'NA'}, 'TextType', 'string');
rawFull.Technology = string(rawFull.Technology);
rawFull.Plan       = string(rawFull.Plan);
if ~isnumeric(rawFull.Capacity_MW)
    rawFull.Capacity_MW = str2double(string(rawFull.Capacity_MW));
end
rawFull = rawFull(rawFull.Plan == planName, :);

[allYears, fossilGW_all] = capacity_matrix(rawFull, fossilTechs);
[~,        renewGW_all]  = capacity_matrix(rawFull, renewableTechs);

fossilMW = sum(fossilGW_all, 2) * 1000;
renewMW  = sum(renewGW_all,  2) * 1000;

baseIdx    = allYears == 2025;
fossilBase = fossilMW(baseIdx);
renewBase  = renewMW(baseIdx);

nYrs = numel(allYears);
T = table( ...
    [allYears; allYears], ...
    [repmat("Fossil", nYrs, 1); repmat("Renewable", nYrs, 1)], ...
    [fossilMW; renewMW], ...
    [repmat(fossilBase, nYrs, 1); repmat(renewBase, nYrs, 1)], ...
    [fossilMW ./ fossilBase * 100; renewMW ./ renewBase * 100], ...
    'VariableNames', {'Year','TechType','Total_Capacity_MW','Base_Capacity','Index_Value'});

outCSV = fullfile(repoRoot, 'ExcelFiles', 'PDP8', 'IndexedTrajectories_FossilRenewable_Capacity.csv');
writetable(T, outCSV);
fprintf('Saved indexed trajectories CSV:\n  %s\n', outCSV);

function [years, valuesGW, labels] = capacity_matrix(data, techs)
    years = sort(unique(data.Year));
    valuesGW = zeros(numel(years), numel(techs));

    for it = 1:numel(techs)
        techMask = data.Technology == techs(it);
        for iy = 1:numel(years)
            yearMask = data.Year == years(iy);
            valuesGW(iy, it) = sum(data.Capacity_MW(techMask & yearMask), 'omitnan') / 1000;
        end
    end

    keep = any(valuesGW > 0, 1);
    valuesGW = valuesGW(:, keep);
    labels = techs(keep);
end

function plot_stacked_capacity(ax, years, valuesGW, labels, plotTitle)
    axes(ax); %#ok<LAXES>
    area(years, valuesGW, 'LineStyle', 'none');
    hold(ax, 'on');
    plot(ax, years, sum(valuesGW, 2), 'k-', 'LineWidth', 1.2, ...
         'DisplayName', 'Total');
    hold(ax, 'off');

    xlim(ax, [years(1), years(end)]);
    ylabel(ax, 'Installed capacity (GW)');
    title(ax, plotTitle, 'Interpreter', 'none');
    grid(ax, 'on');
    box(ax, 'off');

    lgd = legend(ax, [labels; "Total"], 'Location', 'eastoutside');
    lgd.Interpreter = 'none';
end
