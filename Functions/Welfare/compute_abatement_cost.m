function out = compute_abatement_cost(dsScenario, dsBaseline, beta, anchors)
% USD-per-tonne-CO2-avoided (average abatement cost) of a scenario vs. baseline.
%
%   PV GDP cost        = sum_t beta^(t-1) * (Y_1_baseline,t - Y_1_scenario,t)
%   Cumulative abated   = sum_t (E_1_baseline,t - E_1_scenario,t)   [undiscounted]
%   Cost per tonne      = PV GDP cost / Cumulative abated
%
% Y_1 (model numeraire, ExcelFiles/README.md:227) and E_1 (base-year value set
% at runtime from the calibration workbook, Functions/SteadyState/setupInitialState/
% finalize_calibration_parameters.m:13) are both calibration-relative index
% units, not confirmed absolute USD/MtCO2 -- see the driver script's header
% for the units caveat. anchors.GDPAnchorUSDperUnit and
% anchors.EmissionsAnchorMtPerUnit default to 1 (no conversion); override only
% once a verified numeraire-to-real conversion is confirmed.
%
% Also reports the scenario's own average endogenous carbon price (PE_1) as a
% companion marginal-abatement-cost cross-check against the computed average
% cost per tonne.

T = min(height(dsScenario), height(dsBaseline));
discount = beta .^ (0:T-1)';

Yb = dsBaseline.Y_1(1:T);
Ys = dsScenario.Y_1(1:T);
Eb = dsBaseline.E_1(1:T);
Es = dsScenario.E_1(1:T);

pvGdpCost = sum(discount .* (Yb - Ys));
cumAbatement = sum(Eb - Es);
costPerTonneIndex = pvGdpCost / cumAbatement;
costPerTonneUSD = costPerTonneIndex * anchors.GDPAnchorUSDperUnit / anchors.EmissionsAnchorMtPerUnit;

peAvgScenario = mean(dsScenario.PE_1(1:T));

out = struct('T', T, 'PVGDPCost', pvGdpCost, 'CumulativeAbatement', cumAbatement, ...
    'CostPerTonneIndexUnits', costPerTonneIndex, 'CostPerTonneUSD', costPerTonneUSD, ...
    'CarbonPriceAvgCrossCheck', peAvgScenario);

end
