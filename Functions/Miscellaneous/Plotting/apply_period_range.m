function apply_period_range(ax, tb_from, tb_to, t_all)
% Parse the From/To edit boxes and set xlim; clamps to valid data range.

    t_min = t_all(1);
    t_max = t_all(end);

    from = str2double(tb_from.String);
    to   = str2double(tb_to.String);

    if isnan(from) || from < t_min, from = t_min; end
    if isnan(to)   || to   > t_max, to   = t_max; end
    if from >= to,  from = t_min;   to = t_max;   end

    tb_from.String = num2str(from);
    tb_to.String   = num2str(to);

    xlim(ax, [from to]);
end
