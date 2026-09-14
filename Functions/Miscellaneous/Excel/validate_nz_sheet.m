function validate_nz_sheet(workbookPath, sheetName)
% validate_nz_sheet  Structural sanity check for a runnable NZ scenario sheet.
%
%   validate_nz_sheet(workbookPath, sheetName)
%
% Mirrors the required-key check already inside update_nz_sheet.m's
% read_nz_inputs (column B "Import Key" must include "exo_E_1"), as an
% external, re-checkable gate rather than trusting that write succeeded
% silently. Errors with validate_nz_sheet:ValidationFailed on failure.
%
% Shared by scripts/maintenance/build_all_workbooks.m and RunSimulationsEasy.m
% so both answer "is this workbook sane" identically.

data = readcell(workbookPath, 'Sheet', sheetName);
importKeyCol = data(:, 2); % column B: Import Key, per update_nz_sheet.m's read_nz_inputs
hasRequiredKey = any(cellfun(@(v) ischar(v) && strcmpi(v, 'exo_E_1'), importKeyCol));
if ~hasRequiredKey
    error('validate_nz_sheet:ValidationFailed', ...
        '%s!%s is missing the required import key "exo_E_1".', workbookPath, sheetName);
end
fprintf('  OK: %s!%s (required "exo_E_1" key present)\n', workbookPath, sheetName);
end
