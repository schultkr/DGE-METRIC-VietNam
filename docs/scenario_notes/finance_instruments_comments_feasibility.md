# Finance Instruments Comments - Feasibility in Current DGE-METRIC

Source files:
- `ExcelFiles/PDP8/Finance Instruments.docx`
- `ExcelFiles/PDP8/Vietnam_Green_Finance_Scenarios_April2026.xlsx`

Assessment basis: current checkout on branch `finance_new`, commit `aa6eb80`, with `DGE_Model.mod` modified locally. The DOCX and PDP8 finance workbook are untracked files in the working tree.

> **Status update (2026-07-14):** as of this date, `PDP8_GF_A/B/C` and
> `NZ_GF_A/B/C` scenario names and their switch logic are fully wired and
> uncommented in `RunSimulations.m` (they simply aren't in the default
> `activeScenarioGroups`) — the "commented out" description below is stale.
> See [scenario.md](../reference/scenario.md#green-finance-scenarios) for the current
> operational status. The rest of this document's instrument-by-instrument
> feasibility assessment remains valid.

## Current-Version Finding

The PDP8 finance workbook is a standalone WACF/allocation workbook, not a DGE-METRIC input workbook in the current code path. The model loader reads `ExcelFiles/ModelBaseline5Sectorsand1Regions.xlsx` for `Baseline` and `ExcelFiles/ModelScenarios5Sectorsand1Regions.xlsx` for other scenario sheets (`Functions/Miscellaneous/Simulation/load_exogenous.m`). `RunSimulations.m` currently has only `Baseline` active; the finance scenario names are present but commented out.

The current model can represent finance mechanisms through reduced-form channels:
- cost/rate channels: `exo_r_G_*`, `exo_r_FDI_*`, `exo_P_K_*`, `exo_I_*`, `exo_wedgeKE_*`
- public/private/foreign capital volume channels: `exo_K_G_*`, `exo_s_G_*`, `exo_s_GScen_*`, `exo_KRGTarget_*`
- subsidy/tax and ETS recycling channels: `exo_tauS_*`, `exo_tauSTr_*`, `exo_tauKF_*`
- cap-and-trade/emissions-price channels: `exo_E_*`, `exo_PE_*`, `exo_CapTrade_*`

The current model does not explicitly represent bond-market instruments, guarantee/default-risk balance sheets, sub-sovereign governments, regulatory bottlenecks, or instrument-specific mobilization ratios unless those are converted into one of the exogenous shock paths above.

The PDP8 finance workbook scenarios calculate:
- Scenario A Balanced WACF: 6.425%, annual cost on USD 136bn: USD 8.738bn
- Scenario B Market-led WACF: 7.367%, annual cost: USD 10.019bn
- Scenario C Public-led WACF: 5.067%, annual cost: USD 6.891bn

## Extracted Comments And Feasibility Answers

| ID | Comment | Anchor | Feasibility / answer in current DGE-METRIC |
|---:|---|---|---|
| 10 | Good overview. It would be interesting to understand what is holding various instruments back in terms of scale/growth/impacts and how we can address those bottlenecks (regulatory, risks, costs, etc.) | Instrument | Feasible for the paper as non-model evidence. The current DGE can quantify macro/sector impacts once bottlenecks are translated into rates, capital volumes, subsidies, or investment-price shocks, but it does not model regulatory/risk/cost bottlenecks structurally. |
| 11 | Unclear why concessional loans and blended finance are placed together here. In my understanding, concessional loans could be provided independent from blended finance structures. In the text below, guarantees and risk-sharing scenario are connected to blended finance, not concessional loans. | Concessional Loans / Blended Finance | Feasible and recommended to separate. The current model can approximate concessional loans as lower public/foreign finance rates, while blended finance should be a separate bundle combining public tranche, private/FDI mobilization, and possibly lower private risk premia. |
| 12 | Seems to be repeated from above. Delete one/rephrase | Vietnam's policy landscape paragraph | Feasible as an editorial change. No model implication. |
| 15 | I think it would generally be helpful to list the assumptions for the scenarios: e.g. where does blended finance come in - will there be an assumption on private capital mobilised per public input? (ratio) | Scenario Design: Financing Instruments in the DGE-METRIC Model | Feasible, but not yet wired into the DGE. The workbook already has public/private blended tranches and allocation shares; to affect DGE results these need conversion into `ModelScenarios5Sectorsand1Regions.xlsx` exogenous paths, such as `exo_KRGTarget`, `exo_r_FDI`, `exo_r_G`, or subsidy/tax shocks. |
| 16 | What does that mean? | Mapping financing instruments into model channels | Feasible to clarify. In current DGE terms: "cost of capital" maps to public/FDI rental-rate or investment-price shocks; "investment frictions" map to investment price/friction/MEI channels, though the active `lCapPrice = 1` setup emphasizes investment-goods prices rather than the `phiK` adjustment-cost channel. |
| 18 | PDP 8 is a pretty optimistic baseline, with overly ambitious targets. | Baseline Scenario (PDP8 Consistent) | Feasible as a caveat and sensitivity. Current baseline is PDP8-consistent; a less optimistic baseline would require an alternate baseline sheet/path and rerunning scenarios against it. |
| 19 | @Hai/Trang - can we confirm these market interest rates, also for other instruments, as referenced here and in other parts of the doc | 8-10% borrowing cost statement | Feasible as source validation outside the model. DGE-METRIC can consume annualized rate assumptions, but it does not validate or estimate market rates. |
| 21 | To verify, this first scenario would look at the use of concessional loans without any blended finance aspects? So e.g. a KfW loan provided to German PV project developers. | Concessional Finance Scenario (REA-style) | Feasible as a separate scenario. In current DGE it would be represented as a lower finance-rate or investment-price shock, not as a named KfW instrument. If the source is foreign/bilateral, mapping it to `exo_r_FDI` or public capital channels should be explicit. |
| 22 | For the model, does it matter where the concessional finance comes from, i.e. either the government, international, or bilateral sources? | Concessional Finance Scenario (REA-style) | It matters only if the scenario uses balance-sheet channels. Government finance affects public investment/budget channels; international/bilateral/foreign finance can be mapped to FDI/foreign-asset channels; a generic cost-of-capital shock would make the source invisible. |
| 24 | Do we decide on one / two specifically or does it not matter for the effects? | Guarantees, first-loss capital, PPPs | Partly feasible. The model cannot distinguish guarantees, first-loss, and PPPs institutionally. They matter only through the shock they imply: lower rate/risk premium, lower investment price/friction, higher private/FDI volume, or a public subsidy. |
| 25 | Is this visible in the model or will it simply be shown through an adjustment of the CoC? | Reduction in risk premium and investment adjustment costs | Mostly a reduced-form CoC/friction adjustment. Current outputs can show changed rates, investment, capital, emissions, GDP, and foreign income flows if mapped to FDI, but guarantees/risk-sharing are not visible as explicit instruments. |
| 27 | Private + sovereign green bonds? | Green bond markets scenario | Partly feasible. Sovereign/quasi-sovereign versus corporate/private bonds can be separated in the assumptions and mapped to public versus private/FDI channels, but DGE-METRIC currently has no explicit green bond market. |
| 28 | It may also be good to include sub-sovereigns. GIZ VNM did previous work in this area, and this is where the projects actually are implemented. | Green bond markets scenario | Not explicit in current one-region model. Sub-sovereign instruments can be discussed narratively or folded into public/quasi-sovereign assumptions; explicit provincial/subnational finance would require a regional/fiscal extension. |
| 29 | Not sure if this applies and if VNM will fetch any greeniums, at all. | Green bond markets scenario | Feasible as a sensitivity. The model cannot estimate a greenium endogenously; set the green bond rate equal to conventional rates in a no-greenium case, or lower it only if externally justified. |
| 31 | I wonder how this scenario weights different mechanisms, if at all. How would the emergence of an integrated policy framework look like, be measured and would affect mechanisms? | Coordinated Policy Mix Scenario | Feasible only after defining weights externally. The current workbook has allocation shares that can become weights; DGE-METRIC will not endogenously measure "integrated policy framework" quality. |
| 32 | General question: Does volume matter for the modelling? Currently, we consider cost of capital/ risk premia changes and disregard volume of concessional loans for example. | Coordinated Policy Mix Scenario | Yes, volume can matter if represented through public capital, FDI capital, target capital/investment paths, or subsidy envelopes. In the current finance workbook, volume is used for WACF/cost calculations but is not yet fed into the DGE scenario workbooks. If only CoC/risk-premium shocks are used, concessional loan volume is invisible. |
| 33 | A mixed policy scenario makes sense to showcase the hightened effects, could we still draw concrete results from the individual instruments in this policy mix or is that not necessary given the other individual scenarios? | Joint reduction in CoC, risk premia, and investment frictions | Feasible. Run individual instrument scenarios plus the joint policy-mix scenario and compare deviations from baseline. Current repo needs scenario sheets and the commented finance scenario names reactivated before this is operational. |
| 35 | To clarify: the scenarios would still integrate ETS (as the model is based on a cap and trade system) but would not include fiscal aspects such as subsidies or similar, right? | Conclusion | Feasible. ETS/cap-and-trade can be active while fiscal recycling/subsidies are set to zero. Current `NZ` scenario sheet already has `exo_tauS_1 = 0`; `RunSimulations.m` must run an ETS scenario rather than the currently active `Baseline` only. |
| 36 | To verify, this is something that would be explored further using non-modelled evidence? | Policy perspective / context-specific finance strategy | Yes. Instrument bottlenecks, market readiness, implementation capacity, and policy recommendations need non-model evidence. DGE-METRIC can quantify macro/sector implications of encoded assumptions. |
| 37 | It would also be helpful if the paper could derive practical recommendations for policymakers and the project alike. | Overall contribution | Feasible as synthesis. Recommendations should combine DGE results with the non-model evidence above; the model alone cannot rank institutional feasibility. |

## Bottom Line

Most comments are feasible to address in the paper and scenario design. In the current DGE-METRIC version, the finance instruments should be presented as reduced-form mappings into model shocks, not as fully structural representations of named instruments. To make them operational, the next implementation step is to translate the PDP8 finance workbook's WACF shares/rates/volumes into `ModelScenarios5Sectorsand1Regions.xlsx` sheets and reactivate the corresponding scenario names in `RunSimulations.m`.
