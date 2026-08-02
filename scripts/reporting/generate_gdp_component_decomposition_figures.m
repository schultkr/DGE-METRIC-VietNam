%% Generate GDP component decomposition figures vs Baseline
% Shows percentage-point deviations of GDP relative to baseline, decomposed
% into contributions consistent with the model resource constraint:
%
%   Y_1 = Q_1 - Q_I_1
%       = P_1*(C_1 + I_1 + G_1 + I_G_1) + IH_1*PH_1 + I_PV_1 + NX_1
%
% Each component's contribution is expressed as a share of baseline GDP.

close all;

repoRoot  = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd    = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

outputDir   = fullfile(repoRoot, 'ExcelFiles', 'Output');
baselineCsv = fullfile(outputDir, 'Baseline.csv');

scenarioSpecs = table( ...
    ["Baseline"; "EE_Directive10"; "PDP8_GF_C"], ...
    ["revised PDP 8 high"; "EE Directive 10"; "PDP 8 GF C"], ...
    'VariableNames', {'Name', 'Label'});

plotStartYear = 2025;
plotEndYear   = 2050;

outDir = fullfile(repoRoot, 'Figures', 'ScenarioComparisons', 'GDPDecomposition');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

colors = struct();
colors.consumption = [0.00 0.45 0.74];
colors.investment  = [0.85 0.33 0.10];
colors.government  = [0.47 0.67 0.19];
colors.housingpv   = [0.93 0.69 0.13];
colors.trade       = [0.49 0.18 0.56];
colors.total       = [0.10 0.10 0.10];
colors.residual    = [0.55 0.55 0.55];

set(groot, 'defaultAxesFontSize', 12, ...
           'defaultTextFontSize', 12, ...
           'defaultLegendFontSize', 10, ...
           'defaultAxesFontName', 'Arial', ...
           'defaultTextFontName', 'Arial');

requiredVars = ["Y_1", "P_1", "C_1", "I_1", "G_1", "I_G_1", "IH_1", "PH_1", "I_PV_1"];

baseline = readtable(baselineCsv);
baseline = require_and_sort_years(baseline, plotStartYear, plotEndYear, 'baseline');
require_vars(baseline, ["Year", requiredVars], 'baseline data');
baselineTrade = resolve_trade_balance_series(baseline);

for iScen = 1:height(scenarioSpecs)
    sName  = string(scenarioSpecs.Name(iScen));
    sLabel = string(scenarioSpecs.Label(iScen));

    if sName == "Baseline"
        continue
    end

    csvPath = fullfile(outputDir, sName + ".csv");
    if ~isfile(csvPath)
        warning('generate_gdp_component_decomposition_figures:missingScenarioFile', ...
            'Scenario file not found for "%s": %s. Skipping.', sName, csvPath);
        continue
    end

    scenario = readtable(csvPath);
    require_vars(scenario, ["Year", requiredVars], char(sName) + " data");
    scenarioTrade = resolve_trade_balance_series(scenario);

    commonYears = intersect(baseline.Year(:), scenario.Year(:));
    commonYears = commonYears(commonYears >= plotStartYear & commonYears <= plotEndYear);
    commonYears = sort(commonYears(:));
    if isempty(commonYears)
        warning('generate_gdp_component_decomposition_figures:noCommonYears', ...
            'No common years found for "%s". Skipping.', sName);
        continue
    end

    baselineAligned = sortrows(baseline(ismember(baseline.Year, commonYears), :), 'Year');
    scenarioAligned  = sortrows(scenario(ismember(scenario.Year,  commonYears), :), 'Year');

    [~, baseIdx] = ismember(commonYears, baseline.Year);
    [~, scenIdx] = ismember(commonYears, scenario.Year);
    baselineTradeAligned = baselineTrade(baseIdx);
    scenarioTradeAligned = scenarioTrade(scenIdx);

    decomp = compute_decomposition(baselineAligned, scenarioAligned, ...
                                   baselineTradeAligned, scenarioTradeAligned);

    summaryCsv = fullfile(outDir, 'GDP_Component_Decomposition_' + sanitize_filename(sName) + '.csv');
    writetable(decomp, summaryCsv);

    fig = figure('Color', 'w', 'Position', [80 80 1120 560]);

    stackedData = [ ...
        decomp.ConsumptionPctOfBaseline, ...
        decomp.InvestmentPctOfBaseline, ...
        decomp.GovernmentPctOfBaseline, ...
        decomp.HousingPVPctOfBaseline, ...
        decomp.TradeBalancePctOfBaseline];

    bh = bar(decomp.Year, stackedData, 'stacked');
    ax = gca;
    hold(ax, 'on');
    bh(1).FaceColor = colors.consumption;
    bh(2).FaceColor = colors.investment;
    bh(3).FaceColor = colors.government;
    bh(4).FaceColor = colors.housingpv;
    bh(5).FaceColor = colors.trade;

    componentLabels = ["Private Consumption", "Private Investment", ...
                       "Government Expenditure", "Housing & Solar Investment", "Net Exports"];
    for iBar = 1:numel(bh)
        bh(iBar).DisplayName = componentLabels(iBar);
    end

    plot(ax, decomp.Year, decomp.GDPDeviationPctOfBaseline, '-', ...
        'Color', colors.total, 'LineWidth', 2.0, 'DisplayName', 'Total GDP change');

    yline(ax, 0, ':', 'Color', colors.residual, 'LineWidth', 1.0, 'HandleVisibility', 'off');
    hold(ax, 'off');
    grid(ax, 'on');
    box(ax, 'off');
    xlabel(ax, 'Year');
    ylabel(ax, 'Percentage points of baseline GDP');
    title(ax, sprintf('%s vs Baseline — GDP component decomposition', sLabel), ...
        'Interpreter', 'none');
    legend(ax, 'Location', 'bestoutside', 'Box', 'off', 'Interpreter', 'none');

    save_dual(fig, outDir, 'GDP_Component_Decomposition_' + sanitize_filename(sName));
    fprintf('Saved GDP decomposition for %s to %s\n', sName, outDir);
end

fprintf('GDP decomposition figures written to: %s\n', outDir);

%% Local functions --------------------------------------------------------

function tbl = require_and_sort_years(tbl, startYear, endYear, label)
    require_vars(tbl, 'Year', label);
    tbl = tbl(tbl.Year >= startYear & tbl.Year <= endYear, :);
    tbl = sortrows(tbl, 'Year');
end

function require_vars(tbl, vars, label)
    vars = string(vars);
    missing = vars(~ismember(vars, string(tbl.Properties.VariableNames)));
    if ~isempty(missing)
        error('generate_gdp_component_decomposition_figures:missingVars', ...
            'Missing variable(s) in %s: %s', label, strjoin(cellstr(missing), ', '));
    end
end

function trade = resolve_trade_balance_series(tbl)
    names = string(tbl.Properties.VariableNames);
    if ismember('NX_1', names)
        trade = tbl.NX_1;
        if ismember('NX_1_1', names)
            trade = trade + tbl.NX_1_1;
        end
        return
    end
    if ismember('X_1', names) && ismember('M_1', names)
        trade = tbl.X_1 - tbl.M_1;
        return
    end
    error('generate_gdp_component_decomposition_figures:missingTradeBalance', ...
        'Neither NX_1 nor X_1/M_1 were found. Cannot compute net exports.');
end

function out = compute_decomposition(baseTbl, scenTbl, baseTrade, scenTrade)
    % Decomposition from the model identity:
    %   Y_1 = P_1*(C_1 + I_1 + G_1 + I_G_1) + IH_1*PH_1 + I_PV_1 + NX_1
    baseGDP = baseTbl.Y_1;

    base_C    = baseTbl.P_1 .* baseTbl.C_1;
    base_I    = baseTbl.P_1 .* baseTbl.I_1;
    base_Gov  = baseTbl.P_1 .* (baseTbl.G_1 + baseTbl.I_G_1);
    base_HsPV = baseTbl.IH_1 .* baseTbl.PH_1 + baseTbl.I_PV_1;
    base_NX   = baseTrade;

    scen_C    = scenTbl.P_1 .* scenTbl.C_1;
    scen_I    = scenTbl.P_1 .* scenTbl.I_1;
    scen_Gov  = scenTbl.P_1 .* (scenTbl.G_1 + scenTbl.I_G_1);
    scen_HsPV = scenTbl.IH_1 .* scenTbl.PH_1 + scenTbl.I_PV_1;
    scen_NX   = scenTrade;

    out = table();
    out.Year                      = baseTbl.Year;
    out.BaselineGDP               = baseTbl.Y_1;
    out.ScenarioGDP               = scenTbl.Y_1;
    out.GDPDeviation              = scenTbl.Y_1 - baseTbl.Y_1;
    out.GDPDeviationPctOfBaseline = safe_divide(out.GDPDeviation, baseGDP) .* 100;

    out.ConsumptionChange         = scen_C    - base_C;
    out.InvestmentChange          = scen_I    - base_I;
    out.GovernmentChange          = scen_Gov  - base_Gov;
    out.HousingPVChange           = scen_HsPV - base_HsPV;
    out.TradeBalanceChange        = scen_NX   - base_NX;

    out.ConsumptionPctOfBaseline  = safe_divide(out.ConsumptionChange,  baseGDP) .* 100;
    out.InvestmentPctOfBaseline   = safe_divide(out.InvestmentChange,   baseGDP) .* 100;
    out.GovernmentPctOfBaseline   = safe_divide(out.GovernmentChange,   baseGDP) .* 100;
    out.HousingPVPctOfBaseline    = safe_divide(out.HousingPVChange,    baseGDP) .* 100;
    out.TradeBalancePctOfBaseline = safe_divide(out.TradeBalanceChange, baseGDP) .* 100;

    componentSum = out.ConsumptionChange + out.InvestmentChange + ...
                   out.GovernmentChange  + out.HousingPVChange  + out.TradeBalanceChange;
    out.Residual              = out.GDPDeviation - componentSum;
    out.ResidualPctOfBaseline = safe_divide(out.Residual, baseGDP) .* 100;
end

function z = safe_divide(a, b)
    z = a ./ b;
    z(~isfinite(z)) = NaN;
end

function save_dual(fig, outDir, stem)
    svgPath = fullfile(outDir, char(string(stem) + '.svg'));
    pngPath = fullfile(outDir, char(string(stem) + '.png'));
    try
        exportgraphics(fig, svgPath, 'ContentType', 'vector');
    catch meSvg
        try
            set(fig, 'Renderer', 'painters');
            print(fig, svgPath, '-dsvg');
        catch mePrint
            warning('generate_gdp_component_decomposition_figures:svgExportFailed', ...
                ['SVG export failed for "%s". Continuing with PNG only. ' ...
                 'exportgraphics error: %s | print error: %s'], ...
                stem, meSvg.message, mePrint.message);
        end
    end
    exportgraphics(fig, pngPath, 'Resolution', 300);
    close(fig);
end

function out = sanitize_filename(in)
    out = regexprep(string(in), '[^A-Za-z0-9_\-]', '_');
end
