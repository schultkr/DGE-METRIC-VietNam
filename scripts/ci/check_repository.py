"""Lightweight repository checks for DGE-METRIC.

Checks structure and documentation only; it never runs the model.

  1. Expected entry points and governance files exist.
  2. CITATION.cff has the required top-level fields.
  3. Relative links in the public documentation resolve.
  4. Repository paths quoted in backticks in the run/replication docs exist.
  5. Every DGE_* environment variable read by MATLAB code is documented.
  6. No generated artifacts (Dynare output, result caches, build files) are tracked.

Usage (from the repository root):  python scripts/ci/check_repository.py
Exit code is 1 if any check fails.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[2]

EXPECTED_FILES = [
    "README.md",
    "LICENSE",
    "CITATION.cff",
    "CONTRIBUTING.md",
    "CHANGELOG.md",
    "DGE_Model.mod",
    "DGE_Model_steadystate.m",
    "RunSimulations.m",
    "RunSimulationsEasy.m",
    "setup_paths.m",
    "docs/index.md",
    "docs/reference/running.md",
    "docs/reference/report_replication.md",
    "docs/reference/reproducibility_checklist.md",
    "docs/maintenance/report_repository_consistency.md",
]

CITATION_FIELDS = [
    "cff-version",
    "message",
    "title",
    "authors",
    "repository-code",
    "license",
    "version",
    "date-released",
]

# Public, curated documentation whose links must always resolve.
LINK_CHECKED_DOCS = [
    "README.md",
    "CONTRIBUTING.md",
    "CHANGELOG.md",
    "REPO_STRUCTURE.md",
    "docs/index.md",
    "docs/maintenance/*.md",
    "docs/reference/*.md",
    "docs/policy/*.md",
]

# Docs whose backticked repository paths must exist (operational instructions).
PATH_CHECKED_DOCS = [
    "README.md",
    "docs/reference/running.md",
    "docs/reference/report_replication.md",
    "docs/maintenance/report_repository_consistency.md",
]

# Documentation that may declare DGE_* environment variables.
ENV_VAR_DOCS = [
    "docs/reference/running.md",
    "docs/reference/report_replication.md",
]

# Tracked files matching these patterns are generated and must not be committed.
FORBIDDEN_TRACKED = [
    r"^\+DGE_Model/",
    r"^DGE_Model/",
    r"_dynamic\.m$",
    r"_static\.m$",
    r"_set_auxiliary_variables\.m$",
    r"^ExcelFiles/Output/",
    r"\.mat$",
    r"\.asv$",
    r"(^|/)~\$",
    r"(^|/)__pycache__/",
    r"\.pyc$",
    r"^DGE_Model\.log$",
    r"\.(aux|nav|snm|toc|fls|fdb_latexmk|synctex\.gz)$",
]

# Third-party teaching bundles are distributed as-is.
FORBIDDEN_ALLOWLIST = [r"^Training/"]

LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
CODE_SPAN_RE = re.compile(r"`([^`\n]+)`")
PATH_TOKEN_RE = re.compile(
    r"^(?:\./)?(?:[A-Za-z0-9_.+-]+/)*[A-Za-z0-9_.+-]+\.(?:m|mod|md|xlsx|csv|py|R|cff)$"
)
PATH_PREFIXES = ("Functions/", "ModFiles/", "scripts/", "docs/", "ExcelFiles/", "Training/")
ENV_USE_RE = re.compile(r"getenv\(\s*'(DGE_[A-Z0-9_]+)'")


def expand(patterns: list[str]) -> list[Path]:
    files: list[Path] = []
    for pattern in patterns:
        files.extend(sorted(ROOT.glob(pattern)))
    return [f for f in files if f.is_file()]


def strip_code_blocks(text: str) -> str:
    return re.sub(r"```.*?```", "", text, flags=re.S)


def check_expected_files() -> list[str]:
    return [f"missing expected file: {name}" for name in EXPECTED_FILES if not (ROOT / name).is_file()]


def check_citation() -> list[str]:
    path = ROOT / "CITATION.cff"
    if not path.is_file():
        return []
    keys = set(re.findall(r"^([A-Za-z-]+):", path.read_text(encoding="utf-8"), flags=re.M))
    return [f"CITATION.cff: missing field '{field}'" for field in CITATION_FIELDS if field not in keys]


def check_links() -> list[str]:
    errors = []
    for doc in expand(LINK_CHECKED_DOCS):
        text = strip_code_blocks(doc.read_text(encoding="utf-8", errors="replace"))
        for target in LINK_RE.findall(text):
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            target_path = unquote(target.split("#", 1)[0])
            if not target_path:
                continue
            if not (doc.parent / target_path).exists():
                errors.append(f"{doc.relative_to(ROOT).as_posix()}: broken link -> {target}")
    return errors


def check_documented_paths() -> list[str]:
    errors = []
    for doc in expand(PATH_CHECKED_DOCS):
        text = doc.read_text(encoding="utf-8", errors="replace")
        for token in set(CODE_SPAN_RE.findall(text)):
            token = token.strip()
            if not token.startswith(PATH_PREFIXES) or not PATH_TOKEN_RE.match(token):
                continue
            if not (ROOT / token).exists():
                errors.append(f"{doc.relative_to(ROOT).as_posix()}: documented path not found -> {token}")
    return errors


def check_env_vars() -> list[str]:
    used: dict[str, str] = {}
    for mfile in ROOT.glob("**/*.m"):
        rel = mfile.relative_to(ROOT).as_posix()
        if rel.startswith(("+DGE_Model/", "DGE_Model/", "Training/", ".venv/")):
            continue
        for name in ENV_USE_RE.findall(mfile.read_text(encoding="utf-8", errors="replace")):
            used.setdefault(name, rel)
    documented = "".join(
        (ROOT / doc).read_text(encoding="utf-8", errors="replace")
        for doc in ENV_VAR_DOCS
        if (ROOT / doc).is_file()
    )
    return [
        f"environment variable {name} (read in {where}) is not documented in {' or '.join(ENV_VAR_DOCS)}"
        for name, where in sorted(used.items())
        if name not in documented
    ]


def check_forbidden_tracked() -> list[str]:
    try:
        tracked = subprocess.run(
            ["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True
        ).stdout.splitlines()
    except (OSError, subprocess.CalledProcessError) as exc:
        return [f"could not list tracked files: {exc}"]
    errors = []
    for path in tracked:
        if any(re.search(p, path) for p in FORBIDDEN_ALLOWLIST):
            continue
        if not (ROOT / path).exists():
            continue  # deleted in the working tree; will not be committed
        if any(re.search(p, path) for p in FORBIDDEN_TRACKED):
            errors.append(f"generated artifact is tracked: {path}")
    return errors


def main() -> int:
    checks = [
        ("expected files", check_expected_files),
        ("CITATION.cff", check_citation),
        ("documentation links", check_links),
        ("documented paths", check_documented_paths),
        ("environment variables", check_env_vars),
        ("generated artifacts", check_forbidden_tracked),
    ]
    failed = False
    for label, check in checks:
        errors = check()
        status = "FAIL" if errors else "ok"
        print(f"[{status}] {label}")
        for error in errors:
            print(f"    - {error}")
        failed = failed or bool(errors)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
