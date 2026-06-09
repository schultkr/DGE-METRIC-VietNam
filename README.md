# DGE-METRIC

This repository contains the implementation of a **Dynamic General Equilibrium (DGE)** model (DGE-CRED / DGE-METRIC variant) used to simulate macroeconomic and sectoral impacts under alternative climate and energy-transition pathways. The codebase combines **Dynare `.mod` files**, **MATLAB steady-state/calibration routines**, and supporting **Excel inputs**.

## 📘 Documentation Overview

- 🏠 [Home](docs/index.md)
- 🧮 [Model](docs/model.md)
- ▶️ [Running](docs/running.md)
- ⚙️ [Dynare Install (MATLAB, Octave, MATLAB Online)](docs/running.md#install-dynare)

---

## What’s in this repository?

At a high level, we use:

- **Dynare** to define and solve the dynamic model (`.mod`).
- **MATLAB** to compute/calibrate the steady state, assemble parameters, and run scenario workflows.
- **Excel** files as curated inputs/assumptions (as needed).

---

## Repository structure (quick map)

Below is the intended navigation by folder. (Names reflect what you see in the repo; adjust descriptions if you rename anything.)

- `DGE_CRED_Model/`Main model workspace: Dynare model files, steady-state routines, and scripts to run simulations and produce results.
- `ModFiles/`Dynare `.mod` files (model equations, shocks, closures, scenario switches).
- `Functions/`MATLAB helper functions (steady state blocks, aggregation, plotting, IO routines).
- `ExcelFiles/`Input data and calibration sheets (assumptions, sector/region mappings, scenario parameters).
- `matlab.mat`, `structScenarioResults*.mat`
