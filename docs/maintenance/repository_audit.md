# Repository and Technical Report Audit — first improvement cycle

**Audit date:** 2026-09-29
**Scope:** `schultkr/DGE-METRIC-VietNam` (commit `31abfff` plus the uncommitted working tree of
that date), `schultkr/DGE-METRIC` (commit `f81b602`), and the Technical Report
[`docs/reports/IWH_Technical_Report.docx`](../reports/IWH_Technical_Report.docx) (dated 30.09.2026).
**Plan implemented:** *DGE-METRIC Public Repository Improvement and Maintenance Plan*, Section 9
("Suggested first work package").

This page is the working record of the first cycle. The standing rules that come out of it live in
[CONTRIBUTING.md](../../CONTRIBUTING.md) and
[report_repository_consistency.md](report_repository_consistency.md). This page is dated evidence,
so do not keep it up to date; start a new audit page for the next cycle.

---

## 1. Inventory

| Item | DGE-METRIC — Viet Nam | DGE-METRIC (framework) |
|---|---|---|
| GitHub visibility | **Public** | **Private** |
| GitHub About text / topics | empty / none | description set / none |
| README | Viet Nam–specific; links to both IWH reports | Viet Nam–specific policy narrative; links to `docs/reports/*.md` that are not in the Viet Nam repo |
| CITATION.cff | same title and version (1.0.0) as framework, `repository-code` → Viet Nam repo | same, `repository-code` → framework repo |
| LICENSE | MIT | MIT |
| CONTRIBUTING / CHANGELOG | absent (added this cycle) | absent (added this cycle) |
| `.github/` | absent (added this cycle) | assistant-instruction file only |
| Framework assistant template | **absent** in this repo, present in framework | present |
| Entry points | `RunSimulationsEasy.m`, `RunSimulations.m`, `setup_paths.m`, `DGE_Model.mod` | same, plus `RunSimulations_Sensitivity*.m` |
| Default workbook suffix in `RunSimulations.m` | `''` (unsuffixed) | `'_replication_fix'` |
| Workbooks present | `_replication` only (unsuffixed and `_check` sets deleted in the uncommitted working tree) | `_replication`, `_replication_fix` |
| Environment variables | `DGE_WORKBOOK_VERSION`, `DGE_SCENARIO_GROUPS`, `DGE_SCENARIO_NAMES`, `DGE_EASY_SCENARIO_NAMES`, `DGE_INVESTMENT_TARGETS_CSV`, `DGE_INVESTMENT_TARGETS_IOTABLE_XLSX`, `DGE_DYNARE_PATH` (new) | same |
| Tracked generated artifacts | LaTeX build files and `__pycache__` (untracked this cycle); Dynare bytecode inside a Training bundle (kept, see §4) | `Archive/` (≈270 files), `ConflictBackups/`, `outputs/<uuid>/`, `ExcelFiles/Archive/`, `snippets1.txt`, dated workbook backups |
| Duplicate docs | 12 pages exist both at `docs/` root and in `docs/policy/`, `docs/reference/` or `docs/scenario_notes/` | same layout |

---

## 2. Discrepancy list: repository vs. Technical Report

Each item states the evidence, the proposed canonical form, and the risk class used in §5.

| # | Discrepancy | Evidence | Proposed resolution | Risk |
|---|---|---|---|---|
| D1 | TR §2 names **`schultkr/DGE-METRIC`** at commit `619b45a` as "the public GitHub repository", but that repository is private; the public one is `DGE-METRIC-VietNam`. | TR §2 intro; `gh repo view` | Decide which repository the TR pins. Recommended: pin the TR to a tagged release of `DGE-METRIC-VietNam` (it holds the reports and the replication workflow), or make the framework public before the TR is published. | High |
| D2 | Three long-form expansions of "DGE-METRIC". | TR cover: *"A Dynamic General Equilibrium Model for Vietnam's Energy Transition"*; TR abbreviations: *"Dynamic General Equilibrium Model for Vietnam's Energy Transition Incorporating Carbon Markets"*; TR §1, README, CITATION.cff: *"Dynamic General Equilibrium for Macroeconomic Energy Transition Incorporating Carbon markets/Markets"*. The framework README also says "DGE-CRED / DGE-METRIC variant". | Proposed canonical form (needs author sign-off): **Dynamic General Equilibrium for Macroeconomic Energy Transition Incorporating Carbon Markets**. It is already used in CITATION.cff and both READMEs and fits the acronym. The TR cover can keep its descriptive subtitle, but the abbreviation list must use the canonical expansion. | Medium (editorial, identity) |
| D3 | **Workbook default is inconsistent across code, docs, TR and the working tree.** | TR §2.4: default suffix `''` → unsuffixed workbooks. `RunSimulations.m` sets `sSensitivity = ''`, but its comment says the default is `"_replication"`. `RunSimulationsEasy.m` hard-codes the unsuffixed files. README says the workbooks are `*_replication.xlsx`. `report_replication.md` calls `_replication` "the earlier workbook variant". `reproducibility_checklist.md` says "blank = default `_replication`". The uncommitted working tree **deletes the unsuffixed workbooks**, so both entry points would fail on a fresh checkout if that deletion were committed. The framework defaults to `_replication_fix`. | Decide which workbook set is canonical for the published results, then align `RunSimulations.m`, `RunSimulationsEasy.m`, README, `report_replication.md` and TR §2.4 **in one commit**. Do not commit the workbook deletions until this is settled. | **High** (scenario/calibration, reproducibility) |
| D4 | TR §2.4 does not mention `RunSimulationsEasy.m`, the recommended first entry point. | TR §2.4; README | Add one paragraph to TR §2.4 (first-time users start with `RunSimulationsEasy`; `RunSimulations` for full reproduction). | Low (editorial) |
| D5 | Workstation-specific default paths: the GSO investment inputs default to `%USERPROFILE%\Dropbox\2025_GIZ_Vietnam\...`. | `RunSimulations.m` l.184–200 | Keep the env-var overrides, remove the Dropbox default, and document how to obtain the two input files. TR §2.4 already describes the overrides correctly. | Medium (operational; changes a run specification on the author's machine) |
| D6 | Dynare location was limited to `C:\dynare\7.0` / `6.1`. | `setup_paths.m` (before this cycle) | **Done:** `DGE_DYNARE_PATH`, detection of Dynare already on the path, macOS/Linux roots. Tested versions 7.0 and 6.1 are still preferred, so the default choice on existing machines is unchanged. The TR should mention `DGE_DYNARE_PATH` in §2.4 "Establish a controlled starting point". | Low (additive) |
| D7 | 12 documentation pages are duplicated between `docs/` root and subfolders. TR §2.3 acknowledges "related top-level technical pages remain available … for compatibility". | §1 inventory | Proposed rename in §3 (not executed). | Medium |
| D8 | TR §2.2 lists "MATLAB structures, logs" as repository result artifacts, but `*.mat` and logs are git-ignored. | TR §2.2; `.gitignore` | Editorial: say that such artifacts are produced locally and archived with a run, not tracked. | Low |
| D9 | Spelling is mixed: the TR uses "Vietnam" 31 times and "Viet Nam" 5 times; the docs use "Vietnam". The plan's canonical public spelling is **"Viet Nam"**. | TR text; docs | Use "Viet Nam" in public-facing prose (READMEs, TR body, CITATION abstract). Keep existing file names and the `VietNam` repository slug. Keep "Vietnam" as a search keyword. | Low (editorial) |
| D10 | Scenario names in navigation pages disagree: README lists `EE_Dir10_full(_NoBESS)`, `EE_RTS_prerev_95GW`; `docs/index.md` lists `EE_PDP8`, `EE_Directive10`. `RunSimulations.m` runs the former. | README, `docs/index.md`, `RunSimulations.m` | **Done in `docs/index.md`:** names aligned with `RunSimulations.m`. Remaining pages (`docs/use_cases_ee.md`, `docs/reference/running.md` group table) need a scenario-terminology pass. | Low |
| D11 | `REPO_STRUCTURE.md` lists `RunSimulations_Sensitivity*.m`, which the uncommitted working tree deletes. | `REPO_STRUCTURE.md` | Update when the deletion is committed. | Low |
| D12 | Assistant-instruction references pointed to files not present in this repository. | maintenance notes | **Done:** references now point to the framework repository template. | Low |
| D13 | TR cover logo is a *linked* image pointing to `G:\Kdl\Privat\Vorlagen\Logos\...`, which will not resolve on other machines. | pandoc extract of the TR | Embed the logo in the .docx. | Low (editorial) |
| D14 | The framework holds **three** versions of the Technical Report (`IWH_Technical_Report.docx`, `TECHNICAL_REPORT.md`, `TECHNICAL_REPORT_PERFECT.md`), and its README links the Markdown one. The Viet Nam repository holds only the .docx. | framework `docs/reports/` | Declare `IWH_Technical_Report.docx` in the Viet Nam repository as canonical. Link the framework README to it, and mark or remove the Markdown copies. | Medium (divergent copies of the methodological reference) |
| D15 | `docs/use_cases_ee.md` describes `EE_Directive10` as an "EU Directive 10 equivalent". TR §5.2 describes it as a *Prime Minister* directive, and the framework README calls it PM Directive 10/CT-TTg. The page also uses the older scenario names (see D10). | `docs/use_cases_ee.md` l.21–24 | Editorial correction during the scenario-terminology pass. | Low (editorial, but factually wrong) |
| D16 | `DGE_BASELINE_SHEETS` is set by `create_baseline_share_candidates.m`, `optimize_baseline_share_path.m` and `run_sensitivity_analysis.m`, but no runner reads it. `RunSimulations.m` ignores it, and the deleted `RunSimulations_Sensitivity.m` did not read it either, so the candidate-sheet sweeps run whatever `RunSimulations.m` selects. | `grep getenv`; `scripts/ci/check_repository.py` | Either wire it into `RunSimulations.m` (scenario selection) or remove it from the maintenance scripts. Documented as inert in `running.md` meanwhile. | Medium (operational; can silently run the wrong scenario set) |
| D17 | 28 `DGE_*` environment variables were read by code but not documented in the canonical run docs. | `scripts/ci/check_repository.py` | **Done:** full table in `docs/reference/running.md#environment-variables`; CI enforces it. | Low |

---

## 3. Proposed directory and file renames (not executed)

None of these renames were executed. Each one changes public paths, so each needs a Technical Report
check (TR §2.2–2.4 quote paths directly).

| Proposal | Rationale | TR impact | Risk |
|---|---|---|---|
| Replace the 12 duplicated `docs/*.md` root pages with one-line redirect stubs pointing at `docs/policy/`, `docs/reference/`, `docs/scenario_notes/` | Removes silent divergence between copies | §2.3 (navigation wording) | Medium |
| Move root `REPO_STRUCTURE.md` → `docs/maintenance/repository_structure.md`, leaving a root link in README | Root holds only entry points and governance | none (not cited) | Low |
| Move `docs/implementation_plans/`, `docs/dev/` behind a `docs/internal/` prefix, or exclude them from the public index | Visitors should not land on developer notes | §2.3 mentions `implementation_plans/` | Medium |
| Framework: move `Archive/`, `ConflictBackups/`, `outputs/<uuid>/`, `snippets1.txt` out of version control (to a GitHub release asset or delete) | Root no longer looks like a working directory | none | Low–Medium (history size unchanged; content leaves `main`) |
| Rename `Functions/SteadyState/` + `Functions/steady_state/` into one folder | Two casing conventions for one concept | §2.2 names both folders | **High** (touches the calibration pipeline; defer) |

---

## 4. Repository hygiene findings

- **Untracked this cycle (files kept on disk):** 26 LaTeX byproducts (`*.aux`, `*.log`, `*.nav`,
  `*.out`, `*.snm`, `*.toc`, `*.fls`, `*.fdb_latexmk`) under `docs/figures/model_diagrams/` and
  `docs/presentations/`, and 2 `__pycache__/*.pyc` files. `.gitignore` extended accordingly.
- **Kept deliberately:** the Dynare bytecode (`*.cod`, `*.bin`) under
  `Training/Day2_Dynare_Resources_2026-06-03/…/rbc/model/bytecode/`. It belongs to a third-party
  teaching bundle that is distributed as-is.
- **Training outputs:** `Training/Day3_Calibration/IO_Calibration/data/output/` holds generated CSV
  and XLSX files that the exercise uses as reference solutions. Keep them, and document that
  in the Training README.
- **Pending (user's working tree):** deletion of unsuffixed and `_check` workbooks, two dated
  `ScenarioPathDefinition_backup_*.xlsx`, and both sensitivity runners. See D3 before committing.

---

## 5. All proposed changes by risk

**Low — implemented this cycle**

1. Harmonized README top sections for both repositories: canonical name, model-family table,
   reciprocal links above the fold, badges, and quick start with `RunSimulationsEasy` as the
   recommended entry point.
2. Model-family and execution-workflow diagrams in both READMEs (Mermaid).
3. `CONTRIBUTING.md` and `CHANGELOG.md` in both repositories, carrying the plan's maintenance rules.
4. `.github/` PR template with the mandatory *Technical Report impact* field, plus issue templates.
5. Repository–report consistency matrix
   ([report_repository_consistency.md](report_repository_consistency.md)).
6. Lightweight CI (`.github/workflows/repository-checks.yml` + `scripts/ci/check_repository.py`):
   links in public docs, CITATION.cff fields, expected entry points, and forbidden generated
   artifacts. The CI never runs the model.
7. `.gitignore` hardening and untracking of the LaTeX and Python byproducts.
8. Portable Dynare detection in `setup_paths.m` (`DGE_DYNARE_PATH`) with unchanged default
   preference, documented in `docs/reference/running.md`.
9. Broken links fixed in `docs/reference/model.md`, `docs/reference/scenario.md`,
   `docs/reference/baseline_scenario_manual.md`, `docs/use_cases_ee.md`, `docs/use_cases_finance.md`.
10. Maintenance section and `docs/index.md` navigation updates.

**Low — prepared, needs the maintainer to apply (outward-facing)**

11. GitHub About text and topics. Suggested commands:

    ```bash
    gh repo edit schultkr/DGE-METRIC-VietNam \
      --description "DGE-METRIC — Viet Nam: calibrated Viet Nam implementation of the DGE-METRIC dynamic general equilibrium model (Dynare/MATLAB) — scenarios, replication workflow, and report outputs." \
      --add-topic dynare --add-topic matlab --add-topic dsge --add-topic general-equilibrium \
      --add-topic energy-transition --add-topic climate-policy --add-topic carbon-pricing \
      --add-topic green-finance --add-topic viet-nam --add-topic vietnam --add-topic macroeconomics
    gh repo edit schultkr/DGE-METRIC \
      --description "DGE-METRIC: dynamic general equilibrium framework for macroeconomic energy-transition and carbon-market analysis (Dynare/MATLAB)." \
      --add-topic dynare --add-topic matlab --add-topic general-equilibrium \
      --add-topic energy-transition --add-topic carbon-pricing --add-topic macroeconomics
    ```

**Medium — proposed, not executed**

12. Remove the Dropbox defaults in `RunSimulations.m` (D5).
13. Consolidate duplicated docs (D7, §3).
14. Framework root cleanup (§3).
14a. Framework hygiene parity: running `scripts/ci/check_repository.py` against the framework
    on 2026-09-29 reported 35 tracked LaTeX/`__pycache__` byproducts, 8 broken links in
    `docs/reference/` and `docs/policy/` (the same ones fixed here), and the same 28 undocumented
    `DGE_*` variables. Port the fixes from this cycle, then add the CI workflow there.
15. Scenario-level run summary: `RunSimulations.m` catches scenario errors and continues (TR §2.4),
    so print a final PASS/FAIL table per scenario. This is operational only and adds no numerical
    change, but it touches the runner.
16. Publish `docs/` with GitHub Pages/MkDocs once the structure is stable.

**High — requires an author decision first**

17. Canonical workbook set and default suffix (D3).
18. Which repository and release the TR pins (D1), and whether the framework repository becomes
    public.
19. Official long-form name (D2).

---

## 6. Technical Report edits needed

To be applied in the next editorial pass of `IWH_Technical_Report.docx`. The report was not
modified in this cycle.

| TR location | Edit | Driven by |
|---|---|---|
| Cover, Abbreviations, §1 | Use one long-form expansion of DGE-METRIC (see D2). | D2 |
| Cover | Embed the IWH logo instead of linking to `G:\…`. | D13 |
| §2 intro | Replace "Repository: schultkr/DGE-METRIC … commit 619b45a" with the public repository and an explicit release tag, e.g. "DGE-METRIC — Viet Nam, release vX.Y.Z (commit …)". Mention the framework/country-implementation split in one sentence. | D1 |
| §2.2 | Say that MATLAB result structures and logs are produced locally and archived with a run, not stored in the repository. | D8 |
| §2.3 | If the duplicate-docs consolidation is executed, drop the "compatibility" sentence. | D7 |
| §2.4 "Establish a controlled starting point" | Add: first-time users run `RunSimulationsEasy`; Dynare can be located with `DGE_DYNARE_PATH`. | D4, D6 |
| §2.4 workbook list and default suffix | Align with the decision on D3. | D3 |
| Throughout | "Vietnam" → "Viet Nam" in prose, if the canonical spelling is confirmed. | D9 |
| §2.5 | Point to `docs/maintenance/report_repository_consistency.md` as the place where repository–report alignment is tracked. | plan §7 |
