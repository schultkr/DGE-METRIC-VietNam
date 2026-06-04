# Additional Shocks Configuration Guide

## Overview
The refactored simulation model supports additional exogenous shocks after the baseline transition path is computed. Use this to add policy or scenario shocks with optional incremental fine-tuning for convergence.

## Key Features
- **Configurable shock array** for one or many exogenous shocks.
- **Incremental fine-tuning** (`fineTuneSteps`) to apply shocks gradually.
- **Post-baseline application** so baseline dynamics are available before extra shocks are imposed.

## Quick Start

### 1. Define `AdditionalShocks`
Before running `simulation_model_refactored.m`, define the structure:

```matlab
AdditionalShocks = struct();
AdditionalShocks(1).shockIndex = posIdx.iposKGShocks(3);
AdditionalShocks(1).periods = {1:5, 6:19, 20:24};
AdditionalShocks(1).values = [0.02, 0.01, 0.005];
AdditionalShocks(1).name = 'Public capital stock (region 3)';
AdditionalShocks(1).fineTuneSteps = 3;
```

### 2. Run simulation
```matlab
simulation_model_refactored
```

## Shock Structure Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `shockIndex` | Integer | Yes | Column index in `oo_.exo_simul` (typically from `posIdx`) |
| `periods` | Cell array | Yes | Period ranges like `{1:5, 6:10}` |
| `values` | Numeric array | Yes | Shock values, one per period block |
| `name` | String/char | Yes | Label used in logs and diagnostics |
| `fineTuneSteps` | Integer | No | Number of incremental steps (default `1`) |

## Fine-tuning Behavior
If `fineTuneSteps = n`, the model applies each shock at fractions `1/n, 2/n, ..., n/n`, solving after every step.

Typical guidance:

| `fineTuneSteps` | Use Case |
|-----------------|----------|
| `1` | Small shocks and stable convergence |
| `2-3` | Medium shocks |
| `4-5` | Large shocks or tightly coupled blocks |

## Example: Two Shocks

```matlab
AdditionalShocks(1).shockIndex = posIdx.iposKGShocks(2);
AdditionalShocks(1).periods = {1:10, 11:25};
AdditionalShocks(1).values = [0.03, 0.01];
AdditionalShocks(1).name = 'Public capital stock (region 2)';
AdditionalShocks(1).fineTuneSteps = 5;

AdditionalShocks(2).shockIndex = posIdx.iposPERegShocks(1);
AdditionalShocks(2).periods = {1:30};
AdditionalShocks(2).values = [0.25];
AdditionalShocks(2).name = 'Carbon price (region 1)';
AdditionalShocks(2).fineTuneSteps = 4;
```

## Common `posIdx` Entries

```matlab
posIdx.iposProdShocks      % TFP shocks
posIdx.iposKGShocks        % Public capital stock shocks
posIdx.ipostauKFShocks     % Corporate tax shocks
posIdx.iposPERegShocks     % Regional carbon price shocks
posIdx.iposDamShocks       % Damage shocks
posIdx.iposExpShocks       % Export shocks
posIdx.iposNXShock         % Net export shocks
posIdx.iposBShock          % Foreign asset shocks
```

See `Miscellaneous/ModelSetup/define_auxiliary_expressions_looped.m` for the full generated index map.

## Troubleshooting
- Increase `fineTuneSteps` when solver convergence fails after shock application.
- Reduce shock magnitudes and/or spread them over more periods.
- Validate that `periods` and `values` lengths match and indices point to intended exogenous series.

## See Also
- `simulation_model_refactored.m` (main simulation entry point)
- `QUICKSTART_AdditionalShocks.md` (short practical setup guide)
- `Miscellaneous/ModelSetup/define_auxiliary_expressions_looped.m` (index definitions)

## Version
- **v1.1** (Feb 2026): references and examples aligned with current repository layout.
