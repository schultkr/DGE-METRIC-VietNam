%  Plot Results from different scenarios to check them
clear all

addpath('C:\dynare\6.1\matlab')
load('structScenarioResultsssp185.mat')
casScenarios = {'Baseline', 'NZ'};%, 'NZ_constInt', 'NZ_constEE', 'NZ_constEEInt'};%, 'Subsidies'};
caslegendentries = {'PDP8', 'NZ'};%, 'NZ with constant emission efficiency', 'NZ with constant energy productivity', 'NZ with constant emission and energy efficiency'};
casLinetypes = {'-', '+-', '-.', '.', '+'};
dsall = [];
for iscen = 1:length(casScenarios)
    sScen = char(casScenarios(iscen));
    dsall.(sScen) = readtable(['ExcelFiles/Output/ssp185'  sScen '.csv']);
end




% M_ = structScenarioResults.Sectors5Regions1ssp185.(sScenario).M_;
% oo_ = structScenarioResults.Sectors5Regions1ssp185.(sScenario).oo_;
% options_ = structScenarioResults.Sectors5Regions1ssp185.(sScenario).options_;
% dyn2vec(M_, oo_, options_);
close all;
Tplot = 25;
figure('name', 'Emissions')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.E_1(1:Tplot)./ds.E_1(1).*300, sline); hold on;
end
legend(caslegendentries); hold on;
hold off


figure('name', 'Energy productivity')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.Y_1(1:Tplot)./(ds.Q_D_2_1(1:Tplot) + ds.Q_D_3_1(1:Tplot))./(ds.Y_1(1)./(ds.Q_D_2_1(1) + ds.Q_D_3_1(1))).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off

figure('name', 'Revenues from Cap and Trade System')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.PE_1(1:Tplot).*ds.E_1(1:Tplot)./(ds.Q_1(1:Tplot)-ds.Q_I_1(1:Tplot)).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off

figure('name', 'GDP Growth')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(2:Tplot),(ds.Y_1(2:Tplot)./(ds.Y_1(1:(Tplot-1)))-1).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off

figure('name', 'RES')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.Q_D_3_1(1:Tplot)./(ds.Q_D_2_1(1:Tplot)+ds.Q_D_3_1(1:Tplot)).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off

figure('name', 'emission intensity')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.kappaE_2_1(1:Tplot)./(ds.kappaE_2_1(1)).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off

figure('name', 'Energy efficicency')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.EE_1(1:Tplot)./(ds.EE_1(1)).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off


figure('name', 'Emission price')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.PE_1(1:Tplot)./(ds.PE_1(1)), sline); hold on;
end
legend(caslegendentries); hold on;
hold off

figure('name', 'Investments renewable')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.I_3_1(1:Tplot)./(ds.I_3_1(1)).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off

figure('name', 'Capital renewable')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.K_3_1(1:Tplot)./(ds.K_3_1(1)).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off


figure('name', 'Investments fossil')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.I_2_1(1:Tplot)./(ds.I_2_1(1)).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off

figure('name', 'Capital fossil')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.K_2_1(1:Tplot)./(ds.K_2_1(1)).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off

figure('name', 'Capital/Value-Added ratio')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.K_2_1(1:Tplot)./(ds.Q_2_1(1:Tplot)).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off

figure('name', 'Employment fossil')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.N_2_1(1:Tplot)./(ds.N_2_1(1)).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off

figure('name', 'Employment renewables')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.N_3_1(1:Tplot)./(ds.N_3_1(1)).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off

figure('name', 'Energy Efficiency')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.Q_3_1(1:Tplot)./(ds.Q_3_1(1)).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off

figure('name', 'Energy Efficiency')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.kappaE_2_1(1:Tplot), sline); hold on;
end
legend(caslegendentries); hold on;
hold off

% [~,iposvar] = ismember(svar, M_.endo_names);
figure('name', 'fossil energy production')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.Q_2_1(1:Tplot)./ds.Q_2_1(1).*100, sline); hold on;
end
legend(caslegendentries); hold on;


figure('name', 'renewable energy production')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.Q_3_1(1:Tplot)./ds.Q_3_1(1).*100, sline); hold on;
end
legend(caslegendentries); hold on;


figure('name', 'fossil energy price: value added')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.P_2_1(1:Tplot).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off
figure('name', ':agriculture share: value added')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.P_1_1(1:Tplot).*ds.Y_1_1(1:Tplot)./ds.Y_1(1:Tplot).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off
figure('name', 'manufacturing share: value added')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.P_4_1(1:Tplot).*ds.Y_4_1(1:Tplot)./ds.Y_1(1:Tplot).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off
figure('name', 'services share: value added')
for iscen = 1:length(casScenarios) 
    sScen = char(casScenarios(iscen));
    sline = char(casLinetypes(iscen));
    ds = dsall.(sScen);
    plot(ds.Year(1:Tplot),ds.P_5_1(1:Tplot).*ds.Y_5_1(1:Tplot)./ds.Y_1(1:Tplot).*100, sline); hold on;
end
legend(caslegendentries); hold on;
hold off



% figure('name', 'Energy Efficiency')
% for iscen = 1:length(casScenarios) 
%     sScen = char(casScenarios(iscen));
%     sline = char(casLinetypes(iscen));
%     ds = dsall.(sScen);
%     plot(ds.Year(1:Tplot),ds.Q_3_1(1:Tplot)./(ds.Q_3_1(1)).*100, sline); hold on;
% end
% legend(caslegendentries); hold on;
% hold off
