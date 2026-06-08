function [values, rowNames, colNames] = load_gso_reduced_table(ioXlsxPath, sheetName)
%LOAD_GSO_REDUCED_TABLE Load the same 12 x 15 IO block used by the R code.

if nargin < 2 || strlength(string(sheetName)) == 0
    sheetName = "GSO_REDUCED";
end

require_file(ioXlsxPath, "IO workbook");

raw = readcell(ioXlsxPath, "Sheet", sheetName);

if size(raw, 1) < 13 || size(raw, 2) < 16
    error("Sheet '%s' does not contain the expected IO block.", char(sheetName));
end

colNames = strings(1, 15);
for j = 2:16
    colNames(j - 1) = cell_to_string(raw{1, j});
end

rowNames = strings(12, 1);
for i = 2:13
    rowNames(i - 1) = cell_to_string(raw{i, 1});
end

values = cells_to_double(raw(2:13, 2:16));
end

