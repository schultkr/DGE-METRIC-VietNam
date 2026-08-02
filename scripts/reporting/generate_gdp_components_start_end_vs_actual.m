%% GDP components at Baseline start/end vs. observed 2019 shares
% Compares the expenditure-side GDP decomposition
%   Y_1 = P_1*(C_1 + I_1 + G_1 + I_G_1) + IH_1*PH_1 + I_PV_1 + NX_1
% at the Baseline simulation start year (2025) and reporting end year
% (2050), against Vietnam 2019 national-accounts shares.
%
% Workbook/data inputs used by this script:
%   1) Model output data (repo):
%      - ExcelFiles/Output/Baseline.csv
%      - Provides simulated component levels for 2025 and 2050.
%   2) Actual national-accounts workbook (external, not tracked in repo):
%      - IO_GSO_2019.xlsx, sheet "GSO_REDUCED": aggregate actual totals
%        (CONS, GC, GFCF, INVNT, EXPO, IMPO, TOTAL).
%      - IO_GSO_2019.xlsx, sheet "E_IOT 2019 NSX 23032025": housing GFCF
%        from row "Residental house" and column "GFCF".
%
% Seven categories are shown: Private Consumption, Government Consumption,
% Private Investment (I_1 only), Housing Investment (IH_1*PH_1), Solar/PV
% Investment (I_PV_1), Government Investment (I_G_1), and Net Exports.
%
% Because GSO reports GFCF+INVNT as one aggregate (no direct split into
% private/government/housing/solar), three pieces of the Actual (2019) bar
% are handled as follows:
%   - Housing Investment: read directly from the GSO IO workbook.
%   - Government Investment: estimated by applying the model's simulated
%     start-year government consumption/investment split to actual GC.
%   - Solar/PV Investment: estimated by applying the model's simulated
%     start-year solar share of non-housing private investment.
%   Both proxies use the start year only. The end year is a net-zero
%   transition endpoint and is not representative of 2019 structure.
% Private Investment is the residual after the above allocations.

close all;

repoRoot   = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd     = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

%% Configuration -----------------------------------------------------------

baselineCsv = fullfile(repoRoot, 'ExcelFiles', 'Output', 'Baseline.csv');
startYear   = 2025;
reportingEndYear  = 2050;
simulationEndYear = 2100;

% External actual-data workbook (not tracked in this repo, see docs/data_sources.md)
actualDataFile   = 'C:\Users\schul\Dropbox\2025_GIZ_Vietnam\Data\GSO\data\raw\IO_GSO_2019.xlsx';
if ~isfile(actualDataFile)
    fprintf(2, 'Actual data file not found at default path:\n  %s\n', actualDataFile);
    userPath = strtrim(input(['Enter full path to IO_GSO_2019.xlsx ' ...
        '(or press Enter to cancel): '], 's'));

    if isempty(userPath)
        error('generate_gdp_components_start_end_vs_actual:missingActualDataFile', ...
            ['Actual data file not found: %s. No alternate path provided. ' ...
             'See docs/data_sources.md for instructions.'], actualDataFile);
    end

    userPath = strrep(userPath, '"', '');
    if ~isfile(userPath)
        error('generate_gdp_components_start_end_vs_actual:missingActualDataFile', ...
            ['Provided actual data file path does not exist: %s. ' ...
             'See docs/data_sources.md for instructions.'], userPath);
    end

    actualDataFile = userPath;
end
% Workbook sheets used from IO_GSO_2019.xlsx:
% - GSO_REDUCED: aggregate expenditure components (CONS/GC/GFCF/INVNT/EXPO/IMPO/TOTAL)
% - E_IOT 2019 NSX 23032025: housing line item used to isolate actual housing investment
actualSheet      = 'GSO_REDUCED';
actualHousingSheet = 'E_IOT 2019 NSX 23032025';
actualYear       = 2019;

outDir = fullfile(repoRoot, 'Figures', 'Baseline', 'GDPComponents');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

colors = struct();
colors.consumption          = [0.00 0.45 0.74];
colors.government            = [0.47 0.67 0.19];
colors.investment            = [0.85 0.33 0.10];
colors.housingInvestment     = [0.64 0.43 0.24];
colors.solarInvestment       = [0.93 0.69 0.13];
colors.governmentInvestment  = [0.20 0.55 0.55];
colors.trade                 = [0.49 0.18 0.56];

set(groot, 'defaultAxesFontSize', 12, ...
           'defaultTextFontSize', 12, ...
           'defaultLegendFontSize', 10, ...
           'defaultAxesFontName', 'Arial', ...
           'defaultTextFontName', 'Arial');

%% Load simulated Baseline components --------------------------------------

requiredVars = ["Year", "Y_1", "P_1", "C_1", "I_1", "G_1", "I_G_1", "IH_1", "PH_1", "I_PV_1"];
baseline = readtable(baselineCsv);
require_vars(baseline, requiredVars, 'Baseline_replication.csv');

startRow = baseline(baseline.Year == startYear, :);
endRow   = baseline(baseline.Year == reportingEndYear, :);
if height(startRow) ~= 1
    error('generate_gdp_components_start_end_vs_actual:missingStartYear', ...
        'Expected exactly one row for Year == %d in %s, found %d.', startYear, baselineCsv, height(startRow));
end
if height(endRow) ~= 1
    error('generate_gdp_components_start_end_vs_actual:missingEndYear', ...
        'Expected exactly one row for Year == %d in %s, found %d.', reportingEndYear, baselineCsv, height(endRow));
end

startShares = compute_model_shares(startRow);
endShares   = compute_model_shares(endRow);

%% Load actual (GSO 2019) shares --------------------------------------------

actual = read_gso_actuals(actualDataFile, actualSheet);

actualConsumption     = actual.CONS / actual.TOTAL * 100;
actualGovConsShare    = actual.GC   / actual.TOTAL * 100;
actualInvestmentTotal = (actual.GFCF + actual.INVNT) / actual.TOTAL * 100;
actualNetExports      = (actual.EXPO - actual.IMPO)  / actual.TOTAL * 100;

% Housing Investment is read directly from the GSO 2019 IO table's
% "Residental house" GFCF row -- actual reported data, not an estimate.
residentialGFCF = read_gso_named_cell(actualDataFile, actualHousingSheet, ...
    'Residental house', 'GFCF', 6);
actualHousingInvestment = residentialGFCF / actual.TOTAL * 100;
remainingAfterHousing = actualInvestmentTotal - actualHousingInvestment;
if remainingAfterHousing < 0
    warning('generate_gdp_components_start_end_vs_actual:actualHousingExceedsTotal', ...
        ['Actual Housing Investment (%.2f%% of GDP) exceeds total actual Investment ' ...
         '(%.2f%% of GDP); clamping Housing Investment to the total.'], ...
        actualHousingInvestment, actualInvestmentTotal);
    actualHousingInvestment = actualInvestmentTotal;
    remainingAfterHousing = 0;
end

% Government Investment is estimated: apply the model's government
% consumption/investment ratio from the simulated start year to the actual
% GC figure. See file header for why the start year (not an average with
% the end year) is the right proxy.
govConsShareProxy = startShares.GovernmentConsumption / ...
    (startShares.GovernmentConsumption + startShares.GovernmentInvestment);

actualGovInvestment = actualGovConsShare * (1 - govConsShareProxy) / govConsShareProxy;
if actualGovInvestment > remainingAfterHousing
    warning('generate_gdp_components_start_end_vs_actual:actualGovInvestmentEstimateExceedsTotal', ...
        ['Estimated actual Government Investment (%.2f%% of GDP) exceeds remaining actual ' ...
         'Investment after Housing (%.2f%% of GDP); clamping to the remainder.'], ...
        actualGovInvestment, remainingAfterHousing);
    actualGovInvestment = remainingAfterHousing;
end
remainingAfterGov = remainingAfterHousing - actualGovInvestment;

% Solar/PV Investment is estimated: GSO has no renewable-investment line, so
% apply the model's solar share of non-housing private investment from the
% simulated start year to whatever remains of GFCF+INVNT.
solarShareProxy = startShares.SolarInvestment / ...
    (startShares.PrivateInvestment + startShares.SolarInvestment);

actualSolarInvestment   = remainingAfterGov * solarShareProxy;
actualPrivateInvestment = remainingAfterGov - actualSolarInvestment;

actualShares = struct( ...
    'Consumption',           actualConsumption, ...
    'GovernmentConsumption', actualGovConsShare, ...
    'PrivateInvestment',     actualPrivateInvestment, ...
    'HousingInvestment',     actualHousingInvestment, ...
    'SolarInvestment',       actualSolarInvestment, ...
    'GovernmentInvestment',  actualGovInvestment, ...
    'NetExports',            actualNetExports);

%% Build summary table -------------------------------------------------------

component = ["Consumption"; "GovernmentConsumption"; "PrivateInvestment"; ...
             "HousingInvestment"; "SolarInvestment"; "GovernmentInvestment"; ...
             "NetExports"; "Total"];

actualCol = [actualShares.Consumption; actualShares.GovernmentConsumption; ...
             actualShares.PrivateInvestment; actualShares.HousingInvestment; ...
             actualShares.SolarInvestment; actualShares.GovernmentInvestment; ...
             actualShares.NetExports; NaN];
actualCol(end) = sum(actualCol(1:end-1));

startCol = [startShares.Consumption; startShares.GovernmentConsumption; ...
            startShares.PrivateInvestment; startShares.HousingInvestment; ...
            startShares.SolarInvestment; startShares.GovernmentInvestment; ...
            startShares.NetExports; NaN];
startCol(end) = sum(startCol(1:end-1));

endCol = [endShares.Consumption; endShares.GovernmentConsumption; ...
          endShares.PrivateInvestment; endShares.HousingInvestment; ...
          endShares.SolarInvestment; endShares.GovernmentInvestment; ...
          endShares.NetExports; NaN];
endCol(end) = sum(endCol(1:end-1));

summary = table(component, actualCol, startCol, endCol, 'VariableNames', ...
    {'Component', ...
     sprintf('Actual_%d_PctGDP', actualYear), ...
     sprintf('Simulated_%d_PctGDP', startYear), ...
    sprintf('Simulated_%d_PctGDP', reportingEndYear)});

disp(summary);

summaryCsv = fullfile(outDir, 'GDPComponents_StartEndVsActual.csv');
writetable(summary, summaryCsv);
fprintf('Wrote summary table to %s\n', summaryCsv);

%% Plot stacked bar chart -----------------------------------------------------

barNames = {sprintf('Actual (%d)', actualYear), ...
            sprintf('Simulated start (%d)', startYear), ...
            sprintf('Reporting end (%d)', reportingEndYear)};
barCats = categorical(barNames);
barCats = reordercats(barCats, barNames);

stackedData = [actualShares.Consumption, actualShares.GovernmentConsumption, actualShares.PrivateInvestment, actualShares.HousingInvestment, actualShares.SolarInvestment, actualShares.GovernmentInvestment, actualShares.NetExports; ...
               startShares.Consumption,  startShares.GovernmentConsumption,  startShares.PrivateInvestment,  startShares.HousingInvestment,  startShares.SolarInvestment,  startShares.GovernmentInvestment,  startShares.NetExports; ...
               endShares.Consumption,    endShares.GovernmentConsumption,    endShares.PrivateInvestment,    endShares.HousingInvestment,    endShares.SolarInvestment,    endShares.GovernmentInvestment,    endShares.NetExports];

fig = figure('Color', 'w', 'Position', [80 80 900 560]);
bh = bar(barCats, stackedData, 'stacked');
bh(1).FaceColor = colors.consumption;
bh(2).FaceColor = colors.government;
bh(3).FaceColor = colors.investment;
bh(4).FaceColor = colors.housingInvestment;
bh(5).FaceColor = colors.solarInvestment;
bh(6).FaceColor = colors.governmentInvestment;
bh(7).FaceColor = colors.trade;

componentLabels = ["Private Consumption", "Government Consumption", ...
                    "Private Investment", "Housing Investment", ...
                    "Solar/PV Investment (est. for Actual)", ...
                    "Government Investment (I_G, est. for Actual)", "Net Exports"];
for iBar = 1:numel(bh)
    bh(iBar).DisplayName = componentLabels(iBar);
end

ax = gca;
yline(ax, 100, ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.0, 'HandleVisibility', 'off');
yline(ax, 0, '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.5, 'HandleVisibility', 'off');
grid(ax, 'on');
box(ax, 'off');
ylabel(ax, '% of GDP');
title(ax, sprintf(['GDP components — Baseline start vs. reporting end (%d) ', ...
    '[simulation horizon to %d; actual = GSO %d]'], ...
    reportingEndYear, simulationEndYear, actualYear), 'Interpreter', 'none');
legend(ax, 'Location', 'southoutside', 'Orientation', 'horizontal', 'NumColumns', 3, 'Box', 'off', 'Interpreter', 'none');

save_dual(fig, outDir, 'GDPComponents_StartEndVsActual');
fprintf('Saved GDP components figure to %s\n', outDir);

%% Local functions ------------------------------------------------------------

function require_vars(tbl, vars, label)
    vars = string(vars);
    missing = vars(~ismember(vars, string(tbl.Properties.VariableNames)));
    if ~isempty(missing)
        error('generate_gdp_components_start_end_vs_actual:missingVars', ...
            'Missing variable(s) in %s: %s', label, strjoin(cellstr(missing), ', '));
    end
end

function trade = resolve_trade_balance_value(row)
    names = string(row.Properties.VariableNames);
    if ismember('NX_1', names)
        trade = row.NX_1;
        if ismember('NX_1_1', names)
            trade = trade + row.NX_1_1;
        end
        return
    end
    if ismember('X_1', names) && ismember('M_1', names)
        trade = row.X_1 - row.M_1;
        return
    end
    error('generate_gdp_components_start_end_vs_actual:missingTradeBalance', ...
        'Neither NX_1 nor X_1/M_1 were found. Cannot compute net exports.');
end

function shares = compute_model_shares(row)
    gdp        = row.Y_1;
    cons       = row.P_1 .* row.C_1;
    govCons    = row.P_1 .* row.G_1;
    govInv     = row.P_1 .* row.I_G_1;
    privInv    = row.P_1 .* row.I_1;
    housingInv = row.IH_1 .* row.PH_1;
    solarInv   = row.I_PV_1;
    nx         = resolve_trade_balance_value(row);

    shares = struct( ...
        'Consumption',           cons       / gdp * 100, ...
        'GovernmentConsumption', govCons    / gdp * 100, ...
        'PrivateInvestment',     privInv    / gdp * 100, ...
        'HousingInvestment',     housingInv / gdp * 100, ...
        'SolarInvestment',       solarInv   / gdp * 100, ...
        'GovernmentInvestment',  govInv     / gdp * 100, ...
        'NetExports',            nx         / gdp * 100);
end

function actual = read_gso_actuals(file, sheet)
    if ~isfile(file)
        error('generate_gdp_components_start_end_vs_actual:missingActualFile', ...
            'Actual data file not found: %s', file);
    end
    raw = readcell(file, 'Sheet', sheet);
    header = string(raw(1, :));

    colPrimary = find(header == "Primary", 1);
    colCONS    = find(header == "CONS", 1);
    colGC      = find(header == "GC", 1);
    colGFCF    = find(header == "GFCF", 1);
    colINVNT   = find(header == "INVNT", 1);
    colEXPO    = find(header == "EXPO", 1);
    colIMPO    = find(header == "IMPO", 1);
    colTOTAL   = find(header == "TOTAL", 1);
    if any(cellfun(@isempty, {colPrimary, colCONS, colGC, colGFCF, colINVNT, colEXPO, colIMPO, colTOTAL}))
        error('generate_gdp_components_start_end_vs_actual:unexpectedHeader', ...
            'Expected columns Primary/CONS/GC/GFCF/INVNT/EXPO/IMPO/TOTAL not found in sheet "%s" of %s.', sheet, file);
    end

    % The aggregate final-demand row has no sector breakdown (Primary column
    % blank) but a populated TOTAL column; it precedes the row of GDP shares.
    rowIdx = [];
    for r = 2:size(raw, 1)
        if ismissing(raw{r, colPrimary}) && isnumeric(raw{r, colTOTAL}) && ~isempty(raw{r, colTOTAL}) && ~isnan(raw{r, colTOTAL})
            rowIdx = r;
            break
        end
    end
    if isempty(rowIdx)
        error('generate_gdp_components_start_end_vs_actual:aggregateRowNotFound', ...
            'Could not locate the aggregate final-demand row in sheet "%s" of %s.', sheet, file);
    end

    actual.CONS  = raw{rowIdx, colCONS};
    actual.GC    = raw{rowIdx, colGC};
    actual.GFCF  = raw{rowIdx, colGFCF};
    actual.INVNT = raw{rowIdx, colINVNT};
    actual.EXPO  = raw{rowIdx, colEXPO};
    actual.IMPO  = raw{rowIdx, colIMPO};
    actual.TOTAL = raw{rowIdx, colTOTAL};

    identityCheck = actual.CONS + actual.GC + actual.GFCF + actual.INVNT + actual.EXPO - actual.IMPO;
    if abs(identityCheck - actual.TOTAL) > 1e-3 * abs(actual.TOTAL)
        error('generate_gdp_components_start_end_vs_actual:identityMismatch', ...
            ['GSO actual-data identity CONS+GC+GFCF+INVNT+EXPO-IMPO ~= TOTAL failed ' ...
             '(got %.3f vs %.3f); row/column mapping may be wrong.'], identityCheck, actual.TOTAL);
    end
end

function value = read_gso_named_cell(file, sheet, rowLabel, colLabel, headerRows)
    if ~isfile(file)
        error('generate_gdp_components_start_end_vs_actual:missingActualFile', ...
            'Actual data file not found: %s', file);
    end
    raw = readcell(file, 'Sheet', sheet);

    colIdx = [];
    for r = 1:min(headerRows, size(raw, 1))
        for c = 1:size(raw, 2)
            v = raw{r, c};
            if (ischar(v) || isstring(v)) && strcmp(strtrim(string(v)), colLabel)
                colIdx = c;
                break
            end
        end
        if ~isempty(colIdx)
            break
        end
    end
    if isempty(colIdx)
        error('generate_gdp_components_start_end_vs_actual:columnNotFound', ...
            'Could not find column "%s" in the first %d rows of sheet "%s" of %s.', ...
            colLabel, headerRows, sheet, file);
    end

    rowIdx = [];
    matchCount = 0;
    for r = 1:size(raw, 1)
        for c = 1:size(raw, 2)
            v = raw{r, c};
            if (ischar(v) || isstring(v)) && strcmpi(strtrim(string(v)), rowLabel)
                rowIdx = r;
                matchCount = matchCount + 1;
            end
        end
    end
    if matchCount == 0
        error('generate_gdp_components_start_end_vs_actual:rowNotFound', ...
            'Could not find row "%s" in sheet "%s" of %s.', rowLabel, sheet, file);
    elseif matchCount > 1
        error('generate_gdp_components_start_end_vs_actual:ambiguousRow', ...
            'Row label "%s" matched %d cells in sheet "%s" of %s; expected exactly one.', ...
            rowLabel, matchCount, sheet, file);
    end

    value = raw{rowIdx, colIdx};
    if ~isnumeric(value) || isempty(value) || isnan(value)
        error('generate_gdp_components_start_end_vs_actual:nonNumericValue', ...
            'Value at row "%s", column "%s" in sheet "%s" of %s is not a valid number.', ...
            rowLabel, colLabel, sheet, file);
    end
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
            warning('generate_gdp_components_start_end_vs_actual:svgExportFailed', ...
                ['SVG export failed for "%s". Continuing with PNG only. ' ...
                 'exportgraphics error: %s | print error: %s'], ...
                stem, meSvg.message, mePrint.message);
        end
    end
    exportgraphics(fig, pngPath, 'Resolution', 300);
    close(fig);
end
