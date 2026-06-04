# steady_state

Thin wrappers and helper entry points for the refactored steady-state interface.

## Relationships
- **ss_build_initial_guess.m** calls SteadyState/build_initial_guess.m.
- **ss_compute_capital.m** calls SteadyState/compute_capital.m.
- **ss_setup_initial_state.m** calls SteadyState/setup_initial_state.m.
- **diagnostics/check_allocation_errors.m** provides post-solve consistency checks used during calibration/debugging.

These wrappers preserve legacy call signatures while routing to the snake_case implementation.
