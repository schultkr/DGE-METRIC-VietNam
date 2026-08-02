%% estimate_inv_price_decline.m
%  Estimates declining investment price indices for Renewables and Fossil.
%  Method:
%    (1) capacity-weighted average CAPEX from CAPEXINTER.csv, with
%        capacity weights drawn from Capacity_Inter.csv by plan.
%    (2) investment-weighted average CAPEX from CAPEXINTER.csv, with
%        investment weights drawn from Investment.csv by plan.
%  Outputs one index per plan (PDP8, PDP8_rev_high, PDP8_rev_low).

close all;
repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd   = pwd;
cleanupObj = onCleanup(@() cd(oldPwd));
cd(repoRoot);
setup_paths();

set(groot, 'defaultAxesFontSize',  13);
set(groot, 'defaultTextFontSize',  13);
set(groot, 'defaultLegendFontSize',11);
set(groot, 'defaultAxesFontName', 'Arial');

outDir = 'figures';
if ~exist(outDir,'dir'); mkdir(outDir); end

% ---- load data -------------------------------------------------------
capex = readtable('ExcelFiles/PDP8/CAPEXINTER.csv',    'TreatAsEmpty',{'NA'});
cap   = readtable('ExcelFiles/PDP8/Capacity_Inter.csv','TreatAsEmpty',{'NA'});
inv   = readtable('ExcelFiles/PDP8/Investment.csv',    'TreatAsEmpty',{'NA'});

% Drop unnamed R-style row-index column if present
if strcmp(capex.Properties.VariableNames{1},'Var1') || ...
        all(cellfun(@isnumeric, table2cell(capex(1,1))))
    capex(:,1) = [];
end

if strcmp(inv.Properties.VariableNames{1},'Var1') || ...
        all(cellfun(@isnumeric, table2cell(inv(1,1))))
    inv(:,1) = [];
end

% ---- settings --------------------------------------------------------
plans     = {'PDP8','PDP8_rev_high','PDP8_rev_low'};
baseYear  = 2025;
yearRange = (2020:2050)';
nYears    = numel(yearRange);
nPlans    = numel(plans);
lw        = 1.8;
fsz       = [100 100 680 480];

planColors = [0.20 0.45 0.75;   % blue  – PDP8
              0.85 0.33 0.10;   % red   – PDP8_rev_high
              0.10 0.65 0.35];  % green – PDP8_rev_low
planStyles = {'-','--',':'};

% ---- tech crosswalk: CAPEXINTER name → Capacity_Inter name -----------
%  Renewable group
renMap = {
    'Solar PV (Weighted)',        'PV';
    'Onshore Wind',               'Wind';
    'Wind offshore (fixed base)', 'Wind_offshore';
    'Small hydro',                'Hydro';
    'Battery',                    'Batteries';
    'Biomass',                    'Biomass';
};

%  Fossil group  (Nuclear included per existing classification)
fosMap = {
    'Coal supercritical',         'Coal_PVC';
    'Coal_CFB',                   'Coal_CFB';
    'Coal_conv_biomassNH3_PVC',   'Coal_conv_biomassNH3_PVC';
    'Coal_conv_biomassNH3_CFB',   'Coal_conv_biomassNH3_CFB';
    'CCGT - LNG',                 'LNG';
    'CCGT- CCS- LNG',            'LNG_CCS';
    'CCGT \x2013 H2',            'GAS_H2';     % en-dash in source
    'SCGT',                       'Gas';
    'Nuclear \x2013 PWR',        'Nuclear';    % en-dash in source
};

% Resolve en-dash characters by matching from the actual table content
% (avoids encoding issues in the source file)
capexTechs = capex.Tech;
fosMap = resolveEnDash(fosMap, capexTechs);

% ---- compute capacity-weighted CAPEX per group, plan, year -----------
capexRen     = NaN(nYears, nPlans);
capexFos     = NaN(nYears, nPlans);
capexRen_lwr = NaN(nYears, nPlans);
capexRen_upr = NaN(nYears, nPlans);
capexFos_lwr = NaN(nYears, nPlans);
capexFos_upr = NaN(nYears, nPlans);

capexRen_invW     = NaN(nYears, nPlans);
capexFos_invW     = NaN(nYears, nPlans);
capexRen_invW_lwr = NaN(nYears, nPlans);
capexRen_invW_upr = NaN(nYears, nPlans);
capexFos_invW_lwr = NaN(nYears, nPlans);
capexFos_invW_upr = NaN(nYears, nPlans);

for ip = 1:nPlans
    capPlan = cap(strcmp(cap.Plan, plans{ip}), :);
    invPlan = inv(strcmp(inv.Plan, plans{ip}), :);
    for iy = 1:nYears
        yr       = yearRange(iy);
        capexYr  = capex(capex.Year == yr, :);
        capPlanYr = capPlan(capPlan.Year == yr, :);
        invPlanYr = invPlan(invPlan.Year == yr, :);

        [capexRen(iy,ip), capexRen_lwr(iy,ip), capexRen_upr(iy,ip)] = ...
            weightedCapex(capexYr, capPlanYr, renMap, 'Capacity_MW');

        [capexFos(iy,ip), capexFos_lwr(iy,ip), capexFos_upr(iy,ip)] = ...
            weightedCapex(capexYr, capPlanYr, fosMap, 'Capacity_MW');

        [capexRen_invW(iy,ip), capexRen_invW_lwr(iy,ip), capexRen_invW_upr(iy,ip)] = ...
            weightedCapex(capexYr, invPlanYr, renMap, 'INV_MIOUSD');

        [capexFos_invW(iy,ip), capexFos_invW_lwr(iy,ip), capexFos_invW_upr(iy,ip)] = ...
            weightedCapex(capexYr, invPlanYr, fosMap, 'INV_MIOUSD');
    end
end

% ---- index to base year = 100 ----------------------------------------
baseIdx = yearRange == baseYear;

idxRen     = capexRen     ./ capexRen(baseIdx,:)     .* 100;
idxFos     = capexFos     ./ capexFos(baseIdx,:)     .* 100;
idxRen_lwr = capexRen_lwr ./ capexRen(baseIdx,:)     .* 100;
idxRen_upr = capexRen_upr ./ capexRen(baseIdx,:)     .* 100;
idxFos_lwr = capexFos_lwr ./ capexFos(baseIdx,:)     .* 100;
idxFos_upr = capexFos_upr ./ capexFos(baseIdx,:)     .* 100;

idxRen_invW     = capexRen_invW     ./ capexRen_invW(baseIdx,:)     .* 100;
idxFos_invW     = capexFos_invW     ./ capexFos_invW(baseIdx,:)     .* 100;
idxRen_invW_lwr = capexRen_invW_lwr ./ capexRen_invW(baseIdx,:)     .* 100;
idxRen_invW_upr = capexRen_invW_upr ./ capexRen_invW(baseIdx,:)     .* 100;
idxFos_invW_lwr = capexFos_invW_lwr ./ capexFos_invW(baseIdx,:)     .* 100;
idxFos_invW_upr = capexFos_invW_upr ./ capexFos_invW(baseIdx,:)     .* 100;

% ---- fit log-linear time trend (annual % decline) --------------------
fprintf('\n=== Implied annual price decline (log-linear fit, 2020-2050) ===\n');
fitSlopes = zeros(nPlans, 2);   % col1=ren, col2=fos

for ip = 1:nPlans
    yr0 = yearRange - baseYear;

    validR = ~isnan(capexRen(:,ip)) & capexRen(:,ip) > 0;
    bR = polyfit(yr0(validR), log(capexRen(validR,ip)), 1);
    fitSlopes(ip,1) = bR(1);

    validF = ~isnan(capexFos(:,ip)) & capexFos(:,ip) > 0;
    bF = polyfit(yr0(validF), log(capexFos(validF,ip)), 1);
    fitSlopes(ip,2) = bF(1);

    fprintf('  %-18s  Ren: %+.2f%%/yr   Fos: %+.2f%%/yr\n', ...
        plans{ip}, (exp(bR(1))-1)*100, (exp(bF(1))-1)*100);
end

% ---- Figure 1: Renewable price index by plan -------------------------
f = figure('Name','Ren Price Index','NumberTitle','off','Position',fsz);
hold on;
for ip = 1:nPlans
    valid = ~isnan(idxRen(:,ip));
    plot(yearRange(valid), idxRen(valid,ip), ...
        'Color',planColors(ip,:), 'LineStyle',planStyles{ip}, ...
        'LineWidth',lw, 'DisplayName', strrep(plans{ip},'_',' '));
end
xline(baseYear,'k:','LineWidth',1,'HandleVisibility','off');
yline(100,'k:','LineWidth',1,'HandleVisibility','off');
hold off;
title('Renewable Investment Price Index');
ylabel('Index (2025 = 100)');  xlabel('Year');
xlim([yearRange(1) yearRange(end)]);
legend('Location','southwest');  grid on;
exportgraphics(f, fullfile(outDir,'ren_price_index.png'),'Resolution',150);

% ---- Figure 2: Fossil price index by plan ----------------------------
f = figure('Name','Fos Price Index','NumberTitle','off','Position',fsz);
hold on;
for ip = 1:nPlans
    valid = ~isnan(idxFos(:,ip));
    plot(yearRange(valid), idxFos(valid,ip), ...
        'Color',planColors(ip,:), 'LineStyle',planStyles{ip}, ...
        'LineWidth',lw, 'DisplayName', strrep(plans{ip},'_',' '));
end
xline(baseYear,'k:','LineWidth',1,'HandleVisibility','off');
yline(100,'k:','LineWidth',1,'HandleVisibility','off');
hold off;
title('Fossil Investment Price Index');
ylabel('Index (2025 = 100)');  xlabel('Year');
xlim([yearRange(1) yearRange(end)]);
legend('Location','southwest');  grid on;
exportgraphics(f, fullfile(outDir,'fos_price_index.png'),'Resolution',150);

% ---- Figure 3: Renewable index with uncertainty band (rev_high) ------
ip_h = find(strcmp(plans,'PDP8_rev_high'));
f = figure('Name','Ren Price Index Unc','NumberTitle','off','Position',fsz);
hold on;
validB = ~isnan(idxRen_lwr(:,ip_h)) & ~isnan(idxRen_upr(:,ip_h));
if any(validB)
    fill([yearRange(validB); flipud(yearRange(validB))], ...
         [idxRen_lwr(validB,ip_h); flipud(idxRen_upr(validB,ip_h))], ...
         planColors(2,:),'FaceAlpha',0.20,'EdgeColor','none', ...
         'HandleVisibility','off');
end
for ip = 1:nPlans
    valid = ~isnan(idxRen(:,ip));
    plot(yearRange(valid), idxRen(valid,ip), ...
        'Color',planColors(ip,:),'LineStyle',planStyles{ip}, ...
        'LineWidth',lw,'DisplayName',strrep(plans{ip},'_',' '));
end
xline(baseYear,'k:','LineWidth',1,'HandleVisibility','off');
yline(100,'k:','LineWidth',1,'HandleVisibility','off');
hold off;
title('Renewable Investment Price Index  (shaded: PDP8\_rev\_high uncertainty)');
ylabel('Index (2025 = 100)');  xlabel('Year');
xlim([yearRange(1) yearRange(end)]);
legend('Location','southwest');  grid on;
exportgraphics(f, fullfile(outDir,'ren_price_index_unc.png'),'Resolution',150);

% ---- Figure 4: Fossil index with uncertainty band --------------------
f = figure('Name','Fos Price Index Unc','NumberTitle','off','Position',fsz);
hold on;
validB = ~isnan(idxFos_lwr(:,ip_h)) & ~isnan(idxFos_upr(:,ip_h));
if any(validB)
    fill([yearRange(validB); flipud(yearRange(validB))], ...
         [idxFos_lwr(validB,ip_h); flipud(idxFos_upr(validB,ip_h))], ...
         planColors(2,:),'FaceAlpha',0.20,'EdgeColor','none', ...
         'HandleVisibility','off');
end
for ip = 1:nPlans
    valid = ~isnan(idxFos(:,ip));
    plot(yearRange(valid), idxFos(valid,ip), ...
        'Color',planColors(ip,:),'LineStyle',planStyles{ip}, ...
        'LineWidth',lw,'DisplayName',strrep(plans{ip},'_',' '));
end
xline(baseYear,'k:','LineWidth',1,'HandleVisibility','off');
yline(100,'k:','LineWidth',1,'HandleVisibility','off');
hold off;
title('Fossil Investment Price Index  (shaded: PDP8\_rev\_high uncertainty)');
ylabel('Index (2025 = 100)');  xlabel('Year');
xlim([yearRange(1) yearRange(end)]);
legend('Location','southwest');  grid on;
exportgraphics(f, fullfile(outDir,'fos_price_index_unc.png'),'Resolution',150);

% ---- Figure 5: Renewable investment-weighted index by plan ----------
f = figure('Name','Ren Price Index InvW','NumberTitle','off','Position',fsz);
hold on;
for ip = 1:nPlans
    valid = ~isnan(idxRen_invW(:,ip));
    plot(yearRange(valid), idxRen_invW(valid,ip), ...
        'Color',planColors(ip,:), 'LineStyle',planStyles{ip}, ...
        'LineWidth',lw, 'DisplayName', strrep(plans{ip},'_',' '));
end
xline(baseYear,'k:','LineWidth',1,'HandleVisibility','off');
yline(100,'k:','LineWidth',1,'HandleVisibility','off');
hold off;
title('Renewable Investment Price Index (Investment-Weighted)');
ylabel('Index (2025 = 100)');  xlabel('Year');
xlim([yearRange(1) yearRange(end)]);
legend('Location','southwest');  grid on;
exportgraphics(f, fullfile(outDir,'ren_price_index_inv_weighted.png'),'Resolution',150);

% ---- Figure 6: Fossil investment-weighted index by plan -------------
f = figure('Name','Fos Price Index InvW','NumberTitle','off','Position',fsz);
hold on;
for ip = 1:nPlans
    valid = ~isnan(idxFos_invW(:,ip));
    plot(yearRange(valid), idxFos_invW(valid,ip), ...
        'Color',planColors(ip,:), 'LineStyle',planStyles{ip}, ...
        'LineWidth',lw, 'DisplayName', strrep(plans{ip},'_',' '));
end
xline(baseYear,'k:','LineWidth',1,'HandleVisibility','off');
yline(100,'k:','LineWidth',1,'HandleVisibility','off');
hold off;
title('Fossil Investment Price Index (Investment-Weighted)');
ylabel('Index (2025 = 100)');  xlabel('Year');
xlim([yearRange(1) yearRange(end)]);
legend('Location','southwest');  grid on;
exportgraphics(f, fullfile(outDir,'fos_price_index_inv_weighted.png'),'Resolution',150);

% ---- export CSV ------------------------------------------------------
rows = cell(nYears * nPlans, 15);
row  = 0;
for ip = 1:nPlans
    for iy = 1:nYears
        row = row + 1;
        rows(row,:) = {plans{ip}, yearRange(iy), ...
            idxRen(iy,ip),     idxRen_lwr(iy,ip), idxRen_upr(iy,ip), ...
            idxFos(iy,ip),     idxFos_lwr(iy,ip), idxFos_upr(iy,ip), ...
            idxRen_invW(iy,ip), idxRen_invW_lwr(iy,ip), idxRen_invW_upr(iy,ip), ...
            idxFos_invW(iy,ip), idxFos_invW_lwr(iy,ip), idxFos_invW_upr(iy,ip), ...
            fitSlopes(ip,1)};
    end
end
T = cell2table(rows, 'VariableNames', { ...
    'Plan','Year', ...
    'P_INV_Ren','P_INV_Ren_lwr','P_INV_Ren_upr', ...
    'P_INV_Fos','P_INV_Fos_lwr','P_INV_Fos_upr', ...
    'P_INV_Ren_inv_weighted','P_INV_Ren_inv_weighted_lwr','P_INV_Ren_inv_weighted_upr', ...
    'P_INV_Fos_inv_weighted','P_INV_Fos_inv_weighted_lwr','P_INV_Fos_inv_weighted_upr', ...
    'Ren_log_slope'});
outCSV = fullfile('ExcelFiles','Output','InvPriceIndex.csv');
writetable(T, outCSV);
fprintf('Saved: %s\n', outCSV);

% ======================================================================
function [cw, cw_lwr, cw_upr] = weightedCapex(capexYr, weightPlanYr, techMap, weightVar)
%WEIGHTEDCAPEX  Weighted average CAPEX and bounds by technology group.
    totalCap = 0;  wC = 0;  wL = 0;  wU = 0;
    for j = 1:size(techMap,1)
        cxRow = capexYr(strcmp(capexYr.Tech, techMap{j,1}), :);
        wpRow = weightPlanYr(strcmp(weightPlanYr.Technology, techMap{j,2}), :);
        if isempty(cxRow) || isempty(wpRow) || ~ismember(weightVar, wpRow.Properties.VariableNames)
            continue;
        end
        cx  = cxRow.CAPEX_kUSD_MW;
        wt  = wpRow.(weightVar);
        if isnan(cx) || isnan(wt) || wt <= 0; continue; end
        lwr = cxRow.CAPEX_kUSD_MW_lwr;  if isnan(lwr); lwr = cx; end
        upr = cxRow.CAPEX_kUSD_MW_upr;  if isnan(upr); upr = cx; end
        wC = wC + cx  * wt;
        wL = wL + lwr * wt;
        wU = wU + upr * wt;
        totalCap = totalCap + wt;
    end
    if totalCap == 0
        cw = NaN;  cw_lwr = NaN;  cw_upr = NaN;
    else
        cw     = wC / totalCap;
        cw_lwr = wL / totalCap;
        cw_upr = wU / totalCap;
    end
end

function techMap = resolveEnDash(techMap, capexTechs)
%RESOLVEENDASH  Replace placeholder \x2013 with the actual en-dash
%  character as it appears in the loaded table, avoiding encoding issues.
    for j = 1:size(techMap,1)
        if contains(techMap{j,1},'\x2013')
            stub = strrep(techMap{j,1},'\x2013','');
            stub = strtrim(stub);
            % find matching tech name that contains the stub words
            parts = strsplit(stub);
            mask  = true(numel(capexTechs),1);
            for k = 1:numel(parts)
                mask = mask & contains(capexTechs, parts{k},'IgnoreCase',true);
            end
            hits = capexTechs(mask);
            if ~isempty(hits)
                techMap{j,1} = hits{1};
            end
        end
    end
end
