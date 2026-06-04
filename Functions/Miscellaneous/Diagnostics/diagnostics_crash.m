% =========================================================================
% diagnostics_crash.m — NaN/divergence inspector for Dynare PF solver
% =========================================================================
% Prerequisites (must exist in workspace):
%   res       — flat residual vector (ny * T)
%   y         — flat endogenous vector (ny * (T+2))
%   M_        — Dynare model structure
%   oo_       — Dynare output structure  (exo_simul must be set)
%   options_  — Dynare options structure
% =========================================================================

%% 0. Reconstruct matrices
ny      = M_.endo_nbr;
periods = get_simulation_periods(options_);

resmat         = reshape(res, ny, periods);
endo_simul = reshape(y, ny, periods);

names  = cellstr(M_.endo_names);
xnames = cellstr(M_.exo_names);

% Pre-build equation-tag lookup: eq_number -> name string
tag_nums  = cell2mat(M_.equations_tags(:, 1));
tag_mask  = strcmp(M_.equations_tags(:, 2), 'name');

% Pre-build reverse map: y-index -> (variable index, lag column 1/2/3)
LLI       = M_.lead_lag_incidence;   % ny x 3; col1=lag, col2=current, col3=lead
lag_lbl   = {'t-1', 't  ', 't+1'};
max_yidx  = max(LLI(:));
ymap_var  = zeros(max_yidx, 1);      % y-index -> variable index in M_.endo_names
ymap_lag  = zeros(max_yidx, 1);      % y-index -> lag column (1/2/3)
for vi = 1:size(LLI, 1)
    for li = 1:3
        if LLI(vi, li) > 0
            ymap_var(LLI(vi, li)) = vi;
            ymap_lag(LLI(vi, li)) = li;
        end
    end
end

% Sparse Jacobian structure: for each equation, which y-columns appear
sparse_rowval = double(M_.dynamic_g1_sparse_rowval);
sparse_colval = double(M_.dynamic_g1_sparse_colval);

%% 1. Locate NaN residuals
[iposrow, iposcol] = find(isnan(resmat));

fprintf('\n%s\n', repmat('=', 1, 70));
if isempty(iposrow)
    fprintf('  No NaN residuals found in resmat.\n');
    fprintf('%s\n', repmat('=', 1, 70));
else
    fprintf('  NaN RESIDUALS DETECTED: %d occurrence(s)\n', numel(iposrow));
    fprintf('%s\n', repmat('=', 1, 70));
    fprintf('  %-6s  %-8s  %s\n', 'Eq', 'Period', 'Equation tag');
    fprintf('  %s\n', repmat('-', 1, 65));
    for k = 1:numel(iposrow)
        fprintf('  %-6d  %-8d  %s\n', iposrow(k), iposcol(k), ...
                get_eq_tag(M_, iposrow(k), tag_nums, tag_mask));
    end

    %% 2. For each unique NaN equation: find and display involved variables
    unique_eqs = unique(iposrow);
    auto_vars  = {};    % collect variable names for auto-plot

    for eq_idx = unique_eqs(:)'
        fail_periods = iposcol(iposrow == eq_idx);
        eq_name      = get_eq_tag(M_, eq_idx, tag_nums, tag_mask);

        fprintf('\n%s\n', repmat('-', 1, 70));
        fprintf('  Equation %d: %s\n', eq_idx, eq_name);
        fprintf('  NaN at period(s): %s\n', num2str(fail_periods(:)'));
        fprintf('%s\n', repmat('-', 1, 70));
        fprintf('  %-36s  %-5s  %-10s  %-10s  %-9s  %s\n', ...
                'Variable', 'Lag', 'Min', 'Max', 'First NaN', 'Status');
        fprintf('  %s\n', repmat('.', 1, 90));

        % y-columns that appear in this equation (structural sparsity)
        y_cols = unique(sparse_colval(sparse_rowval == eq_idx));

        % Also find exogenous columns that appear (y is endo; x is exo)
        % Exo entries in dynamic_resid have y-indices > max LLI value,
        % but they are handled separately via the x vector in the residual.
        % We can flag them by checking y_cols > max_yidx.
        y_cols_endo = y_cols(y_cols <= max_yidx);
        y_cols_exo  = y_cols(y_cols > max_yidx);

        for yj = y_cols_endo(:)'
            vi = ymap_var(yj);
            li = ymap_lag(yj);
            if vi == 0, continue; end

            vn     = names{vi};
            series = endo_simul(vi, :);

            % Values at failing periods (endo_simul col = fail_t + (li-1))
            tp   = fail_periods + (li - 1);
            tp   = tp(tp >= 1 & tp <= size(endo_simul, 2));
            vals = series(tp);

            mn  = min(series);
            mx  = max(series);
            fn  = find(~isfinite(series), 1, 'first');

            % Status
            if any(~isfinite(vals))
                status = '<<< NaN/Inf at fail period';
            elseif any(vals <= 0)
                status = '<<< <= 0 at fail period';
            elseif ~isfinite(mn) || ~isfinite(mx)
                status = '  ! NaN/Inf elsewhere';
            else
                status = '';
            end

            fn_str = '';
            if ~isempty(fn), fn_str = num2str(fn - 1); end

            fprintf('  %-36s  %-5s  %-10.4g  %-10.4g  %-9s  %s\n', ...
                    vn, lag_lbl{li}, mn, mx, fn_str, status);

            auto_vars{end+1} = vn; %#ok<SAGROW>
        end

        % Report exogenous variables structurally linked (indices only)
        if ~isempty(y_cols_exo)
            fprintf('\n  Exogenous variable y-indices linked to this equation: %s\n', ...
                    num2str(y_cols_exo(:)'));
            fprintf('  (check exo_simul columns at fail periods for these)\n');
        end
    end

    %% 3. Auto-plot all variables involved in NaN equations
    auto_vars = unique(auto_vars);
    n_auto    = numel(auto_vars);
    T_plot    = min(100, size(endo_simul, 2));
    t_vec     = 0:T_plot - 1;
    fail_t    = unique(iposcol);

    if n_auto > 0
        n_cols_fig = min(4, n_auto);
        n_rows_fig = ceil(n_auto / n_cols_fig);
        fig_auto = figure('Color', 'w', ...
                          'Name', 'Diagnostics: Variables in NaN Equations', ...
                          'NumberTitle', 'off', ...
                          'Position', [30 30 300*n_cols_fig 220*n_rows_fig]);

        for i = 1:n_auto
            vn  = auto_vars{i};
            idx = find(strcmp(names, vn), 1);
            if isempty(idx), continue; end

            ax_i = subplot(n_rows_fig, n_cols_fig, i);
            series = endo_simul(idx, 1:T_plot);

            fin_mask  = isfinite(series);
            hold(ax_i, 'on');

            % Finite part
            if any(fin_mask)
                plot(ax_i, t_vec(fin_mask), series(fin_mask), ...
                     'b-', 'LineWidth', 1.5);
            end
            % Mark NaN/Inf locations
            if any(~fin_mask)
                plot(ax_i, t_vec(~fin_mask), zeros(1, sum(~fin_mask)), ...
                     'rx', 'MarkerSize', 8, 'LineWidth', 2);
            end
            % Vertical lines at NaN-residual periods
            for fp = fail_t(fail_t < T_plot)'
                xline(fp, '--r', 'Alpha', 0.4);
            end

            hold(ax_i, 'off');
            grid(ax_i, 'on');
            title(ax_i, vn, 'Interpreter', 'none', 'FontSize', 8);
            xlabel(ax_i, 't');

            if any(series(fin_mask) <= 0)
                ylabel(ax_i, '<=0!', 'Color', 'r', 'FontSize', 8);
            end
        end

        sgtitle(fig_auto, ...
            'Variables linked to NaN equations  (red x = NaN/Inf, dashed = fail period)', ...
            'Interpreter', 'none', 'FontSize', 9);
    end
end

%% 4. Global non-finite scan of endo_simul
fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('  GLOBAL NON-FINITE SCAN\n');
fprintf('%s\n', repmat('=', 1, 70));

X    = endo_simul;
badT = find(any(~isfinite(X), 1), 1, 'first');

if isempty(badT)
    fprintf('  No NaN/Inf in endo_simul.\n');
else
    fprintf('  First non-finite column (period): %d\n', badT);
    badVars = find(~isfinite(X(:, badT)));
    fprintf('  %-36s  %s\n', 'Variable', 'Value');
    fprintf('  %s\n', repmat('-', 1, 50));
    for bv = badVars(:)'
        fprintf('  %-36s  %g\n', names{bv}, X(bv, badT));
    end
end

%% 5. First <= 0 scan (log-domain safety check), sorted by earliest occurrence
fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('  FIRST <= 0 OCCURRENCES (log-domain safety)\n');
fprintf('%s\n', repmat('=', 1, 70));

first_nonpos = NaN(ny, 1);
for vi = 1:ny
    t_np = find(X(vi, :) <= 0, 1, 'first');
    if ~isempty(t_np)
        first_nonpos(vi) = t_np;
    end
end

[~, sort_ord] = sort(first_nonpos);
shown = 0;
for vi = sort_ord(:)'
    if isnan(first_nonpos(vi)), break; end
    fprintf('  %-36s  first <= 0 at t=%-5d  value = %g\n', ...
            names{vi}, first_nonpos(vi) - 1, X(vi, first_nonpos(vi)));
    shown = shown + 1;
    if shown >= 20
        fprintf('  ... (truncated at 20 entries)\n');
        break;
    end
end
if shown == 0
    fprintf('  No variable <= 0 detected.\n');
end

%% 6. Interactive variable viewer
fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('  Opening interactive variable viewer ...\n');
fprintf('%s\n\n', repmat('=', 1, 70));

T_all   = size(X, 2);
t_all   = 0:T_all - 1;
names_c = cellstr(names);   % guarantee cell-of-chars regardless of Dynare version

fig_iv = figure('Color', 'w', 'Name', 'Dynare Variable Viewer', ...
                'NumberTitle', 'off', 'Position', [100 100 1100 600]);

% --- Left panel: search box + listbox (always-visible variable list) ---
uicontrol('Style', 'text', 'Parent', fig_iv, ...
          'Units', 'normalized', 'Position', [0.01 0.94 0.27 0.04], ...
          'String', sprintf('Search (%d vars):', numel(names_c)), ...
          'BackgroundColor', 'w', 'HorizontalAlignment', 'left');

tb_iv = uicontrol('Style', 'edit', 'Parent', fig_iv, ...
                  'Units', 'normalized', 'Position', [0.01 0.89 0.27 0.05], ...
                  'String', '', 'HorizontalAlignment', 'left', ...
                  'FontSize', 10);

lb_iv = uicontrol('Style', 'listbox', 'Parent', fig_iv, ...
                  'Units', 'normalized', 'Position', [0.01 0.02 0.27 0.86], ...
                  'String', names_c, 'Value', 1, ...
                  'FontSize', 9, 'FontName', 'Monospaced');

% --- Right panel: plot ---
ax_iv  = axes('Parent', fig_iv, 'Position', [0.34 0.13 0.63 0.80]);
plt_iv = plot(ax_iv, t_all, X(1, :), 'LineWidth', 2);
grid(ax_iv, 'on');
title(ax_iv, names_c{1}, 'Interpreter', 'none');
xlabel(ax_iv, 'Time');

% --- Period range controls (below plot) ---
uicontrol('Style', 'text', 'Parent', fig_iv, ...
          'Units', 'normalized', 'Position', [0.34 0.04 0.08 0.05], ...
          'String', 'Period from:', 'BackgroundColor', 'w', ...
          'HorizontalAlignment', 'right');

tb_from = uicontrol('Style', 'edit', 'Parent', fig_iv, ...
                    'Units', 'normalized', 'Position', [0.43 0.04 0.07 0.05], ...
                    'String', num2str(t_all(1)), 'FontSize', 10);

uicontrol('Style', 'text', 'Parent', fig_iv, ...
          'Units', 'normalized', 'Position', [0.51 0.04 0.04 0.05], ...
          'String', 'to:', 'BackgroundColor', 'w', ...
          'HorizontalAlignment', 'center');

tb_to = uicontrol('Style', 'edit', 'Parent', fig_iv, ...
                  'Units', 'normalized', 'Position', [0.56 0.04 0.07 0.05], ...
                  'String', num2str(t_all(end)), 'FontSize', 10);

uicontrol('Style', 'pushbutton', 'Parent', fig_iv, ...
          'Units', 'normalized', 'Position', [0.64 0.04 0.06 0.05], ...
          'String', 'Reset', ...
          'Callback', @(~,~) set_period_range(ax_iv, tb_from, tb_to, t_all(1), t_all(end)));

tb_from.Callback = @(~,~) apply_period_range(ax_iv, tb_from, tb_to, t_all);
tb_to.Callback   = @(~,~) apply_period_range(ax_iv, tb_from, tb_to, t_all);

% Listbox selection -> update plot
lb_iv.Callback = @(src, ~) update_plot(src, plt_iv, ax_iv, t_all, X, names_c);

% Search box -> filter listbox and update plot
tb_iv.Callback = @(src, ~) filter_variables(src, lb_iv, plt_iv, ax_iv, t_all, X, names_c);

%% 7. Known-risk variable monitor
% Based on structural analysis of mod files: equations that are prone to
% domain crashes (log of zero, division by zero, smooth-switch instability).
fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('  KNOWN-RISK VARIABLE MONITOR\n');
fprintf('%s\n', repmat('=', 1, 70));

risk_groups = {
    % { label,  name_pattern,  near_zero_tol,  why_dangerous }
    'HH investment (log/switch domain)', '^I_H_\d+_\d+$',   0.05, ...
        'investment FOC smooth switch (zInvFOC) becomes active near INegFloor; asinh derivative 1/sqrt(I^2+IScale^2) ill-conditioned';
    'Sector investment (max(0,.) in aggregation)', '^I_\d+_\d+$',   0.05, ...
        'max(0,I)*P_K/P in regional aggregation is non-smooth at zero; damage scrapping switch (sI) activates near Ibar';
    'Gov investment',              '^I_G_\d+_\d+$', 0.05, ...
        'public capital LOM uses max(0,...) — non-differentiable at zero; K_G can collapse if I_G is large negative';
    'Investment price P_K',        '^P_K_\d+_\d+$', 0.10, ...
        'P_K = P*exp(exo_P_K)+phiG*exo_I; appears as divisor in firms FOC (mu*r_F/u_K*(1+tauKF)*P_K/P)';
    'Output price P (sector)',     '^P_\d+_\d+$',   0.10, ...
        'divisor in final demand price ratios (PH/P, I_PV/P) and in firms FOC; near-zero P causes explosive ratios';
    'HH rental rate r_H',          '^r_H_\d+_\d+$', 1e-3, ...
        'log(max(1e-3,r_H)) hits floor at 1e-3; Euler equation term (r_H - wedgeKE) can go negative';
    'Firm rental rate r_F',        '^r_F_\d+_\d+$', 0.05, ...
        'r_F/u_K in firms FOC; vanishes if capital stock is very large or TFP collapses';
    'Capital utilization u_K',     '^u_K_\d+_\d+$', 0.05, ...
        'direct divisor in firms FOC: mu*r_F/u_K; if utilization goes to zero the FOC is singular';
    'HH capital K_H',              '^K_H_\d+_\d+$', 0.05, ...
        'capital going to zero collapses the marginal product and makes delta endogenous — downstream singularities';
    'Public capital K_G',          '^K_G_\d+_\d+$', 0.05, ...
        'max(0,...) in LOM is non-smooth; if K_G hits zero the public capital rental equation is singular';
    'Housing investment IH',       '^IH_\d+$',       0.05, ...
        'IH/PoP in housing LOM; no FOC lower bound; large negative IH can drive H negative';
    'Housing price PH',            '^PH_\d+$',       0.10, ...
        'PH/P in final demand; if PH->0 or P->0 the ratio diverges';
    'Marginal utility lambda',     '^lambda_\d+$',   0.01, ...
        'appears in every HH FOC numerator; if lambda->0 all HH FOCs become degenerate';
};

near_zero_any = false;
for ig = 1:size(risk_groups, 1)
    label   = risk_groups{ig, 1};
    pattern = risk_groups{ig, 2};
    tol     = risk_groups{ig, 3};
    reason  = risk_groups{ig, 4};

    % find all variables matching this pattern
    matches = find(~cellfun('isempty', regexp(names, pattern)));
    if isempty(matches), continue; end

    % check each matched variable
    hits = struct('name', {}, 'min_val', {}, 'first_nonpos', {}, 'first_nan', {}, 'ss_ratio', {});
    for vi = matches(:)'
        series = X(vi, :);
        mn     = min(series);
        fn_pos = find(series <= 0, 1, 'first');
        fn_nan = find(~isfinite(series), 1, 'first');

        % ratio to steady state magnitude (to detect "dangerously small")
        ss_val = abs(steadystate(vi));
        if ss_val > 0
            ratio = mn / ss_val;
        else
            ratio = NaN;
        end

        is_hit = (~isempty(fn_pos)) || (~isempty(fn_nan)) || ...
                 (~isnan(ratio) && ratio < tol);

        if is_hit
            hits(end+1).name        = names{vi}; %#ok<SAGROW>
            hits(end).min_val       = mn;
            hits(end).first_nonpos  = fn_pos;
            hits(end).first_nan     = fn_nan;
            hits(end).ss_ratio      = ratio;
        end
    end

    if isempty(hits), continue; end
    near_zero_any = true;

    fprintf('\n  [RISK] %s\n', label);
    fprintf('  Why: %s\n', reason);
    fprintf('  %-32s  %-10s  %-10s  %-10s  %-10s\n', ...
            'Variable', 'Min val', 'Min/SS', 'First<=0', 'First NaN');
    fprintf('  %s\n', repmat('.', 1, 80));
    for k = 1:numel(hits)
        h = hits(k);
        fp_str = '';   if ~isempty(h.first_nonpos), fp_str = num2str(h.first_nonpos - 1); end
        fn_str = '';   if ~isempty(h.first_nan),    fn_str = num2str(h.first_nan - 1);    end
        rat_str = 'N/A';
        if ~isnan(h.ss_ratio), rat_str = sprintf('%.3f', h.ss_ratio); end
        fprintf('  %-32s  %-10.4g  %-10s  %-10s  %-10s\n', ...
                h.name, h.min_val, rat_str, fp_str, fn_str);
    end
end

if ~near_zero_any
    fprintf('  All known-risk variables look healthy (no <=0 or near-zero values).\n');
end


[iposrow, iposcol] = find(resmat == err);
M_.equations_tags(iposrow,:);