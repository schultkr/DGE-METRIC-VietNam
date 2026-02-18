# Viet Nam – Rooftop PV and Grid Demand Reduction  
## Calibration Note for DGE Scenario Design

---

## 1. Rooftop PV today: contribution to final energy demand

Rooftop solar (RTS) photovoltaic systems already make a measurable contribution to Vietnam’s final energy demand by directly supplying electricity services behind the meter and thereby reducing grid purchases.

As of end-2024:

- **Installed rooftop PV capacity:** ~9.5 GW  
- Estimated annual generation: ~14 TWh  
- National electricity consumption (2023): 277.5 TWh  
- Total final energy consumption (TFEC): ~874 TWh (all fuels)

### Current contribution

| Indicator | Value | Interpretation |
|------------|--------|----------------|
| RTS generation | ~14 TWh/year | Electricity produced behind-the-meter |
| Share of electricity demand | ~5% | 14 / 277.5 |
| Share of total final energy demand | ~1.6% | 14 / 874 |

Thus, rooftop PV currently reduces **grid-supplied electricity demand by roughly 5% annually**, and accounts for approximately **1.6% of Vietnam’s total final energy consumption**.

In a DGE context, this implies that initial calibration should set rooftop PV to cover approximately **1.6% of final energy demand** in the base year.

---

## 2. Macroeconomic magnitude: value of installed rooftop solar panels

Instead of measuring RTS relative to GDP via annual electricity value, we approximate the **capital value of installed rooftop solar panels** and compare it to GDP and annual investment.

### Assumptions

- Installed RTS capacity: 9.5 GW  
- Investment cost per kW (all-in rooftop system cost): ~800 USD/kW  
  (Conservative estimate consistent with recent ASEAN residential/commercial PV costs)

### Total capital value of installed rooftop PV

\[
9.5 \text{ GW} = 9.5 \times 10^6 \text{ kW}
\]

\[
9.5 \times 10^6 \times 800 \approx 7.6 \text{ billion USD}
\]

### Relative to GDP

Vietnam GDP ≈ 430 billion USD.

\[
7.6 / 430 \approx 1.8\%
\]

Thus, the installed rooftop PV capital stock corresponds to roughly:

> **~1.8% of GDP**

### Relative to annual gross investment

Vietnam’s gross capital formation is approximately 30% of GDP:

\[
0.30 \times 430 \approx 129 \text{ billion USD/year}
\]

Therefore:

\[
7.6 / 129 \approx 5.9\%
\]

So the **current rooftop PV capital stock** is equivalent to roughly:

> **~6% of one year of national gross investment**

This confirms that rooftop PV is macroeconomically non-trivial in capital terms, even though its energy share remains modest.

---

## 3. PDP8 expansion trajectory (10× rooftop PV)

Vietnam’s Power Development Plan 8 (PDP8) foresees a substantial expansion of rooftop solar capacity.

Relative to the current ~9.5 GW installed base, PDP8 implies approximately:

> **A tenfold increase in rooftop PV capacity**

This corresponds to:

- ~95 GW rooftop PV  
- ~140 TWh annual generation (at unchanged capacity factor)

At current electricity demand levels:

\[
140 / 277.5 \approx 50\%
\]

Under this scaling, rooftop PV could offset roughly **half of today’s grid electricity demand** (abstracting from demand growth and curtailment).

### Capital stock implication

\[
95 \text{ GW} \times 800 \text{ USD/kW} \approx 76 \text{ billion USD}
\]

This would correspond to:

- ~18% of GDP  
- ~59% of one year’s gross investment  

This scale implies a major structural capital reallocation toward distributed solar assets.

---

## 4. Extended scenario: 20× rooftop PV expansion

For stress-testing energy transition pathways, we simulate an even more ambitious rollout:

> **20× expansion relative to today**

This implies:

- ~190 GW rooftop PV  
- ~280 TWh annual generation  

At current electricity demand levels:

\[
280 / 277.5 \approx 100\%
\]

This scale would approximately match today’s entire electricity consumption on an annual basis.

### Capital implication

\[
190 \text{ GW} \times 800 \text{ USD/kW} \approx 152 \text{ billion USD}
\]

Which corresponds to approximately:

- ~35% of GDP  
- ~118% of one year’s gross investment  

This is clearly a long-run transformation scenario rather than a near-term policy trajectory.

---

## 5. Implications for DGE modeling

In the model, rooftop PV should:

1. Increase effective electricity services:
   \[
   Q_E^{eff} = Q_E^{grid} + Q_{PV}
   \]

2. Reduce grid demand one-for-one (annual accounting approximation):
   \[
   Q_E^{grid} = Q_E^{eff} - Q_{PV}
   \]

3. Enter as a capital stock in the economy:
   \[
   K_{PV,t+1} = (1-\delta_{PV})K_{PV,t} + I_{PV,t}
   \]

This ensures:
- Proper resource constraint treatment  
- Explicit capital accumulation  
- Transparent investment requirements for transition scenarios  

---

# Appendix: Derivation of All Numbers

---

## A1. Converting TFEC to TWh

Given:
- TFEC (2023) = 75,122 ktoe  
- 1 toe = 11.63 MWh  
- 1 ktoe = 11.63 GWh  

\[
TFEC (TWh) = 75,122 \times 11.63 / 1000
\]

\[
\approx 874 \text{ TWh}
\]

---

## A2. Rooftop PV generation from installed capacity

Formula:

\[
E_{PV} = \text{Capacity (GW)} \times 8.76 \times CF
\]

Assume:
- Capacity factor CF = 0.17  

\[
1 \text{ GW} \rightarrow 8.76 \times 0.17 = 1.49 \text{ TWh/year}
\]

### Current:

\[
9.5 \times 1.49 \approx 14.1 \text{ TWh}
\]

---

## A3. Share calculations

Electricity demand:

\[
14 / 277.5 \approx 5.1\%
\]

Total final energy:

\[
14 / 874 \approx 1.6\%
\]

---

## A4. Capital stock valuation

\[
\text{Capital value} = \text{Capacity (kW)} \times \text{Cost per kW}
\]

\[
9.5 \times 10^6 \times 800 = 7.6 \text{ billion USD}
\]

---

## A5. 10× and 20× expansion

| Scenario | Capacity (GW) | TWh/year | Capital (bn USD) |
|------------|---------------|----------|-------------------|
| Today | 9.5 | 14 | 7.6 |
| 10× | 95 | 140 | 76 |
| 20× | 190 | 280 | 152 |

All generation calculated with CF = 0.17 and capital cost = 800 USD/kW.
