# Calibration Transparency Backlog

This is an internal improvement backlog, not a description of current model
behavior. It was split out of [calibration.md](../reference/calibration.md), which now
covers only the calibration workflow as it actually runs today. Everything
below is a proposed process change, not something implemented.

---

## Current transparency gaps in the data workflow

The repository already exposes many calibration targets, but the current workflow still has several transparency weaknesses.

### External spreadsheet links are not self-documenting

Some cells in the workbook contain formulas referencing external workbooks, for example expressions like `=[1]Data!J2`. If those links are broken or unavailable, Excel may resolve them to blanks or zeros. At that point the repository no longer tells the reader:

- what the original source was,
- which year the value refers to,
- whether the imported number was observed, adjusted, or estimated.

### Required inputs can remain as placeholders

Several baseline fields are still documented as `enter value here`, especially for:

- regional initial price levels,
- population and labor force levels,
- housing stock,
- climate initial conditions,
- sea level.

Because the updater script only skips placeholders rather than failing on them, missing baseline data can be masked by defaults elsewhere in the workflow.

### Hardcoded defaults and workbook values are mixed

The generated driver sets many parameters before the workbook is loaded. This is useful operationally, but it makes it harder to tell whether the final baseline is coming from:

- observed data,
- normative assumptions,
- legacy defaults,
- or calibration residuals.

See [calibration_model_detailed.md §12](../reference/calibration_model_detailed.md) for
a concrete example of code-default-vs-workbook-override divergence
(`phiB_p`, `phiadjB_p`, and other external-sector parameters).

### There is no explicit data dictionary

At present, the workbook lists parameter names and values, but not a structured mapping from each named range to:

- source dataset,
- source year,
- units,
- transformation formula,
- sector mapping rule,
- and whether the number is observed, imputed, or assumed.

### Final calibrated parameters are not exported as a reproducible snapshot

The solved steady state updates many parameters internally, but the repository does not yet export a compact machine-readable baseline parameter snapshot that can be checked into version control.

---

## Proposed steps to make data use more transparent

The following changes would materially improve transparency without changing the model structure.

### Add a `DataSources` sheet to the workbook

For every user-facing input, store:

- parameter name,
- plain-language description,
- source file or publication,
- table or sheet reference,
- source year,
- units,
- transformation rule,
- sector aggregation rule,
- and a short note on judgment calls.

Recommended minimum columns:

| Parameter | Description | Source | Year | Units | Transformation | Sector mapping | Status |
|:--|:--|:--|:--|:--|:--|:--|:--|
| `phiY0_4_1_p` | Secondary-sector value-added share | Vietnam IO table | 2019 | share of GDP | aggregated from industries A-C | mapped to subsector 4 | observed |

### Separate raw data from model-ready targets

Do not store only final shares in the main calibration sheet. Split the workflow into:

- `RawData` for untouched source values,
- `Mappings` for sector and unit conversions,
- `Targets` for model-ready calibration objects,
- `Start` and `Structural Parameters` for the final numbers actually loaded by the model.

This would make it possible to trace, for example, how a national supply-use entry becomes `phiQI_4_1_3_p`.

### Replace fragile external links with frozen values plus metadata

Where workbook formulas currently point to external files, replace them with:

- the imported numeric value,
- a text note documenting the original source,
- and, ideally, a script or export file that regenerates the import.

That prevents hidden dependency failures.

### Fail fast on missing required baseline inputs

The update logic should stop with an error, not silently continue, when required named cells still contain `enter value here`.

At minimum, add a validation step that checks all required baseline cells before calibration starts.

### Export the solved baseline parameter set

After the baseline steady state is solved, export:

- all final `M_.params`,
- the solved steady-state vector,
- and a small checksum or timestamped metadata file.

Recommended outputs:

- `ExcelFiles/Output/baseline_parameters.csv`
- `ExcelFiles/Output/baseline_steady_state.csv`
- `ExcelFiles/Output/baseline_metadata.json`

This would make it clear which values are the actual calibrated ones used in the simulations.

### Label each input as observed, assumed, calibrated, or residual

Each parameter in the workbook should carry a status tag:

- `observed`
- `assumed`
- `calibrated target`
- `model-implied residual`

This single change would already make the calibration much easier to audit.

### Record manual overrides in version control

If a modeler overwrites a workbook value manually, the change should be documented in a short changelog entry stating:

- what changed,
- why it changed,
- the old value,
- the new value,
- and the date.

### Publish a short calibration validation checklist

Before accepting a baseline calibration, the project should verify:

- sectoral shares sum to one where required,
- import and export shares are economically feasible,
- all required initial-condition cells are filled,
- no broken workbook links remain,
- no placeholder text remains in required ranges,
- and the final steady-state residuals are below tolerance.

---

## Recommended transparent workflow for future updates

When updating calibration data, the clean sequence should be:

1. import raw source tables into a versioned raw-data sheet or file,
2. document units, years, and sector mappings,
3. derive model-ready target shares in a dedicated transformation layer,
4. load only validated targets into `Start` and `Structural Parameters`,
5. run calibration,
6. export the solved baseline parameter snapshot,
7. store both the workbook revision and the solved outputs under version control.

This makes the baseline reproducible even if the original spreadsheet environment changes.

---

## Immediate priorities for this repository

If the goal is to improve transparency with minimal disruption, the highest-value next steps are:

1. add a `DataSources` sheet and status tags for all calibration inputs,
2. make calibration fail when required placeholders remain,
3. export the final calibrated parameter vector after the baseline solve,
4. replace external Excel links with frozen values and source metadata,
5. separate raw source data from model-ready target shares.

These steps would make the calibration substantially more auditable while preserving the current MATLAB/Dynare workflow.
