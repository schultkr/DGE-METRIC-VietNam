# Figure map: IWH Report on Macroeconomic Impact Assessment

Maps each figure in `IWH_Report_Macro_Impact_Assessment_revised.docx` (GIZ "Project Reports" share) to the
script that produces it. Confirmed by comparing the report's embedded chart images against the
generated PNGs (scenario labels, panel titles, and axis values match).

## Reproduce every figure in one go

[`reproduce_macro_impact_assessment_figures.m`](reproduce_macro_impact_assessment_figures.m) runs all
six scripts in the table below (Figures 1�10) in order and checks that each named output file was
rewritten:

```matlab
setup_paths
reproduce_macro_impact_assessment_figures                 % everything, prints a summary table
reproduce_macro_impact_assessment_figures('DryRun', true) % only check inputs/tools, run nothing
reproduce_macro_impact_assessment_figures('Steps', {'NZ', 'Policy'})   % subset: EE, EE_NZ, Finance, GF_NZ, NZ, Policy
summary = reproduce_macro_impact_assessment_figures('StopOnError', true);
```

It first verifies that every scenario CSV each step needs exists in `ExcelFiles/Output/` (same
suffix/fallback rules as the scripts themselves) and, for a missing one, names the `RunSimulations`
scenario group that produces it (`DGE_SCENARIO_GROUPS=ReportReplication` covers all of them). Each
MATLAB script runs in an isolated workspace so their `clearvars`/`clc`/`close all` cannot interfere
with the batch; a failing step is recorded and the remaining steps still run unless `StopOnError`
is set. Figure 10 runs `Visualization/PolicyRecommendations.py` with the repo's `.venv` Python if
present (else `DGE_PYTHON`, else `python`/`py` on `PATH`); its PNG export needs ImageMagick's
`magick` on `PATH`, the SVG is always written. A full run takes roughly 8 minutes.

## Per-figure scripts

All five scripts below share the same `format_axes`/`save_dual` reporting core (see
`generate_finance_simulation_results_figures.m`); the four wrapper scripts just set a
`figureScenarioConfig` struct and then `run()` the appropriate core script. Run any script directly
from the MATLAB console (no arguments needed) after `setup_paths` � each one `cd`s to the repo root
itself and expects `ExcelFiles/Output/*.csv` to already exist for every scenario it lists (i.e. run
the relevant `RunSimulations` scenario groups first).

All scripts read `<Scenario><suffix>.csv`, where the suffix comes from
`Functions/Miscellaneous/Reporting/report_version_suffix.m`: `` by default (the
`sSensitivity` value `RunSimulations.m` writes with the `Model*.xlsx` workbooks, in
which `r_G` is the public-instrument-only weighted rate), or whatever `DGE_WORKBOOK_VERSION` is set to
(`canonical` selects the plain, unsuffixed files). The EE and renewables-investment scripts fall back
to `_replication` and then to the plain files if the preferred variant is missing.

| Figure | Report title | Script to run | Output file (under `docs/figures/`) |
|---|---|---|---|
| 1 | Impact of Energy Efficiency Measures on GDP | [`generate_ee_simulation_results_figures.m`](generate_ee_simulation_results_figures.m) | `EE_Simulation_Results/GDP_Level_Deviation_vs_Baseline_5Y_Average.png` |
| 2 | Energy-intensity reductions relative to the PDP8-rev Baseline | [`generate_ee_simulation_results_figures.m`](generate_ee_simulation_results_figures.m) (same run as Fig. 1) | `EE_Simulation_Results/Energy_Intensity_Deviation_vs_Baseline_5Y_Average.png` |
| 3 | Impact of Energy Efficiency Measures on GDP and Energy intensity under Net Zero | [`generate_ee_nz_simulation_results_figures.m`](generate_ee_nz_simulation_results_figures.m) | Top panel: `EE_NZ_Simulation_Results/GDP_Level_Deviation_vs_Baseline_5Y_Average.png`; bottom panel: `EE_NZ_Simulation_Results/Energy_Intensity_Deviation_vs_Baseline_5Y_Average.png` (stacked manually in the report) |
| 4 | Five-year average GDP-level deviations across green-finance architectures | [`generate_finance_simulation_results_figures.m`](generate_finance_simulation_results_figures.m) | `Finance_Simulation_Results/GDP_Level_Deviation_vs_Baseline_5Y_Average.png` |
| 5 | Renewable-energy financing costs across green-finance architectures | [`generate_finance_simulation_results_figures.m`](generate_finance_simulation_results_figures.m) (same run as Fig. 4) | `Finance_Simulation_Results/WACC_Renewables_Deviation_vs_Baseline_5Y_Average.png` |
| 6 | Renewable-energy financing costs and GDP effects for Net Zero | [`generate_gf_nz_simulation_results_figures.m`](generate_gf_nz_simulation_results_figures.m) | Top panel: `GF_NZ_Simulation_Results/WACC_Renewables_Deviation_vs_Baseline_5Y_Average.png`; bottom panel: `GF_NZ_Simulation_Results/GDP_Level_Deviation_vs_Baseline_5Y_Average.png` |
| 7 | Cumulative emissions trading system revenues | [`generate_nz_simulation_results_figures.m`](generate_nz_simulation_results_figures.m) | `NZ_Simulation_Results/ETS_Revenue_5Y_Cumulative_Billion_USD_NZ_Scenarios.png` |
| 8 | Average deviations in ETS revenue as a share of GDP from the PDP8-rev Baseline | [`generate_nz_simulation_results_figures.m`](generate_nz_simulation_results_figures.m) (same run as Fig. 7) | `NZ_Simulation_Results/ETS_Revenue_Share_Deviation_vs_Baseline_5Y_Average.png` |
| 9 | GDP level deviation from the PDP8-rev Baseline | [`generate_nz_simulation_results_figures.m`](generate_nz_simulation_results_figures.m) (same run as Fig. 7) | `NZ_Simulation_Results/GDP_Level_Deviation_vs_Baseline_5Y_Average.png` |
| 10 | Policy Recommendations | [`Visualization/PolicyRecommendations.py`](Visualization/PolicyRecommendations.py) | `Vietnam_integrated_policy_package_revised.png` / `.svg` (written next to the script, under `scripts/reporting/Visualization/`, not under `docs/figures/`) |

## Scenario CSVs each run needs

Names below are the scenario stems; each is read as `<stem>.csv` by default (see above).

- Figures 1�2: `Baseline`, `EE_Dir10_full`, `EE_Dir10_full_NoBESS`, `EE_RTS_prerev_95GW` (`DataVersion = "plain"`, falls back to `_replication`).
- Figure 3: `Baseline`, `NZ`, `NZ_Dir10_full`, `NZ_Dir10_full_NoBESS` (same fallback).
- Figures 4�5: `Baseline`, `PDP8_GF_A`, `PDP8_GF_B`, `PDP8_GF_C`.
- Figure 6: `Baseline`, `NZ_GF_B`, `NZ_GF_C` (plus `NZ`, which the script's baseline-vs-scenario plotting loop treats as one of the compared series).
- Figures 7�9: `Baseline`, `NZ`, `NZ_subsidy`, `NZ_subsidy_direct`, `NZ_Dir10_full_GF_C`.
- Figure 10 does not read model output � it is a static, hand-authored policy diagram.

## Note on a stray duplicate file

`docs/figures/NZ_Simulation_Results/` currently has both `GDP_Level_Deviation_vs_Baseline_5Y_Average.png`
(current stem, used above) and an older `GDP_Level_Deviation_vs_Baseline_5YAvg.png` (no underscore
before `Average`) � the second one is a leftover from a prior filename convention and is not written
by the script as it stands today. Safe to delete next time this directory is regenerated; left alone
here since removing generated output wasn't asked for.
