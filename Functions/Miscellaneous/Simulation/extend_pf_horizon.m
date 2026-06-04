function oo_ = extend_pf_horizon(oo_, M_, options_, Tsim, exo_mode, endo_mode)
%EXTEND_PF_HORIZON Ensure oo_.exo_simul / oo_.endo_simul are long enough for Tsim.
%  Dynare deterministic sims typically need length = periods+1 (including t=0).
%
% exo_mode:
%   "pad_exo_last" : pad with last available exo row (good for permanent levels)
%   "pad_exo_zero" : pad with zeros (good if exo are shocks around 0)
%
% endo_mode:
%   "pad_endo_ss"   : pad with oo_.steady_state if available, else last column
%   "pad_endo_last" : pad with last simulated column

    reqRows = Tsim + 1;  % common Dynare convention for simul arrays

    % --- exo ---
    if isfield(oo_, 'exo_simul') && ~isempty(oo_.exo_simul)
        nRows = size(oo_.exo_simul, 1);
        if nRows < reqRows
            add = reqRows - nRows;
            switch exo_mode
                case "pad_exo_last"
                    padRow = oo_.exo_simul(end, :);
                case "pad_exo_zero"
                    padRow = zeros(1, size(oo_.exo_simul,2));
                otherwise
                    error("Unknown exo_mode: %s", exo_mode);
            end
            oo_.exo_simul = [oo_.exo_simul; repmat(padRow, add, 1)];
        else
            oo_.exo_simul = oo_.exo_simul(1:reqRows, :);
        end
    end

    % --- endo ---
    if isfield(oo_, 'endo_simul') && ~isempty(oo_.endo_simul)
        % Dynare endo_simul is usually (nendo x (periods+1))
        nCols = size(oo_.endo_simul, 2);
        if nCols < reqRows
            add = reqRows - nCols;

            if strcmp(endo_mode, "pad_endo_ss") && isfield(oo_, 'steady_state') && ~isempty(oo_.steady_state)
                padCol = oo_.steady_state(:);
            else
                padCol = oo_.endo_simul(:, end);
            end

            oo_.endo_simul = [oo_.endo_simul, repmat(padCol, 1, add)];
        else
            oo_.endo_simul = oo_.endo_simul(:, 1:reqRows);
        end
    end

    % Keep these consistent too if present
    if isfield(oo_, 'exo_det_simul') && ~isempty(oo_.exo_det_simul)
        nRows = size(oo_.exo_det_simul,1);
        if nRows < reqRows
            oo_.exo_det_simul = [oo_.exo_det_simul; zeros(reqRows-nRows, size(oo_.exo_det_simul,2))];
        else
            oo_.exo_det_simul = oo_.exo_det_simul(1:reqRows,:);
        end
    end
end
