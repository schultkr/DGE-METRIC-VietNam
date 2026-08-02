---
name: dge-technical-reporter
description: Create a complete, publication-style technical report for a dynamic general equilibrium model from a user-provided GitHub repository or local repository checkout. Use when the repository contains model documentation, equations, source code, calibration data, scenario definitions, simulation outputs, figures, tables, or references and the user wants a rigorous report explaining the model, baseline, calibration, shocks, results, limitations, policy implications, and reproducibility. Work only from user-provided repository files and attachments; do not browse for external sources or fill gaps with unsupported assumptions.
---

# DGE Technical Reporter

Produce an auditable, publication-ready report from the contents of a dynamic general equilibrium model repository. Treat the repository as the sole evidence base.

## Operating rules

- Use only files supplied by the user, including the repository and attachments. Do not use web search.
- Distinguish documented facts, results inferred from code or data, and unresolved gaps.
- Never invent parameter values, equations, calibration targets, scenarios, citations, or numerical results.
- Trace every material numerical claim, modelling assumption, and policy conclusion to a repository file and location.
- Preserve the model's own terminology and notation unless it is inconsistent; document any normalization or notation cleanup.
- Explain economic mechanisms, not only correlations or chart movements.
- State whether results are annual or cumulative, levels or deviations, nominal or real, and relative to which baseline.
- Separate model-generated results from historical data, external inputs already stored in the repository, and author interpretation.

## Workflow

### 1. Establish repository scope

Confirm the repository path or mounted checkout. If only a GitHub URL is supplied, use the available repository connector or clone mechanism only when the user has provided access. Do not retrieve unrelated external material.

Run:

```bash
python scripts/inventory_repository.py <repo-path> --output <work-dir>/repository_inventory.md
```

Use the inventory to identify:

- primary README and report templates;
- model source files and equation documentation;
- calibration, estimation, and baseline files;
- scenario and shock definitions;
- simulation outputs, tables, and figures;
- tests, validation scripts, and replication instructions;
- bibliography files and cited documents already in the repository.

Ignore generated build folders, caches, version-control metadata, and duplicate exports unless needed to interpret final results.

### 2. Read sources in evidence order

Use this priority order:

1. Repository-native report template, README, and user instructions.
2. Model equations and source code.
3. Calibration, baseline, and data transformation files.
4. Scenario configuration and shock-generation files.
5. Simulation outputs and figure/table scripts.
6. Validation tests and replication logs.
7. Background documents and bibliography files contained in the repository.

When documentation conflicts with executable code or configuration, report the conflict and treat the executed configuration as the operative specification only when the evidence supports that conclusion.

### 3. Build an evidence ledger

Create a working ledger before drafting. For each important claim record:

- claim or report element;
- source path;
- line, table, figure, equation, variable, or code location;
- evidence type: documented, code-derived, data-derived, or inferred;
- confidence and unresolved issues.

Follow `references/evidence-policy.md`.

### 4. Reconstruct and audit the model

Determine and document at least:

- model class: CGE, DSGE, recursive dynamic, perfect foresight, stochastic, or hybrid;
- temporal structure, horizon, timing, state variables, controls, and exogenous processes;
- agents, sectors, regions, households, labour types, and market structure;
- household preferences and budget constraints;
- production technologies, factor substitution, intermediate inputs, trade, and price formation;
- government, taxation, transfers, debt, and policy financing;
- market-clearing conditions, external balance, closure rules, numeraire, and price normalization;
- capital accumulation, depreciation, adjustment costs, and terminal conditions;
- steady state or baseline construction;
- calibration or estimation targets, parameter sources, units, and transformations;
- solution method, software environment, convergence criteria, and reproducibility steps;
- shock construction, timing, persistence, decay, financing, and mapping to equations or variables.

Use `references/model-audit.md` as the mandatory technical checklist.

### 5. Validate the baseline, scenarios, and results

Before writing conclusions:

- verify that the baseline reproduces intended accounting identities and calibration targets;
- reconcile scenario names across configuration, code, outputs, and plots;
- verify time indices and reporting years;
- check units, scales, signs, aggregation weights, and denominators;
- distinguish direct effects, equilibrium feedbacks, spillovers, and financing effects;
- check whether tables and figures can be reproduced from stored outputs;
- compare narrative claims with raw results and plotting scripts;
- identify sensitivity analyses, uncertainty bands, alternative closures, or parameter tests;
- flag any result that cannot be independently traced or reproduced.

Do not interpret a multiplier, welfare effect, employment change, damage estimate, or distributional effect until its definition is explicit.

### 6. Draft the complete report

Use a repository-native LaTeX, Quarto, Word, or Markdown template when available. Otherwise create a Markdown report with LaTeX-compatible equations and publication-ready captions.

Follow the full structure in `references/report-blueprint.md`. Include all applicable sections and explicitly mark inapplicable sections or missing evidence. The default structure is:

1. Title page and citation information
2. Abstract, keywords, and classification codes when supported
3. Executive summary
4. Introduction and policy or research question
5. Model overview and transmission mechanisms
6. Mathematical specification and equilibrium conditions
7. Data, calibration or estimation, baseline, and validation
8. Scenario and simulation strategy
9. Results, decompositions, heterogeneity, and dynamics
10. Sensitivity, uncertainty, and robustness
11. Limitations and interpretation boundaries
12. Policy implications or research implications
13. Conclusions
14. References
15. Technical and reproducibility appendices

Use equations only when they clarify the model. Define every symbol at first use or in a notation table. Number equations that are referenced later.

### 7. Apply reporting conventions

- Lead each results subsection with the result, then explain the mechanism and evidence.
- Report magnitudes with units, horizon, baseline, and uncertainty or sensitivity context.
- Use consistent decimal precision and sign conventions.
- Give every table and figure a number, descriptive title, notes, and repository-derived source line.
- Explain discontinuities, non-monotonic paths, negative results, and counterintuitive outcomes.
- Avoid causal language beyond what the structural experiment supports.
- Avoid promotional language and unsupported claims of effectiveness.
- Include explicit limitations arising from model structure, data resolution, calibration choices, scenario design, and missing mechanisms.

### 8. Run the quality gate

Run:

```bash
python scripts/check_report.py <report-path>
```

Fix all errors. Review warnings individually; retain a warning only when the report clearly explains why the expected element is unavailable or inapplicable.

Then perform a final manual check against `references/model-audit.md` and `references/report-blueprint.md`.

## Deliverables

Produce:

- the complete report in the repository's preferred format, or Markdown by default;
- an evidence ledger or source map;
- a short unresolved-issues note listing missing inputs, conflicts, or non-reproducible results;
- any generated tables and figures in a clearly named output directory;
- a reproducibility appendix containing commands, software requirements, scenario identifiers, and relevant commit information when available.

Do not replace the complete report with an outline or a prose summary.

## Reference materials

- Read `references/report-blueprint.md` before drafting.
- Read `references/model-audit.md` while reconstructing the model and validating results.
- Read `references/evidence-policy.md` before making numerical claims or citations.
- Read `references/exemplars/README.md` for patterns distilled from the included RHOMOLO and DGE-CRED technical reports. Consult the exemplar PDFs only when a concrete formatting or exposition example is needed.
