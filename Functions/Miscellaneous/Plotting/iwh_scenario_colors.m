function colors = iwh_scenario_colors(scenarioNames)
%IWH_SCENARIO_COLORS  Stable, name-keyed scenario colours (RGB, 0-1).
%   COLORS = IWH_SCENARIO_COLORS(SCENARIONAMES) returns an N-by-3 RGB matrix,
%   one row per entry in SCENARIONAMES (string array or cellstr), so the
%   same named scenario (e.g. "NZ_Dir10_full") renders in the same colour in
%   every reporting script that plots it, regardless of its position or
%   which other scenarios/baseline share the chart.
%
%   This is a thin backward-compatible wrapper around IWH_SCENARIO_STYLE,
%   which is the canonical registry and also returns LineStyle/Marker per
%   name. Prefer IWH_SCENARIO_STYLE directly in new or migrated code; this
%   function exists so callers that only need a colour matrix (the drop-in
%   replacement for IWH_COLORS(N)) don't need to change.
%
%   A scenario name not in the registry falls back to a deterministic
%   cycling palette (see IWH_SCENARIO_STYLE) and raises a warning so it can
%   be added there.

    styles = iwh_scenario_style(scenarioNames);
    colors = reshape([styles.Color], 3, [])';
end
