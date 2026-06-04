function oo_ = copy_pf_prefix_after_setup(oo_, endo_long, exo_long)
% Copy the prefix of a longer PF solution into oo_ AFTER perfect_foresight_setup
% has allocated arrays for the (shorter) current options_.periods.

    % --- endo ---
    Tneed = size(oo_.endo_simul, 2);          % Dynare-required width
    oo_.endo_simul(:,:) = endo_long(:, 1:Tneed);

    % --- exo ---
    if isfield(oo_, 'exo_simul') && ~isempty(oo_.exo_simul) && ~isempty(exo_long)
        Rneed = size(oo_.exo_simul, 1);       % Dynare-required rows
        oo_.exo_simul(:,:) = exo_long(1:Rneed, :);
    end

    % (Optional) deterministic exo array if present
    if isfield(oo_, 'exo_det_simul') && ~isempty(oo_.exo_det_simul) ...
            && isfield(oo_, 'exo_det_simul') && ~isempty(oo_.exo_det_simul)
        % only do this if you also stored exo_det_long similarly
    end
end