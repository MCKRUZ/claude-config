#!/usr/bin/env python3
"""PostToolUse hook: non-blocking semgrep security scanning.

semgrep has a fixed ~5-7s startup cost per run on this machine, so scanning
inline would stall every edit by that much. Instead this hook:

  1. READS any findings that previously-spawned background scans have published
     to the results dir, surfaces them to Claude as advisory context, and clears
     them. ERROR-severity findings are flagged for attention.
  2. LAUNCHES a detached background scan of the just-edited file (semgrep-bg-
     runner.py) and returns immediately (<200ms), so the edit never waits.

Net effect: full local-ruleset security coverage with zero per-edit stall;
findings surface on the next tool call. Honors the CLAUDE_DISABLED_HOOKS
kill-switch (add "semgrep") and fails open on any error.
"""
import glob
import json
import os
import subprocess
import sys
import time

RESULTS_DIR = os.path.join(
    os.path.expanduser("~"), ".claude", ".cache", "semgrep-findings"
)
RUNNER = os.path.join(
    os.path.expanduser("~"), ".claude", "hooks", "semgrep-bg-runner.py"
)
MAX_CONCURRENT = 3  # cap simultaneous background scans (CPU guard)
RUNNING_STALE_SEC = 300  # a scan should finish well within this
DROP_STALE_SEC = 3600  # unconsumed findings older than this are dropped
MAX_SURFACED = 20  # cap findings shown in one batch

# file extension -> ordered list of semgrep-rules language dirs to scan against
EXT_LANGS = {
    ".py": ["python"],
    ".pyi": ["python"],
    ".js": ["javascript", "typescript"],
    ".jsx": ["javascript", "typescript"],
    ".mjs": ["javascript"],
    ".cjs": ["javascript"],
    ".ts": ["typescript", "javascript"],
    ".tsx": ["typescript", "javascript"],
    ".cs": ["csharp"],
    ".go": ["go"],
    ".java": ["java"],
    ".rb": ["ruby"],
    ".php": ["php"],
    ".rs": ["rust"],
    ".kt": ["kotlin"],
    ".kts": ["kotlin"],
    ".swift": ["swift"],
    ".scala": ["scala"],
    ".sc": ["scala"],
    ".ex": ["elixir"],
    ".exs": ["elixir"],
    ".c": ["c"],
    ".h": ["c"],
    ".clj": ["clojure"],
    ".cljs": ["clojure"],
    ".cljc": ["clojure"],
    ".tf": ["terraform"],
    ".sh": ["bash"],
    ".bash": ["bash"],
}


def _disabled():
    raw = os.environ.get("CLAUDE_DISABLED_HOOKS", "")
    return "semgrep" in [h.strip() for h in raw.split(",")]


def _langs_for(file_path):
    base = os.path.basename(file_path)
    if base == "Dockerfile" or base.startswith("Dockerfile."):
        return ["dockerfile"]
    return EXT_LANGS.get(os.path.splitext(file_path)[1].lower())


def _cleanup(now):
    for p in glob.glob(os.path.join(RESULTS_DIR, "*.running")):
        try:
            if now - os.path.getmtime(p) > RUNNING_STALE_SEC:
                os.remove(p)
        except OSError:
            pass
    for pat in ("*.json.partial", "*.json.writing"):
        for p in glob.glob(os.path.join(RESULTS_DIR, pat)):
            try:
                if now - os.path.getmtime(p) > RUNNING_STALE_SEC:
                    os.remove(p)
            except OSError:
                pass


def _consume_findings(now):
    """Read + delete all published finding drops; return deduped findings list."""
    seen, findings = set(), []
    for p in sorted(glob.glob(os.path.join(RESULTS_DIR, "*.json"))):
        try:
            if now - os.path.getmtime(p) > DROP_STALE_SEC:
                os.remove(p)
                continue
            with open(p, "r", encoding="utf-8") as f:
                drop = json.load(f)
        except Exception:
            try:
                os.remove(p)
            except OSError:
                pass
            continue
        for fnd in drop.get("findings", []):
            key = (fnd.get("file"), fnd.get("line"), fnd.get("check_id"))
            if key in seen:
                continue
            seen.add(key)
            findings.append(fnd)
        try:
            os.remove(p)
        except OSError:
            pass
    return findings


def _format(findings):
    errors = [f for f in findings if f.get("severity") == "ERROR"]
    others = [f for f in findings if f.get("severity") != "ERROR"]
    ordered = (errors + others)[:MAX_SURFACED]
    head = (
        f"Semgrep background scan: {len(errors)} ERROR + {len(others)} "
        f"WARNING/INFO security finding(s) (advisory, non-blocking). "
        f"Review and fix the ERROR-level items:"
    )
    lines = []
    for f in ordered:
        cid = (f.get("check_id") or "").split(".")[-1]
        loc = os.path.basename(f.get("file") or "?")
        line = f.get("line")
        lines.append(
            f"  [{f.get('severity','?')}] {loc}:{line} {cid} — {f.get('message','')}"
        )
    extra = len(findings) - len(ordered)
    if extra > 0:
        lines.append(f"  ...and {extra} more.")
    return head + "\n" + "\n".join(lines)


def _launch(file_path, langs):
    try:
        running = glob.glob(os.path.join(RESULTS_DIR, "*.running"))
        if len(running) >= MAX_CONCURRENT:
            return  # too many in flight; drop this scan to protect CPU
        flags = 0
        if os.name == "nt":
            flags = 0x00000008 | 0x00000200 | 0x08000000  # DETACHED|NEW_GROUP|NO_WINDOW
        subprocess.Popen(
            [sys.executable, RUNNER, file_path, ",".join(langs)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL,
            creationflags=flags,
            close_fds=True,
        )
    except Exception:
        pass


def main():
    if _disabled():
        return
    try:
        data = json.loads(sys.stdin.read() or "{}")
    except Exception:
        return

    os.makedirs(RESULTS_DIR, exist_ok=True)
    now = time.time()
    _cleanup(now)

    findings = _consume_findings(now)

    file_path = (data.get("tool_input") or {}).get("file_path")
    if file_path:
        langs = _langs_for(file_path)
        if langs:
            _launch(file_path, langs)

    if findings:
        print(
            json.dumps(
                {
                    "hookSpecificOutput": {
                        "hookEventName": "PostToolUse",
                        "additionalContext": _format(findings),
                    }
                }
            )
        )


if __name__ == "__main__":
    main()
