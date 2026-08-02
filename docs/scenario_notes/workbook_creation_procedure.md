# Workbook Restoration Procedure

This is the operational runbook for rebuilding DGE-METRIC's Excel workbooks from scratch if any of
them are lost, corrupted, or found to contain stale/placeholder data. It reflects the actual,
tested pipeline as of commit `13a5c9a` (2026-07-22) — not the aspirational split-workbook flow
described in older versions of this document, which relied on `Baseline_Input`/`Baseline_calc`/
`Baseline_Implied` sheets that do not currently exist in the live `ModelBaseline...xlsx` (see
[Known gaps](#known-gaps-accepted-limitations) below).

## The three workbooks and their dependency order

```
ExcelFiles/ScenarioPathDefinition.xlsx          (canonical hand-maintained source of truth)
        │  Baseline sheet: VA/employment shares+growth, and ~15 "Optional block"
        │  exogenous paths (emissions, public capital, investment prices/rates,
        │  demographics, rooftop PV, FDI, emissions price)
        ▼
scripts/maintenance/create_baseline_from_user_input_file.m
        ▼
ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx   (values-only "Baseline" sheet, read by Dynare)
        ▼
scripts/maintenance/create_ee_scenarios_from_expert_inputs.m
        ▼
ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx  (EE_PDP8, EE_Directive10, EE_PDP8_PV_BESS + NoBESS)
        ▼
(sync back into ScenarioPathDefinition.xlsx's EE sheets — optional, for template completeness)
```

**Restore in this order.** `ScenarioPathDefinition.xlsx` is upstream of everything; if it is stale,
every downstream workbook will be too, regardless of how many times you regenerate them.

## Prerequisites

- MATLAB with Excel COM automation available (Windows + Microsoft Excel installed)
- Repository opened at root; run `setup_paths` first, or let the maintenance scripts do it
  (they all `cd` to repo root and call `setup_paths()` themselves)
- No target workbook open in Excel (COM automation will fail to acquire the file lock)
- `ExcelFiles/ModelCalibration5Sectorsand1Regions.xlsx` present and current — several rebuild
  steps read calibration parameters (`phiKPV0_p`, `deltaPV_p`, `delta_2_1_p`, `delta_3_1_p`) from it

## Step 1 — Verify or restore `ScenarioPathDefinition.xlsx`

This file is hand-maintained (or restored from git history), not script-generated from nothing.
Before rebuilding anything downstream, check its `Baseline` sheet is not sitting on placeholder
defaults. Two known corruption signatures to check for:

1. **Flat placeholder values.** VA/employment shares all `0.2` for every sector/year, or a
   "Total value-added growth factor" row that's flat `1` for every year. Real data should show a
   declining Primary-sector VA share and non-trivial year-to-year variation.
2. **Missing rows / truncated sheet.** As of the last known-good state the `Baseline` sheet has
   **100 rows** (VA/employment shares end at row 28; "Optional block" sections — Emissions,
   Public Capital Stock, Target Investment Ratios/Logicals, Investment Prices, Public Capital
   Interest Rates, Emissions Price, Demographics, Sector EE Targets, Rooftop Solar PV, FDI Capital
   Stock — run through row 100). If `wb.sheetnames` / `ws.max_row` shows fewer than 100 rows, an
   entire block (usually the trailing "FDI Capital Stock" block) has been dropped.

If either symptom is present, recover real values from git history:

```bash
git log --oneline -- ExcelFiles/ScenarioPathDefinition.xlsx
git show <last-good-commit>:ExcelFiles/ScenarioPathDefinition.xlsx > /tmp/spd_good.xlsx
```

then diff the `Baseline` sheet row-by-row against the current file (a short Python/openpyxl script
reading both with `data_only=True, read_only=True` is the fastest way — see the worked example in
this repository's own recovery session, git-blame this paragraph for the commit that fixed it).

**Column-layout gotcha:** two different sections of the `Baseline` sheet use *different* column
offsets for the same "Year" concept:

| Section | Rows | `Year` marker column | Data columns |
|---|---|---|---|
| VA/employment shares | 9–28 | C | D:AD (2025–2051) |
| "Optional block" exogenous paths | 39–100 | C (in the current/restored layout) | D:AD (2025–2051) |

Older archived copies of this workbook used `Year` in column **D** with data in **E:AD** for the
Optional-block sections — if you're pulling from a pre-2026-07 backup, shift every value one
column to the right when transplanting it into the current D:AD layout, and copy the **Import Key**
(column B, e.g. `exo_LF_1`) and **Conversion Rule** (column C's text, e.g.
`log(index/index(1))`) too — not just the label and data. Leaving the conversion rule blank makes
`apply_conversion_rule` silently default to `direct` (raw index pass-through instead of the
log-transform), which is difficult to spot because it produces plausible-looking numbers that are
silently wrong by roughly `+1` relative to the correct log-departure value.

**Year-2025 anchor:** the VA/employment share rows have no real 2025 data anywhere in history
(2025 is backfilled from 2026's value — defensible because `compute_sector_growth_factors` only
needs *some* positive anchor for the ratio, not any specific level; only the 2026+ path, driven by
the model's own `gY_*_1`/`gN_*_1`, actually matters). The "Optional block" section's 2025 column
*does* have real historical data — don't backfill it if you can source it from history.

**Year-2051 extension:** every row extends one year past the historical data's native 2050 ceiling.
Convention used throughout: repeat the 2050 value for header/index rows and most exogenous paths;
for the VA/employment share anchor there's nothing special to do since 2051 is just another period
in the same growth-driven reconstruction.

## Step 2 — Rebuild `ModelBaseline5Sectorsand1Regions.xlsx`

**This script is now idempotent — safe to re-run against its own prior output.** It was not,
originally: `apply_government_rts_sector_pv_shocks` only reset `exo_GA_4_1`/`exo_GA_5_1`'s base
level to the calibration parameter `phiKPV0` when the *existing* value in the target Baseline sheet
was empty or `<= 0`; if it was already positive (i.e. the script had already run once against this
file), it reused that existing value as the new base level, and `apply_vneep3_ee_targets`
unconditionally *added* its VNEEP3 increment on top regardless. Running the script twice in a row
against the same target file — even with no other changes — compounded `exo_GA_4_1`/`exo_GA_5_1`
upward each time. This is almost certainly how the original untraceable `exo_GA_4_1` value this
whole recovery procedure was written to fix came about in the first place. `exo_AI_4_1_2`/`exo_AI_5_1_2`
had the same latent risk, masked only by `write_generic_optional_paths` happening to unconditionally
reset them via unrelated `ScenarioPathDefinition.xlsx` rows (87–91) — a coincidence, not a guarantee.

The fix (`reset_additive_baseline_columns`, called at the top of `write_growth_rates_to_baseline` in
both `create_baseline_from_user_input_file.m` and `create_baseline_from_path_definition_lite.m`): explicitly
zero `exo_GA_3_1`, `exo_GA_4_1`, `exo_GA_5_1`, `exo_AI_4_1_2`, `exo_AI_5_1_2` before any additive step
runs, so every run starts from the same clean state regardless of rerun history. Verified: running
the script twice in a row now produces byte-identical output the second time.

**This fix changed what "correct" means for `exo_GA_4_1`/`exo_GA_5_1`.** Every value validated
earlier in this recovery effort was — without anyone noticing — built by reusing the original,
never-explained ~0.064 legacy anchor (because the recovery process kept restoring
`ModelBaseline5Sectorsand1Regions.xlsx` from a backup that still had it baked in, and the
pre-fix code treated that positive legacy value as a legitimate existing base rather than resetting
it). With the fix, the pipeline computes `exo_GA_4_1`/`exo_GA_5_1` fresh from `phiKPV0_p` every time —
which surfaced a second, separate problem: the calibration workbook's `phiKPV0_p` (`0.013`) and
`ModFiles/DGE_Model_Parameters.mod`'s hardcoded `phiKPV0_p` (previously `0.03`) had diverged. Resolved
by updating the `.mod` file to `0.013` to match the calibration workbook (the hand-edited source per
this repo's convention) — **the compiled Dynare model must be re-invoked (`dynare DGE_Model.mod` or
a full `RunSimulations` pass) for this `.mod` change to actually take effect**, since `+DGE_Model/`
and the other generated artifacts are stale until then. The net effect: `exo_GA_4_1` now runs
`0.016 → ~0.23` over 2026–2050, not the previously-reported `0.067 → ~0.90` — a substantial change to
the EE/RTS investment-cost channel's Baseline level, not a rounding difference. If you're comparing
against results generated before this fix, they used the old, contaminated anchor.

```matlab
run('scripts/maintenance/create_baseline_from_user_input_file.m')
```

This reads `ScenarioPathDefinition.xlsx` (`Input Scenario` sheet if present, else `Baseline`) in
`dedicated_path` mode and rewrites the `Baseline` sheet in
`ModelBaseline5Sectorsand1Regions_replication.xlsx`.

PDP8 fossil/renewable target investment shares are calculated by the shared
`compute_pdp8_target_investment_series` function. The default `CapitalStock` method adds
`INV_MIOUSD/GDP` to replacement investment based on `delta * lagged CAP_MIOUSD/GDP`.
`DGE_TARGET_IY_METHOD=IndexProxy` retains the legacy indexed-capacity method. Both the baseline
builder and standalone diagnostic use the same GDP anchor and replication calibration workbook
from `get_pdp8_target_investment_config`.

Expect these non-fatal warnings on a normal run — they are known, accepted external-data gaps, not
regressions:

- With `DGE_TARGET_IY_METHOD=IndexProxy`,
  `compute_pdp8_target_investment_series:IndexedTrajectoryCarryForward` can be reported for 2051.
  The external indexed-capacity extract ends in 2050, so the diagnostic carries its last available
  index forward. The default `CapitalStock` method does not require that file; 2051 replacement
  investment uses lagged 2050 capital and zero new PDP8 investment.
- `Note: Baseline_Implied not found and no legacy source workbook; skipping Baseline_Implied
  refresh.` — expected; see [Known gaps](#known-gaps-accepted-limitations).

**Before trusting the output**, check the console for:

```
Terminal VA share consistency check (Year 2051)
  Max abs difference (sim vs input target): 0.000000
```

If this is not ~0, the VA-share rows in `ScenarioPathDefinition.xlsx` are internally inconsistent
(don't sum to 1, or don't match the growth-factor reconstruction) — stop and fix Step 1 before
proceeding; do not adopt a Baseline built on a failing consistency check.

### If you also need the RTS-driven channels (`exo_GA_4_1/5_1`, `exo_AI_4_1_2/5_1_2`, `exo_PV_1`) computed fresh rather than falling back

These depend on `ExcelFiles/Input/ExpertClean/RTS_PDP8_revised_reference.csv`, which is generated
by `prepare_expert_inputs_for_sheet_creation.m` from the expert workbook's `PDP8_revised` sheet — itself
only covering 2026–2050. Regenerate it first so it covers 2025–2051 (this script already extends
it: backfill 2025 from 2026, repeat 2050 for 2051):

```matlab
run('scripts/maintenance/prepare_expert_inputs_for_sheet_creation.m')
```

then re-run Step 2. Watch the console for `Applied Vietnam RTS rooftop-solar sector shocks from RTS
split CSV` (real computation) rather than `using K_A-progress fallback` (degraded approximation
used when the RTS reference doesn't cover the full horizon).

`read_vietnam_rts_sector_plan` (used by `apply_industrial_pv_to_ee_coupling`) now degrades
gracefully instead of failing outright if the RTS split CSV is ever short a year again: any
requested year not present in the CSV is filled from the *nearest available year's* capacity/
generation data (clamped to the CSV's first/last year for years outside its range) — a "stable RTS"
assumption, i.e. no further rooftop-solar capacity growth once the expert plan data runs out, rather
than an error. Look for `RTS split CSV does not cover N requested year(s)... holding nearest
available year flat` in the console if this triggers. This mirrors the "maintain the stock, don't
grow it" assumption used elsewhere for other missing-year gaps in this pipeline, and keeps the real
RTS gen/demand computation path in `apply_industrial_pv_to_ee_coupling` active (rather than falling
further back to the cruder K_A-progress method) whenever only a small tail of years is missing.

## Step 3 — Regenerate EE scenario sheets

```matlab
run('scripts/maintenance/create_ee_scenarios_from_expert_inputs.m')
```

Reads the (now-current) `Baseline` sheet and writes `EE_PDP8`, `EE_Directive10`,
`EE_PDP8_PV_BESS`, and their `_NoBESS` counterfactuals into
`ModelScenarios5Sectorsand1Regions.xlsx`. This step is horizon-agnostic — it reads `nYears` from
whatever's in the Baseline sheet, so there's nothing to configure for the 2051 extension.

## Step 4 — Sync EE sheets back into `ScenarioPathDefinition.xlsx` (optional but recommended)

Keeps the path-definition template's own copies of the EE sheets in sync with what actually got
written to the runnable scenario workbook, so a future diff against git history reflects reality:

```matlab
sourceWorkbook = fullfile(pwd, 'ExcelFiles', 'ModelScenarios5Sectorsand1Regions.xlsx');
targetWorkbook = fullfile(pwd, 'ExcelFiles', 'ScenarioPathDefinition.xlsx');
eeSheets = {'EE_PDP8','EE_Directive10','EE_PDP8_PV_BESS','EE_Directive10_NoBESS','EE_PDP8_PV_BESS_NoBESS'};
for i = 1:numel(eeSheets)
    data = readcell(sourceWorkbook, 'Sheet', eeSheets{i});
    writecell(data, targetWorkbook, 'Sheet', eeSheets{i}, 'Range', 'A1');
end
```

(`create_scenario_path_definition_templates.m` does this plus the Baseline/Finance/NZ sheets in one
pass, but it also regenerates the Baseline path-definition template from scratch via
`create_baseline_path_definition_template.m` — only run the full script if you actually want that too.)

## Verification checklist

1. `ModelBaseline5Sectorsand1Regions.xlsx`'s `Baseline` sheet has 26 rows, `Year` 2026–2051.
2. Terminal VA-share consistency check printed `0.000000` (or acceptably close) during Step 2.
3. Spot-check `EE_PDP8` sheet, year 2026: `exo_GA_4_1` should be a few thousandths *above* the
   Baseline sheet's own `exo_GA_4_1(2026)` (first year's investment deposit), not equal to it and
   not wildly different — if it's near-identical to Baseline, the EE regeneration didn't pick up
   the current Baseline; if it's off by an order of magnitude, Step 3 ran against a stale Baseline.
4. If you have a pre-change backup, run a column-by-column relative-difference comparison (per
   column, per year, `abs(new-old)/max(abs(old),1e-9)`) rather than eyeballing a few cells — this
   is what surfaced every real regression during the last full rebuild (a `+1` conversion-rule bug,
   a zeroed-out `exo_PE_1` series, and the RTS-fallback degradation) that spot-checks alone missed.
5. Sanity-check `exo_GA_4_1`/`exo_GA_5_1` stay in a plausible range through 2051 (roughly 0.06–0.95
   in the current calibration) — a value pushing past ~1.0, or a 2026 starting value noticeably
   above ~0.07/0.05, is the signature of the double-run compounding bug described in Step 2. If you
   see it, restore Baseline from backup/git and re-run Step 2 exactly once more.

## Known gaps / accepted limitations

- **`Baseline_Input`/`Baseline_calc`/`Baseline_Implied` are not restored.** The live
  `ModelBaseline5Sectorsand1Regions.xlsx` has only `Content` and `Baseline` sheets. The documented
  split-workbook formula chain (Baseline_Input → Baseline_calc → Baseline_Implied → Baseline) does
  not currently exist in this file and has not for several commits — `create_baseline_from_user_input_file.m`
  writes values directly into `Baseline`, bypassing it entirely (`update_baseline_excel()` skips its
  own `Baseline_Implied` refresh with a printed note when the sheet is absent, which is expected,
  not an error). Restoring the formula chain would mean re-bootstrapping from a legacy combined
  workbook (`ModelSimulationandCalibration...xlsx`) that has since diverged — this is a larger,
  separate undertaking, not part of a routine rebuild.
- **`Investment.csv` / `IndexedTrajectories_FossilRenewable_Capacity.csv` end at 2050.** These are
  external PDP8 planning-data extracts (an R/Shiny dashboard in `ExcelFiles/PDP8/app.R` reads them,
  it doesn't generate them). Under the default `CapitalStock` method, 2051 therefore has zero new
  PDP8 investment and replacement investment based on lagged 2050 capital. The legacy
  `IndexProxy` method carries the 2050 capacity index forward to 2051.
- **`phiKPV0_p` — resolved, but re-check if it drifts again.** The calibration workbook's
  `phiKPV0_p` is a sheet-scoped named range — `openpyxl`'s `wb.defined_names` misses it; check with
  `read_calibration_parameter_value` in MATLAB, or a worksheet-scoped named-range read, not a
  workbook-scoped one. It had diverged from `ModFiles/DGE_Model_Parameters.mod:106`'s hardcoded
  value (`0.03` vs the calibration workbook's `0.013`) — resolved by updating the `.mod` file to
  `0.013` (see the idempotency-fix note in Step 2 above). If you ever see these two values disagree
  again, that's worth investigating before trusting either `exo_GA_4_1/5_1` or `exo_AI_4_1_2/5_1_2` —
  the calibration workbook is the intended hand-edited source of truth per this repo's convention,
  but confirm which one actually changed most recently before assuming that's still true.

## Troubleshooting

- **`Error: Invalid text character. Check for unsupported symbol, invisible character, or pasting
  of non-ASCII characters.`** when running a copy of one of these scripts under a different
  filename: MATLAB's `run()` chokes if the script's filename starts with an underscore (or
  otherwise isn't a valid identifier). Rename the file (no leading underscore) and re-run — this is
  unrelated to file content or encoding despite the error text.
- **`GDP base year %d is not present in source years` / `Input must contain one year before the
  model start year (%d) to compute growth from actual t-1 shares.`** — `dedicatedInputs.years` is
  read from `ScenarioPathDefinition.xlsx` using `srcStartCol`/`srcEndCol` in
  `import_dedicated_path_inputs` (`create_baseline_from_user_input_file.m` and
  `create_baseline_from_path_definition_lite.m`). This should be `'D'`/`'AD'` (2025–2051) — if it's been
  reverted to `'E'`/`'AD'` (2026–2051, dropping the 2025 base year), both of these errors reappear.
- **Target workbook not writable / Excel COM fails to open it.** Close the file in Excel first;
  `assert_file_writable` in `update_baseline_excel.m` checks for this but the underlying COM
  automation will still hang or error if Excel has it locked via AutoRecover.
- **Stray `<Workbook> - Copy.xlsx` or `..._TEMPLATE.xlsx` files appear in `ExcelFiles/`.** These can
  be created as side effects of Excel COM automation runs (AutoRecover / conflict-copy behavior).
  Check their content before deleting — confirm they're not someone's in-progress work — but they
  are not part of the tracked pipeline output.
- **A rebuild produces values that make no sense (implausible magnitudes, non-monotonic paths where
  a monotonic one is expected, or a workbook's file-modification time updates *after* a later,
  supposedly-unrelated step already ran) — with no error or warning printed.** Check for orphaned
  `EXCEL.EXE` processes left over from a prior run (`tasklist` on Windows) and kill them
  (`taskkill /F /IM EXCEL.EXE`) before re-running. Each MATLAB `writematrix`/`writecell`/`readcell`
  call opens Excel via COM automation; if a prior script run didn't cleanly release its Excel
  session, a new run can attach to or race against the leftover instance, silently corrupting the
  write. This produced exactly this symptom once during this repo's own recovery session — always
  verify with a fresh, immediately-following read after any rebuild step, not just once at the end.

## See also

- [scripts/maintenance/README.md](../../scripts/maintenance/README.md) — one-line description of every
  maintenance script, including the ones referenced above
- [EE scenario design](ee_scenario_design.md) — variable-by-variable mapping for the EE sheets
  built in Step 3
- [Baseline scenario manual](../reference/baseline_scenario_manual.md) — what happens *after* these workbooks
  are handed to Dynare (steady-state solve, transition simulation)
- [ExcelFiles/README.md](../../ExcelFiles/README.md) — accounting identities the calibration workbook
  must satisfy (unrelated to this procedure, but commonly edited alongside it)
