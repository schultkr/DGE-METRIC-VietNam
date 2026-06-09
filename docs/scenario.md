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

---

## Energy Efficiency Scenarios

These scenarios add demand-side energy efficiency shocks on top of the PDP8 baseline. No binding carbon constraint is active.

### EE_PDP8

- Energy productivity improvements in industry (sector 4) and services (sector 5) consistent with Vietnam's PDP8 efficiency targets.
- Reported sectoral savings by 2030: Industry ~7.4%, Services ~5.1%, Households ~11.6%.
- Annual EE investment: approximately USD 361 million/year (~0.076% of GDP).

### EE_Directive10

- Higher EE ambition calibrated to EU Directive 10 equivalent targets.
- Steeper energy productivity path and higher investment cost in the near term.
- Delivers ~0.44% higher GDP level vs EE_PDP8 by 2030, persisting through the horizon.

### NoBESS counterfactuals

- `EE_PDP8_PV_BESS_NoBESS` and `EE_Directive10_NoBESS` reset BESS-specific channels to baseline while retaining EE productivity gains.
- Difference (Full − NoBESS) isolates the BESS contribution.
- Result: BESS contributes negligibly to macro aggregates; its value is primarily in grid reliability.

**Note on emissions:** Emissions paths are identical across all EE scenarios — EE reduces energy intensity but does not impose a binding cap. To see emissions reductions from EE, these scenarios must be combined with the NZ path.

See [EE scenario design](ee_scenario_design.md) for variable mapping details and [Use case: Energy Efficiency](use_cases_ee.md) for results.

---

## Green Finance Scenarios

These scenarios modify the cost of capital for energy transition investment, running on both the PDP8 baseline and the Net-Zero path.

### Financing structures

Three WACF levels correspond to different blends of financing instruments:

| Scenario suffix | Structure | WACF |
|---|---|---|
| `GF_A` | Balanced: ODA/MDB + blended + green bonds | 6.43% |
| `GF_B` | Market-led: predominantly commercial capital | 7.37% |
| `GF_C` | Public-led: concessional and ODA dominant | 5.07% |

Each runs on both `PDP8` (→ `PDP8_GF_A/B/C`) and `NZ` (→ `NZ_GF_A/B/C`).

### Model channels

Finance scenarios operate through cost-of-capital and investment-price shock paths:

- `exo_r_G_s`: public finance rate by sector
- `exo_r_FDI_s`: foreign/international finance rate
- `exo_P_K_s`: effective investment goods price
- `exo_K_G_s`, `exo_s_G_s`: public capital volume channels

Named instruments (green bonds, guarantees, concessional loans) are not modeled as balance-sheet items but as equivalent cost or investment-volume shocks.

See [Finance instruments feasibility](finance_instruments_comments_feasibility.md) and [Use case: Green Finance](use_cases_finance.md) for details.

---

## Further reading

- [Scenarios at a glance](scenarios_overview.md) — all scenario families with one-sentence summaries
- [Use case: Energy Efficiency](use_cases_ee.md)
- [Use case: Green Finance](use_cases_finance.md)
