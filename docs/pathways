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
- Capacity factors by region (if regionalized)

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

