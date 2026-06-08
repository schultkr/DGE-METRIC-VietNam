# Maintenance Scripts

Operational helpers for creating and updating baseline/scenario workbooks.

## Current Files

- `CreateModelWorkbooks.m`: creates `ModelBaseline`, `ModelCalibration`, and `ModelScenarios` workbooks.
- `CreateEEScenariosFromExpertInputs.m`: generates EE + BESS scenario sheets from expert-input workbooks.
- `CreateGreenFinanceScenarios.m`: generates green-finance scenario sheets (PDP8_GF_* and NZ_GF_*).

## Usage

Run from repository root (or use full script path):

```matlab
setup_paths;
run('scripts/maintenance/CreateModelWorkbooks.m');
run('scripts/maintenance/CreateEEScenariosFromExpertInputs.m');
run('scripts/maintenance/CreateGreenFinanceScenarios.m');
```
