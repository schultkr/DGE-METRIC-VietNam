function set_period_range(ax, tb_from, tb_to, t_min, t_max)
% Reset both edit boxes and xlim to the full data range.

    tb_from.String = num2str(t_min);
    tb_to.String   = num2str(t_max);
    xlim(ax, [t_min t_max]);
end
