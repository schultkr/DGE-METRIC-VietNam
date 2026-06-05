function value = matrix_value(matrixData, rowLabels, colLabels, rowName, colName)
%MATRIX_VALUE Return a value from a matrix by row and column label.

r = label_index(rowLabels, rowName);
c = label_index(colLabels, colName);
value = matrixData(r, c);
end

