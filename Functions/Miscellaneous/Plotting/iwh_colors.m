function c = iwh_colors(n)
%IWH_COLORS  IWH corporate-design colour palette (RGB, 0-1).
%   C = IWH_COLORS() returns a struct of named IWH colours (from the
%   "Primaerfarben und Abstufungen" page of IWH_New_CD_Colours.pdf) plus the
%   semantic aliases used by the reporting scripts and an ordered scenario
%   palette in C.order.
%
%   C = IWH_COLORS(N) returns an N-by-3 matrix of scenario-series colours,
%   cycling the ordered palette when N exceeds its length. This is a drop-in
%   replacement for LINES(N).
%
%   Named fields:
%       primaryBlue mediumBlue slate green orange yellow
%       slate40 slate25 slate10          (slate gradations for muted greys)
%   Semantic aliases:
%       baseline (slate)  scenario (primaryBlue)  delta (orange)
%       zero (slate25)    grid (slate10)
%       order  (6-by-3 scenario palette)

    rgb = @(r, g, b) [r, g, b] / 255;

    primaryBlue = rgb( 36,  43, 132);   % #242b84
    mediumBlue  = rgb( 82, 134, 210);   % #5286d2
    slate       = rgb( 40,  49,  60);   % #28313c
    green       = rgb(178, 200,  35);   % #b2c823
    orange      = rgb(200, 120,  30);   % #c8781e
    yellow      = rgb(240, 208,  25);   % #f0d019

    slate40 = rgb(157, 166, 174);       % slate at 40%
    slate25 = rgb(192, 199, 205);       % slate at 25%
    slate10 = rgb(228, 231, 234);       % slate at 10%

    order = [primaryBlue; orange; green; mediumBlue; yellow; slate];

    if nargin >= 1
        idx = mod((0:n - 1).', size(order, 1)) + 1;
        c = order(idx, :);
        return
    end

    c = struct( ...
        'primaryBlue', primaryBlue, 'mediumBlue', mediumBlue, 'slate', slate, ...
        'green', green, 'orange', orange, 'yellow', yellow, ...
        'slate40', slate40, 'slate25', slate25, 'slate10', slate10, ...
        'baseline', slate, 'scenario', primaryBlue, 'delta', orange, ...
        'zero', slate25, 'grid', slate10, 'order', order);
end
