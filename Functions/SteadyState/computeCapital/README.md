# computeCapital

Building blocks used by SteadyState/compute_capital.m.

## Call sequence (typical)
1. **assign_exogenous_climate_and_prices.m** injects climate/price variables into state.
2. **compute_regional_price_indexes.m** updates regional price indices.
3. **compute_exogenous_y_production.m** computes exogenous output when calibrating by output.
4. **initialize_sectoral_aggregation.m** prepares sectoral aggregation structures.
5. **compute_sectoral_price_and_factor_aggregates.m** computes sectoral aggregates.
6. **compute_regional_macro_aggregates.m** derives regional macro aggregates.
7. **evaluate_capital_steady_state_residuals.m** returns residuals for the solver.

These functions are orchestrated by compute_capital.m, which also calls shared SteadyState utilities such as compute_aggregates.m and compute_tax_income.m.
