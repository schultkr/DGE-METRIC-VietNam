# Repository Structure Guide

This guide documents how to navigate the repository and where to place changes without altering model behavior.

## Top-Level Layout

- DGE_Model.mod: canonical Dynare entry point.
- ModFiles/: hand-maintained Dynare blocks and declarations.
- Functions/: MATLAB source for calibration, steady state, simulation, Excel I/O, and diagnostics.
- scripts/: operational scripts grouped by purpose.
  - scripts/analysis/
  - scripts/maintenance/
  - scripts/reporting/
- ExcelFiles/: input workbooks and scenario assumptions.
- docs/: policy and technical documentation. See [docs/index.md](docs/index.md) for the full map;
  subfolders are `policy/`, `reference/`, `scenario_notes/`, `reports/`, `implementation_plans/`,
  `dev/`, `presentations/`, `figures/`, `exports/`.
- Figures/: exported visuals.
- Training/: standalone learning material (non-production runtime path).
- Archive/: historical or legacy material.

## Source vs Generated

Treat these as source (edit here):
- DGE_Model.mod
- ModFiles/
- Functions/
- scripts/
- docs/
- ExcelFiles/ input workbooks

Treat these as generated or local outputs (do not hand-edit):
- +DGE_Model/
- DGE_Model/
- *_dynamic.m, *_static.m, *_set_auxiliary_variables.m
- ExcelFiles/Output/
- transient caches and logs

## Root Hygiene Policy

Keep the repository root minimal:
- Canonical entry points and governance only.
- Avoid temporary artifacts in root.
- Keep local backup folders ignored.

## Runner Conventions

Canonical runners:
- RunSimulations.m
- RunSimulations_Sensitivity.m

Variant runners should be clearly marked as experimental and documented before broader use.

## Contributor Checklist

Before commit:
1. Confirm edits are in source folders only.
2. Confirm generated outputs are not hand-edited.
3. Confirm docs links still resolve after moves/renames.
4. Confirm temporary/local folders are ignored.
