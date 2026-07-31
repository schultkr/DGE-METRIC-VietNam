# Capital / Investment Path Targeting — Implementation Log

This document records the design decisions, failed attempts, working solutions, and open problems encountered while implementing the ability to target a **specific total-capital or investment path** for energy sub-sectors (fossil and renewable) in DGE-METRIC / DGE-CRED. It is written so that someone picking up the work cold can understand *why* each choice was made without having to re-derive it.

---

## 1. What We Were Trying to Do

In the energy-transition scenarios we need to impose an **exogenous capital accumulation path** for specific sub-sectors — for example, to enforce a pre-determined fossil-capital phase-out or a renewable build-out that matches an external engineering forecast.

The model decomposes total sector capital `K_` into three components:

```
K_ = K_H_ + K_G_ + K_FDI_
```

| Component | Owner | Equation |
|-----------|-------|---------|
| `K_H_` | Domestic households | Euler + capital LOM |
| `K_G_` | Government | ExoSubsec_11 / ExoSubsec_12 (investment share) |
| `K_FDI_` | Foreign investors | Exogenous rental rate `r_FDI_` |

The rental-clearing identity (firm FOC for capital) links these via:

```
r_F_ · K_ = r_H_ · K_H_ + r_G_ · K_G_ + r_FDI_ · K_FDI_
```

The existing **`exo_lTargetInv` / `wedgeKE`** mechanism already allowed targeting household investment `I_H_` by inserting a wedge into the Euler equation, effectively deactivating it when a target path is imposed. The challenge was to do the same at the **total-capital level**, coordinating public and FDI components.

---

## 2. Existing Mechanisms (Prior Art in the Model)

### 2.1 `exo_lTargetInv` + `wedgeKE`
- Declared in `ModFiles/DGE_Model_Declaration.mod`.
- `wedgeKE_` enters the Euler equation for household investment; when non-zero it absorbs the equilibrium residual, effectively turning off the optimality condition.
- Used for scenarios that need sector-level investment to follow an externally prescribed path.

### 2.2 `ExoSubsec_12` — Government investment share
- Controls public-sector investment `I_G_` via an exogenous share `s_G_`.
- The switch `exo_KTargetB_` allows converting the share into an absolute capital target denominated in output units.

### 2.3 `ExoSubsec_13` — Public rental rate
- Before this work: `r_G_ = rf0_p + exo_r_G_` (fixed exogenous rate).
- The model implicitly uses this as an instrument: changing `r_G_` shifts the attractiveness of government capital relative to household capital.

---

## 3. Design Goal

We wanted a runtime **on/off switch** for K-targeting that, when activated, re-purposes the equation for `r_G_` so that instead of setting the rental rate exogenously, it **targets total capital `K_`** and lets `r_G_` be determined endogenously from the rental-clearing identity.

---

## 4. Option A — Direct K_ Pin via Blended ExoSubsec_13 (Implemented)

### 4.1 The Blended Equation

`ExoSubsec_13` in `ModFiles/Equations/government.mod` was turned into a blended switch:

```
lhs = lKTargetSwitch * K_  + (1 - lKTargetSwitch) * r_G_
rhs = lKTargetSwitch * K0_p * exp(exo_KRGTarget_)
    + (1 - lKTargetSwitch) * (rf0_p + exo_r_G_)
```

- `lKTargetSwitch = 0` → original behaviour: `r_G_ = rf0_p + exo_r_G_`
- `lKTargetSwitch = 1` → pin total capital: `K_ = K0_p * exp(exo_KRGTarget_)`

This is a **soft blend** that keeps the equation count and structure unchanged — no equation is added or removed, only the roles of `K_` and `r_G_` swap.

**Files changed:**
- `ModFiles/Equations/government.mod` (ExoSubsec_13 block)
- `ModFiles/DGE_Model_Declaration.mod` (new exogenous variable `exo_KRGTarget_`)

**Commit:** `a942f93` — *Add K_ targeting via r_G instrument (blended ExoSubsec_13, steady-state helpers)*

### 4.2 Steady-State Helper: `set_k_target_and_backout_rg`

A new helper function was created at `Functions/SteadyState/set_k_target_and_backout_rg.m`. It is called from `compute_production_factors_and_output.m` whenever K-targeting is active, and performs the following steps:

**Step 1 — Fix total capital to target:**
```matlab
K_target = K0_p * exp(exo_KRGTarget_);
K_ = K_target;
```

**Step 2 — Split into components:**
```matlab
K_FDI = max(0, K_target - K0_p);     % FDI absorbs any excess above baseline
K_H   = max(0, K_target - K_G - K_FDI);  % HH gets the remainder
```
The logic here is that `K_G_` is already determined by ExoSubsec_11/12 before this function runs. FDI is brought in to close the gap between the target and the calibrated baseline level `K0_p`, leaving `K_H_` unchanged from its calibrated share `K0_p * (1 - phiG)`.

**Step 3 — Derive `r_F_` from the firm FOC:**
For CES production:
```matlab
rkgross_PK = alphaK^(1/etaNK) * [(1-D)*A*A_K]^rho * (Kserv/Y)^(-1/etaNK) * P/P_K;
r_F_ = rkgross / (1 + tauKF);
```
For Cobb-Douglas (`etaNK = 1`):
```matlab
r_F_ = alphaK * Y * P / (P_K * Kserv * (1 + tauKF));
```

**Step 4 — Back out `r_G_` from rental clearing:**
```matlab
r_G_ = (r_F_ * K_ - r_H_ * K_H - r_FDI_ * K_FDI) / K_G_;
```
Then `exo_r_G_` is updated so that ExoSubsec_13 stays self-consistent:
```matlab
exo_r_G_ = r_G_ - rf0_p;
```

**Step 5 — Update investment:**
```matlab
I_H_ = K_H * delta + D_K * (K_H > 0);
I_FDI_ = K_FDI * delta;
ILR_ = I_H_;
```

**Files changed:**
- `Functions/SteadyState/set_k_target_and_backout_rg.m` (new file, 82 lines)
- `Functions/SteadyState/compute_production_factors_and_output.m`
- `Functions/setupInitialState/compute_pf_parameters.m`

### 4.3 Why This Works for the Steady State

The steady-state solver runs iteratively. By injecting the target value of `K_` and backing out `r_G_` analytically, the MATLAB solver sees a self-consistent starting point. The Dynare-preprocessed static residuals then agree with the Dynare equation, because `exo_r_G_` is also updated to match.

### 4.4 Known Issue: Perfect-Foresight Solver Singularity

**The dynamic (perfect-foresight) solver remains singular when K-targeting is active.**

**Reason:** The Euler equation for household investment remains active in Dynare. The blended ExoSubsec_13 pins `K_` directly, but the Euler equation is also attempting to optimise over `I_H_` (and thus `K_H_`). Because `K_ = K_H_ + K_G_ + K_FDI_` is fixed and `K_G_` is pre-determined, the Euler equation loses its degree of freedom. The Jacobian of the system is rank-deficient → singular.

This means the dynamic scenario runs fail when this switch is active.

---

## 5. Refinement — FDI Capital at Steady State

**Commit:** `d5afbdc` — *Allow non-zero FDI capital at steady state when K-targeting is active*

### 5.1 Problem

In the first implementation (Step 2 above), when `K_target > K0_p` (i.e., we need more total capital than the baseline), the original code incorrectly assumed the excess went to `K_H_`. This is wrong because:
- `K_H_` is governed by the Euler equation; its steady-state level is pinned by the no-arbitrage condition between `r_H_` and the HH discount rate.
- Forcing `K_H_` above its equilibrium value violates the HH optimality condition and creates solver instability.

### 5.2 Fix

FDI capital is used as the **residual absorber**: foreign investors supply capital at the exogenous rate `r_FDI_ = rf0_p + exo_r_FDI_`. In the K-targeting regime:

```matlab
K_FDI = max(0, K_target - K0_p);  % excess above calibrated baseline → FDI
K_H   = max(0, K_target - K_G - K_FDI);  % K_H anchored near K0*(1-phiG)
```

This separation ensures `K_H_` stays close to its calibrated equilibrium, which avoids violating the Euler equation at the starting steady state.

### 5.3 Files Changed

| File | Change |
|------|--------|
| `Functions/SteadyState/set_k_target_and_backout_rg.m` | Updated K_FDI/K_H logic; rental clearing now includes `r_FDI_ * K_FDI` term |
| `Functions/SteadyState/compute_production_factors_and_output.m` | K_H_ subtracts K_FDI_ in all three branches (CES/CD/climate); K_FDI_ zero-init guarded by the K-targeting switch being off |
| `Functions/setupInitialState/compute_pf_parameters.m` | K_FDI_/I_FDI_/r_FDI_ initialisation moved to `else` branch (skip when switch is ON) |
| `Functions/simulation_model_refactored.m` | `exo_r_FDI_` shocks included in `stepFrac` scaling and `baseVars` interpolation |
| `DGE_Model.mod`, `+DGE_Model/driver.m`, `RunSimulations.m` | Reduced `iStepSimulation` from 40 → 20 (faster debugging) |

---

## 6. Current State of the Code (as of 2026-05-25)

### Runtime Switch Summary

| Exogenous variable | Type | Meaning |
|-------------------|------|---------|
| `exo_KRGTarget_<s>_<r>` | Log-deviation | Target: `K_ = K0_p * exp(exo_KRGTarget_)` |
| `exo_r_G_<s>_<r>` | Level shift | Backed out endogenously when switch is ON |
| `exo_r_FDI_<s>_<r>` | Level shift | FDI rental rate (above `rf0_p`) |

### What Works
- Steady-state computation with K-targeting active: K_, K_H_, K_G_, K_FDI_ are all consistent with the target.
- Steady-state path over multiple periods (baseline loop) works cleanly.
- Backward compatibility: when K-targeting is not activated, the model is exactly identical to before.

### What Does Not Work Yet
- **Perfect-foresight dynamic simulation is singular** when K-targeting is active. Dynare's Newton solver fails because the Euler equation for I_H_ is redundant given the pinned K_.

---

## 7. Planned Fix: Option B — Investment-Wedge Approach

The correct fix mirrors the existing `exo_lTargetInv` / `wedgeKE` mechanism:

1. When K-targeting is active, add a **wedge** `wedgeKRG_` to the Euler equation for I_H_ (or directly deactivate the Euler) so that the equation is no longer a genuine optimality condition.
2. The system then has one fewer equilibrium condition and one more degree of freedom — exactly compensating for the pinned `K_`.
3. The wedge itself carries the shadow price of the capital constraint, which is economically interpretable.

**Key difference from Option A:**
- Option A: pins K_ directly via a Dynare equation; Euler stays active → singular.
- Option B: pins I_H_ via Euler-wedge; K_ follows from the LOM → no singularity.

**Implementation path:**
- In `ModFiles/Equations/investment_adjustment.mod` (the `HH FOC investment` equation), blend the Euler condition with the K-target in the same way ExoSubsec_13 was blended.
- Declare `wedgeKRG_<s>_<r>` as an endogenous variable (absorbs the residual).
- In the steady-state helper, set `wedgeKRG_` = 0 (targeting is already achieved via the K path) and set the initial dynamic value to 0.

---

## 8. Lessons Learned

| Lesson | Detail |
|--------|--------|
| **Pinning a stock directly creates a singular Jacobian** | Any equation that hard-pins `K_t` removes the column for `I_H_{t-1}` from the Jacobian. Use a wedge in the flow equation instead. |
| **K_H_ must stay near its Euler-implied level** | Deviating K_H_ from its no-arbitrage value at the starting SS breaks the dynamic initialisation even if the static residual is zero. |
| **FDI capital is the right residual absorber** | It enters capital accounting but is NOT governed by a domestic Euler equation — it takes any value set by the exogenous `r_FDI_` and the rental clearing identity. |
| **Always update `exo_r_G_` after backing out `r_G_`** | ExoSubsec_13 reads `rf0_p + exo_r_G_` even when K-targeting is on; if `exo_r_G_` is stale, the Dynare static residual will disagree with the MATLAB steady state. |
| **Reduce `iStepSimulation` during debugging** | Fewer homotopy steps means errors surface faster. Default is 40; use 20 for development. Reset before production runs. |
| **Blended equation structure is cleaner than conditional preprocessing** | Using `lhs = alpha * X + (1-alpha) * Y` keeps equation count constant and avoids re-preprocessing the model for different switch values. |

---

## 9. Key File Locations

| File | Purpose |
|------|---------|
| `ModFiles/Equations/government.mod` (ExoSubsec_13) | Blended K-targeting / r_G equation |
| `ModFiles/DGE_Model_Declaration.mod` | Declaration of `exo_KRGTarget_`, `r_FDI_` |
| `Functions/SteadyState/set_k_target_and_backout_rg.m` | Steady-state K_ pin and r_G_ back-out |
| `Functions/SteadyState/compute_production_factors_and_output.m` | Calls the helper; handles K_H/K_FDI branches |
| `Functions/setupInitialState/compute_pf_parameters.m` | Parameter initialisation — guards K_FDI zero-init |
| `Functions/simulation_model_refactored.m` | Simulation loop — includes exo_r_FDI_ in interpolation |
| `ModFiles/Equations/investment_adjustment.mod` | Euler equation / LOM — target for Option B wedge |

---

## 10. Related Existing Mechanisms (Cross-Reference)

| Mechanism | Switch | Equation file | Description |
|-----------|--------|---------------|-------------|
| Household investment target | `exo_lTargetInv` | `investment_adjustment.mod` | Wedge in Euler deactivates optimality |
| Government investment share | `exo_s_G_` / `exo_KTargetB_` | `government.mod` (ExoSubsec_12) | Exo share of GDP going to public K_ |
| Government capital stock path | `exo_K_G_` | `government.mod` (ExoSubsec_14) | Direct path for K_G_ |
| FDI rental rate | `exo_r_FDI_` | `government.mod` (ExoSubsec_15) | Exogenous foreign investor rate |
| Total K_ target (this work) | `exo_KRGTarget_` | `government.mod` (ExoSubsec_13) | K_ pin; r_G_ endogenous |
