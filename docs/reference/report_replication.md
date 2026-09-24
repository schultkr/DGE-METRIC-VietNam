# Report Replication Guide

This page maps every scenario-dependent figure and table in the two IWH reports this repository
supports to the exact scenario name(s), reporting script, and output location that produce it.
Static diagrams (model architecture, IO structure, the scenario-hierarchy diagram, the policy
recommendations illustration) aren't scenario output and aren't listed.

- **IWH Technical Report** — `docs/reports/IWH_Technical_Report.docx`
- **IWH Macro Impact Assessment** — `docs/reports/IWH_Report_Macro_Impact_Assessment_revised.docx`

## One-command reproduction

```matlab
setup_paths
RunSimulations   % default activeScenarioGroups = {'ReportReplication'}: all 18 scenarios below,
                 % Baseline and NZ solved first since every other scenario builds on one of them.
```

To run only a subset, either edit `activeScenarioGroups` in `RunSimulations.m` or set
`DGE_SCENARIO_GROUPS` (comma-separated group names) or `DGE_SCENARIO_NAMES` (an exact,
comma-separated, ordered scenario list, bypassing groups entirely) before starting MATLAB. Both
env vars are read by `RunSimulations.m`; see its header comments for exact semantics, along with
`DGE_WORKBOOK_VERSION` (workbook-filename suffix — default ``, in which `r_G` is
the public-instrument-only weighted rate; set to `_replication` for the earlier workbook variant,
or `canonical` for the plain, unsuffixed files).

Then generate figures:

```matlab
run('scripts/reporting/display_baseline_energy.m')                    % Technical Report Figures 4-7, Figures/baseline_*
run('scripts/reporting/generate_gdp_components_start_end_vs_actual.m') % Technical Report Figure 3
run('scripts/reporting/generate_ee_simulation_results_figures.m')      % Technical Report Figs 9-15; Macro Assessment Figs 1-2
run('scripts/reporting/generate_finance_simulation_results_figures.m') % Technical Report Figs 16-23; Macro Assessment Figs 4-5
run('scripts/reporting/generate_ee_nz_simulation_results_figures.m')   % Macro Assessment Figure 3
run('scripts/reporting/generate_gf_nz_simulation_results_figures.m')   % Macro Assessment Figure 6
run('scripts/reporting/generate_nz_simulation_results_figures.m')      % Technical Report Figs 24-36; Macro Assessment Figs 7-9
```

## Scenario name glossary

Both reports were drafted at different points against different code states and use scenario
aliases that don't literally match the current `RunSimulations.m` names. This table gives the
canonical name for each — use these when setting `DGE_SCENARIO_NAMES` or reading
`ExcelFiles/Output/*.csv`.

| Canonical scenario name (current code) | As named in the Technical Report | As named in the Macro Impact Assessment |
|---|---|---|
| `Baseline` | Baseline / PDP8-rev | PDP8-rev Baseline |
| `NZ` | NZ | Net Zero |
| `EE_Dir10_full` | EE_Directive10 | Directive 10 (full) |
| `EE_Dir10_full_NoBESS` | (EE_PDP8_PV_noBESS, approximate) | Directive 10 (no BESS) |
| `EE_RTS_prerev_95GW` | — (not yet in the 31.07.2026 draft) | RTS at pre-revision 95 GW |
| `PDP8_GF_A` / `PDP8_GF_B` / `PDP8_GF_C` | GF A / GF B / GF C (on PDP8-rev) | GF A / GF B / GF C (on PDP8-rev) |
| `NZ_GF_A` / `NZ_GF_B` / `NZ_GF_C` | GF A/B/C (on NZ) | GF A/B/C for Net Zero |
| `NZ_Dir10_full` | — | Net Zero and Directive 10 (full) |
| `NZ_Dir10_full_NoBESS` | — | Net Zero and Directive 10 (no BESS) |
| `NZ_RTS_prerev_95GW(_NoBESS)` | — | (RTS downside, on NZ; not separately charted) |
| `NZ_subsidy` | NZ subsidy | (recycling: non-fossil investment subsidy) |
| `NZ_subsidy_direct` | NZ subsidy direct | (recycling: household climate dividend) |
| `NZ_Dir10_full_GF_C` | NZ GF C EE | Net Zero + GF C + EE |

If you're reconciling against the 31.07.2026 Technical Report draft specifically, note it cites
repository commit `619b45a`, which predates the scripts and scenario names in this table (added
the following day). Cite the tagged commit noted in `docs/reference/reproducibility_checklist.md`
instead when reproducing current figures.

## Technical Report

| Figure/Table | Scenario(s) vs. | Script | Output |
|---|---|---|---|
| Fig. 3 — GDP components, actual vs. baseline start/end | Baseline | `generate_gdp_components_start_end_vs_actual.m` | see script header for `outDir` |
| Table 1 — run-validation checklist | — | — | `docs/reference/reproducibility_checklist.md` (template) |
| Figs. 4–7 — baseline vs. PDP8 target (capacity/investment) | Baseline | `display_baseline_energy.m` | `Figures/baseline_pdp8_*`, `Figures/baseline_ren_*`, `Figures/baseline_energy_*` |
| Figs. 9–15 — EE scenario deviations | `EE_Dir10_full`, `EE_Dir10_full_NoBESS`, `EE_RTS_prerev_95GW` vs. `Baseline` | `generate_ee_simulation_results_figures.m` | `docs/figures/EE_Simulation_Results/` |
| Figs. 16–23 — Finance scenario deviations | `PDP8_GF_A/B/C` vs. `Baseline` | `generate_finance_simulation_results_figures.m` | `docs/figures/Finance_Simulation_Results/` |
| Table 8, Figs. 24–36 — NZ decomposition | `NZ`, `NZ_subsidy`, `NZ_subsidy_direct`, `NZ_Dir10_full_GF_C` vs. `Baseline` | `generate_nz_simulation_results_figures.m` | `docs/figures/NZ_Simulation_Results/` |

## Macro Impact Assessment

| Figure | Scenario(s) vs. | Script | Output |
|---|---|---|---|
| Fig. 1–2 — EE impact on GDP / energy intensity | `EE_Dir10_full`, `EE_Dir10_full_NoBESS`, `EE_RTS_prerev_95GW` vs. `Baseline` | `generate_ee_simulation_results_figures.m` | `docs/figures/EE_Simulation_Results/` |
| Fig. 3 — EE under Net Zero (GDP + energy intensity) | `NZ_Dir10_full`, `NZ_Dir10_full_NoBESS` vs. `NZ` | `generate_ee_nz_simulation_results_figures.m` | `docs/figures/EE_NZ_Simulation_Results/` |
| Fig. 4–5 — GF architectures, GDP level & WACC (PDP8-rev) | `PDP8_GF_A/B/C` vs. `Baseline` | `generate_finance_simulation_results_figures.m` | `docs/figures/Finance_Simulation_Results/` |
| Fig. 6 — GF architectures, GDP & WACC (Net Zero) | `NZ_GF_A/B/C` vs. `NZ` | `generate_gf_nz_simulation_results_figures.m` | see script header for `outDir` |
| Fig. 7–9 — ETS revenues, GDP deviation across NZ variants | `NZ`, `NZ_subsidy`, `NZ_subsidy_direct`, `NZ_Dir10_full_GF_C` vs. `Baseline` | `generate_nz_simulation_results_figures.m` | `docs/figures/NZ_Simulation_Results/` |

If a script's output path above doesn't match what you see on disk, trust the script's own
`outDir`/`fullfile(...)` line over this table — this page is a map, the script is the source of
truth. Report the mismatch so this page can be corrected.
