# EE Scenario TeX Presentation

This folder contains a Beamer presentation for the EE simulation scenarios.

## Main file

- `ee_scenarios_presentation.tex`
- `ee_scenarios_presentation_5y_average_deviations.tex`

## Compile (example)

From repository root, run:

```bash
powershell -ExecutionPolicy Bypass -File scripts/reporting/export_ee_figures_jpeg.ps1
pdflatex docs/EE_Scenario_Presentation/ee_scenarios_presentation.tex
```

Run twice for stable references/table of contents if needed.

The first command exports JPEG figures from SVG sources and updates image assets used by the deck.

## Compile 5-year average deviations deck

From repository root, run:

```bash
pdflatex docs/EE_Scenario_Presentation/ee_scenarios_presentation_5y_average_deviations.tex
```

Run twice for stable references if needed.

## Figure source

The slides use figures from:

- `docs/figures/EE_Simulation_Results/`

## Finance scenario figure generation

For finance scenario reporting figures (including GDP growth and WACC), run from repository root:

```bash
matlab -batch "run('scripts/reporting/GenerateFinanceSimulationResultsFigures.m')"
```

This writes SVG and PNG files to:

- `docs/figures/Finance_Simulation_Results/`
