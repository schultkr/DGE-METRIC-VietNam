# Generates the integrated policy-package diagram together with its
# companion "model results -> implementation" table
# (PolicyRecommendationsTable.py). Produces three outputs so each can be
# used on its own or combined, depending on the target document:
#   1. Figure only  -- Vietnam_integrated_policy_package_diagram.svg/.png
#   2. Table only    -- Vietnam_policy_recommendations_table.svg/.png
#   3. Combination   -- Vietnam_integrated_policy_package_revised.svg/.png
#      (figure with the table embedded directly beneath it, read as a
#      single Figure 10)
#
# Used in: IWH_Report_Macro_Impact_Assessment_revised.docx, Figure 10 (Policy
# Recommendations). See ../README_MacroImpactAssessment.md for the full
# figure map. This one is a hand-authored diagram, not a model-output chart,
# so there is no scenario CSV to regenerate first.

from pathlib import Path
from xml.sax.saxutils import escape

from PolicyRecommendationsTable import build_table_group, build_standalone_svg, write_svg_and_png

HERE = Path(__file__).resolve().parent
diagram_out = HERE / "Vietnam_integrated_policy_package_diagram.svg"
diagram_png_out = diagram_out.with_suffix(".png")
table_out = HERE / "Vietnam_policy_recommendations_table.svg"
table_png_out = table_out.with_suffix(".png")
combo_out = HERE / "Vietnam_integrated_policy_package_revised.svg"
combo_png_out = combo_out.with_suffix(".png")

W = 1600
DIAGRAM_H = 1120     # height of the diagram section alone
DIAGRAM_MARGIN_BOTTOM = 20  # bottom padding for the diagram-only figure
TABLE_GAP = 56        # vertical gap between the diagram and the embedded table

# IWH corporate-design palette (Functions/Miscellaneous/Plotting/iwh_colors.m
# is the single source of truth for brand colours in this repo). Reused
# identically in PolicyRecommendationsTable.py so the figure and its
# companion table stay colour-linked.
IWH_PRIMARY_BLUE = "#242B84"
IWH_MEDIUM_BLUE = "#5286D2"
IWH_SLATE = "#28313C"
IWH_GREEN = "#B2C823"
IWH_ORANGE = "#C8781E"
IWH_YELLOW = "#F0D019"
IWH_SLATE40 = "#9DA6AE"   # slate at 40% — muted connector lines/subtitle

# Pillar accents in iwh_colors.m's ordered scenario palette (order =
# [primaryBlue; orange; green; mediumBlue; yellow; slate]), one per pillar,
# with a light pastel tint of each for card fills.
PILLAR_ACCENT = [IWH_PRIMARY_BLUE, IWH_ORANGE, IWH_GREEN, IWH_MEDIUM_BLUE, IWH_YELLOW]
PILLAR_TINT = ["#E5E6F0", "#F8EFE4", "#F6F8E5", "#EAF0FA", "#FDF9E3"]


def badge_text_color(hex_color):
    """White or IWH slate text, whichever contrasts better on hex_color."""
    r, g, b = (int(hex_color[i : i + 2], 16) for i in (1, 3, 5))
    luminance = 0.299 * r + 0.587 * g + 0.114 * b
    return IWH_SLATE if luminance > 150 else "#FFFFFF"


def text_block(x, y, lines, size=22, weight=400, fill="#16324F",
               anchor="start", line_gap=1.22, family="Arial, Helvetica, sans-serif",
               justify_width=None):
    """lines may contain "" as a paragraph break (blank tspan row).

    If justify_width is given, each line is stretched via SVG's
    textLength/lengthAdjust to fill that width exactly (full justification),
    except: blank lines, the last line of the whole block, and the last line
    of a paragraph (the one right before a blank separator line) -- those
    stay natural/left-aligned, per standard typographic convention.
    """
    tspans = []
    n = len(lines)
    for i, line in enumerate(lines):
        dy = "0" if i == 0 else f"{size * line_gap:.1f}"
        is_last_overall = i == n - 1
        ends_paragraph = (i + 1 < n) and not lines[i + 1].strip()
        justify_attr = ""
        if (justify_width is not None and not is_last_overall and not ends_paragraph
                and " " in line.strip()):
            justify_attr = f' textLength="{justify_width:.1f}" lengthAdjust="spacing"'
        tspans.append(f'<tspan x="{x}" dy="{dy}"{justify_attr}>{escape(line)}</tspan>')
    return (
        f'<text x="{x}" y="{y}" text-anchor="{anchor}" '
        f'font-family="{family}" font-size="{size}" font-weight="{weight}" '
        f'fill="{fill}">' + "".join(tspans) + "</text>"
    )


def render_header(total_h):
    """Page background, top accent bar and shared <defs> (shadow filter,
    arrowhead marker), sized to total_h. Shared by the diagram-only and
    combined documents so they stay visually identical above the divider.
    """
    return [f'''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{total_h}" viewBox="0 0 {W} {total_h}">
  <title>Integrated policy package for Viet Nam's energy transition</title>
  <desc>Editable vector figure showing five mutually reinforcing policy pillars and their combined macroeconomic and climate outcomes.</desc>
  <defs>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="130%">
      <feDropShadow dx="0" dy="5" stdDeviation="7" flood-color="#000000" flood-opacity="0.13"/>
    </filter>
    <marker id="arrow" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L8,4 L0,8 z" fill="{IWH_SLATE40}"/>
    </marker>
  </defs>

  <rect x="0" y="0" width="{W}" height="{total_h}" fill="#F5F8FA"/>
  <rect x="0" y="0" width="{W}" height="16" fill="{IWH_PRIMARY_BLUE}"/>
''']


def build_diagram_elements():
    """Build the five-pillar diagram content (everything below the page
    background/accent bar set up by render_header): title, pillar cards,
    section bands, connectors and the combined-outcome box. Shared by the
    diagram-only figure and the combined figure+table output so the two
    never drift apart.
    """
    elements = []

    elements.append(text_block(
        800, 78,
        ["An integrated policy package for Viet Nam’s energy transition"],
        size=36, weight=700, fill=IWH_SLATE, anchor="middle"
    ))
    elements.append(text_block(
        800, 118,
        ["Five mutually reinforcing pillars reduce transition costs and strengthen growth"],
        size=20, fill=IWH_SLATE40, anchor="middle"
    ))

    elements.append(f'<rect x="70" y="160" width="1460" height="38" rx="19" fill="{PILLAR_TINT[0]}"/>')
    elements.append(text_block(
        800, 186, ["CORE ECONOMIC AND INVESTMENT PILLARS"],
        size=16, weight=700, fill=IWH_PRIMARY_BLUE, anchor="middle"
    ))

    cards = [
        {
            "x": 80, "y": 225, "w": 450, "h": 280, "fill": PILLAR_TINT[0], "stroke": PILLAR_ACCENT[0],
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
            "x": 575, "y": 225, "w": 450, "h": 280, "fill": PILLAR_TINT[1], "stroke": PILLAR_ACCENT[1],
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
            "x": 1070, "y": 225, "w": 450, "h": 280, "fill": PILLAR_TINT[2], "stroke": PILLAR_ACCENT[2],
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
        elements.append(
            f'<rect x="{c["x"]}" y="{c["y"]}" width="{c["w"]}" height="{c["h"]}" '
            f'rx="24" fill="{c["fill"]}" stroke="{c["stroke"]}" stroke-width="3" '
            f'filter="url(#shadow)"/>'
        )
        elements.append(f'<circle cx="{c["x"]+44}" cy="{c["y"]+43}" r="24" fill="{c["stroke"]}"/>')
        elements.append(text_block(
            c["x"]+44, c["y"]+51, [c["num"]],
            size=21, weight=700, fill=badge_text_color(c["stroke"]), anchor="middle"
        ))
        elements.append(text_block(
            c["x"]+82, c["y"]+40, c["title"],
            size=23, weight=700, fill=IWH_SLATE, line_gap=1.06
        ))
        elements.append(text_block(
            c["x"]+30, c["y"]+112, c["body"],
            size=17, fill=IWH_SLATE, line_gap=1.27, justify_width=c["w"] - 60
        ))

    elements.append(f'<rect x="70" y="558" width="1460" height="38" rx="19" fill="{PILLAR_TINT[3]}"/>')
    elements.append(text_block(
        800, 584, ["ENABLING CONDITIONS"],
        size=16, weight=700, fill=IWH_MEDIUM_BLUE, anchor="middle"
    ))

    for x in [305, 800, 1295]:
        elements.append(
            f'<line x1="{x}" y1="510" x2="{x}" y2="566" '
            f'stroke="{IWH_SLATE40}" stroke-width="3" marker-end="url(#arrow)"/>'
        )

    lower = [
        {
            "x": 150, "y": 625, "w": 620, "h": 270, "fill": PILLAR_TINT[3], "stroke": PILLAR_ACCENT[3],
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
            "x": 830, "y": 625, "w": 620, "h": 270, "fill": PILLAR_TINT[4], "stroke": PILLAR_ACCENT[4],
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
        elements.append(
            f'<rect x="{c["x"]}" y="{c["y"]}" width="{c["w"]}" height="{c["h"]}" '
            f'rx="24" fill="{c["fill"]}" stroke="{c["stroke"]}" stroke-width="3" '
            f'filter="url(#shadow)"/>'
        )
        elements.append(f'<circle cx="{c["x"]+46}" cy="{c["y"]+45}" r="24" fill="{c["stroke"]}"/>')
        elements.append(text_block(
            c["x"]+46, c["y"]+53, [c["num"]],
            size=21, weight=700, fill=badge_text_color(c["stroke"]), anchor="middle"
        ))
        elements.append(text_block(
            c["x"]+86, c["y"]+53, c["title"],
            size=23, weight=700, fill=IWH_SLATE
        ))
        elements.append(text_block(
            c["x"]+34, c["y"]+108, c["body"],
            size=17, fill=IWH_SLATE, line_gap=1.25, justify_width=c["w"] - 68
        ))

    elements.append(
        f'<rect x="310" y="955" width="980" height="122" rx="30" '
        f'fill="{IWH_PRIMARY_BLUE}" filter="url(#shadow)"/>'
    )
    elements.append(text_block(
        800, 1003, ["Combined outcome"],
        size=21, weight=700, fill="#FFFFFF", anchor="middle"
    ))
    elements.append(text_block(
        800, 1040,
        ["Lower transition costs • stronger GDP growth • reliable power system",
         "and alignment with Viet Nam’s net-zero pathway"],
        size=20, weight=700, fill="#FFFFFF", anchor="middle", line_gap=1.18
    ))

    elements.append(
        f'<line x1="460" y1="900" x2="640" y2="944" '
        f'stroke="{IWH_SLATE40}" stroke-width="4" marker-end="url(#arrow)"/>'
    )
    elements.append(
        f'<line x1="1140" y1="900" x2="960" y2="944" '
        f'stroke="{IWH_SLATE40}" stroke-width="4" marker-end="url(#arrow)"/>'
    )

    return elements


diagram_elements = build_diagram_elements()

# --- 1. Figure only: the diagram alone, no table -----------------------
diagram_h = DIAGRAM_H + DIAGRAM_MARGIN_BOTTOM
diagram_svg = render_header(diagram_h) + diagram_elements + ["</svg>"]
write_svg_and_png(diagram_svg, diagram_out, diagram_png_out)

# --- 2. Table only: same companion table PolicyRecommendationsTable.py
# produces standalone, generated here too so this script is self-sufficient.
table_svg, _table_h = build_standalone_svg()
write_svg_and_png(table_svg, table_out, table_png_out)

# --- 3. Combination: diagram with the table embedded directly beneath it,
# so the two read as a single Figure 10. A thin rule marks the section break.
divider_y = DIAGRAM_H + TABLE_GAP // 2
table_elements, table_bottom_y = build_table_group(y_shift=DIAGRAM_H + TABLE_GAP)
combo_h = table_bottom_y + 20
combo_svg = render_header(combo_h) + diagram_elements + [
    f'<line x1="70" y1="{divider_y}" x2="1530" y2="{divider_y}" '
    f'stroke="{IWH_SLATE40}" stroke-width="1.5" stroke-dasharray="2,6"/>'
] + table_elements + ["</svg>"]
write_svg_and_png(combo_svg, combo_out, combo_png_out)
