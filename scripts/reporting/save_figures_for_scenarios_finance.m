%% Financing figures (PDP8 and NZ pathways)
clearvars
close all
clc

addpath('C:\dynare\6.1\matlab')
set(groot,'defaultAxesFontSize',13)
set(groot,'defaultTextFontSize',13)
set(groot,'defaultLegendFontSize',11)
set(groot,'defaultAxesFontName','Arial')

outdir = fullfile('..','docs','figures','Financing');
outdir = 'C:/Users/schul/Documents/GitHub/DGE-METRIC-VietNam/docs/figures/finance/';
if ~exist(outdir,'dir')
    mkdir(outdir);
end

allScenarios = {'Baseline', 'PDP8_concessional', 'PDP8_subsidies', 'NZ', 'NZ_concessional', 'NZ_subsidies'};
legendAll = {'PDP8-Base', 'PDP8-Concessional', 'PDP8-Recycle', 'NZ-Base', 'NZ-Concessional', 'NZ-Recycle'};
lineAll = {'-', '--', '-.', '-', '--', '-.'};
colorAll = [
    31, 119, 180;
    31, 119, 180;
    31, 119, 180;
    214, 39, 40;
    214, 39, 40;
    214, 39, 40
    ] ./ 255;

policyScenarios = {'PDP8_concessional', 'PDP8_subsidies', 'NZ_concessional', 'NZ_subsidies'};
legendPolicy = {'PDP8 concessional vs PDP8 base', 'PDP8 recycle vs PDP8 base', 'NZ concessional vs NZ base', 'NZ recycle vs NZ base'};
linePolicy = {'--', '-.', '--', '-.'};
colorPolicy = [
    31, 119, 180;
    31, 119, 180;
    214, 39, 40;
    214, 39, 40
    ] ./ 255;

sversion = '_replication_fix';  % output-CSV suffix written by RunSimulations (sSensitivity); this script does not call setup_paths, so report_version_suffix() is not available here
dsall = struct();
for iscen = 1:length(allScenarios)
    scenario = allScenarios{iscen};
    filename = ['../../ExcelFiles/Output/' scenario sversion '.csv'];
    dsall.(scenario) = readtable(filename);
end

Tplot = min(26, min(cellfun(@(s) height(dsall.(s)), allScenarios)));
years = dsall.Baseline.Year(1:Tplot);
ilw = 2;

basePDP8 = dsall.Baseline;
baseNZ = dsall.NZ;

rateVar = 'r_G_3_1';
if isfield(basePDP8, 'r_F_3_1')
    spread = max(abs(dsall.PDP8_concessional.r_G_1_1(1:Tplot) - basePDP8.r_G_1_1(1:Tplot)));
    if spread < 1e-10
        rateVar = 'r_F_3_1';
    end
end

%% 1) Public interest rate
fig = new_policy_figure('Public interest rate');
ax = gca;
for iscen = 1:length(allScenarios)
    ds = dsall.(allScenarios{iscen});
    series = ds.(rateVar)(1:Tplot) * 100;
    plot(ax, years, series, 'LineStyle', lineAll{iscen}, 'LineWidth', ilw, 'Color', colorAll(iscen,:));
end
style_axes(ax, 'Year', 'Percent', legendAll, 'northeast');
save_my_figure(fig,'PublicInterestRate',outdir)


%% 1) Public interest rate
fig = new_policy_figure('Public interest rate');
ax = gca;
for iscen = 1:length(allScenarios)
    ds = dsall.(allScenarios{iscen});
    series = ds.(rateVar)(1:Tplot) * 100;
    plot(ax, years, series, 'LineStyle', lineAll{iscen}, 'LineWidth', ilw, 'Color', colorAll(iscen,:));
end
style_axes(ax, 'Year', 'Percent', legendAll, 'northeast');
save_my_figure(fig,'PublicInterestRate2',outdir)

%% 2) Renewable capital stock
fig = new_policy_figure('Renewable capital stock');
ax = gca;
for iscen = 1:length(allScenarios)
    ds = dsall.(allScenarios{iscen});
    series = ds.K_3_1(1:Tplot) ./ ds.K_3_1(1) * 100;
    plot(ax, years, series, 'LineStyle', lineAll{iscen}, 'LineWidth', ilw, 'Color', colorAll(iscen,:));
end
style_axes(ax, 'Year', 'Index (2025=100)', legendAll, 'northwest');
save_my_figure(fig,'RenewableCapital',outdir)

%% 3) GDP growth (pp vs pathway baseline)
fig = new_policy_figure('GDP growth');
ax = gca;
for iscen = 1:length(policyScenarios)
    scenario = policyScenarios{iscen};
    ds = dsall.(scenario);
    if startsWith(scenario,'NZ')
        base = baseNZ;
    else
        base = basePDP8;
    end

    gScenario = (ds.Y_1(2:Tplot) ./ ds.Y_1(1:Tplot-1) - 1) * 100;
    gBase = (base.Y_1(2:Tplot) ./ base.Y_1(1:Tplot-1) - 1) * 100;
    plot(ax, years(2:Tplot), gScenario - gBase, 'LineStyle', linePolicy{iscen}, 'LineWidth', ilw, 'Color', colorPolicy(iscen,:));
end
yline(ax, 0, ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 1, 'HandleVisibility', 'off');
style_axes(ax, 'Year', 'Percentage points vs baseline', legendPolicy, 'northeast');
save_my_figure(fig,'GDP_Growth',outdir)

%% 4) GDP (% vs pathway baseline)
fig = new_policy_figure('GDP level');
ax = gca;
for iscen = 1:length(policyScenarios)
    scenario = policyScenarios{iscen};
    ds = dsall.(scenario);
    if startsWith(scenario,'NZ')
        base = baseNZ;
    else
        base = basePDP8;
    end

    series = pct_diff(ds.Y_1(1:Tplot), base.Y_1(1:Tplot));
    plot(ax, years, series, 'LineStyle', linePolicy{iscen}, 'LineWidth', ilw, 'Color', colorPolicy(iscen,:));
end
yline(ax, 0, ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 1, 'HandleVisibility', 'off');
style_axes(ax, 'Year', '% vs pathway baseline', legendPolicy, 'northwest');
save_my_figure(fig,'GDP',outdir)

%% 5) Total investment (% vs pathway baseline)
fig = new_policy_figure('Total investment');
ax = gca;
for iscen = 1:length(policyScenarios)
    scenario = policyScenarios{iscen};
    ds = dsall.(scenario);
    if startsWith(scenario,'NZ')
        base = baseNZ;
    else
        base = basePDP8;
    end

    series = pct_diff(ds.I_1(1:Tplot), base.I_1(1:Tplot));
    plot(ax, years, series, 'LineStyle', linePolicy{iscen}, 'LineWidth', ilw, 'Color', colorPolicy(iscen,:));
end
yline(ax, 0, ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 1, 'HandleVisibility', 'off');
style_axes(ax, 'Year', '% vs pathway baseline', legendPolicy, 'northwest');
save_my_figure(fig,'Investment',outdir)

%% 6) Emission tax revenue
fig = new_policy_figure('Emission tax revenue');
ax = gca;
for iscen = 1:length(allScenarios)
    ds = dsall.(allScenarios{iscen});
    series = ds.PE_1(1:Tplot) .* ds.E_1(1:Tplot);
    plot(ax, years, series, 'LineStyle', lineAll{iscen}, 'LineWidth', ilw, 'Color', colorAll(iscen,:));
end
style_axes(ax, 'Year', 'Model units', legendAll, 'northwest');
save_my_figure(fig,'EmissionTaxRevenue',outdir)

%% 7) Recycled renewable investment
fig = new_policy_figure('Recycled renewable investment');
ax = gca;
seriesPDP8 = (dsall.PDP8_subsidies.PE_1(1:Tplot) .* dsall.PDP8_subsidies.E_1(1:Tplot))./baseNZ.Y(1);
seriesNZ = (dsall.NZ_subsidies.PE_1(1:Tplot) .* dsall.NZ_subsidies.E_1(1:Tplot))./baseNZ.Y(1);
plot(ax, years, seriesPDP8 * 500, 'LineStyle', '-.', 'LineWidth', ilw, 'Color', colorPolicy(2,:));
plot(ax, years, seriesNZ * 500, 'LineStyle', '-.', 'LineWidth', ilw, 'Color', colorPolicy(4,:));
yline(ax, 0, ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 1, 'HandleVisibility', 'off');
style_axes(ax, 'Year', 'Billion USD (2015)', {'PDP8 recycle incremental', 'NZ recycle incremental'}, 'northwest');
save_my_figure(fig,'RecycledInvestment',outdir)

%% 8) Emissions
fig = new_policy_figure('Emissions');
ax = gca;
for iscen = 1:length(allScenarios)
    ds = dsall.(allScenarios{iscen});
    series = ds.E_1(1:Tplot) ./ ds.E_1(1) * 300;
    plot(ax, years, series, 'LineStyle', lineAll{iscen}, 'LineWidth', ilw, 'Color', colorAll(iscen,:));
end
style_axes(ax, 'Year', 'Mio. t CO_2', legendAll, 'northwest');
save_my_figure(fig,'Emissions',outdir)

%% 9) Renewable generation
fig = new_policy_figure('Renewable generation');
ax = gca;
for iscen = 1:length(allScenarios)
    ds = dsall.(allScenarios{iscen});
    series = ds.Q_3_1(1:Tplot) ./ ds.Q_3_1(1) * 100;
    plot(ax, years, series, 'LineStyle', lineAll{iscen}, 'LineWidth', ilw, 'Color', colorAll(iscen,:));
end
style_axes(ax, 'Year', 'Index (2025 = 100)', legendAll, 'northwest');
save_my_figure(fig,'RenewableGeneration',outdir)

disp("All financing figures generated and saved.")


%% ---- local functions (keep at end of file) ----
function y = pct_diff(x, xBase)
    y = (x ./ xBase - 1) * 100;
end

function fig = new_policy_figure(figName)
    fig = figure('Name', figName, 'Color', 'w', 'Units', 'pixels', 'Position', [100 100 1100 650]);
    hold on
end

function style_axes(ax, xLabelText, yLabelText, legendEntries, legendLocation)
    ylabel(ax, yLabelText);
    grid(ax, 'on');
    ax.GridAlpha = 0.18;
    ax.MinorGridAlpha = 0.08;
    ax.XMinorGrid = 'on';
    ax.YMinorGrid = 'on';
    ax.Box = 'off';
    ax.LineWidth = 1;
    xlim(ax, 'tight');
    legend(ax, legendEntries, 'Location', legendLocation, 'Box', 'off');
end

function save_my_figure(fig, name, outdir)
    name = regexprep(name,'[^A-Za-z0-9_\-]','_');

    exportgraphics(fig, fullfile(outdir,[name '.png']), 'Resolution', 600);
    exportgraphics(fig, fullfile(outdir,[name '.pdf']), 'ContentType','vector');
end
