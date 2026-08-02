%% Export Investment-to-GDP Ratios (Fossil & Renewable) to Excel
%  Reads ExcelFiles/Output/Baseline.csv and writes
%  ExcelFiles/Output/InvestmentGDPRatios.xlsx with one sheet per scenario
%  (currently only Baseline).
%
%  Formulas follow display_baseline_energy.m exactly:
%    GDP value          = Y_1 * P_1, in the model numeraire
%    Fossil inv value   = (I_H_2_1 + I_G_2_1) * P_INV_2_1
%    Renewable inv value= (I_H_3_1 + I_G_3_1) * P_INV_3_1
%    Share (%)          = investment value / GDP value * 100

repoRoot   = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd     = pwd;
cleanupObj = onCleanup(@() cd(oldPwd));
cd(repoRoot);
setup_paths();

% ---- configuration ------------------------------------------------------
csvPath  = fullfile('ExcelFiles', 'Output', 'Baseline.csv');
xlsPath  = fullfile('ExcelFiles', 'Output', 'InvestmentGDPRatios.xlsx');
Tplot    = Inf;   % use all available periods; set to e.g. 25 to truncate

% ---- load ---------------------------------------------------------------
ds = readtable(csvPath);
if isfinite(Tplot)
    ds = ds(1:min(Tplot, height(ds)), :);
end

years = ds.Year;

% ---- derived series -----------------------------------------------------
gdp_value = ds.Y_1 .* ds.P_1;

inv_fos_value = (ds.I_H_2_1 + ds.I_G_2_1) .* ds.P_INV_2_1;
inv_ren_value = (ds.I_H_3_1 + ds.I_G_3_1) .* ds.P_INV_3_1;

inv_fos_share = inv_fos_value ./ gdp_value .* 100;
inv_ren_share = inv_ren_value ./ gdp_value .* 100;

% ---- assemble table -----------------------------------------------------
T = table(years, ...
          inv_ren_share, inv_fos_share, ...
          inv_ren_value, inv_fos_value, gdp_value, ...
    'VariableNames', { ...
        'Year', ...
        'Renewable_Inv_pct_GDP', 'Fossil_Inv_pct_GDP', ...
        'Renewable_Inv_Value',   'Fossil_Inv_Value',   'GDP_Value'});

% ---- write to Excel -----------------------------------------------------
writetable(T, xlsPath, 'Sheet', 'Baseline');
fprintf('Saved investment/GDP ratios to %s\n', xlsPath);
