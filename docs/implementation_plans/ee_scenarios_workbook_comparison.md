# Energy Efficiency Scenario Workbook Comparison

Date: 2026-06-03

## Scope

This note compares:

- `ExcelFiles/PDP8/Vietnam_EnergyExpert_ScenarioInputs - Adjust_2505.xlsx` (new)
- `ExcelFiles/PDP8/Vietnam_Green_Finance_Scenarios_April2026.xlsx` (old)

and highlights implications for EE macro-scenario analysis.

## Executive Takeaway

The new workbook is not a minor revision of the old one. It is a full redesign:

- Old workbook: financing mix and weighted average cost of finance (WACF) calculator.
- New workbook: annual physical and policy scenario-input engine for PV, BESS, RTS, and EE.

As a result, direct one-to-one cell comparison is mostly not meaningful because the model objects changed.

## Explicit Change Log (Old -> New)

## 1) Workbook purpose changed

- Old: green finance instrument allocation, interest rates, and dashboard summary.
- New: scenario trajectories (2026-2050) and EE assumptions that can be transformed into model exogenous shock paths.

## 2) Sheet architecture expanded (3 -> 9 sheets)

Old workbook sheets:

- `Assumptions`
- `WACF Breakdown`
- `Summary Dashboard`

New workbook sheets:

- `README`
- `Context`
- `Assumption_Dictionary`
- `PV_Yield_Source`
- `PDP8_revised`
- `PDP8_PV_EV_BESS`
- `Directive10_RTS_EE`
- `EE_PDP8_reference`
- `EE`

## 3) New annual time-series scenario inputs added

The new workbook introduces annual paths for key technical variables, including:

- `RTS_Capacity_GW`
- `PV_Integration_Gain_pct`
- `BESS_Annual_Investment_USDbn`
- Sector-level EE savings and EE investments.

These variables did not exist in the old WACF-centered workbook.

## 4) Legacy finance dashboard metrics removed from this file

The following old metrics are not the focus of the new workbook structure:

- instrument allocation shares (A/B/C)
- instrument-specific lending rates
- WACF totals by scenario
- annual financing cost dashboard rows

## EE-Specific Numerical Changes in New Workbook

The two EE sheets (`EE_PDP8_reference` and `EE`) give explicit policy-intensity shifts.

### A) Industry and Services EE savings, plus total EE investment

| Year | `EE_PDP8_reference` Industry saving (%) | `EE` Industry saving (%) | Delta (pp) | `EE_PDP8_reference` Services saving (%) | `EE` Services saving (%) | Delta (pp) | `EE_PDP8_reference` Total EE investment (USDm) | `EE` Total EE investment (USDm) | Delta (USDm) |
|:--|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| 2030 | 3.0 | 7.4 | +4.4 | 2.0 | 5.1 | +3.1 | 320 | 461 | +141 |
| 2040 | 4.0 | 9.0 | +5.0 | 2.8 | 6.2 | +3.4 | 365 | 497 | +132 |
| 2050 | 4.5 | 10.0 | +5.5 | 3.2 | 7.0 | +3.8 | 377 | 515 | +138 |

Interpretation: the new EE policy sheet implies materially stronger productivity/efficiency assumptions and higher investment support than the EE reference path.

## Scenario Mapping for Model Runs

Based on `scripts/maintenance/create_ee_scenarios_from_expert_inputs.m`, expert sheets map to model scenario sheets as follows:

- `EE_PDP8_reference` -> `EE_PDP8` and `EE_PDP8_NoBESS`
- `Directive10_RTS_EE` -> `EE_Directive10` and `EE_Directive10_NoBESS`
- `PDP8_PV_EV_BESS` -> `EE_PDP8_PV_BESS` and `EE_PDP8_PV_BESS_NoBESS`

### Requested scenario list check

Requested list:

- `EE_PDP8` -> exists
- `EE_Directive10` -> exists
- `EE_Directive10_NoBESS` -> exists
- `EE_Directive10_PV_BESS` -> **not found in `ModelScenarios5Sectorsand1Regions.xlsx`**
- `EE_PDP8_PV_BESS_NoBESS` -> exists

Likely intended sheet: `EE_PDP8_PV_BESS` (exists), paired with `EE_PDP8_PV_BESS_NoBESS`.

## Recommended Plots for EE Macroeconomic Effects

Use `Figures/save_figures_for_scenarios_ee.m` as the base plotting template. The most informative macro panel is:

1. `GDP_Growth` (short-run activity effects)
2. `GDP` (level effect)
3. `Investment` (cost of transition and capital formation)
4. `Consumption` (welfare/proxy for household burden)
5. `EnergyIntensity` (core EE mechanism)
6. `FinalEnergyDemand` (demand compression channel)
7. `EnergyExpenditure` (energy-cost burden channel)
8. `Emissions` (environmental outcome and co-benefit)

## Comparison layout suggestion

For a clean attribution narrative, produce these figure groups:

- Group A (policy stringency): `EE_PDP8` vs `EE_Directive10`
- Group B (BESS attribution inside Directive10): `EE_Directive10` vs `EE_Directive10_NoBESS`
- Group C (PV+BESS package attribution): `EE_PDP8_PV_BESS` vs `EE_PDP8_PV_BESS_NoBESS`
- Group D (cross-package benchmark): `EE_PDP8`, `EE_Directive10`, `EE_PDP8_PV_BESS`

## Notes for reproducibility

- The old and new files are structurally different by design; this document therefore reports explicit structural and variable-level changes rather than formula-by-formula diffs.
- If `EE_Directive10_PV_BESS` is required, add that scenario sheet in `ModelScenarios5Sectorsand1Regions.xlsx` or update `RunSimulations.m` to the existing `EE_PDP8_PV_BESS` name.