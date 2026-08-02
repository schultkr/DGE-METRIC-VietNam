# Publication report blueprint

Use this structure unless the repository provides a mandatory institutional or journal template. Adapt headings while preserving the required content.

## Front matter

### Title page

Include title, model name and version, authors or institution when supplied, date, repository commit, report status, and citation information. Do not infer authorship.

### Abstract

Write 150 to 250 words covering the question, model class, scope, scenarios, main quantitative findings, and principal limitation. Avoid citations unless required by the repository style.

### Keywords and classification

Use only keywords and classification codes supported by the repository or requested by the user.

### Executive summary

Write for technical policy readers. Include:

- problem and decision context;
- model and evidence base;
- scenario design;
- three to seven quantified findings with horizon and baseline;
- main mechanisms;
- robustness and uncertainty;
- implications and interpretation boundaries.

## 1. Introduction

Explain the research or policy problem, why general equilibrium feedbacks matter, contribution of the model, scope of the report, and report organization. Base literature positioning only on references contained in the repository.

## 2. Model overview

Provide a compact verbal overview before equations. Include agents, markets, sectors, regions, dynamic links, trade or spatial links, policy instruments, and the principal transmission channels. Add a model-structure diagram when one exists or can be reconstructed faithfully.

## 3. Mathematical specification

Organize by economic block:

- households;
- firms and production nests;
- labour market;
- trade and external sector;
- government and policy financing;
- accumulation and dynamic equations;
- equilibrium, closure, and normalization;
- exogenous processes and shocks.

Define notation consistently. Use a notation table for large models. Present the core system in the main text and place full equation listings in an appendix when needed.

## 4. Data, calibration, and baseline

Document:

- data sources already stored or cited in the repository;
- base year, units, transformations, and aggregation;
- social accounting, input-output, national accounts, survey, climate, engineering, or other inputs;
- calibration and estimation procedure;
- key parameter table with definition, value, unit, method, and source;
- baseline path and exogenous assumptions;
- benchmark replication and validation checks.

Explain how the baseline differs from a forecast. State which paths are imposed and which are endogenous.

## 5. Scenario and simulation strategy

Provide a scenario matrix. For each scenario report:

- identifier and purpose;
- intervention or shock;
- affected equation or variable;
- geography, sector, and agent coverage;
- magnitude and unit;
- start, duration, persistence, decay, and anticipation;
- financing rule;
- comparison baseline;
- sensitivity variants.

Use a mapping table when policy categories or physical hazards are translated into model shocks.

## 6. Results

Start with aggregate dynamics, then decompose.

### 6.1 Aggregate effects

Report time paths for GDP, consumption, investment, employment or hours, welfare, prices, public finance, external balance, and other core outcomes relevant to the model.

### 6.2 Transmission mechanisms

Explain how the shock moves through factor demand, wages, prices, income, consumption, investment, trade, government accounts, and capital accumulation. Link the narrative to equations and decompositions.

### 6.3 Heterogeneity

Report sectoral, regional, household, skill, income, or demographic differences supported by the model. Explain exposure, structural composition, and spillovers.

### 6.4 Cost-effectiveness, multipliers, damages, or welfare

Define every metric. State accumulation period, discount rate, price basis, baseline, numerator, denominator, and whether values are gross or net of financing costs.

### 6.5 Distribution and convergence

When relevant, report inequality, disparities, incidence, or convergence measures and define them precisely.

## 7. Sensitivity, uncertainty, and robustness

Cover available parameter tests, alternative baselines, scenario ranges, closure choices, damage functions, elasticities, financing rules, or solver checks. Distinguish uncertainty that was quantified from uncertainty that remains qualitative.

## 8. Limitations

Address limitations under separate headings:

- model structure;
- behavioural assumptions;
- data and aggregation;
- calibration or estimation;
- scenario translation;
- omitted policy interactions;
- numerical solution;
- reproducibility and missing repository evidence.

Explain likely direction of bias only when supported.

## 9. Implications

Translate results into policy or research implications without presenting model outputs as forecasts or observed causal effects. Separate robust implications from scenario-dependent ones.

## 10. Conclusions

Restate the question, main findings, mechanisms, limitations, and the most defensible implication. Do not introduce new evidence.

## References

Use only bibliography entries present in the repository or user-provided attachments. Check that every citation appears in the reference list and every listed reference is cited or clearly marked as background.

## Appendices

Include as applicable:

- full equation system;
- notation and variable lists;
- calibration details and data mappings;
- additional scenarios and results;
- sensitivity tables;
- source map and evidence ledger;
- replication environment, commands, and folder structure;
- unresolved issues and documentation conflicts.

## Figure and table standard

Every figure and table must include:

- sequential number;
- descriptive title;
- units and baseline in the caption or notes;
- legend and readable labels;
- source path or generation script;
- notes explaining scenario, aggregation, and rounding;
- accessible prose interpretation in the body.

Do not use screenshots of raw terminal output or spreadsheets as publication figures.
