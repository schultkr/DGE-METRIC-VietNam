# Quick Start: Additional Shocks for Baseline Scenarios

## Overview
The refactored simulation now supports **ignoring specific shocks during baseline computation** and then **applying them incrementally afterward** from `oo_.exo_simul_start`.

## Key Concept
Instead of manually specifying shock values in code, you:
1. Define shock values in your **Excel input file** (as usual)
2. Tell the model **which shocks to ignore** during baseline
3. After baseline converges, those shocks are **automatically applied from Excel values**

## Minimal Example

```matlab
% 1. Define which shocks to ignore/fine-tune
AdditionalShocks = struct();
AdditionalShocks(1).shockIndex = posIdx.iposKGShocks(3);
AdditionalShocks(1).name = 'Public capital stock (region 3)';
AdditionalShocks(1).fineTuneSteps = 3;

% 2. Run simulation
simulation_model_refactored
```

## What Happens?

### During Baseline Steps (icostep = 1 to iStep)
```matlab
% Shocks specified in AdditionalShocks are set to 0
oo_.exo_simul(:, posIdx.iposKGShocks(3)) = 0;
```

### After Baseline Converges
```matlab
% Apply shocks from oo_.exo_simul_start incrementally:
% Step 1: Apply 33% of original shock → solve
% Step 2: Apply 67% of original shock → solve  
% Step 3: Apply 100% of original shock → solve
```

## Structure Fields

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `shockIndex` | Yes | Integer | Column index in `oo_.exo_simul` |
| `name` | Yes | String | Description for logging |
| `fineTuneSteps` | No (default=1) | Integer | Number of incremental steps |

## Common Use Cases

### 1. Single Shock, No Fine-tuning
```matlab
AdditionalShocks(1).shockIndex = posIdx.ipostauKFShocks(1);
AdditionalShocks(1).name = 'Corporate tax';
AdditionalShocks(1).fineTuneSteps = 1;  % Apply immediately
```

### 2. Multiple Shocks with Different Fine-tuning
```matlab
% Large policy shock - apply gradually
AdditionalShocks(1).shockIndex = posIdx.iposKGShocks(2);
AdditionalShocks(1).name = 'Public capital stock boost (region 2)';
AdditionalShocks(1).fineTuneSteps = 5;  % 5 incremental steps

% Small shock - apply quickly
AdditionalShocks(2).shockIndex = posIdx.iposphiKShocks(1);
AdditionalShocks(2).name = 'Adjustment cost (region 1)';
AdditionalShocks(2).fineTuneSteps = 1;  % Apply immediately
```

### 3. Climate Policy Package
```matlab
% Carbon price
AdditionalShocks(1).shockIndex = posIdx.iposPERegShocks(1);
AdditionalShocks(1).name = 'Carbon price (region 1)';
AdditionalShocks(1).fineTuneSteps = 4;

% Green subsidies
AdditionalShocks(2).shockIndex = posIdx.iposTauSShocks(1);
AdditionalShocks(2).name = 'Green subsidies (region 1)';
AdditionalShocks(2).fineTuneSteps = 3;
```

## Choosing Fine-tuning Steps

| Shock Magnitude | Recommended Steps | Rationale |
|-----------------|-------------------|-----------|
| Very small (<1%) | 1 | Fast, usually converges easily |
| Small (1-5%) | 2-3 | Moderate stability improvement |
| Medium (5-15%) | 3-5 | Significant help with convergence |
| Large (>15%) | 5-10 | Essential for stability |

## Complete Workflow

```matlab
%% 1. Setup (run once)
define_auxiliary_expressions_looped  % Creates posIdx structure

%% 2. Configure shocks
AdditionalShocks = struct();
AdditionalShocks(1).shockIndex = posIdx.iposKGShocks(3);
AdditionalShocks(1).name = 'Public capital stock';
AdditionalShocks(1).fineTuneSteps = 3;

%% 3. Run simulation
sScenario = 'Baseline';
simulation_model_refactored

%% 4. Check results
% During run, you'll see:
% "=== Applying Additional Shocks from exo_simul_start ==="
% "    Fine-tuning step 1 of 3 (applying 33.3% of original shock)"
% "    ✓ Solver converged in 2.34 seconds"
% etc.
```

## Advantages over Manual Specification

| Old Approach | New Approach |
|--------------|--------------|
| Hard-coded shock values in MATLAB | Values from Excel input file |
| Changed by editing code | Changed by editing Excel |
| Periods specified manually | All periods from input file |
| Error-prone | Less error-prone |
| Inconsistent across scenarios | Consistent source of truth |

## Troubleshooting

### Solver Not Converging?
```matlab
% Increase fine-tuning steps
AdditionalShocks(1).fineTuneSteps = 10;  % Was 3
```

### Shock Not Being Applied?
```matlab
% Check that shock values exist in oo_.exo_simul_start
% Warning message: "All values in exo_simul_start are zero. Skipping."
```

### Wrong Shock Being Applied?
```matlab
% Verify shock index
disp(AdditionalShocks(1).shockIndex);  % Should match intended variable
```

## See Also
- [example_additional_shocks_config.m](example_additional_shocks_config.m) - Detailed examples
- [simulation_model_refactored.m](simulation_model_refactored.m) - Implementation
- [README_AdditionalShocks.md](README_AdditionalShocks.md) - Full documentation
