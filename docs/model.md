---

layout: default

title: Technical model documentation

---



# Technical model documentation



This page provides a technical overview of the DGE model structure as implemented in this repository. It is meant to complement the paper/report and to help anyone reproduce or extend the code.



## 1. Model overview

**Type:** Dynamic general equilibrium model implemented in Dynare with MATLAB steady-state/calibration routines.  

**Core objects:** households, firms (multiple sectors), government, external sector, and (optional) emissions/energy blocks.



> Implementation note: the economic logic lives in Dynare `.mod` files, while calibration and steady-state solving are handled in MATLAB.



## 2. Agents and blocks (conceptual)

### Households

- Preferences over consumption and leisure

- Budget constraint including wages, capital income, transfers/taxes

- (Optional) heterogeneity / aggregation, depending on the `.mod` version



### Firms

- Production by sector with nested CES/Cobb-Douglas structures (as implemented)

- Input demands (labor, capital, energy / intermediates)

- Price-setting / wage-setting blocks if included in the `.mod`



### Government

- Tax instruments, spending rules, budget constraint

- Closure rules (e.g., keep deficit fixed, adjust tax rate, etc.)



### External sector

- Imports/exports, trade balance closure

- Exchange rate / numeraire conventions (document your choice)



## 3. Where the equations live in the repo

- **Dynare model files:** `ModFiles/` (and/or `DGE\_CRED\_Model/*.mod`)

- **Steady state code:** `DGE\_CRED\_Model/*steadystate*.m` and `Functions/`

- **Calibration inputs:** `ExcelFiles/` and MATLAB `.mat` bundles



## 4. Steady state and calibration

### Steady state

- Computed in MATLAB, then passed into Dynare

- Key objects: prices, quantities, shares, and market-clearing residuals



### Calibration

- Parameter values: (i) literature, (ii) accounting identities, (iii) targets (shares/ratios), (iv) scenario assumptions  

- If you use a saved workspace (e.g., `matlab.mat`), document:

&nbsp; - which variables are “inputs”

&nbsp; - which variables are “computed”

&nbsp; - how to regenerate it from raw sources



## 5. Scenarios and shocks

Document here how your scenarios are implemented, for example:

- energy transition: technology shares, fuel switching, capacity paths

- climate impacts: productivity shocks, capital destruction, land loss, etc.

- policy closures: carbon tax, transfers, investment subsidies



**Implementation locations:**

- scenario switches in `.mod` files (parameters, `shocks; end;`, `initval; end;`)

- MATLAB scripts that load scenario assumptions and write parameter sets



## 6. Outputs

Typical outputs produced by the workflow:

- IRFs or simulated paths for macro variables

- sectoral decomposition tables/figures

- scenario comparison plots (percent deviations from baseline)



Point readers to:

- `SimulationResults*.mlx/.pdf`

- any export folder you use (recommended: `results/`)



## 7. Reproducibility checklist (recommended)

- [ ] One “main” script that runs everything end-to-end

- [ ] A pinned Dynare version + MATLAB version

- [ ] A single configuration file for scenario selection

- [ ] Clear separation of **inputs** vs **generated outputs**



