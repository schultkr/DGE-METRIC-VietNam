# MATLAB IO Pipeline

This folder is a MATLAB recreation of `reproducible_pipeline`.

It performs the same two pipeline stages:

1. Split `Utilities` into `Utilities_Fossil` and `Utilities_Renewables`
2. Aggregate the split IO table into the 5-sector DGE `IO_Data` format

The required input files are bundled under `matlab_pipeline/data`.

## Files

- `run_pipeline.m`: one-command runner
- `run_full_pipeline.m`: function-based runner
- `default_pipeline_config.m`: default paths
- `config_example.m`: editable config template
- `config_local_example.m`: optional example for updating an existing DGE workbook
- `split_utilities_sector.m`: utilities split stage
- `aggregate_for_dge.m`: 5-sector DGE aggregation stage

## Quick Start

From the project root in MATLAB:

```matlab
addpath("matlab_pipeline")
run_pipeline
```

From PowerShell:

```powershell
& "C:\Program Files\MATLAB\R2025b\bin\matlab.exe" -batch "addpath('matlab_pipeline'); run_pipeline"
```

## Custom Config

Copy `config_example.m` to `config_local.m`, edit paths, then run:

```matlab
addpath("matlab_pipeline")
run_pipeline("matlab_pipeline/config_local.m")
```

To update a copy of an existing DGE model workbook, use `config_local_example.m` as a starting point and set `cfg.dge_workbook`.

## Outputs

By default, outputs are written to `matlab_pipeline/data/output`:

- `IO-2019_utilities_split.xlsx`
- `IO-2019_utilities_split.csv`
- `IO_2019_utilities_split_summary.csv`
- `IO_2019_5sec_for_DGE_IO_Data.xlsx`
- `IO_2019_5sec_for_DGE_IO_Data.csv`
- `IO_2019_5sec_for_DGE_validation.csv`
- `IO_2019_5sec_for_DGE_audit.csv`
- `ModelSimulationandCalibration5Sectorsand1Regions_IO_Data_Replaced.xlsx` if `dge_workbook` is provided

