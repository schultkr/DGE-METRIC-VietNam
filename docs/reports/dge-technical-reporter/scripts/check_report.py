#!/usr/bin/env python3
"""Check a Markdown, Quarto, LaTeX, or text report for required elements."""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Requirement:
    name: str
    patterns: tuple[str, ...]
    severity: str


REQUIREMENTS = (
    Requirement("abstract", (r"\babstract\b",), "error"),
    Requirement("executive summary", (r"executive\s+summary", r"summary\s+for\s+policymakers"), "warning"),
    Requirement("introduction", (r"\bintroduction\b", r"background\s+and\s+motivation"), "error"),
    Requirement("model overview", (r"model\s+overview", r"model\s+description", r"the\s+model"), "error"),
    Requirement("mathematical specification", (r"mathematical\s+specification", r"model\s+equations", r"equilibrium\s+conditions"), "warning"),
    Requirement("data or calibration", (r"\bcalibration\b", r"\bestimation\b", r"data\s+and\s+parameters"), "error"),
    Requirement("baseline", (r"\bbaseline\b", r"benchmark\s+equilibrium"), "error"),
    Requirement("scenario strategy", (r"scenario", r"simulation\s+strategy", r"policy\s+experiment"), "error"),
    Requirement("results", (r"\bresults\b", r"simulation\s+results"), "error"),
    Requirement("sensitivity or robustness", (r"sensitivity", r"robustness", r"uncertainty"), "warning"),
    Requirement("limitations", (r"\blimitations\b", r"caveats", r"interpretation\s+boundaries"), "error"),
    Requirement("implications", (r"policy\s+implications", r"research\s+implications", r"implications"), "warning"),
    Requirement("conclusions", (r"\bconclusions?\b",), "error"),
    Requirement("references", (r"\breferences\b", r"bibliography"), "error"),
    Requirement("appendix", (r"\bappendix\b", r"\bannex\b"), "warning"),
    Requirement("reproducibility", (r"reproduc", r"replication", r"software\s+environment"), "warning"),
)

PLACEHOLDER_PATTERNS = (
    r"\bTODO\b",
    r"\bTBD\b",
    r"\bFIXME\b",
    r"\bXXX\b",
    r"\[insert[^\]]*\]",
    r"\{\{[^}]+\}\}",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", help="Path to the report file")
    parser.add_argument(
        "--min-words",
        type=int,
        default=2500,
        help="Minimum expected word count (default: 2500)",
    )
    return parser.parse_args()


def normalize(text: str) -> str:
    cleaned = re.sub(r"%.*", " ", text)
    cleaned = re.sub(r"```.*?```", " ", cleaned, flags=re.DOTALL)
    cleaned = re.sub(r"\\[a-zA-Z]+\*?(?:\[[^\]]*\])?", " ", cleaned)
    return re.sub(r"\s+", " ", cleaned).lower()


def has_any(text: str, patterns: tuple[str, ...]) -> bool:
    return any(re.search(pattern, text, flags=re.IGNORECASE) for pattern in patterns)


def count_words(text: str) -> int:
    return len(re.findall(r"\b[\w'-]+\b", text))


def main() -> int:
    args = parse_args()
    report = Path(args.report).expanduser().resolve()
    if not report.exists() or not report.is_file():
        raise SystemExit(f"Report file not found: {report}")
    if args.min_words < 0:
        raise SystemExit("--min-words must be non-negative")

    try:
        raw = report.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        raise SystemExit(
            "This checker supports UTF-8 text formats such as .md, .qmd, .tex, and .txt. "
            "Export a text version for validation."
        )

    text = normalize(raw)
    errors: list[str] = []
    warnings: list[str] = []

    for requirement in REQUIREMENTS:
        if not has_any(text, requirement.patterns):
            target = errors if requirement.severity == "error" else warnings
            target.append(f"Missing or unrecognized section: {requirement.name}")

    word_count = count_words(raw)
    if word_count < args.min_words:
        warnings.append(f"Report is short for a complete technical report: {word_count} words")

    for pattern in PLACEHOLDER_PATTERNS:
        matches = re.findall(pattern, raw, flags=re.IGNORECASE)
        if matches:
            errors.append(f"Unresolved placeholder pattern `{pattern}`: {len(matches)} occurrence(s)")

    figure_mentions = len(re.findall(r"\bfigure\s+\d+", text))
    table_mentions = len(re.findall(r"\btable\s+\d+", text))
    if figure_mentions == 0:
        warnings.append("No numbered figure mentions found")
    if table_mentions == 0:
        warnings.append("No numbered table mentions found")

    if (figure_mentions or table_mentions) and not has_any(
        text, (r"source\s*:", r"generated\s+from", r"repository\s+path")
    ):
        warnings.append("Figures or tables appear to lack source or generation notes")

    if not has_any(text, (r"deviation\s+from\s+baseline", r"relative\s+to\s+baseline", r"compared\s+with\s+the\s+baseline")):
        warnings.append("Baseline-relative interpretation is not stated explicitly")

    if not has_any(text, (r"annual", r"cumulative")):
        warnings.append("Annual versus cumulative reporting is not discussed")

    if not has_any(text, (r"unit", r"percent", r"percentage", r"currency", r"constant\s+prices")):
        warnings.append("Units or price basis may be insufficiently documented")

    if not has_any(text, (r"source\s+map", r"evidence\s+ledger", r"file\s+path", r"repository\s+path")):
        warnings.append("No source map or repository evidence trail detected")

    print(f"Report: {report}")
    print(f"Word count: {word_count}")
    print(f"Errors: {len(errors)}")
    for item in errors:
        print(f"ERROR: {item}")
    print(f"Warnings: {len(warnings)}")
    for item in warnings:
        print(f"WARNING: {item}")

    if errors:
        return 1
    print("Quality gate passed with no errors.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
