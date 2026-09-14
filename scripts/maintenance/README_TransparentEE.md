# Transparent EE Scenarios with Verifiable RTS Deployment

## Overview

This folder contains the infrastructure for creating **energy efficiency (EE) scenarios with transparent, auditable assumptions** about sectoral energy savings and rooftop solar (RTS) deployment.

The new approach separates:
- **Energy efficiency improvements** (e.g., "Industry saves 2.5% of energy per unit output by 2030")
- **RTS deployment** (e.g., "Industry installs 70 MW of rooftop solar by 2030 at USD 140M investment")
- **Grid integration (BESS)** (e.g., "Grid batteries enable 5% higher solar utilization at USD 0.9bn investment")

Each assumption is independently specified, sourced, and verifiable by domain experts.

---

## Quick Start

### For Policymakers / Domain Experts

1. **Obtain the template:** [`ExcelFiles/Input/ExpertClean/Transparent_EE_Baseline_RTS_Conservative.csv`](../../ExcelFiles/Input/ExpertClean/Transparent_EE_Baseline_RTS_Conservative.csv)

2. **Fill in your assumptions:**
   - Column headers are self-documenting (e.g., `EE_Intensity_Improvement_Industry_pct`).
   - For each year (2026–2050), provide:
     - **EE intensity improvement** (% reduction in energy per unit output)
     - **EE investment cost** (USD million/year for retrofits)
     - **RTS capacity addition** (MW/year of rooftop solar)
     - **RTS investment cost** (USD million/year)
     - **Grid integration gain** (% higher solar utilization from BESS)
     - **BESS investment cost** (USD billion/year for grid batteries)
   - Add sources for each assumption in the `*_Source` columns (e.g., "PDP8 Annex 4.2.1", "IEA report #XYZ").

3. **Save as a new CSV** in the same folder, with a descriptive name:
   - Good: `Transparent_EE_Enhanced_RTS_Ambitious.csv`
   - Avoid: `Scenario_v3_final_EDIT_2.csv`

4. **Register the scenario** in the script [`scripts/maintenance/create_ee_scenarios_transparent_rts.m`]:
   - Find the `scenarios` table (around line 80).
   - Add a row: `'Transparent_EE_Enhanced_RTS_Ambitious', 'EE_Transparent_Enhanced_Ambitious'`
   - First column = your CSV filename (without `.csv`).
   - Second column = desired output sheet name in the model workbook.

5. **Run the script** from the repository root:
   ```matlab
   run('scripts/maintenance/create_ee_scenarios_transparent_rts.m')
   ```

6. **Inspect the outputs:**
   - **Main workbook:** `ExcelFiles/ModelScenarios_TransparentEE_5Sectorsand1Regions.xlsx`
     - Contains a sheet per scenario with model variables (exo_AI, exo_GA, exo_PVEff, etc.).
   - **Audit CSVs:** `ExcelFiles/Output/TransparentEE/EE_Scenario_Audit_<name>.csv`
     - Shows inputs, intermediate calculations, and derived model variables.
     - Use this to verify that your assumptions were correctly translated.
   - **Summary table:** `ExcelFiles/Output/TransparentEE/EE_Scenarios_Summary.csv`
     - Comparison across all scenarios (peak EE %, total investment by type, RTS capacity, etc.).

---

## File Structure

```
docs/
  └─ implementation_plans/
     └─ EE_Scenarios_Transparent_RTS_Deployment.md
        ├ Full design document (design principles, model integration, formulas)
        ├ Input specifications (column-by-column reference)
        ├ Validation checklist
        └─ Example scenarios (Baseline, Enhanced, EE-only, RTS-only)

scripts/
  └─ maintenance/
     └─ create_ee_scenarios_transparent_rts.m
        ├ Main implementation (reads CSV, computes shocks, writes outputs)
        ├ Helper functions (accumulate_ka, write_audit_csv, etc.)
        └─ Invoked from repository root: run('scripts/maintenance/...')

ExcelFiles/
  ├─ Input/
  │  └─ ExpertClean/
  │     ├─ Transparent_EE_Baseline_RTS_Conservative.csv  [TEMPLATE]
  │     ├─ Transparent_EE_Enhanced_RTS_Ambitious.csv     [EXAMPLE]
  │     ├─ Transparent_EE_Only.csv                       [EXAMPLE]
  │     └─ Transparent_RTS_Only.csv                      [EXAMPLE]
  │
  └─ Output/
     └─ TransparentEE/
        ├─ EE_Scenario_Audit_<name>.csv
        ├─ EE_Scenarios_Summary.csv
        └─ (populated by script run)

ModelScenarios_TransparentEE_5Sectorsand1Regions.xlsx  [OUTPUT]
  └─ Sheets: one per scenario (EE_Transparent_Baseline_Conservative, etc.)
```

---

## Input Column Reference

### Energy Efficiency (EE)

| Column | Units | Meaning | Example | Notes |
|--------|-------|---------|---------|-------|
| `EE_Intensity_Improvement_Industry_pct` | % reduction | Energy saved per unit industry output | 2.5 | Cumulative or annual; see source documentation |
| `EE_Intensity_Improvement_Commercial_pct` | % reduction | Energy saved per unit commercial output | 2.0 | Applies to services/tertiary sector |
| `EE_Investment_Cost_Industry_USDm_yr` | USD million | Annual EE retrofit cost (industry) | 150 | Cumulative cost for the year; includes labor, equipment, training |
| `EE_Investment_Cost_Commercial_USDm_yr` | USD million | Annual EE retrofit cost (commercial) | 40 | Same basis as industry |

### Rooftop Solar (RTS)

| Column | Units | Meaning | Example | Notes |
|--------|-------|---------|---------|-------|
| `RTS_Capacity_Addition_Industry_MW_yr` | MW/year | Rooftop solar installed (industry) | 50 | Annual addition; cumulative by end of scenario |
| `RTS_Capacity_Addition_Commercial_MW_yr` | MW/year | Rooftop solar installed (commercial) | 30 | Same as industry |
| `RTS_Investment_Cost_Industry_USDm_yr` | USD million | Annual RTS installation cost (industry) | 120 | Includes panels, inverters, grid interconnection, local labor |
| `RTS_Investment_Cost_Commercial_USDm_yr` | USD million | Annual RTS installation cost (commercial) | 60 | Same as industry |

### Grid Integration (BESS + Smart Controls)

| Column | Units | Meaning | Example | Notes |
|--------|-------|---------|---------|-------|
| `RTS_Grid_Integration_Gain_pct` | % | Solar utilization gain via BESS/demand management | 5.0 | Effect of grid batteries on renewable effectiveness |
| `RTS_Grid_Integration_Investment_USDbn_yr` | USD billion | Annual grid-level BESS & smart-meter investment | 0.9 | Aggregate for entire energy system (not per-sector) |

### Verification & Audit (Required)

| Column | Units | Meaning | Example |
|--------|-------|---------|---------|
| `EE_Source_Industry` | text | Source document or expert for industry EE | "IEA ECBCS report #XYZ, 2024" |
| `EE_Source_Commercial` | text | Source document or expert for commercial EE | "MoIT feasibility study, 2025" |
| `RTS_Capacity_Source` | text | Source for RTS capacity roadmap | "PDP8 Annex 4.2.1" |
| `RTS_Cost_Basis` | text | Source for RTS cost assumptions | "NREL PVDB 2026; Vietnam-adjusted" |

---

## Model Integration

### How EE Translates to Model Variables

**Input:** `EE_Intensity_Improvement_Industry_pct = 2.5` (2.5% energy reduction)

**Translation:**
$$
\text{exo\_AI}_{4,1,2}(t) = \log\left(\frac{1}{1 - 0.025}\right) \approx 0.0253
$$

This shock is additive to the baseline AI trend and captures a productivity gain in the energy-using sector.

### How RTS Investment Translates to Model Variables

**Input:** `RTS_Investment_Cost_Industry_USDm_yr = 120` (USD 120M/year)

**Translation:**
$$
\text{exo\_GA}_{3,1}(t) = \text{exo\_GA}_{3,1}^\text{baseline}(t) + \sum_{s} \frac{120 \text{ million}}{430000 \text{ GDP base}} \times (1 - 0.10)^{t-s}
$$

RTS costs are accumulated into the renewable-energy sector's adaptation capital stock (K_A), capturing the investment channel.

### How BESS/Grid Integration Translates

**Input:** `RTS_Grid_Integration_Gain_pct = 5` (5% higher solar utilization)

**Translation:**
$$
\text{exo\_PVEff}_{1}(t) = \log(1 + 0.05) \approx 0.04879
$$

This shock multiplies the productivity of renewable capital (K_PV), modeling how BESS enables higher-value utilization of solar assets.

See [EE_Scenarios_Transparent_RTS_Deployment.md](./EE_Scenarios_Transparent_RTS_Deployment.md) for detailed mathematical formulation.

---

## Validation Checklist

Before submitting a scenario, verify:

- [ ] **Sources are documented.** Every assumption has a reference in the `*_Source` columns (published study, expert, or official plan).
- [ ] **Capacity is plausible.** RTS additions are physically realistic (Vietnam's recent pace: ~5–7 GW/year nationally). A single sector adding >100 MW/year needs strong justification.
- [ ] **Energy savings make sense.** EE improvements > 4% annually for industry are aggressive; check literature benchmarks (typically 1–3%/year for mature markets).
- [ ] **Investment costs are consistent.** EE retrofit costs: ~USD 300–500/kW (typical for industrial chiller/motor upgrades). RTS: ~USD 1.5–2.5/W installed (panels + BOP).
- [ ] **Grid integration is proportional.** BESS investment should scale with cumulative RTS capacity (e.g., USD 50–100/kW of installed capacity).
- [ ] **Columns are complete.** No blank cells except where explicitly NaN is acceptable (e.g., if no RTS in a given year, write `0`, not blank).

---

## Comparing Scenarios

### Isolation: EE-Only vs. RTS-Only

To understand the separate contributions of EE vs. RTS:

1. **EE-Only scenario:** Set all RTS columns to zero; keep EE as desired.
   - CSV name: `Transparent_EE_Only.csv`
   - Shows macroeconomic impact of efficiency retrofits alone.

2. **RTS-Only scenario:** Set all EE columns to zero; keep RTS as desired.
   - CSV name: `Transparent_RTS_Only.csv`
   - Shows macroeconomic impact of solar deployment alone.

3. **Full scenario:** Both EE and RTS active.
   - CSV name: `Transparent_EE_Enhanced_RTS_Ambitious.csv`
   - Shows combined effect.

**Interpretation:** `(Full) - (EE-only) ≈` interaction between EE and RTS.

### Audit Trails

Each run generates an audit CSV (`EE_Scenario_Audit_<name>.csv`) with:
- All input assumptions (by year).
- Derived model variables (exo_AI, exo_GA, exo_PVEff).
- Cumulative metrics (total EE investment, RTS capacity, BESS spending).

Use this to:
- Verify that your CSV inputs were correctly parsed.
- Cross-check intermediate calculations against literature.
- Explain divergences to stakeholders (e.g., "Why did scenario X reach 80 GW RTS by 2050?").

---

## FAQs

### Q: What if my EE saving is not constant every year?

**A:** Specify the year-by-year path. The script will read all rows and interpolate/extrapolate as needed.  
Example:
```
Year,EE_Intensity_Improvement_Industry_pct,...
2026,1.5,...
2027,1.8,...
2030,2.5,...
2040,3.2,...
2050,3.2,...  (terminal level)
```

### Q: What if I want to add a new sector (e.g., Primary or Fossil energy)?

**A:** The current template covers Industry and Commercial (subsectors 4 & 5). To add Primary (subsector 1) or Fossil (subsector 2):
1. Add columns `EE_Intensity_Improvement_Primary_pct`, `EE_Investment_Cost_Primary_USDm_yr`, etc.
2. Update the script's `read_expert_transparent_inputs()` function to parse these new columns.
3. Add corresponding logic to `accumulate_ka()` for the new sector index.

See the script comments for guidance.

### Q: Can I run this script for scenarios that use the old "embedded" EE inputs?

**A:** No. The old script (`create_ee_scenarios_from_expert_inputs.m`) remains for backward compatibility and is still the primary production path. This new transparent script (`create_ee_scenarios_transparent_rts.m`) writes to a **separate workbook** (`ModelScenarios_TransparentEE_*`) to preserve the original workflow.

To migrate a scenario from old to new format, manually decompose the embedded EE assumption into separate EE and RTS columns, then provide sources.

### Q: What is the depreciation rate (deltaKA = 0.10) and why?

**A:** 10% annual depreciation reflects the typical economic lifetime of EE retrofits (~10 years) and RTS systems (~25 years, but modeled as a shorter effective depreciation to account for technological obsolescence). This value is hardcoded in the script; to change it, edit line 56.

### Q: How do I compare results across scenarios in the model?

**A:** After running this script and generating scenario sheets in `ModelScenarios_TransparentEE_5Sectorsand1Regions.xlsx`:

1. Load all scenarios into the model via `RunSimulations.m` or a custom comparison script.
2. Use the audit CSVs to understand which input assumptions differ.
3. Plot or tabulate simulated outcomes (GDP, emissions, investment, sectoral output, etc.) against the input assumptions.

Example:  
*"EE_Transparent_Enhanced_Ambitious has 30% higher EE investment (2026–2050) than Baseline. Simulated emissions in 2050 are 25% lower. Therefore, incremental EE investment has an implicit carbon abatement cost of ~USD X/ton."*

### Q: Can I use the old and new workbooks side-by-side?

**A:** Yes. They have different filenames (`ModelScenarios5Sectorsand1Regions.xlsx` vs. `ModelScenarios_TransparentEE_5Sectorsand1Regions.xlsx`), so there is no conflict. This design intentionally allows piloting the new approach without disrupting existing runs.

---

## Related Documentation

- **Full design rationale:** [`docs/implementation_plans/EE_Scenarios_Transparent_RTS_Deployment.md`](./EE_Scenarios_Transparent_RTS_Deployment.md)
- **Model equations (AI, GA, PVEff):** [`docs/reference/model.md`](../reference/model.md) (search for "exo_AI", "exo_GA")
- **Scenario overview:** [`docs/reference/scenario.md`](../reference/scenario.md)
- **Data & calibration:** [`ExcelFiles/README.md`](../../ExcelFiles/README.md)

---

## Contact & Feedback

Questions? Issues with the template or script?

1. Check the FAQ above.
2. Review the example CSVs (Baseline_Conservative, Enhanced_Ambitious) to see correct formatting.
3. Open an issue or contact the model maintainers with:
   - Your CSV file (attach or describe the problematic row).
   - Error message or unexpected output.
   - Desired outcome.

---

**Version:** 1.0  
**Created:** 2026-09-04  
**Last Updated:** 2026-09-04
