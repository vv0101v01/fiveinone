#!/usr/bin/env python3
"""Documentation consistency gate.

This checker intentionally covers only facts that are cheap and objective:
local Markdown links, the documentation index, the canonical repository URL,
current governance counts, and a short list of phrases that would contradict
the published state. Prose quality and mathematical scope remain review work;
see docs/ENGINEERING-GAPS.md.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXCLUDED_DIRS = {".git", "_build", ".mooncakes", ".moonagent", "target"}
CURRENT_DOCS = {
    "README.md",
    "ARCHITECTURE.md",
    "GUIDE.md",
    "GUIDE.en.md",
    "SPEC.md",
    "SPEC.en.md",
    "docs/STATUS.md",
    "docs/MIGRATION.md",
    "docs/LEGACY-ARCHIVE.md",
    "docs/ENGINEERING-GAPS.md",
    "docs/GRAND-UNIFICATION.md",
}
FORBIDDEN_CURRENT = [
    "待遠端憑證",
    "遠端待憑證",
    "尚未推送",
    "主倉實際推送並驗證前",
    "github.com/vv0101v01/algorithms02",
]


def markdown_files() -> list[Path]:
    out: list[Path] = []
    for path in ROOT.rglob("*.md"):
        if any(part in EXCLUDED_DIRS for part in path.parts):
            continue
        out.append(path)
    return sorted(out)


def local_link_errors() -> list[str]:
    errors: list[str] = []
    link_re = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
    for path in markdown_files():
        rel = path.relative_to(ROOT)
        for lineno, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
            for raw in link_re.findall(line):
                target = raw.strip().strip("<>").split()[0].split("#", 1)[0]
                if (
                    not target
                    or "://" in target
                    or target.startswith(("mailto:", "javascript:", "/"))
                ):
                    continue
                if not (path.parent / target).exists():
                    errors.append(f"{rel}:{lineno}: missing local link target {raw!r}")
    return errors


def count_mbt() -> tuple[int, int]:
    files = 0
    lines = 0
    for path in ROOT.rglob("*.mbt"):
        if any(part in EXCLUDED_DIRS for part in path.parts):
            continue
        files += 1
        lines += len(path.read_text(errors="ignore").splitlines())
    return files, lines


def main() -> int:
    errors = local_link_errors()

    index_path = ROOT / "docs" / "README.md"
    if not index_path.exists():
        errors.append("docs/README.md: documentation index is missing")
        index_text = ""
    else:
        index_text = index_path.read_text(errors="ignore")
        for path in markdown_files():
            rel = path.relative_to(ROOT).as_posix()
            if rel == "docs/README.md":
                continue
            # Links in the index are written relative to docs/; accepting
            # either the repository path or that relative spelling keeps the
            # table readable without weakening the ownership requirement.
            rel_from_docs = Path(rel).name if path.parent == ROOT else str(
                path.relative_to(ROOT / "docs")
            ) if (ROOT / "docs") in path.parents else rel
            if rel not in index_text and rel_from_docs not in index_text:
                errors.append(f"docs/README.md: Markdown file is not indexed: {rel}")

    arch = json.loads((ROOT / "architecture.json").read_text())
    packages = len(arch["packages"])
    components = len(arch["components"])
    mbt_files, mbt_lines = count_mbt()
    appendix = (ROOT / "SPEC-APPENDIX.md").read_text(errors="ignore")
    m = re.search(r"共 \*\*(\d+)\*\* 個公共符號", appendix)
    if not m:
        errors.append("SPEC-APPENDIX.md: cannot parse public-symbol count")
        symbols = -1
    else:
        symbols = int(m.group(1))

    expected = {
        "packages": f"{packages} packages",
        "components": f"{components} components",
        "mbt_files": f"{mbt_files} `.mbt` files",
        "mbt_lines": f"{mbt_lines:,} `.mbt` lines",
        "symbols": f"{symbols:,} public symbols",
    }
    for name in ("README.md", "docs/STATUS.md"):
        path = ROOT / name
        if not path.exists():
            errors.append(f"{name}: missing current-status document")
            continue
        text = path.read_text(errors="ignore")
        for label, needle in expected.items():
            if needle not in text:
                errors.append(f"{name}: stale {label}; expected text {needle!r}")

    moon_mod = (ROOT / "moon.mod").read_text(errors="ignore")
    repository_match = re.search(
        r'^repository\s*=\s*"(https://github\.com/[^"\s]+)"',
        moon_mod,
        re.M,
    )
    if not repository_match:
        errors.append("moon.mod: missing canonical HTTPS GitHub repository")
    else:
        canonical_repository = repository_match.group(1).rstrip("/")
        for name in ("README.md", "AGENTS.md", "CONTRIBUTING.md", "docs/STATUS.md", "docs/MIGRATION.md"):
            path = ROOT / name
            if path.exists() and canonical_repository not in path.read_text(errors="ignore"):
                errors.append(f"{name}: missing canonical repository URL {canonical_repository!r}")

    toolchain_path = ROOT / ".moon-toolchain"
    if not toolchain_path.exists():
        errors.append(".moon-toolchain: missing pinned MoonBit toolchain file")
    else:
        toolchain = toolchain_path.read_text(errors="ignore")
        if not re.search(r"^moon=\d+\.\d+\.\d+$", toolchain, re.M):
            errors.append(".moon-toolchain: expected moon=<version>")
        if not re.search(r"^moonc=v[0-9A-Za-z.+-]+$", toolchain, re.M):
            errors.append(".moon-toolchain: expected moonc=<version>")
        if not re.search(r"^release=[0-9A-Za-z.+-]+$", toolchain, re.M):
            errors.append(".moon-toolchain: expected release=<installer version>")
        for key in ("linux_x86_64_archive_sha256", "linux_core_archive_sha256"):
            if not re.search(rf"^{key}=[0-9a-f]{{64}}$", toolchain, re.M):
                errors.append(f".moon-toolchain: invalid SHA-256 for {key}")

    for rel in sorted(CURRENT_DOCS):
        path = ROOT / rel
        if not path.exists():
            continue
        text = path.read_text(errors="ignore")
        for phrase in FORBIDDEN_CURRENT:
            if phrase in text:
                errors.append(f"{rel}: stale current-status phrase: {phrase}")

    if errors:
        print("documentation check failed:")
        for error in errors:
            print(f"  - {error}")
        return 1

    print(
        "documentation ok: "
        f"{len(markdown_files())} Markdown files, local links valid, "
        f"{packages} packages / {components} components / "
        f"{mbt_files} .mbt files / {mbt_lines:,} lines / {symbols:,} symbols"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
