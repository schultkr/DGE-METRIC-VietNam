function out = cell_to_string(value)
%CELL_TO_STRING Convert a scalar spreadsheet cell to a trimmed string.

if isempty(value)
    out = "";
elseif isstring(value)
    if any(ismissing(value))
        out = "";
    else
        out = strtrim(value);
    end
elseif ischar(value)
    out = strtrim(string(value));
elseif isnumeric(value)
    if isscalar(value) && isnan(value)
        out = "";
    else
        out = strtrim(string(value));
    end
elseif islogical(value)
    out = strtrim(string(value));
else
    out = strtrim(string(value));
end
end

