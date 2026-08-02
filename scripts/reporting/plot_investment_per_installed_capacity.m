%% plot_investment_per_installed_capacity.m
%  Annual investment divided by installed capacity for fossil and renewable
%  technologies in the PDP8 investment pathways.
%
%  Data source:
%    ExcelFiles/PDP8/Investment.csv
%
%  Outputs:
%    ExcelFiles/PDP8/InvestmentPerInstalledCapacity.xlsx
%    Figures/PDP8/investment_per_installed_capacity_<plan>.png
%    Figures/PDP8/investment_per_installed_capacity_<plan>.pdf

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd));
cd(repoRoot);

% ---- configuration ------------------------------------------------------
planToPlot = "PDP8_rev_high";
yearRange  = [2025, 2050];

csvFile = fullfile(repoRoot, 'ExcelFiles', 'PDP8', 'Investment.csv');
xlsFile = fullfile(repoRoot, 'ExcelFiles', 'PDP8', ...
    'InvestmentPerInstalledCapacity.xlsx');
outDir  = fullfile(repoRoot, 'Figures', 'PDP8');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

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

% ---- load ---------------------------------------------------------------
raw = readtable(csvFile, 'TreatAsEmpty', {'NA'}, 'TextType', 'string');
raw.Technology = string(raw.Technology);
raw.Plan       = string(raw.Plan);

raw = ensure_numeric(raw, ["Year", "Capacity_MW", "INV_MIOUSD"]);
raw = raw(raw.Year >= yearRange(1) & raw.Year <= yearRange(2), :);

if ~ismember(planToPlot, unique(raw.Plan))
    error('plot_investment_per_installed_capacity:missingPlan', ...
          'Plan "%s" not found in %s.', planToPlot, csvFile);
end

% ---- compute ------------------------------------------------------------
annual = aggregate_ratios(raw, fossilTechs, renewableTechs);
detail = technology_detail(raw, fossilTechs, renewableTechs);
mapping = technology_mapping(fossilTechs, renewableTechs);

% ---- write Excel workbook ----------------------------------------------
if exist(xlsFile, 'file')
    delete(xlsFile);
end
writetable(annual,  xlsFile, 'Sheet', 'AnnualRatios');
writetable(detail,  xlsFile, 'Sheet', 'TechnologyDetail');
writetable(mapping, xlsFile, 'Sheet', 'TechnologyGroups');

% ---- plot selected plan -------------------------------------------------
plotData = annual(annual.Plan == planToPlot, :);

set(groot, 'defaultAxesFontSize', 12, ...
           'defaultTextFontSize', 12, ...
           'defaultLegendFontSize', 10, ...
           'defaultAxesFontName', 'Arial');

fig = figure('Name', 'Investment per installed capacity', ...
             'NumberTitle', 'off', 'Color', 'w', ...
             'Position', [80 80 980 680]);
tlo = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile(tlo);
plot(ax1, plotData.Year, plotData.Fossil_Inv_per_Capacity_kUSD_per_MW, ...
    '-', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.8);
hold(ax1, 'on');
plot(ax1, plotData.Year, plotData.Renewable_Inv_per_Capacity_kUSD_per_MW, ...
    '-', 'Color', [0.20 0.45 0.75], 'LineWidth', 1.8);
hold(ax1, 'off');
grid(ax1, 'on');
box(ax1, 'off');
xlim(ax1, yearRange);
ylabel(ax1, 'kUSD / MW');
title(ax1, 'Annual investment / installed capacity', 'Interpreter', 'none');
legend(ax1, {'Fossil', 'Renewables'}, 'Location', 'northwest');

ax2 = nexttile(tlo);
plot(ax2, plotData.Year, plotData.Renewable_to_Fossil_Intensity_Ratio, ...
    'k-', 'LineWidth', 1.8);
yline(ax2, 1, ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.0);
grid(ax2, 'on');
box(ax2, 'off');
xlim(ax2, yearRange);
ylabel(ax2, 'Renewable / fossil');
xlabel(ax2, 'Year');
title(ax2, 'Relative investment intensity', 'Interpreter', 'none');

sgtitle(tlo, sprintf('%s investment intensity by installed capacity (%d-%d)', ...
    planToPlot, yearRange(1), yearRange(2)), ...
    'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'none');

plotStem = sprintf('investment_per_installed_capacity_%s', planToPlot);
outPng = fullfile(outDir, [plotStem '.png']);
outPdf = fullfile(outDir, [plotStem '.pdf']);
exportgraphics(fig, outPng, 'Resolution', 300);
exportgraphics(fig, outPdf, 'ContentType', 'vector');

fprintf('Saved investment/capacity workbook:\n  %s\n', xlsFile);
fprintf('Saved investment/capacity plots:\n  %s\n  %s\n', outPng, outPdf);

function data = ensure_numeric(data, vars)
    for iv = 1:numel(vars)
        v = char(vars(iv));
        if ~isnumeric(data.(v))
            data.(v) = str2double(string(data.(v)));
        end
    end
end

function annual = aggregate_ratios(data, fossilTechs, renewableTechs)
    plans = sort(unique(data.Plan));
    years = sort(unique(data.Year));

    nRows = numel(plans) * numel(years);
    Plan = strings(nRows, 1);
    Year = nan(nRows, 1);
    Fossil_Investment_MIOUSD = nan(nRows, 1);
    Renewable_Investment_MIOUSD = nan(nRows, 1);
    Fossil_Capacity_MW = nan(nRows, 1);
    Renewable_Capacity_MW = nan(nRows, 1);

    irow = 0;
    for ip = 1:numel(plans)
        for iy = 1:numel(years)
            irow = irow + 1;
            Plan(irow) = plans(ip);
            Year(irow) = years(iy);

            baseMask = data.Plan == plans(ip) & data.Year == years(iy);
            fossilMask = baseMask & ismember(data.Technology, fossilTechs);
            renewMask  = baseMask & ismember(data.Technology, renewableTechs);

            Fossil_Investment_MIOUSD(irow) = nan_sum_or_nan(data.INV_MIOUSD(fossilMask));
            Renewable_Investment_MIOUSD(irow) = nan_sum_or_nan(data.INV_MIOUSD(renewMask));
            Fossil_Capacity_MW(irow) = nan_sum_or_nan(data.Capacity_MW(fossilMask));
            Renewable_Capacity_MW(irow) = nan_sum_or_nan(data.Capacity_MW(renewMask));
        end
    end

    Fossil_Inv_per_Capacity_MIOUSD_per_MW = ...
        safe_divide(Fossil_Investment_MIOUSD, Fossil_Capacity_MW);
    Renewable_Inv_per_Capacity_MIOUSD_per_MW = ...
        safe_divide(Renewable_Investment_MIOUSD, Renewable_Capacity_MW);

    Fossil_Inv_per_Capacity_kUSD_per_MW = ...
        Fossil_Inv_per_Capacity_MIOUSD_per_MW * 1000;
    Renewable_Inv_per_Capacity_kUSD_per_MW = ...
        Renewable_Inv_per_Capacity_MIOUSD_per_MW * 1000;

    Renewable_to_Fossil_Intensity_Ratio = safe_divide( ...
        Renewable_Inv_per_Capacity_kUSD_per_MW, ...
        Fossil_Inv_per_Capacity_kUSD_per_MW);

    annual = table(Plan, Year, ...
        Fossil_Investment_MIOUSD, Renewable_Investment_MIOUSD, ...
        Fossil_Capacity_MW, Renewable_Capacity_MW, ...
        Fossil_Inv_per_Capacity_MIOUSD_per_MW, ...
        Renewable_Inv_per_Capacity_MIOUSD_per_MW, ...
        Fossil_Inv_per_Capacity_kUSD_per_MW, ...
        Renewable_Inv_per_Capacity_kUSD_per_MW, ...
        Renewable_to_Fossil_Intensity_Ratio);
end

function detail = technology_detail(data, fossilTechs, renewableTechs)
    keep = ismember(data.Technology, [fossilTechs; renewableTechs]);
    detail = data(keep, {'Plan', 'Year', 'Technology', 'Capacity_MW', 'INV_MIOUSD'});

    TechType = strings(height(detail), 1);
    TechType(ismember(detail.Technology, fossilTechs)) = "Fossil";
    TechType(ismember(detail.Technology, renewableTechs)) = "Renewable";

    Investment_per_Capacity_MIOUSD_per_MW = ...
        safe_divide(detail.INV_MIOUSD, detail.Capacity_MW);
    Investment_per_Capacity_kUSD_per_MW = ...
        Investment_per_Capacity_MIOUSD_per_MW * 1000;

    detail = addvars(detail, TechType, ...
        Investment_per_Capacity_MIOUSD_per_MW, ...
        Investment_per_Capacity_kUSD_per_MW, ...
        'After', 'Technology');
    detail = sortrows(detail, {'Plan', 'Year', 'TechType', 'Technology'});
end

function mapping = technology_mapping(fossilTechs, renewableTechs)
    TechType = [repmat("Fossil", numel(fossilTechs), 1); ...
                repmat("Renewable", numel(renewableTechs), 1)];
    Technology = [fossilTechs; renewableTechs];
    mapping = table(TechType, Technology);
end

function y = nan_sum_or_nan(x)
    x = x(~isnan(x));
    if isempty(x)
        y = NaN;
    else
        y = sum(x);
    end
end

function y = safe_divide(num, den)
    y = num ./ den;
    y(den <= 0 | isnan(num) | isnan(den)) = NaN;
end
