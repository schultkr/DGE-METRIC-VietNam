# Energy Efficiency Pathway (Day 1 Afternoon)

This page is the training quick-start for the energy-efficiency pathway used in the Day 1 afternoon online session.

## Policy framing

**Policy context.** Improving energy efficiency is among the most cost-effective ways to moderate electricity demand, reduce pressure on new generation and network investment, and support economic growth. Viet Nam's Adjusted Power Development Plan VIII (PDP8) provides the power-system planning context. Prime Minister's Directive No. 10/CT-TTg of 30 March 2026 strengthens near-term implementation by calling for at least 3% national electricity savings in 2026, a reduction of at least 3,000 MW in peak demand when supply is tight, wider demand-side management, and faster deployment of self-consumption rooftop solar. The Directive also explicitly encourages rooftop solar paired with battery energy storage systems (BESS) to reduce peak demand and improve local supply flexibility. The analysis therefore asks whether stronger demand-side efficiency produces macroeconomic benefits sufficient to justify the additional investment, while assessing BESS separately to distinguish its contribution to power-system performance from its aggregate macroeconomic effects.

**Directive 10 energy-efficiency and solar-PV pathway.** Directive No. 10/CT-TTg places electricity saving and demand-side management at the centre of Viet Nam's response to rapid demand growth and emerging risks to security of supply. It calls for stronger electricity savings, lower peak demand, more efficient equipment and production processes, and accelerated deployment of self-consumption rooftop solar photovoltaic (PV) systems. The Directive encourages public bodies, businesses, service providers, and households to install rooftop PV and promotes its integration with battery energy storage systems (BESS) to reduce peak demand, increase on-site electricity supply, and improve system flexibility. The `EE_Directive10` scenario translates this combined policy direction—greater energy efficiency, expanded rooftop PV, and improved PV integration—into an economy-wide pathway and is evaluated against the more moderate `EE_PDP8` reference. The pathway assumes sector-specific energy savings by 2030 of approximately 7.4% in industry and 5.1% in services, supported by combined energy-efficiency investment of about USD 361 million per year, equivalent to approximately 0.076% of GDP. These values are expert-calibrated modeling assumptions used to represent the Directive's higher ambition; they are not quantitative targets stated verbatim in the Directive. Both pathways are assessed under the same emissions trajectory, maintained through the emissions trading system, so that differences in outcomes capture the macroeconomic effects of stronger efficiency and PV deployment rather than differences in emissions. Additional `NoBESS` counterfactuals retain the energy-efficiency and PV assumptions but remove the storage-specific channels, thereby identifying the contribution of BESS to aggregate economic performance.

Core scenario pairs:
- `EE_PDP8` vs `EE_PDP8_NoBESS`
- `EE_Directive10` vs `EE_Directive10_NoBESS`
- `EE_PDP8_PV_BESS` vs `EE_PDP8_PV_BESS_NoBESS`

Pairwise differences isolate BESS contribution.

## Where assumptions live

Primary source workbook:
- `ExcelFiles/PDP8/Vietnam_EnergyExpert_ScenarioInputs - Adjust_2505.xlsx`

Fallback source workbook:
- `ExcelFiles/Vietnam_EnergyExpert_ScenarioInputs.xlsx`

Scenario writer script:
- `scripts/maintenance/create_ee_scenarios_from_expert_inputs.m`

Model scenario workbook (written by the script):
- `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx`

Technical design details:
- `docs/ee_scenario_design.md`
- `docs/ee_pv_coupling.md`

Policy interpretation and figures:
- `docs/use_cases_ee.md`

## Main mapping logic (expert inputs to model shocks)

- Industry and services EE saving percentages map into productivity shocks.
- EE and RTS investment costs map into accumulation channels for additional capital stock.
- PV integration gain and BESS investments map into dedicated efficiency and capital channels.
- In NoBESS sheets, BESS-specific channels revert to baseline while EE channels are preserved.

## Day 1 afternoon workflow

1. Inspect expert assumptions in the source workbook.
2. Regenerate EE scenario sheets with `create_ee_scenarios_from_expert_inputs.m`.
3. Validate that full and NoBESS sheets were written correctly.
4. Confirm scenario group selection in `RunSimulations.m`.
5. Run scenarios and prepare Day 2 interpretation outputs.

## Suggested checks before Day 2 run-and-interpret block

- Verify year alignment between expert input years and baseline years.
- Confirm terminal-year behavior for extrapolated paths.
- Confirm NoBESS sheets only reset BESS channels (not EE productivity channels).

## Related references

- `docs/scenarios_overview.md`
- `docs/ee_scenario_design.md`
- `docs/running.md`
