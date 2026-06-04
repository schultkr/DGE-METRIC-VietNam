function oo_ = set_pf_paths_after_setup(oo_, M_, options_, exo_in, endo_in, exo_mode, endo_mode)
% After perfect_foresight_setup, oo_.endo_simul/oo_.exo_simul have correct Dynare sizes.
% This function copies/pads user-provided exo/endo into those arrays WITHOUT changing size.

    % ---------- exo ----------
    if ~isempty(exo_in)
        exo_need = size(oo_.exo_simul, 1);   % whatever Dynare expects
        exo_use  = exo_in;

        if size(exo_use,1) < exo_need
            add = exo_need - size(exo_use,1);
            switch exo_mode
                case "pad_exo_last"
                    padRow = exo_use(end,:);
                case "pad_exo_zero"
                    padRow = zeros(1,size(exo_use,2));
                otherwise
                    error("Unknown exo_mode: %s", exo_mode);
            end
            exo_use = [exo_use; repmat(padRow, add, 1)];
        else
            exo_use = exo_use(1:exo_need,:);
        end

        oo_.exo_simul(:,:) = exo_use;  % keep Dynare size
    end

    % ---------- endo ----------
    if ~isempty(endo_in)
        % Dynare PF expects width = periods + maxlag + maxlead (NOT periods+1)
        Tneed = size(oo_.endo_simul, 2);
        endo_use = endo_in;

        if size(endo_use,2) < Tneed
            add = Tneed - size(endo_use,2);
            switch endo_mode
                case "pad_endo_last"
                    padCol = endo_use(:,end);
                case "pad_endo_ss"
                    if isfield(oo_,'steady_state') && ~isempty(oo_.steady_state)
                        padCol = oo_.steady_state(:);
                    else
                        padCol = endo_use(:,end);
                    end
                otherwise
                    error("Unknown endo_mode: %s", endo_mode);
            end
            endo_use = [endo_use, repmat(padCol, 1, add)];
        else
            endo_use = endo_use(:,1:Tneed);
        end

        oo_.endo_simul(:,:) = endo_use;  % keep Dynare size
    end
end
