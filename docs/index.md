# DGE-METRIC Documentation

DGE-METRIC (**D**ynamic **G**eneral **E**quilibrium for **M**acroeconomic **E**nergy **T**ransition **I**ncorporating **C**arbon markets) is a multi-sector macroeconomic model for evaluating energy transition pathways, green finance instruments, and carbon-pricing policies — applied to Vietnam.

---

## New to the model? Start here

1. [What is DGE-METRIC?](overview.md) — plain-language overview, agent structure, policy questions
2. [Vietnam energy transition context](vietnam_context.md) — PDP8, net-zero targets, the financing gap
3. [Scenarios at a glance](scenarios_overview.md) — all scenario families in one table

**Use cases with results:**
- [Energy Efficiency scenarios](use_cases_ee.md) — EE_PDP8, EE_Directive10, BESS counterfactuals
- [Green Finance scenarios](use_cases_finance.md) — GF_A/B/C, WACC and GDP effects

---

## Technical reference

- [Model architecture and equations](reference/model.md)
- [Scenario design and implementation](reference/scenario.md)
- [Calibration workflow](reference/calibration.md)
- [Running the model](reference/running.md)
- [Calibration data sources](reference/data_sources.md)
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

## Repository map

- `DGE_Model.mod`: Dynare model entry file.
- `RunSimulations.m`: batch scenario runner.
- `DGE_Model_steadystate.m`: steady-state function used by the model workflow.
- `setup_paths.m`: adds MATLAB/Dynare paths.
- `Functions/`: steady-state, simulation, model setup, and Excel helpers.
- `ModFiles/`: model declarations, equations, parameters, and LaTeX output includes.
- `ExcelFiles/`: calibration/baseline/scenario workbooks and output files.
- `scripts/maintenance/`: workbook maintenance scripts.
- `Training/`: training assets and calibration resources.

## Important Notes

- Current scenario execution defaults are defined in `RunSimulations.m`.
- Current calibration workbook generation logic is in `Functions/Miscellaneous/Excel/create_calibration_excel_file.m`.
