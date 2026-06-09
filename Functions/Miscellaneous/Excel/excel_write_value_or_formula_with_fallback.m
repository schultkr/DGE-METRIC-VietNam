function excel_write_value_or_formula_with_fallback(rngObj, data)
% excel_write_value_or_formula_with_fallback
% Write as value first, then as formula if cells look formula-like.

try
    rngObj.Value = data;
    return
catch
end

if is_formula_like_data(data) && excel_write_formula_with_fallback(rngObj, data)
    return
end

% Final fallback for some COM conversion issues.
rngObj.Value2 = data;

end

function tf = is_formula_like_data(data)
if iscell(data)
    tf = any(cellfun(@(x) ischar(x) && ~isempty(x) && x(1) == '=', data(:)));
elseif ischar(data)
    tf = ~isempty(data) && data(1) == '=';
else
    tf = false;
end
end