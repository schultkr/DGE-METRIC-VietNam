# DGE-METRIC / DGE-CRED Model (Vietnam)

This repository contains my working implementation of a **Dynamic General Equilibrium (DGE)** model (DGE-CRED / DGE-METRIC variant) used to simulate macroeconomic and sectoral impacts under alternative climate and energy-transition pathways. The codebase combines **Dynare `.mod` files**, **MATLAB steady-state/calibration routines**, and supporting **Excel inputs**.

➡️ **Start here (GitHub Pages):** `docs/index.md`  
➡️ **Technical model description:** `docs/model.md`

---

## 📘 Documentation Overview

- **Project overview:** [Home](index.md)
- **Model structure & equations:** [Model documentation]('docs/model.md')
- **Scenario design & assumptions:** [Scenarios](docs/scenario.md)
- **Calibration & data sources:** [Calibration](docs/calibration.md)
- **How to run the model:** [Running the model](docs/running.md)

---
## What’s in this repository?

At a high level, we use:
- **Dynare** to define and solve the dynamic model (`.mod`).
- **MATLAB** to compute/calibrate the steady state, assemble parameters, and run scenario workflows.
- **Excel** files as curated inputs/assumptions (as needed).

---

## Repository structure (quick map)

Below is the intended navigation by folder. (Names reflect what you see in the repo; adjust descriptions if you rename anything.)

- `DGE_CRED_Model/`  
  Main model workspace: Dynare model files, steady-state routines, and scripts to run simulations and produce results.

- `+DGE_CRED_Model/`  
  MATLAB package folder (namespace `DGE_CRED_Model.*`) for more structured code (helpers, class-like organization).

- `ModFiles/`  
  Dynare `.mod` files (model equations, shocks, closures, scenario switches).

- `Functions/`  
  MATLAB helper functions (steady state blocks, aggregation, plotting, IO routines).

- `ExcelFiles/`  
  Input data and calibration sheets (assumptions, sector/region mappings, scenario parameters).

- `CheckResults.m`  
  Quick consistency checks / sanity checks for outputs.

- `RunSimulationsSSP185.m` (and similar scripts)  
  End-to-end scripts: load calibration → solve steady state → run scenarios → export figures/tables.

- `SimulationResults*.mlx/.pdf`  
  Outputs / reports (generated).

- `matlab.mat`, `structScenarioResults*.mat`  
  Saved MATLAB workspaces / result structures (generated artifacts).
---

## Getting started

### Requirements
