# DGE-METRIC

This repository contains the implementation of **DGE-METRIC** (Dynamic General Equilibrium for
Macroeconomic Energy Transition Incorporating Carbon Markets), a five-sector, one-region dynamic
general equilibrium model of Vietnam's economy (2026–2050) used to simulate macroeconomic and
sectoral impacts under alternative climate and energy-transition pathways. The codebase combines
**Dynare `.mod` files**, **MATLAB steady-state/calibration/simulation routines**, and supporting
**Excel inputs**.

This is the public, operational companion to two GIZ/IWH reports:

- **[IWH Technical Report](docs/reports/IWH_Technical_Report.docx)** — model structure,
  calibration, data sources, solution method, and scenario design.
- **[IWH Macro Impact Assessment](docs/reports/IWH_Report_Macro_Impact_Assessment_revised.docx)**
  — policy findings on energy efficiency, green finance, and carbon pricing.

**Reproducing a report figure or table?** Start at
[docs/reference/report_replication.md](docs/reference/report_replication.md), which maps every
figure/table in both reports to the exact scenario, script, and output file that produces it.

## Documentation

**New to the model?** Start here:
- [What is DGE-METRIC?](docs/overview.md) — plain-language overview, agent structure, policy questions
- [Vietnam energy transition context](docs/vietnam_context.md) — PDP8, net-zero targets, financing gap
- [Scenarios at a glance](docs/scenarios_overview.md) — all scenario families in one table

**Use cases with results:**
- [Energy Efficiency scenarios](docs/use_cases_ee.md) — EE_Dir10_full(_NoBESS), EE_RTS_prerev_95GW
- [Green Finance scenarios](docs/use_cases_finance.md) — GF_A/B/C, WACC and GDP effects

**Technical reference** (see [docs/index.md](docs/index.md) for the full index):
- [Model architecture](docs/reference/model.md)
- [Scenario design](docs/reference/scenario.md)
- [Calibration](docs/reference/calibration.md)
- [Running the model](docs/reference/running.md)
- [Report replication guide](docs/reference/report_replication.md)
- [Reproducibility checklist](docs/reference/reproducibility_checklist.md)

---

## What's in this repository?

At a high level, we use:

- **Dynare** to define and solve the dynamic model (`.mod`).
- **MATLAB** to compute/calibrate the steady state, assemble parameters, and run scenario workflows.
- **Excel** files as curated inputs/assumptions (calibration, baseline, and scenario workbooks).

## Repository structure (quick map)

- `DGE_Model.mod` — canonical Dynare entry point; `DGE_Model_steadystate.m` — steady-state dispatcher.
- `RunSimulations.m`, `setup_paths.m` — scenario batch runner and MATLAB/Dynare path setup.
- `ModFiles/` — hand-maintained Dynare declarations, parameters, and equations (`Equations/`,
  with a human-readable mirror in `Equations/Equations_display/`).
- `Functions/` — MATLAB implementation: `SteadyState/`/`steady_state/` (calibration and steady
  state), `Miscellaneous/` (Excel I/O, model setup, diagnostics, plotting), `Welfare/`.
- `ExcelFiles/` — calibration/baseline/scenario workbooks (`*_replication.xlsx`) and
  `ScenarioPathDefinition.xlsx`; `Output/` holds generated scenario CSVs (gitignored).
- `scripts/` — `maintenance/` (workbook rebuild helpers) and `reporting/` (figure/table generators).
- `docs/` — documentation hub; see [docs/index.md](docs/index.md). `docs/reports/` holds the two
  IWH report documents this repo supports.
- `Figures/` — baseline validation charts exported by `scripts/reporting/display_baseline_energy.m`.
- `Training/` — standalone teaching material (RBC replication, toy Dynare model); not part of the
  production run path.

Generated/derived content — never hand-edit, and not tracked in git: `+DGE_Model/`, `DGE_Model/`,
`*_dynamic.m`, `*_static.m`, `DGE_Model.log`, `ExcelFiles/Output/`, `structScenarioResults*.mat`.

## Reproducing the reports

New to the model or running on a fresh clone? Start with `RunSimulationsEasy` — it checks your
MATLAB/Dynare environment and the workbooks before running anything, with actionable errors
instead of a mid-run crash:

```matlab
RunSimulationsEasy
```

For the full reproduction (`RunSimulations.m` defaults to the `ReportReplication` scenario group,
18 scenarios) once your environment is confirmed working:

```matlab
setup_paths
RunSimulations
```

See [docs/reference/report_replication.md](docs/reference/report_replication.md) for the full
recipe (environment-variable overrides, which `scripts/reporting/*` script produces which figure)
and [docs/reference/reproducibility_checklist.md](docs/reference/reproducibility_checklist.md) for
the run-validation checklist used to sign off a reproduction run.
