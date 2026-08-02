# PV-to-EE Coupling and VNEEP3 Targets: Computation of Energy-Productivity Gains

This document explains how rooftop solar (PV) deployment and Vietnam's National Energy Efficiency Program (VNEEP3) targets are translated into energy-productivity improvements (`exo_AI_s_r_2`, `exo_EE_r`) and adaptation-capital costs (`exo_GA_s_r`) in the DGE-METRIC baseline.

---

## VNEEP3 Policy Targets

**Source**: Decision 280/QD-TTg (2019) — Vietnam National Energy Efficiency Program Phase 3 (2019–2030); expert confirmation: "EE target 8–10% (2019–2030), follow VNEEP3" (Nguyen Hoang Lan, HUST, May 2026).

### Aggregate target
Vietnam's VNEEP3 mandates an **8–10% reduction in economy-wide energy intensity** relative to the 2019 BAU scenario by 2030. In the model this maps to the regional EE variable `exo_EE_1`.

| Scenario | Target | Annual log-rate 2025–2030 | Post-2030 rate | `exo_EE_1` by 2030 | `exo_EE_1` by 2050 |
|:--|:--|:--|:--|--:|--:|
| Baseline (PDP8) | VNEEP3 lower (8%) | +0.728%/yr | +0.300%/yr | +0.036 | +0.096 |
| EE scenario | VNEEP3 upper (10%) | +0.909%/yr | +1.000%/yr | +0.045 | +0.244 |

Excel formulas for `exo_EE_1`:
- Baseline: `=IF($A<=6, LN(1.00728^($A-1)), LN(1.00728^5*1.003^($A-6)))`
- EE scenario: `=IF($A<=6, LN(1.00909^($A-1)), LN(1.00909^5*1.01^($A-6)))`

where `$A` is the model period index (A=1 → 2025, A=6 → 2030).

### Sector-specific interpretation
VNEEP3 addresses industry and commercial buildings with particular emphasis. In the model the sector-specific residual above the aggregate `exo_EE_1` path is captured by `exo_AI_s_r_2`:

| Sector | VNEEP3 indicative target | Approximate annual saving (addl. vs aggregate) |
|:--|:--|:--|
| Industry (subsec 4) | 8–10% energy intensity reduction by 2030 | ~0.5–1.0%/yr beyond aggregate |
| Commercial/services (subsec 5) | 25–30% reduction in commercial electricity by 2030 | ~2.0–2.5%/yr beyond aggregate |

The **PV channel** computed below constitutes a quantified sub-component of these sector-specific gains. The remaining gap (non-PV EE measures — insulation, motors, building management systems) can be added to `exo_AI_s_r_2` as an additional increment.

### Combined sector-specific path (implemented)

`exo_AI_s_1_2` receives two additive increments written by `apply_vneep3_ee_targets` (non-PV VNEEP3 measures) plus the PV contribution from `apply_industrial_pv_to_ee_coupling`. The aggregate `exo_EE_1` multiplies on top of these in the model equation.

For the **industry** sector:

| Year | `exo_EE_1` (agg.) | VNEEP3 non-PV `exo_AI_4_1_2` | PV `exo_AI_4_1_2` | Total `exo_AI_4_1_2` | Full log-boost¹ |
|:--|--:|--:|--:|--:|--:|
| 2025 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| 2030 | +0.036 | +0.025 | +0.012 | **+0.037** | **+0.073** |
| 2040 | +0.057 | +0.055 | +0.040 | **+0.095** | **+0.152** |
| 2050 | +0.096 | +0.085 | +0.077 | **+0.162** | **+0.258** |

For the **commercial/services** sector:

| Year | `exo_EE_1` (agg.) | VNEEP3 non-PV `exo_AI_5_1_2` | PV `exo_AI_5_1_2` | Total `exo_AI_5_1_2` | Full log-boost¹ |
|:--|--:|--:|--:|--:|--:|
| 2025 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| 2030 | +0.036 | +0.100 | +0.017 | **+0.117** | **+0.153** |
| 2040 | +0.057 | +0.200 | +0.065 | **+0.265** | **+0.322** |
| 2050 | +0.096 | +0.300 | +0.138 | **+0.438** | **+0.534** |

¹ Full log-boost = `exo_EE_1` + `exo_AI_s_1_2` (multiplicative in model). Non-PV VNEEP3 column uses default rates (0.005/0.003 log/yr ind, 0.020/0.010 log/yr com, to2030/post2030).

The `exo_GA_s_1` cost path also receives a VNEEP3 increment (EE investment cost) on top of the PV capacity path:

| Year | VNEEP3 GA increment (industry) | VNEEP3 GA increment (commercial) |
|:--|--:|--:|
| 2030 | +0.015 of Y0_p | +0.010 of Y0_p |
| 2050 | +0.055 of Y0_p | +0.030 of Y0_p |

---

## Model Channels Summary

| Variable | Economic role | Driven by |
|:--|:--|:--|
| `exo_EE_1` | Aggregate regional energy efficiency (enters TFP and all sectors) | VNEEP3 aggregate 8–10% target |
| `exo_GA_4_1`, `exo_GA_5_1` | Adaptation capital expenditure (costs of PV/EE investment) | PV capacity index — `plan.idxIndustrial`, `plan.idxCommercial` |
| `exo_AI_4_1_2`, `exo_AI_5_1_2` | Log-productivity of energy intermediates — sector-specific (effectiveness) | PV generation / demand fractions; additional non-PV VNEEP3 measures |

`exo_GA` and `exo_AI` are **decoupled**: `K_A = exo_GA × Y0_p` captures costs; `exo_AI_s_r_2` enters directly as `exp(exo_AI_s_r_2)` multiplied by `EE_r = exp(exo_EE_r)` for the energy intermediate. `exo_EE_r` (aggregate VNEEP3 path) and `exo_AI_s_r_2` (sector-specific increment) combine multiplicatively.

---

## Data Sources

### Rooftop PV generation path
File: `ExcelFiles/Output/RTS_split_assumptions_from_expert_email.csv`

| Year | Industrial gen (GWh) | Household gen (GWh) | Commercial gen (GWh)¹ |
|:--|--:|--:|--:|
| 2025 | 17,300 | 14,638 | 4,391 |
| 2030 | 23,361 | 21,466 | 6,440 |
| 2040 | 42,598 | 46,160 | 13,848 |
| 2050 | 77,676 | 99,260 | 29,778 |

¹ Commercial = 30% of household generation (default split `rtsCommercialShareOfHousehold = 0.30`).

### Vietnam sectoral electricity demand (PDP8 reference)
Base year: **2025**, reference total demand **335 TWh** (Vietnam PDP8 scenario).

| Sector | Share | Base demand 2025 (GWh) | Annual growth assumed |
|:--|:--|--:|:--|
| Industrial (subsec 4) | 53% | 177,550 | 4.0% p.a. |
| Commercial/services (subsec 5) | 17% | 56,950 | 4.0% p.a. |

Parameter names in `create_baseline_from_user_input_file.m`:
- `IndustrialElecDemandBase_GWh = 177550`
- `CommercialElecDemandBase_GWh = 56950`
- `ElecDemandAnnualGrowth_Ind = 0.040`
- `ElecDemandAnnualGrowth_Com = 0.040`

### Email-to-workbook setup

The expert email is handled in two layers:

1. **Structured extraction layer**
	 - Email-derived annual rooftop split data is stored in:
		 - `ExcelFiles/Output/RTS_split_assumptions_from_expert_email.csv`

2. **Workbook assumptions layer**
	 - Scenario workbook used by maintenance scripts:
		 - `ExcelFiles/Vietnam_EnergyExpert_ScenarioInputs.xlsx`
	 - Harmonized copy from the CSV:
		 - `ExcelFiles/Vietnam_EnergyExpert_ScenarioInputs_harmonized.xlsx`

Harmonization mapping for sheet `PDP8_revised`:
- `RTS_Capacity_GW = cap_total_MW / 1000`
- `RTS_Generation_TWh = gen_total_GWh / 1000`
- `Office_RTS_Penetration_pct (2030) = 50`
- `Residential_RTS_Penetration_pct (2030) = 50`

For details, see:
- `docs/expert_email_workbook_harmonization.md`

---

## Computation

### Step 1 — Projected sectoral demand

$$D_t^s = D_0^s \cdot (1 + g^s)^{t}$$

where $t = 0$ corresponds to 2025 and $g^s = 0.04$.

### Step 2 — PV coverage fraction

$$\varphi_t^s = \min\!\left(\frac{\text{gen}_{PV,t}^s}{D_t^s},\; 0.9999\right)$$

PV generation displaces grid-supplied energy, effectively raising the productivity of the energy-intermediate input by $1/(1 - \varphi_t)$.

### Step 3 — Incremental log-productivity boost

The base-year coverage $\varphi_0$ is already embedded in the steady-state calibration. The **incremental** contribution relative to 2025 is:

$$\Delta A^{I,s}_{t} = \ln\!\left(\frac{1 - \varphi_0^s}{1 - \varphi_t^s}\right)$$

This is added to any pre-existing path in `exo_AI_s_1_2`.

---

## Milestone Values

### Industrial sector (subsector 4, `exo_AI_4_1_2`)

| Year | D (GWh) | gen_PV (GWh) | φ (%) | ΔAI (log-pts) |
|:--|--:|--:|--:|--:|
| 2025 | 177,550 | 17,300 | 9.7 | 0.000 |
| 2030 | 216,076 | 23,361 | 10.8 | +0.012 |
| 2040 | 319,837 | 42,598 | 13.3 | +0.040 |
| 2050 | 473,181 | 77,676 | 16.4 | +0.077 |

### Commercial / services sector (subsector 5, `exo_AI_5_1_2`)

| Year | D (GWh) | gen_PV (GWh) | φ (%) | ΔAI (log-pts) |
|:--|--:|--:|--:|--:|
| 2025 | 56,950 | 4,391 | 7.7 | 0.000 |
| 2030 | 69,288 | 6,440 | 9.3 | +0.017 |
| 2040 | 102,583 | 13,848 | 13.5 | +0.065 |
| 2050 | 151,839 | 29,778 | 19.6 | +0.138 |

The commercial sector shows larger gains by 2050 because its demand base is smaller relative to the PV capacity assigned to it.

---

## Code Entry Points

Call order in `write_growth_rates_to_baseline`:

1. `write_generic_optional_paths` — user-provided paths from `ScenarioPathDefinition.xlsx`
2. `apply_government_rts_sector_pv_shocks` — writes `exo_GA_s_1` and `exo_PV_1` from PV capacity indices
3. `apply_industrial_pv_to_ee_coupling` — adds PV gen/demand increment to `exo_AI_s_1_2`
4. `apply_vneep3_ee_targets` — adds VNEEP3 non-PV increments to **both** `exo_AI_s_1_2` and `exo_GA_s_1`

| Function | File | Role |
|:--|:--|:--|
| `apply_government_rts_sector_pv_shocks` | `create_baseline_from_user_input_file.m` | `exo_GA_s_1` (PV costs) + `exo_PV_1` residential |
| `apply_industrial_pv_to_ee_coupling` | `create_baseline_from_user_input_file.m` | `exo_AI_s_1_2` += PV gen/demand fractions |
| `apply_vneep3_ee_targets` | `create_baseline_from_user_input_file.m` | `exo_AI_s_1_2` += VNEEP3 non-PV log-rate path; `exo_GA_s_1` += EE investment cost ramp |
| `read_vietnam_rts_sector_plan` | `create_baseline_from_user_input_file.m` | Reads RTS CSV; returns capacity indices and gen data |
| `get_scalar_field` | `create_baseline_from_user_input_file.m` | Helper: read scalar from struct with default fallback |

---

## Expert-Calibrated EE Scenarios

Source: `ExcelFiles/Vietnam_EnergyExpert_ScenarioInputs.xlsx` (Nguyen Hoang Lan, HUST, May 2026).  
Script: `scripts/maintenance/create_ee_scenarios_from_expert_inputs.m` — writes to `ModelScenarios5Sectorsand1Regions.xlsx`.

### Scenario definitions

| Sheet (expert) | Model sheet | Policy | Industry save 2030 | Services save 2030 | Industry save 2050 | Services save 2050 |
|:--|:--|:--|--:|--:|--:|--:|
| `EE_PDP8_reference` | `EE_PDP8` | No additional carbon policy | 3.0% | 2.0% | 4.5% | 3.2% |
| `Directive10_RTS_EE` | `EE_Directive10` | PM Directive 10/CT-TTg | 7.4% | 5.1% | 10.0% | 7.0% |

### Translation formulas

**`exo_AI_s_1_2(t)`** (energy-intermediate productivity increment):
$$\Delta AI_t = \ln\!\left(\frac{1}{1 - \text{saving\_pct}_t / 100}\right)$$
added to the existing Baseline `exo_AI_s_1_2` (PV contribution).

**`exo_GA_s_1(t)`** (adaptation-capital K_A stock as share of GDP):
$$K_A^{EE}(t) = (1 - \delta_{KA}) \cdot K_A^{EE}(t-1) + \frac{I_t^{EE}}{Y_0}$$
with $\delta_{KA} = 0.10$ and $Y_0 = \$430{,}000$ M (Vietnam 2025 GDP). Added to Baseline GA path.

**`exo_lAddEE_4_1` / `exo_lAddEE_5_1`**: written as `1` (additive mode) in all scenario sheets.

### Implied log-productivity milestones (scenario only, above Baseline PV)

| | 2030 | 2040 | 2050 |
|:--|--:|--:|--:|
| `EE_PDP8` industry | +0.030 | +0.038 | +0.046 |
| `EE_PDP8` commercial | +0.020 | +0.025 | +0.033 |
| `EE_Directive10` industry | +0.077 | +0.089 | +0.105 |
| `EE_Directive10` commercial | +0.052 | +0.063 | +0.074 |

---

## Key Assumptions and Caveats

- **Demand-side**: Growth at 4% p.a. from the PDP8 reference level is an external assumption. If the model's own sectoral GDP growth differs substantially, coverage fractions will diverge.
- **Commercial split**: 30% of household PV generation attributed to commercial sites. This can be overridden via `RTSCommercialShareOfHousehold`.
- **No capacity factor adjustment**: Generation data in the CSV already reflects assumed capacity factors (approximately 1,300–1,400 full-load hours/year for Vietnam).
- **Base-year absorption**: φ_0 (2025 PV coverage ≈ 9.7% industrial, 7.7% commercial) is assumed to be embedded in the calibrated steady state. Only incremental gains relative to 2025 are written as `exo_AI`.
- **Upper bound**: Coverage fractions are clipped at 0.9999 to prevent numerical issues in the log formula.
- **VNEEP3 decomposition**: The tables above show PV as one quantified sub-channel. Non-PV VNEEP3 measures (motor efficiency, building insulation, management systems) can be added to `exo_AI_s_1_2` as an additional constant or linearly interpolated increment toward the remaining sectoral target.
- **Aggregate vs. sector-specific**: `exo_EE_1` captures the weighted-average VNEEP3 path and affects all sectors simultaneously. `exo_AI_s_1_2` adds a sector-specific layer on top. Avoid double-counting: if a sector-level measure is already reflected in the aggregate `exo_EE_1` calibration, it should not be added again in `exo_AI`.
