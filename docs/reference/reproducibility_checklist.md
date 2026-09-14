# Reproducibility Checklist

A filled-in instance of this checklist is the run-validation record referenced by the IWH
Technical Report's Table 1 ("Scenario run-validation and reproducibility checklist"). Complete
one copy per reproduction run intended to back a published figure, table, or claim, save it
(e.g. `docs/reference/reproducibility_runs/<date>-<short-description>.md`), and link it from the
report or issue it supports.

## Run identification

- **Date:** _____
- **Repository commit / tag:** _____ (`git rev-parse HEAD` and `git describe --tags`)
- **MATLAB version:** _____
- **Dynare version:** _____
- **Operating system:** _____

## Workbook and scenario selection

- **`DGE_WORKBOOK_VERSION`** (blank = default `_replication`): _____
- **Resolved workbook filenames** (calibration / baseline / scenarios): _____
- **`DGE_SCENARIO_GROUPS`** or **`DGE_SCENARIO_NAMES`** used: _____
- **Full ordered scenario list actually run:** _____ (should match
  `docs/reference/report_replication.md`'s `ReportReplication` group for a full reproduction)

## Reference dependency

- [ ] `Baseline` solved (or loaded from `structScenarioResults*.mat`) before any scenario using it
- [ ] `NZ` solved (or loaded) before any NZ-dependent scenario
- **Source of the reference state:** ☐ solved this run ☐ loaded from saved structure: _____

## Numerical convergence

- [ ] Steady-state solver (`fsolve`) residuals near zero for every scenario
- [ ] Perfect-foresight solver converged for every scenario (no `dynare` errors caught and
      swallowed by `RunSimulations.m`'s try/catch — check the console log, not just "no crash")
- **Maximum steady-state residual:** _____
- **Maximum perfect-foresight residual:** _____
- **Tolerances used:** _____

## Accounting and allocation diagnostics

- [ ] `Functions/steady_state/diagnostics/check_allocation_errors.m` run, no unexplained
      discrepancies
- [ ] `scripts/analysis/check_results.m` run
- [ ] `ExcelFiles/README.md` accounting identities hold (row sums, `phiQI = phiX + phiY0`,
      Trade_Flows rows sum to 1)
- **Maximum discrepancy found:** _____

## Growth-target alignment

- [ ] Simulated growth compared against the active workbook's `gY_*` targets over the full horizon
- **Audit file:** _____
- **Maximum deviation:** _____ / **Accepted threshold:** _____

## Outputs and plausibility

- [ ] All 18 `ExcelFiles/Output/*_replication.csv` files present and non-empty
- [ ] `Figures/baseline_*` regenerated (`display_baseline_energy.m`)
- [ ] `docs/figures/EE_Simulation_Results/`, `Finance_Simulation_Results/`,
      `EE_NZ_Simulation_Results/`, `NZ_Simulation_Results/` regenerated and spot-checked against
      `docs/reference/report_replication.md`
- [ ] No missing, infinite, or unexplained discontinuous values in any output series
- **Plausibility notes:** _____

## Sign-off

- **Disposition:** ☐ Pass ☐ Pass with documented caveats ☐ Fail
- **Reviewer:** _____
- **Caveats (if any):** _____
