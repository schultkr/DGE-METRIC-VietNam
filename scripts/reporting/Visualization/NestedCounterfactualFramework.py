"""Generate the nested counterfactual scenario-framework figure.

The editable SVG is written beside this script. When ImageMagick is available,
the publication-ready PNG is exported to the repository's ``Figures`` folder.
"""

from pathlib import Path
import shutil
import subprocess
from xml.sax.saxutils import escape


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = Path(__file__).resolve().parents[3]
SVG_OUT = SCRIPT_DIR / "nested_counterfactual_framework.svg"
PNG_OUT = REPO_ROOT / "Figures" / "nested_counterfactual_framework.png"

WIDTH, HEIGHT = 1696, 930
FONT_FAMILY = "Arial, Helvetica, sans-serif"


def text_block(
    x,
    y,
    lines,
    *,
    size=24,
    weight=400,
    fill="#243746",
    anchor="middle",
    line_gap=1.22,
    italic=False,
):
    """Return a multiline SVG text element."""
    tspans = []
    for index, line in enumerate(lines):
        dy = "0" if index == 0 else f"{size * line_gap:.1f}"
        tspans.append(f'<tspan x="{x}" dy="{dy}">{escape(line)}</tspan>')
    font_style = ' font-style="italic"' if italic else ""
    return (
        f'<text x="{x}" y="{y}" text-anchor="{anchor}" '
        f'font-family="{FONT_FAMILY}" font-size="{size}" '
        f'font-weight="{weight}" fill="{fill}"{font_style}>'
        + "".join(tspans)
        + "</text>"
    )


def rounded_box(x, y, width, height, *, fill, stroke, radius=14, stroke_width=3):
    """Return a consistently styled rounded rectangle."""
    return (
        f'<rect x="{x}" y="{y}" width="{width}" height="{height}" '
        f'rx="{radius}" fill="{fill}" stroke="{stroke}" '
        f'stroke-width="{stroke_width}"/>'
    )


svg = [
    f'''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}"
     viewBox="0 0 {WIDTH} {HEIGHT}">
  <title>Nested counterfactual framework for Viet Nam's energy transition</title>
  <desc>A common benchmark economy feeds the PDP8 baseline, followed by three policy branches whose comparison isolates emissions, demand and investment mechanisms.</desc>
  <defs>
    <marker id="arrow" markerWidth="10" markerHeight="10" refX="8.5" refY="5"
            orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L10,5 L0,10 z" fill="#102A56"/>
    </marker>
  </defs>
  <rect x="0" y="0" width="{WIDTH}" height="{HEIGHT}" fill="#FFFFFF"/>
'''
]

# Common benchmark economy.
svg.append(rounded_box(20, 22, 545, 287, fill="#FFFFFF", stroke="#102A56"))
svg.append(text_block(292, 70, ["Common benchmark economy"], size=34, weight=700, fill="#102A56"))
svg.append('<line x1="20" y1="91" x2="565" y2="91" stroke="#AEB8C2" stroke-width="2"/>')

benchmark_rows = [
    (130, "Identical calibration"),
    (184, "Same model structure"),
    (238, "Same initial steady state"),
    (292, "Deterministic transition path"),
]
for index, (y, label) in enumerate(benchmark_rows):
    svg.append(text_block(292, y, [label], size=26, fill="#202B33"))
    if index < len(benchmark_rows) - 1:
        line_y = y + 18
        svg.append(
            f'<line x1="20" y1="{line_y}" x2="565" y2="{line_y}" '
            'stroke="#CCD3D9" stroke-width="1.5"/>'
        )

# PDP8 baseline and connection from the common benchmark.
svg.append(
    '<line x1="565" y1="151" x2="672" y2="151" stroke="#102A56" '
    'stroke-width="7" marker-end="url(#arrow)"/>'
)
svg.append(rounded_box(682, 42, 500, 220, fill="#103B70", stroke="#103B70"))
svg.append(text_block(932, 145, ["PDP8 baseline"], size=46, weight=700, fill="#FFFFFF"))
svg.append(text_block(932, 198, ["Policy-consistent benchmark"], size=30, fill="#FFFFFF"))

# Branching tree from PDP8.
svg.extend(
    [
        '<line x1="932" y1="262" x2="932" y2="348" stroke="#102A56" stroke-width="7"/>',
        '<line x1="355" y1="348" x2="1408" y2="348" stroke="#102A56" stroke-width="7"/>',
        '<line x1="355" y1="348" x2="355" y2="397" stroke="#102A56" stroke-width="7" marker-end="url(#arrow)"/>',
        '<line x1="897" y1="348" x2="897" y2="397" stroke="#102A56" stroke-width="7" marker-end="url(#arrow)"/>',
        '<line x1="1408" y1="348" x2="1408" y2="397" stroke="#102A56" stroke-width="7" marker-end="url(#arrow)"/>',
    ]
)

branches = [
    {
        "x": 116,
        "width": 482,
        "color": "#16867D",
        "tint": "#EDF8F6",
        "title": "Net-Zero cap",
        "subtitle": "Binding emissions constraint",
        "mechanism": "Emissions channel",
    },
    {
        "x": 658,
        "width": 478,
        "color": "#D58C00",
        "tint": "#FFF8E8",
        "title": "Energy efficiency",
        "subtitle": "Demand-side efficiency shocks",
        "mechanism": "Demand channel",
    },
    {
        "x": 1178,
        "width": 466,
        "color": "#B82C2C",
        "tint": "#FFF1F1",
        "title": "Transition finance",
        "subtitle": "Modified cost of capital",
        "mechanism": "Investment channel",
    },
]

for branch in branches:
    x = branch["x"]
    width = branch["width"]
    center = x + width / 2
    svg.append(rounded_box(x, 403, width, 225, fill="#FFFFFF", stroke=branch["color"], radius=13))
    svg.append(
        f'<path d="M{x + 13},403 H{x + width - 13} Q{x + width},403 {x + width},416 '
        f'V473 H{x} V416 Q{x},403 {x + 13},403 Z" fill="{branch["color"]}"/>'
    )
    svg.append(f'<rect x="{x}" y="550" width="{width}" height="78" fill="{branch["tint"]}" rx="10"/>')
    svg.append(f'<line x1="{x}" y1="550" x2="{x + width}" y2="550" stroke="{branch["color"]}" stroke-width="1.5"/>')
    svg.append(text_block(center, 450, [branch["title"]], size=34, weight=700, fill="#FFFFFF"))
    svg.append(text_block(center, 522, [branch["subtitle"]], size=25, fill="#202B33"))
    svg.append(text_block(center, 598, [branch["mechanism"]], size=28, weight=700, fill=branch["color"]))

# Converging paths into mechanism decomposition.
svg.extend(
    [
        '<line x1="355" y1="628" x2="355" y2="676" stroke="#102A56" stroke-width="7"/>',
        '<line x1="897" y1="628" x2="897" y2="708" stroke="#102A56" stroke-width="7"/>',
        '<line x1="1408" y1="628" x2="1408" y2="676" stroke="#102A56" stroke-width="7"/>',
        '<line x1="355" y1="676" x2="1408" y2="676" stroke="#102A56" stroke-width="7"/>',
        '<line x1="897" y1="676" x2="897" y2="718" stroke="#102A56" stroke-width="7" marker-end="url(#arrow)"/>',
    ]
)

svg.append(rounded_box(432, 723, 896, 120, fill="#FFFFFF", stroke="#102A56", radius=14))
svg.append(text_block(880, 773, ["Mechanism decomposition"], size=39, weight=700, fill="#102A56"))
svg.append(
    text_block(
        880,
        817,
        ["Scenario differences isolate marginal policy contributions"],
        size=25,
        fill="#202B33",
    )
)
svg.append(
    text_block(
        848,
        892,
        ["Only shock paths differ across scenarios"],
        size=27,
        fill="#202B33",
        italic=True,
    )
)

svg.append("</svg>")

SVG_OUT.write_text("\n".join(svg), encoding="utf-8")
PNG_OUT.parent.mkdir(parents=True, exist_ok=True)

magick = shutil.which("magick")
if magick:
    subprocess.run(
        [magick, "-density", "144", "-background", "white", str(SVG_OUT), str(PNG_OUT)],
        check=True,
    )
    print(f"Created PNG: {PNG_OUT}")
else:
    print("ImageMagick not found; skipped PNG export.")

print(f"Created editable SVG: {SVG_OUT}")
