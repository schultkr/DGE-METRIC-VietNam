# Running

## Install Dynare

Use one of the setup paths below before running this project.

### Option A: MATLAB Desktop (recommended)

1. Install MATLAB (R2019a or newer recommended).
2. Download Dynare from the official Dynare download page.
3. Run the Dynare installer for your OS.
4. Keep/install Dynare in a path matched by this repository setup (for Windows defaults: `C:\dynare\7.0\matlab` or `C:\dynare\6.1\matlab`).
5. Open MATLAB and verify Dynare:

```matlab
which dynare
dynare_version
```

If `which dynare` is empty, add Dynare manually in MATLAB:

```matlab
addpath('C:\dynare\7.0\matlab')
savepath
```

### Option B: GNU Octave + Dynare

1. Install GNU Octave.
2. Install Dynare for Octave:
	- Linux (Debian/Ubuntu):

```bash
sudo apt update
sudo apt install dynare octave
```

	- Other platforms: use the Dynare package/installer for your OS and Octave version.
3. Start Octave and verify Dynare:

```octave
which dynare
dynare_version
```

Note: this repository's main script currently targets MATLAB flow. If you use Octave, validate your local Dynare/Octave compatibility first.

### Option C: MATLAB Online

MATLAB Online usually cannot run a full local Dynare installer workflow (external binaries/toolchain access is limited in many setups).

Practical alternatives:

1. Run this project in MATLAB Desktop with local Dynare installed.
2. Or run with local Octave + Dynare.
3. Keep code editing in MATLAB Online if needed, but execute simulations in a local environment.

## Prerequisites

- MATLAB (project comments indicate MATLAB 2019 or newer).
- Dynare installation available in one of the paths listed in `setup_paths.m` (currently `C:\dynare\7.0\matlab` or fallback `C:\dynare\6.1\matlab`).
- Windows + Excel if you need to rebuild or modify Excel workbooks with COM scripts.

## Recommended Run Order

1. Open MATLAB in the repository root.
2. Run:

```matlab
setup_paths
```

3. Ensure required Excel workbooks exist in `ExcelFiles/`.
4. Run scenario batch:

```matlab
RunSimulations
```

## Selecting Scenario Groups

Default active groups are defined in `RunSimulations.m`.

You can override groups from the environment before running MATLAB:

```powershell
$env:DGE_SCENARIO_GROUPS = "Reference,GF_NZ"
matlab -batch "RunSimulations"
```

## Baseline Candidate Sweep

`RunSimulations.m` supports baseline candidate sheet sweeps via `casCandidates`.

Typical usage:

1. Duplicate `Baseline` sheet in `ModelBaseline5Sectorsand1Regions.xlsx`.
2. Rename to `Baseline_Cand01` (or similar).
3. Add the sheet name to `casCandidates`.
4. Re-run `RunSimulations` to produce separate `structScenarioResults*.mat` outputs by suffix.

## Outputs

Primary outputs include:

- `structScenarioResults.mat` and optional candidate/sensitivity variants.
- Dynare output/log artifacts in model output folders.
- Excel outputs under `ExcelFiles/Output/`.

## Useful Maintenance Script

To rebuild baseline values from path definitions:

```matlab
run('scripts/maintenance/CreateBaselineFromPathDefinitionLite.m')
```
