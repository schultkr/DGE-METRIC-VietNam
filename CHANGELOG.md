# Changelog

All notable changes to **DGE-METRIC — Viet Nam** are recorded here. Each entry states its
Technical Report impact (see [CONTRIBUTING.md](CONTRIBUTING.md#technical-report-impact)).
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions follow the
release tags that the Technical Report cites.

## [Unreleased]

First public-repository improvement cycle
([audit](docs/maintenance/repository_audit.md)).
**Scientific impact:** no intended numerical/model impact.

### Added
- `CONTRIBUTING.md` with canonical terminology, maintenance rules, and the mandatory Technical
  Report impact classification.
- `CHANGELOG.md` (this file).
- `docs/maintenance/`: repository and Technical Report audit, and the repository–report
  consistency matrix.
- `.github/`: pull-request template with a *Technical Report impact* field, issue templates, and a
  lightweight CI workflow (`scripts/ci/check_repository.py`) that checks links, `CITATION.cff`,
  expected entry points, and forbidden generated artifacts. The CI does not run the model.
- `setup_paths.m`: `DGE_DYNARE_PATH` environment variable, detection of a Dynare already on the
  MATLAB path, and macOS/Linux install locations. Tested versions 7.0 and 6.1 are still tried
  first, so existing machines pick the same Dynare as before.
  *TR impact: Repository-path references (§2.4, additive).*

### Changed
- README: model-family introduction, reciprocal link to the framework repository, badges,
  model-family and workflow diagrams, and `RunSimulationsEasy` as the recommended first entry
  point. *TR impact: None.*
- `docs/index.md`: maintenance section, scenario names aligned with `RunSimulations.m`.
- Assistant-instruction housekeeping: references now point to the framework repository template.
- `.gitignore`: LaTeX build files, Python caches, lock files, dated workbook backups.
- Workbook creation harmonized with the framework repository: `build_all_workbooks.m` (seeds
  missing canonical workbooks from `*_replication_fix.xlsx`; `DGE_PROMOTE_BASELINE` replaced by
  `DGE_SEED_CANONICAL_FROM_REPLICATION_FIX`), `update_nz_sheet.m`, the
  `Functions/Miscellaneous/Excel/create_*`/`update_data_excel.m` builders (canonical filenames,
  `etaIA_*_p = 0.1` to match the published calibration workbook), `ScenarioPathDefinition.xlsx`,
  and `RunSimulationsEasy.m`. `compute_pdp8_capital_investment_ratio.m` now uses a bracketed
  `fzero` in place of `fsolve`. *TR impact: None.*
- `RunSimulations.m`: the `ReportReplication` group again runs all 18 scenarios listed in
  `docs/reference/report_replication.md` (four NZ-based EE/RTS variants were commented out).
  *TR impact: None.*

### Removed
- LaTeX build byproducts under `docs/figures/model_diagrams/` and `docs/presentations/`, and
  `__pycache__` files, are no longer tracked (the files remain on disk).

### Fixed
- Restored the canonical `ExcelFiles/Model*5Sectorsand1Regions.xlsx` workbooks, which the previous
  clean-up removed although `RunSimulations.m` reads them. They are byte-identical copies of the
  newly tracked `*_replication_fix.xlsx` set that produced `docs/figures/`, which is also identical
  to the framework repository's set. *TR impact: None.*
- Broken figure and report links in `docs/reference/model.md`, `docs/reference/scenario.md`,
  `docs/reference/baseline_scenario_manual.md`, `docs/use_cases_ee.md`, `docs/use_cases_finance.md`.

## [1.0.0] — 2026-06-09

Initial public release accompanying the IWH Technical Report and the IWH Macro Impact Assessment.
