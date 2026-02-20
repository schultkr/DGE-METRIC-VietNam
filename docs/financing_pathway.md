# Viet Nam Energy Transition Financing Pathways
## Policy Summary for Concessional Finance, Revenue Recycling, and Growth

---

## Executive summary (for decision-makers)

- This draft compares financing strategies under two emissions pathways: **PDP8** and **Net Zero (NZ)**.
- Reference cases use **normal government financing conditions**: public investment interest rate of **5%** and **no recycling** of emission tax revenues.
- Two financing-policy variants are assessed: (i) **concessional public loans** (interest rate reduced by 5 percentage points), and (ii) **recycling emission tax revenues** into renewable capital investment.
- These financing tools can accelerate renewable capital formation, reduce financing pressure, and improve transition feasibility.
- Macroeconomic effects depend on policy design and timing, with potential near-term investment support and medium-term productivity gains.

---

## Why this matters

Financing design is a key determinant of transition speed and cost:

1. **Affordability of public investment:** lower rates reduce debt-service burden.
2. **Investment crowd-in:** recycled revenues can fund additional renewable capacity.
3. **Policy credibility:** transparent financing rules improve implementation certainty.

---

## Baseline facts used in the model

| Indicator | Value | Policy interpretation |
|---|---:|---|
| Emissions pathways | PDP8 and Net Zero | Two policy environments for financing assessment |
| Public investment financing rate (baseline) | 5% | Reference cost of government capital |
| Concessional financing shock | -5 percentage points | Effective public financing rate reduced to 0% in the scenario design |
| Revenue recycling baseline | None | Emission tax revenues are not earmarked for renewable investment |
| Renewable investment financing variant | Tax-recycling rule | Emission-tax revenue redirected to renewable capital accumulation |

---

## Scenario matrix

| Scenario ID | Emissions pathway | Public financing rate | Emission-tax revenue recycling | Role in analysis |
|---|---|---:|---|---|
| **PDP8-Base** | PDP8 | 8% | No | Baseline under planned pathway |
| **NZ-Base** | Net Zero | 8 | No | Baseline under decarbonization pathway |
| **PDP8-Concessional** | PDP8 | 3% (5pp lower) | No | Isolates concessional loan effect under PDP8 |
| **NZ-Concessional** | Net Zero | 3% (5pp lower) | No | Isolates concessional loan effect under NZ |
| **PDP8-Recycle** | PDP8 | 5% | Yes | Isolates tax-recycling investment channel under PDP8 |
| **NZ-Recycle** | Net Zero | 5% | Yes | Isolates tax-recycling investment channel under NZ |

**Comparison principle:**
- Concessional scenarios are compared against the corresponding base case with the same emissions pathway.
- Recycling scenarios are compared against the corresponding base case with the same emissions pathway.
- Cross-pathway comparison (PDP8 vs NZ) shows how financing tools interact with the stringency of climate policy.

---

## Main results (draft structure)

### 1) Financing conditions and public investment costs
- Lower concessional rates reduce the effective cost of public renewable investment.
- This can bring forward investment and smooth transition financing needs.

<figure style="text-align:center; margin: 1.2rem 0;">
  <figcaption><em>Figure 1. Public financing rate.</em></figcaption>
  <img src="figures/Financing/PublicInterestRate.png" alt="Public investment financing rates across scenarios" style="width:88%; max-width:980px; border-radius:6px;" />
</figure>

### 2) Renewable capital accumulation
- Both concessional loans and tax-revenue recycling can increase renewable capital stock.
- Effects are typically stronger in the NZ environment due to stronger transition incentives.

<figure style="text-align:center; margin: 1.2rem 0;">
  <figcaption><em>Figure 2. Renewable capital stock.</em></figcaption>
  <img src="figures/Financing/RenewableCapital.png" alt="Renewable capital stock pathways" style="width:88%; max-width:980px; border-radius:6px;" />
</figure>

### 3) Investment and growth
- Financing support can raise near-term investment and support GDP growth.
- Over longer horizons, growth rates may normalize due to base effects, while output levels remain above baseline.
- **All GDP components shown below are expressed relative to the corresponding emissions baseline (PDP8-Base or NZ-Base).**

<figure style="text-align:center; margin: 1.2rem 0;">
  <figcaption><em>Figure 3. GDP growth.</em></figcaption>
  <img src="figures/Financing/GDP_Growth.png" alt="GDP growth effects" style="width:88%; max-width:980px; border-radius:6px;" />
</figure>

<figure style="text-align:center; margin: 1.2rem 0;">
  <figcaption><em>Figure 4. GDP.</em></figcaption>
  <img src="figures/Financing/GDP.png" alt="GDP level effects" style="width:88%; max-width:980px; border-radius:6px;" />
</figure>

<figure style="text-align:center; margin: 1.2rem 0;">
  <figcaption><em>Figure 5. Total investment.</em></figcaption>
  <img src="figures/Financing/Investment.png" alt="Investment effects" style="width:88%; max-width:980px; border-radius:6px;" />
</figure>

### 4) Fiscal and carbon-market channels
- Revenue recycling shifts fiscal resources from general budget use to transition investment.
- Under NZ, interaction with higher carbon-policy stringency can amplify renewable investment effects.

<figure style="text-align:center; margin: 1.2rem 0;">
  <figcaption><em>Figure 6. Emission tax revenues.</em></figcaption>
  <img src="figures/Financing/EmissionTaxRevenue.png" alt="Emission tax revenue pathways" style="width:88%; max-width:980px; border-radius:6px;" />
</figure>

<figure style="text-align:center; margin: 1.2rem 0;">
  <figcaption><em>Figure 7. Recycled renewable investment.</em></figcaption>
  <img src="figures/Financing/RecycledInvestment.png" alt="Renewable investment financed by recycled revenues" style="width:88%; max-width:980px; border-radius:6px;" />
</figure>

### 5) Emissions and energy-system outcomes
- Financing design affects the speed of capital turnover and therefore emissions trajectories.
- The same financing tool can have different emissions effects under PDP8 versus NZ.

<figure style="text-align:center; margin: 1.2rem 0;">
  <figcaption><em>Figure 8. Emissions.</em></figcaption>
  <img src="figures/Financing/Emissions.png" alt="Emissions pathways under financing scenarios" style="width:88%; max-width:980px; border-radius:6px;" />
</figure>

<figure style="text-align:center; margin: 1.2rem 0;">
  <figcaption><em>Figure 9. Renewable generation.</em></figcaption>
  <img src="figures/Financing/RenewableGeneration.png" alt="Renewable generation effects" style="width:88%; max-width:980px; border-radius:6px;" />
</figure>

---

## What policymakers can take away

- **Financing terms matter as much as technology costs** for transition speed.
- **Concessional public loans** reduce upfront financing pressure and improve project viability.
- **Revenue recycling** can create a self-reinforcing investment channel for renewable capital.
- **Policy consistency across emissions and financing rules** is critical for stable long-run outcomes.

---

## DGE implementation note (technical, short)

Let $b$ denote baseline emissions pathway ($b \in \{\text{PDP8},\text{NZ}\}$), and $s$ financing scenario.

### Public financing rate rule

$$
r^{G}_{s,t} = r^{G,base}_{b,t} - \Delta r^{G}_{s,t}
$$

with

$$
r^{G,base}_{b,t}=0.05,
\qquad
\Delta r^{G}_{s,t}=0.05\;\text{for concessional scenarios, else }0.
$$

### Revenue recycling into renewable capital

Let $Rev^{ET}_{b,t}$ be emission-tax revenue and $\rho^{rec}_{s,t}$ the recycling share:

$$
I^{RE,rec}_{s,t}=\rho^{rec}_{s,t}\,Rev^{ET}_{b,t},
\qquad
\rho^{rec}_{s,t}=1\;\text{in recycling scenarios, else }0.
$$

Renewable capital accumulation:

$$
K^{RE}_{s,t+1}=(1-\delta^{RE})K^{RE}_{s,t}+I^{RE,base}_{s,t}+I^{RE,rec}_{s,t}.
$$

### Comparison metric

Report outcomes as deviations from pathway-specific baselines:

$$
\Delta X^{PDP8}_{s,t}=\frac{X_{s,t}-X_{\text{PDP8-Base},t}}{X_{\text{PDP8-Base},t}}\times 100,
\quad
\Delta X^{NZ}_{s,t}=\frac{X_{s,t}-X_{\text{NZ-Base},t}}{X_{\text{NZ-Base},t}}\times 100.
$$

---

## Annex: reporting checklist

### A1. Core indicators
- Public financing rate (%).
- Emission-tax revenue (bn USD, % GDP).
- Recycled renewable investment (bn USD, % GDP).
- Renewable capital stock and generation.
- GDP growth and GDP level effects.
- Emissions pathway comparison.

### A2. Minimum figure package
- Financing rate path.
- Renewable investment and capital stock.
- GDP growth and GDP level.
- Emission-tax revenue and recycling flows.
- Emissions and renewable generation.

### A3. Notes for final calibration
- Confirm whether concessional-rate shock is modeled as deterministic level shift or time-bounded program.
- Confirm recycling share ($\rho^{rec}$) and any lag between revenue collection and investment disbursement.
- Confirm whether revenue recycling applies under PDP8 only, NZ only, or both (current draft assumes both for symmetry).
