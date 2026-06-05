function values = row_values(matrixData, rowLabels, colLabels, rowName, colNames)
%ROW_VALUES Return one labeled row across a requested set of columns.

values = zeros(1, numel(colNames));
for j = 1:numel(colNames)
    values(j) = matrix_value(matrixData, rowLabels, colLabels, rowName, colNames(j));
end
end

