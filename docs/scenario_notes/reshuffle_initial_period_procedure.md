# Reshuffle Procedure: Initial-Period Investment and Flow Reconciliation

## Purpose

The reshuffle procedure rewrites only the first simulation period (column 1 of oo_.endo_simul) so that investment matches user-specified targets, then re-derives all dependent accounting flows in a consistent way.

This procedure is implemented in [Functions/SteadyState/reshuffle_initial_period.m](../../Functions/SteadyState/reshuffle_initial_period.m).

In normal Baseline runs, it is invoked from [Functions/simulation_model_refactored.m](../../Functions/simulation_model_refactored.m) when lReshuffleInitial_p == 1.

## Where It Sits in the Baseline Pipeline

1. Baseline exogenous paths are loaded.
2. Optional investment targets are prepared as tabtargets (from CSV or direct struct).
3. Optional PDP8 fossil/renewable I/K targets are solved by:
   [Functions/Miscellaneous/Simulation/compute_pdp8_capital_investment_ratio.m](../../Functions/Miscellaneous/Simulation/compute_pdp8_capital_investment_ratio.m).
4. Reshuffle is applied once to period 1 through:
   [Functions/SteadyState/reshuffle_initial_period.m](../../Functions/SteadyState/reshuffle_initial_period.m).
5. exo_simul_start is synchronized for exo_I shocks so the baseline homotopy does not undo the price shift.

The call site and synchronization logic are in [Functions/simulation_model_refactored.m](../../Functions/simulation_model_refactored.m).

## Inputs and Control Switches

Main runtime switches (set in run script, typically [RunSimulations.m](../../RunSimulations.m)):

- lReshuffleInitial_p:
  Enables/disables reshuffle invocation in Baseline.
- sInvestmentTargetsCsv:
  Optional CSV source for IH/IFDI/IG targets via:
  [Functions/Miscellaneous/Simulation/build_investment_targets_from_gso.m](../../Functions/Miscellaneous/Simulation/build_investment_targets_from_gso.m).
- sInvestmentTargetsIoTableXlsx, sInvestmentTargetsIoTableSheet:
  Optional proportional rescaling of all source/activity targets to match IO-table aggregate I/Y.
- lReshuffleIK_p:
  Enables optional fossil/renewable IK and PINVIndex target injection (subsectors 2 and 3 in region 1).

Manual shortcut currently present in active implementation:

- manualScaleIK2_p (optional): multiplicative factor applied to tabtargets.IK_2_1.
- manualScaleIK3_p (optional): multiplicative factor applied to tabtargets.IK_3_1.

Current default values in code are hardcoded to 0.72 and 0.65 before optional override by manualScaleIK2_p/manualScaleIK3_p. This behavior is in [Functions/simulation_model_refactored.m](../../Functions/simulation_model_refactored.m). If you want neutral defaults, set both to 1 in code or define manualScaleIK2_p=1 and manualScaleIK3_p=1 before running.

## Target Structure (tabtargets)

reshuffle_initial_period reads target fields from tabtargets.

### By-source investment targets

For each subsector/reg pair stemp = <subsec>_<reg>:

- IH_stemp: private-household investment share of nominal regional GDP.
- IFDI_stemp: FDI investment share of nominal regional GDP.
- IG_stemp: public investment share of nominal regional GDP.

Interpretation:

- IH_stemp = I_H_stemp * P_INV_stemp / Y_reg
- IFDI_stemp = I_FDI_stemp * P_INV_stemp / Y_reg
- IG_stemp = I_G_stemp * P_INV_stemp / Y_reg

Any missing or NaN target is treated as no override for that specific source/activity.

### Optional IK and price-index targets

For each stemp:

- IK_stemp:
  target real investment ratio I_total_stemp / K_stemp in period 1,
  where I_total_stemp = I_stemp + I_G_stemp.
- PINVIndex_stemp:
  relative path P_INV(t)/P_INV(1), applied through exo_I_stemp for an active time window.

In current standard use, IK_2_1, IK_3_1 and PINVIndex_2_1, PINVIndex_3_1 are supplied from:

- [Functions/Miscellaneous/Simulation/compute_pdp8_capital_investment_ratio.m](../../Functions/Miscellaneous/Simulation/compute_pdp8_capital_investment_ratio.m)

## Step-by-Step Algorithm in reshuffle_initial_period

### Step 0: Snapshot and struct conversion

The function creates local structs from:

- M_.params -> strpar
- oo_.endo_simul(:,1) -> strys
- oo_.exo_simul(1,:) -> strexo

and stores pre-reshuffle state (strys_pre) for lagged BG and s terms in the government-budget closure.

### Step 1: Apply bottom-up IH/IFDI/IG targets

For each region and subsector:

1. Read PINV and Y_reg.
2. If IH target exists: set I_H = IH * Y_reg / PINV.
3. If IFDI target exists: set I_FDI = IFDI * Y_reg / PINV.
4. If IG target exists: set I_G = IG * Y_reg / PINV.
5. Enforce firms identity: I = I_H + I_FDI.

At this point, investment is aligned to target source shares, conditional on current PINV.

### Step 1b: Optional IK reconciliation with fixed nominal anchor

If IK_stemp exists and is finite/positive:

1. Read old quantities/prices:
   Iold = I + I_G, PINVold, K.
2. Compute target real quantity:
   Inew = IK * K.
3. Compute scaling factor:
   scale = Inew / Iold (if Iold > 0).
4. Scale I_H, I_FDI, I_G by scale.
5. Recompute I = I_H + I_FDI.
6. Keep nominal investment unchanged:
   nominalOld = Iold * PINVold,
   PINVnew = nominalOld / (I + I_G).

So real investment is changed to hit IK, while period-1 nominal level is preserved by letting PINV absorb the adjustment.

### Step 1b.a: Translate PINV change into exo_I and optional relative path

For each adjusted stemp:

1. Determine PINV base:
   - if lCapGoodsSecPrice_p == 1, use parameter P0_stemp_p.
   - else use P_stemp from endo state.
2. Compute implied exo_I_new = log(PINVnew / PINVbase).
3. Compute level shift exoIShift = exo_I_new - exo_I_old(period 1).
4. Apply to oo_.exo_simul for exo_I_stemp:
   - if PINVIndex_stemp provided:
     apply exoIShift + log(PINVIndex(t)/PINVIndex(1)) from t=1..nApply,
     then hold constant from nApply+1 onward.
   - else apply level shift to period 1 only.

This is the key mechanism that moves the investment-price path while avoiding a full-horizon unconditional shift.

### Step 2-6: Recompute accounting blocks (same order as calibration pipeline)

After investment is set, dependent aggregates are recomputed by calling:

1. compute_aggregates
2. compute_regional_imports_and_demand
3. compute_tax_income
4. compute_regional_economic_accounts
5. compute_government_expenditure_and_capital

These maintain internal accounting consistency for C, G, NX, B, and related regional/national sums.

### Step 7: Close regional government budget for BG

For each region, BG_reg is recomputed as residual of the government budget identity using:

- updated C_reg, G_reg, I_G_reg, taxes, PE*E term,
- lagged BG_reg and lagged s_reg from pre-reshuffle snapshot,
- phi_BG_ext and rf terms.

### Final writeback

Only the selected names are written back to oo_.endo_simul(:,1).

No other periods in oo_.endo_simul are directly rewritten by this function.

## What Changes vs What Does Not

Changed by reshuffle:

- Period-1 investment flow variables tied to targets (I_H, I_FDI, I_G, I).
- Period-1 P_INV for entries with IK target.
- Exogenous investment price shocks exo_I_stemp in oo_.exo_simul for affected entries (period-1 shift, optional bounded tracking window).
- Re-derived period-1 accounting variables (C, G, NX, B, BG and aggregates).

Not changed by reshuffle:

- Capital stocks K, including K_H/K_FDI/K_G decomposition.
- Productivity, wages, lambda, damage stocks, and other structural state variables.
- Endogenous columns beyond period 1 (except indirectly after later model solve).

## Why exo_simul_start Resynchronization Is Required

After reshuffle, [Functions/simulation_model_refactored.m](../../Functions/simulation_model_refactored.m) copies updated exo_I paths into oo_.exo_simul_start for prod-I shock positions.

Reason: baseline homotopy logic rebuilds exo paths from exo_simul_start each step. Without resync, reshuffle-induced exo_I modifications would be overwritten.

## Diagnostics Printed by reshuffle_initial_period

Per IK-adjusted subsector/region line:

- target IK
- I+I_G before and after
- P_INV before and after
- exo_I shift and number of periods affected

Per region summary line:

- I/Y, C/Y, G/Y, NX/Y, and change in BG

These are printed from [Functions/SteadyState/reshuffle_initial_period.m](../../Functions/SteadyState/reshuffle_initial_period.m).

## Failure Modes and Guards

Built-in guards include warnings/errors for:

- non-positive IK target
- non-positive K for IK target
- zero pre-reshuffle investment when IK scaling is requested
- missing/invalid PDP8 inputs upstream in compute_pdp8_capital_investment_ratio

Practical failure patterns:

- Overly large permanent exo_I shifts can compound with active muI targeting and inflate capital paths.
- Omitting PINVIndex in contexts where the solved path requires time-varying tracking can under-correct later periods.
- stale exo_simul_start will silently undo exo_I adjustments during baseline stepping.

## How to Use in Practice

### Option A: Build targets from GSO ownership CSV

1. Set sInvestmentTargetsCsv.
2. Optionally set IO table path for aggregate rescaling.
3. Keep lReshuffleInitial_p = 1.
4. Optionally enable lReshuffleIK_p = 1 for subsectors 2 and 3 IK/PINV path alignment.

Target builder:
[Functions/Miscellaneous/Simulation/build_investment_targets_from_gso.m](../../Functions/Miscellaneous/Simulation/build_investment_targets_from_gso.m)

### Option B: Provide tabtargets directly

Define selected fields manually, for example:

- tabtargets.IFDI_3_1 = 0.015
- tabtargets.IG_1_1 = 0.020
- tabtargets.IK_2_1 = <value>
- tabtargets.IK_3_1 = <value>
- tabtargets.PINVIndex_2_1 = <vector>
- tabtargets.PINVIndex_3_1 = <vector>

Unspecified entries stay at pre-reshuffle values.

### Optional manual IK shortcut in current code

In [Functions/simulation_model_refactored.m](../../Functions/simulation_model_refactored.m), IK_2_1 and IK_3_1 are currently multiplied by manualScaleIK2/manualScaleIK3 defaults before optional override by manualScaleIK2_p/manualScaleIK3_p.

Use this only as an operational shortcut. It is not a full calibration solver.

## Minimal Validation Checklist

After a Baseline run:

1. Confirm reshuffle logs are printed for intended subsectors.
2. Verify period-1 investment composition matches requested IH/IFDI/IG shares.
3. Verify period-1 IK for targeted subsectors is close to requested IK.
4. Verify exo_I_2_1 and exo_I_3_1 paths contain intended level shift and bounded tracking window.
5. Confirm accounting identities remain consistent in period 1 (I, C, G, NX, BG summaries).
6. Confirm homotopy steps preserve reshuffled exo_I path (no reversion).

## Related Files

- Core reshuffle implementation:
  [Functions/SteadyState/reshuffle_initial_period.m](../../Functions/SteadyState/reshuffle_initial_period.m)
- Baseline integration and target preparation:
  [Functions/simulation_model_refactored.m](../../Functions/simulation_model_refactored.m)
- GSO target builder:
  [Functions/Miscellaneous/Simulation/build_investment_targets_from_gso.m](../../Functions/Miscellaneous/Simulation/build_investment_targets_from_gso.m)
- PDP8 IK solver and PINVIndex generation:
  [Functions/Miscellaneous/Simulation/compute_pdp8_capital_investment_ratio.m](../../Functions/Miscellaneous/Simulation/compute_pdp8_capital_investment_ratio.m)
- Run configuration entry:
  [RunSimulations.m](../../RunSimulations.m)

## Status and Scope

This document describes the currently implemented behavior in repository source as of 2026-07-19, including the present manual IK shortcut logic in the Baseline setup block.
