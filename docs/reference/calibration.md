# Model Calibration

This page explains how the baseline DGE-METRIC model is calibrated in the current repository: which inputs come from the Excel workbook, and which parameters are solved inside the MATLAB steady-state routines.

The focus is the Vietnam single-region, five-subsector setup driven by the active calibration workbook:

- `ExcelFiles/ModelCalibration5Sectorsand1Regions.xlsx` (calibration inputs and named ranges)
- `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx` (split baseline path workbook)

The older combined workbook name (`ModelSimulationandCalibration5Sectorsand1Regions.xlsx`)
referenced in some historical notes is now archived under `ExcelFiles/Archive/`
and is not read by the current pipeline — see [ExcelFiles/README.md](../../ExcelFiles/README.md)
for the current workbook layout.

For known transparency gaps in this workflow and a proposed improvement backlog
(not yet implemented), see [implementation_plans/calibration_transparency_backlog.md](../implementation_plans/calibration_transparency_backlog.md).
For the code-default-vs-active-workbook parameter divergence (e.g. `phiB_p`,
`phiadjB_p`), see [calibration_model_detailed.md §12](calibration_model_detailed.md).

---

## Documentation Overview

- **Project overview:** [Home](../index.md)
- **Model structure & equations:** [Model documentation](model.md)
- **Scenario design & assumptions:** [Scenarios](scenario.md)
- **Calibration & data sources:** [Calibration](calibration.md)
- **How to run the model:** [Running the model](running.md)

---

## 1. Calibration objective

The model is calibrated to reproduce a baseline steady state that is consistent with:

- the sectoral composition of output and employment,
- the input-output structure across sectors,
- import and export shares,
- emissions shares and energy structure,
- initial macro aggregates such as GDP, labor force, housing, and emissions,
- and a set of structural elasticities, taxes, and behavioral parameters.

In practical terms, calibration means combining:

- **direct inputs** from the Excel workbook,
- **structural assumptions** chosen by the modeler,
- **generated defaults** embedded in the model setup,
- and **model-implied residual parameters** that are backed out so the steady state is internally consistent.

---

## 2. Main calibration artifacts

| Workbook | Main purpose | Key contents and workflow |
|:--|:--|:--|
| `ExcelFiles/ModelCalibration5Sectorsand1Regions.xlsx` | Model calibration | Contains the hand-entered calibration inputs, generated named ranges, and parameter sheets used to initialise the five-sector, one-region model. |
| `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx` | Baseline construction | Contains the runnable Baseline sheet plus its supporting baseline-construction sheets; `scripts/maintenance/update_baseline_sheet.m` refreshes `Baseline`. |
| `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx` | Scenario definition | Holds the scenario-specific sheets, exogenous shock paths, and assumptions that `RunSimulations.m` and `simulation_model_refactored.m` use during transition runs. |
| `Functions/Miscellaneous/Excel/create_raw_excel_input_file.m` | Workbook generator | Creates workbook structure, named cells, formulas, and placeholder entries |
| `Functions/Miscellaneous/Excel/update_data_excel.m` | Workbook updater | Copies named values from the `Data` sheet into `Start` and `Structural Parameters`, skipping cells that still say `enter value here` |
| `scripts/maintenance/update_baseline_sheet.m` | Baseline sheet refresher | Recomputes `Baseline_Implied` and writes values into `Baseline` via `update_baseline_excel` |
| `RunSimulations.m` | Runtime orchestrator | Selects scenario groups/sheets, sets workbook paths and macro switches, then invokes Dynare |
| `Functions/Miscellaneous/ModelSetup/change_mod_file.m` | Macro switch updater | Rewrites `DGE_Model.mod` macro flags (`YEndogenous`, `BaselineScenario`, sector/region counts, etc.) before each run |
| `+DGE_Model/driver.m` | Dynare/MATLAB driver | Loads the workbook, sets many default parameter values, then overwrites matching parameters from the `Start` and `Structural Parameters` sheets |
| `Functions/steadystate_model.m` | Baseline calibration wrapper | Runs calibration mode first, then solves the full steady state |
| `DGE_Model_steadystate.m` | Steady-state dispatcher | Switches between calibration mode, hybrid mode, and full steady state |
| `Functions/SteadyState/setup_initial_state.m` | Core calibration routine | Builds the initial state, calibrates production and trade blocks, updates aggregates, and returns residuals for `fsolve` |

---

## 2.1 Step-by-step: create and prepare the calibration file

Use this procedure when you need to create or rebuild the calibration workbook for the active 5-sector, 1-region setup.

### Step 1. Open MATLAB at repo root and initialize paths

```matlab
cd('<repo-root>')
setup_paths
```

Expected result:

- `Functions/` and `ModFiles/` are on the MATLAB path.
- Dynare path is available.

### Step 2. Generate the workbook scaffold (if missing or intentionally rebuilding)

```matlab
run('Functions/Miscellaneous/Excel/create_raw_excel_input_file.m')
```

Expected result:

- `ExcelFiles/ModelCalibration5Sectorsand1Regions.xlsx` exists.
- Required sheets exist (`IO_Data`, `Trade_Flows`, `Data`, `Start`, `Structural Parameters`, plus scenario/helper sheets).

### Step 3. Fill calibration inputs in Excel

Edit only user-input sheets in `ModelCalibration5Sectorsand1Regions.xlsx`:

- `IO_Data`
- `Trade_Flows`

Current upstream source for `IO_Data` in the project workflow:

- the external reproducible IO pipeline (R-based) maintained in the GSO data workspace,
- which splits utilities into fossil/renewables and aggregates to the model's 5-sector structure,
- then exports DGE-ready files (for example `IO_2019_5sec_for_DGE_IO_Data.xlsx/.csv` and validation/audit tables).

Practical handoff:

1. Run the reproducible IO pipeline in the data workspace.
2. Take the generated 5-sector IO output table.
3. Paste/map the resulting shares into `IO_Data` (and matching trade destinations into `Trade_Flows`) before running `update_data_excel.m`.

Do not hand-edit generated propagation targets unless you are doing an intentional advanced override:

- `Data`
- `Start`
- `Structural Parameters`

### Step 4. Run workbook synchronization

```matlab
run('Functions/Miscellaneous/Excel/update_data_excel.m')
```

What this does now:

- propagates `IO_Data` into `Data` named ranges,
- propagates `Data` named ranges into `Start` and `Structural Parameters`,
- skips unresolved placeholder cells (`enter value here`),
- does not modify `ModelBaseline*.xlsx` or `ModelScenarios*.xlsx`.

### Step 5. Refresh baseline workbook values sheet

```matlab
run('scripts/maintenance/update_baseline_sheet.m')
```

Expected result:

- `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx` gets refreshed,
- `Baseline_Implied` is recomputed and copied into values-only `Baseline`.

### Step 6. Quick integrity checks before running the model

Minimum checks:

1. In `IO_Data`, row-share accounting is consistent (including `phiQ = phiQI + phiY0` logic).
2. In `Trade_Flows`, each source row sums to 1 (including `ROW`).
3. In `Start` / `Structural Parameters`, critical entries are numeric (not placeholders).

Reference for sheet-level checks and conventions:

- [ExcelFiles/README.md](../../ExcelFiles/README.md)

### Step 7. Run baseline solve to validate calibration load

```matlab
run('RunSimulations.m')
```

If you want a baseline-only quick validation, set scenario groups/sheets via environment variables before running, or edit `activeScenarioGroups` and `casCandidates` in `RunSimulations.m`.

Expected runtime behavior:

- Pass 1 calibration (`lCalibration_p = 1`) solves residual calibration parameters.
- Pass 2 full steady state (`lCalibration_p = 0`) validates the calibrated set.
- Results write to `ExcelFiles/Output/` and `structScenarioResults*.mat`.

### Step 8. Troubleshooting checklist (fast)

If workbook creation/propagation fails:

1. Close all open Excel windows for the calibration workbook.
2. Re-run `update_data_excel.m` (it includes lock/open retries).
3. Confirm file exists at `ExcelFiles/ModelCalibration5Sectorsand1Regions.xlsx`.
4. Confirm MATLAB was started from repo root and `setup_paths` was executed.

---

## 3. What is imposed, what is solved, and what is still defaulted

The current workflow mixes four distinct types of inputs. Keeping these separate is important for transparency.

| Type | Examples in the current setup | How they enter the model |
|:--|:--|:--|
| **Observed or targeted baseline shares** | `phiY0`, `phiN0`, `phiW`, `phiX`, `phiM_I`, `phiM_F`, `phiQI`, `phiQ_D`, `sE` | Read from workbook sheets and used as calibration targets |
| **Structural assumptions** | `beta`, `delta`, `sigmaL`, `sigmaC`, `etaQ`, `etaF`, `etaX`, `etaQA`, `etaI`, `etaIA`, tax rates | Read from `Structural Parameters` or left at defaults in the driver |
| **Initial levels / macro closures** | `Y0`, `N0`, `PoP0`, `LF0`, `H0`, `E0`, `PE0`, `tas0`, `SL0` | Read from `Start` when available; otherwise many values fall back to defaults or remain placeholders |
| **Solved residual parameters** | `D_X`, `omegaQ`, `omegaM`, `kappaE`, `omegaLF0`, `phiL`, `A`, `A0`, `rf0`, `E0` | Computed inside the steady-state routines so the model reproduces the baseline targets |

The key point is that the workbook does **not** contain every final parameter used in the solved model. A material subset is generated inside the calibration routines.

---

## 4. How the calibration runs in this repository

### Step 1. Workbooks are prepared and synchronized

The active calibration workbook is `ModelCalibration5Sectorsand1Regions.xlsx`, with analyst edits focused on `IO_Data` and `Trade_Flows`.

`update_data_excel.m` then performs two propagation stages:

- `IO_Data` -> `Data` named ranges,
- `Data` named ranges -> `Start` and `Structural Parameters` sheets.

In parallel, baseline path maintenance is handled in the Baseline workbook:

- `scripts/maintenance/update_baseline_sheet.m` runs `update_baseline_excel`,
- recalculates `Baseline_Implied`,
- and copies values into `Baseline` (formula-free runnable baseline sheet).

`create_raw_excel_input_file.m` still exists for workbook scaffolding and creates:

- the `Data` sheet with named ranges,
- the `Start` sheet,
- the `Structural Parameters` sheet,
- and scenario-specific sheets.

It also inserts placeholder text such as `enter value here` in many cells. That means the workbook is partly a template, not just a data file.

If `update_data_excel.m` is used, named cells in the `Data` sheet are copied into `Start` and `Structural Parameters`, but only when the source cell is not equal to `enter value here`.

### Step 2. Run scripts set macro/workbook context, then the driver loads parameters

`RunSimulations.m` defines active workbook paths (`sWorkbookCalibration`, `sWorkbookBaseline`, `sWorkbookScenarios`), chooses scenario groups, and calls `change_mod_file.m` to set compile-time macro switches in `DGE_Model.mod` (including `YEndogenous`, `NEndogenous`, `BaselineScenario`, sector/region structure, and cap-and-trade mode).

After preprocessing/compile, the generated driver sets defaults and then overwrites from workbook tables.

The generated driver file contains a large block of hardcoded default parameter values. After that, it executes:

- `readtable(..., 'Sheet', 'Start', 'Range', 'A:C')`
- `readtable(..., 'Sheet', 'Structural Parameters', 'Range', 'A:C')`

Matching workbook entries overwrite the defaults in `M_.params`.

This implies the effective calibration inputs are the combination of:

- hardcoded defaults in the driver,
- formulas and values stored in the workbook,
- and any cells that remain unresolved because they are placeholders or broken external references.

### Step 3. Baseline calibration mode is activated (pass 1)

In `steadystate_model.m`, the baseline case sets:

- `lCalibration_p = 1`

and calls `DGE_Model_steadystate(...)` twice before the first `steady` call, writing updated parameters back into `M_.params` after each call.

Inside `DGE_Model_steadystate.m`, this selects **calibration mode** and calls:

- `ss_build_initial_guess(..., 'calibrate')`
- `ss_setup_initial_state(...)`

If residuals are non-zero, `fsolve` is used to find a consistent initial state.

### Step 4. Initial guesses are built from baseline targets

In calibration mode, the initial guess routine uses baseline targets such as:

- `phiY0_*_*_p`
- `P0_Q_*_*_p`

These values seed the steady-state solve rather than fully determining it.

### Step 5. The model calibrates internal weights and residual parameters

`setup_initial_state.m` runs the following sequence:

1. assign guessed and predetermined values,
2. compute regional export price indices,
3. calibrate production-function parameters,
4. compute sectoral outputs and factor demands,
5. aggregate imports, demand, emissions, and output,
6. compute taxes, regional accounts, and public finance,
7. finalize calibrated parameters,
8. evaluate price-consistency residuals.

This is the core place where the model turns target shares into a fully internally consistent baseline.

### Step 6. A full steady state is solved after calibration (pass 2)

Once calibration mode finishes, `steadystate_model.m` switches to:

- `lCalibration_p = 0`

and solves the full steady state again, followed by a BK stability check (`check(...)` with `qz_zero_threshold = 1e-22`). The calibrated parameters are therefore validated in standard steady-state mode before simulation.

### Step 7. Scenario runs reuse the calibrated baseline

Non-baseline scenarios load the baseline results and typically use a hybrid setup with:

- `lCalibration_p = 2`

This means scenario analysis is conditional on the baseline calibration being accepted as the starting point. During transition stepping in `simulation_model_refactored.m`, candidate steady states are repeatedly solved under hybrid mode and checked against static residual tolerances.

---

## 5. How the main parameter blocks are pinned down

### 5.1 Output, value added, and employment structure

The sector and subsector structure is anchored by workbook targets such as:

- `phiY0_*_*_p` for baseline value-added shares,
- `phiN0_*_*_p` for baseline employment shares,
- `phiW_*_*_p` for labor cost shares.

These determine the relative scale of production, labor use, and income flows across subsectors in the baseline.

### 5.2 Input-output and trade structure

The workbook provides the main expenditure and sourcing shares:

- `phiQI_*_*_p` for intermediate input cost shares,
- `phiQI_*_*_*_p` for origin-sector composition of intermediate inputs,
- `phiM_I_*_*_p` for intermediate import shares,
- `phiM_F_*_*_p` for final import shares,
- `phiX_*_*_p` for export shares,
- `phiQ_D_*_*_*_p` for regional destination shares.

The calibration routines then back out CES weights such as `omegaQ`, `omegaM`, and export variety weights `D_X` so the price system and allocation system reproduce those shares.

### 5.3 Emissions and energy intensity

Sectoral emissions exposure enters through `sE_*_*_p`. The routine `compute_pf_parameters.m` then calibrates emission intensities `kappaE_*_*_p` using the targeted emissions shares, baseline emissions level `E0`, and model-implied expenditure flows.

In other words:

- emissions shares are imposed,
- emission intensities are solved.

### 5.4 Labor supply and household block

Regional labor force and population inputs such as `PoP0` and `LF0`, together with elasticities like `sigmaL` and `etaLF`, are used to recover labor disutility weights `omegaLF0_*_p` and subsectoral labor utility scaling parameters `phiL_*_*_p`.

These are not simple direct data entries. They are implied by the steady-state household first-order conditions.

### 5.5 Productivity and residual technology terms

The model backs out productivity shifters `A_*_*_p` as residual terms that reconcile:

- the observed or targeted baseline allocations,
- public capital,
- and exogenous shocks or closures.

This means productivity is partly a residual calibration object, not a directly observed input.

### 5.6 Financial and macro closure terms

Parameters such as the steady-state foreign interest rate `rf0_p` and net-export ratios are finalized after aggregate consistency conditions are computed.

This is why documenting only the workbook values is not enough to reproduce the final baseline. The solved parameter set matters as much as the raw input set.

---

## 6. Script-level workflows around calibration

### 6.1 Main run loop (`RunSimulations.m`)

- Chooses scenarios through named groups (with optional environment-variable overrides).
- Supports baseline candidate-sheet sweeps (multiple `Baseline*` sheets).
- Persists run outputs and candidate scores to `ExcelFiles/Output`.

### 6.2 Baseline workbook refresh (`scripts/maintenance/update_baseline_sheet.m`)

- One-command refresh for `ModelBaseline5Sectorsand1Regions.xlsx`.
- Keeps `Baseline` aligned with `Baseline_Implied` before simulation runs.

### 6.3 Parameter sensitivity batch (`scripts/maintenance/run_sensitivity_analysis.m`)

- Applies parameter overrides into `Start`/`Structural Parameters`.
- Optionally runs `update_data_excel.m` (`cfg.runUpdateDataExcel`).
- Runs `RunSimulations.m` per case and archives changed CSV/MAT artifacts.

---

## 7. What this means for interpreting results

Users of the model should read the baseline as the outcome of a **hybrid calibration**:

- part data-driven,
- part assumption-driven,
- part generated from legacy defaults,
- and part solved residually inside the steady-state model.

That is a normal approach for a DGE model, but it should be documented explicitly. Without that separation, readers may mistakenly treat every parameter in the workbook as an observed data input, which is not how this repository currently works.

For known gaps in this workflow and a proposed improvement backlog, see
[implementation_plans/calibration_transparency_backlog.md](../implementation_plans/calibration_transparency_backlog.md).
