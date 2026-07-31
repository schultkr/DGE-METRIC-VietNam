# Calibration Data Sources

This page documents where the calibration data for DGE-METRIC's Vietnam baseline comes from — which variables are sourced from which datasets, and where those datasets live.

For the calibration *methodology* (how parameters are solved), see [Calibration](calibration.md).

---

## Overview

DGE-METRIC's Vietnam calibration uses data from seven primary source categories. All raw data files are stored in `C:\Users\schul\Dropbox\2025_GIZ_Vietnam\Data\` (not tracked in the repository due to size and licensing).

| Category | Primary source | Used for |
|---|---|---|
| Macroeconomic structure | GSO, OECD | IO table, sectoral value-added shares, employment |
| Energy production & capacity | EVN, IEA | Energy sector calibration, capacity targets |
| Energy investment costs | IEA WEO, IRENA | CAPEX paths, LCOE assumptions |
| Emissions | EDGAR, IEA | Baseline emissions levels and intensity |
| Trade and capital flows | World Bank, OECD | Import/export shares, FDI flows |
| Climate variables | MRI, SSP scenarios | Climate damage paths (`tas` shocks) |
| Financial parameters | IWH assessment, GIZ workbook | Finance rates and WACF scenarios |

## Provenance note: ETS revenue inputs are scenario assumptions

For Vietnam, this repository currently treats long-run ETS fiscal revenue as a
scenario construct, not an official published projection for 2030/2050. The
main unknowns are ETS-covered emissions, auction share, and carbon price.

For modeling, the accounting identity used is:

$$
REV^{ETS}_t = \theta^{auc}_t \cdot P^{CO2}_t \cdot E^{covered}_t
$$

Only auctioned allowances create direct government revenue; free allocation is
modeled as zero direct fiscal revenue.

---

## Macroeconomic structure

### General Statistics Office of Vietnam (GSO)

- **What:** Input-output tables, labor force survey, sectoral employment data
- **Key file:** `Data/GSO/Vietnam_IO_2019.xlsx` — 2019 supply-use table (VSIC classification)
- **Used for:** Sector-level IO coefficients (`phiW` wholesale shares, `phiN` labor shares), employment shares by sector
- **Aggregation:** Vietnam's VSIC sectors are aggregated to the model's 5-sector structure using NACE-to-model mapping tables in `Data/GSO/`

### OECD

- **What:** OECD IO tables for Vietnam (TiVA database)
- **Key files:** `Data/OECD/Vietnam_IO_OECD.xlsx`, aggregation mapping spreadsheets
- **Used for:** Cross-check of IO structure and trade-embedded sector shares
- **Note:** OECD TiVA uses a different sectoral classification than GSO; a concordance table is used for comparison

---

## Energy production and capacity

### EVN (Vietnam Electricity)

- **What:** EVN annual reports 2010–2023
- **Key files:** `Data/EVN/` — 24 files covering capacity, generation, and power plant data
- **Used for:** Baseline energy sector calibration:
  - Grid energy supply (`Q_A_2_1`) initial level
  - Fossil vs. renewable generation shares
  - Power plant capacity by technology type
- **Vintage:** Primarily 2022–2023 data for the 2026 calibration start year

### IEA World Energy Outlook (WEO)

- **What:** Annual WEO reports 1999–2025; CAPEX and investment data
- **Key files:** `Data/IEA/` — 40 files including WEO_2025.pdf and structured data extracts
- **Used for:** Energy system calibration and scenario inputs:
  - Technology CAPEX trajectories (solar PV, wind, storage)
  - Vietnam energy demand projections (cross-check)
  - Global carbon price scenarios (Net-Zero scenario reference)
  - LCOE assumptions for renewable vs. fossil energy

---

## Emissions

### EDGAR (EU Joint Research Centre)

- **What:** Global GHG emissions database (2024 release)
- **Key files:** `Data/EDGAR/` — sectoral emissions data for Vietnam
- **Used for:** Baseline emissions levels by sector (`E_s` initial values), emission intensity factors, cross-check against IEA emissions data

### IEA emissions data

- **What:** Vietnam energy sector CO₂ emissions from WEO supplementary data
- **Used for:** Energy-sector emission coefficients, consistency with IEA energy balance data

---

## Trade and capital flows

### World Bank

- **What:** Vietnam balance of payments, FDI inflows, external debt
- **Used for:** Initial net foreign asset position, foreign sector calibration (`B_0`, `rf0`)

### OECD (trade shares)

- **What:** Trade in value-added data
- **Used for:** Import and export shares by sector (`phiIM`, `phiEX`)

---

## Environmentally extended IO

### EXIOBASE 3

- **What:** Environmentally extended multi-region IO database
- **Key files:** `Data/EXIOBASE_3/` — database with documentation
- **Used for:** Cross-check of embodied emissions and energy coefficients; validation of sectoral energy intensity assumptions
- **Note:** EXIOBASE operates at a global/region level; Vietnam-specific results require extraction and re-aggregation

---

## Climate damage paths

### MRI climate model (CMIP6)

- **What:** Regional temperature anomaly paths for Vietnam under SSP scenarios
- **Key files:** `Data/ClimateVariablesSSP*/` — scenario-specific climate variable files
- **Used for:** Temperature anomaly (`tas`) shocks entering climate damage equations:
  - Productive capital damage (`D^K_{s,t}`)
  - Housing damage (`D^H_t`)
- **SSP variants:** SSP2-4.5 (moderate warming, PDP8-consistent), SSP5-8.5 (high warming, sensitivity)

---

## Financial parameters and rates

### IWH Financial Assessment (2025)

- **What:** Market interest rates, WACF estimates, instrument availability assessment
- **Key file:** `Dropbox/2025_GIZ_Vietnam/Reports/Deliverables/Financial Assessment Report/IWH_Report_Financial Assessment_2025_10_06.docx`
- **Used for:** Finance scenario WACF calibration (GF_A: 6.43%, GF_B: 7.37%, GF_C: 5.07%)

### GIZ Vietnam Green Finance Scenarios Workbook (April 2026)

- **What:** WACF by instrument and scenario, annual financing cost calculations
- **Key file:** `ExcelFiles/PDP8/Vietnam_Green_Finance_Scenarios_April2026.xlsx`
- **Used for:** Translating financing architecture into model rate shocks (`exo_r_G`, `exo_r_FDI`)

### IWH Investment Needs Assessment (2025)

- **What:** Investment volume estimates by sector and technology (2026–2050)
- **Key file:** `Dropbox/2025_GIZ_Vietnam/Reports/Deliverables/Investment Needs Assessment/IWH_Investment_Needs_Assessment_Report_clean.docx`
- **Used for:** Calibrating investment path targets (`exo_I_s`) and public capital paths (`exo_K_G_s`)

---

## Summary: variable-to-source mapping

| Model variable | Description | Primary source |
|---|---|---|
| `phiY0_s` | Sectoral value-added shares | GSO IO table 2019 |
| `phiN0_s` | Labor income shares | GSO employment + IO |
| `phiW_s_k` | Intermediate input shares | GSO / OECD IO |
| `E_s_0` | Initial sectoral emissions | EDGAR 2024 |
| `Q_A_2_1_0` | Initial grid energy supply | EVN annual report |
| `CAPEX_s` | Renewable investment cost path | IEA WEO 2025 |
| `tas_t` | Temperature anomaly path | MRI / CMIP6 SSP |
| `exo_r_G_s` | Public finance rate | IWH Financial Assessment |
| `exo_KRGTarget_s` | Investment volume target | IWH Investment Needs Assessment |
| `rf0` | World interest rate | World Bank / OECD |

---

## Provenance note: expert-email harmonization (rooftop solar / RTS split)

One input series — the rooftop solar (RTS) capacity and generation split used
in baseline and scenario construction — originates from an expert email
rather than a structured dataset, and its transformation into model-ready
data is tracked explicitly for transparency:

- **Source:** an Outlook expert email (extract retained as `tmp_pdf_extract.txt`).
- **Structured intermediate:** `ExcelFiles/Output/RTS_split_assumptions_from_expert_email.csv`
  — the email's capacity/generation figures converted to an annual time series
  (2025–2050).
- **Harmonized workbook:** `ExcelFiles/Vietnam_EnergyExpert_ScenarioInputs_harmonized.xlsx`,
  sheet `PDP8_revised`, columns `RTS_Capacity_GW` (from `cap_total_MW / 1000`)
  and `RTS_Generation_TWh` (from `gen_total_GWh / 1000`), plus 2030 milestones
  `Office_RTS_Penetration_pct = 50` and `Residential_RTS_Penetration_pct = 50`.
- **Key milestones matched exactly:** 2030 — `RTS_Capacity_GW = 36.733`,
  `RTS_Generation_TWh = 44.827`; 2050 — `RTS_Capacity_GW = 137.670`,
  `RTS_Generation_TWh = 176.936`.
- **Consumed by:** `scripts/maintenance/create_baseline_from_user_input_file.m`
  (reads the CSV) and `scripts/maintenance/create_ee_scenarios_from_expert_inputs.m`
  (reads `ExcelFiles/Vietnam_EnergyExpert_ScenarioInputs.xlsx`).
- **Operational note:** if the source workbook is open in Excel, direct
  overwrite is blocked — write to the `_harmonized.xlsx` copy and replace
  after closing the original.

This CSV-as-intermediate pattern — raw qualitative/expert input converted to
a transparent, versioned annual series before it reaches a workbook — is the
template to follow for any future non-dataset input.

## Notes on data access

- The Dropbox data folder is **not tracked in the repository** (too large, mixed licensing). It is maintained locally at `C:\Users\schul\Dropbox\2025_GIZ_Vietnam\Data\`.
- Raw data is pre-processed into the calibration workbook (`ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx`) and is reproduced by `scripts/maintenance/update_baseline_sheet.m`.
- For questions about specific source data, contact the IWH project team or consult the IWH Data Report: `Dropbox/2025_GIZ_Vietnam/Reports/Deliverables/Data Report/`.
