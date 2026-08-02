# Scenarios at a Glance

DGE-METRIC scenarios are organized into four families. Each family asks a distinct policy question. All scenarios share the same model and calibration; they differ in the exogenous shock paths fed to the model.

---

## Scenario logic: nested counterfactuals

The design follows a **layered counterfactual** approach:

```
Baseline (PDP8)
│
├── Net-Zero (NZ) ──────────────────────── adds: binding emissions cap + ETS
│     ├── NZ_constInt ─────────────────── removes: emission-intensity improvement
│     └── NZ_constEEInt ───────────────── removes: energy efficiency + intensity
│
├── Energy Efficiency ───────────────────  adds: EE shocks on PDP8 baseline
│     ├── EE_PDP8
│     ├── EE_Directive10
│     └── EE_PDP8_PV_BESS (+ NoBESS variants)
│
└── Green Finance ───────────────────────  modifies: cost-of-capital and investment paths
      ├── On PDP8: GF_A, GF_B, GF_C
      └── On NZ:   NZ_GF_A, NZ_GF_B, NZ_GF_C
```

Each node is comparable to its parent by construction. Taking differences isolates the contribution of the added or removed mechanism.

---

## Reference scenarios

| Scenario | Short name | What it models | Key shock type |
|---|---|---|---|
| Policy-consistent baseline | `Baseline` | Vietnam economy following PDP8 plan; no binding carbon constraint | None (calibrated path) |
| Net-Zero | `NZ` | Binding emissions cap declining to net-zero by 2050; economy-wide ETS activated | Emissions cap + endogenous carbon price |
| NZ — constant emission intensity | `NZ_constInt` | NZ without fuel-switching within fossil categories | Emission coefficients held fixed |
| NZ — constant energy efficiency | `NZ_constEEInt` | NZ without energy efficiency gains and without fuel-switching | Energy & emission efficiency held fixed |

**When to use:** Use the Baseline vs NZ comparison to quantify the overall transition cost. Use constrained NZ variants to decompose how much of that cost would be saved or worsened if efficiency or fuel-switching channels were unavailable.

---

## Energy efficiency scenarios

| Scenario | Short name | What it models | Key shock type |
|---|---|---|---|
| EE under PDP8 | `EE_PDP8` | Industry and services EE improvements consistent with PDP8 efficiency targets | Energy productivity improvement in industry and services |
| EE under PM Directive 10 | `EE_Directive10` | Stronger EE ambition aligned with Vietnam's Prime Minister Directive 10/CT-TTg for industry and services | Higher energy productivity improvement + additional upfront investment cost |
| EE_PDP8 without BESS | `EE_PDP8_PV_BESS_NoBESS` | EE_PDP8 PV+BESS variant with BESS contribution removed | Battery storage contribution removed |
| Directive 10 without BESS | `EE_Directive10_NoBESS` | EE_Directive10 with BESS contribution removed | Battery storage contribution removed |

**NoBESS counterfactuals:** The difference between a full scenario and its NoBESS counterpart isolates the macroeconomic contribution of battery energy storage systems (BESS) within the transition.

**Key efficiency inputs (2030 reported targets):**

- Industry EE saving: ~7.4% of sectoral energy demand
- Services EE saving: ~5.1%
- Households: ~11.6%
- Annual EE investment: approximately USD 361 million/year (~0.076% of GDP)

**When to use:** Use EE scenarios to assess demand-side transition levers. Compare EE_PDP8 vs EE_Directive10 to evaluate the macro return to scaling up efficiency ambition. See [Use case: Energy Efficiency](use_cases_ee.md) for a full worked example.

---

## Green finance scenarios

These scenarios ask: **does the architecture of green finance — who provides capital, at what rate — change macroeconomic outcomes materially?**

Three financing structures are compared, differentiated by their Weighted Average Cost of Finance (WACF):

| Scenario | Short name | Financing structure | WACF | Annual financing cost (USD 136bn base) |
|---|---|---|---|---|
| Balanced finance | `PDP8_GF_A` / `NZ_GF_A` | Mix of ODA/MDB concessional, blended public/private, green bonds | 6.43% | USD 8.74bn/year |
| Market-led finance | `PDP8_GF_B` / `NZ_GF_B` | Predominantly private/market-rate capital | 7.37% | USD 10.02bn/year |
| Public-led finance | `PDP8_GF_C` / `NZ_GF_C` | ODA-heavy, concessional and quasi-sovereign instruments dominant | 5.07% | USD 6.89bn/year |

Each finance scenario runs on both the **PDP8 baseline** and the **Net-Zero** path, giving six total finance runs (GF_A/B/C × Baseline/NZ).

**Operational status:** the scenario names and their routing logic are fully
wired in `RunSimulations.m` (`scenarioGroups.GF_PDP8`, `scenarioGroups.GF_NZ`),
but these groups are not part of the default `activeScenarioGroups`, and
whether the underlying WACF shock data is already present in
`ModelScenarios5Sectorsand1Regions.xlsx` is unconfirmed — see
[Scenario design: implementation details](../reference/scenario.md#green-finance-scenarios)
for the current status.

**Model representation:** Finance instruments are translated into their aggregate macroeconomic effect — changes in the cost of capital for public and foreign investment, and in the effective price of new energy capital. The model does not represent individual bond instruments or guarantee balance sheets, but captures their combined impact on investment and consumption dynamics.

**When to use:** Use GF scenarios to quantify the macroeconomic value of closing the green finance gap. Compare GF_C (public-led, cheapest) vs GF_B (market-led, most expensive) to bound the range of transition costs under different financing conditions. See [Use case: Green Finance](use_cases_finance.md) for a full worked example.

---

## Scenario input files

| Workbook | Used for |
|---|---|
| `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx` | Baseline calibration and all reference scenarios |
| `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx` | EE and NZ scenario shock paths |
| `ExcelFiles/ScenarioPathDefinition.xlsx` | Scenario metadata and path mappings |
| `ExcelFiles/PDP8/Vietnam_EnergyExpert_ScenarioInputs*.xlsx` | Expert EE inputs (source for create_ee_scenarios_from_expert_inputs.m) |
| `ExcelFiles/PDP8/Vietnam_Green_Finance_Scenarios_April2026.xlsx` | Finance WACF/allocation source workbook |

---

## Further reading

- [Use case: Energy Efficiency](use_cases_ee.md)
- [Use case: Green Finance](use_cases_finance.md)
- [Scenario design (technical)](../reference/scenario.md)
- [EE scenario design (implementation detail)](../scenario_notes/ee_scenario_design.md)
- [Finance instruments feasibility](../scenario_notes/finance_instruments_comments_feasibility.md)
- [Running the model](../reference/running.md)
