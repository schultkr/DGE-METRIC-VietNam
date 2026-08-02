# Import Shock Setup Checklist

A practical step-by-step checklist for setting up and running import shock scenarios.

---

## Pre-Setup: Understanding What You Have

- [ ] Review [import_shock_investigation_guide.md](./import_shock_investigation_guide.md) sections 1–2
- [ ] Confirm three import variables exist in `DGE_Model_Declaration.mod` lines 193–195:
  - `exo_M_@{subsec}` (price wedge)
  - `exo_lMAmount_@{subsec}` (mode toggle)
  - `exo_MAmt_@{subsec}` (amount/growth shock)
- [ ] Verify equation is in `ModFiles/Equations/rest_of_world.mod` lines 10–18

---

## Phase 1: Excel Setup (30 minutes)

### 1.1: Create Scenario Sheet

- [ ] Open `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx`
- [ ] Right-click sheet tab → Insert Sheet → Name it (e.g., `ImportShock_Fossil`)
- [ ] Copy structure from `Reference` sheet (headers, region/subsector rows)

### 1.2: Define Import Shocks

**Choose your shock type:**

- [ ] **Price shock?** → Set `exo_lMAmount_@{subsec}` = 0, use `exo_M_@{subsec}`
- [ ] **Amount/supply shock?** → Set `exo_lMAmount_@{subsec}` = 1, use `exo_MAmt_@{subsec}`

**Fill in values** (see template below):

```
Period | exo_lMAmount_S | exo_M_S | exo_MAmt_S
1      | 0              | 0       | 0
2      | [1 or 0]       | [shock] | [shock]
...    | ...            | ...     | ...
25     | 0              | 0       | 0
```

- [ ] For untouched subsectors: set all three variables = 0

### 1.3: Propagate to Baseline

- [ ] Open `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx` → `Baseline` sheet
- [ ] Verify or add rows for `exo_lMAmount_*`, `exo_M_*`, `exo_MAmt_*` (all = 0)
- [ ] Save file

### 1.4: Synchronize Excel Files

- [ ] Run in MATLAB:
  ```matlab
  setup_paths
  cd('Functions/Miscellaneous/Excel')
  update_data_excel
  ```
- [ ] Verify no error messages
- [ ] Check that both `ModelBaseline...xlsx` and `ModelScenarios...xlsx` have synced

---

## Phase 2: MATLAB Setup (15 minutes)

### 2.1: Register Scenario in RunSimulations.m

- [ ] Open `RunSimulations.m`
- [ ] Locate scenario group definitions (~line 30–50)
- [ ] **Option A (recommended):** Add to existing group:
  ```matlab
  case 'ImportShock'
      casScenarios = {'ImportShock_Fossil'};  % <-- Your sheet name
  ```
- [ ] **Option B:** Modify `activeScenarioGroups`:
  ```matlab
  activeScenarioGroups = {'Reference', 'ImportShock'};  % Add ImportShock
  ```

### 2.2: Verify Model Declarations

- [ ] No edits needed; model already has import variables declared
- [ ] Confirm `DGE_Model.mod` includes `ModFiles/DGE_Model_Declaration.mod`:
  ```mod
  @# include "ModFiles/DGE_Model_Declaration.mod"
  ```

---

## Phase 3: First Run (10 minutes)

### 3.1: Test Run

- [ ] In MATLAB command line:
  ```matlab
  setup_paths
  RunSimulations
  ```
- [ ] Watch console output for:
  - "Solving scenario: [Your Scenario Name]" ✓
  - Dynare compilation messages (normal)
  - No fatal errors (warnings are OK)

### 3.2: Verify Results

- [ ] After completion, run:
  ```matlab
  load structScenarioResults.mat
  fieldnames(structScenarioResults)
  ```
- [ ] Your scenario name should appear in the list
- [ ] Example: `structScenarioResults.ImportShock_Fossil` exists

### 3.3: Quick Sanity Check

- [ ] Plot a simple comparison:
  ```matlab
  baseline = structScenarioResults.Reference;
  shock = structScenarioResults.ImportShock_Fossil;
  
  iM = ismember(baseline.var_names, 'M_I_2_1');  % Fossil intermediate imports
  figure; plot([baseline.endo_simul(iM, :); shock.endo_simul(iM, :)]');
  legend('Baseline', 'Shock');
  title('Fossil Intermediate Imports');
  ```
- [ ] Shock scenario should visibly differ from baseline (not identical)

---

## Phase 4: Analysis (Variable)

### 4.1: Extract Key Time Series

- [ ] Import quantities: `M_I_s_r`, `M_F_s_r`
- [ ] Import prices: `P_M_s`
- [ ] Output: `Q_s_r`, `Y`
- [ ] Consumption: `C`
- [ ] Investment: `I`
- [ ] Trade balance: `NX_r`

### 4.2: Generate Comparison Plots

- [ ] Percentage changes from baseline (use formulas in step 3.3)
- [ ] Multiple subsectors on one plot (if multi-shock scenario)
- [ ] Comparison of scenarios (e.g., price vs. amount shock, mild vs. severe)

### 4.3: Export Results (Optional)

- [ ] Save key variables to CSV:
  ```matlab
  writetable(array2table(delta_M_I'), 'ImportShock_Results.csv', 'Delimiter', ',');
  ```
- [ ] Use `ExcelFiles/Output/` for results organization

---

## Troubleshooting Checklist

### Scenario doesn't run (not in results)

- [ ] Sheet name matches exactly (case-sensitive)
- [ ] Sheet has all required column headers
- [ ] `update_data_excel` was run after sheet creation
- [ ] No typos in scenario group definition in `RunSimulations.m`

### Scenario runs but no import shock apparent

- [ ] Check `exo_lMAmount_@{subsec}` is correctly set (0 or 1)
- [ ] Verify `exo_M_@{subsec}` or `exo_MAmt_@{subsec}` has non-zero shock values
- [ ] Baseline sheet has import variables = 0
- [ ] Not accidentally using both `exo_M_` and `exo_MAmt_` simultaneously

### Solver fails / NaN values in results

- [ ] Reduce shock magnitude (try 2–5% first)
- [ ] Start with single-subsector shock (not all subsectors together)
- [ ] Ensure all other exogenous variables are populated (copy from Reference sheet)
- [ ] Check `DGE_Model/DGE_Model.log` for error details

### Results seem unrealistic

- [ ] Verify baseline scenario runs correctly (use Reference as control)
- [ ] Check magnitude and direction of shocks (positive vs. negative)
- [ ] Inspect comparison with baseline (use sanity-check plot from Phase 3.3)
- [ ] For amount shocks, remember `exo_MAmt_` is **log growth** (e.g., -0.10 = -10% volume decline)

---

## Template: Copy-Paste Shock Values

Use these as starting points; adjust magnitudes based on your research question.

### Price Shock (Oil/Fossil Energy)

```
Period | exo_lMAmount_2 | exo_M_2 | exo_MAmt_2
1      | 0              | 0.00    | 0
2      | 0              | 0.15    | 0
3      | 0              | 0.15    | 0
4-10   | 0              | 0.10    | 0
11-25  | 0              | 0.05    | 0
```

### Amount Shock (Supply Disruption)

```
Period | exo_lMAmount_4 | exo_M_4 | exo_MAmt_4
1      | 0              | 0.00    | 0
2-4    | 1              | 0.00    | -0.15
5-6    | 1              | 0.00    | -0.05
7+     | 0              | 0.00    | 0
```

### Broad Price Shock (All Subsectors)

For subsectors 1, 4, 5: set `exo_M = 0.08`  
For subsectors 2, 3: set `exo_M = 0.12`  
All: `exo_lMAmount = 0` (all periods)

---

## Next Steps

After successful first run:

1. **Expand scenarios:** Create variants (mild/severe, longer/shorter duration)
2. **Multi-subsector:** Combine shocks across sectors to study spillover effects
3. **Policy layer:** Add import tariffs or export subsidies in parallel scenarios
4. **Sensitivity:** Test how results change with different model parameters
5. **Documentation:** Record shock values and key results in `docs/implementation_plans/`

---

## Key Contacts / References

- **Questions about imports modeling:** See [rest_of_world.mod](../../ModFiles/Equations/rest_of_world.mod)
- **Questions about Excel integration:** See [ExcelFiles/README.md](../../ExcelFiles/README.md)
- **Full technical guide:** [import_shock_investigation_guide.md](./import_shock_investigation_guide.md)
- **Running model:** [docs/running.md](../reference/running.md)

