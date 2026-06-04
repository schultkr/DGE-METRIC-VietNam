function [hasNaN, info] = detect_pf_nan_residuals(M_, options_, oo_, verbose)
% Detect NaN/Inf in perfect foresight solver variables and model residuals.
%
% Call this before and/or after perfect_foresight_solver to pinpoint when
% and where NaNs first appear.
%
% Usage:
%   [hasNaN, info] = detect_pf_nan_residuals(M_, options_, oo_)
%   [hasNaN, info] = detect_pf_nan_residuals(M_, options_, oo_, false)  % silent
%
% Outputs:
%   hasNaN  - true if any NaN/Inf found in variables or residuals
%   info    - struct with fields:
%       .varNaN          - logical: NaN found in oo_.endo_simul
%       .firstVarNaNPeriod  - first simulation period (1-indexed) with NaN variable
%       .badVarNames     - cell array of variable names at first bad period
%       .badVarIdx       - indices into M_.endo_names at first bad period
%       .residNaN        - logical: NaN found in dynamic residuals
%       .firstResidNaNPeriod - first period with NaN residual
%       .badResidIdx     - equation indices with NaN at first bad period
%       .residualMap     - neq x T logical matrix (full residual NaN map)

if nargin < 4
    verbose = true;
end

ny = M_.endo_nbr;
T  = options_.periods;

info = struct( ...
    'varNaN',               false, ...
    'firstVarNaNPeriod',    [], ...
    'badVarNames',          {{}}, ...
    'badVarIdx',            [], ...
    'residNaN',             false, ...
    'firstResidNaNPeriod',  [], ...
    'badResidIdx',          [], ...
    'residualMap',          [] ...
);
hasNaN = false;

%% ── 1. Check oo_.endo_simul for NaN/Inf ─────────────────────────────────
X        = oo_.endo_simul;           % ny × (T+2)
badMask  = ~isfinite(X);

if any(badMask(:))
    hasNaN       = true;
    info.varNaN  = true;

    % First column (period index 0 = initial SS, 1..T = simulation, T+1 = terminal SS)
    badCols = find(any(badMask, 1));
    firstCol = badCols(1);
    info.firstVarNaNPeriod = firstCol - 1;   % convert to 0-based period

    badVarIdx = find(badMask(:, firstCol));
    info.badVarIdx   = badVarIdx;
    info.badVarNames = strtrim(cellstr(M_.endo_names(badVarIdx, :)));

    if verbose
        fprintf('\n[detect_pf_nan] NaN/Inf in oo_.endo_simul:\n');
        fprintf('  First bad period : %d  (endo_simul column %d)\n', ...
            info.firstVarNaNPeriod, firstCol);
        fprintf('  Bad variables    : %d\n', length(badVarIdx));
        for i = 1:min(20, length(badVarIdx))
            fprintf('    [%4d]  %s\n', badVarIdx(i), info.badVarNames{i});
        end
        if length(badVarIdx) > 20
            fprintf('    ... (%d more)\n', length(badVarIdx) - 20);
        end
        fprintf('  Total bad entries: %d / %d\n', sum(badMask(:)), numel(X));
    end
else
    if verbose
        fprintf('[detect_pf_nan] oo_.endo_simul: no NaN/Inf found.\n');
    end
end

%% ── 2. Evaluate model residuals period-by-period ─────────────────────────
% For Dynare period t (1..T):
%   y = [oo_.endo_simul(:,t); oo_.endo_simul(:,t+1); oo_.endo_simul(:,t+2)]
%   x = oo_.exo_simul(t+1, :)   [rows: 1=initial, 2..T+1=simulation, T+2=terminal]

params = M_.params;
ss     = oo_.steady_state;
nex    = M_.exo_nbr;

% Probe residual length on first finite period
neq = [];
for t_probe = 1:T
    y_test = [oo_.endo_simul(:,t_probe); oo_.endo_simul(:,t_probe+1); oo_.endo_simul(:,t_probe+2)];
    if all(isfinite(y_test))
        x_test = safe_exo(oo_.exo_simul, t_probe+1, nex);
        try
            res_test = DGE_Model.dynamic_resid(y_test, x_test, params, ss);
            neq = length(res_test);
        catch
        end
        break;
    end
end

if isempty(neq)
    if verbose
        fprintf('[detect_pf_nan] Cannot evaluate dynamic_resid (no finite period found).\n');
    end
    return;
end

residualMap = false(neq, T);

for t = 1:T
    y_lag  = oo_.endo_simul(:, t);
    y_curr = oo_.endo_simul(:, t+1);
    y_lead = oo_.endo_simul(:, t+2);
    y      = [y_lag; y_curr; y_lead];
    x      = safe_exo(oo_.exo_simul, t+1, nex);

    try
        res = DGE_Model.dynamic_resid(y, x, params, ss);
        residualMap(:, t) = ~isfinite(res);
    catch ME
        if verbose
            fprintf('[detect_pf_nan] Period %d: dynamic_resid error: %s\n', t, ME.message);
        end
        residualMap(:, t) = true;   % treat eval failure as NaN
    end
end

info.residualMap = residualMap;

if any(residualMap(:))
    hasNaN = true;
    info.residNaN = true;

    badPeriods = find(any(residualMap, 1));
    info.firstResidNaNPeriod = badPeriods(1);

    badEqIdx = find(residualMap(:, badPeriods(1)));
    info.badResidIdx = badEqIdx;

    if verbose
        fprintf('\n[detect_pf_nan] NaN/Inf in model residuals (dynamic_resid):\n');
        fprintf('  First bad period : %d\n', info.firstResidNaNPeriod);
        fprintf('  Bad equations    : %s\n', num2str(badEqIdx'));
        fprintf('  Periods affected : %d / %d\n', length(badPeriods), T);
    end
else
    if verbose
        fprintf('[detect_pf_nan] dynamic_resid: no NaN/Inf residuals found.\n');
    end
end

end % function

%% ── Helper ───────────────────────────────────────────────────────────────
function x = safe_exo(exo_simul, row, nex)
if row >= 1 && row <= size(exo_simul, 1)
    x = exo_simul(row, :);
else
    x = zeros(1, nex);
end
end
