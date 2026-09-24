# Evidence and source policy

## Core rule

Treat the user-provided repository and attachments as the complete evidence universe. Do not add external facts, references, parameter values, or interpretations from memory or the web.

## Evidence classes

Label working claims as one of these classes:

1. Documented: explicitly stated in a repository document.
2. Code-derived: directly visible in executable code or configuration.
3. Data-derived: calculated from repository data or model outputs.
4. Inferred: a reasoned interpretation supported by multiple repository elements.
5. Unresolved: not supported strongly enough for publication.

Use documented, code-derived, and data-derived claims freely when traceable. Mark inferences as interpretations. Do not publish unresolved claims as facts.

## Evidence ledger

Maintain a table with these columns:

| ID | Claim or report element | Source path | Exact location | Evidence class | Confidence | Notes |
|---|---|---|---|---|---|---|

Exact location can be a line range, equation, table, figure, sheet and cell range, variable name, function, configuration key, or output file and time index.

## Numerical claims

For every material number, record:

- original value and source;
- unit and price basis;
- geography, sector, household group, or other scope;
- time period and whether the value is annual or cumulative;
- denominator for percentages and multipliers;
- baseline or comparison scenario;
- transformations or aggregation steps;
- rounding applied in the report.

Recompute aggregates when possible. If the report value comes from a plotting script, trace it back to the underlying output rather than citing only the image.

## Equations and parameters

For each reported equation or parameter:

- use the operative code or equation file;
- identify whether the object is calibrated, estimated, imposed, or scenario-specific;
- record units and indexing;
- explain any discrepancy between documentation and code;
- do not silently repair a suspected typo.

## Conflicting sources

When sources conflict:

1. Describe the conflict.
2. Identify which file controls the executed simulation, if demonstrable.
3. Use that file for the operative specification.
4. Preserve the conflicting documentation in the limitations or reproducibility note.
5. Avoid choosing a source merely because it is newer or more polished.

## Citation conventions

Use the citation system already present in the repository. If none exists:

- cite background literature through the repository bibliography;
- use author-year references in the report body;
- use repository path notes for model-specific evidence, such as `Source: model/scenarios/policy.yaml, scenario policy_A`;
- provide a source map appendix linking report tables, figures, equations, and claims to repository locations.

Do not cite the GitHub repository generically when a specific file is available.

## Missing evidence

Use explicit language:

- "The repository does not document..."
- "This result could not be reproduced from the stored outputs..."
- "The parameter source is not identified..."
- "The code and documentation differ on..."

Do not hide gaps with generic prose. Add each gap to the unresolved-issues note.
