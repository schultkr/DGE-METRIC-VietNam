# Energy Reserve Break-Even Analysis
## Required Avoided GDP/Consumption Loss to Justify Storage Costs
### Vietnam 2024/2030 — Data: *Data for DGE-METRIC.xlsx*

> **Status: proposed model extension, not implemented.** This is a cost-benefit
> analysis supporting a strategic-reserve feature that does not yet exist in
> the model — see [energy_reserve_inputs.md](energy_reserve_inputs.md) for the
> companion data-requirements spec. Do not cite as a current model result.

---

## Framework

The simple optimality condition is **MC = MB**:

```
Annual storage cost  =  p_crisis  ×  Avoided GDP loss (conditional on crisis)
```

Rearranging gives the **break-even avoided GDP loss** — the minimum GDP loss a crisis must
cause (when it occurs) to justify maintaining the reserve:

```
Break-even avoided GDP loss (% of GDP) = Annual storage cost / (p_crisis × GDP)
```

GDP loss from a disruption is a **model output** — it is computed endogenously by the CES
production chain in DGE-METRIC when augmented energy supply `Q_2_aug_r` falls short of firm
demand. The break-even threshold is what that model output must exceed for the reserve to
pass the cost-benefit test.

### Parameters

| Parameter | Value | Source |
|---|---|---|
| Vietnam GDP 2024 | USD 430,000m (USD 430bn) | IMF WEO 2024 |
| Private consumption / GDP (`C/Y`) | 0.67 | World Bank Vietnam 2023 |
| Annual crisis probability `p_crisis` | 0.04 (once per 25 years) | IEA supply disruption database; ToyModel calibration |
| Infrastructure CRF (oil/gas/LNG) | 0.0897 (25-yr asset life, 7.5% SOE discount rate) | Standard annuity; matches PSHP sheet parameters |
| PSHP CRF | 0.0847 (30-yr, 7.5%) | Sheet: Inputs_Coal-BESS-PHS |
| BESS CRF | 0.1204 (15-yr, 8.5%) | Sheet: Inputs_Coal-BESS-PHS |
| **Break-even divisor** | **172.0 USD m per 1% of GDP** | `= p × GDP/100 = 0.04 × 4,300` |
| **Break-even divisor (consumption)** | **115.2 USD m per 1% of C** | `= p × GDP × C/Y / 100` |

> **Annualised cost formula (oil/gas):** `Annual cost = CAPEX × CRF + OPEX`  
> Coal costs are taken directly from the sheet (include storage, maintenance, and financing/carry).

---

## Table 1 — Crude Oil Strategic Petroleum Reserve

**Consumption basis:** Vietnam net oil imports ≈ 12 Mt/yr (crude 5 Mt + products 7 Mt) → 32.9 KT/day  
1 MTA ≈ 30 days net-import coverage (IEA SPR standard)

| Coverage | Volume | CAPEX | OPEX | **Annual cost** | Cost % GDP | **BE: avoided GDP loss** | **BE: avoided C loss** | MC per day |
|---|---|---|---|---|---|---|---|---|
| 30 days | 1,000 KT | USD 300m | USD 3.5m/yr | **USD 30.4m/yr** | 0.007% | **0.177%** | **0.264%** | USD 1.01m/day |
| 61 days | 2,000 KT | USD 600m | USD 7.0m/yr | **USD 60.8m/yr** | 0.014% | **0.354%** | **0.528%** | USD 1.00m/day |
| 91 days | 3,000 KT | USD 900m | USD 10.5m/yr | **USD 91.2m/yr** | 0.021% | **0.530%** | **0.792%** | USD 1.00m/day |

> Marginal cost is **constant at ~USD 1.01m per additional day** of crude oil coverage — no
> convexity in this dataset. Cost per 30-day tranche: USD 30.4m/yr.  
> Crude oil is the **cheapest reserve per day** of all carriers listed.

---

## Table 2 — Refined Petroleum Products Reserve

**Consumption basis:** Total refined product demand ≈ 20 Mt/yr → 54.8 KT/day  
Storage density assumed 0.85 t/m³ (weighted average gasoline/diesel/jet)

| Coverage | Volume | CAPEX | OPEX | **Annual cost** | Cost % GDP | **BE: avoided GDP loss** | **BE: avoided C loss** | MC per day |
|---|---|---|---|---|---|---|---|---|
| 7.8 days  | 500K m³ / 425 KT  | USD 250m | USD 5m/yr  | **USD 27.4m/yr** | 0.006% | **0.159%** | **0.238%** | USD 3.52m/day |
| 15.5 days | 1,000K m³ / 850 KT | USD 500m | USD 10m/yr | **USD 54.8m/yr** | 0.013% | **0.319%** | **0.476%** | USD 3.54m/day |
| 23.3 days | 1,500K m³ / 1,275 KT | USD 750m | USD 15m/yr | **USD 82.3m/yr** | 0.019% | **0.478%** | **0.714%** | USD 3.53m/day |

> Product reserves cost **3.5× more per day** than crude oil reserves because liquid-tight tank
> construction (pumps, vapour recovery, fire suppression) is far more expensive than crude
> tank-farm storage. The break-even GDP loss thresholds are similar to crude oil in absolute terms
> because the volume stored per dollar is lower.

---

## Table 3 — LNG Strategic Reserve

**Consumption basis (2030 PDP8):** ≈ 10 Mt LNG/yr = 27.4 KT/day  
*(Current 2025 LNG imports are negligible; this table targets the 2030+ policy horizon when LNG
storage matters.)*

| Coverage | Volume | CAPEX | OPEX | **Annual cost** | Cost % GDP | **BE: avoided GDP loss** | **BE: avoided C loss** | MC per day |
|---|---|---|---|---|---|---|---|---|
| 110 days | 3,000 KT | USD 1,050m | USD 77m/yr | **USD 171.2m/yr** | 0.040% | **0.995%** | **1.485%** | USD 1.56m/day |
| 219 days | 6,000 KT | USD 2,100m | USD 140m/yr | **USD 328.4m/yr** | 0.076% | **1.909%** | **2.849%** | USD 1.50m/day |

> **Critical caveat:** The 110-day coverage figure assumes LNG imports of 10 Mt/yr (2030 target).
> At current (2025) LNG consumption (~0.5 Mt/yr), the same 3,000 KT reserve would represent
> ~2,190 days (~6 years) of supply — far beyond any strategic reserve concept.  
> LNG has a high boil-off rate (~0.05%/day = ~18%/yr effective loss) which substantially increases
> the true holding cost beyond the OPEX figure shown. The OPEX in the sheet covers terminal
> operations but may understate boil-off replacement costs.  
> The 1% GDP break-even makes LNG storage **the hardest reserve to justify** among fossil fuels
> on direct GDP grounds alone.

---

## Table 4 — LPG Underground Storage

**Consumption basis:** LPG imports ≈ 2 Mt/yr → 5.5 KT/day

| Coverage | Volume | CAPEX | OPEX | **Annual cost** | Cost % GDP | **BE: avoided GDP loss** | **BE: avoided C loss** | MC per day |
|---|---|---|---|---|---|---|---|---|
| 44 days | 240 KT | USD 400m | USD 15m/yr | **USD 50.9m/yr** | 0.012% | **0.296%** | **0.442%** | USD 1.16m/day |

> LPG underground cavern storage is long-lived (30+ years) and cost-efficient per day of
> coverage. Break-even is in the same range as crude oil and domestic coal.

---

## Table 5 — Coal Strategic Reserve

**Consumption basis for coverage:** 75 Mt coal/yr used in power sector → 205.5 KT/day  
*(Sheet states 30/60/90-day coverage directly; verified against this flow.)*  
Annual costs from sheet include: storage & maintenance + financing/carry charge.  
Useful electricity column = net power deliverable after combustion efficiency losses.

### 5a — Domestic Coal (Quảng Ninh mines + plant stockyards)

| Coverage | Volume | Useful electricity | **Annual cost** | Cost % GDP | **BE: avoided GDP loss** | **BE: avoided C loss** | MC per day |
|---|---|---|---|---|---|---|---|---|
| 30 days | 6.16 Mt | 15.0 TWh | **USD 60.4m/yr**  | 0.014% | **0.351%** | **0.524%** | USD 2.01m/day |
| 60 days | 12.33 Mt | 30.0 TWh | **USD 120.7m/yr** | 0.028% | **0.702%** | **1.047%** | USD 2.01m/day |
| 90 days | 18.49 Mt | 45.0 TWh | **USD 181.1m/yr** | 0.042% | **1.053%** | **1.572%** | USD 2.01m/day |

### 5b — Imported Coal (port stockyards: Vĩnh Tân, Duyên Hải, Hải Phòng)

| Coverage | Volume | Useful electricity | **Annual cost** | Cost % GDP | **BE: avoided GDP loss** | **BE: avoided C loss** | MC per day |
|---|---|---|---|---|---|---|---|---|
| 30 days | 6.16 Mt | 16.3 TWh | **USD 113.1m/yr** | 0.026% | **0.658%** | **0.981%** | USD 3.77m/day |
| 60 days | 12.33 Mt | 32.7 TWh | **USD 226.2m/yr** | 0.053% | **1.315%** | **1.963%** | USD 3.77m/day |
| 90 days | 18.49 Mt | 49.0 TWh | **USD 339.4m/yr** | 0.079% | **1.973%** | **2.945%** | USD 3.77m/day |

> **Domestic vs. imported split:** Domestic coal costs USD 2.01m/day of reserve, imported costs
> USD 3.77m/day — 87% more expensive. The premium reflects port-side storage (hired capacity,
> congestion risk, weather exposure) vs. mine-adjacent or plant-yard storage.  
> Domestic 30-day reserve (USD 60.4m/yr) is the most cost-effective coal option; imported 90-day
> (USD 339.4m/yr) has the highest break-even GDP threshold of all fossil fuel options.

---

## Table 6 — Grid Storage: PSHP and BESS

Grid storage serves a **different risk function** from fossil fuel strategic reserves: it covers
short-duration grid frequency deviations and peak-demand shortfalls (minutes to hours), not
multi-month import supply disruptions. The break-even is therefore expressed **per dispatch event**
rather than per annual crisis.

**PSHP (Bac Ai Phase 1, 1,200 MW / 8h, 250 dispatch cycles/yr)**  
CRF = 0.0847 (30-yr, 7.5%). Annual cost includes grid connection CAPEX annualised.

| Metric | Value |
|---|---|
| CAPEX (plant + connection) | USD 1,920m (1,800 + 120) |
| Annual cost (plant + connection) | **USD 189.6m/yr** |
| Annual cost (% GDP) | 0.044% |
| Energy per dispatch event (net of 80% RTE) | **7.68 GWh** |
| Annual energy available | 1.92 TWh/yr (0.62% of 310 TWh grid) |
| **Cost per MWh dispatched** | **USD 98.8/MWh** |
| Break-even GDP loss per dispatch event | **0.000176% of GDP = USD 0.76m per event** |
| Break-even avoided GDP loss (annual crisis basis, p=0.04) | 1.10% of GDP |
| Break-even avoided C loss (annual crisis basis) | 1.65% of C |

**BESS 4h Distributed (1,000 MWh, 365 dispatch cycles/yr)**  
CRF = 0.1204 (15-yr, 8.5%). Effective discharge per cycle = 792 MWh (90% DoD × 88% RTE).

| Metric | Value |
|---|---|
| CAPEX | USD 200m |
| Annual cost | **USD 29.1m/yr** |
| Annual cost (% GDP) | 0.007% |
| Energy per dispatch event (net of DoD × RTE) | **0.792 GWh = 792 MWh** |
| Annual energy available | 0.29 TWh/yr (0.09% of grid) |
| **Cost per MWh dispatched** | **USD 100.6/MWh** |
| Break-even GDP loss per dispatch event | **0.0000185% of GDP = USD 0.08m per event** |
| Break-even avoided GDP loss (annual crisis basis, p=0.04) | 0.169% of GDP |
| Break-even avoided C loss (annual crisis basis) | 0.252% of C |

> PSHP and BESS achieve **similar cost per MWh dispatched (~USD 99–101/MWh)** despite very
> different technology and scale. The break-even per dispatch event is extremely low (USD 0.08m–
> USD 0.76m), meaning virtually any quantifiable grid-disruption avoidance justifies these assets
> on a per-event basis. The relevant economic question is whether the grid actually experiences
> sufficient disruption events, not whether the per-event threshold is met.

---

## Summary: Break-Even Thresholds at a Glance

All avoided GDP and consumption loss figures are **conditional on a crisis occurring** (p = 0.04/yr).

| Energy source | Coverage | Annual cost (USD m/yr) | MC per day (USD m) | **BE: GDP loss (%)** | **BE: C loss (%)** |
|---|---|---|---|---|---|
| Crude oil SPR | 30 days | 30.4 | 1.01 | **0.18%** | 0.26% |
| Crude oil SPR | 61 days | 60.8 | 1.00 | **0.35%** | 0.53% |
| Crude oil SPR | 91 days | 91.2 | 1.00 | **0.53%** | 0.79% |
| LPG underground | 44 days | 50.9 | 1.16 | **0.30%** | 0.44% |
| Domestic coal | 30 days | 60.4 | 2.01 | **0.35%** | 0.52% |
| Domestic coal | 60 days | 120.7 | 2.01 | **0.70%** | 1.05% |
| Domestic coal | 90 days | 181.1 | 2.01 | **1.05%** | 1.57% |
| Ref. products | 7.8 days | 27.4 | 3.52 | **0.16%** | 0.24% |
| Ref. products | 15.5 days | 54.8 | 3.54 | **0.32%** | 0.48% |
| Ref. products | 23.3 days | 82.3 | 3.53 | **0.48%** | 0.71% |
| Imported coal | 30 days | 113.1 | 3.77 | **0.66%** | 0.98% |
| Imported coal | 60 days | 226.2 | 3.77 | **1.32%** | 1.96% |
| Imported coal | 90 days | 339.4 | 3.77 | **1.97%** | 2.95% |
| LNG (2030) | 110 days | 171.2 | 1.56 | **1.00%** | 1.49% |
| LNG (2030) | 219 days | 328.4 | 1.50 | **1.91%** | 2.85% |
| **BESS 4h** | 0.29 TWh/yr | 29.1 | — | **0.17%** *(annual)* | 0.25% |
| **PSHP 1,200 MW** | 1.92 TWh/yr | 189.6 | — | **1.10%** *(annual)* | 1.65% |

*MC per day for PSHP/BESS not applicable — these are cycling assets, not stock reserves.*

---

## Cost Efficiency Ranking (USD m per additional day of reserve coverage)

| Rank | Carrier | MC per day (USD m/yr) | Interpretation |
|---|---|---|---|
| 1 | **Crude oil** | 1.01 | Cheapest per day; large-volume tank farms scale well |
| 2 | **LPG underground** | 1.16 | Cavern storage economical at high utilisation |
| 3 | **LNG (2030)** | 1.50–1.56 | Cryogenic CAPEX offset by large volumes |
| 4 | **Domestic coal** | 2.01 | Mine/plant yard storage; moderate infrastructure |
| 5 | **Refinery products** | 3.52–3.54 | High-spec tanks; vapour control; fire suppression |
| 6 | **Imported coal** | 3.77 | Port-side hired storage; weather exposure premium |

---

## Key Observations for Model Calibration

**1. All fossil storage costs are linear (constant MC)**  
Every storage option shows constant marginal cost per additional day of coverage — the raw
cost data implies no convexity. The quadratic term `kappa2_c` in ToyModelSOEMC and the
DGE-METRIC integration captures the *scarcity of sites and infrastructure* that the raw
cost sheet does not include. This should be calibrated separately from the unit costs above.

**2. Lower break-even thresholds do not mean easier justification**  
Crude oil and refinery products have the lowest break-even GDP% (0.16–0.53%) because their
costs are low and storage volumes are large. Whether those thresholds are actually exceeded
depends on the model's endogenous GDP response — which is determined by the CES production
elasticity (`etaIA`, `alpha_E`) and the fraction of production that the disrupted carrier serves.

**3. Coal reserves are hard to justify on direct GDP loss alone**  
Even domestic coal at 30 days requires a 0.35% GDP loss per crisis. Coal is 46% of Vietnam's
primary energy but mostly serves power plants which have some flexibility (inventory, demand
response). A 50% coal supply disruption for 30 days in the CES model yields roughly 0.15–0.25%
GDP loss depending on substitution — below the break-even for domestic coal and far below the
threshold for imported coal. Coal reserves therefore require either (a) multiplier effects
(brownout damage to industry), (b) multi-year crisis duration, or (c) non-economic security
valuation to pass the cost-benefit test.

**4. BESS and PSHP are almost always justified on a per-event basis**  
The per-dispatch-event break-even is so low (USD 0.08m for BESS, USD 0.76m for PSHP) that
any quantifiable production or consumption disruption during grid stress easily clears the
threshold. The binding question is annual utilisation (cycles/yr) and whether the reserve
displaces genuinely costly events.

**5. LNG storage requires 2030 consumption levels to be meaningful**  
At current LNG imports (~0.5 Mt/yr), the 3 MTA terminal represents years of supply, making
the 90-day coverage framework inapplicable. The LNG break-even of 1% GDP is only relevant
once PDP8 LNG targets (~10 Mt/yr) are realised.
