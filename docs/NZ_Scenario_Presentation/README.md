# Net Zero Comparison TeX Presentation

This folder contains a Beamer presentation for NZ vs Baseline comparison results.

## Main file

- nz_comparison_presentation.tex

## Compile

From repository root, run:

```bash
pdflatex -interaction=nonstopmode -output-directory=docs/NZ_Scenario_Presentation docs/NZ_Scenario_Presentation/nz_comparison_presentation.tex
```

## Figure source

The slides use figures from:

- docs/figures/NZ_Simulation_Results/

Generate/update these figures with:

```bash
matlab -batch "run('scripts/reporting/GenerateNZBaselineComparisonFigures.m')"
```
