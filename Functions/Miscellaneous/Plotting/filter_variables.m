function filter_variables(tb, lb, plt, ax, t, X, names)
% Filter the listbox to names matching the search text.
% Supports plain substrings and * wildcards (case-insensitive).

    query = strtrim(tb.String);

    if isempty(query)
        matched  = names;
        idx_map  = (1:numel(names))';
    else
        pattern  = regexptranslate('wildcard', query);
        hits     = regexpi(names, pattern, 'once');
        idx_map  = find(~cellfun('isempty', hits));
        if isempty(idx_map)
            matched = {'(no match)'};
        else
            matched = names(idx_map);
        end
    end

    lb.String = matched;
    lb.Value  = 1;

    if ~isempty(idx_map) && ~strcmp(matched{1}, '(no match)')
        global_idx = idx_map(1);
        set(plt, 'YData', X(global_idx, :));
        title(ax, names{global_idx}, 'Interpreter', 'none');
    end

    lb.Callback = @(src, ~) update_plot_mapped(src, plt, ax, t, X, names, idx_map);
end
