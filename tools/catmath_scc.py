#!/usr/bin/env python3
"""Approximate production-source dependency graph and SCCs for catmath.

This is a review aid, not a MoonBit parser or compiler dependency graph.
It intentionally excludes tests and uses only unambiguous top-level names:
module-level function calls plus type/enum/constructor references. Receiver
method dispatch, macros, local shadowing and ambiguous duplicate names can
hide or add edges. Always compile after interpreting the output.
"""
from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PKG = ROOT / "catmath"
SKIP_SUFFIXES = ("_test.mbt", "_wbtest.mbt")


def mask_comments_strings(text: str) -> str:
    """Preserve newlines/offsets while masking comments and string bodies."""
    out = list(text)
    i = 0
    state = "code"
    while i < len(text):
        if state == "code":
            if text.startswith("//", i):
                state = "line"
                out[i] = out[i + 1] = " "
                i += 2
                continue
            if text.startswith("/*", i):
                state = "block"
                out[i] = out[i + 1] = " "
                i += 2
                continue
            if text[i] == '"':
                state = "string"
                out[i] = " "
                i += 1
                continue
        elif state == "line":
            if text[i] == "\n":
                state = "code"
            else:
                out[i] = " "
        elif state == "block":
            if text.startswith("*/", i):
                out[i] = out[i + 1] = " "
                state = "code"
                i += 2
                continue
            if text[i] != "\n":
                out[i] = " "
        elif state == "string":
            if text[i] == "\\":
                out[i] = " "
                if i + 1 < len(text) and text[i + 1] != "\n":
                    out[i + 1] = " "
                i += 2
                continue
            if text[i] == '"':
                state = "code"
            else:
                out[i] = " "
        i += 1
    return "".join(out)


def production_files() -> list[Path]:
    return sorted(
        p for p in PKG.glob("*.mbt")
        if not p.name.endswith(SKIP_SUFFIXES)
    )


def decls(source: str) -> dict[str, set[str]]:
    """Return dependency-relevant simple symbol names declared in a file."""
    names: dict[str, set[str]] = defaultdict(set)
    for kind, name in re.findall(
        r"(?m)^(?:pub(?:\((?:all|open)\))?\s+|priv\s+)?"
        r"(fn|struct|enum|type|trait|let)\s+"
        r"([A-Za-z_][A-Za-z0-9_]*)",
        source,
    ):
        names[name].add(kind)

    # Enum constructors are top-level references too.
    for match in re.finditer(
        r"(?m)^(?:pub(?:\((?:all|open)\))?\s+|priv\s+)?enum\s+"
        r"[A-Z][A-Za-z0-9_]*[^\n]*\n(.*?)(?=^\}|\Z)",
        source,
        re.S,
    ):
        for ctor in re.findall(r"(?m)^\s{2}([A-Z][A-Za-z0-9_]*)\b", match.group(1)):
            names[ctor].add("constructor")
    return names


def build_graph():
    files = production_files()
    sources = {p: mask_comments_strings(p.read_text(errors="replace")) for p in files}
    declarations: dict[str, set[Path]] = defaultdict(set)
    kinds: dict[str, set[str]] = defaultdict(set)
    for path, source in sources.items():
        for name, declared_kinds in decls(source).items():
            declarations[name].add(path)
            kinds[name].update(declared_kinds)

    unique_owner = {
        name: next(iter(owners))
        for name, owners in declarations.items()
        if len(owners) == 1
    }
    ambiguous = {name: owners for name, owners in declarations.items() if len(owners) > 1}
    graph: dict[Path, set[Path]] = {p: set() for p in files}
    witnesses: dict[tuple[Path, Path], set[str]] = defaultdict(set)
    unresolved_ambiguous: dict[Path, set[str]] = defaultdict(set)

    for path, source in sources.items():
        seen: set[str] = set()
        # Function calls resolve across files only when a module-level name is unique.
        seen.update(re.findall(r"\b([a-z_][A-Za-z0-9_]*)\s*(?:\[[^\]]*\])?\s*\(", source))
        # Type names, enum names and constructors resolve by uppercase identifiers.
        seen.update(re.findall(r"\b[A-Z][A-Za-z0-9_]*\b", source))
        # Top-level types can be used in struct literal/type-application syntax without calls.
        for name in seen:
            owner = unique_owner.get(name)
            if owner is not None and owner != path:
                graph[path].add(owner)
                witnesses[(path, owner)].add(name)
            elif name in ambiguous and path not in ambiguous[name]:
                unresolved_ambiguous[path].add(name)

    return files, graph, witnesses, ambiguous, unresolved_ambiguous


def tarjan(graph: dict[Path, set[Path]]) -> list[list[Path]]:
    index = 0
    indices: dict[Path, int] = {}
    low: dict[Path, int] = {}
    stack: list[Path] = []
    on_stack: set[Path] = set()
    result: list[list[Path]] = []

    def visit(node: Path) -> None:
        nonlocal index
        indices[node] = low[node] = index
        index += 1
        stack.append(node)
        on_stack.add(node)
        for target in sorted(graph[node]):
            if target not in indices:
                visit(target)
                low[node] = min(low[node], low[target])
            elif target in on_stack:
                low[node] = min(low[node], indices[target])
        if low[node] == indices[node]:
            component = []
            while True:
                member = stack.pop()
                on_stack.remove(member)
                component.append(member)
                if member == node:
                    break
            result.append(sorted(component))

    for node in sorted(graph):
        if node not in indices:
            visit(node)
    return sorted(result, key=lambda c: (-len(c), [p.name for p in c]))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true", help="emit machine-readable graph")
    parser.add_argument("--list-edges", action="store_true", help="show source and witness names")
    args = parser.parse_args()
    files, graph, witnesses, ambiguous, unresolved = build_graph()
    components = tarjan(graph)
    cyclic = [c for c in components if len(c) > 1 or (len(c) == 1 and c[0] in graph[c[0]])]
    edges = [
        {
            "from": a.relative_to(ROOT).as_posix(),
            "to": b.relative_to(ROOT).as_posix(),
            "witnesses": sorted(witnesses[(a, b)]),
        }
        for a in sorted(graph)
        for b in sorted(graph[a])
    ]
    data = {
        "scope": "catmath production .mbt only; tests excluded",
        "approximation": "unique top-level function calls and uppercase type/constructor references; not compiler graph",
        "files": [p.relative_to(ROOT).as_posix() for p in files],
        "file_count": len(files),
        "edge_count": len(edges),
        "ambiguous_symbol_count": len(ambiguous),
        "unresolved_ambiguous_reference_count": sum(map(len, unresolved.values())),
        "edges": edges,
        "sccs": [[p.relative_to(ROOT).as_posix() for p in c] for c in components],
        "cyclic_sccs": [[p.relative_to(ROOT).as_posix() for p in c] for c in cyclic],
    }
    if args.json:
        print(json.dumps(data, indent=2, ensure_ascii=False))
        return 0
    print(f"catmath production source graph: {len(files)} files, {len(edges)} directed file edges")
    print(f"ambiguous declaration names: {len(ambiguous)}; unresolved ambiguous references: {data['unresolved_ambiguous_reference_count']}")
    print(f"strongly connected components: {len(components)} total, {len(cyclic)} cyclic")
    for i, component in enumerate(components, 1):
        marker = "CYCLE" if len(component) > 1 or component[0] in graph[component[0]] else "acyclic"
        print(f"  SCC {i} [{marker}; {len(component)} file(s)]: " + ", ".join(p.name for p in component))
    if args.list_edges:
        for edge in edges:
            print(f"  {edge['from']} -> {edge['to']} via {', '.join(edge['witnesses'])}")
    print("NOTE: heuristic source graph only; method dispatch/ambiguous names can hide edges. Inspect witnesses and compile before package splits.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
