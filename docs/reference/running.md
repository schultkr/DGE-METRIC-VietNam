# Running the Model

This page describes the current MATLAB and Dynare workflow for DGE-METRIC.

## Requirements

- MATLAB R2020a or newer recommended
- Dynare 7.0 preferred; Dynare 6.1 also works for many workflows
- Microsoft Excel on Windows for scripts that refresh `.xlsx` workbooks through COM automation

## Setup

Open MATLAB from the repository root and run:

```matlab
setup_paths
```

`setup_paths.m` adds:

- `Functions/`
- `ModFiles/`
- the repository root
- Dynare, located in this order:
  1. the `DGE_DYNARE_PATH` environment variable (the folder containing `dynare.m`,
     e.g. `C:\dynare\7.0\matlab`), if set;
  2. a `dynare.m` that is already on the MATLAB path;
  3. the default install locations (`C:\dynare\<version>\matlab` on Windows,
     `/Applications/Dynare/<version>/matlab` on macOS, `/usr/lib/dynare/matlab` on Linux),
     trying the tested versions 7.0 and 6.1 first, then other installed versions, newest first.

If Dynare is installed elsewhere, set `DGE_DYNARE_PATH` (for example
`setenv('DGE_DYNARE_PATH', 'D:\tools\dynare\7.0\matlab')` in MATLAB before `setup_paths`).
Record the Dynare version used with every reproduction run.

## Main Simulation Workflow

The canonical model entry point is:

```text
DGE_Model.mod
```

The model pulls shared blocks from:

```text
ModFiles/
```

Run the scenario loop from MATLAB:

```matlab
RunSimulations
```

`RunSimulations.m` updates scenario switches, calls Dynare, and writes outputs for each configured scenario.

## Scenario groups

Defining a scenario in the model or adding its worksheet to the scenario
workbook does **not** make it run. `RunSimulations.m` applies three separate
selection steps:

1. `scenarioGroups.<name>` lists the scenario names that are enabled in a
   group. A line beginning with `%` is disabled and is not added to the group.
2. `activeScenarioGroups` selects which of those groups are run.
3. A nonempty `DGE_SCENARIO_GROUPS` environment variable replaces the
   `activeScenarioGroups` value from the script.

The script concatenates the enabled names from the selected groups into
`casScenarioNames`. Only the names in that final list reach the simulation
loop.

The available group families are:

| Group | Scenario names | Purpose |
|---|---|---|
| `Reference` | `Baseline`, `NZ` | Core baseline and Net-Zero reference paths |
| `EE` | `EE_Directive10` and related variants | Energy-efficiency scenarios |
| `GF_PDP8` | `PDP8_GF_A`, `PDP8_GF_B`, `PDP8_GF_C` | Green finance on the PDP8 baseline |
| `GF_NZ` | `NZ_GF_A`, `NZ_GF_B`, `NZ_GF_C` and related variants | Green finance on the Net-Zero path |
| `NZ_Sensitivity` | `NZ_constEE`, `NZ_constInt`, `NZ_constEEInt`, `NZ_subsidy` | NZ decomposition and policy variants |
| `ImportShock` | `ImportShock_Fossil2_P10` and related variants | Import and trade shock scenarios |

This table describes the families, not the scenarios enabled in a particular
checkout. Inspect the corresponding `scenarioGroups` block: several `EE` and
`NZ_Sensitivity` names may be individually commented out.

### Edit the script

For a persistent repository configuration, uncomment only the desired names
inside each group and leave exactly one `activeScenarioGroups` assignment
uncommented. For example, this runs `Baseline`, `NZ`, and all three PDP8 green
finance scenarios:

```matlab
scenarioGroups.Reference = { ...
    'Baseline', ...
    'NZ', ...
    };

scenarioGroups.GF_PDP8 = { ...
    'PDP8_GF_A', ...
    'PDP8_GF_B', ...
    'PDP8_GF_C', ...
    };

activeScenarioGroups = {'Reference', 'GF_PDP8'};
```

By contrast, selecting `EE` does not run a commented-out member:

```matlab
scenarioGroups.EE = { ...
    % 'EE_Directive10', ...       % does not run
    'EE_Directive10_nocap', ...  % runs when EE is selected
    };
activeScenarioGroups = {'EE'};
```

The repository's baseline-only default is:

```matlab
scenarioGroups.Reference = {'Baseline'};
activeScenarioGroups = {'Reference'};
```

The Green Finance groups are wired into the scenario-switch logic, but merely
defining `scenarioGroups.GF_PDP8` and `scenarioGroups.GF_NZ` does not select
them. Add those group names to `activeScenarioGroups` to run them.

To run exactly one scenario, either comment out the other members of its group
or create a temporary one-member group. For example:

```matlab
scenarioGroups.SingleRun = {'PDP8_GF_B'};
activeScenarioGroups = {'SingleRun'};
```

The group label is only an organizer; the scenario name must still match the
name expected by the workbook and the scenario-switch logic.

### Override the selected groups without editing the script

`DGE_SCENARIO_GROUPS` accepts comma-separated **group names**, not individual
scenario names. Set it before invoking `RunSimulations`:

```matlab
setenv('DGE_SCENARIO_GROUPS', 'Reference,GF_PDP8,GF_NZ');
RunSimulations
```

From PowerShell, when starting a new MATLAB process:

```powershell
$env:DGE_SCENARIO_GROUPS = 'Reference,GF_PDP8,GF_NZ'
matlab -batch "RunSimulations"
```

The environment value has precedence over the assignment in the file. Clear
it to return control to `activeScenarioGroups`:

```matlab
setenv('DGE_SCENARIO_GROUPS', '');
```

The override changes only which groups are selected. It does not uncomment
members inside a group, create missing workbook sheets, or change the scenario
switch logic.

### Confirm what will run

Immediately before the main simulation loop, inspect `casScenarioNames` in
MATLAB. It is the authoritative list for that invocation. For a published or
archived result, record all of the following:

- the repository commit;
- the value of `DGE_SCENARIO_GROUPS` (including that it was empty, if so);
- `activeScenarioGroups`;
- the resolved `casScenarioNames`; and
- the scenario workbook/version used.

A scenario name appearing in `DGE_Model.mod`, a workbook, or documentation is
therefore not evidence that it ran. See
[scenario.md](scenario.md#reproducibility).

## Environment variables

This table is the canonical list of every `DGE_*` environment variable the code reads.
`scripts/ci/check_repository.py` fails if code reads a variable that is not listed here.
Variables stay set in the MATLAB session or shell that set them. Record all of them with every
archived run and clear them (`setenv('NAME', '')`) before the next experiment.

**Setup and simulation runs**

| Variable | Read by | Effect when set |
|---|---|---|
| `DGE_DYNARE_PATH` | `setup_paths.m` | Folder containing `dynare.m`; takes precedence over automatic detection. |
| `DGE_WORKBOOK_VERSION` | `RunSimulations.m` | Workbook-filename suffix. `canonical` selects the unsuffixed workbooks; any other value is used literally (e.g. `_replication`); unset keeps the value of `sSensitivity` in the script. |
| `DGE_SCENARIO_GROUPS` | `RunSimulations.m` | Comma-separated group names; replaces `activeScenarioGroups`. |
| `DGE_SCENARIO_NAMES` | `RunSimulations.m` | Comma-separated, ordered scenario names; replaces both `scenarioGroups` and `activeScenarioGroups`. |
| `DGE_EASY_SCENARIO_NAMES` | `RunSimulationsEasy.m` | Comma-separated scenario names for the guided runner (default `Baseline,NZ`). |
| `DGE_INVESTMENT_TARGETS_CSV` | `RunSimulations.m` | GSO investment-by-ownership CSV used to reshuffle initial-period investment. If the file is missing, the reshuffle step is skipped with a warning. |
| `DGE_INVESTMENT_TARGETS_IOTABLE_XLSX` | `RunSimulations.m` | 2019 input–output workbook used to rescale those targets. If the file is missing, rescaling is skipped with a warning. |
| `DGE_OUTPUT_SUBFOLDER` | `Functions/simulation_model_refactored.m` | Writes scenario CSVs to `ExcelFiles/Output/<value>/` instead of `ExcelFiles/Output/`. |
| `DGE_CALIBRATION_VERSION` | `Functions/Miscellaneous/Excel/update_data_excel.m` | Suffix of the calibration workbook to update (default: unsuffixed). |
| `DGE_PYTHON` | `scripts/reporting/reproduce_macro_impact_assessment_figures.m` | Python interpreter for the figure pipeline; otherwise the repository `.venv`, then `python` on `PATH`. |

A warning about a missing investment-target file changes the run specification. Treat it as a
change, not as harmless console output.

**Workbook maintenance (`scripts/maintenance/`)**

| Variable | Read by | Effect when set (default) |
|---|---|---|
| `DGE_BUILD_MODE` | `build_all_workbooks.m` | `quickcheck` or `full` (`quickcheck`). |
| `DGE_BUILD_SCENARIO_GROUPS` | `build_all_workbooks.m` | Scenario groups to rebuild (`Reference`). |
| `DGE_PROMOTE_BASELINE` | `build_all_workbooks.m` | `1` promotes the rebuilt Baseline to the canonical workbook (`0`). |
| `DGE_USE_PDP8_INVESTMENT_TARGETS` | `create_baseline_from_user_input_file.m` | `0` skips the PDP8 investment-target computation for a quick Baseline build (`1`). |
| `DGE_TARGET_IY_METHOD` | `create_baseline_from_user_input_file.m`, `compute_target_investment_ratios.m` | `IndexProxy` or `CapitalStock` (`CapitalStock`, from `get_pdp8_target_investment_config.m`). |
| `DGE_SKIP_TARGET_IY_PARITY_CHECK` | `compute_target_investment_ratios.m` | `1` skips the workbook-parity assertion. |
| `DGE_BASELINE_SOURCE_SHEET` | `create_baseline_from_user_input_file.m`, `compute_target_investment_ratios.m`, `create_baseline_share_candidates.m` | Source sheet in the path-definition workbook, with no fallback (`Baseline` fallback). |
| `DGE_BASELINE_ANCHOR_YEARS` | `create_baseline_share_candidates.m` | Interpolation anchor years (`2030,2035,2040,2045,2050`). |
| `DGE_BASELINE_SHARE_GAMMAS` | `create_baseline_share_candidates.m` | Candidate curvature grid (`0.1,0.2`). |
| `DGE_BASELINE_CANDIDATE_PREFIX` | `create_baseline_share_candidates.m` | Candidate sheet-name prefix (`Baseline_FR`). |
| `DGE_BASELINE_INCLUDE_SMOOTH` | `create_baseline_share_candidates.m` | Include the smooth-step candidate (`true`). |
| `DGE_BASELINE_RESIDUAL_SUBSECTOR` | `create_baseline_share_candidates.m` | Subsector absorbing share changes (`5`). |
| `DGE_REFRESH_BASELINE_FIRST` | `create_baseline_share_candidates.m` | `false` skips refreshing the main Baseline first (`true`). |
| `DGE_BASELINE_OPT_GAMMAS` | `optimize_baseline_share_path.m` | Initial curvature grid (`0.35,0.5,0.75,1,1.5,2,3`). |
| `DGE_BASELINE_OPT_ANCHOR_YEARS` | `optimize_baseline_share_path.m` | Interpolation anchor years (`2030,…,2050`). |
| `DGE_BASELINE_OPT_ROUNDS` | `optimize_baseline_share_path.m` | Refinement rounds (`2`). |
| `DGE_BASELINE_OPT_POINTS` | `optimize_baseline_share_path.m` | Points per refinement, minimum 3 (`5`). |
| `DGE_BASELINE_OPT_RESIDUAL_SUBSECTOR` | `optimize_baseline_share_path.m` | Subsector absorbing share changes (`5`). |
| `DGE_BASELINE_GDP_TOL` | `optimize_baseline_share_path.m` | GDP-growth matching tolerance (`1e-6`). |
| `DGE_BASELINE_OPT_INCLUDE_SMOOTH` | `optimize_baseline_share_path.m` | Include the smooth candidate (`false`). |
| `DGE_BASELINE_OPT_INCLUDE_BASELINE` | `optimize_baseline_share_path.m` | Include the current Baseline as a benchmark (`false`). |
| `DGE_BASELINE_SHEETS` | *set* by `create_baseline_share_candidates.m`, `optimize_baseline_share_path.m`, `run_sensitivity_analysis.m` | **Currently not read by any runner**, so it has no effect. See [audit D16](../maintenance/repository_audit.md). |

## Outputs

Scenario CSV files are generated in:

```text
ExcelFiles/Output/
```

Dynare also writes generated MATLAB code and solver artifacts to folders such as:

```text
+DGE_Model/
DGE_Model/
```

Those generated folders are ignored by Git and can be regenerated by rerunning Dynare.

## Workbook Maintenance

After editing baseline helper sheets in the baseline workbook, refresh the runnable `Baseline` values sheet with:

```matlab
run('scripts/maintenance/update_baseline_sheet.m')
```

## Analysis and Reporting

Post-run scripts live outside the root folder:

```matlab
run('scripts/analysis/analyze_va_shares.m')
run('scripts/analysis/compute_terminal_ss.m')
run('scripts/reporting/display_baseline_energy.m')
```

Figures are written to `Figures/` by the reporting scripts.

## Recommended Workflow

1. Open MATLAB in the repository root.
2. Run `setup_paths`.
3. Confirm Excel inputs in `ExcelFiles/`.
4. Run `RunSimulations`.
5. Inspect CSV outputs in `ExcelFiles/Output/`.
6. Run analysis or reporting scripts from `scripts/`.
