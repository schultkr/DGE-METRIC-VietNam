# Structural Parameters Source Audit

Audit date: 2026-05-22

Workbook checked: `ExcelFiles/ModelSimulationandCalibration5Sectorsand1Regions.xlsx`

This note maps the `Structural Parameters` sheet to defensible citation sources and separates data-fed calibration targets from modeling assumptions. The key local scripts are `Functions/Miscellaneous/Excel/update_data_excel.m` and `ExcelFiles/README.md`.

## Main Findings

The sheet is a mix of:

- Observed or IO-derived calibration targets: `phiQI`, `phiM_F`, `phiM_I`, `phiX`, `phiW`, and `phiQI_*_*_*`.
- Behavioral or closure assumptions: `beta`, `phiB`, `phiadjB`, `sigmaL`, `sigmaC`, CES elasticities, `phiK`.
- Policy/tax parameters: `tauC`, `tauNH`, `tauKH`, `tauKF`, `tauNF`.
- Emissions allocation assumptions or targets: `sE`, `sE_NOETS`, `sEI`.
- Single-region identities: `phiQ_D_*_1_1_p = 1`.

The updater currently reads `IO_Data` and `Trade_Flows`, writes to named ranges in `Data`, then propagates to all sheets with `Parameter` and `Value` headers. It directly populates the IO/trade share families listed above, but not the behavioral elasticities or policy assumptions.

## Values That Look Stale

These `Structural Parameters` cells differ from the value implied by current `IO_Data` and the updater logic:

| Parameter | Structural sheet | Current `IO_Data` implied value | Note |
|---|---:|---:|---|
| `phiM_F_3_1_p` | 0.0010000000 | 0.0000124348 | Renewables final-import share appears stale/manual. |
| `phiQI_3_1_1_p` | 0.0001280984 | 0.0000128098 | Renewables input from Primary appears off by factor 10. |
| `phiX_2_1_p` | 0.0040000000 | 0.0046139330 | Fossil export share is stale relative to `IO_Data`. |
| `phiX_3_1_p` | 0.0001000000 | 0.0000594584 | Renewables export share is stale relative to `IO_Data`. |
| `sE_2_1_p` | 1.0000000000 | `Data` sheet currently has 0 | If intentional, document as a manual emissions allocation. Running the updater may overwrite it if the named range is active. |

Before citing the final calibration table, rerun `update_data_excel.m` or intentionally freeze and document these overrides.

## Citation Map

| Parameter block | Current values in sheet | Status | Recommended citation/source | How to describe in paper/report |
|---|---:|---|---|---|
| `phiQI`, `phiM_I`, `phiM_F`, `phiX`, `phiW` | Sector-specific | Data-fed from `IO_Data` | ADB Viet Nam Input-Output Economic Indicators; OECD ICIO if using inter-country flows | "Sectoral expenditure, labor compensation, import, export, and intermediate-use shares are calibrated from a Vietnam input-output table, aggregated to the five model activities and normalized by baseline gross output or value added as specified in the workbook." |
| `phiQI_*_*_*` | Sector-origin matrix | Data-fed from `IO_Data` | Same as IO source above | "Intermediate-input composition is calibrated from the aggregated IO use matrix." |
| `phiQ_D_*_1_1_p` | 1 | Model identity | No external citation needed | "Set to one because the current calibration has a single explicit region." |
| `beta_p` | 0.97 | Assumption / steady-state calibration | Use steady-state annual real-rate target; cite standard RBC/DSGE calibration literature such as King and Rebelo (1999), or derive as `beta = 1/(1+r)` | "The annual discount factor implies a steady-state real return of about 3.1 percent." |
| `delta_p`, `deltaB_p`, `delta_*_1_p` | 0.05 | Assumption, data-checkable | Penn World Table depreciation series; Feenstra, Inklaar and Timmer (2015) | "Capital depreciation is set to 5 percent annually, consistent with common macro calibrations and close to economy-wide PWT depreciation-rate magnitudes." |
| `phiB_p`, `phiadjB_p` | 0.1 | Small-open-economy closure | Schmitt-Grohe and Uribe (2003) | "Foreign bond adjustment costs are stationarity-inducing closure devices following small-open-economy DSGE practice." |
| `sigmaL_p` | 1 | Labor-supply assumption | Chetty et al. (2011) for Frisch elasticity evidence | "Inverse Frisch elasticity is set to one, implying a unit Frisch labor supply elasticity; this should be sensitivity-tested because micro and macro estimates vary widely." |
| `sigmaC_p` | 1 | Preference assumption | Hansen and Singleton (1983), standard log utility/Ramsey-DSGE practice | "Consumption preferences use unit intertemporal elasticity/log utility." |
| `etaQ_p`, `etaF_p`, `etaX_p` | 0.6 | Trade/CES assumption | Armington (1969); GTAP behavioral parameters documentation | "Trade and final-good substitution elasticities are conservative Armington-style CES assumptions." |
| `etaQ_1_p` to `etaQ_5_p` | 2 | Multi-region CES assumption | Armington (1969); GTAP behavioral parameters documentation | "Regional-origin substitution uses an Armington CES elasticity. In the one-region workbook this block is not behaviorally active." |
| `etaQA_1_p`, `etaQA_3_p`, `etaQA_4_p`, `etaQA_5_p` | 1 | Cobb-Douglas within aggregate sectors | van der Werf (2008) for climate-policy production nesting evidence | "Within-sector activity aggregation is Cobb-Douglas except for energy." |
| `etaQA_2_p` | 5 | Clean/dirty energy substitution assumption | Papageorgiou, Saam and Schulte (2017); test sensitivity | "Fossil and renewable energy outputs are treated as relatively close substitutes within the energy aggregate." |
| `etaI_*_p` | 1 | VA/intermediate nesting assumption | van der Werf (2008); CGE nesting practice | "Gross output combines value added and intermediates with a Cobb-Douglas nest." |
| `etaIA_*_p` | 0.1 | Low intermediate-input substitution assumption | GTAP behavioral parameters; CGE/IO Leontief practice | "Intermediate composites are close to Leontief, reflecting limited substitutability among input bundles." |
| `etaNK_*_1_p` | 1 | Capital-labor Cobb-Douglas assumption | van der Werf (2008), plus standard RBC/DSGE production calibration | "Sectoral value added combines capital and labor using Cobb-Douglas technology." |
| `tauC_p` | 0.2 | Policy/effective tax wedge | OECD Revenue Statistics in Asia and the Pacific; OECD Economic Surveys: Viet Nam 2025; PwC VAT summaries | "The consumption tax is an effective wedge, not the statutory VAT. Vietnam's standard VAT is 10 percent, with temporary reductions for some goods through 2026, so 20 percent needs an effective-tax interpretation." |
| `tauNH_p`, `tauKH_p`, `tauKF_*`, `tauNF_*` | 0 | Modeling assumption | PwC Vietnam tax summaries for statutory PIT/CIT if actual tax rates are required | "Sectoral labor and capital tax wedges are switched off in the baseline. Do not cite these zeros as statutory tax rates." |
| `sE`, `sE_NOETS`, `sEI` | Mostly 0/1 | Emissions allocation target/assumption | EDGAR 2025, IEA Greenhouse Gas Emissions from Energy, UNFCCC Viet Nam BUR/NIR, Climate Watch | "Emissions shares should be calibrated from sectoral GHG inventories. Current 0/1 values are best described as a stylized allocation unless replaced by inventory shares." |
| `phiK_*_1_p` | 5 | Investment adjustment-cost assumption | Christiano, Eichenbaum and Evans (2005); Smets and Wouters (2007) | "Sectoral capital adjustment costs are calibrated in the range commonly used in medium-scale DSGE models; sensitivity analysis is recommended, especially for fossil-sector transition scenarios." |

## Source List

- ADB Data Library, "Viet Nam: Input-Output Economic Indicators": https://data.adb.org/dataset/viet-nam-input-output-economic-indicators
- ADB Data Library, "Economic Insights from Input-Output Tables for Asia and the Pacific": https://data.adb.org/dataset/economic-insights-input-output-tables-asia-and-pacific
- OECD, "Inter-Country Input-Output tables": https://www.oecd.org/en/data/datasets/inter-country-input-output-tables.html
- Schmitt-Grohe, S. and Uribe, M. (2003), "Closing Small Open Economy Models": https://econpapers.repec.org/paper/nbrnberwo/9270.htm
- King, R. G. and Rebelo, S. T. (1999), "Resuscitating Real Business Cycles": https://www.nber.org/papers/w7534
- Hansen, L. P. and Singleton, K. J. (1983), "Stochastic Consumption, Risk Aversion, and the Temporal Behavior of Asset Returns": https://larspeterhansen.org/lph_research/stochastic-consumption-risk-aversion-and-the-temporal-behavior-of-asset-returns/
- Armington, P. S. (1969), "A Theory of Demand for Products Distinguished by Place of Production": https://www.elibrary.imf.org/view/journals/024/1969/001/article-A007-en.xml
- Christiano, L. J., Eichenbaum, M. and Evans, C. L. (2005), "Nominal Rigidities and the Dynamic Effects of a Shock to Monetary Policy": https://eric.ed.gov/?id=EJ696919
- Smets, F. and Wouters, R. (2007), "Shocks and Frictions in US Business Cycles": https://www.aeaweb.org/articles?id=10.1257/aer.97.3.586
- Feenstra, R. C., Inklaar, R. and Timmer, M. P. (2015), "The Next Generation of the Penn World Table": https://www.nber.org/papers/w19255
- Chetty, R., Guren, A., Manoli, D. and Weber, A. (2011), "Are Micro and Macro Labor Supply Elasticities Consistent?": https://www.aeaweb.org/articles?id=10.1257/aer.101.3.471
- van der Werf, E. (2008), "Production functions for climate policy modeling": https://ideas.repec.org/a/eee/eneeco/v30y2008i6p2964-2979.html
- Papageorgiou, C., Saam, M. and Schulte, P. (2017), "Substitution between Clean and Dirty Energy Inputs": https://ideas.repec.org/a/tpr/restat/v99y2017i2p281-290.html
- GTAP, "Behavioral Parameters": https://www.gtap.agecon.purdue.edu/resources/res_display.asp?RecordID=5138
- OECD, "Revenue Statistics in Asia and the Pacific 2025": https://www.oecd.org/en/publications/revenue-statistics-in-asia-and-the-pacific-2025_6c04402f-en/full-report/tax-revenue-trends-in-asia-and-the-pacific_d86f4487.html
- OECD, "Economic Surveys: Viet Nam 2025": https://www.oecd.org/content/dam/oecd/en/publications/reports/2025/06/oecd-economic-surveys-viet-nam-2025_f2511b78/fb37254b-en.pdf
- PwC, "Value-added tax rates": https://taxsummaries.pwc.com/quick-charts/value-added-tax-vat-rates
- PwC, "Vietnam - Corporate taxes": https://taxsummaries.pwc.com/vietnam/corporate/taxes-on-corporate-income
- PwC, "Vietnam - Individual taxes": https://taxsummaries.pwc.com/vietnam/individual/taxes-on-personal-income
- EDGAR 2025 GHG database: https://edgar.jrc.ec.europa.eu/dataset_ghg2025
- IEA, "Greenhouse Gas Emissions from Energy": https://www.iea.org/data-and-statistics/data-product/greenhouse-gas-emissions-from-energy
- UNFCCC, "Viet Nam BUR 3 National Inventory Report": https://unfccc.int/documents/273503
- Climate Watch GHG methodology: https://www.wri.org/research/climate-watch-country-greenhouse-gas-emissions-data-and-methodology
- IEA policy database, "National Power Development Planning VIII": https://www.iea.org/policies/26034-decision-no-262qd-ttg-to-implement-the-national-power-development-planning-in-2021-2030
- GIZ/IWH, "Overview of the DGE-CRED model in Vietnam": https://www.giz.de/en/downloads/giz2023-en-overview-dge-cred-model-vietnam.pdf

## Recommended Next Step

Add a `DataSources` sheet to the workbook with columns:

`Parameter`, `Source type`, `Primary source`, `Year`, `Unit`, `Transformation`, `Sector mapping`, `Status`, `Notes`.

At minimum, tag each structural row as `data-fed`, `literature assumption`, `policy assumption`, `model identity`, or `manual override`.
