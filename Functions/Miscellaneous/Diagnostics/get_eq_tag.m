% =========================================================================
% Local helpers
% =========================================================================

function s = get_eq_tag(M_, eq_idx, tag_nums, tag_mask)
    row = find(tag_nums == eq_idx & tag_mask, 1);
    if isempty(row)
        s = sprintf('eq_%d', eq_idx);
    else
        s = M_.equations_tags{row, 3};
    end
end