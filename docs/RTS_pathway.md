# Viet Nam – Rooftop PV calibration note (TWh) for grid-demand reduction scenarios

This note tabulates **current energy demand**, **electricity demand**, **rooftop PV (installed + production)**, and **potential**, and translates these into **scenario calibration targets** for reducing **final energy demand supplied by the grid** (i.e., grid electricity purchases).

---

## 1) Core data (latest public, rounded)

| Metric | Unit | Value | Source / comment |
|---|---:|---:|---|
| Total final energy consumption (TFEC), 2023 | ktoe | **75,122** | National estimate in 2023 country report. :contentReference[oaicite:0]{index=0} |
| Total final energy consumption (TFEC), 2023 | TWh (eq.) | **~874** | Conversion: 1 toe = 11.63 MWh ⇒ 75,122 ktoe × 11.63 GWh/ktoe ≈ 874 TWh. (Derived from TFEC above.) :contentReference[oaicite:1]{index=1} |
| Electricity consumption, 2023 | TWh | **277.5** | Net electricity consumption. :contentReference[oaicite:2]{index=2} |
| Rooftop PV installed capacity, end-2024 | GW | **~9.5** | “Over 9,500 MW” rooftop PV. :contentReference[oaicite:3]{index=3} |
| Grid-connected solar capacity (all solar), Nov-2025 | GW | **~17** | Grid operator figure reported. :contentReference[oaicite:4]{index=4} |
| Rooftop share of solar capacity | % | **~46%** | Rooftop share of the ~17 GW solar capacity. :contentReference[oaicite:5]{index=5} |

---

## 2) Conversions and working assumptions (transparent, model-friendly)

### 2.1 Convert TFEC to TWh-equivalent
- Using the standard energy unit conversion: **1 toe = 11.63 MWh**  
  ⇒ **1 ktoe = 11.63 GWh**  
  ⇒ **TFEC (TWh) = TFEC (ktoe) × 11.63 / 1,000**.

### 2.2 Rooftop PV generation from capacity
Public sources often report rooftop PV **capacity** more reliably than **annual generation**. For calibration, estimate generation from:

- **Annual PV generation (TWh) ≈ Capacity (GW) × 8.76 × Capacity Factor (CF)**  
- Use a **Vietnam-reasonable CF = 0.16–0.18** (typical range for PV in tropical/subtropical climates; choose a single value for baseline sensitivity).

Rule of thumb at **CF = 0.17**:
- **1 GW rooftop PV ≈ 8.76 × 0.17 = 1.49 TWh/year**

So with **9.5 GW** rooftop PV:
- **Rooftop PV generation ≈ 9.5 × 1.49 = 14.1 TWh/year** (baseline estimate)

> Note: This is a *calibration estimate* for macro modeling; actual realized generation depends on curtailment, self-consumption, outages, and location mix.

---

## 3) Tabulation in TWh (what you can plug into scenarios)

### 3.1 Demand and current rooftop PV contribution (TWh/year)

| Item | Symbol (example) | TWh/year | How to interpret in the model |
|---|---|---:|---|
| Total final energy demand | `FE` | **~874** | All fuels + electricity (energy-balance concept) |
| Final electricity demand (grid supplied) | `E_grid_total` | **277.5** | Electricity purchased from grid (economy-wide) |
| Rooftop PV generation (estimated) | `E_PV` | **~14** | Electricity services produced “behind-the-meter” |
| Grid-demand reduction from rooftop PV | `ΔE_grid` | **~14** | If PV offsets grid purchases one-for-one (annual) |
| Rooftop PV share of electricity demand |  | **~5.1%** | 14 / 277.5 |
| Rooftop PV share of total final energy |  | **~1.6%** | 14 / 874 |

Electricity demand source: :contentReference[oaicite:6]{index=6}  
TFEC source: :contentReference[oaicite:7]{index=7}  
Rooftop capacity source: :contentReference[oaicite:8]{index=8}

---

## 4) Potential (technical upper bound) and why you still need “deployable” scenarios

A commonly cited national **technical rooftop PV potential** is **~963 GW**. :contentReference[oaicite:9]{index=9}

Convert this to annual electricity (illustrative upper bound):
- Using CF = 0.17:  
  **E_PV_potential ≈ 963 × 1.49 ≈ 1,435 TWh/year**

| Potential concept | Capacity (GW) | TWh/year (CF=0.17) | Interpretation |
|---|---:|---:|---|
| Rooftop PV technical potential (upper bound) | **963** | **~1,435** | Purely technical roof-area potential; not economically or grid-feasibility constrained :contentReference[oaicite:10]{index=10} |
| “Deployable” medium-term envelope (example) | 20–40 | ~30–60 | Practical scenario range for policy + grid + finance constraints (recommended for macro scenarios) |

**Why not calibrate to the technical maximum?**  
Because 963 GW would exceed current annual electricity demand by a very large margin. For DGE scenario analysis, it’s usually better to define **deployable potentials** (e.g., 20/30/40 GW rooftop) and treat the technical maximum as a *ceiling* for long-run feasibility discussions.

---

## 5) Scenario calibration targets (directly usable for “reduce grid final energy demand”)

Assume annual electricity demand is held fixed at 277.5 TWh for calibration (or you can let it grow endogenously). Then define:

- `E_eff = E_grid + E_PV` (electricity services)
- **Grid purchases** (what the electricity sector must produce/sell):  
  `E_grid = max(0, E_eff - E_PV)`  
- In annual accounting, the **reduction in grid-supplied final electricity** is approximately `ΔE_grid ≈ E_PV` if services demand is unchanged.

### 5.1 Rooftop PV expansion scenarios (capacity → TWh)

Using CF = 0.17 (1 GW → 1.49 TWh):

| Scenario | Rooftop PV (GW) | Rooftop PV (TWh) | Grid electricity reduction (TWh) | % of current electricity demand |
|---|---:|---:|---:|---:|
| Current baseline | 9.5 | ~14 | ~14 | ~5% |
| Moderate rollout | 20 | ~30 | ~30 | ~11% |
| Strong rollout | 30 | ~45 | ~45 | ~16% |
| High rollout | 40 | ~60 | ~60 | ~22% |

> Interpretation: in the model, you can implement these as **paths for `Q_PV_reg`** (annual TWh equivalent) that reduce **grid demand** one-for-one.

---

## 6) How to map this into your DGE demand system (conceptual)

To avoid breaking the resource constraint:

1. Keep **market absorption** (`Q_U_reg`) based on **grid electricity purchases**.
2. Create **effective electricity services** used in the CES nest:  
   `Q_E_eff = Q_E_grid + Q_PV`
3. Electricity sector market clearing uses **grid purchases only**:  
   `Y_E = Q_E_grid + ...` (other grid users)

This ensures rooftop PV reduces **final energy provided by the grid** without requiring additional production in the economy-wide resource constraint.

---

## 7) Recommended reporting lines for your scenario write-up

- **Today:** rooftop PV is ~9.5 GW installed, plausibly delivering ~14 TWh/year, reducing grid-supplied electricity demand by ~5% on an annual basis. :contentReference[oaicite:11]{index=11}  
- **Potential:** technical rooftop potential is cited around 963 GW (very large ceiling), which would correspond to >1,000 TWh/year at typical PV capacity factors. :contentReference[oaicite:12]{index=12}  
- **Scenarios:** a practical macro-relevant deployable range is 20–40 GW (≈30–60 TWh/year), implying ~11–22% reductions in grid-supplied final electricity demand at current demand levels.

---

### Appendix: Quick conversions
- **TFEC (TWh)** = `TFEC (ktoe) × 11.63 / 1000`
- **PV generation (TWh)** = `PV capacity (GW) × 8.76 × CF`
- **PV share of electricity demand** = `E_PV / E_grid_total`

