function validate_baseline_sheet(workbookPath, sheetName)
% validate_baseline_sheet  Structural sanity check for a runnable Baseline sheet.
%
%   validate_baseline_sheet(workbookPath, sheetName)
%
% Asserts the invariants documented as the Baseline verification checklist in
% docs/baseline_scenario_manual.md Section 11 /
% docs/scenario_notes/workbook_creation_procedure.md: a "Time" column running
% 2:27 (26 annual rows, 2026-2051), and no blank/NaN cells anywhere in the
% live A1:BV27 range (the "Year" column is a text label and is not
% numeric-checked). Errors with build_all_workbooks:ValidationFailed-style
% messages on the first problem found; does not reimplement the accounting
% identities in ExcelFiles/README.md, which apply to the calibration
% workbook, not this one.
%
% Shared by scripts/maintenance/build_all_workbooks.m and RunSimulationsEasy.m
% so both answer "is this workbook sane" identically.

data = readcell(workbookPath, 'Sheet', sheetName, 'Range', 'A1:BV27');
header = data(1, :);
body = data(2:end, :);

timeCol = find(strcmpi(header, 'Time'), 1);
if isempty(timeCol)
    error('validate_baseline_sheet:ValidationFailed', ...
        '%s!%s has no "Time" column.', workbookPath, sheetName);
end
timeValues = cell2mat(body(:, timeCol));
if numel(timeValues) ~= 26 || ~isequal(timeValues(:)', 2:27)
    error('validate_baseline_sheet:ValidationFailed', ...
        '%s!%s: expected Time=2:27 (26 rows), found %d rows spanning %g:%g.', ...
        workbookPath, sheetName, numel(timeValues), min(timeValues), max(timeValues));
end

checkedBody = body;
checkedBody(:, strcmpi(header, 'Year')) = {0}; % Year is a label column, not numeric-checked here
isBad = cellfun(@(v) isempty(v) || (isnumeric(v) && any(isnan(v(:)))), checkedBody);
if any(isBad(:))
    [badRow, badCol] = find(isBad, 1);
    error('validate_baseline_sheet:ValidationFailed', ...
        '%s!%s has a blank/NaN cell at row %d, column "%s".', ...
        workbookPath, sheetName, badRow + 1, header{badCol});
end
fprintf('  OK: %s!%s (26 rows, Time=2:27, no blank/NaN cells)\n', workbookPath, sheetName);
end
