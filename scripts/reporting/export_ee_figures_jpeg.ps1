$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$figDir = Join-Path $repoRoot 'docs\figures\EE_Simulation_Results'
$magick = 'C:\Program Files\ImageMagick-7.1.1-Q16-HDRI\magick.exe'

if (-not (Test-Path $magick)) {
    throw "ImageMagick executable not found: $magick"
}

$names = @(
    'GDP_Growth_Comparison_with_Baseline',
    'Investment_Share_GDP',
    'Consumption_Share_GDP',
    'Energy_Intensity_Index',
    'Energy_Prices_Index',
    'Final_Energy_Demand_Index',
    'Emissions_Index',
    'GDP_Level_Deviation_vs_Baseline',
    'Investment_Share_Deviation_vs_Baseline',
    'Consumption_Share_Deviation_vs_Baseline',
    'Energy_Intensity_Deviation_vs_Baseline',
    'Energy_Prices_Deviation_vs_Baseline',
    'Final_Energy_Demand_Deviation_vs_Baseline'
)

foreach ($name in $names) {
    $svg = Join-Path $figDir ($name + '.svg')
    $jpg = Join-Path $figDir ($name + '.jpg')

    if (-not (Test-Path $svg)) {
        Write-Warning "Skipping missing SVG: $svg"
        continue
    }

    & $magick $svg -density 220 -background white -alpha remove -alpha off -quality 92 $jpg
    Write-Host "Wrote $jpg"
}

Write-Host 'JPEG export complete.'
