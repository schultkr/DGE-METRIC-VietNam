# Finance Instruments TeX Presentation

This folder contains a Beamer presentation for financial instrument scenarios.

## Main file

- finance_instruments_presentation.tex

## Compile

From repository root, run:

```bash
pdflatex -output-directory=docs/Finance_Scenario_Presentation docs/Finance_Scenario_Presentation/finance_instruments_presentation.tex
```

Run twice if you need fully stabilized references.

## Figure source

The slides use figures from:

- docs/figures/Finance_Simulation_Results/

Generate/update those figures with:

```bash
matlab -batch "run('scripts/reporting/GenerateFinanceSimulationResultsFigures.m')"
```
