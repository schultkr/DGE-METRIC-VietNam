% update_data_excel  —  Sync calibration inputs and propagate to parameter sheets.
%
% Workflow (two stages), all operating on ModelCalibration*.xlsx:
%
%  1. IO_Data → Data named ranges
%     Reads the IO_Data sheet (intermediate input matrix, export/import/labour/
%     value-added/employment shares) and writes values into the corresponding
%     named ranges in the Data sheet.  All column/row positions are auto-detected
%     from header text; no indices are hardcoded.
%
%  2. Data named ranges → Start and Structural Parameters sheets
%     Two-pass propagation (open–write–save–close–reopen) so that formula-driven
%     cells in the Data sheet recalculate before the second propagation pass reads
%     them.  Any sheet whose row 1 contains "Parameter" and "Value" column headers
%     is processed; IO_Data, Data, Content, and Damage Functions are
%     excluded.  Cells in the target sheet whose Parameter name is not a named
%     range in Data are silently skipped.
%
% Note: ModelBaseline*.xlsx and ModelScenarios*.xlsx are not touched here —
% their sheets use time-series format (no Parameter/Value headers) and do not
% receive propagated values from the Data sheet.

%% User Input
clearvars;
% define working directory path
sPathWD = pwd();
% define number of total subsectors
inbsubsectors_p = 5;
% define number of regions
inbregions_p = 1;
sversion = '';

%% Update the calibration excel file
% ModelCalibration*.xlsx holds Data, Start, and Structural Parameters sheets
sWorkBookName = ['ModelCalibration' num2str(inbsubsectors_p) 'Sectorsand' num2str(inbregions_p) 'Regions' sversion '.xlsx'];

addpath(genpath(fullfile(sPathWD, 'Functions')))

sExcelFileName = [pwd() '\ExcelFiles\' sWorkBookName];
if ~exist(sExcelFileName, 'file')
    error('First run create_raw_excel_input_file.m')
end

% ── Close any Excel session holding the workbook (pre-flight) ─────────────────
% Happens when a previous run crashed before exl.Quit, or the file is open
% for manual editing.  Match by filename only (not full path) to survive drive
% letter / UNC path differences between what Excel reports and sExcelFileName.
[~, sTgtStem, sTgtExt] = fileparts(sExcelFileName);
sTgtFile = [sTgtStem sTgtExt];
bPreflightClosed = false;
try
    hExl = actxGetRunningServer('Excel.Application');
    for iWb = hExl.Workbooks.Count : -1 : 1
        [~, sWbStem, sWbExt] = fileparts(hExl.Workbooks.Item(iWb).FullName);
        if strcmpi([sWbStem sWbExt], sTgtFile)
            hExl.Workbooks.Item(iWb).Close(false);   % discard unsaved changes
            bPreflightClosed = true;
        end
    end
catch
end
if bPreflightClosed
    pause(1.5);   % let the OS release the file lock before re-opening
end

% ── Verify file is not locked before starting Excel ───────────────────────────
fid = fopen(sExcelFileName, 'r+');
if fid == -1
    error(['update_data_excel: file is locked or inaccessible for writing.\n' ...
           '  Path: %s\n' ...
           '  Close the file in Excel (or any other application) and re-run.'], ...
        sExcelFileName);
end
fclose(fid);

exl = actxserver('excel.application');
exl.DisplayAlerts  = false;
exl.ScreenUpdating = false;
set(exl, 'AskToUpdateLinks', 0)
exl.Visible = 0;
exlWkbk = exl.Workbooks;
try
    exlFile = exlWkbk.Open(sExcelFileName, 0, false);
catch
    % Retry once — Excel sometimes needs a moment after actxserver
    pause(2);
    try
        exlFile = exlWkbk.Open(sExcelFileName, 0, false);
    catch ME2
        try
            exl.Quit
        catch
        end
        try
            exl.release
        catch
        end
        error(['update_data_excel: could not open workbook.\n' ...
               '  Path : %s\n' ...
               '  Cause: %s\n\n' ...
               '  The file is not locked (fopen succeeded), so the cause is\n' ...
               '  likely an Excel initialisation issue. Try:\n' ...
               '    1. Open the file manually in Excel, close it, then re-run.\n' ...
               '    2. Repair Office: Settings > Apps > Microsoft 365 > Modify.\n' ...
               '    3. Run MATLAB as Administrator.'], ...
            sExcelFileName, ME2.message);
    end
end
exl.Visible = 1;

%% Sync IO_Data → Data named ranges
% Named-range convention in Data (numeric indices, 1-based):
%   phiX_s_r_p  phiM_I_s_r_p  phiW_s_r_p  phiY0_s_r_p  phiN0_s_r_p
%   phiQI_s_r_p   (2-index: total intermediate inputs, row sum over supply cols)
%   phiQI_s_r_k_p (3-index: k = aggregate supply sector index, order of first
%                  appearance in IO_Data column A)
%   phiM_F_s_r_p  (from the phiM_F footnote row in IO_Data)
%
% All layout constants are derived from the IO_Data header and cell content
% below — no column or row numbers are hardcoded here.

ireg     = 1;   % single region
iHdrRow  = 2;   % row containing column headers in IO_Data

wsIOData = exlFile.Sheets.Item('IO_Data');
wsData   = exlFile.Sheets.Item('Data');

% ── Read and normalise the header row ────────────────────────────────────────
inbIOCols  = wsIOData.UsedRange.Columns.Count;
caHdr      = wsIOData.Range(['A' num2str(iHdrRow) ':' ...
                 get_excel_column(inbIOCols) num2str(iHdrRow)]).Value;
caHdrClean = cell(1, inbIOCols);
for ic = 1:inbIOCols
    h = caHdr{ic};
    if ischar(h)
        caHdrClean{ic} = strtrim(regexprep(h, '[\r\n]+', ' '));
    else
        caHdrClean{ic} = '';
    end
end

% ── Locate structural columns by header text ─────────────────────────────────
iC_AggSec = find(contains(caHdrClean, 'Aggregate'), 1);
iC_Subsec = find(strcmpi(caHdrClean, 'Subsector'), 1);
if isempty(iC_AggSec) || isempty(iC_Subsec)
    error('IO_Data: could not locate "Aggregate" or "Subsector" columns in header row %d', iHdrRow);
end

% ── Locate phi parameter columns by embedded parameter name in header ─────────
caParamKeys = {'phiX', 'phiM_I', 'phiW', 'phiY0', 'phiN0'};
caParamCols = zeros(1, numel(caParamKeys));
for ip = 1:numel(caParamKeys)
    icol = find(contains(caHdrClean, caParamKeys{ip}), 1);
    if isempty(icol)
        error('IO_Data: column for "%s" not found in header row %d', caParamKeys{ip}, iHdrRow);
    end
    caParamCols(ip) = icol;
end
iC_phiX   = caParamCols(1);
iC_phiM_I = caParamCols(2);
iC_phiW   = caParamCols(3);
iC_phiY0  = caParamCols(4);
iC_phiN0  = caParamCols(5);

% ── Scan rows: collect subsector data rows and phiM_F footnote row ────────────
inbIORows     = wsIOData.UsedRange.Rows.Count;
caDataRows    = [];
caSubsecNames = {};
caAggNames    = {};
iRow_phiMF    = [];

for irow = iHdrRow + 1 : inbIORows
    valB = wsIOData.Range([get_excel_column(iC_Subsec) num2str(irow)]).Value;
    valA = wsIOData.Range([get_excel_column(iC_AggSec) num2str(irow)]).Value;
    if ischar(valB) && ~isempty(strtrim(valB))
        % Non-empty Subsector cell → data row
        caDataRows(end+1)    = irow;                         %#ok
        caSubsecNames{end+1} = strtrim(valB);                %#ok
        if ischar(valA)
            caAggNames{end+1} = strtrim(valA);               %#ok
        else
            caAggNames{end+1} = caSubsecNames{end};          %#ok  fallback: own name
        end
    elseif ischar(valA) && ~isempty(regexpi(valA, 'final|phiM_F', 'once'))
        iRow_phiMF = irow;
    end
end
inbSubsec = numel(caDataRows);

% ── Map each subsector to its supply column (header == subsector name) ────────
caSupplyColIdx = zeros(1, inbSubsec);
for is = 1:inbSubsec
    icol = find(strcmpi(caHdrClean, caSubsecNames{is}), 1);
    if isempty(icol)
        error('IO_Data: no column header matching subsector "%s"', caSubsecNames{is});
    end
    caSupplyColIdx(is) = icol;
end

% ── Build aggregate groupings (order of first appearance in column A) ─────────
% caSupplyAggCols{k} = vector of supply column indices for aggregate k
% This determines the 3-index phiQI_s_r_k_p mapping automatically.
%
% Two-pass approach to avoid dynamic growth:
%   Pass 1 – collect unique aggregate labels in order of first appearance.
%   Pass 2 – fill supply-column vectors (preallocated with known sizes).

% Pass 1: unique aggregate labels
caAggLabels = cell(1, inbSubsec);   % upper bound: one agg per subsector
nAgg = 0;
for is = 1:inbSubsec
    sAgg = caAggNames{is};
    if ~any(strcmp(caAggLabels(1:nAgg), sAgg))
        nAgg = nAgg + 1;
        caAggLabels{nAgg} = sAgg;
    end
end
caAggLabels  = caAggLabels(1:nAgg);
inbSupplyAgg = nAgg;

% Pass 2: preallocate each supply-column vector, then fill
caSupplyAggCols = cell(1, inbSupplyAgg);
caAggCount      = zeros(1, inbSupplyAgg);
for ik = 1:inbSupplyAgg
    caAggCount(ik)      = sum(strcmp(caAggNames, caAggLabels{ik}));
    caSupplyAggCols{ik} = zeros(1, caAggCount(ik));
end
caAggFilled = zeros(1, inbSupplyAgg);
for is = 1:inbSubsec
    ik = find(strcmp(caAggLabels, caAggNames{is}), 1);
    caAggFilled(ik)              = caAggFilled(ik) + 1;
    caSupplyAggCols{ik}(caAggFilled(ik)) = caSupplyColIdx(is);
end

% ── Write values from IO_Data into Data named ranges ─────────────────────────
for icos = 1:inbSubsec
    irow = caDataRows(icos);
    sIdx = [num2str(icos) '_' num2str(ireg)];

    % --- scalar phi parameters (one per subsector) ---
    caCols = [iC_phiX, iC_phiM_I, iC_phiW, iC_phiY0, iC_phiN0];
    for ip = 1:numel(caParamKeys)
        sName = [caParamKeys{ip} '_' sIdx '_p'];
        val   = wsIOData.Range([get_excel_column(caCols(ip)) num2str(irow)]).Value;
        if isnumeric(val)
            try
                wsData.Range(sName).Value = val;
            catch
            end
        end
    end

    % --- 2-index phiQI: row sum over all supply columns ---
    valQI = 0;
    for is = 1:inbSubsec
        v = wsIOData.Range([get_excel_column(caSupplyColIdx(is)) num2str(irow)]).Value;
        if isnumeric(v); valQI = valQI + v; end
    end
    try
        wsData.Range(['phiQI_' sIdx '_p']).Value = valQI;
    catch
    end

    % --- 3-index phiQI: one entry per aggregate supply sector ---
    for ik = 1:inbSupplyAgg
        val = 0;
        for icol = caSupplyAggCols{ik}
            v = wsIOData.Range([get_excel_column(icol) num2str(irow)]).Value;
            if isnumeric(v); val = val + v; end
        end
        sName = ['phiQI_' sIdx '_' num2str(ik) '_p'];
        try
            wsData.Range(sName).Value = val;
        catch
        end
    end

    % --- phiM_F: footnote row, column aligned with this subsector ---
    if ~isempty(iRow_phiMF)
        val = wsIOData.Range([get_excel_column(caSupplyColIdx(icos)) num2str(iRow_phiMF)]).Value;
        if isnumeric(val)
            try
                wsData.Range(['phiM_F_' sIdx '_p']).Value = val;
            catch
            end
        end
    end
end

%% Consistency checks — IO_Data
fprintf('\n=== IO_Data consistency checks (%d subsectors) ===\n', inbSubsec);
tol_chk = 1e-6;
inbWarn = 0;

% Collect phi values (re-read using column indices already detected above)
daPhiX   = zeros(1, inbSubsec);
daPhiM_I = zeros(1, inbSubsec);
daPhiW   = zeros(1, inbSubsec);
daPhiY0  = zeros(1, inbSubsec);
daPhiN0  = zeros(1, inbSubsec);
daPhiQI  = zeros(1, inbSubsec);
daPhiM_F = zeros(1, inbSubsec);
for icos = 1:inbSubsec
    irow   = caDataRows(icos);
    daTmp  = zeros(1, 5);
    daCols = [iC_phiX, iC_phiM_I, iC_phiW, iC_phiY0, iC_phiN0];
    for ic = 1:5
        v = wsIOData.Range([get_excel_column(daCols(ic)) num2str(irow)]).Value;
        if isnumeric(v); daTmp(ic) = v; end
    end
    daPhiX(icos)   = daTmp(1);
    daPhiM_I(icos) = daTmp(2);
    daPhiW(icos)   = daTmp(3);
    daPhiY0(icos)  = daTmp(4);
    daPhiN0(icos)  = daTmp(5);
    qiSum = 0;
    for is = 1:inbSubsec
        v = wsIOData.Range([get_excel_column(caSupplyColIdx(is)) num2str(irow)]).Value;
        if isnumeric(v); qiSum = qiSum + v; end
    end
    daPhiQI(icos) = qiSum;
    if ~isempty(iRow_phiMF)
        v = wsIOData.Range([get_excel_column(caSupplyColIdx(icos)) num2str(iRow_phiMF)]).Value;
        if isnumeric(v); daPhiM_F(icos) = v; end
    end
end

% Print value table
fprintf('  %-14s %7s %7s %7s %7s %7s %7s %7s\n', ...
    'Subsector', 'phiX', 'phiM_I', 'phiW', 'phiY0', 'phiN0', 'phiQI', 'phiM_F');
for icos = 1:inbSubsec
    fprintf('  %-14s %7.4f %7.4f %7.4f %7.4f %7.4f %7.4f %7.4f\n', ...
        caSubsecNames{icos}, daPhiX(icos), daPhiM_I(icos), daPhiW(icos), ...
        daPhiY0(icos), daPhiN0(icos), daPhiQI(icos), daPhiM_F(icos));
end

% 1 — Non-negativity of all shares
caChkNames = {'phiX','phiM_I','phiW','phiY0','phiN0','phiQI','phiM_F'};
daChkMat   = [daPhiX; daPhiM_I; daPhiW; daPhiY0; daPhiN0; daPhiQI; daPhiM_F];
for ip = 1:numel(caChkNames)
    for icos = 1:inbSubsec
        if daChkMat(ip, icos) < -tol_chk
            fprintf('  WARN  [%s] %s = %.6f (negative)\n', ...
                caSubsecNames{icos}, caChkNames{ip}, daChkMat(ip, icos));
            inbWarn = inbWarn + 1;
        end
    end
end

% 2 — Employment shares sum to 1 (phiN0 are shares of LF0)
daN0Sum = sum(daPhiN0);
if abs(daN0Sum - 1) > 1e-4
    fprintf('  WARN  phiN0 sums to %.6f (expected 1.0, gap = %+.2e)\n', daN0Sum, daN0Sum - 1);
    inbWarn = inbWarn + 1;
else
    fprintf('  OK    phiN0 sum = %.6f\n', daN0Sum);
end

% 3 — Gross output identity: sum_s(phiQI_s + phiY0_s) = 1
%     (both are shares of Q0; phiQI = intermediate inputs used, phiY0 = value added)
daQSum = sum(daPhiQI + daPhiY0);
if abs(daQSum - 1) > 1e-4
    fprintf('  WARN  sum(phiQI + phiY0) = %.6f (expected 1.0, gap = %+.2e)\n', daQSum, daQSum - 1);
    inbWarn = inbWarn + 1;
else
    fprintf('  OK    sum(phiQI + phiY0) = %.6f\n', daQSum);
end

% 4 — Labour share <= value-added share (both scaled by Y0, so capital share >= 0)
for icos = 1:inbSubsec
    if daPhiW(icos) > daPhiY0(icos) + tol_chk
        fprintf('  WARN  [%s] phiW (%.4f) > phiY0 (%.4f) — implied negative capital share\n', ...
            caSubsecNames{icos}, daPhiW(icos), daPhiY0(icos));
        inbWarn = inbWarn + 1;
    end
end

% 5 — Intermediate input matrix column sums (supply-side column sum check)
%     Each column s: sum_i Z_{is} / Q0 = phiM_I_s + phiX_s + phiM_F_s + domestic_final
%     We check only that no single bilateral cell exceeds the row total phiQI
daChkMat_IO = zeros(inbSubsec, inbSubsec);
for icos = 1:inbSubsec
    for is = 1:inbSubsec
        v = wsIOData.Range([get_excel_column(caSupplyColIdx(is)) num2str(caDataRows(icos))]).Value;
        if isnumeric(v); daChkMat_IO(icos, is) = v; end
    end
end
for icos = 1:inbSubsec
    for is = 1:inbSubsec
        if daChkMat_IO(icos, is) > daPhiQI(icos) + tol_chk
            fprintf('  WARN  [%s -> %s] Z_ij (%.4f) > row phiQI (%.4f)\n', ...
                caSubsecNames{icos}, caSubsecNames{is}, daChkMat_IO(icos, is), daPhiQI(icos));
            inbWarn = inbWarn + 1;
        end
    end
end

if inbWarn == 0; fprintf('  All IO_Data checks passed.\n'); end

% ── Overall summary ────────────────────────────────────────────────────────────
fprintf('\n=== Consistency summary ===\n');
fprintf('  IO_Data:     %d warning(s)\n', inbWarn);
if inbWarn == 0
    fprintf('  All checks passed — proceeding to propagate values.\n\n');
else
    fprintf('  Review WARN messages above before relying on this calibration.\n\n');
end

%% Propagate Data named ranges to all scenario sheets
[inbrow, inbcol] = size(exlFile.Sheets.Item('Data').UsedRange.Value);
casCellNames = {''};
for icorow = 1:inbrow
    for icocol = 1:inbcol
        try
            casCellNames = [casCellNames {exlFile.Sheets.Item('Data').Range([get_excel_column(icocol) num2str(icorow)]).Name.Name}]; %#ok
        catch
        end
    end
end
casCellNames = casCellNames(2:end);

for icosheet = 1:exlFile.Sheets.Count
    if ~ismember(exlFile.Sheets.Item(icosheet).Name, {'Content', 'Data', 'IO_Data', 'Trade_Flows', 'Damage Functions'})
        exlSheet1 = exlFile.Sheets.Item(icosheet);
        exlSheet1.Activate
        inbrow = size(exlSheet1.UsedRange.Value,1);
        inbcol = size(exlSheet1.UsedRange.Value,2);
        caHeader = exlSheet1.Range(['A1:' get_excel_column(inbcol) '1']).Value;
        caHeader = cellfun(@(x) char(x), caHeader, 'UniformOutput', false);
        [~, iparamcol] = ismember('Parameter', caHeader);
        [~, ivaluecol] = ismember('Value', caHeader);
        if iparamcol > 0 && ivaluecol > 0
            for icorow = 1:inbrow
                dat_range = ['A' num2str(icorow) ':' get_excel_column(inbcol) num2str(icorow)];
                rngObj    = exlSheet1.Range(dat_range);
                cavalues  = rngObj.Value;
                if ~iscell(cavalues), cavalues = num2cell(cavalues); end
                if ischar(cavalues{1, iparamcol}) && ismember(cavalues{1, iparamcol}, casCellNames)
                    sParamName = cavalues{1, iparamcol};
                    dat_range  = [get_excel_column(ivaluecol) num2str(icorow)];
                    rngObj     = exlSheet1.Range(dat_range);
                    if ~isequal(exlFile.Sheets.Item('Data').Range(sParamName).Value,'enter value here')
                        rngObj.Value = exlFile.Sheets.Item('Data').Range(sParamName).Value;
                    end
                end
            end
        end
    end
end
exlFile.Save
exl.Quit
exl.release

%% Second pass (ensures formula-driven cells recalculate correctly)
exl = actxserver('excel.application');
set(exl,'AskToUpdateLinks',0)
exl.Visible = 1;
exlWkbk = exl.Workbooks;
exlFile = exlWkbk.Open(sExcelFileName);

[inbrow, inbcol] = size(exlFile.Sheets.Item('Data').UsedRange.Value);
casCellNames = {''};
for icorow = 1:inbrow
    for icocol = 1:inbcol
        try
            casCellNames = [casCellNames {exlFile.Sheets.Item('Data').Range([get_excel_column(icocol) num2str(icorow)]).Name.Name}]; %#ok
        catch
        end
    end
end
casCellNames = casCellNames(2:end);

for icosheet = 1:exlFile.Sheets.Count
    if ~ismember(exlFile.Sheets.Item(icosheet).Name, {'Content', 'Data', 'IO_Data', 'Trade_Flows', 'Damage Functions'})
        exlSheet1 = exlFile.Sheets.Item(icosheet);
        exlSheet1.Activate
        inbrow = size(exlSheet1.UsedRange.Value,1);
        inbcol = size(exlSheet1.UsedRange.Value,2);
        caHeader = exlSheet1.Range(['A1:' get_excel_column(inbcol) '1']).Value;
        caHeader = cellfun(@(x) char(x), caHeader, 'UniformOutput', false);
        [~, iparamcol] = ismember('Parameter', caHeader);
        [~, ivaluecol] = ismember('Value', caHeader);
        if iparamcol > 0 && ivaluecol > 0
            for icorow = 1:inbrow
                dat_range = ['A' num2str(icorow) ':' get_excel_column(inbcol) num2str(icorow)];
                rngObj    = exlSheet1.Range(dat_range);
                cavalues  = rngObj.Value;
                if ~iscell(cavalues), cavalues = num2cell(cavalues); end
                if ischar(cavalues{1, iparamcol}) && ismember(cavalues{1, iparamcol}, casCellNames)
                    sParamName = cavalues{1, iparamcol};
                    dat_range  = [get_excel_column(ivaluecol) num2str(icorow)];
                    rngObj     = exlSheet1.Range(dat_range);
                    if ~isequal(exlFile.Sheets.Item('Data').Range(sParamName).Value,'enter value here')
                        rngObj.Value = exlFile.Sheets.Item('Data').Range(sParamName).Value;
                    end
                end
            end
        end
    end
end

exlFile.Save
exl.Quit
exl.release
