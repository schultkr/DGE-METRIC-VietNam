function ok = excel_write_formula_with_fallback(rngObj, data)
% excel_write_formula_with_fallback
% Try writing formulas with both comma and semicolon separators.

ok = false;
variants = build_formula_variants_for_data(data);

for i = 1:numel(variants)
    thisData = variants{i};
    try
        rngObj.FormulaLocal = thisData;
        ok = true;
        return
    catch
    end
    try
        rngObj.Formula = thisData;
        ok = true;
        return
    catch
    end
end

end

function variants = build_formula_variants_for_data(data)
variants = {data};

if iscell(data)
    if any(cellfun(@(x) ischar(x) && contains(x, ';'), data(:)))
        variants{end + 1} = cellfun(@replace_sep_semicolon_to_comma, data, 'UniformOutput', false); %#ok<AGROW>
    end
    if any(cellfun(@(x) ischar(x) && contains(x, ','), data(:)))
        variants{end + 1} = cellfun(@replace_sep_comma_to_semicolon, data, 'UniformOutput', false); %#ok<AGROW>
    end
else
    if ischar(data) && contains(data, ';')
        variants{end + 1} = strrep(data, ';', ','); %#ok<AGROW>
    end
    if ischar(data) && contains(data, ',')
        variants{end + 1} = strrep(data, ',', ';'); %#ok<AGROW>
    end
end

end

function out = replace_sep_semicolon_to_comma(x)
if ischar(x)
    out = strrep(x, ';', ',');
else
    out = x;
end
end

function out = replace_sep_comma_to_semicolon(x)
if ischar(x)
    out = strrep(x, ',', ';');
else
    out = x;
end
end