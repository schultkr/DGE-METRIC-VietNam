# Contributing to DGE-METRIC — Viet Nam

This repository is the **calibrated Viet Nam implementation** of the DGE-METRIC model family. The
[IWH Technical Report](docs/reports/IWH_Technical_Report.docx) is the stable methodological
reference, and this repository is the versioned executable implementation. Contributions must keep
the two in sync.

> **Primary rule:** presentation can evolve quickly; scientific behavior changes only deliberately,
> with validation and synchronized documentation.

Assistant-specific rules (Claude, Copilot, Cursor) are in [AGENTS.md](AGENTS.md) and apply to
human contributors as well.

## Canonical terminology

Use these terms consistently in code comments, documentation, PRs, and the Technical Report.

| Term | Meaning |
|---|---|
| **DGE-METRIC** | The model family and the framework repository [`schultkr/DGE-METRIC`](https://github.com/schultkr/DGE-METRIC). Long form: *Dynamic General Equilibrium for Macroeconomic Energy Transition Incorporating Carbon Markets* (pending author sign-off, see [audit D2](docs/maintenance/repository_audit.md)). |
| **DGE-METRIC — Viet Nam** | This repository: the country implementation with Viet Nam inputs, scenarios, replication workflows, training material, and report-linked outputs. |
| **Framework** | The common model architecture and reusable components. |
| **Country implementation** | A calibrated application of the framework to one economy. |
| **Scenario** | A named, runnable experiment: one sheet in the scenario workbook, registered in `RunSimulations.m`, with a defined reference (`Baseline` or `NZ`) and closure. |
| **Calibration data** | The active workbooks under `ExcelFiles/` and the inputs they are built from. |
| **Simulation output** | Files a run writes (`ExcelFiles/Output/`, `*.mat`, Dynare folders). These are generated and never hand-edited. |
| **Reporting layer** | `scripts/reporting/` and the figures and tables it produces from simulation output. |

Spelling: **"Viet Nam"** in prose. `VietNam` appears only in the repository slug and existing file
names.

## Before editing

1. Read [README.md](README.md), this file, [CITATION.cff](CITATION.cff), and the latest
   [CHANGELOG.md](CHANGELOG.md) entry.
2. Decide whether the change affects the framework repository, this repository, or both.
3. Check the [repository–report consistency matrix](docs/maintenance/report_repository_consistency.md)
   and classify the **Technical Report impact** (see below).
4. Decide whether the change could alter numerical results or reproducibility.

## During editing

- **Preserve scientific behavior.** Do not change equations, calibration values, scenario meaning,
  or result construction for stylistic reasons.
- Edit source only: `DGE_Model.mod`, `ModFiles/`, `Functions/`, `scripts/`, `docs/`, input workbooks
  in `ExcelFiles/`. Never hand-edit generated Dynare output (`+DGE_Model/`, `DGE_Model/`,
  `*_dynamic.m`, `*_static.m`, `*_set_auxiliary_variables.m`) or `ExcelFiles/Output/`.
- Keep operational instructions in **one canonical place**:
  [docs/reference/running.md](docs/reference/running.md) (setup and scenario selection) and
  [docs/reference/report_replication.md](docs/reference/report_replication.md) (report
  reproduction). Link to them rather than copying them.
- Do not introduce personal paths, machine-specific defaults, undocumented environment variables,
  or untracked scientific assumptions. New environment variables use the `DGE_` prefix and are
  documented in `running.md`.
- Keep scientific changes, path/structure changes, and presentation changes in **separate
  commits**, and separate PRs where possible.
- Preserve file-local MATLAB style: camelCase in legacy files, snake_case in refactored
  steady-state files. Rename opaque variables only in code you are already changing.
- Improve incrementally: documentation and presentation first, then directory renames and
  architecture refactors. Propose renames in an issue before executing them.

## After editing

- Check Markdown links, file paths, capitalization, code examples, and environment-variable names.
  `python scripts/ci/check_repository.py` runs the same checks as CI.
- Run the **smallest relevant validation** and report exactly what was run. Baseline quality means
  steady-state convergence, accounting identities that hold, and growth-audit CSVs consistent with
  the Excel targets. Extend `scripts/analysis/check_results.m` and
  `Functions/steady_state/diagnostics/check_allocation_errors.m` rather than adding parallel
  diagnostics.
- Update [CHANGELOG.md](CHANGELOG.md) when public behavior, structure, or scientific content
  changes.
- Update the Technical Report, or record in the PR why no update is required.
- Check the [framework repository](https://github.com/schultkr/DGE-METRIC) for contradictions the
  change introduces.

## Technical Report impact

Every PR states one of these values. The PR template asks for it.

| Value | Use when | Report action |
|---|---|---|
| `None` | Visual only: styling, badges, topics, About text, with no change to claims | none |
| `Editorial` | Wording, naming, or spelling that the TR also uses | Queue for the next editorial pass |
| `Repository-path references` | Folder/script renames, new entry points, setup commands, environment variables | Update TR §2 paths/instructions, or pin the TR to an older release |
| `Scenario-calibration` | Scenario definitions, baseline logic, workbook inputs, calibration procedure | Update TR §4–5; rerun validation |
| `Methodology` | Equations, closure, solution method | Update TR §3/§6; document before/after validation |
| `Results-regeneration` | Anything that changes reported numbers or figures | Regenerate results/figures via `scripts/reporting/`; update the TR |

When the value is not `None`, list the affected TR sections and add a row to the change log in the
[consistency matrix](docs/maintenance/report_repository_consistency.md).

## Completion note

Close every PR (and every assistant task) with:

- **Files changed**
- **What improved**
- **Scientific impact**: either "No intended numerical/model impact" or a precise description of
  what changed
- **Technical Report impact**: the value above and the sections affected
- **Validation performed**: only checks that were actually run. Never imply numerical
  equivalence was verified if it was not.
- **Remaining work**

## Releases

The Technical Report must cite an explicit release or commit. Tag a release (`vX.Y.Z`) whenever
report-cited results are produced. Record the tag in the consistency matrix and `CITATION.cff`
(`version`, `date-released`). Expensive numerical reproduction is validated at release time with
the [reproducibility checklist](docs/reference/reproducibility_checklist.md), not on every commit.

## Reporting problems

Open an issue using the templates provided. For a run failure, include the MATLAB and Dynare
versions, the commit, all `DGE_*` environment variables, and the console log.
