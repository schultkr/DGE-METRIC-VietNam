# Energy Transition Scenario Implementation Guide

This document describes how to implement alternative energy transition scenarios in a macro-energy model (e.g. DGE-METRC / DGE-CRED).  
Each scenario is defined by a **narrative**, followed by **key modeling assumptions**, **required inputs**, and **implementation notes**.

The scenarios are not mutually exclusive technology pathways, but distinct **system-level transition logics** that can be implemented via different combinations of shocks, constraints, and structural parameters.

---

## Scenario A: Accelerated Distributed Energy Resources (DER)

### Narrative
Electric vehicles (EVs), rooftop solar PV, and battery storage (and other distributed energy resources, DERs) scale up faster than in official plans.  
Households, firms, and service providers rapidly adopt DER technologies.  
Large-scale renewable energy continues to expand, but the power system increasingly relies on a **mix of distributed and utility-scale generation**, improving diversification, reducing fossil fuel dependence, and enhancing system resilience.

---

### Core Modeling Channels
- Final electricity demand from the grid declines relative to baseline
- Electricity demand becomes more flexible (load shifting, self-consumption)
- Capital deepening in household and firm energy assets
- Transport electrification raises electricity demand but reduces fossil fuel demand

---

### Key Assumptions and Required Inputs

#### 1. Rooftop Solar PV
- Installed rooftop PV trajectory:
  - MW installed **or**
  - Share of households adopting PV
- Adoption path relative to PDP8 (faster diffusion)

#### 2. Electricity Demand from the Grid
- Reduction in grid electricity demand by households due to rooftop PV
- Treatment of surplus generation:
  - Self-consumed vs exported to grid
  - Net-metering vs feed-in tariffs vs zero-export assumptions

#### 3. Battery Storage
- Share of PV-adopting households with battery storage
- Assumed storage duration (hours)
- Impact on:
  - Peak load reduction
  - Intra-day load shifting

#### 4. Electric Vehicles
- EV penetration path (% of vehicle stock)
- Electricity demand per EV (kWh/year)
- Charging behavior assumptions (unmanaged vs smart charging)

#### 5. Investment and Cost Assumptions
- DER capital costs:
  - Rooftop PV CAPEX trajectory
  - Battery CAPEX trajectory
- Learning rates and cost declines
- Subsidies, concessional finance, or tax incentives (if any)
- Financing split (households vs firms vs public support)

---

### Implementation Notes
- Can be implemented as:
  - Sector-specific productivity shocks in electricity use
  - Reductions in effective electricity demand elasticities
  - Explicit DER capital stocks owned by households/firms
- Important to avoid double-counting:
  - Reduced grid demand vs increased electricity use from EVs
- System-level consistency requires:
  - Adjusting electricity market clearing conditions
  - Explicit accounting of self-generation vs grid supply


### Objective
We explicitly model the reduction in **final energy consumption purchased from the grid** due to increased household rooftop solar (RTS) adoption.  
RTS supplies a fraction of household electricity demand directly, thereby reducing grid-based final energy demand by **$x\%$**.

---

### Baseline Final Energy Demand Condition

Final energy demand for sector $s$ in region $r$ satisfies the CES demand condition:

## Household Rooftop Solar (RTS) and Final Energy Consumption

### Objective
Household rooftop solar supplies a share of electricity demand directly, reducing **grid-supplied final energy consumption** by x%.

---

### Baseline Final Energy Demand

Final energy demand for sector s in region r satisfies:

$$ P^A_{s,r} / P^D_r = ω_{s,r}^{1/η_Q} · A_{F,s,r}^{(η_Q−1)/η_Q} · ( Q^{A,F}_{s,r} / Q^U_r )^{−1/η_Q} $$

---

### RTS-Adjusted Final Energy Demand

## Household Rooftop Solar (RTS) and Final Energy Consumption

### Objective
Household rooftop solar supplies a share of electricity demand directly, reducing **grid-supplied final energy consumption** by x%.

---

### Baseline Final Energy Demand

Final energy demand for sector s in region r satisfies:

P^A_{s,r} / P^D_r
= ω_{s,r}^{1/η_Q} · A_{F,s,r}^{(η_Q−1)/η_Q}
  · ( Q^{A,F}_{s,r} / Q^U_r )^{−1/η_Q}

---

### RTS-Adjusted Final Energy Demand

## Rooftop Solar (RTS) and the Final Energy Demand Shifter A^F

### Objective
Household rooftop solar (RTS) investment reduces the amount of **grid-supplied final energy** required to deliver a given level of energy services.  
In the model, this effect is captured by an increase in the **final-energy demand shifter** A^F_{s,r,t}, interpreted as energy-augmenting efficiency / self-supply.

---

### Baseline Final Energy Demand

Final energy demand for sector s in region r satisfies:

P^A_{s,r,t} / P^D_{r,t}
= ω_{s,r}^{1/η_Q} · (A^F_{s,r,t})^{(η_Q−1)/η_Q}
  · ( Q^{A,F}_{s,r,t} / Q^U_{r,t} )^{−1/η_Q}

where Q^{A,F}_{s,r,t} denotes **grid-purchased final energy**.

---

### RTS-Driven Shift in A^F_{s,r,t}

Let χ^{RTS}_{r,t} ∈ [0,1] denote the share of household electricity demand met by rooftop solar in region r at time t.  
A reduction in grid final energy consumption by x% corresponds to:

χ^{RTS}_{r,t} = x / 100

RTS affects final energy demand through the shifter A^F_{s,r,t}:

A^F_{s,r,t}
= Ā^F_{s,r} · (1 − χ^{RTS}_{r,t})^{ 1 / (η_Q − 1) }

This mapping ensures that an increase in RTS adoption lowers required grid-supplied final energy in a manner consistent with the CES structure.

---

### Interpretation

- Higher χ^{RTS}_{r,t} raises A^F_{s,r,t}
- For a given level of energy services Q^U_{r,t}, grid final energy demand Q^{A,F}_{s,r,t} declines
- RTS operates as a **quantity-equivalent efficiency wedge**, not a price distortion

---

### Scenario Implementation

- In the Accelerated DER scenario, χ^{RTS}_{r,t} follows an exogenous adoption path reflecting rapid diffusion of rooftop PV.
- The adjustment to A^F_{s,r,t} applies only to **household electricity final energy** (not industrial or transport fuels).

---

### Modeling Notes

- RTS is implemented exclusively through A^F_{s,r,t}; no additional quantity wedge should be applied to Q^{A,F}_{s,r,t}.
- Self-consumption only is captured. Export of rooftop electricity (net-metering) requires an explicit supply-side extension.
- Applying RTS via A^F preserves market-clearing and avoids double-counting with other demand-side shocks.

---
### Notes
- Self-consumption only; no export/net-metering unless modeled separately
- Avoid double-counting with other electricity demand shocks
- Apply χ^{RTS}_r only to household electricity components if sectors are mixed

where:

- $P^{A}_{s,r}$ is the price of final energy input $s$
- $P^{D}_{r}$ is the price of the final demand composite
- $Q^{A,F}_{s,r}$ is grid-supplied final energy consumption
- $Q^{U}_{r}$ is aggregate utility / energy services
- $A_{F,s,r}$ is a final-energy demand shifter
- $\eta_Q$ is the elasticity of substitution across final energy inputs

---

### RTS-Adjusted Final Energy Demand

Let $\chi^{RTS}_{r} \in [0,1]$ denote the **share of household electricity demand met by rooftop solar** in region $r$.

Grid-supplied final energy demand is then reduced to:

\[
(1 - \chi^{RTS}_{r}) \, Q^{A,F}_{s,r}
\]

The modified final energy demand condition becomes:

\[
\frac{P^{A}_{s,r}}{P^{D}_{r}}
=
\omega^{1/\eta_Q}_{s,r}
\,
A^{(\eta_Q-1)/\eta_Q}_{F,s,r}
\left(
\frac{(1 - \chi^{RTS}_{r}) \, Q^{A,F}_{s,r}}{Q^{U}_{r}}
\right)^{-1/\eta_Q}
\]

---

### Interpretation
- An increase in $\chi^{RTS}_{r}$ lowers the quantity of **grid-purchased final energy** required to deliver a given level of energy services $Q^{U}_{r}$.
- A reduction of final energy consumption by $x\%$ corresponds to:
  \[
  \chi^{RTS}_{r} = \frac{x}{100}
  \]
- RTS enters the model as a **quantity wedge**, not a price distortion.

---

### Scenario Implementation
- In Scenario A (Accelerated DER), $\chi^{RTS}_{r}$ follows an exogenous adoption path reflecting rapid diffusion of rooftop PV.
- $\chi^{RTS}_{r}$ may be:
  - time-varying,
  - region-specific,
  - or linked to rooftop PV capital accumulation in an extended model version.

---

### Modeling Notes
- This formulation captures **self-consumption only**.  
  Export of rooftop electricity to the grid (net-metering) is not modeled unless explicitly introduced on the supply side.
- To avoid double counting, RTS-induced demand reduction should not be combined with a separate negative shock to household electricity demand.
- If $s$ includes non-household final energy uses, $\chi^{RTS}_{r}$ should be applied only to the household electricity component.


---

## Scenario B: Energy Efficiency and Demand-Side Management

### Narrative
Energy efficiency improvements in industry and transport are prioritized, alongside demand-side management (DSM) measures such as demand response.  
These measures flatten peak loads and slow overall electricity demand growth.  
System costs and fuel import needs decline, supporting industrial competitiveness and decarbonization with fewer new supply-side investments.

---

### Core Modeling Channels
- Lower energy intensity of production
- Reduced peak electricity demand
- Slower growth of total final energy demand
- Lower fossil fuel and electricity imports

---

### Key Assumptions and Required Inputs

#### 1. Energy Efficiency Improvements
- Sector-specific energy efficiency gains:
  - Industry
  - Transport
- Mapping to:
  - Energy input coefficients
  - Effective productivity of energy services

#### 2. Demand-Side Management (DSM)
- Load shifting assumptions (peak vs off-peak)
- Reduction in required generation capacity per unit of demand
- Impact on system costs (capacity, fuel, O&M)

#### 3. Investment Costs
- Required investment for efficiency improvements:
  - Who pays? (households, firms, government)
- CAPEX vs operating cost trade-offs
- Potential public support or concessional finance

#### 4. Fuel and Electricity Imports
- Elasticity of fuel imports with respect to electricity demand
- Reduction in imported fuels due to efficiency gains

#### 5. Rebound Effects
- Assumption on rebound effects:
  - None
  - Partial (e.g. X% of efficiency gains offset by higher demand)

---

### Implementation Notes
- Efficiency improvements can be modeled as:
  - Energy-augmenting technical change
  - Reductions in sectoral energy input requirements
- DSM mainly affects:
  - Capacity constraints
  - Marginal system costs rather than annual energy balances
- Important to distinguish:
  - Short-run demand response
  - Long-run structural efficiency gains

---

## Scenario C: LNG-to-Hydrogen Transition with CCS

### Narrative
Vietnam initially relies on high LNG imports and gas-fired generation to accommodate increasing electricity demand and industrial growth.  
Over time, the system transitions toward hydrogen and other green fuels, coupled with carbon capture and storage (CCS), to support long-run decarbonization.

---

### Core Modeling Channels
- Higher short- to medium-run fossil fuel imports
- Gradual substitution toward low-carbon fuels
- Capital-intensive decarbonization technologies
- Declining emissions intensity over time

---

### Key Assumptions and Required Inputs

#### 1. Fuel Mix and Emissions
- Emissions intensity assumptions for:
  - LNG
  - Hydrogen (blue vs green)
  - CCS-equipped generation
- Capture rates and residual emissions

#### 2. Hydrogen and CCS Costs
- CAPEX trajectories for:
  - Hydrogen production
  - CCS infrastructure
- O&M costs
- Learning rates and scale effects

#### 3. Financing Structure
- Public vs private investment shares
- Role of concessional finance or international support
- Cost of capital assumptions by technology

#### 4. Transition Timing
- Time profile of:
  - LNG expansion
  - Hydrogen deployment
  - CCS scale-up
- Constraints on deployment speed

---

### Implementation Notes
- Can be implemented via:
  - Technology-specific electricity generation sectors
  - Nested fuel CES structures with declining carbon intensity
- Important to ensure:
  - Consistency between emissions accounting and fuel use
  - Transitional dynamics (lock-in risks vs flexibility)
- Suitable for analyzing:
  - Near-term energy security vs long-term decarbonization trade-offs

---

## Cross-Cutting Modeling Considerations

- Calibration consistency with PDP8 and national energy balances
- Avoiding double-counting of demand reductions and efficiency gains
- Clear separation between:
  - Final energy demand
  - Electricity generation
  - Energy services
- Transparency in financing and incidence assumptions

---

## Suggested Outputs for Comparison
- Electricity demand and capacity mix
- Fuel imports by type
- System costs (investment, fuel, O&M)
- Emissions trajectories
- GDP and sectoral output impacts

---

