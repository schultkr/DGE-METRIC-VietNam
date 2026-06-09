# EE Scenario Plotting Runbook (Ready to Run)

Date: 2026-06-03

## Objective

Run and visualize macro impacts for the EE-focused scenarios:

- `EE_PDP8`
- `EE_Directive10`
- `EE_Directive10_NoBESS`
- `EE_Directive10_PV_BESS` (requested name)
- `EE_PDP8_PV_BESS_NoBESS`

Important naming note:

- `EE_Directive10_PV_BESS` is not present in `ModelScenarios5Sectorsand1Regions.xlsx`.
- Use `EE_PDP8_PV_BESS` as the available PV+BESS counterpart.

## Canonical scenario set to run now

Use this set for a complete, runnable comparison:

- `EE_PDP8`
- `EE_Directive10`
- `EE_Directive10_NoBESS`
- `EE_PDP8_PV_BESS`
- `EE_PDP8_PV_BESS_NoBESS`

## Step 1. Rebuild EE scenario sheets from expert workbook

In MATLAB (from repository root):

```matlab
run('scripts/maintenance/CreateEEScenariosFromExpertInputs.m');
```

## Step 2. Preflight check that all required scenario sheets exist

```matlab
scenarioWorkbook = 'ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx';
required = { ...
    'EE_PDP8', ...
    'EE_Directive10', ...
    'EE_Directive10_NoBESS', ...
    'EE_PDP8_PV_BESS', ...
    'EE_PDP8_PV_BESS_NoBESS'};

allSheets = sheetnames(scenarioWorkbook);
missing = required(~ismember(required, allSheets));

if isempty(missing)
    disp('Preflight OK: all required scenario sheets are present.');
else
    disp('Preflight FAILED: missing scenario sheets:');
    disp(missing');
end
```

## Step 3. Run simulations for the EE set

Edit `RunSimulations.m` and set `casScenarioNames` to:

```matlab
casScenarioNames = {...
    'EE_PDP8',...
    'EE_Directive10',...
    'EE_Directive10_NoBESS',...
    'EE_PDP8_PV_BESS',...
    'EE_PDP8_PV_BESS_NoBESS'};
```

Then run:

```matlab
run('RunSimulations.m');
```

Expected outputs are scenario CSVs in `ExcelFiles/Output/`.

## Step 4. Generate macro comparison plots (copy-paste block)

This block reads the scenario CSVs and exports core macro figures to `docs/figures/EE_Comparisons/`.

```matlab
clearvars; close all; clc;

outdir = 'docs/figures/EE_Comparisons/';
if ~exist(outdir, 'dir'); mkdir(outdir); end

scenarios = { ...
    'EE_PDP8', ...
    'EE_Directive10', ...
    'EE_Directive10_NoBESS', ...
    'EE_PDP8_PV_BESS', ...
    'EE_PDP8_PV_BESS_NoBESS'};

labels = { ...
    'EE PDP8', ...
    'EE Directive10', ...
    'EE Directive10 NoBESS', ...
    'EE PDP8 PV+BESS', ...
    'EE PDP8 PV+BESS NoBESS'};

colors = lines(numel(scenarios));
linetypes = {'-','--','-.',':','-'};
Tplot = 26;
ilw = 2;

dsall = struct();
for i = 1:numel(scenarios)
    fn = fullfile('ExcelFiles', 'Output', [scenarios{i} '.csv']);
    if ~isfile(fn)
        error('Missing scenario output file: %s', fn);
    end
    dsall.(scenarios{i}) = readtable(fn);
end

years = dsall.(scenarios{1}).Year(1:Tplot);

plot_and_save = @(name) saveas(gcf, fullfile(outdir, [name '.png']));

% 1) GDP growth (%)
figure('Color','w'); hold on;
for i = 1:numel(scenarios)
    ds = dsall.(scenarios{i});
    growth = (ds.Y_1(2:Tplot)./ds.Y_1(1:Tplot-1)-1)*100;
    plot(ds.Year(2:Tplot), growth, 'LineWidth', ilw, ...
        'LineStyle', linetypes{i}, 'Color', colors(i,:));
end
grid on; box off; xlabel('Year'); ylabel('%');
legend(labels, 'Location', 'best', 'Box', 'off');
title('GDP Growth');
plot_and_save('GDP_Growth');

% 2) GDP level index (first plotted year = 100)
figure('Color','w'); hold on;
for i = 1:numel(scenarios)
    ds = dsall.(scenarios{i});
    idx = ds.Y_1(1:Tplot)./ds.Y_1(1)*100;
    plot(ds.Year(1:Tplot), idx, 'LineWidth', ilw, ...
        'LineStyle', linetypes{i}, 'Color', colors(i,:));
end
grid on; box off; xlabel('Year'); ylabel('Index');
legend(labels, 'Location', 'best', 'Box', 'off');
title('GDP Level (Index)');
plot_and_save('GDP_Level_Index');

% 3) Investment share of GDP (%)
figure('Color','w'); hold on;
for i = 1:numel(scenarios)
    ds = dsall.(scenarios{i});
    invShare = ds.I_1(1:Tplot)./ds.Y_1(1:Tplot)*100;
    plot(ds.Year(1:Tplot), invShare, 'LineWidth', ilw, ...
        'LineStyle', linetypes{i}, 'Color', colors(i,:));
end
grid on; box off; xlabel('Year'); ylabel('% of GDP');
legend(labels, 'Location', 'best', 'Box', 'off');
title('Investment Share of GDP');
plot_and_save('Investment_Share_GDP');

% 4) Consumption share of GDP (%)
figure('Color','w'); hold on;
for i = 1:numel(scenarios)
    ds = dsall.(scenarios{i});
    cShare = ds.C_1(1:Tplot)./ds.Y_1(1:Tplot)*100;
    plot(ds.Year(1:Tplot), cShare, 'LineWidth', ilw, ...
        'LineStyle', linetypes{i}, 'Color', colors(i,:));
end
grid on; box off; xlabel('Year'); ylabel('% of GDP');
legend(labels, 'Location', 'best', 'Box', 'off');
title('Consumption Share of GDP');
plot_and_save('Consumption_Share_GDP');

% 5) Energy intensity index
figure('Color','w'); hold on;
for i = 1:numel(scenarios)
    ds = dsall.(scenarios{i});
    intensity = ((ds.Q_A_2_1 + ds.Q_PV_1)./(ds.Q_A_2_1(1) + ds.Q_PV_1(1))) ...
        ./ (ds.Y_1./ds.Y_1(1)) * 100;
    plot(ds.Year(1:Tplot), intensity(1:Tplot), 'LineWidth', ilw, ...
        'LineStyle', linetypes{i}, 'Color', colors(i,:));
end
grid on; box off; xlabel('Year'); ylabel('Index');
legend(labels, 'Location', 'best', 'Box', 'off');
title('Energy Intensity (Energy/GDP)');
plot_and_save('Energy_Intensity_Index');

% 6) Final energy demand index
figure('Color','w'); hold on;
for i = 1:numel(scenarios)
    ds = dsall.(scenarios{i});
    fed = (ds.Q_A_F_2_1 + ds.Q_PV_1)./(ds.Q_A_F_2_1(1) + ds.Q_PV_1(1))*100;
    plot(ds.Year(1:Tplot), fed(1:Tplot), 'LineWidth', ilw, ...
        'LineStyle', linetypes{i}, 'Color', colors(i,:));
end
grid on; box off; xlabel('Year'); ylabel('Index');
legend(labels, 'Location', 'best', 'Box', 'off');
title('Final Energy Demand (Index)');
plot_and_save('Final_Energy_Demand_Index');

% 7) Energy expenditure (% of nominal GDP)
figure('Color','w'); hold on;
for i = 1:numel(scenarios)
    ds = dsall.(scenarios{i});
    ee = ds.Q_A_2_1 .* ds.P_A_2_1 ./ (ds.Y_1 .* ds.P_1) * 100;
    plot(ds.Year(1:Tplot), ee(1:Tplot), 'LineWidth', ilw, ...
        'LineStyle', linetypes{i}, 'Color', colors(i,:));
end
grid on; box off; xlabel('Year'); ylabel('%');
legend(labels, 'Location', 'best', 'Box', 'off');
title('Energy Expenditure Share');
plot_and_save('Energy_Expenditure_Share');

% 8) Emissions index
figure('Color','w'); hold on;
for i = 1:numel(scenarios)
    ds = dsall.(scenarios{i});
    emissions = ds.E_1(1:Tplot)./ds.E_1(1)*100;
    plot(ds.Year(1:Tplot), emissions, 'LineWidth', ilw, ...
        'LineStyle', linetypes{i}, 'Color', colors(i,:));
end
grid on; box off; xlabel('Year'); ylabel('Index');
legend(labels, 'Location', 'best', 'Box', 'off');
title('Emissions (Index)');
plot_and_save('Emissions_Index');

disp('EE macro comparison figures exported to docs/figures/EE_Comparisons/');
```

## Step 5. Plot grouping for interpretation

Use the exported figures in these four narrative groups:

1. Policy stringency: `EE_PDP8` vs `EE_Directive10`
2. Directive10 BESS attribution: `EE_Directive10` vs `EE_Directive10_NoBESS`
3. PV+BESS package attribution: `EE_PDP8_PV_BESS` vs `EE_PDP8_PV_BESS_NoBESS`
4. Cross-package comparison: `EE_PDP8`, `EE_Directive10`, `EE_PDP8_PV_BESS`

## Optional: keep requested naming in reporting tables

If you must show `EE_Directive10_PV_BESS` in external slides/tables, map it as an alias to `EE_PDP8_PV_BESS` and document the alias in a footnote.