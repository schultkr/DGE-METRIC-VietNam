# EE Scenarios with Transparent & Verifiable RTS Deployment Assumptions

## Executive Summary

This document proposes a new generation of energy-efficiency (EE) scenarios for the DGE-METRIC model that explicitly decouple and track two independent policy levers:

1. **Sectoral Energy Efficiency Improvements** — measured as energy service per unit output within each sector (industry, commercial, households)
2. **Rooftop Solar (RTS) Deployment by Sector** — measured as installed capacity and cost accumulation within each sector

This design replaces the current "embedded" approach (where RTS effects are folded into headline energy-saving percentages) with a **transparent, audit-able methodology** where each assumption is independently documented, sourced, and can be challenged or refined by domain experts.

---

## Motivation

### Current Limitation

The existing `create_ee_scenarios_from_expert_inputs.m` script treats `Industry_EE_Saving_pct` and `Services_EE_Saving_pct` as **all-in targets** that implicitly include any energy-saving benefits from rooftop solar installation. This approach:

- **Obscures the decomposition**: it is unclear what fraction of the headline saving comes from EE retrofits vs. RTS displacement of grid demand.
- **Limits policy granularity**: a policymaker cannot easily adjust RTS targets independently without re-specifying the entire EE saving.
- **Complicates audit trails**: when results diverge from expert expectations, it is hard to trace which assumption (EE per-sector or RTS per-sector) drove the difference.
- **Conflates two technologies**: efficiency and renewable substitution, though correlated, are distinct margin-of-adjustment mechanisms.

### New Approach

A **transparent, component-based design** where:

1. **Energy efficiency** is specified as a time-path of sectoral energy intensity improvements (e.g., "Industry saves 2% of baseline energy per unit output by 2030").
2. **RTS deployment** is specified as a separate time-path of installed capacity additions and cost accumulation per sector (e.g., "Industry installs 500 MW of rooftop solar in 2026–2030, at an investment cost of USD $200M/year").
3. **Integration accounting** is explicit: both channels feed into separate model variables with documented calculation steps.
4. **Counterfactuals are feasible**: shutting down RTS deployment does not require re-specifying the EE pathway, and vice versa.

---

## Proposed Scenario Structure

### Input Specification (Excel or CSV)

Each EE scenario workbook now contains the following **independent columns**, sourced from expert elicitation or detailed technical analysis:

#### A. Sectoral Energy Efficiency Assumptions

| Column | Units | Meaning | Example |
|--------|-------|---------|---------|
| `Year` | integer | Calendar year | 2026, ..., 2050 |
| `EE_Intensity_Improvement_Primary_pct` | %/year or cumulative % | Primary sector energy per unit output reduction | 1.5% or 15% cumulatively by 2030 |
| `EE_Intensity_Improvement_Fossil_pct` | %/year or cumulative % | Fossil energy subsector | 2.0% |
| `EE_Intensity_Improvement_Renewables_pct` | %/year or cumulative % | Renewables subsector | 0.5% (mainly solar insolation, not a controllable EE lever) |
| `EE_Intensity_Improvement_Industry_pct` | %/year or cumulative % | Industry sector (aggregate or subsector detail) | 2.5% |
| `EE_Intensity_Improvement_Commercial_pct` | %/year or cumulative % | Commercial/services sector | 2.0% |
| `EE_Intensity_Improvement_Household_pct` | %/year or cumulative % | Household/residential sector | 1.8% |
| `EE_Investment_Cost_Industry_USDm_yr` | USD million/year | Cumulative cost of EE retrofits, equipment, and training in industry | 150 |
| `EE_Investment_Cost_Commercial_USDm_yr` | USD million/year | Cumulative cost in commercial | 40 |
| `EE_Investment_Cost_Household_USDm_yr` | USD million/year | Cumulative cost in households | 60 |

#### B. Sectoral RTS Deployment Assumptions

| Column | Units | Meaning | Example |
|--------|-------|---------|---------|
| `RTS_Capacity_Addition_Industry_MW_yr` | MW/year or cumulative MW | Rooftop solar installed capacity, industry | 50 MW/year |
| `RTS_Capacity_Addition_Commercial_MW_yr` | MW/year or cumulative MW | Rooftop solar installed capacity, commercial | 30 MW/year |
| `RTS_Capacity_Addition_Household_MW_yr` | MW/year or cumulative MW | Rooftop solar installed capacity, households | 20 MW/year |
| `RTS_Investment_Cost_Industry_USDm_yr` | USD million/year | Cumulative cost of RTS installation and grid integration, industry | 120 |
| `RTS_Investment_Cost_Commercial_USDm_yr` | USD million/year | Cumulative cost in commercial | 60 |
| `RTS_Investment_Cost_Household_USDm_yr` | USD million/year | Cumulative cost in households | 40 |
| `RTS_Grid_Integration_Gain_pct` | % | Energy yield gain from grid batteries/demand management enabling higher solar utilization | 5% |
| `RTS_Grid_Integration_Investment_USDbn_yr` | USD billion/year | Cumulative cost of grid-level BESS (battery storage) and smart controls | 0.8 |

#### C. Verification & Audit Columns (Optional but Recommended)

| Column | Units | Meaning | Example |
|--------|-------|---------|---------|
| `EE_Source_Industry` | text | Document or expert reference for industry EE assumption | "IEA ECBCS report #XYZ, 2024" |
| `EE_Source_Commercial` | text | Document or expert reference for commercial EE | "IEPE, MoIT feasibility study" |
| `EE_Savings_Mechanism_Industry` | text | Specific technologies/practices contributing to savings | "LED lighting, chiller efficiency, motor upgrades" |
| `RTS_Capacity_Source` | text | Document or regulatory baseline for RTS deployment | "PDP8 Annex, Table 4.2.1" |
| `RTS_Cost_Basis` | text | Cost assumption source | "NREL PVDB 2026, Vietnam-specific" |

---

## Model Integration

### Translation to Dynare Variables

The MATLAB script `create_ee_scenarios_transparent_rts.m` performs the following translations:

#### 1. EE Intensity → Productivity Shock

**Input:** `EE_Intensity_Improvement_Industry_pct` (e.g., 2.5% reduction in energy per output)  
**Translation:**
$$
\text{exo\_AI}_{4,1,2}(t) = \log\left(\frac{1}{1 - \text{EE\_Intensity\_Improvement}(t) / 100}\right)
$$

This follows the steady-state specification in `DGE_Model.mod` where the AI shock represents an efficiency gain in the energy-use production function.

**Rationale:** Energy savings are modeled as a productivity improvement in the capital–energy-labor bundle that produces sectoral output.

#### 2. EE Investment Cost → Capital Accumulation

**Input:** `EE_Investment_Cost_Industry_USDm_yr` (e.g., USD 150M/year)  
**Translation:**
$$
\text{exo\_GA}_{4,1}(t) = \text{exo\_GA}_{4,1}^\text{baseline}(t) + \sum_{s=1}^{t} \frac{\text{EE\_Investment\_Cost}(s)}{GDP_{\text{base}} \times 1000} \times (1 - \delta_{K_A})^{t-s}
$$

where $\delta_{K_A} = 0.10$ (annual depreciation), and $\text{GDP}_{\text{base}}$ is Vietnam's 2025 GDP baseline (~430 USD billion).

**Rationale:** EE retrofits require capital investment; the accumulated stock enters the model via an exogenous adaptation-capital shock (`exo_GA`), which affects capital deepening and sectoral productivity dynamics.

#### 3. RTS Deployment → Grid Productivity & Investment Costs

**Input:** `RTS_Capacity_Addition_Industry_MW_yr`, `RTS_Investment_Cost_Industry_USDm_yr`  
**Translation:**

- **Energy displaced from grid:** captured implicitly in the EE channel (to avoid double-counting, RTS electricity generation reduces final fossil demand, modeled via the combined energy-efficiency productivity shock).
- **RTS investment cost:** accumulated separately into `exo_GA` for the renewable-energy subsector (sector 3), specifically tracking grid-level balance-of-system costs and micro-grid infrastructure.
- **Integration gain (BESS + smart control):** captured in `exo_PVEff_r(t)` (the PV integration-gain shock), which models how grid-scale battery storage increases the economic value of solar by smoothing supply fluctuations.

#### 4. Grid Integration (BESS) → PV Effectiveness Shock

**Input:** `RTS_Grid_Integration_Gain_pct` (e.g., 5% higher utilization), `RTS_Grid_Integration_Investment_USDbn_yr`  
**Translation:**
$$
\text{exo\_PVEff}_{1}(t) = \log(1 + \text{RTS\_Grid\_Integration\_Gain\_pct}(t) / 100)
$$
$$
\text{exo\_GA}_{3,1}(t) = \text{exo\_GA}_{3,1}^\text{baseline}(t) + \sum_{s=1}^{t} \frac{\text{RTS\_Grid\_Integration\_Investment}(s) \times 1000}{GDP_{\text{base}}} \times (1 - \delta_{K_A})^{t-s}
$$

**Rationale:** Grid-level BESS increases the effective output of PV installations by matching supply to demand peaks; this is modeled as a multiplicative effectiveness gain on renewable capital productivity.

---

## Implementation: Script & Workflow

### New Script: `create_ee_scenarios_transparent_rts.m`

Location: `scripts/maintenance/create_ee_scenarios_transparent_rts.m`

**Features:**
- Reads transparent expert input CSVs (separate EE and RTS columns).
- Performs validation of input assumptions (e.g., capacity additions are cumulative and non-decreasing).
- Computes verification tables showing:
  - Annual energy saved (GJ/year) by sector and mechanism (EE vs. RTS).
  - Cumulative investment by sector and mechanism.
  - Installed RTS capacity and capacity factors (implied).
  - Comparison to baseline exogenous trends.
- Writes scenario sheets to a **new workbook** `ModelScenarios_TransparentEE_5Sectorsand1Regions.xlsx` (leaving the original `ModelScenarios5Sectorsand1Regions.xlsx` untouched).
- Generates an audit CSV (e.g., `EE_Scenario_Audit_<name>.csv`) that documents:
  - Each input assumption with its source.
  - Intermediate calculations (e.g., cumulative energy saved, derived productivity shocks).
  - Counterfactual pathways (e.g., "if RTS is 0" or "if EE is 0").

### Expert Input Template

**File:** `ExcelFiles/Input/ExpertClean/Transparent_EE_Scenarios_Template.csv`

Example rows:
```
Year,EE_Intensity_Improvement_Industry_pct,EE_Intensity_Improvement_Commercial_pct,EE_Investment_Cost_Industry_USDm_yr,EE_Investment_Cost_Commercial_USDm_yr,RTS_Capacity_Addition_Industry_MW_yr,RTS_Capacity_Addition_Commercial_MW_yr,RTS_Investment_Cost_Industry_USDm_yr,RTS_Investment_Cost_Commercial_USDm_yr,RTS_Grid_Integration_Gain_pct,RTS_Grid_Integration_Investment_USDbn_yr,EE_Source_Industry,EE_Mechanism_Industry,...
2026,2.0,1.8,150,40,50,30,120,60,3.0,0.5,"IEA ECBCS 2024","LED + chiller retrofit",...
2027,2.1,1.9,155,42,55,32,125,62,3.2,0.6,...
...
```

---

## Validation & Audit

### Transparency Checklist

Before running a scenario, verify:

- [ ] All EE assumptions are sourced from published studies or expert elicitation (documented in `*_Source_*` columns).
- [ ] RTS capacity additions are physically plausible (compare to Vietnam's recent solar installation rate: ~5–7 GW/year nationally across all sectors).
- [ ] RTS capacity × capacity factor (assumed 15% in Vietnam) × ΔT (8760 hours/year) ≈ expected annual energy displacement.
- [ ] EE investment costs are consistent with literature benchmarks (e.g., USD 300–500/kW for industrial chiller retrofit).
- [ ] Grid integration investment is proportional to cumulative RTS capacity (e.g., USD 50–100/kW of installed capacity for BESS + controls).

### Verification Outputs

The new script generates:

1. **Scenario audit CSV:** `EE_Scenario_Audit_<scenario_name>.csv`
   - Lists all inputs, intermediate calculations, and derived model variables.
   - Allows cross-check against expert expectations and literature.

2. **Comparison plots** (optional, written to `Figures/EE_Scenarios_Transparent/`):
   - Time-paths of exo_AI, exo_GA, exo_PVEff by scenario.
   - Cumulative energy saved and invested capital by sector.
   - Capacity utilization and implicit grid integration effectiveness.

3. **Summary table:** `EE_Scenarios_Summary_Statistics.xlsx`
   - One row per scenario.
   - Columns: peak EE saving %, total EE investment (USD bn), total RTS capacity (GW), BESS investment (USD bn), implied carbon intensity reduction (if combined with cap-and-trade).

---

## Example Scenarios

### Scenario A: "EE_Baseline_RTS_Conservative"

**Assumption Set:**
- EE intensity improvements: 1.5–2.5%/year by sector (in line with Vietnam's recent historical trend).
- RTS deployment: 20–30 GW by 2050 (conservative relative to PDP8's 100+ GW aspiration).
- Grid integration: modest BESS deployment (15–20% of installed RTS capacity by 2050).
- Key metric: Total EE investment USD 8–10 bn; RTS investment USD 15–20 bn; BESS investment USD 2–3 bn.

### Scenario B: "EE_Enhanced_RTS_Ambitious"

**Assumption Set:**
- EE intensity improvements: 2.5–4.0%/year by sector (aggressive retrofit pace).
- RTS deployment: 50–80 GW by 2050 (aligned with PDP8 high pathway).
- Grid integration: substantial BESS deployment (50%+ of installed RTS capacity by 2050).
- Key metric: Total EE investment USD 15–18 bn; RTS investment USD 40–60 bn; BESS investment USD 8–12 bn.

### Scenario C: "EE_Only"

**Assumption Set:**
- EE intensity improvements: same as Scenario B.
- RTS deployment: 0 (zero installed capacity, zero cost).
- Grid integration: baseline (no BESS above baseline).
- **Purpose:** Isolate the macroeconomic contribution of EE retrofits alone.

### Scenario D: "RTS_Only"

**Assumption Set:**
- EE intensity improvements: baseline (zero additional improvement).
- RTS deployment: same as Scenario B.
- Grid integration: same as Scenario B.
- **Purpose:** Isolate the macroeconomic contribution of RTS deployment and grid integration alone.

---

## Benefits

1. **Transparency:** Each assumption is explicitly named, sourced, and separated from others.
2. **Auditability:** Domain experts can challenge specific input paths without invalidating the entire scenario.
3. **Modularity:** Counterfactual scenarios (e.g., "no RTS" or "double EE investment") require only simple input modifications.
4. **Decomposition:** Comparative statics clearly show the marginal contribution of EE vs. RTS vs. BESS/grid integration.
5. **Policy relevance:** Policymakers can map their planned investments directly to model inputs without layers of interpretation.

---

## Timeline & Next Steps

1. **Design & Review** (this document): stakeholder feedback on component structure.
2. **Expert Elicitation:** gather verifiable assumptions for 2–3 pilot scenarios (e.g., "Baseline," "Enhanced EE," "Enhanced RTS").
3. **Script Development:** implement `create_ee_scenarios_transparent_rts.m` with validation and audit outputs.
4. **Pilot Runs:** simulate 1–2 scenarios with the new workbook; compare results to existing embedded-EE scenarios to validate the translation logic.
5. **Documentation:** publish scenario audit CSVs and comparison tables in `ExcelFiles/Output/TransparentEE/`.

---

## References

- **Model:** DGE-METRIC documentation ([docs/reference/model.md](../reference/model.md)).
- **Current EE Scenarios:** `create_ee_scenarios_from_expert_inputs.m` (existing implementation; retained as archived baseline).
- **Expert Inputs:** `ExcelFiles/Input/ExpertClean/` directory.
- **Vietnam Solar Deployment:** PDP8 (Power Development Plan), Ministry of Industry & Trade; IEA PVDB 2026.
- **EE Cost Benchmarks:** IEA Technology Collaboration Programme (TCP) reports on retrofit costs and energy savings by sector.
