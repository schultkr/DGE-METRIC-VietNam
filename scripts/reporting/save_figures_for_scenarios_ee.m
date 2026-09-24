%% Load Scenario Data
clearvars
close all
clc

addpath('C:\dynare\6.1\matlab')
set(groot,'defaultAxesFontSize',13)
set(groot,'defaultTextFontSize',13)
set(groot,'defaultLegendFontSize',12)
set(groot,'defaultAxesFontName','Arial')

outdir = 'C:/Users/schul/Documents/GitHub/DGE-METRIC-VietNam/docs/figures/EE/';
if ~exist(outdir,'dir')
    mkdir(outdir);
end

casScenarios = {'Baseline', 'EE', 'EE_CapandTrade'};
caslegendentries = {'PDP8', 'EE carbon tax', 'EE Cap and Trade'};
casLinetypes = {'-', '--', '-.'};
casColors = [
    31, 119, 180;
    214, 39, 40;
    44, 160, 44
    ] ./ 255;

sversion = '';  % output-CSV suffix written by RunSimulations (sSensitivity); this script does not call setup_paths, so report_version_suffix() is not available here
dsall = struct();
for iscen = 1:length(casScenarios)
    sScen = casScenarios{iscen};
    filename = ['../../ExcelFiles/Output/' sScen sversion '.csv'];
    dsall.(sScen) = readtable(filename);
end

Tplot = 26;
ilw = 2;
years = dsall.Baseline.Year(1:Tplot);

%% 1. Emissions
fig = new_policy_figure('Emissions');
ax = gca;
for iscen = 1:length(casScenarios)
    ds = dsall.(casScenarios{iscen});
    plot(ax, ds.Year(1:Tplot), ds.E_1(1:Tplot)./ds.E_1(1)*300, ...
        'LineStyle', casLinetypes{iscen}, 'LineWidth', ilw, 'Color', casColors(iscen,:));
end
style_axes(ax, 'Year', 'Mio. t CO_2', caslegendentries, 'northwest');
save_my_figure(fig,'Emissions',outdir)

%% 2. GDP Growth
fig = new_policy_figure('GDP_Growth');
ax = gca;
for iscen = 1:length(casScenarios)
    ds = dsall.(casScenarios{iscen});
    growth = (ds.Y_1(2:Tplot)./ds.Y_1(1:Tplot-1)-1)*100;
    plot(ax, ds.Year(2:Tplot), growth, ...
        'LineStyle', casLinetypes{iscen}, 'LineWidth', ilw, 'Color', casColors(iscen,:));
end
style_axes(ax, 'Year', '%', caslegendentries, 'northeast');
save_my_figure(fig,'GDP_Growth',outdir)

%% 3. Renewable Share
fig = new_policy_figure('Renewable_Share');
ax = gca;
for iscen = 1:length(casScenarios)
    ds = dsall.(casScenarios{iscen});
    res_share = (ds.Q_3_1)./(ds.Q_2_1+ds.Q_3_1)*100;
    plot(ax, ds.Year(1:Tplot), res_share(1:Tplot), ...
        'LineStyle', casLinetypes{iscen}, 'LineWidth', ilw, 'Color', casColors(iscen,:));
end
style_axes(ax, 'Year', '%', caslegendentries, 'northwest');
save_my_figure(fig,'Renewable_Share',outdir)

%% 5. Energy Intensity
fig = new_policy_figure('Energy Intensity');
ax = gca;
for iscen = 1:length(casScenarios)
    ds = dsall.(casScenarios{iscen});
    res_share = ((ds.Q_A_2_1 + ds.Q_PV_1)./(ds.Q_A_2_1(1) + ds.Q_PV_1(1)))./(ds.Y_1./ds.Y_1(1)).*100;
    plot(ax, ds.Year(1:Tplot), res_share(1:Tplot), ...
        'LineStyle', casLinetypes{iscen}, 'LineWidth', ilw, 'Color', casColors(iscen,:));
end
style_axes(ax, 'Year', 'Energy/GDP', caslegendentries, 'northwest');
save_my_figure(fig,'EnergyIntensity',outdir)


%% 5. Energy Intensity
fig = new_policy_figure('Energy Demand');
ax = gca;
for iscen = 1:length(casScenarios)
    ds = dsall.(casScenarios{iscen});
    res_share = ((ds.Q_A_F_2_1 + ds.Q_PV_1)./(ds.Q_A_F_2_1(1) + ds.Q_PV_1(1))).*100;
    plot(ax, ds.Year(1:Tplot), res_share(1:Tplot), ...
        'LineStyle', casLinetypes{iscen}, 'LineWidth', ilw, 'Color', casColors(iscen,:));
end
style_axes(ax, 'Year', 'Energy Demand', caslegendentries, 'northwest');
save_my_figure(fig,'FinalEnergyDemand',outdir)

%% 5. Energy use Agriculure
fig = new_policy_figure('Energy use Agriculure');
ax = gca;
for iscen = 1:length(casScenarios)
    ds = dsall.(casScenarios{iscen});
    res_share = ds.A_I_1_1_2./ds.A_I_1_1_2(1).*100;
    plot(ax, ds.Year(1:Tplot), res_share(1:Tplot), ...
        'LineStyle', casLinetypes{iscen}, 'LineWidth', ilw, 'Color', casColors(iscen,:));
end
style_axes(ax, 'Year', 'Index (2025=100)', caslegendentries, 'northwest');
save_my_figure(fig,'EU_Agriculture',outdir)


%% 6. Energy Expenditure
fig = new_policy_figure('Energy Expenditure');
ax = gca;
for iscen = 1:length(casScenarios)
    ds = dsall.(casScenarios{iscen});
    res_share = ds.Q_A_2_1 .* ds.P_A_2_1./(ds.Y_1.*ds.P_1).*100;
    plot(ax, ds.Year(1:Tplot), res_share(1:Tplot), ...
        'LineStyle', casLinetypes{iscen}, 'LineWidth', ilw, 'Color', casColors(iscen,:));
end
style_axes(ax, 'Year', 'percent', caslegendentries, 'northwest');
save_my_figure(fig,'EnergyExpenditure',outdir)

icofigure = 0;
icofigure = icofigure+1;
strvars(icofigure).VarName = 'GDP';
strvars(icofigure).VarTitle = 'GDP';
strvars(icofigure).VarSymb = 'Y_1';
strvars(icofigure).FileName = 'GDP';
strvars(icofigure).IsGDPComponent = false;

icofigure = icofigure+1;
strvars(icofigure).VarName = 'Emission Price';
strvars(icofigure).VarTitle = 'Emission Price';
strvars(icofigure).VarSymb = 'PE_1';
strvars(icofigure).FileName = 'EmissionPrice';
strvars(icofigure).IsGDPComponent = false;

icofigure = icofigure+1;
strvars(icofigure).VarName = 'Investment';
strvars(icofigure).VarTitle = 'Investment';
strvars(icofigure).VarSymb = 'I_1';
strvars(icofigure).FileName = 'Investment';
strvars(icofigure).IsGDPComponent = true;

icofigure = icofigure+1;
strvars(icofigure).VarName = 'Consumption';
strvars(icofigure).VarTitle = 'Consumption';
strvars(icofigure).VarSymb = 'C_1';
strvars(icofigure).FileName = 'Consumption';
strvars(icofigure).IsGDPComponent = true;

icofigure = icofigure+1;
strvars(icofigure).VarName = 'Government';
strvars(icofigure).VarTitle = 'Government';
strvars(icofigure).VarSymb = 'G_1';
strvars(icofigure).FileName = 'Government';
strvars(icofigure).IsGDPComponent = true;

icofigure = icofigure+1;
strvars(icofigure).VarName = 'TradeBalance';
strvars(icofigure).VarTitle = 'Trade Balance';
strvars(icofigure).VarSymb = 'NX_1';
strvars(icofigure).FileName = 'TradeBalance';
strvars(icofigure).IsGDPComponent = true;

icofigure = icofigure+1;
strvars(icofigure).VarName = 'EnergyPrices';
strvars(icofigure).VarTitle = 'Energy Prices';
strvars(icofigure).VarSymb = 'P_A_2_1';
strvars(icofigure).FileName = 'EnergyPrices';
strvars(icofigure).IsGDPComponent = false;

icofigure = icofigure+1;
strvars(icofigure).VarName = 'Energy';
strvars(icofigure).VarTitle = 'Energy Production';
strvars(icofigure).VarSymb = 'Q_A_2_1';
strvars(icofigure).FileName = 'Energy';
strvars(icofigure).IsGDPComponent = false;

icofigure = icofigure+1;
strvars(icofigure).VarName = 'EnergyAgri';
strvars(icofigure).VarTitle = 'Energy Agriculture';
strvars(icofigure).VarSymb = 'Q_I_2_1_2';
strvars(icofigure).FileName = 'EnergyAgriculture';
strvars(icofigure).IsGDPComponent = false;

icofigure = icofigure+1;
strvars(icofigure).VarName = 'EnergyIndustry';
strvars(icofigure).VarTitle = 'Energy Industry';
strvars(icofigure).VarSymb = 'Q_I_4_1_2';
strvars(icofigure).FileName = 'EnergyIndustry';
strvars(icofigure).IsGDPComponent = false;

icofigure = icofigure+1;
strvars(icofigure).VarName = 'EnergyServices';
strvars(icofigure).VarTitle = 'Energy Services';
strvars(icofigure).VarSymb = 'Q_I_5_1_2';
strvars(icofigure).FileName = 'EnergyServices';
strvars(icofigure).IsGDPComponent = false;

for icovar = 1:length(strvars)
    svar = strvars(icovar).VarName;
    ssymb = strvars(icovar).VarSymb;
    isGDPComponent = strvars(icovar).IsGDPComponent;
    fileName = strvars(icovar).FileName;

    fig = new_policy_figure(svar);
    ax = gca;

    if isGDPComponent
        temp = ((dsall.EE.(ssymb)-dsall.Baseline.(ssymb))./dsall.Baseline.Y_1)*100;
    else
        temp = (dsall.EE.(ssymb)./dsall.Baseline.(ssymb)-1)*100;
    end

    plot(ax, years, temp(1:Tplot), ...
        'LineStyle', casLinetypes{2}, 'LineWidth', ilw, 'Color', casColors(2,:));

    if isGDPComponent
        temp = ((dsall.EE_CapandTrade.(ssymb)-dsall.Baseline.(ssymb))./dsall.Baseline.Y_1).*100;
    else
        temp = (dsall.EE_CapandTrade.(ssymb)./dsall.Baseline.(ssymb)-1)*100;
    end

    plot(ax, years, temp(1:Tplot), ...
        'LineStyle', casLinetypes{3}, 'LineWidth', ilw, 'Color', casColors(3,:));

    yline(ax, 0, ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 1, 'HandleVisibility', 'off');

    if isGDPComponent
        ylabelText = '% of PDP8 GDP';
    else
        ylabelText = '% deviation from PDP8';
    end

    style_axes(ax, 'Year', ylabelText, caslegendentries(2:end), 'northwest');
    save_my_figure(fig,fileName,outdir)
end



%% ---- local function (keep at end of file) ----
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
    % safe filename
    name = regexprep(name,'[^A-Za-z0-9_\-]','_');

    exportgraphics(fig, fullfile(outdir,[name '.png']), 'Resolution', 600);
    exportgraphics(fig, fullfile(outdir,[name '.pdf']), 'ContentType','vector');
end


disp("All figures generated and saved.")
