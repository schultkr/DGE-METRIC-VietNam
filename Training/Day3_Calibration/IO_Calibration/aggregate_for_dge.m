function result = aggregate_for_dge(splitCsv, oecdXlsx, dgeWorkbook, dgeSheet, outputXlsx, outputCsv, outputValidationCsv, outputAuditCsv, outputWorkbookCopy)
%AGGREGATE_FOR_DGE Aggregate the split IO table to DGE IO_Data format.

if nargin < 3
    dgeWorkbook = "";
end
if nargin < 4 || strlength(string(dgeSheet)) == 0
    dgeSheet = "IO_Data";
end
if nargin < 9
    outputWorkbookCopy = "";
end

require_file(splitCsv, "split IO CSV");
require_file(oecdXlsx, "OECD workbook");

splitRaw = readcell(splitCsv);
ioCols = strings(1, size(splitRaw, 2) - 1);
for j = 2:size(splitRaw, 2)
    ioCols(j - 1) = cell_to_string(splitRaw{1, j});
end

ioRows = strings(size(splitRaw, 1) - 1, 1);
for i = 2:size(splitRaw, 1)
    ioRows(i - 1) = cell_to_string(splitRaw{i, 1});
end
io = cells_to_double(splitRaw(2:end, 2:end));

outF = matrix_value(io, ioRows, ioCols, "OUTPUT", "Utilities_Fossil");
outR = matrix_value(io, ioRows, ioCols, "OUTPUT", "Utilities_Renewables");
if (outF + outR) <= 0
    error("Invalid Utilities_Fossil + Utilities_Renewables output total.");
end

shareF = outF / (outF + outR);
shareR = outR / (outF + outR);

baseCols = ["Primary", "MiningEnergy", "Refinery", "Utilities_Fossil", "Utilities_Renewables", "Secondary", "Tertiary"];
agg5 = ["Primary", "Fossil", "Renewables", "Secondary", "Tertiary"];
mapIdx = sector7_to_agg5_indices(baseCols);

Z7 = zeros(7, 7);
copyRows = ["Primary", "MiningEnergy", "Refinery", "Secondary", "Tertiary"];
for r = copyRows
    Z7(label_index(baseCols, r), :) = row_values(io, ioRows, ioCols, r, baseCols);
end

uRow = row_values(io, ioRows, ioCols, "Utilities", baseCols);
Z7(label_index(baseCols, "Utilities_Fossil"), :) = uRow * shareF;
Z7(label_index(baseCols, "Utilities_Renewables"), :) = uRow * shareR;

Z5 = zeros(5, 5);
for r7 = 1:numel(baseCols)
    for c7 = 1:numel(baseCols)
        Z5(mapIdx(r7), mapIdx(c7)) = Z5(mapIdx(r7), mapIdx(c7)) + Z7(r7, c7);
    end
end

OUTPUT5 = aggregate_supply_vector("OUTPUT", io, ioRows, ioCols, baseCols, mapIdx);
VALU5 = aggregate_supply_vector("VALU", io, ioRows, ioCols, baseCols, mapIdx);
LAB5 = aggregate_supply_vector("LAB", io, ioRows, ioCols, baseCols, mapIdx);

EXPO5 = zeros(1, 5);
EXPO5(1) = matrix_value(io, ioRows, ioCols, "Primary", "EXPO");
EXPO5(2) = matrix_value(io, ioRows, ioCols, "MiningEnergy", "EXPO") + ...
    matrix_value(io, ioRows, ioCols, "Refinery", "EXPO") + ...
    matrix_value(io, ioRows, ioCols, "Utilities", "EXPO") * shareF;
EXPO5(3) = matrix_value(io, ioRows, ioCols, "Utilities", "EXPO") * shareR;
EXPO5(4) = matrix_value(io, ioRows, ioCols, "Secondary", "EXPO");
EXPO5(5) = matrix_value(io, ioRows, ioCols, "Tertiary", "EXPO");

IMP_TOTAL5 = zeros(1, 5);
IMP_TOTAL5(1) = matrix_value(io, ioRows, ioCols, "Primary", "IMPO");
IMP_TOTAL5(2) = matrix_value(io, ioRows, ioCols, "MiningEnergy", "IMPO") + ...
    matrix_value(io, ioRows, ioCols, "Refinery", "IMPO") + ...
    matrix_value(io, ioRows, ioCols, "Utilities", "IMPO") * shareF;
IMP_TOTAL5(3) = matrix_value(io, ioRows, ioCols, "Utilities", "IMPO") * shareR;
IMP_TOTAL5(4) = matrix_value(io, ioRows, ioCols, "Secondary", "IMPO");
IMP_TOTAL5(5) = matrix_value(io, ioRows, ioCols, "Tertiary", "IMPO");

Q0 = sum(OUTPUT5);

[oecd, oecdRows, oecdCols] = load_oecd_agg(oecdXlsx);
impRows = ["Primary_IMP", "MiningEnergy_IMP", "Refinery_IMP", "Utilities_IMP", "Secondary_IMP", "Tertiary_IMP"];
useCols = ["Primary", "MiningEnergy", "Refinery", "Utilities", "Secondary", "Tertiary"];
finalCols = ["CONS", "GC", "GFCF", "INVNT", "DPABR", "CONS_NONRES"];

commodityWeights = zeros(6, 5);
commodityWeights(1, 1) = 1;
commodityWeights(2, 2) = 1;
commodityWeights(3, 2) = 1;
commodityWeights(4, 2:3) = [shareF, shareR];
commodityWeights(5, 4) = 1;
commodityWeights(6, 5) = 1;

useWeights = zeros(6, 5);
useWeights(1, 1) = 1;
useWeights(2, 2) = 1;
useWeights(3, 2) = 1;
useWeights(4, 2:3) = [shareF, shareR];
useWeights(5, 4) = 1;
useWeights(6, 5) = 1;

M_int_oecd = zeros(5, 5);
M_fin_oecd = zeros(1, 5);

for r = 1:numel(impRows)
    for uc = 1:numel(useCols)
        val = matrix_value(oecd, oecdRows, oecdCols, impRows(r), useCols(uc));
        if isnan(val)
            val = 0;
        end
        M_int_oecd = M_int_oecd + val * (commodityWeights(r, :)' * useWeights(uc, :));
    end

    finalVals = zeros(1, numel(finalCols));
    for fc = 1:numel(finalCols)
        finalVals(fc) = matrix_value(oecd, oecdRows, oecdCols, impRows(r), finalCols(fc));
    end
    finalVals(isnan(finalVals)) = 0;
    finVal = sum(finalVals);
    M_fin_oecd = M_fin_oecd + finVal * commodityWeights(r, :);
end

M_tot_oecd = sum(M_int_oecd, 2)' + M_fin_oecd;
shareImpInt = zeros(1, 5);
positiveTotals = M_tot_oecd > 0;
shareImpInt(positiveTotals) = sum(M_int_oecd(positiveTotals, :), 2)' ./ M_tot_oecd(positiveTotals);

IMP_INT5 = IMP_TOTAL5 .* shareImpInt;
IMP_FIN5 = IMP_TOTAL5 - IMP_INT5;

allocUse = zeros(5, 5);
for k = 1:5
    denom = sum(M_int_oecd(k, :));
    if denom > 0
        allocUse(k, :) = M_int_oecd(k, :) / denom;
    else
        allocUse(k, :) = ones(1, 5) / 5;
    end
end

IMP_INT_BY_USE = zeros(1, 5);
for k = 1:5
    IMP_INT_BY_USE = IMP_INT_BY_USE + IMP_INT5(k) * allocUse(k, :);
end

phiQI = Z5' ./ Q0;
phiX = EXPO5 ./ Q0;
phiMI = IMP_INT_BY_USE ./ Q0;
phiW = LAB5 ./ Q0;
phiY0 = VALU5 ./ Q0;
phiN0 = LAB5 ./ sum(LAB5);
phiMF = IMP_FIN5 ./ Q0;

ioOut = cell(10, 12);
ioOut(:) = {NaN};
ioOut{1, 1} = "Intermediate Input Shares and Sectoral Accounts (phiQI, phiX, phiM_I, phiW, phiY0, phiN0)";
ioOut(2, 1:12) = {"Aggregate Sector", "Subsector", "Primary", "Fossil", "Renewables", "Secondary", "Tertiary", "Exports (phiX)", "Imports Intermediate (phiM_I)", "Labour (phiW)", "Value Added (phiY0)", "Employment Share (phiN0)"};
ioOut{3, 1} = "Intermediate input matrix phiQI [row=using, col=supplying]";

for i = 1:numel(agg5)
    rr = 3 + i;
    sector = agg5(i);
    if ismember(sector, ["Fossil", "Renewables"])
        ioOut{rr, 1} = "Energy";
    else
        ioOut{rr, 1} = sector;
    end
    ioOut{rr, 2} = sector;
    ioOut(rr, 3:7) = num2cell(phiQI(i, :));
    ioOut{rr, 8} = phiX(i);
    ioOut{rr, 9} = phiMI(i);
    ioOut{rr, 10} = phiW(i);
    ioOut{rr, 11} = phiY0(i);
    ioOut{rr, 12} = phiN0(i);
end

ioOut{10, 1} = "Final Imports (phiM_F)";
ioOut(10, 3:7) = num2cell(phiMF);

ensure_parent_dir(outputXlsx);
ensure_parent_dir(outputCsv);
ensure_parent_dir(outputValidationCsv);
ensure_parent_dir(outputAuditCsv);

headers = arrayfun(@(n) sprintf("V%d", n), 1:12, "UniformOutput", false);
writecell([headers; ioOut], outputCsv);

if isfile(outputXlsx)
    delete(outputXlsx);
end
writecell(ioOut, outputXlsx, "Sheet", "IO_Data_Replacement", "Range", "A1");

validationChecks = {
    "fossil_aggregation_output"
    "output_total_conservation"
    "import_split_conservation_total"
    "import_split_conservation_by_sector"
    "non_negative_core"
};

passed = [
    abs(OUTPUT5(2) - (matrix_value(io, ioRows, ioCols, "OUTPUT", "MiningEnergy") + matrix_value(io, ioRows, ioCols, "OUTPUT", "Refinery") + matrix_value(io, ioRows, ioCols, "OUTPUT", "Utilities_Fossil"))) < 1e-6
    abs(sum(OUTPUT5) - (matrix_value(io, ioRows, ioCols, "OUTPUT", "Primary") + matrix_value(io, ioRows, ioCols, "OUTPUT", "MiningEnergy") + matrix_value(io, ioRows, ioCols, "OUTPUT", "Refinery") + matrix_value(io, ioRows, ioCols, "OUTPUT", "Utilities_Fossil") + matrix_value(io, ioRows, ioCols, "OUTPUT", "Utilities_Renewables") + matrix_value(io, ioRows, ioCols, "OUTPUT", "Secondary") + matrix_value(io, ioRows, ioCols, "OUTPUT", "Tertiary"))) < 1e-6
    abs(sum(IMP_INT5 + IMP_FIN5) - sum(IMP_TOTAL5)) < 1e-6
    all(abs((IMP_INT5 + IMP_FIN5) - IMP_TOTAL5) < 1e-6)
    all(Z5(:) >= -1e-9) && all(IMP_INT5 >= -1e-9) && all(IMP_FIN5 >= -1e-9)
];

passedText = strings(numel(passed), 1);
passedText(passed) = "TRUE";
passedText(~passed) = "FALSE";

validationCell = cell(numel(validationChecks) + 1, 2);
validationCell(1, :) = {"check", "passed"};
validationCell(2:end, 1) = validationChecks;
validationCell(2:end, 2) = cellstr(passedText);
writecell(validationCell, outputValidationCsv);

metrics = {
    "Q0_total_output"
    "IMP_TOTAL_Primary"
    "IMP_TOTAL_Fossil"
    "IMP_TOTAL_Renewables"
    "IMP_TOTAL_Secondary"
    "IMP_TOTAL_Tertiary"
    "IMP_INT_Primary"
    "IMP_INT_Fossil"
    "IMP_INT_Renewables"
    "IMP_INT_Secondary"
    "IMP_INT_Tertiary"
    "IMP_FIN_Primary"
    "IMP_FIN_Fossil"
    "IMP_FIN_Renewables"
    "IMP_FIN_Secondary"
    "IMP_FIN_Tertiary"
};

auditValues = [
    Q0
    IMP_TOTAL5(:)
    IMP_INT5(:)
    IMP_FIN5(:)
];

auditCell = cell(numel(metrics) + 1, 2);
auditCell(1, :) = {"metric", "value"};
auditCell(2:end, 1) = metrics;
auditCell(2:end, 2) = num2cell(auditValues);
writecell(auditCell, outputAuditCsv);

workbookCopyPath = "";
if strlength(string(dgeWorkbook)) > 0 && isfile(dgeWorkbook)
    if strlength(string(outputWorkbookCopy)) == 0
        error("outputWorkbookCopy must be provided when dgeWorkbook exists.");
    end
    ensure_parent_dir(outputWorkbookCopy);
    copyfile(dgeWorkbook, outputWorkbookCopy, "f");
    writecell(ioOut, outputWorkbookCopy, "Sheet", dgeSheet, "Range", "A1");
    workbookCopyPath = string(outputWorkbookCopy);
else
    fprintf("Skipping workbook replacement: dge_workbook not provided or not found.\n");
end

result = struct();
result.io_data = ioOut;
result.validation = validationCell;
result.audit = auditCell;
result.output_files = struct( ...
    "output_xlsx", outputXlsx, ...
    "output_csv", outputCsv, ...
    "output_validation_csv", outputValidationCsv, ...
    "output_audit_csv", outputAuditCsv, ...
    "output_workbook_copy", workbookCopyPath);
end

function mapIdx = sector7_to_agg5_indices(sectorNames)
mapIdx = zeros(1, numel(sectorNames));
for i = 1:numel(sectorNames)
    switch char(sectorNames(i))
        case "Primary"
            mapIdx(i) = 1;
        case {"MiningEnergy", "Refinery", "Utilities_Fossil"}
            mapIdx(i) = 2;
        case "Utilities_Renewables"
            mapIdx(i) = 3;
        case "Secondary"
            mapIdx(i) = 4;
        case "Tertiary"
            mapIdx(i) = 5;
        otherwise
            error("No 5-sector mapping for '%s'.", char(sectorNames(i)));
    end
end
end

function out = aggregate_supply_vector(rowName, io, ioRows, ioCols, baseCols, mapIdx)
v7 = row_values(io, ioRows, ioCols, rowName, baseCols);
out = zeros(1, 5);
for i = 1:numel(baseCols)
    out(mapIdx(i)) = out(mapIdx(i)) + v7(i);
end
end

function [oecd, oecdRows, oecdCols] = load_oecd_agg(oecdXlsx)
raw = readcell(oecdXlsx, "Sheet", "OECD_IO2019_Agg");

headers = strings(1, size(raw, 2));
for j = 1:size(raw, 2)
    headers(j) = cell_to_string(raw{1, j});
end
headers(1) = "row_id";

dataRows = raw(2:end, :);
rowIds = strings(size(dataRows, 1), 1);
for i = 1:size(dataRows, 1)
    rowIds(i) = cell_to_string(dataRows{i, 1});
end

keep = strlength(strtrim(rowIds)) > 0;
oecdRows = rowIds(keep);
oecdCols = headers(2:end);
oecd = cells_to_double(dataRows(keep, 2:end));
end

