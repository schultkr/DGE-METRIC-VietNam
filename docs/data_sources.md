# Calibration Data Sources

This page documents where the calibration data for DGE-METRIC's Vietnam baseline comes from — which variables are sourced from which datasets, and where those datasets live.

For the calibration *methodology* (how parameters are solved), see [Calibration](calibration.md).

---

## Overview

DGE-METRIC's Vietnam calibration uses data from seven primary source categories. Raw data files are not tracked in the repository (size and licensing constraints) — they are held in the project data archive maintained by the IWH research team.

| Category | Primary source | Used for |
|---|---|---|
| Macroeconomic structure | GSO, OECD | IO table, sectoral value-added shares, employment |
| Energy production & capacity | EVN, IEA | Energy sector calibration, capacity targets |
| Energy investment costs | IEA WEO, IRENA | CAPEX paths, LCOE assumptions |
| Emissions | EDGAR, IEA | Baseline emissions levels and intensity |
| Trade and capital flows | World Bank, OECD | Import/export shares, FDI flows |
| Climate variables | MRI, SSP scenarios | Climate damage paths (`tas` shocks) |
| Financial parameters | IWH assessment, GIZ workbook | Finance rates and WACF scenarios |

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
- **Key file:** IWH Report — Financial Assessment (2025); available from the IWH project team
- **Used for:** Finance scenario WACF calibration (GF_A: 6.43%, GF_B: 7.37%, GF_C: 5.07%)

### GIZ Vietnam Green Finance Scenarios Workbook (April 2026)

- **What:** WACF by instrument and scenario, annual financing cost calculations
- **Key file:** `ExcelFiles/PDP8/Vietnam_Green_Finance_Scenarios_April2026.xlsx`
- **Used for:** Translating financing architecture into model rate shocks (`exo_r_G`, `exo_r_FDI`)

### IWH Investment Needs Assessment (2025)

- **What:** Investment volume estimates by sector and technology (2026–2050)
- **Key file:** IWH Investment Needs Assessment Report (2025); available from the IWH project team
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

## Notes on data access

- Raw data is **not tracked in the repository** (too large, mixed licensing). It is held in the project data archive maintained by the IWH research team.
- Raw data is pre-processed into the calibration workbook (`ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx`).
- For questions about specific source data, contact the IWH project team or consult the IWH Data Report (available from the project archive).
