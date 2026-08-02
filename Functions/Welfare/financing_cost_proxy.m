function wacfProxyPct = financing_cost_proxy(ds, targetSector)
% Model-internal financing-cost proxy: an investment-weighted average of the
% public (r_G) and FDI (r_FDI) capital return series for ONE sector, weighted
% by its investment flows (I_G, I_FDI), over the run horizon.
%
% targetSector defaults to 3 (renewables) because
% scripts/maintenance/create_green_finance_scenarios.m only ever shocks
% exo_r_G_3_1/exo_r_FDI_3_1 -- the documented WACF assumptions
% (docs/data_sources.md:126) apply to renewables financing specifically, not
% an economy-wide average. Averaging across all 5 sectors is NOT a valid
% proxy: sector 1 (Primary) has near-zero public investment, which made an
% earlier version of this function pick up a degenerate, economically
% meaningless r_G_1_1 value that swamped the weighted average.
%
% Used as a cross-check against the externally documented WACF assumptions
% used in compute_gdp_per_wacf -- the two need not match exactly (WACF blends
% more instruments than r_G/r_FDI alone), but a large divergence should be
% investigated before citing the WACF-pp metric.

if nargin < 2
    targetSector = 3;
end

rG = ds.(['r_G_' num2str(targetSector) '_1']);
rFDI = ds.(['r_FDI_' num2str(targetSector) '_1']);
iG = ds.(['I_G_' num2str(targetSector) '_1']);
iFDI = ds.(['I_FDI_' num2str(targetSector) '_1']);

weightedRateSum = sum(rG .* iG) + sum(rFDI .* iFDI);
weightSum = sum(iG) + sum(iFDI);

wacfProxyPct = (weightedRateSum / weightSum) * 100;

end
