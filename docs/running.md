# How to Run the DGE-METRIC

This guide explains how to install the required software, set up scenario inputs, and run simulations using the **DGE-METRIC** (Dynamic General Equilibrium for Macroeconomic Energy Transition with Carbon Markets) model. It is designed to fit on one page and provide a clear, reproducible workflow.

---
## 📘 Documentation Overview

- **Project overview:** [Home](index.md)
- **Model structure & equations:** [Model documentation](model.md)
- **Scenario design & assumptions:** [Scenarios](scenario.md)
- **Calibration & data sources:** [Calibration](calibration.md)
- **How to run the model:** [Running the model](running.md)


## 1. Software Requirements

You need the following software installed locally:

- **MATLAB** (recommended: R2020a or newer)
- **Dynare** (recommended: Dynare 6.x)
- **Git** (optional, for cloning the repository)

---

## 2. Installing Dynare

### Windows (recommended)

1. Download Dynare from the official Dynare website.
2. Install Dynare, for example to:
   ```
   C:\dynare\6.1\
   ```
3. Open MATLAB and add Dynare to the MATLAB path:
   ```matlab
   addpath('C:\dynare\6.1\matlab')
   savepath
   ```
4. Verify the installation:
   ```matlab
   dynare --version
   ```

If Dynare prints its version number, the installation is successful.

---

## 3. Repository Setup

1. Clone or download the repository:
   ```bash
   git clone <REPOSITORY_URL>
   ```
2. Open MATLAB and set the repository root as the **Current Folder**.
3. Add the required model paths:
   ```matlab
   addpath(genpath(fullfile(pwd,'Functions')))
   addpath(genpath(fullfile(pwd,'DGE_CRED_Model')))
   addpath(genpath(fullfile(pwd,'ModFiles')))
   ```

---

## 4. Scenario Setup

Scenarios are defined through calibration and assumption files stored in `ExcelFiles/`.  
Each scenario uses a consistent name across MATLAB scripts, Dynare runs, and output files.

Typical scenario names include:
- `Baseline`
- `NZ`
- `NZ_constInt`
- `NZ_constEE`
- `NZ_constEEInt`

All scenarios are solved from the same initial steady state to ensure comparability.

---

## 5. Running the Model

1. Identify the main Dynare model file in:
   ```
   ModFiles/
   ```
   (e.g. `model_main.mod`).

2. Run the model from MATLAB:
   ```matlab
   dynare ModFiles/model_main.mod
   ```

After a successful run, Dynare stores results in memory (`oo_`, `M_`, `options_`).

---

## 6. Exporting Results

Model outputs are typically written to scenario-specific CSV files:
```
ExcelFiles/Output/<scenario>.csv
```

These files contain time series for key variables such as GDP, emissions, energy use, prices, and investment.

---

## 7. Plotting and Figures

A separate MATLAB script reads the CSV files, generates scenario comparison plots, and saves all figures to:
```
pictures/
```

Figures are automatically exported at high resolution and named using their figure titles.

---

## 8. Recommended Workflow

A typical workflow is:

1. Install MATLAB and Dynare  
2. Set MATLAB paths  
3. Configure scenario inputs  
4. Run Dynare for each scenario  
5. Export results to CSV  
6. Generate and save figures  

For details on the model structure and equations, see `model.md`.
