#!/usr/bin/env python3
"""Detached semgrep worker. Spawned (and not waited on) by semgrep-async-scan.py.

Scans a single edited file against the locally-cloned semgrep-rules security
rulesets, fully offline, then writes the findings to the shared results dir as an
atomic JSON drop that the next PostToolUse hook reads and surfaces.

Invocation:  py semgrep-bg-runner.py <file_path> <comma,sep,langs>

It owns a `<id>.running` lock for its lifetime and emits `<id>.json` on success.
All output is best-effort: any failure leaves no drop and is silent (this runs
detached, so there is nobody to report to).
"""
import glob
import hashlib
import json
import os
import subprocess
import sys
import time

RESULTS_DIR = os.path.join(
    os.path.expanduser("~"), ".claude", ".cache", "semgrep-findings"
)
RULES_ROOT = os.path.join(os.path.expanduser("~"), ".claude", "hooks", "semgrep-rules")
SCAN_WALL_TIMEOUT = 120  # detached; generous, but tree-killed on overrun


def _config_dirs(langs):
    """Map language names to local rule dirs, preferring each lang's security packs."""
    dirs = []
    for lang in langs:
        lang_root = os.path.join(RULES_ROOT, lang)
        if not os.path.isdir(lang_root):
            continue
        sec = [
            d
            for d in glob.glob(
                os.path.join(lang_root, "**", "security"), recursive=True
            )
            if os.path.isdir(d)
        ]
        dirs.extend(sec if sec else [lang_root])
    return dirs


def _tree_kill(proc):
    """Windows: terminate the whole semgrep process tree (semgrep spawns children)."""
    try:
        if os.name == "nt":
            subprocess.run(
                ["taskkill", "/F", "/T", "/PID", str(proc.pid)],
                capture_output=True,
                timeout=10,
            )
        else:
            proc.kill()
    except Exception:
        pass


def main():
    if len(sys.argv) < 3:
        return
    file_path, langs_csv = sys.argv[1], sys.argv[2]
    langs = [l.strip() for l in langs_csv.split(",") if l.strip()]
    if not langs or not os.path.isfile(file_path):
        return

    config_dirs = _config_dirs(langs)
    if not config_dirs:
        return

    os.makedirs(RESULTS_DIR, exist_ok=True)
    scan_id = f"{os.getpid()}-{hashlib.sha1(file_path.encode()).hexdigest()[:8]}"
    running = os.path.join(RESULTS_DIR, scan_id + ".running")
    out_tmp = os.path.join(RESULTS_DIR, scan_id + ".json.partial")
    out_final = os.path.join(RESULTS_DIR, scan_id + ".json")

    try:
        with open(running, "w") as f:
            f.write(str(time.time()))
    except Exception:
        return

    try:
        cmd = [
            "semgrep",
            "scan",
            "--metrics=off",
            "--disable-version-check",
            "--no-git-ignore",
            "--quiet",
            "--jobs",
            "2",
            "--json",
            "-o",
            out_tmp,
        ]
        for d in config_dirs:
            cmd += ["--config", d]
        cmd.append(file_path)

        env = dict(os.environ)
        env["SEMGREP_SEND_METRICS"] = "off"
        env["SEMGREP_ENABLE_VERSION_CHECK"] = "0"

        flags = 0x08000000 if os.name == "nt" else 0  # CREATE_NO_WINDOW
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL,
            env=env,
            creationflags=flags,
        )
        try:
            proc.wait(timeout=SCAN_WALL_TIMEOUT)
        except subprocess.TimeoutExpired:
            _tree_kill(proc)
            return

        if not os.path.isfile(out_tmp):
            return
        with open(out_tmp, "r", encoding="utf-8") as f:
            raw = json.load(f)

        findings = []
        for r in raw.get("results", []):
            findings.append(
                {
                    "file": r.get("path", file_path),
                    "line": (r.get("start") or {}).get("line"),
                    "check_id": r.get("check_id", ""),
                    "severity": str((r.get("extra") or {}).get("severity", "")).upper(),
                    "message": ((r.get("extra") or {}).get("message", "") or "")
                    .strip()
                    .split("\n")[0],
                }
            )

        drop = {"file": file_path, "ts": time.time(), "findings": findings}
        with open(out_final + ".writing", "w", encoding="utf-8") as f:
            json.dump(drop, f)
        os.replace(out_final + ".writing", out_final)  # atomic publish
    except Exception:
        return
    finally:
        for p in (running, out_tmp):
            try:
                os.remove(p)
            except OSError:
                pass


if __name__ == "__main__":
    main()
