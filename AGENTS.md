# AGENTS.md

Repository-wide instructions for chat/code assistants.

## Scope

These rules apply to any assistant editing this repository (Claude, Copilot, Cursor, etc.).
If a tool-specific instruction file exists, it should not contradict this file.

## Core rules

- Treat generated Dynare outputs as non-source and do not hand-edit them: `+DGE_Model/`, `DGE_Model/`, `*_dynamic.m`, `*_static.m`, `*_set_auxiliary_variables.m`.
- Make source changes in `DGE_Model.mod`, `ModFiles/`, `Functions/`, `scripts/`, `docs/`, and input workbooks under `ExcelFiles/`.
- Do not edit `ExcelFiles/Output/` artifacts manually; regenerate from model runs.
- Preserve file-local MATLAB style conventions (camelCase in legacy files, snake_case in refactored steady-state files).
- When changing macro switches/sector-region counts in `DGE_Model.mod`, assume downstream workbook names and index maps change; prefer full rerun over patching generated outputs.
- Keep implementation planning docs in `docs/implementation_plans/`.
- Baseline-only endogenous targets (a variable that floats to hit a calibration target in Baseline but is ordinary exogenous input elsewhere, e.g. `EE_reg`/`Q_fossil`, `tauCEndo`/`G_reg`): reuse an existing compile-time indicator already correlated with Baseline (e.g. `lEndogenousY_p`, which `change_mod_file.m` always sets in lockstep with `BaselineScenario`) instead of adding a new parameter; branch with a runtime multiplier inside one equation, not `@#if`/`@#else`; free the variable only inside the hybrid steady-state solver (`lCalibration_p == 2`, add to `build_initial_guess.m` and a matching `fval_vec_*` residual together); transfer the solved Baseline path to other scenarios via `apply_baseline_shock_structure`, matching the transfer formula to the equation's functional form. The full template and worked history are in `CLAUDE.md` in the framework repository ([schultkr/DGE-METRIC](https://github.com/schultkr/DGE-METRIC)); this repository has no `CLAUDE.md`.

## Verification expectations

- Baseline quality means: steady-state convergence, accounting identities hold, and growth-audit CSVs are consistent with Excel targets.
- Prefer extending existing checks (`scripts/analysis/check_results.m`, `Functions/steady_state/diagnostics/check_allocation_errors.m`) over creating parallel diagnostics.

## Maintenance workflow

Follow [CONTRIBUTING.md](CONTRIBUTING.md). In short:

- Before editing: read `README.md`, `CONTRIBUTING.md`, `CITATION.cff`, and the latest `CHANGELOG.md` entry; decide whether the task affects this repository, the framework repository, or both; classify the Technical Report impact using [docs/maintenance/report_repository_consistency.md](docs/maintenance/report_repository_consistency.md); decide whether the change could alter numerical results.
- During editing: preserve canonical terminology ("DGE-METRIC", "DGE-METRIC — Viet Nam", "Viet Nam" in prose) and the reciprocal repository links; keep operational instructions in `docs/reference/running.md` and `docs/reference/report_replication.md` only; add no personal paths or undocumented `DGE_*` environment variables; keep scientific, path/structure, and presentation changes in separate commits.
- After editing: run `python scripts/ci/check_repository.py`; run the smallest relevant validation and report exactly what was run; update `CHANGELOG.md` when public behavior, structure, or scientific content changes; update the Technical Report or record why no update is needed.
- End every task with the completion note: files changed, what improved, scientific impact ("No intended numerical/model impact" or what changed), Technical Report impact, validation performed (only checks actually run), remaining work.

## Documentation hygiene

- Keep links in `docs/index.md` valid after moving or renaming docs.
- Keep this file aligned with `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md` in the framework repository when shared rules change.
