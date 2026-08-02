# Summary: Import Shock Variables — Already Implemented

**Status: ✅ The import shock variables are ALREADY DECLARED and IMPLEMENTED in the model.**

No code changes are needed. You can begin investigating import shocks immediately by setting up scenarios in Excel and running simulations.

---

## What Exists

### Three Exogenous Variables (per subsector)

| Variable | Declaration | Purpose |
|----------|-------------|---------|
| `exo_M_@{subsec}` | [DGE_Model_Declaration.mod:193](../ModFiles/DGE_Model_Declaration.mod#L193) | Exogenous import price wedge |
| `exo_lMAmount_@{subsec}` | [DGE_Model_Declaration.mod:194](../ModFiles/DGE_Model_Declaration.mod#L194) | Binary mode toggle (0=price, 1=amount) |
| `exo_MAmt_@{subsec}` | [DGE_Model_Declaration.mod:195](../ModFiles/DGE_Model_Declaration.mod#L195) | Log growth shock for import volumes |

### Hybrid Equation (Implemented)

[rest_of_world.mod:10-18](../ModFiles/Equations/rest_of_world.mod#L10-L18)

The equation automatically switches between two regimes:
- **Price shock regime** (`exo_lMAmount = 0`): Import price moves via `exo_M_`
- **Amount shock regime** (`exo_lMAmount = 1`): Import quantity moves via `exo_MAmt_`, price determined endogenously

---

## How to Start

### Quick Path (5 minutes)

1. **Copy a reference scenario** to create `ImportShock_Fossil` in `ExcelFiles/ModelScenarios*.xlsx`
2. **Set shock values** in the new sheet:
   - `exo_lMAmount_2` = 0 (or 1 for amount shock)
   - `exo_M_2` = 0.10 (10% price increase)
3. **Run** in MATLAB:
   ```matlab
   setup_paths; RunSimulations;
   ```
4. **Analyze** results in `structScenarioResults.mat`

### Detailed Path

Follow the two implementation guides created in `docs/implementation_plans/`:

1. **[import_shock_checklist.md](./import_shock_checklist.md)** — Phase-by-phase checklist (15 min read, then apply)
2. **[import_shock_investigation_guide.md](./import_shock_investigation_guide.md)** — Comprehensive technical reference (model equations, theory, examples)

---

## Subsectors (5-Sector, 1-Region Configuration)

- Subsector 1: Primary
- Subsector 2: Fossil
- Subsector 3: Renewables
- Subsector 4: Secondary (manufacturing)
- Subsector 5: Tertiary (services)

**Target subsector:** Set `exo_lMAmount_@{subsec}`, `exo_M_@{subsec}`, and `exo_MAmt_@{subsec}` in your scenario sheet.  
**Untouched subsectors:** Keep all three variables = 0.

---

## Example Shocks

### Fossil Energy Price Spike (10% increase)

```
exo_lMAmount_2 = 0  (all periods)
exo_M_2 = 0.10      (period 2+)
exo_MAmt_2 = 0      (all periods)
```

### Supply Chain Disruption (20% volume decline)

```
exo_lMAmount_4 = 1  (period 2-4)
exo_MAmt_4 = -0.20  (period 2-3, log growth)
exo_lMAmount_4 = 0  (period 5+, return to normal)
```

---

## What to Check First

- [ ] **Baseline:** Open `ExcelFiles/ModelBaseline*.xlsx` → `Baseline` sheet
  - Verify `exo_lMAmount_*`, `exo_M_*`, `exo_MAmt_*` rows exist and are all 0

- [ ] **Existing scenarios:** Open `ExcelFiles/ModelScenarios*.xlsx`
  - Check if any scenarios already include import shocks (use as template)

- [ ] **Model compile:** Run `setup_paths; dynare DGE_Model.mod` (should complete without errors related to import variables)

---

## Files Changed

Two implementation guides created in `docs/implementation_plans/`:

1. **import_shock_investigation_guide.md** (6 KB)
   - Full technical guide with equations, step-by-step setup, analysis examples
   - Sections: Overview, Implementation, Step-by-Step Setup, Running, Analyzing, Examples

2. **import_shock_checklist.md** (3 KB)
   - Practical checklist for quick execution
   - Phases: Pre-Setup, Excel Setup, MATLAB Setup, First Run, Analysis, Troubleshooting

**No model code changes required.** The infrastructure is already complete.

---

## Next: Your Next Steps

1. **Read** [import_shock_checklist.md](./import_shock_checklist.md) (10 min)
2. **Setup** your first scenario in Excel (Phase 1, ~30 min)
3. **Run** `RunSimulations` (Phase 3, ~10 min)
4. **Analyze** results using templates in the guide

Questions or issues? See the **Troubleshooting** section of the checklist or the **Appendix** of the detailed guide.

