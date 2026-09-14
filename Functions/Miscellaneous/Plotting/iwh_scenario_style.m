function styles = iwh_scenario_style(scenarioNames)
%IWH_SCENARIO_STYLE  Stable, name-keyed scenario Color+LineStyle+Marker.
%   STYLES = IWH_SCENARIO_STYLE(SCENARIONAMES) returns a struct array, one
%   entry per SCENARIONAMES (string array, cellstr, or single char/string),
%   with fields:
%       .Name       char
%       .Color      1-by-3 RGB (0-1)
%       .LineStyle  '-' | '--' | '-.' | ':'
%       .Marker     'none' | 'o'
%
%   This is the single canonical scenario-name -> style registry for all
%   reporting scripts under scripts/reporting/. IWH_SCENARIO_COLORS.M is a
%   thin backward-compatible wrapper around this function that returns only
%   the Color column as an N-by-3 matrix.
%
%   Design rules:
%     - Hue = policy family (EE/Directive-10/RTS full = primaryBlue,
%       NoBESS = orange, RTS = green; combinations = yellow).
%     - A light TINT (20% toward white) marks the Green-Finance family
%       (PDP8_GF_*/NZ_GF_*). A deeper SHADE (25-45% toward black) marks the
%       ETS-revenue-redistribution family (NZ_subsidy, NZ_subsidy_direct,
%       NZ_concessional, NZ_conandsub). This resolves a real same-chart
%       collision (compare_wcere_scenario_variables_pdp8.m plots
%       EE_Dir10_full and PDP8_GF_A together; both were plain
%       primaryBlue/solid before this registry existed).
%     - LineStyle encodes PDP8-baseline ('-') vs NZ-baseline sibling ('--')
%       for names that have a same-hue counterpart on the other baseline.
%       Bare "NZ" and the NZ-only ETS-redistribution/combination names have
%       no PDP8 counterpart and stay solid.
%     - "_NoBESS" counterfactual twins keep the pre-existing hue-swap
%       convention (a different base hue from their full-BESS sibling)
%       rather than a tint, since that convention was already in production
%       use across two engines and three wrappers before this file existed.
%     - Marker = 'o' flags scenarios that stack >= 2 policy dimensions
%       (NZ_GF_C_EE, NZ_Dir10_full_GF_C), independent of hue/linestyle, so
%       they read unambiguously in a many-scenario "combination of all"
%       chart even when every hue is already in use.
%
%   A scenario name not in the table falls back to a deterministic cycling
%   grid of {hue x tint/shade band x linestyle} (72 combinations) and raises
%   iwh_scenario_colors:unregisteredScenario so it can be promoted here.
%
%   The "baseline"/reference curve in every reporting script uses the
%   separate semantic colour IWH_COLORS().baseline (slate) regardless of
%   which named scenario plays that role -- that channel is untouched by
%   this registry.

    p = iwh_colors();

    white = [1 1 1];
    black = [0 0 0];
    tint  = @(rgb, pct) rgb + (white - rgb) * pct;   % blend toward white (lighter)
    shade = @(rgb, pct) rgb + (black - rgb) * pct;   % blend toward black (darker)

    registry = containers.Map('KeyType', 'char', 'ValueType', 'any');

    % --- Net Zero headline pathway ---------------------------------------
    registry('NZ') = entry(p.mediumBlue, '-', 'none');

    % --- Green Finance family (PDP8/NZ siblings; 20% tint band) ----------
    registry('PDP8_GF_A') = entry(tint(p.primaryBlue, 0.20), '-',  'none');
    registry('NZ_GF_A')   = entry(tint(p.primaryBlue, 0.20), '--', 'none');
    registry('PDP8_GF_B') = entry(tint(p.orange,      0.20), '-',  'none');
    registry('NZ_GF_B')   = entry(tint(p.orange,      0.20), '--', 'none');
    registry('PDP8_GF_C') = entry(tint(p.green,       0.20), '-',  'none');
    registry('NZ_GF_C')   = entry(tint(p.green,       0.20), '--', 'none');

    % --- EE / Directive-10 / RTS family (base hue band) -------------------
    registry('EE_PDP8_ref')               = entry(p.slate40,     '-',  'none');
    registry('EE_Dir10_full')             = entry(p.primaryBlue, '-',  'none');
    registry('NZ_Dir10_full')             = entry(p.primaryBlue, '--', 'none');
    registry('EE_Dir10_full_NoBESS')      = entry(p.orange,      '-',  'none');
    registry('NZ_Dir10_full_NoBESS')      = entry(p.orange,      '--', 'none');
    registry('EE_Dir10_full_nocap')       = entry(shade(p.primaryBlue, 0.30), '-', 'none');
    registry('EE_RTS_prerev_95GW')        = entry(p.green,       '-',  'none');
    registry('NZ_RTS_prerev_95GW')        = entry(p.green,       '--', 'none');
    registry('EE_RTS_prerev_95GW_NoBESS') = entry(p.mediumBlue,  '-',  'none');
    registry('NZ_RTS_prerev_95GW_NoBESS') = entry(p.mediumBlue,  '--', 'none');
    registry('EE_Dir10_RTSslice')         = entry(p.yellow,      '-',  'none');
    registry('EE_Dir10_EEonly')           = entry(shade(p.mediumBlue, 0.25), '-', 'none');

    % --- ETS-revenue-redistribution family (NZ-only; shade band) ---------
    registry('NZ_subsidy')        = entry(shade(p.orange, 0.25), '-', 'none');
    registry('NZ_subsidy_direct') = entry(shade(p.green,  0.25), '-', 'none');
    registry('NZ_concessional')   = entry(shade(p.orange, 0.45), '-', 'none');
    registry('NZ_conandsub')      = entry(shade(p.green,  0.45), '-', 'none');

    % --- Combination-of-multiple-policy-dimensions scenarios -------------
    registry('NZ_GF_C_EE')         = entry(p.yellow,              '-', 'o');
    registry('NZ_Dir10_full_GF_C') = entry(shade(p.yellow, 0.30), '-', 'o');

    names = cellstr(scenarioNames);
    styles = repmat(struct('Name', '', 'Color', [nan nan nan], ...
        'LineStyle', '-', 'Marker', 'none'), numel(names), 1);

    fallbackGrid = build_fallback_grid(p, tint, shade);
    nFallbackUsed = 0;

    for i = 1:numel(names)
        name = names{i};
        if isKey(registry, name)
            e = registry(name);
        else
            nFallbackUsed = nFallbackUsed + 1;
            e = fallbackGrid(mod(nFallbackUsed - 1, numel(fallbackGrid)) + 1);
            warning('iwh_scenario_colors:unregisteredScenario', ...
                ['No canonical style registered for scenario "%s"; using a ' ...
                 'cycling fallback (hue x tint/shade x linestyle). Add it to ' ...
                 'iwh_scenario_style.m so it stays fixed across reporting scripts.'], name);
        end
        styles(i).Name = name;
        styles(i).Color = e.Color;
        styles(i).LineStyle = e.LineStyle;
        styles(i).Marker = e.Marker;
    end
end

function e = entry(color, lineStyle, marker)
    e = struct('Color', color, 'LineStyle', lineStyle, 'Marker', marker);
end

function grid = build_fallback_grid(p, tint, shade)
    hues = {p.primaryBlue, p.orange, p.green, p.mediumBlue, p.yellow, p.slate40};
    bands = {@(c) c, @(c) tint(c, 0.20), @(c) shade(c, 0.25)};
    lineStyles = {'-', '--', '-.', ':'};
    grid = repmat(struct('Color', [0 0 0], 'LineStyle', '-', 'Marker', 'none'), ...
        numel(hues) * numel(bands) * numel(lineStyles), 1);
    k = 0;
    for iHue = 1:numel(hues)
        for iBand = 1:numel(bands)
            for iLine = 1:numel(lineStyles)
                k = k + 1;
                grid(k) = entry(bands{iBand}(hues{iHue}), lineStyles{iLine}, 'none');
            end
        end
    end
end
