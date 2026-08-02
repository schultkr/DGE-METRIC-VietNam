# Dynamic general equilibrium model audit

Use this checklist before and during report drafting. Record the source for every checked item.

## 1. Model identity

- Model name, version, repository commit, and release date.
- Economic question and intended use.
- CGE, DSGE, recursive dynamic, perfect foresight, stochastic, or hybrid classification.
- Long-run, medium-run, or short-run interpretation.
- Deterministic versus stochastic shocks.
- Geographic, sectoral, household, skill, age, or income resolution.

## 2. Time and information structure

- Period length and simulation horizon.
- Timing of choices, payments, investment, and capital installation.
- State, control, static endogenous, and exogenous variables.
- Expectations formation and information set.
- Transition law for every state variable.
- Initial conditions and terminal conditions.
- Shock start, duration, persistence, decay, anticipation, and phaseout.

## 3. Households

- Number and type of representative agents or heterogeneous groups.
- Utility function and aggregation across consumption, housing, leisure, or other goods.
- Intertemporal elasticity and labour supply elasticity definitions.
- Budget constraint and asset menu.
- Taxes, transfers, benefits, remittances, and borrowing constraints.
- Participation, unemployment, migration, or demographic decisions.
- Welfare metric and compensation concept, if reported.

## 4. Production

- Sector and regional production nesting.
- Capital, labour, land, energy, materials, and intermediate inputs.
- CES, Cobb-Douglas, Leontief, or other functional forms.
- Elasticities and share parameters by nest.
- Productivity terms and damage or policy wedges.
- Capital accumulation, depreciation, adjustment costs, and vintages.
- Capacity constraints, fixed factors, or sector-specific capital.
- Firm market structure and profit conditions.

## 5. Labour market

- Labour categories and skill mapping.
- Labour supply or participation mechanism.
- Wage setting, wage curve, bargaining, or market clearing.
- Unemployment definition and benefit replacement rates.
- Mobility across sectors, regions, or skills.
- Productivity versus labour quantity shocks.
- Employment reported as persons, jobs, hours, or efficiency units.

## 6. Trade and spatial structure

- Small open economy or multi-region system.
- Armington, variety, gravity, iceberg cost, or other trade structure.
- Export demand and import supply assumptions.
- Foreign asset or debt closure.
- Exchange rate and world price treatment.
- Interregional spillovers, transport costs, and market access.

## 7. Government and policy closure

- Government budget constraint.
- Tax instruments, transfers, consumption, investment, and debt.
- Policy financing rule and incidence.
- Lump-sum versus distortionary financing.
- Balanced-budget, debt-target, or other fiscal closure.
- Public capital or adaptation capital accumulation.
- Treatment of policy administration costs.

## 8. Equilibrium and closure

- Goods, factor, asset, and external market clearing.
- Walras law and redundant equation handling.
- Numeraire and price normalization.
- Savings-investment closure.
- Labour, government, and external closures.
- Complementarity conditions, occasionally binding constraints, or rationing.

## 9. Baseline and calibration

- Base year and social accounting or input-output data.
- Price base, currency, and deflators.
- Benchmark equilibrium replication.
- Calibration targets and tolerances.
- Estimated versus calibrated parameters.
- Parameter source files and transformations.
- Population, productivity, technology, fiscal, and trade paths.
- Baseline consistency with accounting identities.
- Baseline forecast overlays or external paths already stored in the repository.

## 10. Scenarios and shocks

- Scenario matrix with unique identifiers.
- Mapping from policy or physical inputs to model variables.
- Demand-side and supply-side components.
- Timing profile and implementation lags.
- Persistence, depreciation, or skill loss.
- Financing and repayment.
- Counterfactual definition.
- Sensitivity variants and alternative closures.

## 11. Solution and computation

- Solver, software, packages, and versions.
- Linear, nonlinear, local, global, recursive, or perfect-foresight solution.
- Steady-state method.
- Convergence criteria and failure handling.
- Random seeds, draws, and simulation count if stochastic.
- Parallelization or numerical approximations.
- Replication command and expected runtime.

## 12. Results interpretation

- Baseline-relative versus level results.
- Percentage point versus percent change.
- Annual versus cumulative changes.
- Real versus nominal and current versus constant prices.
- Direct effect, general equilibrium feedback, financing effect, and spillover.
- Short-run versus long-run mechanism.
- Sectoral, regional, household, or skill heterogeneity.
- Welfare, GDP, consumption, employment, emissions, damages, or distribution metrics.
- Multiplier numerator, denominator, accumulation window, and discounting.

## 13. Robustness and limitations

- Parameter sensitivity.
- Alternative damage, policy, or behavioural functions.
- Alternative baseline and closure.
- Model fit or benchmark validation.
- Missing sectors, agents, frictions, or interactions.
- Data aggregation and measurement limitations.
- Structural uncertainty and scenario uncertainty.
- Results that are not reproducible from stored files.

## Completion rule

Do not mark an item as complete without a source. When an item is not applicable, explain why. When evidence is missing, carry the item into the report limitations and unresolved-issues note.
