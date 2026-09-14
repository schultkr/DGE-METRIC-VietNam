# Deriving a CO2 price path from Decisions 232/263 — plan and cap trajectory

> **Status: plan only, not implemented.** No `.mod`, MATLAB, or workbook changes have been made.
> This document lays out the cap trajectory and the exact conversion needed to turn it into a
> model-implied CO2 price; it does not itself add a scenario, edit
> `ScenarioPathDefinition.xlsx`, or run the model.

Source: `vietnam_ets_decisions_232_263_summary.md` (GIZ_Vietnam_Energy/IWH_Revisions Dropbox note),
summarizing Decision No. 232/QD-TTg (24 Jan 2025, carbon market scheme) and Decision No.
263/QD-TTg (9 Feb 2026, 2025-2026 pilot allowance caps).

## 1. Why this can't be "the decisions' price path"

The source note is explicit (§3): the decisions **do not** specify a future carbon-price path —
"the allowance price is intended to emerge from the market." They specify **quantity caps**. §4's
own recommendation is to "determine the permit price endogenously from the binding cap, rather
than treating the decisions as specifying a carbon-tax rate."

So there is no year-by-year price number to transcribe. What the decisions give us is a cap
trajectory (`E_1`, via `exo_EBase_1`/`exo_E_1` under `CapandTrade=1`); the price (`PE_1`) can only
come out of *running the model* against that cap. This document builds the cap trajectory only.
Producing the resulting price still requires wiring a scenario with `CapandTrade=1` and running it
— out of scope here per the chosen deliverable.

## 2. Coverage-fidelity caveat (accepted approximation)

Decision 263's caps cover only 110 facilities in 3 of the model's 5 subsectors (thermal power,
iron/steel, cement — roughly the fossil + part of secondary/industrial subsectors). The compiled
model has **no partial-ETS-coverage mechanism**: `E_ETS_<reg>` is defined to track total regional
emissions `E_<reg>` exactly (`ModFiles/Equations/climate_emissions.mod:41-45`), and the
`xi_*`-coverage-rate extension that would let a cap bind on a genuine subset is only a proposal
(`docs/implementation_plans/ETS_coverage_implementation_prompt.md:1-7`, "proposed, not
implemented").

**Accepted approximation for this plan**: bind the cap on the full regional aggregate `E_1`, as if
pilot coverage were economy-wide. This is known to **understate** the true pilot-implied price —
the same physical tonnage cap applied to a smaller real covered base implies a *higher* shadow
price than applying it to the whole economy. Flag this explicitly wherever the resulting numbers
are used; do not present the resulting price as "the Decision 263 price."

## 3. Cap trajectory: legislated years vs. assumed years

| Year(s) | Cap (tCO2e) | Status | Source / rationale |
|---|---|---|---|
| 2025 | **243,082,392** | Legislated | Decision No. 263/QD-TTg, Art. 1 |
| 2026 | **268,391,454** | Legislated | Decision No. 263/QD-TTg, Art. 1 |
| 2027–2028 | **not set by any decision** | Assumption needed | Decision 232 only says piloting continues through end-2028; no cap number is given |
| 2029–2050 | **not set by any decision** | Assumption needed | Decision 232 only says "official nationwide operation" with possible broadened coverage from 2029; no cap trajectory or coverage schedule is given |

Implied 2025→2026 growth rate: `268,391,454 / 243,082,392 − 1 ≈ 10.41%/yr`. This growth reflects
Decision 263's own administrative allocation, not a policy-committed trend — treat it as
descriptive of the pilot's first year, not predictive of the next two.

### 2027–2028 (pilot continues, no new cap published)

Two defensible fill-in rules — pick one and label it as an assumption in whatever workbook row
carries it (do not let it read as legislated):

- **(a) Hold the pilot growth rate** (~10.41%/yr) through 2028 → `2027 ≈ 296.3` Mt,
  `2028 ≈ 327.1` Mt. Rationale: treats continued facility/coverage expansion during the pilot as
  roughly proportional to the observed 2025→2026 step.
- **(b) Freeze at the 2026 level** (268.39 Mt flat through 2028). Rationale: treats the cap as an
  institutional-capacity ceiling fixed until the pilot formally ends, since Decision 232 gives no
  indication caps grow mechanically year over year.

Recommendation if a single default is needed: **(b), freeze at 2026 level** — it is the more
conservative reading of "pilot continues" and doesn't manufacture a trend the decisions never
state.

### 2029 onward (official phase)

Decision 232 ties official-phase design to "possible expansion to additional sectors and
facilities" with no schedule. Rather than inventing a second unrelated number, **adopt whatever
cap trajectory the model's existing NZ scenario group already uses for `exo_EBase_1`/`exo_E_1` from
2029 onward, unchanged** — this satisfies §4's own instruction to "use the national
net-zero-by-2050 target to define the long-run emissions path" without introducing a path that
conflicts with the model's other net-zero scenario. Read the NZ sheet's `exo_EBase_1`+`exo_E_1`
values for 2029-2050 directly (`ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx`, sheet `NZ`)
rather than re-deriving them.

This gives a three-piece cap path: **2025-2026 legislated → 2027-2028 assumption (frozen at 2026
level, by default) → 2029-2050 = NZ scenario's existing cap**, with the join at 2028→2029 left as a
discrete step (or optionally linearly bridged over 2029-2030) rather than smoothed, so the
legislated/assumed/adopted segments stay visibly distinct.

## 4. Converting the cap (tCO2e) into model units (`exo_EBase_1`/`exo_E_1`)

The cap-and-trade closure pins the regional aggregate as (`climate_emissions.mod:60-66`):

```
E_1 = E0_1_p * exp(exo_EBase_1 + exo_E_1)
```

`E0_1_p = 1` (normalization constant, `ModFiles/DGE_Model_Parameters.mod:169`), so:

```
exo_EBase_1 + exo_E_1 = ln(E_1)
```

`E_1` itself is a model index, not tCO2e. Convert the real-world cap into that index using the same
anchor ratio `generate_baseline_co2_ets_figures.m` already uses in the other direction
(`modelToMtCO2e = energyGHGAnchorMtCO2e / E_1(anchor_year)`, anchor = 352.8946 MtCO2e in 2023
mapped to the model's 2025 point). Inverting it:

```
E_1(target year) = CapMt(target year) / modelToMtCO2e
exo_EBase_1(target year) + exo_E_1(target year) = ln( CapMt(target year) / modelToMtCO2e )
```

where `modelToMtCO2e` must be read from an actual Baseline run's `E_1` value at the 2025 anchor
year (it is not a fixed calibration constant — it depends on the run, exactly as computed at
`generate_baseline_co2_ets_figures.m:99-105`). Concretely, to get numeric `exo_EBase_1`/`exo_E_1`
values for 2025-2028 (and to check the 2029 join against the NZ path), someone will need to:

1. Run (or reuse an existing) Baseline `_replication.csv` to read `E_1` at 2025.
2. Compute `modelToMtCO2e = 352.8946 / E_1(2025)`.
3. For each target year, divide the tCO2e cap by `modelToMtCO2e`, take the log, and split the
   result between `exo_EBase_1` (if a distinct "base" path is already carrying something) and
   `exo_E_1` (the free shock column) — in the Baseline sheet as it stands today `exo_EBase_1` is
   not an actively-driven column, so the simplest approach is to put the whole log term into
   `exo_E_1` and leave `exo_EBase_1` at its existing value.

## 5. What happens after this (out of scope here)

Only once this cap path is written into `exo_E_1` for a scenario compiled with `CapandTrade=1` and
the model is actually run does `PE_1` become the "model-implied CO2 price consistent with Decision
263's pilot caps." That price is an output of `perfect_foresight_solver`, not something derivable
by hand from the decisions or from this document. If/when that run is wanted, the existing
machinery in `generate_baseline_co2_ets_figures.m` (`emission_price_usd_per_tco2e`) already converts
the resulting `PE_1` into USD/tCO2e using the same anchors used here — no new reporting code would
be needed.
