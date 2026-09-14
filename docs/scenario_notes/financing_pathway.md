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

## Financing taxonomy and share-derivation (citable reference)

### Instrument category → model channel

| Financing instrument category | Indicative cost | Model channel | Variable(s) |
|---|---|---|---|
| ODA / MDB concessional loans | 2–4% | Cost of government-intermediated capital | `exo_r_G_s` |
| Blended tranches, guarantees, credit enhancement, risk-sharing | 4–6% | Effective cost of capital / investment friction | `exo_r_G_s`, `exo_P_K_s` |
| Sovereign / quasi-sovereign green bonds | 5–7% | Government-intermediated capital cost | `exo_r_G_s` |
| Corporate green bonds, green credit (domestic) | 6–8% | Domestic private cost of capital (endogenous return on the residual share) | endogenous `r_s`; `exo_P_K_s` |
| Commercial bank credit | 8–10% | Domestic private cost of capital | endogenous `r_s` |
| FDI / foreign private capital | — | Cost of international private capital; FDI volume | `exo_r_FDI_s`, `exo_K_FDI_s` |
| Public / semi-public direct investment | — | Scale of public investment | `exo_K_G_s`, `exo_s_G_s` |

| Architecture | Structure | WACF | Annual cost vs `GF_B` |
|---|---|---|---|
| `GF_A` balanced | ODA/MDB + blended + green bonds in roughly equal shares | 6.43% | −USD 1.28 bn/yr |
| `GF_B` market-led | predominantly commercial / private capital | 7.37% | reference |
| `GF_C` public-led | ODA and concessional dominant | 5.07% | −USD 3.13 bn/yr |

### Share status labels

Renewable-investment ownership shares (public / FDI / domestic-private):
`GF_A` 19.0 / 14.0 / 67.0%; `GF_B` 9.6 / 12.4 / 78.0%; `GF_C` 36.5 / 19.0 / 44.5%.
Modelled public / FDI capital costs: `GF_A` 6.43 / 6.36%; `GF_B` 7.37 / 6.90%;
`GF_C` 5.07 / 6.00%.

| Component | Status | Basis |
|---|---|---|
| Public / FDI / domestic-private shares per architecture | **assumed (scenario)** | Chosen to span public-led → market-led; from the GF workbook |
| Instrument cost ranges (ODA 2–4% … commercial credit 8–10%) | **observed / calibrated** | World Bank / ADB / bilateral terms; Vietnam market rates |
| Headline WACF (6.43 / 7.37 / 5.07%) and modelled public/FDI capital costs | **calibrated from the assumed mix** | Weighted from the cost ranges and the assumed shares |
| Domestic private / household financing rate | **endogenous (residual)** | Solved through the household investment decision |

Source workbook: `ExcelFiles/PDP8/Vietnam_Green_Finance_Scenarios_April2026.xlsx`;
cost ranges from World Bank / ADB / bilateral terms and Vietnam market rates
(see `docs/policy/use_cases_finance.md`).

### Framing (use verbatim in the reports)

> Public finance is catalytic but constrained: it cannot substitute for private
> investment at the scale PDP8 requires. The central lever is **improving
> financing conditions and mobilising private capital** — lowering the weighted
> average cost of capital through blended finance, guarantees, risk-sharing,
> green bonds and green credit — not increasing the volume of public spending.

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
