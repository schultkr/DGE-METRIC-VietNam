% create_baseline_path_definition_template  Create scenario user-input workbook.
%
% Run from the repository root:
%   run('scripts/maintenance/create_baseline_path_definition_template.m')
%
% Output:
%   ExcelFiles/ScenarioPathDefinition.xlsx
%     Sheet Baseline  -> read by create_baseline_from_user_input_file.m
%     Sheet NZ        -> read by update_nz_sheet.m

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPwd = pwd;
cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
cd(repoRoot);
setup_paths();

outFile = fullfile(repoRoot, 'ExcelFiles', 'ScenarioPathDefinition.xlsx');
outSheet = 'Baseline';

startYear = 2025;
endYear = 2050;
years = startYear:endYear;
nYears = numel(years);

yearStartCol = 'D';
yearEndCol = 'AC';

if isfile(outFile)
    delete(outFile);
end

% Seed workbook and sheet.
writecell({'Baseline Path Definition Template'}, outFile, 'Sheet', outSheet, 'Range', 'A1');

% Title and guidance.
writecell({'Input Variable'; 'Import Key'; 'Exogenous variable(s) / conversion rule'}, outFile, 'Sheet', outSheet, 'Range', 'A8:C8');
writecell(num2cell(years), outFile, 'Sheet', outSheet, 'Range', [yearStartCol '9:' yearEndCol '9']);
writecell({'Year'}, outFile, 'Sheet', outSheet, 'Range', 'C9');

% Repeat year headers per block for easier reading without scrolling.
blockYearRows = [11, 23, 39, 50, 57, 60, 64, 71, 78, 82, 86, 93];
for r = blockYearRows
    writecell(num2cell(years), outFile, 'Sheet', outSheet, 'Range', sprintf('%s%d:%s%d', yearStartCol, r, yearEndCol, r));
    writecell({'Year'}, outFile, 'Sheet', outSheet, 'Range', sprintf('C%d', r));
end

writecell({'Required block: Value Added'}, outFile, 'Sheet', outSheet, 'Range', 'A10');
writecell({'Total value-added growth factor'; 'gva_growth_total'; 'required'}, outFile, 'Sheet', outSheet, 'Range', 'A10:C10');
writecell({'VA share - Primary'; 'va_share_1'; 'required'}, outFile, 'Sheet', outSheet, 'Range', 'A12:C12');
writecell({'VA share - Fossil'; 'va_share_2'; 'required'}, outFile, 'Sheet', outSheet, 'Range', 'A13:C13');
writecell({'VA share - Renewables'; 'va_share_3'; 'required'}, outFile, 'Sheet', outSheet, 'Range', 'A14:C14');
writecell({'VA share - Secondary'; 'va_share_4'; 'required'}, outFile, 'Sheet', outSheet, 'Range', 'A15:C15');
writecell({'VA share - Tertiary'; 'va_share_5'; 'required'}, outFile, 'Sheet', outSheet, 'Range', 'A16:C16');

writecell({'Required block: Employment'}, outFile, 'Sheet', outSheet, 'Range', 'A22');
writecell({'Total employment growth factor'; 'emp_growth_total'; 'required'}, outFile, 'Sheet', outSheet, 'Range', 'A22:C22');
writecell({'Employment share - Primary'; 'emp_share_1'; 'required'}, outFile, 'Sheet', outSheet, 'Range', 'A24:C24');
writecell({'Employment share - Fossil'; 'emp_share_2'; 'required'}, outFile, 'Sheet', outSheet, 'Range', 'A25:C25');
writecell({'Employment share - Renewables'; 'emp_share_3'; 'required'}, outFile, 'Sheet', outSheet, 'Range', 'A26:C26');
writecell({'Employment share - Secondary'; 'emp_share_4'; 'required'}, outFile, 'Sheet', outSheet, 'Range', 'A27:C27');
writecell({'Employment share - Tertiary'; 'emp_share_5'; 'required'}, outFile, 'Sheet', outSheet, 'Range', 'A28:C28');

writecell({'Optional block: Emissions and Fossil Paths'}, outFile, 'Sheet', outSheet, 'Range', 'A39');
writecell({'Sector emissions index - Primary'; 'idx_E_1_1'; 'optional, base year typically 1'}, outFile, 'Sheet', outSheet, 'Range', 'A40:C40');
writecell({'Sector emissions index - Fossil'; 'idx_E_2_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A41:C41');
writecell({'Sector emissions index - Renewables'; 'idx_E_3_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A42:C42');
writecell({'Sector emissions index - Secondary'; 'idx_E_4_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A43:C43');
writecell({'Sector emissions index - Tertiary'; 'idx_E_5_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A44:C44');
writecell({'Fossil production index'; 'idx_Q_2_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A46:C46');
writecell({'Fossil exports index'; 'idx_X_2_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A47:C47');

writecell({'Optional block: Public Capital Stock'}, outFile, 'Sheet', outSheet, 'Range', 'A50');
writecell({'Public capital stock index - Primary'; 'idx_K_G_1_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A51:C51');
writecell({'Public capital stock index - subsector 2 (fossil)'; 'idx_K_G_2_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A52:C52');
writecell({'Public capital stock index - subsector 3 (renewables)'; 'idx_K_G_3_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A53:C53');
writecell({'Public capital stock index - Secondary'; 'idx_K_G_4_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A54:C54');
writecell({'Public capital stock index - Tertiary'; 'idx_K_G_5_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A55:C55');

writecell({'Optional block: Target Investment Ratios'}, outFile, 'Sheet', outSheet, 'Range', 'A57');
writecell({'Target investment ratio - fossil'; 'exo_targetIY_2_1'; 'writes exo_targetIY_2_1 as input level (share of GDP); legacy idx_I_2_1 also accepted'}, outFile, 'Sheet', outSheet, 'Range', 'A58:C58');
writecell({'Target investment ratio - renewables'; 'exo_targetIY_3_1'; 'writes exo_targetIY_3_1 as input level (share of GDP); legacy idx_I_3_1 also accepted'}, outFile, 'Sheet', outSheet, 'Range', 'A59:C59');

writecell({'Optional block: Investment Prices'}, outFile, 'Sheet', outSheet, 'Range', 'A64');
writecell({'Investment price index - Primary'; 'idx_P_K_1_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A65:C65');
writecell({'Investment price index - subsector 2 (fossil)'; 'idx_P_K_2_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A66:C66');
writecell({'Investment price index - subsector 3 (renewables)'; 'idx_P_K_3_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A67:C67');
writecell({'Investment price index - Secondary'; 'idx_P_K_4_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A68:C68');
writecell({'Investment price index - Tertiary'; 'idx_P_K_5_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A69:C69');

writecell({'Optional block: Public Capital Interest Rates'}, outFile, 'Sheet', outSheet, 'Range', 'A71');
writecell({'Public capital interest rate index - Primary'; 'idx_r_G_1_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A72:C72');
writecell({'Public capital interest rate index - subsector 2 (fossil)'; 'idx_r_G_2_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A73:C73');
writecell({'Public capital interest rate index - subsector 3 (renewables)'; 'idx_r_G_3_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A74:C74');
writecell({'Public capital interest rate index - Secondary'; 'idx_r_G_4_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A75:C75');
writecell({'Public capital interest rate index - Tertiary'; 'idx_r_G_5_1'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A76:C76');

writecell({'Optional block: Sector Energy Efficiency Targets'}, outFile, 'Sheet', outSheet, 'Range', 'A86');
writecell({'Energy-efficiency target index - Primary'; 'idx_AI_1_1_2'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A87:C87');
writecell({'Energy-efficiency target index - Fossil'; 'idx_AI_2_1_2'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A88:C88');
writecell({'Energy-efficiency target index - Renewables'; 'idx_AI_3_1_2'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A89:C89');
writecell({'Energy-efficiency target index - Secondary'; 'idx_AI_4_1_2'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A90:C90');
writecell({'Energy-efficiency target index - Tertiary'; 'idx_AI_5_1_2'; 'optional'}, outFile, 'Sheet', outSheet, 'Range', 'A91:C91');

writecell({'Optional block: Rooftop Solar (PV)'}, outFile, 'Sheet', outSheet, 'Range', 'A93');
writecell({'Rooftop PV investment index'; 'idx_PV_1'; 'optional, index relative to base year; 1=no change'}, outFile, 'Sheet', outSheet, 'Range', 'A94:C94');
writecell({'Rooftop PV production index'; 'idx_PVEff_1'; 'optional, index relative to base year; 1=no change'}, outFile, 'Sheet', outSheet, 'Range', 'A95:C95');
writecell({'Power-factor efficiency index shock'; 'exo_PFEff'; 'optional, index relative to base year; 1=no change'}, outFile, 'Sheet', outSheet, 'Range', 'A96:C96');

% Defaults for required paths.
write_row(outFile, outSheet, 10, ones(1, nYears), yearStartCol, yearEndCol);
write_row(outFile, outSheet, 22, ones(1, nYears), yearStartCol, yearEndCol);

[vaInitShares, empInitShares, sharesSource] = read_initial_shares(repoRoot);
for iSub = 1:5
    write_row(outFile, outSheet, 11 + iSub, vaInitShares(iSub) * ones(1, nYears), yearStartCol, yearEndCol);
    write_row(outFile, outSheet, 23 + iSub, empInitShares(iSub) * ones(1, nYears), yearStartCol, yearEndCol);
end

% Interpolation formulas for share rows are applied via Excel COM in
% apply_template_formatting to ensure they are stored as real formulas
% (not text) across locale settings.

% Defaults for optional index-style paths.
for r = [40, 41, 42, 43, 44, 46, 47, 51, 52, 53, 54, 55, 65, 66, 67, 68, 69, 87, 88, 89, 90, 91, 94, 95, 96]
    write_row(outFile, outSheet, r, ones(1, nYears), yearStartCol, yearEndCol);
end

% Target investment shares/logicals and public capital rates default to 0.
for r = [58, 59, 72, 73, 74, 75, 76]
    write_row(outFile, outSheet, r, zeros(1, nYears), yearStartCol, yearEndCol);
end

apply_schema_with_conversion(outFile, outSheet, 'baseline');
apply_template_formatting(outFile, outSheet, shift_excel_col_name(yearEndCol, 1), 'E');

% ── NZ sheet ───────────────────────────────────────────────────
outSheetNZ = 'NZ';

writecell({'NZ Scenario Path Definition'}, outFile, 'Sheet', outSheetNZ, 'Range', 'A1');
writecell({'Input Variable'; 'Import Key'; 'Required/Notes'}, outFile, 'Sheet', outSheetNZ, 'Range', 'A8:C8');
writecell(num2cell(years), outFile, 'Sheet', outSheetNZ, 'Range', [yearStartCol '9:' yearEndCol '9']);
writecell({'Year'}, outFile, 'Sheet', outSheetNZ, 'Range', 'C9');

blockYearRowsNZ = [11, 13, 19, 22, 29];
for r = blockYearRowsNZ
    writecell(num2cell(years), outFile, 'Sheet', outSheetNZ, 'Range', sprintf('%s%d:%s%d', yearStartCol, r, yearEndCol, r));
    writecell({'Year'}, outFile, 'Sheet', outSheetNZ, 'Range', sprintf('C%d', r));
end

% Required block: aggregate emissions path.
writecell({'Aggregate emissions index'; 'idx_E_1'; 'required; 1=base-year level, 0.05=95% reduction'}, ...
    outFile, 'Sheet', outSheetNZ, 'Range', 'A10:C10');

% Optional blocks (section-header rows double as year-repeat rows).
writecell({'Optional block: Carbon Policy'}, outFile, 'Sheet', outSheetNZ, 'Range', 'A13');
writecell({'Cap-and-trade active (1=on, 0=off)'; 'exo_CapTrade_1'; 'optional; default: 1'}, ...
    outFile, 'Sheet', outSheetNZ, 'Range', 'A14:C14');

writecell({'Optional block: Rooftop Solar (PV)'}, outFile, 'Sheet', outSheetNZ, 'Range', 'A19');
writecell({'Rooftop PV investment index'; 'idx_PV_1'; 'optional; index relative to base year'}, ...
    outFile, 'Sheet', outSheetNZ, 'Range', 'A20:C20');

writecell({'Optional block: Sector Energy Efficiency Targets'}, outFile, 'Sheet', outSheetNZ, 'Range', 'A22');
writecell({'EE target index - Primary';    'idx_AI_1_1_2'; 'optional'}, outFile, 'Sheet', outSheetNZ, 'Range', 'A23:C23');
writecell({'EE target index - Fossil';     'idx_AI_2_1_2'; 'optional'}, outFile, 'Sheet', outSheetNZ, 'Range', 'A24:C24');
writecell({'EE target index - Renewables'; 'idx_AI_3_1_2'; 'optional'}, outFile, 'Sheet', outSheetNZ, 'Range', 'A25:C25');
writecell({'EE target index - Secondary';  'idx_AI_4_1_2'; 'optional'}, outFile, 'Sheet', outSheetNZ, 'Range', 'A26:C26');
writecell({'EE target index - Tertiary';   'idx_AI_5_1_2'; 'optional'}, outFile, 'Sheet', outSheetNZ, 'Range', 'A27:C27');

writecell({'Optional block: Fossil Paths'}, outFile, 'Sheet', outSheetNZ, 'Range', 'A29');
writecell({'Fossil production index'; 'idx_Q_2_1'; 'optional'}, outFile, 'Sheet', outSheetNZ, 'Range', 'A30:C30');
writecell({'Fossil exports index';    'idx_X_2_1'; 'optional'}, outFile, 'Sheet', outSheetNZ, 'Range', 'A31:C31');

% Default values.
write_row(outFile, outSheetNZ, 10, ones(1, nYears), yearStartCol, yearEndCol);   % idx_E_1
write_row(outFile, outSheetNZ, 14, ones(1, nYears), yearStartCol, yearEndCol);   % exo_CapTrade_1
for r = [17, 20, 23, 24, 25, 26, 27, 30, 31]
    write_row(outFile, outSheetNZ, r, ones(1, nYears), yearStartCol, yearEndCol);
end

apply_schema_with_conversion(outFile, outSheetNZ, 'nz');
apply_nz_formatting(outFile, outSheetNZ, shift_excel_col_name(yearEndCol, 1), 'E');

fprintf('\nScenario path template created.\n');
fprintf('  File: %s\n', outFile);
fprintf('  Sheets: %s, %s\n', outSheet, outSheetNZ);
fprintf('  Years: %d-%d (%d columns)\n', startYear, endYear, nYears);
fprintf('  Initial VA/employment shares source: %s\n', sharesSource);

function [vaSharesOut, empSharesOut, sourceLabel] = read_initial_shares(repoRoot)
% Read initial sector shares from calibration files if available.
% Falls back to equal shares when no valid source is found.

defaultShares = 0.2 * ones(5, 1);
vaSharesOut = defaultShares;
empSharesOut = defaultShares;
sourceLabel = 'Default equal shares (0.2 each)';

calibrationWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelCalibration5Sectorsand1Regions.xlsx');
if isfile(calibrationWorkbook)
    try
        vaRaw = readmatrix(calibrationWorkbook, 'Sheet', 'Start', 'Range', 'B23:B27');
        empRaw = readmatrix(calibrationWorkbook, 'Sheet', 'Start', 'Range', 'B29:B33');
        [okVA, vaShares] = normalize_share_vector(vaRaw);
        [okEmp, empShares] = normalize_share_vector(empRaw);
        if okVA && okEmp
            vaSharesOut = vaShares;
            empSharesOut = empShares;
            sourceLabel = 'ModelCalibration5Sectorsand1Regions.xlsx (Start!B23:B27, B29:B33)';
            return;
        end
    catch
    end
end

legacyWorkbook = fullfile(repoRoot, 'ExcelFiles', 'ModelSimulationandCalibration5Sectorsand1Regions.xlsx');
if isfile(legacyWorkbook)
    try
        vaLegacy = readmatrix(legacyWorkbook, 'Sheet', 'Baseline_Input', 'Range', 'C242:C246');
        empLegacy = readmatrix(legacyWorkbook, 'Sheet', 'Baseline_Input', 'Range', 'C257:C261');
        [okVA, vaShares] = normalize_share_vector(vaLegacy);
        [okEmp, empShares] = normalize_share_vector(empLegacy);
        if okVA && okEmp
            vaSharesOut = vaShares;
            empSharesOut = empShares;
            sourceLabel = 'ModelSimulationandCalibration5Sectorsand1Regions.xlsx (Baseline_Input!C242:C246, C257:C261)';
            return;
        end
    catch
    end
end

end

function [isValid, shares] = normalize_share_vector(values)
values = values(:);
isValid = isnumeric(values) && numel(values) == 5 && all(isfinite(values));
if ~isValid
    shares = 0.2 * ones(5, 1);
    return;
end

total = sum(values);
if total <= 0
    isValid = false;
    shares = 0.2 * ones(5, 1);
    return;
end

shares = values / total;
end

function write_row(filePath, sheetName, rowNum, values, colStart, colEnd)
range = sprintf('%s%d:%s%d', colStart, rowNum, colEnd, rowNum);
writematrix(values, filePath, 'Sheet', sheetName, 'Range', range);
end

function apply_schema_with_conversion(filePath, sheetName, schemaName)
try
    exl = actxserver('excel.application');
    exl.Visible = false;
    exl.DisplayAlerts = false;
    wb = exl.Workbooks.Open(filePath, 0, false);
    ws = wb.Worksheets.Item(sheetName);

    c8 = string(ws.Range('C8').Value);
    if ~strcmpi(strtrim(c8), 'Conversion Rule')
        ws.Columns.Item('C:C').Insert;
    end

    ws.Range('A8').Value = 'Input Variable';
    ws.Range('B8').Value = 'Import Key';
    ws.Range('C8').Value = 'Conversion Rule';
    ws.Range('D8').Value = 'Notes';

    if strcmpi(schemaName, 'baseline')
        rows = [10, 12, 13, 14, 15, 16, 22, 24, 25, 26, 27, 28, ...
            40, 41, 42, 43, 44, 46, 47, 51, 52, 53, 54, 55, 58, 59, ...
            64, 65, 66, 67, 68, 69, 71, 72, 73, 74, 75, 76, ...
            86, 87, 88, 89, 90, 91, 93, 94, 95, 96];
        keys = {
            'gva_growth_total', 'va_share_1', 'va_share_2', 'va_share_3', 'va_share_4', 'va_share_5', ...
            'emp_growth_total', 'emp_share_1', 'emp_share_2', 'emp_share_3', 'emp_share_4', 'emp_share_5', ...
            'exo_E_1_1', 'exo_E_2_1', 'exo_E_3_1', 'exo_E_4_1', 'exo_E_5_1', 'exo_Q_2_1', 'exo_X_2_1', ...
            'exo_K_G_1_1', 'exo_K_G_2_1', 'exo_K_G_3_1', 'exo_K_G_4_1', 'exo_K_G_5_1', 'exo_targetIY_2_1', 'exo_targetIY_3_1', ...
            'exo_P_K_1_1', 'exo_P_K_2_1', 'exo_P_K_3_1', 'exo_P_K_4_1', 'exo_P_K_5_1', ...
            'Section header', 'exo_r_G_1_1', 'exo_r_G_2_1', 'exo_r_G_3_1', 'exo_r_G_4_1', 'exo_r_G_5_1', ...
            'Section header', 'exo_AI_1_1_2', 'exo_AI_2_1_2', 'exo_AI_3_1_2', 'exo_AI_4_1_2', 'exo_AI_5_1_2', ...
            'Section header', 'exo_PV_1', 'exo_PVEff_1', 'exo_PFEff'};
        rules = {
            'direct (growth-factor level)', 'direct (share level)', 'direct (share level)', 'direct (share level)', 'direct (share level)', 'direct (share level)', ...
            'direct (growth-factor level)', 'direct (share level)', 'direct (share level)', 'direct (share level)', 'direct (share level)', 'direct (share level)', ...
            'log(index/index(1))', 'log(index/index(1))', 'log(index/index(1))', 'log(index/index(1))', 'log(index/index(1))', 'log(index/index(1))', 'log(index/index(1))', ...
            'log(index/index(1))', 'log(index/index(1))', 'log(index/index(1))', 'log(index/index(1))', 'log(index/index(1))', 'direct (share level)', 'direct (share level)', ...
            'additive (index-index(1))', 'additive (index-index(1))', 'additive (index-index(1))', 'additive (index-index(1))', 'additive (index-index(1))', ...
            '', 'direct (level)', 'direct (level)', 'direct (level)', 'direct (level)', 'direct (level)', ...
            '', 'additive (index-index(1))', 'additive (index-index(1))', 'log(index)', 'log(index)', 'log(index)', ...
            '', 'additive (index-index(1))', 'log(index/index(1))', 'log(index/index(1))'};
        yearRows = [9, 11, 23, 39, 50, 57, 64, 71, 86, 93];
    else
        rows = [10, 13, 14, 19, 20, 22, 23, 24, 25, 26, 27, 29, 30, 31];
        keys = {
            'exo_E_1', 'Section header', 'exo_CapTrade_1', 'Section header', 'exo_PV_1', 'Section header', ...
            'exo_AI_1_1_2', 'exo_AI_2_1_2', 'exo_AI_3_1_2', 'exo_AI_4_1_2', 'exo_AI_5_1_2', 'Section header', 'exo_Q_2_1', 'exo_X_2_1'};
        rules = {
            'log(index)', '', 'direct (0/1 flag)', '', 'additive (index-index(1))', '', ...
            'direct (level)', 'direct (level)', 'direct (level)', 'direct (level)', 'direct (level)', '', 'log(index)', 'log(index)'};
        yearRows = [9, 11, 13, 19, 22, 29];
    end

    for i = 1:numel(rows)
        ws.Range(sprintf('B%d', rows(i))).Value = keys{i};
        ws.Range(sprintf('C%d', rows(i))).Value = rules{i};
    end

    for i = 1:numel(yearRows)
        ws.Range(sprintf('B%d', yearRows(i))).Value = 'Year';
        ws.Range(sprintf('D%d', yearRows(i))).Value = 'Year';
    end

    wb.Save;
    wb.Close(false);
    exl.Quit;
catch ME
    warning('create_baseline_path_definition_template:SchemaUpdateFailed', ...
        'Workbook created, but schema update could not be applied: %s', ME.message);
    try
        if exist('wb', 'var')
            wb.Close(false);
        end
    catch
    end
    try
        if exist('exl', 'var')
            exl.Quit;
        end
    catch
    end
end
end

function apply_template_formatting(filePath, sheetName, yearEndCol, yearStartCol)
try
    exl = actxserver('excel.application');
    exl.Visible = false;
    exl.DisplayAlerts = false;
    wb = exl.Workbooks.Open(filePath, 0, false);
    ws = wb.Worksheets.Item(sheetName);

    % Interpolate non-milestone years with weighted averages between
    % 5-year anchor points (2025, 2030, 2035, 2040, 2045, 2050).
    startColIdx = excel_col_to_index(yearStartCol);
    nYears = excel_col_to_index(yearEndCol) - startColIdx + 1;
    apply_weighted_share_formulas_excel(ws, 12:16, startColIdx, nYears);
    apply_weighted_share_formulas_excel(ws, 24:28, startColIdx, nYears);

    ws.Range('A1:D1').MergeCells = true;
    ws.Range('A1').Font.Bold = true;
    ws.Range('A1').Font.Size = 14;

    ws.Range(sprintf('A8:%s8', yearEndCol)).Font.Bold = true;
    ws.Range(sprintf('A8:%s8', yearEndCol)).Interior.ColorIndex = 48;
    ws.Range('D9').Font.Bold = true;
    ws.Range([yearStartCol '9:' yearEndCol '9']).Font.Bold = true;

    blockYearRows = [11, 23, 39, 50, 57, 60, 64, 71, 86, 93];
    for r = blockYearRows
        ws.Range(sprintf('D%d:%s%d', r, yearEndCol, r)).Font.Bold = true;
        ws.Range(sprintf('D%d:%s%d', r, yearEndCol, r)).Interior.Color = 15132390; % light gray
    end

    sectionRows = [10, 22, 39, 50, 57, 60, 64, 71, 86, 93];
    for i = 1:numel(sectionRows)
        r = sectionRows(i);
        ws.Range(sprintf('A%d:D%d', r, r)).Font.Bold = true;
        ws.Range(sprintf('A%d:D%d', r, r)).Interior.Color = 12632319; % light blue
    end

    optionalRows = [40:44, 46:47, 51:55, 58:59, 61:62, 65:69, 72:76, 87:91, 94:96];
    for r = optionalRows
        ws.Range(sprintf('A%d:D%d', r, r)).Interior.Color = 15987699; % light yellow
    end

    % Year-value input cells: green fill ('General' is Excel's default, no need to set explicitly).
    inputRows = [10, 12:16, 22, 24:28, optionalRows];
    for r = inputRows
        ws.Range(sprintf('%s%d:%s%d', yearStartCol, r, yearEndCol, r)).Interior.Color = 13434828; % light green
    end

    ws.Range('A:D').Columns.AutoFit;
    ws.Range('A:A').ColumnWidth = 52;
    ws.Range('B:B').ColumnWidth = 24;
    ws.Range('C:C').ColumnWidth = 30;
    ws.Range('D:D').ColumnWidth = 38;
    ws.Range([yearStartCol ':' yearEndCol]).HorizontalAlignment = -4108; % xlCenter

    ws.Activate;
    exl.ActiveWindow.SplitRow = 9;
    exl.ActiveWindow.SplitColumn = 4;
    exl.ActiveWindow.FreezePanes = true;

    wb.Save;
    wb.Close(false);
    exl.Quit;
catch ME
    warning('create_baseline_path_definition_template:FormattingFailed', ...
        'Workbook created, but formatting could not be applied: %s', ME.message);
    try
        if exist('wb', 'var')
            wb.Close(false);
        end
    catch
    end
    try
        if exist('exl', 'var')
            exl.Quit;
        end
    catch
    end
end
end

function apply_weighted_share_formulas_excel(ws, rowNums, startColIdx, nYears)
anchorOffsets = 1:5:nYears;

for rowNum = rowNums
    for iAnchor = 1:(numel(anchorOffsets) - 1)
        iStart = anchorOffsets(iAnchor);
        iEnd = anchorOffsets(iAnchor + 1);
        span = iEnd - iStart;

        startColName = excel_col_name(startColIdx + iStart - 1);
        endColName = excel_col_name(startColIdx + iEnd - 1);

        for k = 1:(span - 1)
            iCurrent = iStart + k;
            currentColName = excel_col_name(startColIdx + iCurrent - 1);
            wStart = span - k;
            wEnd = k;

            formula = sprintf('=(%d*%s%d+%d*%s%d)/%d', ...
                wStart, startColName, rowNum, wEnd, endColName, rowNum, span);
            ws.Range(sprintf('%s%d', currentColName, rowNum)).Formula = formula;
        end
    end
end
end

function idx = excel_col_to_index(colName)
colName = upper(strtrim(char(colName)));
idx = 0;
for i = 1:length(colName)
    idx = idx * 26 + (double(colName(i)) - double('A') + 1);
end
end

function colName = excel_col_name(idx)
letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
colName = '';
while idx > 0
    remIdx = mod(idx - 1, 26);
    colName = [letters(remIdx + 1) colName]; %#ok<AGROW>
    idx = floor((idx - 1) / 26);
end
end

function shifted = shift_excel_col_name(colName, nShift)
idx = excel_col_to_index(colName);
shifted = excel_col_name(idx + nShift);
end

function apply_nz_formatting(filePath, sheetName, yearEndCol, yearStartCol)
try
    exl = actxserver('excel.application');
    exl.Visible = false;
    exl.DisplayAlerts = false;
    wb = exl.Workbooks.Open(filePath, 0, false);
    ws = wb.Worksheets.Item(sheetName);

    ws.Range('A1:D1').MergeCells = true;
    ws.Range('A1').Font.Bold = true;
    ws.Range('A1').Font.Size = 14;

    ws.Range(sprintf('A8:%s8', yearEndCol)).Font.Bold = true;
    ws.Range(sprintf('A8:%s8', yearEndCol)).Interior.ColorIndex = 48;
    ws.Range('D9').Font.Bold = true;
    ws.Range([yearStartCol '9:' yearEndCol '9']).Font.Bold = true;

    blockYearRows = [11, 13, 19, 22, 29];
    for r = blockYearRows
        ws.Range(sprintf('D%d:%s%d', r, yearEndCol, r)).Font.Bold = true;
        ws.Range(sprintf('D%d:%s%d', r, yearEndCol, r)).Interior.Color = 15132390; % light gray
    end

    sectionRows = [13, 19, 22, 29];
    for i = 1:numel(sectionRows)
        r = sectionRows(i);
        ws.Range(sprintf('A%d:D%d', r, r)).Font.Bold = true;
        ws.Range(sprintf('A%d:D%d', r, r)).Interior.Color = 12632319; % light blue
    end

    % Required row: light blue (same shade as section headers to signal importance).
    ws.Range('A10:D10').Font.Bold = true;
    ws.Range('A10:D10').Interior.Color = 12632319;

    optionalRows = [14, 20, 23:27, 30:31];
    for r = optionalRows
        ws.Range(sprintf('A%d:D%d', r, r)).Interior.Color = 15987699; % light yellow
    end

    inputRows = [10, 14, 17, 20, 23:27, 30:31];
    for r = inputRows
        ws.Range(sprintf('%s%d:%s%d', yearStartCol, r, yearEndCol, r)).Interior.Color = 13434828; % light green
    end

    ws.Range('A:D').Columns.AutoFit;
    ws.Range('A:A').ColumnWidth = 52;
    ws.Range('B:B').ColumnWidth = 24;
    ws.Range('C:C').ColumnWidth = 30;
    ws.Range('D:D').ColumnWidth = 38;
    ws.Range([yearStartCol ':' yearEndCol]).HorizontalAlignment = -4108; % xlCenter

    ws.Activate;
    exl.ActiveWindow.SplitRow = 9;
    exl.ActiveWindow.SplitColumn = 4;
    exl.ActiveWindow.FreezePanes = true;

    wb.Save;
    wb.Close(false);
    exl.Quit;
catch ME
    warning('create_baseline_path_definition_template:NZFormattingFailed', ...
        'NZ sheet created, but formatting could not be applied: %s', ME.message);
    try
        if exist('wb', 'var'), wb.Close(false); end
    catch
    end
    try
        if exist('exl', 'var'), exl.Quit; end
    catch
    end
end
end
