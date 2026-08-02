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
- the first installed Dynare path it finds among the default Windows locations

If Dynare is installed elsewhere, add that path manually before running simulations.

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
