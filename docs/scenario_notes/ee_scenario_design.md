# Energy Efficiency Scenario Design

Date: 2026-06-03

## Purpose

This note explains how the energy efficiency (EE) scenarios are designed, how expert assumptions are mapped into model shocks, and how the NoBESS counterfactual is constructed.

## Source Workbook

Primary source workbook:
- ExcelFiles/PDP8/Vietnam_EnergyExpert_ScenarioInputs - Adjust_2505.xlsx

Fallback source (if primary is missing):
- ExcelFiles/Vietnam_EnergyExpert_ScenarioInputs.xlsx

Scenario writer script:
- scripts/maintenance/create_ee_scenarios_from_expert_inputs.m

Target workbook updated by the script:
- ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx

## Scenario Architecture

The script reads three expert sheets and writes six model sheets (full + NoBESS pairs):

| Expert sheet | Full scenario sheet | Counterfactual sheet |
|:--|:--|:--|
| EE_PDP8_reference | EE_PDP8 | EE_PDP8_NoBESS |
| Directive10_RTS_EE | EE_Directive10 | EE_Directive10_NoBESS |
| PDP8_PV_EV_BESS | EE_PDP8_PV_BESS | EE_PDP8_PV_BESS_NoBESS |

Interpretation:
- Full sheet = EE + RTS + BESS channels active.
- NoBESS sheet = same EE path, but BESS-specific channels reset to baseline.
- Difference (Full - NoBESS) isolates BESS contribution.

## Input to Model Variable Mapping

### EE productivity channel

- Industry_EE_Saving_pct -> exo_AI_4_1_2
- Services_EE_Saving_pct -> exo_AI_5_1_2

Transformation used:

dAI = ln(1 / (1 - saving_pct / 100))

This increment is added to the baseline AI path.

### EE and RTS investment cost channels

- Industry_EE_Investment_USDm + RTS_Industry_Investment_USDm -> exo_GA_4_1
- Services_EE_Investment_USDm + RTS_Services_Investment_USDm -> exo_GA_5_1

Accumulation law:

K_A(t) = (1 - deltaKA) * K_A(t-1) + Investment(t) / GDP0

Parameters in script:
- deltaKA = 0.10
- GDP0 = 430000 (USD million)

### BESS channels

- PV_Integration_Gain_pct -> exo_PVEff_1
- BESS_Annual_Investment_USDbn -> exo_GA_3_1 (after bn to million conversion)

Transformations:
- exo_PVEff_1 increment = ln(1 + gain_pct / 100)
- BESS investment stock uses the same K_A accumulation law as above.

### Household RTS channel

- RTS_Household_Investment_USDm -> exo_PV_1 via accumulated stock.

### Scenario switches

- exo_lAddEE_4_1 = 1
- exo_lAddEE_5_1 = 1
- exo_CapTrade_1 = 1

## Year Alignment and Extrapolation

- Baseline years are read from the Baseline sheet in ModelBaseline5Sectorsand1Regions.xlsx.
- Expert years are intersected with baseline years.
- For years beyond the last expert observation, terminal-rate extrapolation is applied to:
  - dAI paths,
  - exo_PVEff increment path,
  - accumulated stock dynamics continue through depreciation plus any available investments.

## NoBESS Counterfactual Definition

In each _NoBESS sheet, three variables revert to baseline:
- exo_PVEff_1
- exo_GA_3_1
- exo_PV_1

All EE-related productivity and cost channels remain as in the paired full scenario.

## Operational Workflow

Run from repository root:

1. Execute scripts/maintenance/create_ee_scenarios_from_expert_inputs.m
2. Inspect updated sheets in ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx
3. Use reporting scripts to compare scenario outcomes.

## Run Snapshot (2026-06-03)

The latest run used the adjusted workbook and completed successfully for all three scenario pairs.

Selected output milestones from script log:

| Scenario | AI industry (2030 / 2050) | AI commercial (2030 / 2050) | exo_PVEff (2030 / 2050) |
|:--|:--|:--|:--|
| EE_PDP8 | 0.0655 / 0.2090 | 0.1349 / 0.4737 | 0.3390 / 1.7120 |
| EE_Directive10 | 0.1120 / 0.2683 | 0.1671 / 0.5138 | 0.3686 / 1.8073 |
| EE_PDP8_PV_BESS | 0.0883 / 0.2355 | 0.1511 / 0.4915 | 0.3878 / 1.8430 |

## EE Scenario Assumptions Table (reproducibility reference)

This table is the citable assumptions summary for the reports. All values are
**increments added to the Baseline** `exo_AI_*` / `exo_PVEff_1` paths.

| Scenario | AI industry (2030 / 2050) | AI commercial (2030 / 2050) | `exo_PVEff` (2030 / 2050) | Annual EE investment | Expert input sheet |
|:--|:--|:--|:--|:--|:--|
| EE_PDP8 | 0.0655 / 0.2090 | 0.1349 / 0.4737 | 0.3390 / 1.7120 | ~USD 361 m/yr (industry + services) | `EE_PDP8_reference` |
| EE_Directive10 | 0.1120 / 0.2683 | 0.1671 / 0.5138 | 0.3686 / 1.8073 | higher near-term (Directive 10 ambition) | `Directive10_RTS_EE` |
| EE_PDP8_PV_BESS | 0.0883 / 0.2355 | 0.1511 / 0.4915 | 0.3878 / 1.8430 | industry + services + BESS annual investment | `PDP8_PV_EV_BESS` |

Reported sectoral energy savings by 2030 for EE_PDP8: industry ~7.4%, services
~5.1%, households ~11.6%.

**Underlying assumption file (traceable from the reports):**
`ExcelFiles/PDP8/Vietnam_EnergyExpert_ScenarioInputs - Adjust_2505.xlsx`
(fallback `ExcelFiles/Vietnam_EnergyExpert_ScenarioInputs.xlsx`), consumed by
`scripts/maintenance/create_ee_scenarios_from_expert_inputs.m`, which writes the
model shock paths into `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx`.

Key transformations (from the mapping above):
`Industry_EE_Saving_pct → exo_AI_4_1_2`, `Services_EE_Saving_pct → exo_AI_5_1_2`
via `dAI = ln(1 / (1 − saving_pct/100))`; investment USD → `exo_GA_*` via the
`deltaKA = 0.10` accumulation law on `GDP0 = 430,000` USD m;
`PV_Integration_Gain_pct → exo_PVEff_1` via `ln(1 + gain_pct/100)`.

> **BESS/RTS conditionality caveat (state upfront in any results discussion).**
> The headline GDP effects of the higher-ambition EE pathway are conditional on
> the assumed battery-storage (BESS) and self-consumption rooftop-solar (RTS)
> cost and deployment paths. The model captures their macro-investment and
> energy-efficiency consequences but not their hourly grid-integration value; a
> slower or costlier BESS/RTS rollout would reduce the estimated gains.

## Notes

- If the source workbook is open in Excel, writing may fail due to file lock.
- Scenario design is intentionally pair-based (Full vs NoBESS) to support clean attribution of BESS effects.