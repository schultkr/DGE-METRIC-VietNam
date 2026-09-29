# Repository–Report Consistency Matrix

The [IWH Technical Report](../reports/IWH_Technical_Report.docx) is the stable methodological
reference. This repository is the versioned executable implementation. This page records, for
each concept both of them describe, which side is authoritative and how the two stay in sync.

**Use it on every change.** Find the rows your change touches, apply the sync rule, and state the
result in the PR's *Technical Report impact* field (see [CONTRIBUTING.md](../../CONTRIBUTING.md)).

- **Report pinned to:** *not yet pinned*. The TR (30.09.2026 draft) cites `schultkr/DGE-METRIC`
  at commit `619b45a`; see [audit D1](repository_audit.md#2-discrepancy-list-repository-vs-technical-report).
  Once a release is tagged, record it here as `vX.Y.Z (commit …)`.
- **Last reviewed:** 2026-09-29, against `DGE-METRIC-VietNam` commit `31abfff`.

## Matrix

| Concept | Report reference | Repository authority | Sync rule | Status (2026-09-29) |
|---|---|---|---|---|
| Model name and scope | Cover, Abbreviations, Executive Summary, §1–3 | `README.md`, `CITATION.cff`, `DGE_Model.mod` | Terminology and model definition must match. | ⚠ Three long-form expansions in circulation ([D2](repository_audit.md)) |
| Model family and repository roles | §2 intro | `README.md` (both repositories) | Report names the repository and release it was verified against. | ⚠ TR cites the private framework repository ([D1](repository_audit.md)) |
| Repository structure | §2.2 | Actual file tree; `REPO_STRUCTURE.md` | Update the report when public paths change, or pin it to the older release. | ✓ Paths in §2.2 exist; minor wording ([D8](repository_audit.md)) |
| Documentation navigation | §2.3 | `docs/index.md` | Named pages must exist at the stated paths. | ✓ Pages exist; duplicates pending ([D7](repository_audit.md)) |
| Run instructions | §2.4 | [`docs/reference/running.md`](../reference/running.md), [`docs/reference/report_replication.md`](../reference/report_replication.md), `RunSimulations.m`, `RunSimulationsEasy.m`, `setup_paths.m` | Commands, entry points, and `DGE_*` environment variables must remain current. | ⚠ Workbook default suffix ([D3](repository_audit.md)); `RunSimulationsEasy`, `DGE_DYNARE_PATH` not yet in TR ([D4, D6](repository_audit.md)) |
| Run-validation checklist | §2.4, Table 1 | [`docs/reference/reproducibility_checklist.md`](../reference/reproducibility_checklist.md) | Both lists contain the same checks. | ✓ Same checks; ⚠ its workbook-default wording is part of [D3](repository_audit.md) |
| Workbook pipeline | §2.4 | [`docs/scenario_notes/workbook_creation_procedure.md`](../scenario_notes/workbook_creation_procedure.md), `scripts/maintenance/create_*` | Script names and dependency order must match. | ✓ Scripts named in §2.4 exist |
| Calibration | §4 | Active calibration workbook + `Functions/SteadyState/`, `Functions/steady_state/` | Values and procedures must be scientifically consistent. | Not re-verified this cycle |
| Scenario framework | §5 | Scenario workbook sheets, `scenarioGroups` and the scenario-switch block in `RunSimulations.m` | Names, dependencies (Baseline/NZ reference), and closures (cap-and-trade) must match. | ⚠ Scenario names differ across docs ([D10, D15](repository_audit.md)) |
| Solution method | §6 | `DGE_Model.mod`, `ModFiles/`, `DGE_Model_steadystate.m` | Methodological consistency required. | Not re-verified this cycle |
| Figures and reported results | §4–5 | `scripts/reporting/`, [`report_replication.md`](../reference/report_replication.md), archived run metadata | Regenerate when result-producing code changes. | Not re-verified this cycle |
| Citation | Cover, References | `CITATION.cff` | Title, authors, and version agree with the release cited by the report. | ⚠ Depends on D1/D2 |

✓ consistent · ⚠ known discrepancy (see the audit) · "Not re-verified" means no check was run
this cycle; it is **not** a claim of consistency.

## Impact classification

| Change type | Repository examples | Technical Report action |
|---|---|---|
| **Visual only** | README styling, badges, topics, About text | Usually none, provided terminology and claims do not change. |
| **Operational / path** | Folder or script rename, new setup command, new or changed environment variable, new entry point | Update every affected path or instruction in the TR, or pin the TR explicitly to an older release. |
| **Scenario / calibration** | Scenario definition, baseline logic, workbook inputs, calibration procedure | Update the relevant TR sections in §4–5; rerun validation. |
| **Scientific / numerical** | Equations, closure, solution method, output construction, calibration values | Update the TR, regenerate affected results/figures, document before/after validation. |

The PR field takes one of: `None` / `Editorial` / `Repository-path references` /
`Scenario-calibration` / `Methodology` / `Results-regeneration`, plus the affected TR sections when
it is not `None`.

## Change log of this matrix

| Date | Change | TR impact recorded |
|---|---|---|
| 2026-09-29 | Matrix created during the first improvement cycle ([audit](repository_audit.md)). `DGE_DYNARE_PATH` added (operational, additive). | Repository-path references: TR §2.4 should mention it at the next editorial pass. |
