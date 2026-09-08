#!/usr/bin/env python3
"""Assemble per-package analysis files into one findings.json for the report renderer.

When the skill analyzes several packages (often via parallel subagents), each
produces one packages[]-shaped JSON object. This merges them, optionally applies
a build-verify overlay (the trial-build results that upgrade changelog/inference
findings to compiler-verified ground truth), sorts for readability, and writes
the combined findings.json that render_report.py consumes.

Usage:
    python assemble_findings.py <pkgs_dir> -o findings.json \
        --project NAME --generated YYYY-MM-DD --summary "..." \
        [--overlay overlay.json] [--build-verified-all]

Overlay schema (keyed by each package's "name" field):
    {
      "MediatR": {
        "build_verified": true,
        "verdict": "override verdict string",
        "add_breaking_changes": [ { ...packages[].breaking_changes[] item... } ],
        "add_behavioral_notes": [ { ... } ]
      }
    }
Stdlib only — runs anywhere Python 3 is present.
"""
import argparse
import json
import sys
from pathlib import Path

JUMP_RANK = {"major": 0, "minor": 1, "patch": 2}


def normalize(obj):
    """Yield package objects from one loaded file, tolerating common wrappers.

    Subagents are asked for a bare package object, but in practice some wrap it
    as {"packages": [...]}, {"package": {...}}, or {"<anything>": {package}}.
    Normalizing here keeps the report correct instead of rendering blank rows for
    every package that didn't follow the schema to the letter.
    """
    if isinstance(obj, list):
        for item in obj:
            yield from normalize(item)
        return
    if not isinstance(obj, dict):
        return
    if "name" in obj:  # already a package object
        yield obj
        return
    if isinstance(obj.get("packages"), list):  # {"packages": [...]}
        for item in obj["packages"]:
            yield from normalize(item)
        return
    if isinstance(obj.get("package"), dict):  # {"package": {...}}
        yield from normalize(obj["package"])
        return
    # Single-key wrapper around a package, e.g. {"mediatr": {...}}
    if len(obj) == 1:
        only = next(iter(obj.values()))
        if isinstance(only, (dict, list)):
            yield from normalize(only)
            return
    print(f"warning: unrecognized object shape, skipping (keys={list(obj)[:4]})", file=sys.stderr)


def load_packages(pkgs_dir):
    pkgs = []
    for p in sorted(Path(pkgs_dir).glob("*.json")):
        try:
            obj = json.loads(p.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            print(f"skip {p.name}: {e}", file=sys.stderr)
            continue
        found = list(normalize(obj))
        if not found:
            print(f"warning: {p.name} yielded no package object", file=sys.stderr)
        pkgs.extend(found)
    return pkgs


def apply_overlay(pkg, overlay, build_verified_all, build_verified_ecosystems):
    if build_verified_all or pkg.get("ecosystem") in build_verified_ecosystems:
        pkg["build_verified"] = True
    entry = overlay.get(pkg.get("name"))
    if not entry:
        return pkg
    if "build_verified" in entry:
        pkg["build_verified"] = entry["build_verified"]
    if "verdict" in entry:
        pkg["verdict"] = entry["verdict"]
    if entry.get("add_breaking_changes"):
        pkg.setdefault("breaking_changes", [])
        pkg["breaking_changes"] = entry["add_breaking_changes"] + pkg["breaking_changes"]
    if entry.get("add_behavioral_notes"):
        pkg.setdefault("behavioral_notes", [])
        pkg["behavioral_notes"] = entry["add_behavioral_notes"] + pkg["behavioral_notes"]
    return pkg


def sort_key(pkg):
    # Packages with breaking changes first; then majors before minors before
    # patches; then by name. Puts the things that need attention at the top.
    n_break = len(pkg.get("breaking_changes") or [])
    return (0 if n_break else 1, JUMP_RANK.get(pkg.get("jump"), 9), pkg.get("name", ""))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pkgs_dir")
    ap.add_argument("-o", "--out", default="findings.json")
    ap.add_argument("--project", default="")
    ap.add_argument("--generated", default="")
    ap.add_argument("--summary", default="")
    ap.add_argument("--overlay")
    ap.add_argument("--build-verified-all", action="store_true")
    ap.add_argument("--build-verified-ecosystem", default="",
                    help="comma-separated ecosystems whose packages were trial-built (e.g. 'nuget')")
    args = ap.parse_args()
    bv_ecosystems = {e.strip() for e in args.build_verified_ecosystem.split(",") if e.strip()}

    overlay = {}
    if args.overlay:
        overlay = json.loads(Path(args.overlay).read_text(encoding="utf-8"))

    pkgs = load_packages(args.pkgs_dir)
    pkgs = [apply_overlay(p, overlay, args.build_verified_all, bv_ecosystems) for p in pkgs]
    pkgs.sort(key=sort_key)

    findings = {
        "project": args.project,
        "generated": args.generated,
        "summary": args.summary,
        "packages": pkgs,
    }
    Path(args.out).write_text(json.dumps(findings, indent=2), encoding="utf-8")
    n_break = sum(1 for p in pkgs if p.get("breaking_changes"))
    print(f"wrote {args.out}: {len(pkgs)} packages, {n_break} with breaking changes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
