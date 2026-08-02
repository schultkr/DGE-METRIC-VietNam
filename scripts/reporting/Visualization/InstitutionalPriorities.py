from pathlib import Path
import shutil
import subprocess
from xml.sax.saxutils import escape


out = Path(__file__).resolve().parent / "Vietnam_institutional_priorities.svg"
png_out = out.with_suffix(".png")

W, H = 1600, 1120


def text_block(
    x,
    y,
    lines,
    size=22,
    weight=400,
    fill="#16324F",
    anchor="start",
    line_gap=1.22,
    family="Arial, Helvetica, sans-serif",
):
    tspans = []
    for i, line in enumerate(lines):
        dy = "0" if i == 0 else f"{size * line_gap:.1f}"
        tspans.append(f'<tspan x="{x}" dy="{dy}">{escape(line)}</tspan>')
    return (
        f'<text x="{x}" y="{y}" text-anchor="{anchor}" '
        f'font-family="{family}" font-size="{size}" font-weight="{weight}" '
        f'fill="{fill}">' + "".join(tspans) + "</text>"
    )


svg = [
    f'''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
  <title>Institutional foundations for integrated energy-transition planning in Viet Nam</title>
  <desc>Editable vector figure showing four institutional priorities, seven enabling factors and their contribution to evidence-based energy-transition planning.</desc>
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
'''
]

svg.append(
    text_block(
        800,
        72,
        ["Institutional foundations for integrated energy-transition planning"],
        size=35,
        weight=700,
        fill="#102A43",
        anchor="middle",
    )
)
svg.append(
    text_block(
        800,
        112,
        [
            "Embedding macroeconomic assessment in national planning improves the quality,",
            "transparency and consistency of policy decisions.",
        ],
        size=19,
        fill="#486581",
        anchor="middle",
        line_gap=1.18,
    )
)

svg.append('<rect x="70" y="158" width="1460" height="38" rx="19" fill="#DCEFEA"/>')
svg.append(
    text_block(
        800,
        184,
        ["INSTITUTIONAL PRIORITIES"],
        size=16,
        weight=700,
        fill="#0F6B5B",
        anchor="middle",
    )
)

cards = [
    {
        "x": 90,
        "y": 222,
        "w": 680,
        "h": 205,
        "fill": "#E8F4EE",
        "stroke": "#2A7F62",
        "num": "1",
        "title": ["Institutionalise integrated assessment"],
        "body": [
            "Make macroeconomic assessment a regular component",
            "of national energy and investment planning,",
            "complementing technology-focused analysis.",
        ],
    },
    {
        "x": 830,
        "y": 222,
        "w": 680,
        "h": 205,
        "fill": "#EAF1F8",
        "stroke": "#2C6E9B",
        "num": "2",
        "title": ["Promote transparent analytical tools"],
        "body": [
            "Use open documentation, clear assumptions and",
            "reproducible modelling to strengthen institutional",
            "ownership and stakeholder confidence.",
        ],
    },
    {
        "x": 90,
        "y": 465,
        "w": 680,
        "h": 205,
        "fill": "#F1ECF8",
        "stroke": "#73539B",
        "num": "3",
        "title": ["Invest in national analytical capacity"],
        "body": [
            "Enable Vietnamese institutions to independently",
            "maintain, update and further develop integrated",
            "assessment tools.",
        ],
    },
    {
        "x": 830,
        "y": 465,
        "w": 680,
        "h": 205,
        "fill": "#FFF6DB",
        "stroke": "#B78000",
        "num": "4",
        "title": ["Use scenario analysis strategically"],
        "body": [
            "Compare pathways, assess uncertainties and develop",
            "robust long-term energy and investment strategies",
            "for a changing policy environment.",
        ],
    },
]

for card in cards:
    svg.append(
        f'<rect x="{card["x"]}" y="{card["y"]}" width="{card["w"]}" '
        f'height="{card["h"]}" rx="24" fill="{card["fill"]}" '
        f'stroke="{card["stroke"]}" stroke-width="3" filter="url(#shadow)"/>'
    )
    svg.append(
        f'<circle cx="{card["x"] + 46}" cy="{card["y"] + 44}" r="24" '
        f'fill="{card["stroke"]}"/>'
    )
    svg.append(
        text_block(
            card["x"] + 46,
            card["y"] + 52,
            [card["num"]],
            size=21,
            weight=700,
            fill="#FFFFFF",
            anchor="middle",
        )
    )
    svg.append(
        text_block(
            card["x"] + 88,
            card["y"] + 52,
            card["title"],
            size=23,
            weight=700,
            fill="#102A43",
        )
    )
    svg.append(
        text_block(
            card["x"] + 34,
            card["y"] + 105,
            card["body"],
            size=18,
            fill="#334E68",
            line_gap=1.28,
        )
    )

svg.append('<rect x="70" y="706" width="1460" height="38" rx="19" fill="#F7EFD7"/>')
svg.append(
    text_block(
        800,
        732,
        ["ENABLING FACTORS"],
        size=16,
        weight=700,
        fill="#8B5E00",
        anchor="middle",
    )
)

for x in [430, 1170]:
    svg.append(
        f'<line x1="{x}" y1="674" x2="{x}" y2="712" '
        f'stroke="#5B7083" stroke-width="3" marker-end="url(#arrow)"/>'
    )

factors = [
    ("High-quality and", "accessible data"),
    ("Strong institutional", "coordination"),
    ("Continuous stakeholder", "engagement"),
    ("Capacity", "development"),
    ("Transparent analytical", "methods"),
    ("Long-term institutional", "ownership"),
    ("International technical", "cooperation"),
]

factor_positions = [
    (95, 775),
    (460, 775),
    (825, 775),
    (1190, 775),
    (278, 872),
    (643, 872),
    (1008, 872),
]

for index, ((line_1, line_2), (x, y)) in enumerate(
    zip(factors, factor_positions), start=1
):
    width = 315
    svg.append(
        f'<rect x="{x}" y="{y}" width="{width}" height="72" rx="20" '
        f'fill="#FFFFFF" stroke="#B8C6D1" stroke-width="2"/>'
    )
    svg.append(f'<circle cx="{x + 28}" cy="{y + 36}" r="15" fill="#0F6B5B"/>')
    svg.append(
        text_block(
            x + 28,
            y + 42,
            [str(index)],
            size=14,
            weight=700,
            fill="#FFFFFF",
            anchor="middle",
        )
    )
    svg.append(
        text_block(
            x + 55,
            y + 29,
            [line_1, line_2],
            size=16,
            weight=600,
            fill="#334E68",
            line_gap=1.08,
        )
    )

svg.append(
    '<line x1="800" y1="952" x2="800" y2="978" '
    'stroke="#5B7083" stroke-width="4" marker-end="url(#arrow)"/>'
)
svg.append(
    '<rect x="260" y="990" width="1080" height="100" rx="28" '
    'fill="#0F6B5B" filter="url(#shadow)"/>'
)
svg.append(
    text_block(
        800,
        1029,
        ["Institutional foundation"],
        size=20,
        weight=700,
        fill="#D9F2EA",
        anchor="middle",
    )
)
svg.append(
    text_block(
        800,
        1063,
        [
            "Evidence-based planning and informed implementation",
            "of Viet Nam’s energy transition",
        ],
        size=20,
        weight=700,
        fill="#FFFFFF",
        anchor="middle",
        line_gap=1.15,
    )
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

print(f"Created SVG: {out}")
