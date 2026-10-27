#!/usr/bin/env python3
"""Static coverage check for catmath's hand-maintained theorem indexes.

This is a governance check, not a semantic verifier: it checks file/module
coverage and that derived-index source labels remain linked to a canonical
entry or an explicitly approved alias.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATMATH = ROOT / "catmath"
INDEX_FILE = CATMATH / "canonical.mbt"

# These production files have infrastructure roles rather than topic entries:
# canonical.mbt owns the indexes, and interop_constructors.mbt contains public
# boundary constructors rather than additional canonical-form topics.
EXEMPT_FILES = {"canonical", "interop_constructors"}
# Short labels that intentionally point to a concept rather than an exact
# canonical_index().name value. Keep this list small and reviewed.
DERIVED_SOURCE_ALIASES = {"RREF", "元素範疇", "規範標號"}


def main() -> int:
    text = INDEX_FILE.read_text(encoding="utf-8")
    canonical_start = text.index("pub fn canonical_index()")
    derived_start = text.index("pub fn derived_index()", canonical_start)
    canonical_text = text[canonical_start:derived_start]
    derived_end = text.find("pub fn verify_all_derived()", derived_start)
    if derived_end < 0:
        print("catmath index check: cannot find verify_all_derived() boundary", file=sys.stderr)
        return 1
    derived_text = text[derived_start:derived_end]

    modules = set(re.findall(r'mod_name\s*:\s*"([^"]+)"', canonical_text))
    canonical_names = set(re.findall(r'name\s*:\s*"([^"]+)"', canonical_text))
    derived_sources = set(re.findall(r'source\s*:\s*"([^"]+)"', derived_text))
    derived_names = re.findall(r'name\s*:\s*"([^"]+)"', derived_text)

    production_files = {
        path.stem
        for path in CATMATH.glob("*.mbt")
        if not path.name.endswith(("_test.mbt", "_wbtest.mbt"))
    }
    expected_modules = production_files - EXEMPT_FILES
    missing_modules = sorted(expected_modules - modules)
    stale_modules = sorted(modules - production_files)
    if missing_modules or stale_modules:
        if missing_modules:
            print(f"catmath canonical index misses production files: {missing_modules}", file=sys.stderr)
        if stale_modules:
            print(f"catmath canonical index has stale module labels: {stale_modules}", file=sys.stderr)
        return 1

    dangling_sources = sorted(derived_sources - canonical_names - DERIVED_SOURCE_ALIASES)
    if dangling_sources:
        print(f"catmath derived index has unlinked source labels: {dangling_sources}", file=sys.stderr)
        return 1
    if len(derived_names) != len(set(derived_names)):
        print("catmath derived index has duplicate theorem names", file=sys.stderr)
        return 1

    print(
        "catmath index coverage ok: "
        f"{len(modules)} topic modules / {len(canonical_names)} canonical entries / "
        f"{len(derived_names)} derived entries"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
