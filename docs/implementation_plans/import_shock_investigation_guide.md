# Guide: Investigating Import Shocks in DGE-METRIC

This guide explains how to use the model's built-in import shock variables to investigate the macroeconomic effects of import price shocks, supply disruptions, and import volume changes.

---

## Table of Contents

1. [Overview of Import Shock Variables](#overview-of-import-shock-variables)
2. [Model Implementation](#model-implementation)
3. [Step-by-Step Setup](#step-by-step-setup)
4. [Running Import Shock Scenarios](#running-import-shock-scenarios)
5. [Analyzing Results](#analyzing-results)
6. [Example Scenarios](#example-scenarios)

---

## Overview of Import Shock Variables

The model contains **three complementary exogenous variables** for investigating import shocks, declared per subsector:

| Variable | Type | Purpose | Declaration |
|----------|------|---------|-------------|
| `exo_M_@{subsec}` | Level shock | Permanent import price shock | [DGE_Model_Declaration.mod:193](../ModFiles/DGE_Model_Declaration.mod#L193) |
| `exo_lMAmount_@{subsec}` | Switch (0 or 1) | Toggle between price and amount shocks | [DGE_Model_Declaration.mod:194](../ModFiles/DGE_Model_Declaration.mod#L194) |
| `exo_MAmt_@{subsec}` | Growth shock | Temporary import amount/volume shock | [DGE_Model_Declaration.mod:195](../ModFiles/DGE_Model_Declaration.mod#L195) |

**Subsectors (as of 5-sector, 1-region config):**
- Subsector 1: Primary
- Subsector 2: Fossil  
- Subsector 3: Renewables
- Subsector 4: Secondary  
- Subsector 5: Tertiary

---

## Model Implementation

### Equation Structure

The import price equation is implemented in [rest_of_world.mod:10-18](../ModFiles/Equations/rest_of_world.mod#L10-L18):

```dynare
// Import block: default is the import price wedge; when exo_lMAmount=1,
// use exo_MAmt as a temporary growth shock to the import wedge level.
#lhsImportPrice_@{subsec} = P_M_@{subsec} * (exo_lMAmount_@{subsec} == 0) +
                            (M_F_@{subsec}_@{reg} + M_I_@{subsec}_@{reg}) * (exo_lMAmount_@{subsec} == 1);
#rhsImportPrice_@{subsec} =
    (P_Q_@{subsec}_@{reg} + exo_M_@{subsec}) * (exo_lMAmount_@{subsec} == 0)
    + ((M_F_@{subsec}_@{reg}(-1) + M_I_@{subsec}_@{reg}(-1)) * exp(exo_MAmt_@{subsec})) * (exo_lMAmount_@{subsec} == 1);
[name = 'import price @{subsec}']
(1 + lhsImportPrice_@{subsec}) / (1 + rhsImportPrice_@{subsec}) = 1;
```

**How it works:**

- **Mode 0 (exo_lMAmount = 0):** Price shock mode
  - LHS: `P_M_@{subsec}` (endogenous import price)
  - RHS: `P_Q_@{subsec}_@{reg} + exo_M_@{subsec}` (domestic price plus exogenous wedge)
  - Use `exo_M_@{subsec}` to shock the import price level

- **Mode 1 (exo_lMAmount = 1):** Amount shock mode
  - LHS: `M_F + M_I` (total import quantity)
  - RHS: `(M_F(-1) + M_I(-1)) * exp(exo_MAmt)` (previous period imports times growth shock)
  - Use `exo_MAmt_@{subsec}` to shock import volume (log growth)

### Key Variables Linked to Imports

- `M_I_@{subsec}_@{reg}`: Intermediate imports (used as production input)
- `M_F_@{subsec}_@{reg}`: Final demand imports (household consumption, investment)
- `P_M_@{subsec}`: Endogenous import price index
- `Q_@{subsec}_@{reg}`: Domestic production

---

## Step-by-Step Setup

### Step 1: Identify Import Shock Target Subsectors

Decide which subsectors to shock:

- **Energy price shock** → Subsectors 2 (Fossil) and 3 (Renewables)
- **Supply chain disruption** → Subsector 4 (Secondary manufacturing)
- **Global commodity shock** → Subsector 1 (Primary)
- **Broad import shock** → All subsectors

### Step 2: Create or Modify a Scenario Sheet

1. **Open** `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx`
2. **Create a new sheet** (e.g., `ImportShock_Fossil` or `ImportShock_All`)
   - Right-click on sheet tab → Insert Sheet
3. **Copy the structure** from an existing scenario sheet (e.g., `Reference`)
   - All required column headers and region/subsector rows must match

### Step 3: Set Exogenous Variable Values

In your new scenario sheet:

#### For Price Shocks (most common case)

Set these variables per subsector per time period:

| Variable | Value | Example | Interpretation |
|----------|-------|---------|-----------------|
| `exo_lMAmount_@{subsec}` | 0 | All periods | Enable price shock mode (price-based) |
| `exo_M_@{subsec}` | Numeric shock | 0.05 for subsec 2 | +5% import price increase for Fossil |
| `exo_MAmt_@{subsec}` | 0 | All periods | Unused in price mode (can leave as 0) |

**Excel setup example** for Fossil energy price shock:

```
Period   exo_lMAmount_2   exo_M_2    exo_MAmt_2
1        0                0.00       0.00
2        0                0.05       0.00
3        0                0.05       0.00
4-25     0                0.02       0.00    (gradual decline)
```

#### For Quantity/Supply Shocks (temporary disruption)

Set these variables per subsector per time period:

| Variable | Value | Example | Interpretation |
|----------|-------|---------|-----------------|
| `exo_lMAmount_@{subsec}` | 1 | Shock periods | Enable amount shock mode |
| `exo_MAmt_@{subsec}` | Log growth | -0.10 for subsec 4 | -10% import volume decline |
| `exo_M_@{subsec}` | 0 | All periods | Unused in amount mode |

**Excel setup example** for Secondary manufacturing supply disruption:

```
Period   exo_lMAmount_4   exo_MAmt_4   exo_M_4
1        0                0.00         0.00
2-4      1                -0.10        0.00    (10% volume decline)
5        1                -0.05        0.00    (recovery phase)
6-25     0                0.00         0.00    (return to price mode / normal)
```

### Step 4: Ensure Baseline Consistency

**Important:** Import shock variables must also be set (usually to 0) in the Baseline scenario:

1. **Open** `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx` → `Baseline` sheet
2. **Verify or add** these rows:
   - `exo_lMAmount_1`, `exo_lMAmount_2`, `exo_lMAmount_3`, `exo_lMAmount_4`, `exo_lMAmount_5` → all periods = **0**
   - `exo_M_1` through `exo_M_5` → all periods = **0**
   - `exo_MAmt_1` through `exo_MAmt_5` → all periods = **0**

3. **Run** `Functions/Miscellaneous/Excel/update_data_excel.m` to propagate to all scenario sheets

### Step 5: Register Scenario in RunSimulations.m

1. **Open** `RunSimulations.m`
2. **Locate** the scenario group definitions (typically around line 30–50)
3. **Add your scenario** to a scenario group:

```matlab
% Example: Add to an existing or new group
sActiveScenarioGroups = {'Reference', 'ImportShock'};  % Add ImportShock group

% Then define the group in the scenario section:
case 'ImportShock'
    casScenarios = {'ImportShock_Fossil', 'ImportShock_All'};
```

Alternatively, run with environment variable override:

```matlab
% In MATLAB command line:
setenv('DGE_SCENARIO_GROUPS', 'Reference,ImportShock_Fossil');
RunSimulations;
```

---

## Running Import Shock Scenarios

### Method 1: Run via RunSimulations.m (Standard)

```matlab
% In MATLAB, with DGE-METRIC repo as working directory:
setup_paths                 % Add Functions/, ModFiles/ to path
RunSimulations              % Runs all active scenario groups
```

This will:
1. Read your scenario sheet from `ModelScenarios5Sectorsand1Regions.xlsx`
2. Compile the Dynare model with current macro settings
3. Simulate the scenario path
4. Save results to `structScenarioResults.mat`

**Progress indicators:**
- Console will show: `Solving scenario: ImportShock_Fossil`
- Output folder `DGE_Model/Output/` contains diagnostic files
- Warnings about import shocks are expected (not errors)

### Method 2: Selective Scenario Runs (Faster Development)

If you want to test only a specific scenario without running full batches:

```matlab
% Option A: Modify RunSimulations.m temporarily
activeScenarioGroups = {'MyTestGroup'};
RunSimulations;

% Option B: Run a single scenario manually (advanced)
% See Functions/simulation_model_refactored.m for direct call signature
```

### Method 3: Environment Variable Override

```powershell
# PowerShell (repo root):
$env:DGE_SCENARIO_GROUPS = "ImportShock_Fossil,ImportShock_All"
matlab -r "setup_paths; RunSimulations; exit"
```

---

## Analyzing Results

### Step 1: Load Simulation Results

```matlab
% After RunSimulations completes:
load structScenarioResults.mat    % Contains all scenarios run

% Inspect available scenarios:
fieldnames(structScenarioResults)
```

### Step 2: Extract Import-Related Variables

```matlab
% Get all variables for a specific scenario:
scenario_name = 'ImportShock_Fossil';
oo_scenario = structScenarioResults.(scenario_name);

% Access endogenous variables:
M_I_2_1 = oo_scenario.endo_simul(ismember(oo_scenario.var_names, 'M_I_2_1'), :);  % Fossil intermediate imports
M_F_2_1 = oo_scenario.endo_simul(ismember(oo_scenario.var_names, 'M_F_2_1'), :);  % Fossil final imports
P_M_2 = oo_scenario.endo_simul(ismember(oo_scenario.var_names, 'P_M_2'), :);      % Fossil import price

% Access exogenous shocks applied:
exo_M_2 = oo_scenario.exo_simul(:, ismember(M_.exo_names, 'exo_M_2'));           % Price shock
exo_MAmt_2 = oo_scenario.exo_simul(:, ismember(M_.exo_names, 'exo_MAmt_2'));     % Amount shock
```

### Step 3: Compare Against Baseline

```matlab
% Differences between scenarios:
baseline = structScenarioResults.Reference;
shock = structScenarioResults.ImportShock_Fossil;

ipos_M_I_2_1 = ismember(baseline.var_names, 'M_I_2_1');
delta_M_I = (shock.endo_simul(ipos_M_I_2_1, :) - baseline.endo_simul(ipos_M_I_2_1, :)) ./ baseline.endo_simul(ipos_M_I_2_1, :);

figure; plot(delta_M_I * 100); 
title('Change in Fossil Intermediate Imports (%)');
ylabel('% deviation from Baseline');
xlabel('Time Period');
grid on;
```

### Step 4: Key Output Variables to Inspect

| Variable | Meaning | Relevant for |
|----------|---------|--------------|
| `M_I_s_r`, `M_F_s_r` | Import quantities by subsector | Measuring import response |
| `P_M_s` | Import price index | Validating price shock pass-through |
| `P_Q_s_r` | Domestic output price | Price equilibration |
| `Q_s_r`, `Y` | Output and GDP | Macroeconomic impact |
| `C`, `I` | Consumption and investment | Demand-side adjustment |
| `PE`, `E` | Emissions and emission price | Environmental co-effects |
| `NX_r` | Net exports | Trade balance response |

### Step 5: Generate Audit CSV

The model automatically produces audit CSVs comparing simulated growth against Excel targets:

```matlab
% Check for audit CSVs in ExcelFiles/Output/:
% - Baseline.csv
% - ImportShock_Fossil.csv
% - etc.

% These contain year-by-year growth rates (%) and can be compared against
% Excel gY_* target cells
```

---

## Example Scenarios

### Scenario A: Oil Price Shock (Fossil Energy Import Price)

**Motivation:** Analyze the macroeconomic impact of a sudden rise in oil import prices (e.g., OPEC supply cut).

**Setup:**

| Parameter | Value |
|-----------|-------|
| Subsector | 2 (Fossil) |
| Shock type | Price |
| `exo_lMAmount_2` | 0 (all periods) |
| `exo_M_2` period 2-3 | 0.15 (15% price increase) |
| `exo_M_2` period 4-25 | 0.10 (10% elevated, gradual decline) |

**Expected results:**
- Import prices rise sharply
- Domestic firms substitute toward cheaper Renewables (subsector 3)
- GDP and consumption decline temporarily
- Trade deficit widens (in nominal terms)

---

### Scenario B: Global Supply Chain Disruption (Secondary Manufacturing)

**Motivation:** Quantify the impact of a temporary but severe disruption to manufactured goods imports (e.g., pandemic-style lockdown).

**Setup:**

| Parameter | Value |
|-----------|-------|
| Subsector | 4 (Secondary) |
| Shock type | Quantity/Amount |
| `exo_lMAmount_4` period 2-4 | 1 (enable amount shock) |
| `exo_MAmt_4` period 2-3 | -0.20 (-20% volume decline) |
| `exo_MAmt_4` period 4 | -0.10 (-10% partial recovery) |
| `exo_lMAmount_4` period 5+ | 0 (return to normal pricing) |

**Expected results:**
- Import quantities fall sharply despite rising prices (supply constrained)
- Secondary manufacturing output declines or firms substitute to domestic sources
- Investment may decline due to lack of imported capital goods
- Transitory GDP loss followed by recovery as supply chain normalizes

---

### Scenario C: Broad-Based Import Shock (All Subsectors)

**Motivation:** Analyze a global trade shock affecting all import-competing sectors simultaneously.

**Setup:** Apply coordinated shocks across subsectors 1–5:

- **Subsectors 1, 4, 5** (Primary, Secondary, Tertiary): `exo_M = +0.08` (8% price increase)
- **Subsectors 2, 3** (Fossil, Renewables): `exo_M = +0.12` (12% price increase, energy shock larger)
- All use `exo_lMAmount = 0` (price-based)

**Expected results:**
- Economy-wide input cost shock
- Broader price-level increases
- Substitution across all sectors toward domestic production
- Sectoral realignment depending on comparative advantages
- Trade balance adjustment mechanism

---

### Scenario D: Renewable Supply Shock (Clean Energy Import)

**Motivation:** Investigate how supply/cost constraints on renewable energy equipment imports affect the energy transition.

**Setup:**

| Parameter | Value |
|-----------|-------|
| Subsector | 3 (Renewables) |
| Shock type | Quantity |
| `exo_lMAmount_3` | 1 (periods 2–6) |
| `exo_MAmt_3` period 2-4 | -0.15 (-15% import volume reduction) |
| `exo_MAmt_3` period 5-6 | -0.05 (-5% partial recovery) |

**Expected results:**
- Renewable energy prices spike due to supply constraint
- Renewable investment slows (capital goods shortage)
- Potential "lock-in" to fossil energy in near term
- Long-run emissions targets harder to achieve without technology breakthrough
- Policy may need to accelerate demand-side EE measures as substitute

---

## Troubleshooting

### Q: My scenario doesn't appear to be running.

**A:** 
1. Verify the scenario sheet name matches exactly (case-sensitive) in `RunSimulations.m`
2. Check that all required exogenous variable columns exist in the Excel sheet
3. Run `update_data_excel.m` to ensure sheets are synchronized
4. Look for error messages in `DGE_Model/DGE_Model.log`

### Q: Import variables don't change from Baseline.

**A:**
1. Verify `exo_lMAmount_@{subsec}` is set correctly (0 for price mode, 1 for quantity mode)
2. Check that `exo_M_@{subsec}` or `exo_MAmt_@{subsec}` has non-zero values
3. Confirm Baseline sheet has these variables set to 0
4. Run `update_data_excel.m` to propagate

### Q: Model fails to solve or produces NaN values.

**A:**
1. Start with small shocks (+/- 5%) and gradually increase
2. Check that all other exogenous variables are consistent (use `Reference` as template)
3. Verify you are not using both price and amount shocks simultaneously (`exo_M` and `exo_MAmt` > 0 in same period)
4. Run a simplified test scenario (only one subsector shocked) before complex multi-subsector scenarios

### Q: How do I know if the scenario ran successfully?

**A:**
- Check `structScenarioResults.mat` loads without error
- Verify your scenario name appears in `fieldnames(structScenarioResults)`
- Inspect `DGE_Model/Output/` for any warning messages
- Compare baseline and shock scenarios visually; results should differ
- If audit CSV is generated, growth rates should be reasonable (typically +/- 20% over 25 years)

---

## References

- **Model equations:** [Model documentation](../reference/model.md#rest-of-world-and-trade)
- **Equation file:** [rest_of_world.mod](../ModFiles/Equations/rest_of_world.mod)
- **Declarations:** [DGE_Model_Declaration.mod](../ModFiles/DGE_Model_Declaration.mod#L192-L195)
- **Simulation:** [simulation_model_refactored.m](../Functions/simulation_model_refactored.m)
- **Excel reference:** [ExcelFiles/README.md](../ExcelFiles/README.md)

