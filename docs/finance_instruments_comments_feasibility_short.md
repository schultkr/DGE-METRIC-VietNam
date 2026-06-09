# Finance Instruments - Short Comment Feasibility Note

Source files:
- `ExcelFiles/PDP8/Finance Instruments.docx`
- `ExcelFiles/PDP8/Vietnam_Green_Finance_Scenarios_April2026.xlsx`

## Bottom Line

Most comments are feasible to address in the paper and scenario framing. In the current DGE-METRIC version, finance instruments are not modeled as named instruments such as green bonds, guarantees, or KfW loans. They need to be translated into reduced-form model shocks: finance rates, investment prices/frictions, public or FDI capital paths, subsidies, or ETS-recycling assumptions.

The PDP8 finance workbook is currently a standalone WACF/allocation workbook. It is not yet connected to `ModelScenarios5Sectorsand1Regions.xlsx`, which is the workbook read by the model for non-baseline scenarios.

## Workbook Signals

- Scenario A Balanced WACF: 6.425%; annual cost on USD 136bn: USD 8.738bn.
- Scenario B Market-led WACF: 7.367%; annual cost: USD 10.019bn.
- Scenario C Public-led WACF: 5.067%; annual cost: USD 6.891bn.
- The workbook separates ODA/MDB concessional finance, blended public/private tranches, sovereign/quasi-sovereign green bonds, corporate green bonds, and green bank credit.

## Comment Feasibility Summary

| ID | Topic | Short feasibility answer |
|---:|---|---|
| 10 | Bottlenecks and scale | Feasible as non-model evidence; model only captures bottlenecks after translation into shocks. |
| 11 | Concessional vs blended finance | Feasible and should be separated; concessional loans and blended finance are different mechanisms. |
| 12 | Repeated policy text | Editorial fix only; no model issue. |
| 15 | Scenario assumptions and mobilization ratios | Feasible, but ratios must be externally defined and mapped into model inputs. |
| 16 | Meaning of model channels | Clarify that channels mean rate, capital-volume, subsidy, and investment-friction shocks. |
| 18 | PDP8 optimism | Feasible as caveat or sensitivity; current baseline remains PDP8-consistent. |
| 19 | Market interest rates | Feasible as source validation; model does not estimate rates. |
| 21 | Concessional finance without blending | Feasible as its own scenario, represented through lower rates or public/foreign finance channels. |
| 22 | Source of concessional finance | Matters only if using budget, public-capital, FDI, or foreign-asset channels; otherwise source is invisible. |
| 24 | Guarantees/first-loss/PPPs | Partly feasible; the model cannot distinguish instruments except through their implied shocks. |
| 25 | Visibility of risk sharing | Mostly reduced-form; visible as lower CoC/frictions or higher investment, not as a guarantee balance sheet. |
| 27 | Private and sovereign green bonds | Partly feasible; can split assumptions, but no explicit bond market exists. |
| 28 | Sub-sovereigns | Not explicit in the current one-region model; include narratively or fold into public/quasi-sovereign assumptions. |
| 29 | Greenium uncertainty | Feasible as sensitivity; set greenium to zero unless externally justified. |
| 31 | Policy-mix weights | Feasible only with externally chosen weights, e.g. from workbook allocation shares. |
| 32 | Whether volume matters | Yes, if modeled through public capital, FDI, capital targets, investment paths, or subsidy envelopes. |
| 33 | Mixed vs individual instruments | Feasible; run individual scenarios plus a joint policy-mix scenario for comparison. |
| 35 | ETS without fiscal subsidies | Feasible; ETS can be active while subsidy/recycling shocks are zero. |
| 36 | Non-modeled evidence | Yes; institutional feasibility and bottlenecks need external evidence. |
| 37 | Practical recommendations | Feasible as synthesis of DGE results plus non-model evidence. |

## Next Step

Create scenario sheets in `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx` that convert the PDP8 finance workbook assumptions into DGE-METRIC shocks, then reactivate the finance scenario names in `RunSimulations.m`.
