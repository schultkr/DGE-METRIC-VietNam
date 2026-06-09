# What is DGE-METRIC?

DGE-METRIC (**D**ynamic **G**eneral **E**quilibrium for **M**acroeconomic **E**nergy **T**ransition **I**ncorporating **C**arbon markets) is a macroeconomic model designed to evaluate the economy-wide consequences of energy transition policies, financing strategies, and climate risks — applied to Vietnam.

It is developed under a joint GIZ-IWH research project to support evidence-based policy dialogue in Vietnam's transition toward Power Development Plan 8 (PDP8) targets and longer-term net-zero ambitions.

---

## What questions can the model answer?

The model is built to address questions that sit at the intersection of energy, macroeconomics, and fiscal policy:

- How much does meeting PDP8 investment needs cost in terms of GDP, consumption, and employment?
- Does more ambitious energy efficiency reduce transition costs or require larger upfront investment?
- How does the architecture of green finance — the mix of concessional, blended, and market-rate capital — affect the pace and affordability of the transition?
- What carbon price trajectories are consistent with net-zero, and how sensitive are they to efficiency improvements?
- How do ETS revenues flow back into the economy, and can they fund transition support measures?
- Which sectors bear the largest structural adjustment burden, and over what time horizon?

---

## How the model works — in plain language

DGE-METRIC simulates the Vietnamese economy as a system of interacting agents over a **25-year horizon (2026–2050)**. The model is *forward-looking*: firms, households, and the government make decisions today knowing what the policy environment will look like in future years. This captures the investment front-loading and anticipation effects that are central to transition dynamics.

### Economic agents

```
┌─────────────────────────────────────────────────────────────────┐
│  REST OF THE WORLD                                              │
│  (Private capital, Public capital, Imports & Exports)           │
└──────────────┬──────────────────────────────┬───────────────────┘
               │                              │
     ┌─────────▼──────────┐        ┌──────────▼──────────┐
     │    GOVERNMENT      │        │     HOUSEHOLDS       │
     │  Taxes, Transfers, │◄──────►│  Consume, Save,      │
     │  ETS permits       │        │  Supply labor        │
     └────────┬───────────┘        └──────────┬───────────┘
              │                               │
     ┌────────▼───────────┐                   │
     │  EMISSION TRADING  │        ┌──────────▼───────────┐
     │  SYSTEM (ETS)      │        │   RETAIL SECTOR       │
     │  Carbon price,     │        │  Final goods assembly │
     │  Permit supply     │        └──────────┬───────────┘
     └────────▲───────────┘                   │
              │                    ┌──────────▼───────────┐
     ┌────────┴───────────┐        │    WHOLESALERS        │
     │  PRODUCTION SECTOR │◄──────►│  Intermediate trade   │
     │  (Firms, 5 sectors)│        └───────────────────────┘
     └────────────────────┘
```

Each agent follows explicit optimizing rules. The model traces how a policy change ripples through all of these channels simultaneously — not just the direct effect in one sector.

### Five sectors

The production side is disaggregated into five sectors calibrated to Vietnam's economic structure:

| # | Sector | Role in energy transition |
|---|--------|--------------------------|
| 1 | Non-energy aggregate | General production; affected by energy costs and labor reallocation |
| 2 | Fossil energy | Coal, gas, oil; the incumbent energy system |
| 3 | Renewable energy | Solar, wind, hydro; the expanding clean system |
| 4 | Industry | Manufacturing; major energy consumer and EE target |
| 5 | Services | Commercial and public services; secondary energy consumer |

### What drives scenario differences

The model distinguishes three families of transition drivers:

1. **Energy efficiency (demand-side):** How much energy industry and services need per unit of output — the `exo_AI` channels. Improving efficiency means the same GDP requires less fossil and renewable energy.

2. **Renewable investment and grid integration:** How quickly the renewable capital stock builds up and at what cost — the `exo_GA` and `exo_PVEff` channels.

3. **Carbon pricing and ETS:** A cap on total emissions forces an emissions trading price that increases over time. Higher carbon prices accelerate substitution away from fossil energy but raise transition costs. Revenue recycling — how permit income flows back to government, firms, or households — shapes the distributional outcome.

Financing scenarios modify the *cost of capital* for the transition: cheaper, longer-maturity, or blended public-private finance lowers the effective investment price, shifting the investment and consumption trade-off.

---

## What the model does not do

DGE-METRIC is a reduced-form macroeconomic model, not an energy-system planning model. It does not:

- Schedule individual power plants or compute optimal dispatch
- Model technology learning curves endogenously
- Represent sub-national regions or provincial governments
- Track individual financial instruments (green bonds, guarantees) as explicit balance-sheet items — these are translated into equivalent cost-of-capital or investment-price shocks

For technology cost projections and supply-stack details, the model draws on IEA World Energy Outlook and Vietnam PDP8 data as exogenous inputs.

---

## How to navigate the documentation

### I am new to the model

1. [Vietnam energy transition context](vietnam_context.md) — why this model was built and what the policy environment looks like
2. [Scenarios at a glance](scenarios_overview.md) — the full scenario set in one table
3. [Use case: Energy Efficiency](use_cases_ee.md) or [Use case: Green Finance](use_cases_finance.md) — worked examples with results

### I want to run or modify the model

1. [Running the model](running.md) — software requirements, quick start, common tasks
2. [Model equations](model.md) — full technical documentation with equations
3. [Calibration](calibration.md) — how baseline parameters are estimated
4. [Scenario design](scenario.md) — how shocks are constructed and loaded

### I want to understand a specific scenario family

- Energy efficiency scenarios: [EE scenario design](ee_scenario_design.md)
- Green finance scenarios: [Finance instruments feasibility](finance_instruments_comments_feasibility.md)
- Grid investment scenarios: [Grid investment scenario design](grid_investment_scenario_design.md)
