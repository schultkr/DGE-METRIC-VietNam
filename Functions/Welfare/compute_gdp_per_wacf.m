function out = compute_gdp_per_wacf(dsA, dsB, wacfAPct, wacfBPct)
% GDP-pp gained per pp of Weighted Average Cost of Finance (WACF) reduction,
% comparing two finance-architecture scenarios (e.g. PDP8_GF_C vs PDP8_GF_B).
%
% GDPpp_t   = (Y_1_A,t / Y_1_B,t - 1) * 100
% deltaWACF = wacfB - wacfA   (positive when A is the cheaper-finance scenario)
% metric    = GDPpp / deltaWACF, reported at the terminal year and as a
%             horizon average.
%
% wacfAPct/wacfBPct are external, documented assumptions (see
% docs/data_sources.md:126: GF_A 6.43%, GF_B 7.37%, GF_C 5.07%), not read from
% the CSVs -- pass them in from the driver's WACF lookup table.

T = min(height(dsA), height(dsB));
gdpPp = (dsA.Y_1(1:T) ./ dsB.Y_1(1:T) - 1) .* 100;

deltaWACF = wacfBPct - wacfAPct;

gdpPpTerminal = gdpPp(T);
gdpPpAvg = mean(gdpPp);

out = struct('T', T, 'DeltaWACFpp', deltaWACF, ...
    'GDPppTerminal', gdpPpTerminal, 'GDPppAverage', gdpPpAvg, ...
    'MetricTerminal', gdpPpTerminal / deltaWACF, ...
    'MetricAverage', gdpPpAvg / deltaWACF);

end
