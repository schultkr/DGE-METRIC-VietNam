function out = cell_to_double(value)
%CELL_TO_DOUBLE Convert a scalar spreadsheet cell to double, using NaN on failure.

if isempty(value)
    out = NaN;
elseif isnumeric(value)
    out = double(value);
elseif islogical(value)
    out = double(value);
elseif isstring(value)
    if any(ismissing(value))
        out = NaN;
    else
        out = str2double(strrep(strtrim(value), ",", ""));
    end
elseif ischar(value)
    out = str2double(strrep(strtrim(string(value)), ",", ""));
else
    out = str2double(strtrim(string(value)));
end

if isempty(out)
    out = NaN;
end
end

