# Purpose
The purpose of this document is to provide a short introduction to the logic of scenario building with the DGE-CRED model, and to outline how alternative energy transition narratives can be translated into consistent model inputs and implementation steps.

# Energy Transition Scenario Implementation Guide

This document describes how to implement alternative energy transition scenarios in a macro-energy model (e.g. DGE-METRC / DGE-CRED).  
Each scenario is defined by a **narrative**, followed by **key modeling assumptions**, **required inputs**, and **implementation notes**.

The scenarios are not mutually exclusive technology pathways, but distinct **system-level transition logics** that can be implemented via different combinations of shocks, constraints, and structural parameters.

---

## PDP 8 Scenario: Baseline Scenario representing the Revised PDP 8 scenario


## Scenario A: Accelerated Distributed Energy Resources (DER)

### Narrative
Electric vehicles (EVs), rooftop solar PV, and battery storage scale up faster than in official plans.  
Households and firms rapidly adopt distributed energy resources (DERs), while utility-scale renewables continue to expand.  
The power system increasingly relies on a mix of distributed and centralized generation, improving resilience and reducing fossil fuel dependence.

---

### Core Modeling Channels
- Decline in grid-supplied final electricity demand
- Increased demand flexibility (self-consumption, load shifting)
- Capital deepening in household and firm energy assets
- Transport electrification increases electricity demand and reduces fossil fuel use

---

### Key Assumptions
- Faster rooftop PV adoption than PDP8
- Partial self-consumption of rooftop generation (no net-metering by default)
- Battery storage reduces peak load and shifts demand intra-day
- Rising EV penetration with assumed charging behavior
- Declining DER capital costs (learning effects, possible subsidies)

---

## Rooftop Solar (RTS) and Final Energy Demand

### Objective
Household rooftop solar (RTS) supplies part of electricity demand directly, reducing **grid-purchased final energy consumption** by *x%*.  
This effect is implemented through the **final energy demand shifter** \(A^F\).

---

### Baseline Final Energy Demand
Final energy demand for sector `s` in region `r` satisfies:

P^A_{s,r,t} / P^D_{r,t}  
= ω_{s,r}^{1/η_Q} · (A^F_{s,r,t})^{(η_Q−1)/η_Q} · ( Q^{A,F}_{s,r,t} / Q^U_{r,t} )^{−1/η_Q}

where Q^{A,F}_{s,r,t} denotes grid-purchased final energy.

---

### RTS Adjustment via A^F

Let χ^{RTS}_{r,t} ∈ [0,1] be the share of household electricity demand met by rooftop solar.  
A reduction in grid final energy consumption by x% implies:

χ^{RTS}_{r,t} = x / 100

RTS affects final energy demand through:

A^F_{s,r,t}  
= Ā^F_{s,r} · (1 − χ^{RTS}_{r,t})^{ 1 / (η_Q − 1) }

This formulation ensures consistency with the CES demand structure.

---

### Interpretation
- Higher χ^{RTS}_{r,t} increases A^F_{s,r,t}
- For a given level of energy services Q^U_{r,t}, grid final energy demand Q^{A,F}_{s,r,t} declines
- RTS acts as a **quantity-equivalent efficiency / self-supply wedge**, not a price distortion

---

### Scenario Implementation Notes
- χ^{RTS}_{r,t} follows an exogenous adoption path in Scenario A
- The adjustment applies only to **household electricity final energy**
- RTS is implemented exclusively through A^F to avoid double counting
- Net-metering or exports require an explicit supply-side extension

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

