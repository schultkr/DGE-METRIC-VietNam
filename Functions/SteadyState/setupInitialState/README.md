# setupInitialState

Building blocks used by SteadyState/setup_initial_state.m to assemble a full steady state.

## Call sequence (typical)
1. **compute_regional_export_price_index.m** computes export price indices and weights.
2. **compute_pf_parameters.m** computes production-function parameters.
3. **compute_regional_imports_and_demand.m** computes imports and demand.
4. **compute_emissions_and_aggregate_output.m** updates emissions and aggregate output.
5. **compute_regional_economic_accounts.m** constructs regional accounts.
6. **compute_government_expenditure_and_capital.m** computes government spending and capital.
7. **finalize_calibration_parameters.m** finalizes calibrated parameters.
8. **evaluate_price_consistency.m** returns price-consistency residuals.

These functions are orchestrated by setup_initial_state.m, which also calls shared SteadyState utilities.
