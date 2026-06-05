function result = split_utilities_sector(ioXlsxPath, techSummaryCsv, outputXlsx, outputCsv, summaryCsv, ioSheetName)
%SPLIT_UTILITIES_SECTOR Split Utilities into fossil and renewables columns.

if nargin < 6 || strlength(string(ioSheetName)) == 0
    ioSheetName = "GSO_REDUCED";
end

require_file(techSummaryCsv, "tech summary CSV");

[ioData, rowNames, colNames] = load_gso_reduced_table(ioXlsxPath, ioSheetName);
techSummary = readtable(techSummaryCsv, "ReadRowNames", true, "VariableNamingRule", "preserve");

utilitiesIdx = find(strcmp(colNames, "Utilities"));
if numel(utilitiesIdx) ~= 1
    error("Could not locate exactly one 'Utilities' column in IO data.");
end

outputRow = label_index(rowNames, "OUTPUT");
valuRow = label_index(rowNames, "VALU");
labRow = label_index(rowNames, "LAB");

utilitiesOutput = ioData(outputRow, utilitiesIdx);
renewablesOutput = techSummary{"OUTPUT", "Renewables"};
fossilOutput = techSummary{"OUTPUT", "Fossil"};
denom = renewablesOutput + fossilOutput;

if denom <= 0
    error("Invalid renewables/fossil totals in tech summary.");
end

shareRenewables = renewablesOutput / denom;
shareFossil = fossilOutput / denom;

outputRenewables = utilitiesOutput * shareRenewables;
outputFossil = utilitiesOutput * shareFossil;

utilitiesIntermediates = ioData(1:6, utilitiesIdx);
intermediatesRenewables = utilitiesIntermediates * shareRenewables;
intermediatesFossil = utilitiesIntermediates * shareFossil;

vaUtilities = ioData(valuRow, utilitiesIdx);
lcUtilities = ioData(labRow, utilitiesIdx);
vaRenewables = vaUtilities * shareRenewables;
vaFossil = vaUtilities * shareFossil;
lcRenewables = lcUtilities * shareRenewables;
lcFossil = lcUtilities * shareFossil;

ioSplit = [ioData, NaN(size(ioData, 1), 2)];
splitColNames = [colNames, "Utilities_Fossil", "Utilities_Renewables"];
fossilCol = numel(splitColNames) - 1;
renewablesCol = numel(splitColNames);

ioSplit(1:6, fossilCol) = intermediatesFossil;
ioSplit(1:6, renewablesCol) = intermediatesRenewables;

ioSplit(7:9, fossilCol) = ioData(7:9, utilitiesIdx) * shareFossil;
ioSplit(7:9, renewablesCol) = ioData(7:9, utilitiesIdx) * shareRenewables;

ioSplit(valuRow, fossilCol) = vaFossil;
ioSplit(valuRow, renewablesCol) = vaRenewables;
ioSplit(outputRow, fossilCol) = outputFossil;
ioSplit(outputRow, renewablesCol) = outputRenewables;
ioSplit(labRow, fossilCol) = lcFossil;
ioSplit(labRow, renewablesCol) = lcRenewables;

ioSplit(:, utilitiesIdx) = [];
splitColNames(utilitiesIdx) = [];

exportCell = cell(size(ioSplit, 1) + 1, size(ioSplit, 2) + 1);
exportCell(1, :) = [{"Sector"}, cellstr(splitColNames)];
exportCell(2:end, 1) = cellstr(rowNames(:));
exportCell(2:end, 2:end) = num2cell(ioSplit);

ensure_parent_dir(outputXlsx);
ensure_parent_dir(outputCsv);
ensure_parent_dir(summaryCsv);

if isfile(outputXlsx)
    delete(outputXlsx);
end
writecell(exportCell, outputXlsx, "Sheet", "IO_Split");
writecell(exportCell, outputCsv);

parameters = {
    "Original_Utilities_Output"
    "Renewables_Output"
    "Renewables_Share"
    "Fossil_Output"
    "Fossil_Share"
    "Total_Intermediates"
    "Renewables_Intermediates"
    "Fossil_Intermediates"
    "Value_Added"
    "Renewables_VA"
    "Fossil_VA"
    "Labor_Compensation"
    "Renewables_LC"
    "Fossil_LC"
};

values = [
    round(utilitiesOutput, 2)
    round(outputRenewables, 2)
    round(shareRenewables, 6)
    round(outputFossil, 2)
    round(shareFossil, 6)
    round(sum(utilitiesIntermediates), 2)
    round(sum(intermediatesRenewables), 2)
    round(sum(intermediatesFossil), 2)
    round(vaUtilities, 2)
    round(vaRenewables, 2)
    round(vaFossil, 2)
    round(lcUtilities, 2)
    round(lcRenewables, 2)
    round(lcFossil, 2)
];

summaryCell = cell(numel(parameters) + 1, 2);
summaryCell(1, :) = {"Parameter", "Value"};
summaryCell(2:end, 1) = parameters;
summaryCell(2:end, 2) = num2cell(values);
writecell(summaryCell, summaryCsv);

result = struct();
result.split_table = ioSplit;
result.row_names = rowNames;
result.column_names = splitColNames;
result.shares = struct("fossil", shareFossil, "renewables", shareRenewables);
result.output_files = struct("output_xlsx", outputXlsx, "output_csv", outputCsv, "summary_csv", summaryCsv);
end

