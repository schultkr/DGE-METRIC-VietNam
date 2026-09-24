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
- Baseline-only endogenous targets (a variable that floats to hit a calibration target in Baseline but is ordinary exogenous input elsewhere, e.g. `EE_reg`/`Q_fossil`, `tauCEndo`/`G_reg`): reuse an existing compile-time indicator already correlated with Baseline (e.g. `lEndogenousY_p`, which `change_mod_file.m` always sets in lockstep with `BaselineScenario`) instead of adding a new parameter; branch with a runtime multiplier inside one equation, not `@#if`/`@#else`; free the variable only inside the hybrid steady-state solver (`lCalibration_p == 2`, add to `build_initial_guess.m` and a matching `fval_vec_*` residual together); transfer the solved Baseline path to other scenarios via `apply_baseline_shock_structure`, matching the transfer formula to the equation's functional form. See `CLAUDE.md` for the full template and worked history.

## Verification expectations

- Baseline quality means: steady-state convergence, accounting identities hold, and growth-audit CSVs are consistent with Excel targets.
- Prefer extending existing checks (`scripts/analysis/check_results.m`, `Functions/steady_state/diagnostics/check_allocation_errors.m`) over creating parallel diagnostics.

## Documentation hygiene

- Keep links in `docs/index.md` valid after moving or renaming docs.
- Keep this file, `CLAUDE.md`, and `.github/copilot-instructions.md` aligned when shared rules change.
