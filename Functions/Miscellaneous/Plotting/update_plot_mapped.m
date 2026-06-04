function update_plot_mapped(src, plt, ax, ~, X, names, idx_map)
% Like update_plot, but translates a filtered-list position back to the
% global variable index stored in idx_map.

    local_i  = src.Value;
    if local_i > numel(idx_map), return; end
    global_i = idx_map(local_i);
    set(plt, 'YData', X(global_i, :));
    title(ax, names{global_i}, 'Interpreter', 'none');
end
