
%% Load Scenario Data

clearvars
close all
clc

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd));
cd(repoRoot);
setup_paths();

% Define scenario metadata
casScenarios = {'Baseline', 'NZ'};%, 'NZ_constEE', 'Finance_RG'};
caslegendentries = {'PDP8', 'Net Zero'};%, 'Net Zero', 'NZ_constEE', 'Finance Government'};
% Per-scenario colour + line style, from the shared reporting registry
% (Baseline keeps the semantic baseline colour; other scenarios come from
% iwh_scenario_style so they match every other reporting script).
casColor = cell(size(casScenarios));
casLineStyle = cell(size(casScenarios));
for iscenStyle = 1:numel(casScenarios)
    if strcmp(casScenarios{iscenStyle}, 'Baseline')
        casColor{iscenStyle} = iwh_colors().baseline;
        casLineStyle{iscenStyle} = '-';
    else
        sty = iwh_scenario_style(casScenarios{iscenStyle});
        casColor{iscenStyle} = sty.Color;
        casLineStyle{iscenStyle} = sty.LineStyle;
    end
end

% Load scenario CSV data
dsall = struct();
for iscen = 1:length(casScenarios)
    sScen = casScenarios{iscen};
    filename = ['ExcelFiles/Output/' sScen '.csv'];
    dsall.(sScen) = readtable(filename);
end

Tplot = 50; % Years to plot
%% Emissions Plot

figure('Name', 'Emissions');
hold on
for iscen = 1:length(casScenarios)
    sScen = casScenarios{iscen};
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot), ds.E_1(1:Tplot) ./ ds.E_1(1) * 300, 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
legend(caslegendentries)
ylabel({'Emissions (Indexed)', 'Index (Base = 300)'})
hold off
%% Energy Productivity

figure('Name', 'Energy productivity');
hold on
for iscen = 1:length(casScenarios)
    sScen = casScenarios{iscen};
    ds = dsall.(sScen);
    productivity = ds.Y_1 ./ (ds.Q_D_2_1 + ds.Q_D_3_1);
    plot(ds.Year(1:Tplot), productivity(1:Tplot) / productivity(1) * 100, 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
legend(caslegendentries)
ylabel({'Energy Productivity (Indexed)', 'Index'})
hold off
%% Cap and Trade Revenues

figure('Name', 'Cap and Trade Revenues');
hold on
for iscen = 1:length(casScenarios)
    sScen = casScenarios{iscen};
    ds = dsall.(sScen);
    revenues = ds.PE_1 .* ds.E_1 ./ (ds.Q_1 - ds.Q_I_1) * 100;
    plot(ds.Year(1:Tplot), revenues(1:Tplot), 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
legend(caslegendentries)
ylabel({'Revenues from Cap and Trade System (% of Value Added)', '%'})
hold off
%% GDP Growth

figure('Name', 'GDP Growth');
hold on
for iscen = 1:length(casScenarios)
    sScen = casScenarios{iscen};
    ds = dsall.(sScen);
    growth = (ds.Y_1(2:Tplot) ./ ds.Y_1(1:Tplot-1) - 1) * 100;
    plot(ds.Year(2:Tplot), growth, 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
legend(caslegendentries)
ylabel({'Annual GDP Growth (%)', '%'})
hold off
%% Renewable Energy Share (RES)

figure('Name', 'Renewable Energy Share');
hold on
for iscen = 1:length(casScenarios)
    sScen = casScenarios{iscen};
    ds = dsall.(sScen);
    res_share = ds.Q_D_3_1 ./ (ds.Q_D_2_1 + ds.Q_D_3_1) .* 100;
    plot(ds.Year(1:Tplot), res_share(1:Tplot), 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
legend(caslegendentries)
ylabel({'Renewable Energy Share (%)', '%'})
hold off
%% Emission Intensity

figure('Name', 'Emission Intensity');
hold on
for iscen = 1:length(casScenarios)
    sScen = casScenarios{iscen};
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot), ds.kappaE_2_1(1:Tplot) / ds.kappaE_2_1(1) * 100, 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
legend(caslegendentries)
ylabel({'Emission Intensity (Indexed)', 'Index'})
hold off
%% Emission Price

figure('Name', 'Emission Price');
hold on
for iscen = 1:length(casScenarios)
    sScen = casScenarios{iscen};
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot), ds.PE_1(1:Tplot), 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
legend(caslegendentries)
ylabel({'Emission Price', 'Index'})
hold off
%% Renewables Interest Rate


ssubsec = '3';
if ssubsec == '1'
    ssectorname = 'Agriculture';
elseif ssubsec == '2'
    ssectorname = 'Fossil';
elseif ssubsec == '3'
    ssectorname = 'Renewables';
elseif ssubsec == '4'
    ssectorname = 'Manufacturing';
elseif ssubsec == '5'
    ssectorname = 'Services';
end
icofig = 0;
icofig = icofig + 1;
strfig(icofig).Name = [ssectorname ' Interest Rate'];
strfig(icofig).Symbol = ['r_F_' ssubsec '_1'];
icofig = icofig + 1;
strfig(icofig).Name = [ssectorname ' Wages'];
strfig(icofig).Symbol = ['W_' ssubsec '_1'];
icofig = icofig + 1;
strfig(icofig).Name = [ssectorname ' Labour'];
strfig(icofig).Symbol = ['N_' ssubsec '_1'];
icofig = icofig + 1;
strfig(icofig).Name =  [ssectorname ' Capital'];
strfig(icofig).Symbol = ['K_' ssubsec '_1'];
icofig = icofig + 1;
strfig(icofig).Name = [ssectorname ' Intermediate Prices'];
strfig(icofig).Symbol = ['P_I_' ssubsec '_1'];
icofig = icofig + 1;
strfig(icofig).Name = [ssectorname ' Price'];
strfig(icofig).Symbol = ['P_Q_' ssubsec '_1'];
icofig = icofig + 1;
strfig(icofig).Name = [ssectorname ' Productivity'];
strfig(icofig).Symbol = ['A_' ssubsec '_1'];
icofig = icofig + 1;
strfig(icofig).Name = 'Energy Productivity';
strfig(icofig).Symbol = 'EE_1';
icofig = icofig + 1;
strfig(icofig).Name = 'Emission Price';
strfig(icofig).Symbol = 'PE_1';
for icofig = 1:size(strfig,2)
    sname = strfig(icofig).Name;
    ssymb = strfig(icofig).Symbol;
    figure('Name', sname);
    hold on
    for iscen = 1:length(casScenarios)
        sScen = casScenarios{iscen};
        ds = dsall.(sScen);
            % plot(ds.Year(2:Tplot), (1+ds.r_F_' ssubsec '_1(2:Tplot)).*(1+ds.tauKF_' ssubsec '_1(2:Tplot)).*ds.P_' ssubsec '_1(2:Tplot)./ds.P_' ssubsec '_1(1:Tplot-1)-1, 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
        plot(ds.Year(1:Tplot), ds.(ssymb)(1:Tplot), 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
        
    end
    legend(caslegendentries)
    ylabel({sname, 'Index'})
    hold off
end

%% Renewable Capital Stock

figure('Name', 'Renewable Capital Stock');
hold on
for iscen = 1:length(casScenarios)
    sScen = casScenarios{iscen};
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot), ds.K_3_1(1:Tplot), 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
legend(caslegendentries)
ylabel({'Renewable Capital Stock', 'Index'})
hold off
figure('Name', 'Renewable Labour');
hold on
for iscen = 1:length(casScenarios)
    sScen = casScenarios{iscen};
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot), ds.N_3_1(1:Tplot), 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
legend(caslegendentries)
ylabel({'Renewable Labor', 'Index'})
hold off

figure('Name', 'Renewable Price');
hold on
for iscen = 1:length(casScenarios)
    sScen = casScenarios{iscen};
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot), ds.P_3_1(1:Tplot), 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
legend(caslegendentries)
ylabel({'Renewable Price', 'Index'})
hold off
%% Energy Efficiency

figure('Name', 'Energy Efficiency');
hold on
for iscen = 1:length(casScenarios)
    sScen = casScenarios{iscen};
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot), ds.EE_1(1:Tplot) / ds.EE_1(1) * 100, 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
legend(caslegendentries)
ylabel({'Energy Efficiency (Indexed)', 'Index'})
hold off
%% Emission Price

figure('Name', 'Emission Price');
hold on
for iscen = 1:length(casScenarios)
    sScen = casScenarios{iscen};
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot), ds.PE_1(1:Tplot) / ds.PE_1(1), 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
legend(caslegendentries)
ylabel({'Emission Price (Relative to Base Year)', 'Relative Price'})
hold off
%% Fossil Energy Production


figure('Name','Fossil Energy Production'); hold on
for iscen = 1:numel(casScenarios)
    ds = dsall.(casScenarios{iscen});
    plot(ds.Year(1:Tplot), ds.Q_2_1(1:Tplot), 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
ylabel({'Fossil Energy Production', 'Index'}); legend(caslegendentries); hold off

%% 19. Renewable Energy Production
figure('Name','Renewable Energy Production'); hold on
for iscen = 1:numel(casScenarios)
    ds = dsall.(casScenarios{iscen});
    plot(ds.Year(1:Tplot), ds.Q_3_1(1:Tplot), 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
ylabel({'Renewable Energy Production', 'Index'}); legend(caslegendentries); hold off

%% 20. Fossil Energy Price (Value Added)
figure('Name','Fossil Energy Price – VA'); hold on
for iscen = 1:numel(casScenarios)
    ds = dsall.(casScenarios{iscen});
    plot(ds.Year(1:Tplot), ds.P_2_1(1:Tplot) * 100, 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
ylabel({'Relative Price of Fossil Energy', 'Price Index'}); legend(caslegendentries); hold off

%% 21. Sectoral Shares in Value Added -------------------------------------
% Agriculture
figure('Name','VA Share – Agriculture'); hold on
for iscen = 1:numel(casScenarios)
    ds = dsall.(casScenarios{iscen});
    shareAg = ds.P_1_1 .* ds.Y_1_1 ./ ds.Y_1 * 100;
    plot(ds.Year(1:Tplot), shareAg(1:Tplot), 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
ylabel({'Agriculture Share in VA', '%'}); legend(caslegendentries); hold off

% Manufacturing
figure('Name','VA Share – Manufacturing'); hold on
for iscen = 1:numel(casScenarios)
    ds = dsall.(casScenarios{iscen});
    shareMan = ds.P_4_1 .* ds.Y_4_1 ./ ds.Y_1 * 100;
     plot(ds.Year(1:Tplot), shareMan(1:Tplot), 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
ylabel({'Manufacturing Share in VA', '%'}); legend(caslegendentries); hold off


% Government Expenditure
figure('Name','Government Expenditure'); hold on
for iscen = 1:numel(casScenarios)
    ds = dsall.(casScenarios{iscen});
    shareMan = ds.G;
     plot(ds.Year(1:Tplot), shareMan(1:Tplot), 'Color', casColor{iscen}, 'LineStyle', casLineStyle{iscen});
end
ylabel({'Government Expenditure', '%'}); legend(caslegendentries); hold off
%% Conclusion

disp("All scenario plots generated.")
