# Financing Pathway (Day 1 Afternoon)

This page is the training quick-start for the green-finance pathway used in the Day 1 afternoon online session.

## Policy framing

Question: how much macroeconomic difference comes from the way the transition is financed (public-led vs market-led), holding the physical transition task constant?

Scenario family:
- `GF_A`: balanced finance
- `GF_B`: market-led finance
- `GF_C`: public-led (concessional-heavy) finance

Each is run on two parent paths:
- PDP8 baseline: `PDP8_GF_A`, `PDP8_GF_B`, `PDP8_GF_C`
- Net-zero path: `NZ_GF_A`, `NZ_GF_B`, `NZ_GF_C`

## Where assumptions live

Primary source workbook:
- `ExcelFiles/PDP8/Vietnam_Green_Finance_Scenarios_April2026.xlsx`

Model scenario workbook (shock paths consumed in runs):
- `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx`

Scenario routing and run groups:
- `RunSimulations.m` (`scenarioGroups.GF_PDP8`, `scenarioGroups.GF_NZ`)

Technical status and implementation details:
- `docs/scenario.md` (Green finance section)
- `docs/finance_instruments_comments_feasibility.md`

Policy interpretation and figures:
- `docs/use_cases_finance.md`

## Model channels used for financing effects

In reduced form, the financing structure affects the model through capital-cost and investment channels such as:
- `exo_r_G_s`
- `exo_r_FDI_s`
- `exo_P_K_s`
- (and, where configured, supporting public-capital path controls)

The model captures the macroeconomic effect of financing conditions, not instrument-level balance-sheet mechanics.

## Day 1 afternoon workflow

1. Confirm scenario assumptions and WACF mapping in the finance source workbook.
2. Check that translated shock paths are present in the model scenarios workbook.
3. Verify the intended run set in `RunSimulations.m` (or `DGE_SCENARIO_GROUPS`).
4. Run scenarios.
5. Review comparative outputs with a focus on renewable WACC and GDP-growth deviations.

## Suggested checks before Day 2 run-and-interpret block

- Ensure scenario sheet names in the workbook match the names routed in `RunSimulations.m`.
- Confirm that Baseline/NZ parent paths are both available for the selected finance scenarios.
- Keep one concise table of WACF assumptions and intended model channels for interpretation consistency.

## Related references

- `docs/scenarios_overview.md`
- `docs/use_cases_finance.md`
- `docs/running.md`
