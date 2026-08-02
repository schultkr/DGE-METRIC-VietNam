# Energy Reserve Inputs: Data Requirements for DGE-METRIC Integration

> **Status: proposed model extension, not implemented.** `Q_2_aug_r`,
> `exo_supply_shock_r`, and the strategic-reserve mechanism described below do
> not exist in `ModFiles/` today. This is a data-requirements spec for future
> work, paired with [energy_reserve_breakeven.md](energy_reserve_breakeven.md).

**Scope:** All parameters, calibration data, and scenario paths needed to model strategic reserves and
storage for oil, coal, gas, and BESS within the DGE-METRIC framework.  
**Key principle:** GDP loss from a supply disruption is a **model result**, not a calibration input. It
emerges from the CES production chain when augmented fossil supply `Q_2_aug_r` falls short of what
firms demand at `Q_I_{subsec}_{reg}_{SecEnergy}`. The inputs listed here shape the shock, the buffer,
and the cost — not the output.

---

## 1. Supply Disruption Shocks

These drive the gap that reserves must fill. They enter as `exo_supply_shock_r`, which scales
`Q_{SubsecFossil}_{reg}` (the fossil energy sector output) downward during a crisis period.

### 1.1 Crisis Frequency and Magnitude

| Input | Symbol | Unit | Vietnam baseline | Source needed |
|---|---|---|---|---|
| Annual probability of a major disruption | `p_crisis` | events/year | 0.04 (once per 25 years) | Historical shipping disruption data, Malacca Strait chokepoint studies |
| Minimum crisis magnitude | `shock_min` | fraction of annual fossil supply lost | 0.20 | IEA supply disruption database |
| Maximum crisis magnitude | `shock_max` | fraction of annual fossil supply lost | 0.50 | IEA supply disruption database |
| Mean crisis duration | `dur_mean` | years | 2.0 (geometric with p_end=0.5) | Historical episode length |
| Probability crisis ends each year | `p_end` | — | 0.50 | Historical episode data |
| **Carrier-specific disruption independence** | — | — | Not yet modeled | Whether oil/coal/gas shocks co-move (e.g. Malacca blockage hits all three simultaneously) |

**Critical gap:** Currently `exo_supply_shock_r` is a single aggregate shock. Each carrier (oil, coal,
gas) needs its own disruption probability and magnitude because:
- Oil: maritime (Malacca), pipeline political risk
- Coal: domestic mining strikes (Quảng Ninh), import port congestion
- Gas: LNG spot-market failure, pipeline geopolitics

### 1.2 Shock Correlation Structure

| Input | Symbol | Vietnam context |
|---|---|---|
| Oil–gas disruption correlation | `rho_shock_oil_gas` | Both LNG and oil tankers pass Malacca → high positive correlation (~0.6) |
| Oil–coal disruption correlation | `rho_shock_oil_coal` | Partially independent; domestic coal reduces co-movement (~0.2) |
| Gas–coal disruption correlation | `rho_shock_gas_coal` | Low if coal is domestic; high if both imported (~0.1–0.4) |

**Why this matters for reserve sizing:** If shocks are correlated, simultaneous drawdown from multiple
reserves depletes all stocks at once. Independent sizing (as in current ToyModel) understates the
worst-case scenario by treating each crisis as isolated.

---

## 2. Reserve Stock Parameters — by Energy Carrier

### 2.1 Parameters Common to All Fossil Carriers

These appear in the reserve law of motion:

```
R_c = (1 - deltaR_c) * R_c(-1) - R_draw_c
    + deltaR_c * Rbar_c
    + gammaR_c * max(0, Rbar_c - R_c(-1))
```

| Parameter | Symbol | Applies to | Value needed |
|---|---|---|---|
| Physical loss rate (annual) | `deltaR_c` | Carrier-specific | See Section 3 |
| Reserve refill speed | `gammaR_c` | Carrier-specific | See Section 3 |
| Reserve target (starting point) | `Rbar_c` | Carrier-specific | IEA 90-day = `(90/365)*ED_c_bar` |
| Policy drawdown fraction | `phiR_c` | Carrier-specific | 0.50 baseline; varies in MC |
| Baseline annual supply flow | `ED_c_bar` | Carrier-specific | From energy balance data |

### 2.2 Oil / Petroleum

| Input | Symbol | Unit | Vietnam value | Source |
|---|---|---|---|---|
| Annual oil/petroleum import baseline | `ED_oil_bar` | share of GDP (normalized) | 0.30 (40% of dirty energy) | IEA Vietnam energy balance 2023 |
| IEA 90-day reserve target | `Rbar_oil` | share of GDP | `(90/365)*ED_oil_bar ≈ 0.074` | IEA Net Importer obligation |
| **Above-ground tank capacity ceiling** | `Rbar_oil_max` | million barrels | ~4–5 Mb (Nghi Son, Dung Quat) | MOIT Vietnam capacity data |
| **Crude vs. refined product split** | `omega_crude` | fraction of SPR held as crude | ~0.7 (crude dominant) | MOIT Strategic Reserve reports |
| Physical loss rate (evaporation, leakage) | `deltaR_oil` | fraction/year | 0.02 | IEA storage loss estimates |
| Refill speed after drawdown | `gammaR_oil` | fraction of gap/year | 0.25 (~4 years to refill from zero) | Expert judgment, port capacity |
| Refinery throughput capacity | `Q_oil_bar` | fraction of annual flow processable/year | Calibrated from Nghi Son + Dung Quat nameplate | MOIT PDP8 |

**Effective usage constraint (critical):** Even if crude reserves exist, they produce fuel only at the
speed the refinery can process them. See Section 4.

### 2.3 Coal

| Input | Symbol | Unit | Vietnam value | Source |
|---|---|---|---|---|
| Annual coal import baseline | `ED_coal_bar` | share of GDP | 0.45 (60% of dirty energy) | IEA Vietnam 2023 |
| Domestic vs. imported coal split | `omega_domestic_coal` | fraction from domestic mines | ~0.55 (Quảng Ninh basin) | VINACOMIN annual report |
| Reserve target | `Rbar_coal` | share of GDP | `(90/365)*ED_coal_bar ≈ 0.111` | IEA guideline |
| **Stockyard capacity ceiling** | `Rbar_coal_max` | Mt | ~8–12 Mt total (ports + plant stockyards) | EVN, PetroVietnam data |
| Physical loss rate (degradation, spontaneous combustion) | `deltaR_coal` | fraction/year | 0.03–0.05 (higher than oil; open-air storage) | Literature (ASTM, mine studies) |
| Calorific value decay beyond 6 months | `decay_coal` | fraction of energy content/year | 0.02–0.04 | Coal storage studies |
| Refill speed | `gammaR_coal` | fraction of gap/year | 0.30 (faster than oil; domestic trucking) | Expert judgment |
| Coal-fired plant ramp-up lag | `Q_coal_bar` | fraction of annual demand dispatchable/month | Calibrated from EVN fleet capacity factors | EVN System Operations |

**Key difference from oil:** Domestic coal (Quảng Ninh) means supply disruption probability for
coal is lower than for oil; the crisis scenario is a mine strike or flooding, not a shipping blockage.
Parameterize `p_crisis_coal` separately from `p_crisis_oil`.

### 2.4 Gas / LNG

| Input | Symbol | Unit | Vietnam value | Source |
|---|---|---|---|---|
| Annual gas import baseline | `ED_gas_bar` | share of GDP | ~0.15 (growing; currently ~12% of primary energy) | IEA Vietnam 2023 |
| **LNG vs. pipeline split** | `omega_LNG` | fraction of gas supply as LNG | ~0.30 now, rising to ~0.70 by 2035 | PDP8 gas capacity plan |
| Reserve target | `Rbar_gas` | share of GDP | `(90/365)*ED_gas_bar` | IEA guideline |
| **Underground storage capacity** | `Rbar_gas_max` | bcm | Near zero currently (no depleted-field storage) | MOIT; major constraint |
| **LNG tank storage** | `K_LNG_tank` | days of sendout | ~7–14 days at existing terminals | PV GAS terminal data |
| Physical loss rate (LNG boil-off) | `deltaR_gas` | fraction/day × 365 | 0.05%/day boil-off → ~18%/year effective | LNG storage engineering norms |
| Regasification capacity | `Q_gas_bar` | fraction of annual demand processable/year | Calibrated from Thi Vai + Son My terminal capacity | PDP8 LNG terminal plan |
| Gas price volatility | `sigma_nu_gas` | annual standard deviation | 0.40–0.60 (JKM LNG spot price) | S&P Global Platts historical |
| Price shock persistence | `rho_p_gas` | AR(1) coefficient | 0.55–0.65 | IEA Gas Market report |
| Refill speed | `gammaR_gas` | fraction of gap/year | 0.40 (fast; LNG can be procured on spot market) | Expert judgment |

**Critical structural note for gas:** The boil-off rate (~0.05%/day) means gas cannot be stockpiled
for months the way oil can. Effective storage is days to weeks, not the 90-day standard. The LNG
tank capacity `K_LNG_tank` is the binding constraint, not `Rbar_gas`. This requires a **different
reserve equation** for gas — a short-term buffer constraint rather than a strategic stock.

---

## 3. Storage Costs by Energy Carrier

Storage costs enter the resource constraint as a flow deduction from GDP each period:

```
StorageCost_r = sum_c [ kappa1_c * R_c(-1) + kappa2_c * R_c(-1)^2 ]
              + StorageCost_BESS_r
```

The cost parameters are **carrier-specific** — the current single shared `kappa1`, `kappa2` in
ToyModelSOEMC is an approximation that should be disaggregated in DGE-METRIC.

### 3.1 Oil Storage Costs

| Cost component | Parameter | Formula | Vietnam calibration |
|---|---|---|---|
| Linear: physical loss replacement | `kappa1_oil` | `deltaR_oil * P_oil_bar` | `0.02 * 1.0 = 0.020` |
| Quadratic: infrastructure + insurance | `kappa2_oil` | Calibrated so MC at 90-day = 2× linear cost | `0.12` |
| **Incremental above-ground tank CAPEX** | `kappa_capex_oil` | USD/barrel/year annualized | ~$4–6/bbl/year (Vietnam: constrained site availability) | MOIT terminal cost data |
| Port and pumping OPEX | `kappa_opex_oil` | USD/barrel/year | ~$1–2/bbl/year | Industry benchmarks |

**Why the quadratic term:** Vietnam has limited above-ground tank capacity at existing refinery sites
(Nghi Son, Dung Quat, Vung Tau). Building beyond current capacity requires new sites — sharply rising
land and construction costs. `kappa2_oil` captures this non-linearity.

**Data needed:** MOIT strategic petroleum reserve feasibility studies; port authority land acquisition
cost curves for tank expansion at Cat Lai, Ba Ria.

### 3.2 Coal Storage Costs

| Cost component | Parameter | Formula | Vietnam calibration |
|---|---|---|---|
| Linear: degradation replacement | `kappa1_coal` | `deltaR_coal * P_coal_bar` | `0.035 * 1.0 = 0.035` (higher than oil) |
| Quadratic: land + handling equipment | `kappa2_coal` | Calibrated to port stockyard expansion cost | `0.08` (lower than oil; open-air cheaper per tonne) |
| Quality degradation penalty | `kappa_degrade_coal` | Lost calorific value × energy price | ~2–4% energy content/year beyond 6 months | ASTM coal storage standards |
| Spontaneous combustion risk premium | `kappa_fire_coal` | Insurance + mitigation cost | ~0.5–1.0% of stock value/year | Insurance industry data |

**Key difference from oil:** Coal storage is cheaper per unit volume but has higher physical
degradation. The quadratic term is lower (`kappa2_coal < kappa2_oil`) but the linear loss rate is
higher (`deltaR_coal > deltaR_oil`). Optimal coal reserve will be smaller relative to daily demand
than the oil reserve.

**Data needed:** Quảng Ninh and Hai Phong port authority stockyard capacity and expansion cost per
additional million tonnes; EVN coal plant stockyard specifications.

### 3.3 Gas / LNG Storage Costs

Gas storage costs are structurally different from solid/liquid fossil fuels:

| Cost component | Parameter | Formula | Vietnam calibration |
|---|---|---|---|
| Boil-off loss (ongoing, unavoidable) | `kappa1_gas` | `deltaR_gas * P_gas_bar` | `0.18 * P_LNG = 0.18` (much higher than oil/coal) |
| LNG tank CAPEX (annualized) | `kappa_capex_gas` | USD/MMBtu/year | ~$0.3–0.6/MMBtu/year (cryogenic tanks very expensive) | PV GAS project data |
| Regasification OPEX | `kappa_opex_gas` | USD/MMBtu | ~$0.15–0.25/MMBtu | PV GAS terminal operating costs |
| Spot procurement premium during crisis | `kappa_premium_gas` | markup on JKM price during disruption | 1.5–3.0× spot price (LNG market is thin; crisis buying is expensive) | IEA LNG market report |
| Underground storage CAPEX (if built) | `kappa_UGS` | USD/MMBtu/year | ~$0.8–1.5 for depleted-field conversion | IEA UGS cost survey |

**Critical:** Because LNG boil-off rates are ~18× higher than oil evaporation, long-term LNG
stockpiling is uneconomic. Vietnam's realistic gas reserve is the **regasification terminal pipeline
pack** (days of sendout), not months. The 90-day IEA standard cannot be applied to LNG without
dedicated underground storage that Vietnam does not yet have.

**Implication for model:** `Rbar_gas` should be capped at `K_LNG_tank` (days × daily demand), not
the IEA 90-day formula. The optimal gas reserve is largely determined by terminal sizing, not a
policy choice.

**Data needed:** PV GAS annual reports; Son My LNG terminal specs (2027 commissioning); Thi Vai
terminal current sendout capacity.

### 3.4 BESS Storage Costs

BESS costs are fundamentally different: they are **capital costs per unit of energy capacity**
(USD/kWh), not flow storage costs. The relevant cost equation is:

```
BESS_CostFlow_r = (annualized_CAPEX_BESS + OPEX_BESS) * K_BESS_r
                + efficiency_loss_cost_r
```

where `efficiency_loss_cost_r = (1 - etaBESS) * P_elec * Q_BESS_charged_r` (cost of electricity
lost each cycle).

| Cost component | Parameter | Unit | 2025 value | 2030 projection | Source |
|---|---|---|---|---|---|
| BESS CAPEX (utility-scale Li-ion) | `capex_BESS` | USD/kWh installed | $200–250/kWh | $130–160/kWh | BNEF 2024 LCOES |
| Annual fixed OPEX | `opex_BESS_fixed` | USD/kWh/year | $8–12/kWh/year | $6–9/kWh/year | BNEF, NREL |
| Annualization factor (15-year lifetime) | `annuity_BESS` | fraction/year | 0.087 at 5% discount | — | Standard annuity formula |
| **Annualized CAPEX per kWh** | `kappa_capex_BESS` | USD/kWh/year | `$200 × 0.087 = $17.4/kWh/year` | `$145 × 0.087 = $12.6` | Derived |
| Round-trip efficiency loss | `1 - etaBESS` | fraction per cycle | 0.10–0.15 (85–90% RTE) | 0.08–0.12 | NREL ATB 2024 |
| **Cycle degradation rate** | `deltaBESS_cycle` | capacity loss per full cycle | 0.02–0.05% per cycle | — | Battery manufacturer specs |
| **Annual capacity fade** | `deltaBESS_p` | fraction/year (≈ cycles/year × per-cycle fade) | 0.03–0.05 at 1 cycle/day | — | Derived from cycle data |
| Replacement cost at end-of-life | `capex_BESS_replace` | USD/kWh | Same as capex but at future prices | Falling ~8%/year | BNEF |

**BESS cost trend matters for optimal sizing:** Unlike fossil reserve costs which are relatively
stable, BESS costs fall ~8–15%/year. The optimal BESS capacity in 2030 is larger than in 2025
even holding grid stress constant. The scenario path `exo_capex_BESS_r` should reflect this decline.

**Data needed:** EVN battery storage procurement bids (2023–2025); BNEF Vietnam LCOES update;
Dong Nai and Ninh Thuan BESS pilot project cost data.

---

## 4. Effective Usage in Crisis: Capacity Constraints

This is the mechanism that links reserve stock to actual crisis relief. A reserve that exists but
cannot be deployed fast enough provides less insurance than its nominal size implies.

### 4.1 The General Mechanism

In DGE-METRIC, the augmented fossil supply available to firms is:

```
Q_2_aug_r = Q_2_disrupted_r
           + min(R_draw_oil_r,  alpha_oil_bar  * Q_oil_refine_r)
           + min(R_draw_coal_r, alpha_coal_bar * Q_coal_plant_r)
           + min(R_draw_gas_r,  alpha_gas_bar  * Q_gas_regas_r)
           + etaBESS * min(Q_BESS_r, K_BESS_r * CRate_BESS)
```

The `min(...)` terms enforce **throughput capacity constraints**: you can only release as much
reserve as the downstream infrastructure can process in a given period.

### 4.2 Oil: Refinery Throughput Constraint

| Input | Symbol | Unit | Vietnam value | Source |
|---|---|---|---|---|
| Refinery nameplate capacity | `Q_oil_refine_bar` | million barrels/year | ~145,000 bbl/day = 53 Mb/year (Nghi Son 200,000 + Dung Quat 148,000 bpd) | MOIT |
| Operating utilization rate at baseline | `u_refine_SS` | fraction | ~0.75–0.85 (historical average) | PetroVietnam reports |
| **Maximum crisis utilization** | `u_refine_max` | fraction | ~0.95 (technical ceiling) | Engineering constraint |
| **Maximum crisis dispatch fraction** | `alpha_oil_bar` | fraction of annual supply processable in one crisis quarter | `u_refine_max * Q_oil_refine_bar / ED_oil_bar` | Derived |
| Refinery-to-demand lag | `lag_refine` | months from crude release to fuel available | 1–2 months | Refinery logistics |
| Fraction of SPR held as crude vs. products | `omega_crude_SPR` | — | ~0.70 crude | MOIT SPR composition |

**Key implication:** If Vietnam's SPR holds crude but refineries are running at 85% utilization,
only 10–15% of additional capacity is available for emergency processing. A large nominal reserve
delivers much less than 90 days of supply coverage in practice.

**Data needed:** Nghi Son and Dung Quat refinery capacity utilization (monthly, 2020–2024); current
product storage at refineries; throughput ramp-up time.

### 4.3 Coal: Rail/Port Unloading and Plant Stockyard Constraint

| Input | Symbol | Unit | Vietnam value | Source |
|---|---|---|---|---|
| Coal port unloading capacity | `Q_coal_port_bar` | Mt/year | ~50 Mt/year (Cai Lan, Vung Ang, Duyen Hai ports) | Vietnam Ports Authority |
| Plant on-site stockyard capacity | `K_coal_plant` | days of plant operation | 15–30 days (varies by plant) | EVN plant specs |
| **Maximum drawdown dispatch rate** | `alpha_coal_bar` | fraction of annual demand releasable per crisis quarter | `min(port_capacity, plant_stockyard) / ED_coal_bar` | Derived |
| Rail bottleneck (north–south coal transport) | `cap_rail_coal` | Mt/year | ~20 Mt/year (Hanoi–HCMC corridor) | Ministry of Transport |
| Emergency truck transport cost premium | `kappa_truck_coal` | USD/tonne markup vs. rail | ~$8–12/tonne | Logistics industry |

**Key implication:** Northern power plants (near Quảng Ninh domestic coal) face fewer bottlenecks
than southern plants that depend on imports. A national-level `alpha_coal_bar` masks significant
regional heterogeneity. If DGE-METRIC is extended to multiple regions, north/south split matters here.

**Data needed:** EVN plant-level stockyard capacities and current days-on-hand; port authority
throughput data; Quảng Ninh colliery production ramp-up speed.

### 4.4 Gas: Regasification Capacity Constraint

This is the binding constraint for Vietnam's gas reserve — not the nominal stock but the rate at which
LNG can be converted to pipeline gas.

| Input | Symbol | Unit | Vietnam value (2025) | 2030 (PDP8) | Source |
|---|---|---|---|---|---|
| Existing regas capacity | `Q_gas_regas_bar` | Bcm/year | ~1.0 Bcm/year (Thi Vai terminal) | ~5–6 Bcm/year (Son My + expansions) | PDP8 LNG plan |
| Peak sendout rate | `alpha_gas_bar` | fraction of annual gas demand serveable from regas/year | `Q_gas_regas_bar / ED_gas_bar` | Rising sharply with PDP8 | Derived |
| LNG tank buffer (days sendout at max rate) | `K_LNG_days` | days | ~7–10 days | 15–20 days | PV GAS terminal specs |
| Regasification-to-grid latency | `lag_regas` | hours | 4–8 hours (operational) | Same | Engineering |
| **Emergency spot LNG procurement time** | `lag_spot_LNG` | weeks | 4–8 weeks (spot cargo delivery) | 3–6 weeks | LNG shipping market |

**Key implication:** Vietnam's regasification capacity is the dominant constraint on gas crisis
response, not LNG tank volume. Even if spare LNG cargoes could be procured on the spot market
(4–8 weeks delivery), there is no way to process them faster than terminal capacity allows.
The effective gas reserve is mostly the LNG already loaded in tanks waiting to be gasified.

**Data needed:** Thi Vai terminal current utilization; Son My terminal commissioning schedule;
PTSC and PV GAS regasification capacity contracts.

### 4.5 BESS: Discharge Rate (C-Rate) and Depth-of-Discharge Constraints

BESS crisis usage is constrained by physics, not infrastructure:

| Input | Symbol | Unit | Typical utility BESS | Source |
|---|---|---|---|---|
| C-rate (discharge power relative to capacity) | `CRate_BESS` | kW per kWh installed | 0.25–0.50 (2–4 hour systems) | NREL, manufacturer specs |
| **Maximum discharge duration at full power** | `duration_BESS` | hours | `1/CRate = 2–4 hours` | Derived |
| Minimum state of charge (DoD limit) | `SoC_min` | fraction of capacity | 0.10–0.20 | Battery protection spec |
| **Effective usable fraction** | `DoD_eff` | fraction of nameplate capacity | `1 - SoC_min = 0.80–0.90` | Derived |
| Grid connection bottleneck | `P_grid_BESS` | MW injection limit | Varies by substation; often binding for large BESS | EVN grid code |
| Charge replenishment time after full dispatch | `T_recharge_BESS` | hours | 4–8 hours (same C-rate) | Operational constraint |

**Key implication for model:** BESS covers **grid frequency and short-duration shortfalls**
(minutes to hours), not the multi-month energy supply disruptions that oil/coal/gas reserves address.
A 4-hour BESS cannot substitute for oil reserves during a shipping blockage. This means:

1. BESS and fossil reserves answer **different risk questions** and should not be aggregated into
   a single `Q_2_aug_r` without time-scale separation.
2. In the annual DGE-METRIC model, BESS value is best captured as a **grid reliability premium**
   on energy sector TFP (`A_{SubsecFossil}_r`) — BESS prevents brownouts that reduce productive
   utilization of power plants — rather than as a direct supply buffer.
3. Alternatively: model BESS dispatch as reducing the **peak shortage** within a crisis year,
   even if it cannot cover the full annual shortfall. This requires a within-year distribution
   assumption about when shortages occur.

**Data needed:** EVN BESS tender specifications (MW, MWh, C-rate); grid frequency deviation
statistics (seconds per year out of band); BESS dispatch event logs from pilot projects.

---

## 5. Cross-Carrier Substitution

When one carrier's supply is disrupted, can firms substitute toward others? This is controlled by
`etaIA_{subsec}_p` (elasticity of substitution between intermediates from different sectors) in
`firms.mod`. Currently set to **0.10** — nearly Leontief (near-zero substitution).

| Input | Symbol | Current value | Realistic range | Implications |
|---|---|---|---|---|
| Short-run coal–gas substitution | `etaIA_ss_p` | 0.10 | 0.05–0.30 | Gas-fired plants can partially replace coal-fired output if gas is available |
| Short-run oil–electricity substitution | `etaIA_oil_elec_p` | 0.10 | 0.02–0.15 | Transport sector: nearly zero short-run substitution |
| Long-run elasticity | `etaIA_lr_p` | Not distinguished | 0.50–1.50 | Capital retooling takes years |
| **Dedicated oil–gas substitution in power** | New parameter | Not modeled | ~0.25–0.45 | Vietnam dual-fuel plants can switch |

**Data needed:** Vietnam's dual-fuel power plant fleet (MW capacity able to switch); observed
fuel-switching behavior during 2021 electricity shortage; IEA Vietnam energy flexibility assessment.

---

## 6. Steady-State Calibration Targets

These are the observable quantities the model must match at the base year (2024):

| Target | Observable | Vietnam 2024 value | Data source |
|---|---|---|---|
| Oil reserve days of coverage | `Rbar_oil / (ED_oil_bar/365)` | 30–45 days (current); 90-day IEA target | MOIT strategic reserve report |
| Coal reserve days of coverage | `Rbar_coal / (ED_coal_bar/365)` | 15–20 days (plant stockyards) | EVN operational data |
| Gas reserve days of coverage | `Rbar_gas / (ED_gas_bar/365)` | 7–10 days (LNG tanks only) | PV GAS terminal reports |
| BESS installed capacity | `K_BESS_r` (in MWh → normalized to GDP share) | ~100 MWh (pilots); PDP8 target: 6,000–9,000 MW by 2030 | EVN, MOIT PDP8 |
| Investment/GDP share for BESS | `I_BESS_r / Y_r` | ~0.1% of GDP (2025); rising to ~0.8% by 2030 | PDP8 investment plan |
| Oil storage cost / GDP | `StorageCost_oil / Y` | ~0.05–0.10% of GDP | Derived from MOIT + IEA data |
| Coal storage cost / GDP | `StorageCost_coal / Y` | ~0.03–0.07% of GDP | Derived from EVN + port data |

---

## 7. Scenario Path Variables

These go into the Excel scenario workbooks (`ModelScenarios5Sectorsand1Regions.xlsx`),
following the same pattern as existing `exo_*` variables.

| Variable name | Type | Description |
|---|---|---|
| `exo_supply_shock_oil_r` | Shock path | Fossil supply disruption for oil carrier (negative = crisis) |
| `exo_supply_shock_coal_r` | Shock path | Coal supply disruption |
| `exo_supply_shock_gas_r` | Shock path | Gas/LNG supply disruption |
| `exo_Rbar_oil_r` | Policy path | Target oil reserve level (IEA 90-day, 60-day, optimal) |
| `exo_Rbar_coal_r` | Policy path | Target coal reserve level |
| `exo_Rbar_gas_r` | Policy path | Target gas reserve level (bounded by LNG tank capacity) |
| `exo_BESS_r` | Investment path | BESS capacity deployment (MWh → normalized) |
| `exo_capex_BESS_r` | Cost path | BESS capital cost trajectory (declining ~8–15%/year) |
| `exo_alpha_oil_r` | Constraint path | Refinery dispatch fraction (rises as new capacity built) |
| `exo_alpha_gas_r` | Constraint path | Regasification dispatch fraction (rises with PDP8 terminal commissioning) |
| `exo_CRate_BESS_r` | Technology path | BESS discharge rate (technology improvement) |

---

## 8. Summary: What Is and Is Not an Input

| Item | Status | Why |
|---|---|---|
| GDP loss from energy shortage | **Model output** | Computed by CES production chain when `Q_2_aug_r` falls |
| Optimal reserve level `Rbar_c*` | **Model output** | Emerges from Monte Carlo benefit–cost search across `Rbar_c` |
| Crisis frequency `p_crisis_c` | **Input** | Calibrated from historical disruption data |
| Crisis magnitude distribution | **Input** | Calibrated from IEA supply disruption database |
| Physical loss rates `deltaR_c` | **Input** | Carrier-specific; calibrated from engineering data |
| Storage cost parameters `kappa1_c`, `kappa2_c` | **Input** | Carrier-specific; calibrated from infrastructure cost data |
| Throughput capacity ceilings `alpha_c_bar` | **Input** | Calibrated from refinery/port/terminal capacity data |
| BESS C-rate, DoD limits | **Input** | From battery engineering specifications |
| BESS capital cost path | **Input** | From BNEF/NREL cost projections |
| Cross-carrier substitution `etaIA` | **Input (calibrate)** | Currently 0.10; should be carrier-pair specific |
| Shock correlation `rho_shock` | **Input** | From historical co-occurrence of disruptions |
