% plot_baseline_revised_pdp8_high_rts_split
% Build revised PDP8-high RTS sector split series and export baseline plots
% for PV deployment (capacity) and PV generation.
%
% Run from repository root:
%   run('scripts/reporting/plot_baseline_revised_pdp8_high_rts_split.m')

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

workbookPath = fullfile(repoRoot, 'ExcelFiles', 'PDP8', 'Vietnam_EnergyExpert_ScenarioInputs - Adjust_2505.xlsx');
sheetName = 'PDP8_revised';
outDir = fullfile(repoRoot, 'Figures', 'RTS');
if ~isfolder(outDir)
    mkdir(outDir);
end

if ~isfile(workbookPath)
    error('plot_baseline_revised_pdp8_high_rts_split:MissingWorkbook', ...
        'Workbook not found:\n  %s', workbookPath);
end

raw = readcell(workbookPath, 'Sheet', sheetName);
hdrRow = find(cellfun(@(x) (ischar(x) || isstring(x)) && strcmpi(strtrim(string(x)), "Year"), raw(:, 1)), 1, 'first');
if isempty(hdrRow)
    error('plot_baseline_revised_pdp8_high_rts_split:MissingHeaderRow', ...
        'Could not find header row (Year) in sheet %s.', sheetName);
end

headers = string(raw(hdrRow, :));
rows = raw((hdrRow + 1):end, :);

iYear = find(strcmpi(strtrim(headers), 'Year'), 1);
iCapHigh = find(strcmpi(strtrim(headers), 'Check PDP8 - High scenario'), 1);
iCap = find(strcmpi(strtrim(headers), 'RTS_Capacity_GW'), 1);
iCF = find(strcmpi(strtrim(headers), 'RTS_CapacityFactor'), 1);

if isempty(iYear) || isempty(iCapHigh) || isempty(iCap) || isempty(iCF)
    error('plot_baseline_revised_pdp8_high_rts_split:MissingColumns', ...
        ['Required columns are missing. Need: Year, Check PDP8 - High scenario, ' ...
         'RTS_Capacity_GW, RTS_CapacityFactor.']);
end

yearVals = as_numeric(rows(:, iYear));
capHighVals = as_numeric(rows(:, iCapHigh));
capVals = as_numeric(rows(:, iCap));
cfVals = as_numeric(rows(:, iCF));

isRowData = isfinite(yearVals) & isfinite(capVals) & isfinite(cfVals);
years = yearVals(isRowData);
capHigh = capHighVals(isRowData);
capBase = capVals(isRowData);
cf = cfVals(isRowData);

% Fill missing high-series years by linear interpolation over available anchors.
if any(isnan(capHigh))
    iKnown = find(~isnan(capHigh));
    if numel(iKnown) < 2
        warning('plot_baseline_revised_pdp8_high_rts_split:InsufficientHighAnchors', ...
            ['High scenario capacity has insufficient anchor points; using RTS_Capacity_GW ' ...
             'for missing years.']);
        capHigh(isnan(capHigh)) = capBase(isnan(capHigh));
    else
        capHighInterp = interp1(years(iKnown), capHigh(iKnown), years, 'linear', 'extrap');
        capHigh(isnan(capHigh)) = capHighInterp(isnan(capHigh));
    end
end

% Convert capacity (GW) to annual generation (GWh): GW * CF * 8760 h/yr * 1000 MWh/GWh.
genHighGWh = capHigh .* cf * 8760;

% Sector split logic consistent with baseline RTS processing:
%  - industrial share anchored from expert email at 2030 and 2050
%  - commercial is 30% of household residual
capIndShare = interpolate_industrial_share(years, [2030, 2050], [18231/36733, 59000/137670]);
genIndShare = interpolate_industrial_share(years, [2030, 2050], [23361/44827, 77676/176936]);
commercialShareOfHousehold = 0.30;

capInd = capHigh .* capIndShare;
capHouseholdTotal = max(capHigh - capInd, 0);
capCom = commercialShareOfHousehold .* capHouseholdTotal;
capRes = (1 - commercialShareOfHousehold) .* capHouseholdTotal;

genInd = genHighGWh .* genIndShare;
genHouseholdTotal = max(genHighGWh - genInd, 0);
genCom = commercialShareOfHousehold .* genHouseholdTotal;
genRes = (1 - commercialShareOfHousehold) .* genHouseholdTotal;

% Plot 1: deployment (capacity)
fig1 = figure('Color', 'w');
area(years, [capRes, capCom, capInd], 'LineStyle', 'none');
hold on;
plot(years, capHigh, 'k-', 'LineWidth', 1.5);
hold off;
grid on;
xlabel('Year');
ylabel('Capacity (GW)');
title('Baseline (Revised PDP8 High): PV Deployment by Segment');
legend({'Residential', 'Commercial', 'Industrial', 'Total (PDP8 High)'}, 'Location', 'northwest');

% Plot 2: generation
fig2 = figure('Color', 'w');
area(years, [genRes, genCom, genInd], 'LineStyle', 'none');
hold on;
plot(years, genHighGWh, 'k-', 'LineWidth', 1.5);
hold off;
grid on;
xlabel('Year');
ylabel('Generation (GWh/year)');
title('Baseline (Revised PDP8 High): PV Generation by Segment');
legend({'Residential', 'Commercial', 'Industrial', 'Total (PDP8 High)'}, 'Location', 'northwest');

png1 = fullfile(outDir, 'Baseline_RevisedPDP8High_PV_Deployment_By_Segment.png');
pdf1 = fullfile(outDir, 'Baseline_RevisedPDP8High_PV_Deployment_By_Segment.pdf');
png2 = fullfile(outDir, 'Baseline_RevisedPDP8High_PV_Generation_By_Segment.png');
pdf2 = fullfile(outDir, 'Baseline_RevisedPDP8High_PV_Generation_By_Segment.pdf');

exportgraphics(fig1, png1, 'Resolution', 300);
exportgraphics(fig1, pdf1, 'ContentType', 'vector');
exportgraphics(fig2, png2, 'Resolution', 300);
exportgraphics(fig2, pdf2, 'ContentType', 'vector');

fprintf('\nCreated revised PDP8-high baseline RTS plots:\n');
fprintf('  %s\n', png1);
fprintf('  %s\n', pdf1);
fprintf('  %s\n', png2);
fprintf('  %s\n', pdf2);

function x = as_numeric(v)
if isnumeric(v)
    x = double(v);
else
    x = str2double(string(v));
end
end

function sh = interpolate_industrial_share(years, anchorYears, anchorShares)
sh = interp1(anchorYears, anchorShares, years, 'linear', 'extrap');
sh(years <= anchorYears(1)) = anchorShares(1);
sh(years >= anchorYears(end)) = anchorShares(end);
sh = min(max(sh, 0), 1);
end