function values = cells_to_double(cells)
%CELLS_TO_DOUBLE Convert a cell array of spreadsheet values to a double matrix.

values = NaN(size(cells));
for k = 1:numel(cells)
    values(k) = cell_to_double(cells{k});
end
end

