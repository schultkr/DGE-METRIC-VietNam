# Scenarios

## Where Scenarios Are Defined

Primary scenario selection is configured in `RunSimulations.m`.

The script organizes scenarios into named groups, including:

- `Reference` (baseline reference run).
- `EE` (energy-efficiency variants).
- `GF_PDP8` (green-finance variants on baseline).
- `GF_NZ` (green-finance variants on NZ baseline).

The active set is controlled by:

- `activeScenarioGroups` in the script.
- optional environment override `DGE_SCENARIO_GROUPS`.

## Baseline vs Non-Baseline Logic

`RunSimulations.m` applies scenario-dependent switches before Dynare execution:

- Baseline scenarios use baseline configuration and transition settings.
- NZ-related scenarios can switch baseline type and cap-and-trade behavior.
- Additional groups inherit defaults unless explicitly overridden in the script.

## Baseline Workbook Mechanics

The simulation workflow reads baseline paths from:

- `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx` (for default 5x1 setup).

Within the refactored simulation flow (`Functions/simulation_model_refactored.m`):

- baseline paths are loaded from the selected baseline sheet;
- non-baseline scenarios copy baseline shock structures before applying scenario deltas;
- warm-starting from prior baseline candidates is supported via `sBaselineWarmRef`.

## Scenario Workbook

Scenario-specific exogenous paths are read from:

- `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx`.

Baseline and scenario series are combined by `load_exogenous_twice(...)` in the refactored simulation pipeline.

## Advanced Scenario Utilities

Useful supporting files:

- `Functions/QUICKSTART_AdditionalShocks.md`: fast setup for post-baseline additional shocks.
- `Functions/README_AdditionalShocks.md`: detailed additional-shock structure and examples.
- `scripts/maintenance/CreateBaselineFromPathDefinitionLite.m`: rebuilds runnable baseline sheet from dedicated path definitions.
