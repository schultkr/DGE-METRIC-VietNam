# Functions

Core MATLAB entry points for simulation and steady-state calibration, plus supporting modules in subfolders.

## Entry points
- **simulation_model_refactored.m**: main simulation workflow; loads exogenous series and growth rates, then runs baseline/scenario transitions.
- **steadystate_model.m**: steady-state calibration and diagnostics script used before simulations.

## Subfolders
- **Miscellaneous/**: shared utilities grouped into Excel, Simulation, ModelSetup, Diagnostics, and Plotting subfolders.
- **SteadyState/**: core steady-state computation pipeline and low-level building blocks.
- **steady_state/**: thin wrappers and diagnostics for the refactored steady-state interface.

## Current Layout

```text
Functions/
|-- Miscellaneous/
|-- SteadyState/
|-- steady_state/
|-- simulation_model_refactored.m
`-- steadystate_model.m
```

## High-level relationships
1. **simulation_model_refactored.m** calls utilities in **Miscellaneous/** (for exogenous data, growth rates, and model setup), then uses steady-state results produced by **SteadyState/** and **steady_state/** wrappers.
2. **steadystate_model.m** prepares steady-state conditions and calls into **SteadyState/** and **steady_state/** for calibration checks.
