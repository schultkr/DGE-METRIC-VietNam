from pathlib import Path
import shutil
import subprocess
from xml.sax.saxutils import escape

out = Path(__file__).resolve().parent / "Vietnam_integrated_policy_package_revised.svg"
png_out = out.with_suffix(".png")

W, H = 1600, 1120

def text_block(x, y, lines, size=22, weight=400, fill="#16324F",
               anchor="start", line_gap=1.22, family="Arial, Helvetica, sans-serif"):
    tspans = []
    for i, line in enumerate(lines):
        dy = "0" if i == 0 else f"{size * line_gap:.1f}"
        tspans.append(f'<tspan x="{x}" dy="{dy}">{escape(line)}</tspan>')
    return (
        f'<text x="{x}" y="{y}" text-anchor="{anchor}" '
        f'font-family="{family}" font-size="{size}" font-weight="{weight}" '
        f'fill="{fill}">' + "".join(tspans) + "</text>"
    )

svg = [f'''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
  <title>Integrated policy package for Viet Nam's energy transition</title>
  <desc>Editable vector figure showing five mutually reinforcing policy pillars and their combined macroeconomic and climate outcomes.</desc>
  <defs>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="130%">
      <feDropShadow dx="0" dy="5" stdDeviation="7" flood-color="#000000" flood-opacity="0.13"/>
    </filter>
    <marker id="arrow" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L8,4 L0,8 z" fill="#5B7083"/>
    </marker>
  </defs>

  <rect x="0" y="0" width="{W}" height="{H}" fill="#F5F8FA"/>
  <rect x="0" y="0" width="{W}" height="16" fill="#0F6B5B"/>
''']

svg.append(text_block(
    800, 78,
    ["An integrated policy package for Viet Nam’s energy transition"],
    size=36, weight=700, fill="#102A43", anchor="middle"
))
svg.append(text_block(
    800, 118,
    ["Five mutually reinforcing pillars reduce transition costs and strengthen growth"],
    size=20, fill="#486581", anchor="middle"
))

svg.append('<rect x="70" y="160" width="1460" height="38" rx="19" fill="#DCEFEA"/>')
svg.append(text_block(
    800, 186, ["CORE ECONOMIC AND INVESTMENT PILLARS"],
    size=16, weight=700, fill="#0F6B5B", anchor="middle"
))

cards = [
    {
        "x": 80, "y": 225, "w": 450, "h": 280, "fill": "#E8F4EE", "stroke": "#2A7F62",
        "num": "1", "title": ["Efficiency first"],
        "body": [
            "Accelerate energy efficiency,",
            "technological upgrading and",
            "fuel switching.",
            "",
            "Model result: lower electricity",
            "demand, investment needs and",
            "carbon-price requirements."
        ]
    },
    {
        "x": 575, "y": 225, "w": 450, "h": 280, "fill": "#EAF1F8", "stroke": "#2C6E9B",
        "num": "2", "title": ["Carbon pricing with", "enabling policies"],
        "body": [
            "Phase in the ETS gradually and",
            "coordinate it with efficiency and",
            "renewable-energy policies.",
            "",
            "Model result: carbon pricing is",
            "less costly when firms have viable",
            "low-carbon adjustment options."
        ]
    },
    {
        "x": 1070, "y": 225, "w": 450, "h": 280, "fill": "#F1ECF8", "stroke": "#73539B",
        "num": "3", "title": ["Affordable green finance"],
        "body": [
            "Mobilise concessional, blended",
            "and publicly supported finance.",
            "",
            "Model result: lower financing",
            "costs accelerate investment and",
            "raise the payoff from greater",
            "climate ambition."
        ]
    }
]

for c in cards:
    svg.append(
        f'<rect x="{c["x"]}" y="{c["y"]}" width="{c["w"]}" height="{c["h"]}" '
        f'rx="24" fill="{c["fill"]}" stroke="{c["stroke"]}" stroke-width="3" '
        f'filter="url(#shadow)"/>'
    )
    svg.append(f'<circle cx="{c["x"]+44}" cy="{c["y"]+43}" r="24" fill="{c["stroke"]}"/>')
    svg.append(text_block(
        c["x"]+44, c["y"]+51, [c["num"]],
        size=21, weight=700, fill="#FFFFFF", anchor="middle"
    ))
    svg.append(text_block(
        c["x"]+82, c["y"]+40, c["title"],
        size=23, weight=700, fill="#102A43", line_gap=1.06
    ))
    svg.append(text_block(
        c["x"]+30, c["y"]+112, c["body"],
        size=17, fill="#334E68", line_gap=1.27
    ))

svg.append('<rect x="70" y="558" width="1460" height="38" rx="19" fill="#F7EFD7"/>')
svg.append(text_block(
    800, 584, ["ENABLING CONDITIONS"],
    size=16, weight=700, fill="#8B5E00", anchor="middle"
))

for x in [305, 800, 1295]:
    svg.append(
        f'<line x1="{x}" y1="510" x2="{x}" y2="566" '
        f'stroke="#5B7083" stroke-width="3" marker-end="url(#arrow)"/>'
    )

lower = [
    {
        "x": 150, "y": 625, "w": 620, "h": 270, "fill": "#FFF6DB", "stroke": "#B78000",
        "num": "4", "title": ["Strategic use of ETS revenues"],
        "body": [
            "Recycle revenues through non-fossil capital-tax",
            "reductions or targeted investment support rather",
            "than broad climate dividends when the objective is",
            "to stimulate investment.",
            "",
            "Use targeted transfers to protect vulnerable",
            "households."
        ]
    },
    {
        "x": 830, "y": 625, "w": 620, "h": 270, "fill": "#FDEDE7", "stroke": "#B95C3B",
        "num": "5", "title": ["Reliable and inclusive transition"],
        "body": [
            "Treat battery storage as a grid-reliability",
            "requirement and support labour mobility,",
            "retraining and skills development.",
            "",
            "These measures strengthen resilience and reduce",
            "adjustment costs."
        ]
    }
]

for c in lower:
    svg.append(
        f'<rect x="{c["x"]}" y="{c["y"]}" width="{c["w"]}" height="{c["h"]}" '
        f'rx="24" fill="{c["fill"]}" stroke="{c["stroke"]}" stroke-width="3" '
        f'filter="url(#shadow)"/>'
    )
    svg.append(f'<circle cx="{c["x"]+46}" cy="{c["y"]+45}" r="24" fill="{c["stroke"]}"/>')
    svg.append(text_block(
        c["x"]+46, c["y"]+53, [c["num"]],
        size=21, weight=700, fill="#FFFFFF", anchor="middle"
    ))
    svg.append(text_block(
        c["x"]+86, c["y"]+53, c["title"],
        size=23, weight=700, fill="#102A43"
    ))
    svg.append(text_block(
        c["x"]+34, c["y"]+108, c["body"],
        size=17, fill="#334E68", line_gap=1.25
    ))

svg.append(
    '<rect x="310" y="955" width="980" height="122" rx="30" '
    'fill="#0F6B5B" filter="url(#shadow)"/>'
)
svg.append(text_block(
    800, 1003, ["Combined outcome"],
    size=21, weight=700, fill="#D9F2EA", anchor="middle"
))
svg.append(text_block(
    800, 1040,
    ["Lower transition costs • stronger GDP growth • reliable power system",
     "and alignment with Viet Nam’s net-zero pathway"],
    size=20, weight=700, fill="#D9F2EA", anchor="middle", line_gap=1.18
))

svg.append(
    '<line x1="460" y1="900" x2="640" y2="944" '
    'stroke="#5B7083" stroke-width="4" marker-end="url(#arrow)"/>'
)
svg.append(
    '<line x1="1140" y1="900" x2="960" y2="944" '
    'stroke="#5B7083" stroke-width="4" marker-end="url(#arrow)"/>'
)

svg.append("</svg>")
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text("\n".join(svg), encoding="utf-8")

magick = shutil.which("magick")
if magick:
    subprocess.run(
        [magick, "-background", "white", str(out), str(png_out)],
        check=True,
    )
    print(f"Created PNG: {png_out}")
else:
    print("ImageMagick not found; skipped PNG export.")

print(f"Created revised SVG: {out}")
