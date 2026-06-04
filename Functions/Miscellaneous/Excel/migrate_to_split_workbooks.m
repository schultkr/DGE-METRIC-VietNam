% migrate_to_split_workbooks  —  One-time migration from monolithic workbook
%                                 to three separate workbooks.
%
% Strategy: copy the old file three times, then delete unwanted sheets from
% each copy.  This preserves named ranges, cell formats, and formula
% references without any manual reconstruction.
%
% Resulting files in ExcelFiles/:
%   ModelCalibration5Sectorsand1Regions.xlsx
%       Content | IO_Data | Trade_Flows | Data | Start | Structural Parameters
%
%   ModelBaseline5Sectorsand1Regions.xlsx
%       Content | Baseline_Input | Baseline_calc | Baseline
%
%   ModelScenarios5Sectorsand1Regions.xlsx
%       Content | <all policy scenario sheets>

%% ── User configuration ──────────────────────────────────────────────────────
inbsubsectors_p = 5;   % must match old workbook
inbregions_p    = 1;
sversion        = '';

casKeepCalib    = {'Content', 'IO_Data', 'Trade_Flows', 'Data', ...
                   'Start', 'Structural Parameters'};

casKeepBaseline = {'Content', 'Baseline_Input', 'Baseline_calc', 'Baseline', ...
                   'Baseline_test'};

% Sheets excluded from the Scenarios workbook (meta / helper / calibration)
casExcludeScenarios = {'Content', 'IO_Data', 'Trade_Flows', 'Data', ...
                       'Baseline_Input', 'Baseline_calc', ...
                       'Start', 'Structural Parameters', ...
                       'Baseline', 'Baseline_test', ...
                       'NZCalib', 'BaselineCalib', 'QA_Spelling'};

%% ── Derived paths ───────────────────────────────────────────────────────────
sPathWD = pwd();
sSuffix = [num2str(inbsubsectors_p) 'Sectorsand' num2str(inbregions_p) 'Regions' sversion '.xlsx'];

sOldFile       = [sPathWD '\ExcelFiles\ModelSimulationandCalibration' sSuffix];
sCalibFile     = [sPathWD '\ExcelFiles\ModelCalibration'  sSuffix];
sBaselineFile  = [sPathWD '\ExcelFiles\ModelBaseline'     sSuffix];
sScenariosFile = [sPathWD '\ExcelFiles\ModelScenarios'    sSuffix];

if ~exist(sOldFile, 'file')
    error('Source file not found:\n  %s', sOldFile);
end

%% ══════════════════════════════════════════════════════════════════════════════
%  1. ModelCalibration
%% ══════════════════════════════════════════════════════════════════════════════
fprintf('Creating ModelCalibration...\n');
if exist(sCalibFile, 'file'); delete(sCalibFile); end
copyfile(sOldFile, sCalibFile);

exl     = actxserver('excel.application');
set(exl, 'AskToUpdateLinks', 0);
exl.Visible = 1;
exlWkbk = exl.Workbooks;
exlFile = exlWkbk.Open(sCalibFile);

exlFile = trim_workbook(exlFile, casKeepCalib, exl);
exlFile = rebuild_content(exlFile, exl);

exlFile.Save;
exl.Quit;
exl.release;
fprintf('  Saved: %s\n', sCalibFile);

%% ══════════════════════════════════════════════════════════════════════════════
%  2. ModelBaseline
%% ══════════════════════════════════════════════════════════════════════════════
fprintf('Creating ModelBaseline...\n');
if exist(sBaselineFile, 'file'); delete(sBaselineFile); end
copyfile(sOldFile, sBaselineFile);

exl     = actxserver('excel.application');
set(exl, 'AskToUpdateLinks', 0);
exl.Visible = 1;
exlWkbk = exl.Workbooks;
exlFile = exlWkbk.Open(sBaselineFile);

exlFile = trim_workbook(exlFile, casKeepBaseline, exl);
exlFile = rebuild_content(exlFile, exl);

exlFile.Save;
exl.Quit;
exl.release;
fprintf('  Saved: %s\n', sBaselineFile);

%% ══════════════════════════════════════════════════════════════════════════════
%  3. ModelScenarios
%% ══════════════════════════════════════════════════════════════════════════════
fprintf('Creating ModelScenarios...\n');
if exist(sScenariosFile, 'file'); delete(sScenariosFile); end
copyfile(sOldFile, sScenariosFile);

exl     = actxserver('excel.application');
set(exl, 'AskToUpdateLinks', 0);
exl.Visible = 1;
exlWkbk = exl.Workbooks;
exlFile = exlWkbk.Open(sScenariosFile);

% Build keep list dynamically: anything not in the exclude list
casAllSheets = cell(1, exlFile.Sheets.Count);
for ico = 1 : exlFile.Sheets.Count
    casAllSheets{ico} = exlFile.Sheets.Item(ico).Name;
end
casKeepScenarios = [{'Content'}, casAllSheets(~ismember(casAllSheets, casExcludeScenarios))];

exlFile = trim_workbook(exlFile, casKeepScenarios, exl);
exlFile = rebuild_content(exlFile, exl);

exlFile.Save;
exl.Quit;
exl.release;
fprintf('  Saved: %s\n', sScenariosFile);

fprintf('\nMigration complete.\n');
fprintf('Next: run update_data_excel.m to re-sync IO_Data -> Data -> Start/Structural Parameters.\n');
fprintf('Then run scripts/maintenance/UpdateBaselineSheet.m if the split Baseline sheet should be refreshed from the combined workbook.\n');

%% ═══════════════════════════════════════════════════════ local functions ═════

function exlFile = trim_workbook(exlFile, casKeep, exl)
    % Delete every sheet whose name is NOT in casKeep (reverse order to keep
    % indices stable).  Stops early if only one sheet remains (Excel requires ≥1).
    exl.DisplayAlerts = false;
    for icosheet = exlFile.Sheets.Count : -1 : 1
        if exlFile.Sheets.Count == 1; break; end
        sName = exlFile.Sheets.Item(icosheet).Name;
        if ~ismember(sName, casKeep)
            exlFile.Sheets.Item(icosheet).Delete;
        end
    end
    exl.DisplayAlerts = true;
end

function exlFile = rebuild_content(exlFile, exl)
    % Remove old Content sheet and create a fresh one listing surviving sheets.
    exl.DisplayAlerts = false;
    for ico = exlFile.Sheets.Count : -1 : 1
        if strcmp(exlFile.Sheets.Item(ico).Name, 'Content') && exlFile.Sheets.Count > 1
            exlFile.Sheets.Item(ico).Delete;
            break
        end
    end
    exl.DisplayAlerts = true;

    % Insert fresh Content sheet at position 1
    exlFile.Sheets.Add(exlFile.Sheets.Item(1));
    wsContent = exlFile.Sheets.Item(1);
    wsContent.Name = 'Content';

    wsContent.Range('A1').Value = 'Sheet';
    wsContent.Range('B1').Value = 'Link';
    wsContent.Range('A1:B1').Interior.ColorIndex = 48;

    for ico = 2 : exlFile.Sheets.Count
        sName = exlFile.Sheets.Item(ico).Name;
        wsContent.Range(['A' num2str(ico)]).Value = sName;
        wsContent.Range(['B' num2str(ico)]).Formula = ...
            ['=HYPERLINK("#''' sName '''!A1","' sName '")'];
    end
    wsContent.Columns.AutoFit;
end
