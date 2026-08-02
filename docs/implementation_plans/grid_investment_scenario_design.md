# Grid Investment Scenario Design for Renewable-Expansion Effectiveness (Vietnam)

> **Status: proposed, not implemented.** This is a design note for a scenario
> that does not yet exist in `RunSimulations.m` or the scenario workbooks. Do
> not cite it as a description of current model capability — see
> [docs/scenarios_overview.md](../policy/scenarios_overview.md) for what is actually
> implemented.

Date: 2026-06-08

## Objective

Design a scenario that shows whether higher grid investment makes renewable capacity expansion more effective in:
- reducing emissions,
- containing power prices,
- limiting macro adjustment costs.

The key identification idea is to hold renewable expansion ambition fixed and vary only the grid-enabling channel.

## Recommended Design: 2x2 Scenario Matrix

Use a factorial design with two dimensions:
- Renewable expansion ambition: Low vs High
- Grid support strength: Weak vs Strong

Suggested sheet names:
- `NZ_RELow_GridWeak`
- `NZ_RELow_GridStrong`
- `NZ_REHigh_GridWeak`
- `NZ_REHigh_GridStrong`

This extends your current NZ-style logic and allows direct estimation of complementarity between renewables and grid investments.

## How to Map into Existing Model Channels

Use channels already present in your workflow:
- `exo_PV_1`: distributed/RTS capital channel (renewables build-out lever)
- `exo_PVEff_1`: PV integration effectiveness (grid flexibility/absorption lever)
- `exo_GA_3_1`: adaptation-capital cost channel for BESS/grid integration spending
- `exo_CapTrade_1`: keep equal across all four scenarios (recommended: 1)

Implementation principle:
- Change `exo_PV_1` between `RELow` and `REHigh`.
- Change `exo_PVEff_1` (and optionally `exo_GA_3_1`) between `GridWeak` and `GridStrong`.
- Keep all other policy settings aligned.

## Calibration Logic (Practical)

Use a phased schedule to avoid abrupt jumps:
- 2026-2030: investment ramp-up
- 2031-2040: system integration acceleration
- 2041-2050: saturation and stabilization

Simple quantitative anchors for first run:
- `RELow`: 0.7x of current RTS/PV expansion path
- `REHigh`: 1.3x of current RTS/PV expansion path
- `GridWeak`: keep `exo_PVEff_1` near baseline trend
- `GridStrong`: add +20% to +40% cumulative `exo_PVEff_1` by 2050 versus `GridWeak`

For cost realism:
- Pair `GridStrong` effectiveness with higher `exo_GA_3_1`.
- Keep financing assumptions constant unless financing is the explicit focus.

## Core Estimands

For any outcome `X_t` (e.g., emissions, GDP deviation, power prices):

Grid effect at fixed RE level:
- `DeltaGrid(RELow, t) = X_RELow_GridStrong(t) - X_RELow_GridWeak(t)`
- `DeltaGrid(REHigh, t) = X_REHigh_GridStrong(t) - X_REHigh_GridWeak(t)`

Complementarity (difference-in-differences):
- `Complementarity(t) = DeltaGrid(REHigh, t) - DeltaGrid(RELow, t)`

Interpretation:
- For emissions and prices: stronger negative values indicate stronger grid enablement.
- For GDP: less-negative (or positive) values indicate lower transition cost.

## Indicators to Report (Available in Current Outputs)

Use variables already used in NZ reporting:
- Emissions: `E_1`
- GDP: `Y_1`
- Grid energy price index basis: `P_A_2_1`
- Grid-provided final demand: `Q_A_F_2_1`
- PV-provided final demand: `Q_PV_1`

Useful derived indicators:
- PV share proxy: `Q_PV_1 / (Q_PV_1 + Q_A_F_2_1)`
- Renewable effectiveness ratio: `(-Delta E_1) / Delta Q_PV_1`
- Cost-effectiveness ratio: `(-Delta E_1) / Delta(transition investment share)`

## Minimal Pair if You Want a Faster First Pass

If a 2x2 is too heavy, start with one paired counterfactual at high renewable ambition:
- `NZ_REHigh_GridWeak`
- `NZ_REHigh_GridStrong`

This directly answers: "How much does grid investment improve the payoff of the same renewable expansion plan?"

## Execution Steps in This Repository

1. Add scenario sheets to `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx` with the names above.
2. Populate exogenous paths for `exo_PV_1`, `exo_PVEff_1`, `exo_GA_3_1`, and `exo_CapTrade_1`.
3. Add a new scenario group in `RunSimulations.m` and include it in `activeScenarioGroups`.
4. Run `RunSimulations`.
5. Reuse `scripts/reporting/generate_nz_baseline_comparison_figures.m` as a template to produce pairwise and difference-in-differences charts.

## Suggested Visuals for Policy Communication

- Emissions paths by the four scenarios
- PV share proxy by scenario
- Grid price index by scenario
- GDP deviation vs baseline by scenario
- Difference-in-differences bars for 2026-2030, 2031-2035, 2036-2040, 2041-2045, 2046-2050

This presentation makes the "grid as an enabler" result visible even for non-technical stakeholders.
