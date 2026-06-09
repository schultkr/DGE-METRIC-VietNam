# SteadyState

Core steady-state computation pipeline. Functions here are called by steady-state entry points and by the thin wrappers in steady_state/.

## Pipeline overview
- **build_initial_guess.m** builds the initial vector of steady-state guesses.
- **compute_capital.m** solves for steady-state capital consistent with household FOCs.
- **setup_initial_state.m** constructs a full steady-state state given a guess vector.
- **compute_aggregates.m**, **compute_tax_income.m**, **compute_production_factors_and_output.m** compute intermediate aggregates used by both compute_capital.m and setup_initial_state.m.
- **assign_guess_to_strys.m** and **assign_predetermined_variables.m** map vector guesses into structures and fill predetermined quantities.

## Subfolders
- **computeCapital/**: lower-level blocks used by compute_capital.m.
- **setupInitialState/**: lower-level blocks used by setup_initial_state.m.

## Relationships
- compute_capital.m calls functions in computeCapital/ and setupInitialState/ to update prices, production, aggregates, and residuals.
- setup_initial_state.m calls setupInitialState/ functions to assemble sectoral/regional accounts and evaluate price consistency.

This folder contains the implementation used by both `steadystate_model.m` and wrappers in `Functions/steady_state/`.
