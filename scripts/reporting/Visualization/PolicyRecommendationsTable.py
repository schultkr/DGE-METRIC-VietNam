# Companion table for the "integrated policy package" figure.
#
# Addresses the review comment (Nguyen Hoang Lan, 25.08.2026) on the Policy
# Recommendations section: bridge the theoretical macroeconomic findings with
# Vietnam's practical institutional, physical and legal constraints by presenting
#   - key model results,
#   - policy implications directly derived from those results,
#   - proposed solutions that take account of institutional and regulatory
#     constraints,
#   - potential barriers to implementation.
#
# One row per pillar of Vietnam_integrated_policy_package_revised.svg
# (PolicyRecommendations.py), which now embeds this table directly beneath the
# diagram (see build_table_group() below) so the two read as a single Figure 10.
#
# Running this file directly still produces the standalone companion table
# (Vietnam_policy_recommendations_table.svg/.png) for uses outside that figure
# (e.g. the .docx export). build_table_group() is the reusable entry point
# PolicyRecommendations.py imports to embed the same content inline.

from pathlib import Path
import shutil
import subprocess
import textwrap
from xml.sax.saxutils import escape

out = Path(__file__).resolve().parent / "Vietnam_policy_recommendations_table.svg"
png_out = out.with_suffix(".png")

MARGIN = 40
W = 1600

# (header label, column width). Widths sum to W - 2 * MARGIN = 1520.
COLUMNS = [
    ("Key model result", 340),
    ("Policy implication (derived from the model)", 350),
    ("Proposed solution — institutional & regulatory constraints", 470),
    ("Potential barriers to implementation", 360),
]

TITLE = ""
SUBTITLE = (
    ""
)

# IWH corporate-design palette (Functions/Miscellaneous/Plotting/iwh_colors.m
# is the single source of truth for brand colours in this repo).
IWH_PRIMARY_BLUE = "#242B84"
IWH_MEDIUM_BLUE = "#5286D2"
IWH_SLATE = "#28313C"
IWH_GREEN = "#B2C823"
IWH_ORANGE = "#C8781E"
IWH_YELLOW = "#F0D019"
IWH_SLATE10 = "#E4E7EA"   # slate at 10% — zebra-row shading
IWH_SLATE25 = "#C0C7CD"   # slate at 25% — borders / separators
IWH_SLATE40 = "#9DA6AE"   # slate at 40% — muted secondary text

# Pillar accent colours: iwh_colors.m's ordered scenario palette (order =
# [primaryBlue; orange; green; mediumBlue; yellow; slate]), one per pillar.
# Reused identically in PolicyRecommendations.py so the figure and its
# embedded table stay colour-linked.
ACCENTS = [IWH_PRIMARY_BLUE, IWH_ORANGE, IWH_GREEN, IWH_MEDIUM_BLUE, IWH_YELLOW]


def badge_text_color(hex_color):
    """White or IWH slate text, whichever contrasts better on hex_color."""
    r, g, b = (int(hex_color[i : i + 2], 16) for i in (1, 3, 5))
    luminance = 0.299 * r + 0.587 * g + 0.114 * b
    return IWH_SLATE if luminance > 150 else "#FFFFFF"

ROWS = [
    {
        "num": "1",
        "pillar": "Efficiency first",
        "result": (
            "Accelerating energy efficiency, technological upgrading and fuel "
            "switching lowers electricity demand, generation and grid investment "
            "needs, and the carbon price required to stay on the net-zero path. It "
            "delivers the largest modelled economic gain per unit of cost."
        ),
        "implication": (
            "Put demand-side efficiency at the centre of PDP8-rev implementation "
            "and treat avoided demand as a system resource on a par with new "
            "supply."
        ),
        "solution": (
            "Enforce minimum energy-performance standards and the Directive "
            "10/CT-TTg electricity-saving targets through binding sub-sector "
            "energy-intensity benchmarks and mandatory audits for designated large "
            "energy users; capitalise a revolving efficiency fund and ESCO / "
            "energy-performance contracting under the State Bank green-credit "
            "framework."
        ),
        "barriers": (
            "Split incentives between landlords and tenants and within SOEs; "
            "limited measurement, reporting and verification (MRV) and enforcement "
            "capacity at provincial DOIT level; subsidised retail tariffs lengthen "
            "payback; thin ESCO market and short project-finance track record."
        ),
    },
    {
        "num": "2",
        "pillar": "Carbon pricing with enabling policies",
        "result": (
            "The emissions trading system (ETS) is markedly less costly when firms "
            "also have efficiency options and affordable finance. A gradual, "
            "coordinated price path reaches the emissions trajectory at lower GDP "
            "cost than carbon pricing alone."
        ),
        "implication": (
            "Phase the ETS in gradually, sequence it after efficiency and "
            "renewable-energy enabling measures, and give firms a predictable "
            "long-term price signal."
        ),
        "solution": (
            "Run the 2025-2028 pilot under Decree 06/2022/ND-CP and the amended "
            "Law on Environmental Protection with free, benchmarked allocation for "
            "trade-exposed industry; align the domestic price and MRV rules with "
            "the EU CBAM timeline; complete the national GHG inventory and "
            "registry and ring-fence a price-stability reserve."
        ),
        "barriers": (
            "Incomplete facility-level emissions data; carbon-leakage and "
            "competitiveness concerns for cement, steel and textiles; institutional "
            "capacity to operate MRV, registry and auctions; political sensitivity "
            "of higher energy prices."
        ),
    },
    {
        "num": "3",
        "pillar": "Affordable green finance",
        "result": (
            "Lowering the weighted average cost of capital — not raising the "
            "volume of public spending — accelerates investment and raises the "
            "economic payoff from greater climate ambition."
        ),
        "implication": (
            "Prioritise instruments that cut financing cost and risk: blended "
            "finance, guarantees, risk-sharing facilities, green bonds and green "
            "credit, delivered through the JETP and the national green taxonomy."
        ),
        "solution": (
            "Operationalise the green taxonomy and the State Bank green-banking "
            "framework; deploy partial credit guarantees and FX-hedging facilities "
            "within the public-debt ceiling and limited fiscal space; standardise "
            "bankable PPA terms and dispute resolution; speed JETP disbursement."
        ),
        "barriers": (
            "Sovereign and EVN off-taker credit risk; currency mismatch and a "
            "shallow domestic capital market; PPAs not yet bankable for many "
            "projects; public-debt and contingent-liability limits on guarantees; "
            "slow mobilisation of pledged concessional funds."
        ),
    },
    {
        "num": "4",
        "pillar": "Strategic use of ETS revenues",
        "result": (
            "Recycling ETS revenue through non-fossil capital-tax reductions or "
            "targeted investment support stimulates investment more than broad "
            "per-capita dividends; targeted transfers still protect vulnerable "
            "households at low aggregate cost."
        ),
        "implication": (
            "Earmark ETS revenue for transition investment and a just-transition "
            "fund rather than the general budget or untargeted rebates."
        ),
        "solution": (
            "Given State Budget Law limits on hypothecating tax revenue, route "
            "receipts through a dedicated environmental-protection / transition "
            "fund with a statutory revenue mandate and published accounts; use "
            "existing social-assistance registries for targeted household "
            "transfers."
        ),
        "barriers": (
            "Legal restrictions on earmarking; competing budget priorities; weak "
            "targeting coverage for informal-sector households; governance and "
            "transparency risk in fund management."
        ),
    },
    {
        "num": "5",
        "pillar": "Reliable and inclusive transition",
        "result": (
            "Treating battery storage as a grid-reliability requirement and "
            "supporting labour mobility, retraining and skills lowers adjustment "
            "costs and strengthens resilience. Headline efficiency gains are "
            "conditional on the assumed rooftop-solar rollout; BESS contributes "
            "through system reliability rather than through aggregate GDP."
        ),
        "implication": (
            "Plan storage and flexibility alongside renewable capacity in "
            "PDP8-rev, and pair transition policy with active labour-market and "
            "regional support for fossil-dependent provinces and workers."
        ),
        "solution": (
            "Introduce a capacity / ancillary-services market and a storage "
            "procurement mandate; finalise direct power purchase agreement (DPPA) "
            "and rooftop-solar rules; fund reskilling through the vocational "
            "system and the Employment Fund; provide targeted support to "
            "coal-dependent communities such as Quang Ninh."
        ),
        "barriers": (
            "No market mechanism yet remunerates storage or flexibility; EVN "
            "single-buyer model and grid-code gaps; fiscal cost of reskilling; "
            "concentrated coal-sector employment and SOE-restructuring politics; "
            "land and grid-connection permitting delays."
        ),
    },
]

FOOTER = (
    "Model results are directional, scenario-relative magnitudes from DGE-METRIC "
    "(five-sector annual general equilibrium, 2026-2050) under stated assumptions "
    "— not point forecasts."
)

BODY_SIZE = 14.5
HEAD_SIZE = 15.0
LINE_GAP = 19.0
PAD_X = 14
PAD_TOP = 16
PAD_BOT = 14
FONT = "Arial, Helvetica, sans-serif"


def wrap(text, col_width, size=BODY_SIZE):
    chars = max(8, int((col_width - 2 * PAD_X) / (size * 0.52)))
    lines = textwrap.wrap(text, chars)
    return lines or [""]


def text_lines(x, y_top, lines, size, weight=400, fill=IWH_SLATE, justify_width=None):
    """Top-aligned multi-line text; first baseline at y_top + size.

    If justify_width is given, every line except the last of a wrapped
    paragraph is stretched via SVG's textLength/lengthAdjust to fill that
    width exactly (full justification, like CSS text-align: justify).
    lengthAdjust="spacing" only stretches the inter-word gaps, not the
    letters themselves, so justified lines still look like normal text. The
    last line is left short/natural, per standard typographic convention
    (and because a single word stretched to the full column width would
    look broken).
    """
    tspans = []
    n = len(lines)
    for i, line in enumerate(lines):
        dy = f"{size:.1f}" if i == 0 else f"{LINE_GAP:.1f}"
        justify_attr = ""
        if justify_width is not None and i < n - 1 and " " in line.strip():
            justify_attr = f' textLength="{justify_width:.1f}" lengthAdjust="spacing"'
        tspans.append(f'<tspan x="{x}" dy="{dy}"{justify_attr}>{escape(line)}</tspan>')
    return (
        f'<text x="{x}" y="{y_top}" font-family="{FONT}" font-size="{size}" '
        f'font-weight="{weight}" fill="{fill}">' + "".join(tspans) + "</text>"
    )


# Column x-positions (fixed; independent of vertical placement).
_x = MARGIN
col_x = []
for _, _w in COLUMNS:
    col_x.append(_x)
    _x += _w
table_right = _x
col_x.append(table_right)


def build_table_group(y_shift=0, include_title=True):
    """Build the SVG elements for the policy-recommendations table, with the
    same layout the standalone figure uses but shifted down by y_shift so it
    can be embedded under another SVG body (e.g. PolicyRecommendations.py's
    diagram). Does NOT draw a page background or top accent bar -- the caller
    owns those for the combined canvas.

    Returns (elements, bottom_y): the list of SVG element strings, and the
    absolute y-coordinate of the lowest content (for sizing the canvas / the
    standalone wrapper).
    """
    elements = []

    top_y = 176 + y_shift
    if include_title:
        elements.append(
            f'<text x="{MARGIN}" y="{76 + y_shift}" font-family="{FONT}" '
            f'font-size="32" font-weight="700" fill="{IWH_SLATE}">'
            f'{escape(TITLE)}</text>'
        )
        elements.append(
            text_lines(MARGIN, 96 + y_shift, wrap(SUBTITLE, W - 2 * MARGIN, 17),
                       17, 400, IWH_SLATE40)
        )

    # Header band height.
    head_lines = [wrap(label, w, HEAD_SIZE) for (label, w) in COLUMNS]
    head_h = PAD_TOP + max(len(l) for l in head_lines) * LINE_GAP + PAD_BOT

    # Row heights.
    row_meta = []
    for row in ROWS:
        c1 = wrap(row["result"], COLUMNS[0][1])
        c2 = wrap(row["implication"], COLUMNS[1][1])
        c3 = wrap(row["solution"], COLUMNS[2][1])
        c4 = wrap(row["barriers"], COLUMNS[3][1])
        # column 1 also carries the pillar name (bold) + a blank spacer line.
        n_lines = max(len(c1) + 2, len(c2), len(c3), len(c4))
        h = PAD_TOP + n_lines * LINE_GAP + PAD_BOT
        row_meta.append({"c1": c1, "c2": c2, "c3": c3, "c4": c4, "h": h})

    table_top = top_y + 8
    body_top = table_top + head_h

    # Header row.
    elements.append(
        f'<rect x="{MARGIN}" y="{table_top}" width="{table_right - MARGIN}" '
        f'height="{head_h}" fill="{IWH_PRIMARY_BLUE}" filter="url(#shadow)"/>'
    )
    for i, (label, w) in enumerate(COLUMNS):
        elements.append(
            text_lines(col_x[i] + PAD_X, table_top + PAD_TOP, head_lines[i],
                       HEAD_SIZE, weight=700, fill="#FFFFFF")
        )

    # Data rows.
    y = body_top
    for idx, (row, meta) in enumerate(zip(ROWS, row_meta)):
        fill = "#FFFFFF" if idx % 2 == 0 else IWH_SLATE10
        accent = ACCENTS[idx % len(ACCENTS)]
        badge_fg = badge_text_color(accent)
        elements.append(
            f'<rect x="{MARGIN}" y="{y}" width="{table_right - MARGIN}" '
            f'height="{meta["h"]}" fill="{fill}" stroke="{IWH_SLATE25}" stroke-width="1"/>'
        )
        elements.append(f'<rect x="{MARGIN}" y="{y}" width="5" height="{meta["h"]}" fill="{accent}"/>')

        # Column 1: badge + pillar name (bold) + blank line + model result.
        elements.append(
            f'<circle cx="{col_x[0] + PAD_X + 11}" cy="{y + PAD_TOP + 8}" r="11" '
            f'fill="{accent}"/>'
        )
        elements.append(
            f'<text x="{col_x[0] + PAD_X + 11}" y="{y + PAD_TOP + 13}" '
            f'text-anchor="middle" font-family="{FONT}" font-size="13" '
            f'font-weight="700" fill="{badge_fg}">{row["num"]}</text>'
        )
        elements.append(
            f'<text x="{col_x[0] + PAD_X + 30}" y="{y + PAD_TOP + 13}" '
            f'font-family="{FONT}" font-size="15" font-weight="700" fill="{IWH_SLATE}">'
            f'{escape(row["pillar"])}</text>'
        )
        elements.append(
            text_lines(col_x[0] + PAD_X, y + PAD_TOP + int(2 * LINE_GAP), meta["c1"], BODY_SIZE,
                       justify_width=COLUMNS[0][1] - 2 * PAD_X)
        )
        for ci, key in ((1, "c2"), (2, "c3"), (3, "c4")):
            elements.append(text_lines(col_x[ci] + PAD_X, y + PAD_TOP, meta[key], BODY_SIZE,
                                        justify_width=COLUMNS[ci][1] - 2 * PAD_X))
        y += meta["h"]

    # Column separators over the whole table.
    for i in range(1, len(COLUMNS)):
        elements.append(
            f'<line x1="{col_x[i]}" y1="{table_top}" x2="{col_x[i]}" y2="{y}" '
            f'stroke="{IWH_SLATE25}" stroke-width="1"/>'
        )

    footer_lines = wrap(FOOTER, W - 2 * MARGIN, 13)
    elements.append(text_lines(MARGIN, y + 22, footer_lines, 13, 400, IWH_SLATE40,
                                justify_width=W - 2 * MARGIN - 2 * PAD_X))
    bottom_y = y + 22 + len(footer_lines) * 17 + 12

    return elements, int(bottom_y)


def build_standalone_svg():
    """Build the full standalone table document (own page background, top
    accent bar and defs) as PolicyRecommendations.py's diagram-only and
    combined outputs also need a standalone table file. Returns
    (svg_lines, height) -- callers write/convert it themselves so this stays
    a pure builder.
    """
    table_elements, H = build_table_group(y_shift=0)
    H += 20

    svg = [
        '<?xml version="1.0" encoding="UTF-8" standalone="no"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
        f'viewBox="0 0 {W} {H}">',
        "  <title>From model results to implementation in Viet Nam's institutional "
        "context</title>",
        '  <desc>Editable vector table linking each policy pillar to its key model '
        'result, policy implication, an institutionally constrained solution and the '
        'main implementation barriers.</desc>',
        '  <defs>',
        '    <filter id="shadow" x="-10%" y="-10%" width="120%" height="130%">'
        '<feDropShadow dx="0" dy="4" stdDeviation="6" flood-color="#000000" '
        'flood-opacity="0.12"/></filter>',
        '  </defs>',
        f'<rect x="0" y="0" width="{W}" height="{H}" fill="#F5F8FA"/>',
        f'<rect x="0" y="0" width="{W}" height="16" fill="{IWH_PRIMARY_BLUE}"/>',
    ]
    svg.extend(table_elements)
    svg.append("</svg>")
    return svg, H


def write_svg_and_png(svg_lines, svg_path, png_path):
    """Write svg_lines to svg_path and, if ImageMagick is on PATH, convert to
    png_path. Shared by PolicyRecommendationsTable.py's own standalone output
    and PolicyRecommendations.py's figure/table/combination outputs so the
    write+convert step doesn't drift between the two scripts.
    """
    svg_path.parent.mkdir(parents=True, exist_ok=True)
    svg_path.write_text("\n".join(svg_lines), encoding="utf-8")

    magick = shutil.which("magick")
    if magick:
        subprocess.run(
            [magick, "-background", "white", str(svg_path), str(png_path)],
            check=True,
        )
        print(f"Created PNG: {png_path}")
    else:
        print("ImageMagick not found; skipped PNG export.")

    print(f"Created SVG: {svg_path}")


if __name__ == "__main__":
    svg, _H = build_standalone_svg()
    write_svg_and_png(svg, out, png_out)
