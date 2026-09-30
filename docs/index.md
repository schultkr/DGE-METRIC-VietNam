# DGE-METRIC — Viet Nam Documentation

DGE-METRIC (**D**ynamic **G**eneral **E**quilibrium for **M**acroeconomic **E**nergy **T**ransition **I**ncorporating **C**arbon **M**arkets) is a multi-sector macroeconomic model for evaluating energy transition pathways, green finance instruments, and carbon-pricing policies. This documentation covers the **Viet Nam implementation**. The common model architecture lives in the framework repository [DGE-METRIC](https://github.com/schultkr/DGE-METRIC). See the [README](../README.md) for the model family and quick start.

---

## New to the model? Start here

1. [What is DGE-METRIC?](overview.md) — plain-language overview, agent structure, policy questions
2. [Viet Nam energy transition context](vietnam_context.md) — PDP8, net-zero targets, the financing gap
3. [Scenarios at a glance](scenarios_overview.md) — all scenario families in one table

**Use cases with results:**
- [Energy Efficiency scenarios](use_cases_ee.md) — `EE_Dir10_full`, `EE_Dir10_full_NoBESS`, `EE_RTS_prerev_95GW`
- [Green Finance scenarios](use_cases_finance.md) — GF_A/B/C, WACC and GDP effects

---

## Reports this repo supports

- **[IWH Technical Report](reports/IWH_Technical_Report.pdf)** — model structure, calibration,
  data sources, solution method, scenario design.
- **[IWH Macro Impact Assessment](reports/IWH_Report_Macro%20Impact%20Assessment.pdf)** —
  policy findings on energy efficiency, green finance, and carbon pricing.
- **[Report replication guide](reference/report_replication.md)** — every report figure/table
  mapped to its scenario, script, and output file; start here to reproduce a specific result.
- **[Reproducibility checklist](reference/reproducibility_checklist.md)** — run-validation
  template to fill in and archive alongside a reproduction run.

---

## Technical reference

- [Model architecture and equations](reference/model.md)
- [Scenario design and implementation](reference/scenario.md)
- [Calibration workflow](reference/calibration.md)
- [Running the model](reference/running.md)
- [Calibration data sources](reference/data_sources.md)
- [Environment variables](reference/running.md#environment-variables)
- [Structural parameters source audit](reference/structural_parameters_source_audit.md)

---

## Scenario-specific docs

- [Energy efficiency scenario design](ee_scenario_design.md)
- [EE simulation results](ee_simulation_scenarios_results.md)
- [Green finance instruments feasibility](scenario_notes/finance_instruments_comments_feasibility.md)
- [Grid investment scenario design](grid_investment_scenario_design.md)

---

## Implementation plans

- [Capital targeting trial and error](implementation_plans/capital_targeting_trial_and_error.md)

---

## Maintenance

- [Contributing guide](../CONTRIBUTING.md): canonical terminology, maintenance rules, Technical Report impact classification
- [Changelog](../CHANGELOG.md)
- [Repository–report consistency matrix](maintenance/report_repository_consistency.md): where the code and the Technical Report must agree
- [Repository audit, first improvement cycle (2026-09)](maintenance/repository_audit.md): discrepancies, proposed renames, pending decisions

---

## Repository map

- `RunSimulationsEasy.m`: recommended first entry point (guided run with environment checks).
- `DGE_Model.mod`: Dynare model entry file.
- `RunSimulations.m`: batch scenario runner.
- `DGE_Model_steadystate.m`: steady-state function used by the model workflow.
- `setup_paths.m`: adds MATLAB/Dynare paths.
- `Functions/`: steady-state, simulation, model setup, and Excel helpers.
- `ModFiles/`: model declarations, equations, parameters, and LaTeX output includes.
- `ExcelFiles/`: calibration/baseline/scenario workbooks and output files.
- `scripts/maintenance/`: workbook maintenance scripts.
- `scripts/ci/`: repository checks run by CI.
- `Training/`: training assets and calibration resources.

## Important Notes

- Current scenario execution defaults are defined in `RunSimulations.m`.
- Current calibration workbook generation logic is in `Functions/Miscellaneous/Excel/create_calibration_excel_file.m`.
