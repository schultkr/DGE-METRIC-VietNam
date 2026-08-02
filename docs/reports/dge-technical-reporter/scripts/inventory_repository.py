#!/usr/bin/env python3
"""Create a concise inventory of a model repository.

The script uses only the Python standard library. It does not read external
sources and does not modify the repository.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import subprocess
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


IGNORE_DIRS = {
    ".git",
    ".github",
    ".idea",
    ".vscode",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
    "node_modules",
    "dist",
    "build",
    "target",
    "tmp",
    "temp",
    "cache",
    ".cache",
    "venv",
    ".venv",
    "env",
}

TEXT_EXTENSIONS = {
    ".md", ".txt", ".rst", ".tex", ".bib", ".qmd", ".yaml", ".yml",
    ".json", ".toml", ".ini", ".cfg", ".csv", ".tsv", ".py", ".r",
    ".jl", ".m", ".mod", ".gms", ".inc", ".do", ".ado", ".sql",
    ".sh", ".bat", ".ps1", ".xml", ".html", ".ipynb",
}

ROLE_KEYWORDS = {
    "entry points and documentation": {
        "readme", "overview", "manual", "guide", "documentation", "docs",
        "technical report", "paper", "report", "manuscript",
    },
    "model equations and source": {
        "model", "equation", "equations", "core", "household", "firm",
        "production", "utility", "market clearing", "closure", "steady state",
        "steadystate", "dynare", "gams", "gempack",
    },
    "calibration and data": {
        "calibration", "calibrate", "parameter", "parameters", "sam",
        "social accounting", "input output", "input-output", "io table",
        "baseline", "benchmark", "data", "elasticity", "mapping",
    },
    "scenarios and shocks": {
        "scenario", "scenarios", "shock", "policy", "experiment", "ssp",
        "rcp", "adaptation", "mitigation", "counterfactual", "simulation",
    },
    "results and figures": {
        "result", "results", "output", "outputs", "figure", "figures",
        "table", "tables", "plot", "chart", "dashboard", "decomposition",
    },
    "validation and tests": {
        "test", "tests", "validation", "validate", "check", "replication",
        "reproduce", "reproducibility", "benchmark test", "log",
    },
    "references": {
        "reference", "references", "bibliography", "literature", "citation",
    },
}


@dataclass(frozen=True)
class FileRecord:
    rel_path: str
    suffix: str
    size: int
    role: str
    sha256: str | None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", help="Path to the repository checkout")
    parser.add_argument(
        "--output",
        default="repository_inventory.md",
        help="Markdown output path (default: repository_inventory.md)",
    )
    parser.add_argument(
        "--hash-limit-mb",
        type=float,
        default=5.0,
        help="Hash files up to this size in MB (default: 5)",
    )
    parser.add_argument(
        "--max-files-per-role",
        type=int,
        default=80,
        help="Maximum paths listed for each role (default: 80)",
    )
    return parser.parse_args()


def classify_role(rel_path: str) -> str:
    normalized = rel_path.lower().replace("_", " ").replace("-", " ")
    scores: dict[str, int] = {}
    for role, keywords in ROLE_KEYWORDS.items():
        scores[role] = sum(1 for keyword in keywords if keyword in normalized)
    best_role = max(scores, key=scores.get)
    return best_role if scores[best_role] > 0 else "other files"


def file_hash(path: Path, size_limit: int) -> str | None:
    try:
        if path.stat().st_size > size_limit:
            return None
        digest = hashlib.sha256()
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
        return digest.hexdigest()
    except OSError:
        return None


def walk_files(root: Path, hash_limit: int) -> Iterable[FileRecord]:
    for current_root, dir_names, file_names in os.walk(root):
        dir_names[:] = sorted(
            name for name in dir_names if name not in IGNORE_DIRS and not name.startswith(".")
        )
        for file_name in sorted(file_names):
            if file_name.startswith("."):
                continue
            path = Path(current_root) / file_name
            try:
                rel_path = path.relative_to(root).as_posix()
                size = path.stat().st_size
            except OSError:
                continue
            yield FileRecord(
                rel_path=rel_path,
                suffix=path.suffix.lower() or "[no extension]",
                size=size,
                role=classify_role(rel_path),
                sha256=file_hash(path, hash_limit),
            )


def git_metadata(root: Path) -> tuple[str | None, str | None]:
    def run_git(args: list[str]) -> str | None:
        try:
            result = subprocess.run(
                ["git", "-C", str(root), *args],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
                timeout=10,
            )
            value = result.stdout.strip()
            return value or None
        except (OSError, subprocess.SubprocessError):
            return None

    return run_git(["rev-parse", "HEAD"]), run_git(["status", "--porcelain"])


def human_size(size: int) -> str:
    value = float(size)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if value < 1024 or unit == "TB":
            return f"{value:.1f} {unit}"
        value /= 1024
    return f"{size} B"


def render_inventory(root: Path, records: list[FileRecord], max_per_role: int) -> str:
    ext_counts = Counter(record.suffix for record in records)
    role_groups: dict[str, list[FileRecord]] = defaultdict(list)
    for record in records:
        role_groups[record.role].append(record)

    commit, status = git_metadata(root)
    total_size = sum(record.size for record in records)
    largest = sorted(records, key=lambda record: record.size, reverse=True)[:20]

    lines: list[str] = []
    lines.append("# Repository inventory")
    lines.append("")
    lines.append(f"- Repository: `{root}`")
    lines.append(f"- Files scanned: {len(records)}")
    lines.append(f"- Total scanned size: {human_size(total_size)}")
    lines.append(f"- Git commit: `{commit}`" if commit else "- Git commit: not available")
    if status is None:
        lines.append("- Git working tree: not available")
    elif status:
        changed_count = len(status.splitlines())
        lines.append(f"- Git working tree: {changed_count} changed or untracked item(s)")
    else:
        lines.append("- Git working tree: clean")

    lines.append("")
    lines.append("## File types")
    lines.append("")
    lines.append("| Extension | Count |")
    lines.append("|---|---:|")
    for suffix, count in sorted(ext_counts.items(), key=lambda item: (-item[1], item[0])):
        lines.append(f"| `{suffix}` | {count} |")

    lines.append("")
    lines.append("## Files by likely role")
    lines.append("")
    role_order = list(ROLE_KEYWORDS) + ["other files"]
    for role in role_order:
        group = sorted(role_groups.get(role, []), key=lambda record: record.rel_path.lower())
        if not group:
            continue
        lines.append(f"### {role.title()}")
        lines.append("")
        for record in group[:max_per_role]:
            hash_note = f", sha256 `{record.sha256[:12]}...`" if record.sha256 else ""
            lines.append(f"- `{record.rel_path}` ({human_size(record.size)}{hash_note})")
        if len(group) > max_per_role:
            lines.append(f"- ... {len(group) - max_per_role} additional file(s) omitted")
        lines.append("")

    lines.append("## Largest files")
    lines.append("")
    lines.append("| Path | Size |")
    lines.append("|---|---:|")
    for record in largest:
        lines.append(f"| `{record.rel_path}` | {human_size(record.size)} |")

    lines.append("")
    lines.append("## Initial review prompts")
    lines.append("")
    lines.append("- Which file defines the operative model equations?")
    lines.append("- Which configuration produced the reported outputs?")
    lines.append("- Where are the baseline, calibration targets, and parameter sources stored?")
    lines.append("- Can each publication figure and table be traced to a script and raw output?")
    lines.append("- Are there documentation and code conflicts or missing replication instructions?")
    lines.append("")
    lines.append("This inventory is a filename-based map. Confirm classifications by reading the files.")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    root = Path(args.repository).expanduser().resolve()
    output = Path(args.output).expanduser().resolve()
    if not root.exists() or not root.is_dir():
        raise SystemExit(f"Repository path is not a directory: {root}")
    if args.hash_limit_mb < 0:
        raise SystemExit("--hash-limit-mb must be non-negative")
    if args.max_files_per_role < 1:
        raise SystemExit("--max-files-per-role must be at least 1")

    hash_limit = int(args.hash_limit_mb * 1024 * 1024)
    records = list(walk_files(root, hash_limit))
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render_inventory(root, records, args.max_files_per_role), encoding="utf-8")
    print(f"Wrote inventory: {output}")
    print(f"Scanned files: {len(records)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
