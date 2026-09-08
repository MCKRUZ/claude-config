#!/usr/bin/env python3
"""PostToolUse wrapper around semgrep's post-tool-cli-scan hook.

The semgrep plugin's hook blocks an edit on ANY finding, including WARNING/INFO
severity. That makes localhost-HTTP false positives (and other low-severity
advisories) block legitimate edits. This wrapper runs the exact same scan, then:

  - ERROR-severity findings        -> preserve the block unchanged.
  - WARNING/INFO-only findings     -> surface as non-blocking advisory context.
  - unparseable block payload      -> preserve the block (fail safe).
  - scanner crash / timeout / not  -> allow the edit (fail open), so broken
    on PATH                           tooling never wedges every edit.

The block contract is defined by semgrep/mcp/hooks/post_tool.py: it prints
{"decision":"block","reason":"<repr of findings list>"} to stdout and exits 0.
Claude Code blocks on decision==block, not on the exit code.
"""
import ast
import json
import os
import shutil
import subprocess
import sys

SCAN_TIMEOUT_SEC = 50


def _allow() -> None:
    """Emit nothing and exit 0 -> the edit proceeds with no annotation."""
    sys.exit(0)


def main() -> None:
    # Honor the CLAUDE_DISABLED_HOOKS kill-switch (same convention as the
    # other hooks, e.g. auto-format.sh). Lets a workspace disable this scan
    # without weakening security globally.
    disabled = os.environ.get("CLAUDE_DISABLED_HOOKS", "")
    if "semgrep" in [h.strip() for h in disabled.split(",")]:
        _allow()

    raw = sys.stdin.read()

    if shutil.which("semgrep") is None:
        _allow()  # scanner not installed/on PATH -> don't block edits

    try:
        proc = subprocess.run(
            ["semgrep", "mcp", "-k", "post-tool-cli-scan"],
            input=raw,
            capture_output=True,
            text=True,
            timeout=SCAN_TIMEOUT_SEC,
        )
    except Exception:
        _allow()  # scanner failed to run / timed out -> fail open

    # Exit 2 is semgrep's "not logged in" / unsupported-agent path: preserve it
    # verbatim so the actionable message reaches the user.
    if proc.returncode == 2:
        if proc.stderr:
            sys.stderr.write(proc.stderr)
        sys.exit(2)

    out = (proc.stdout or "").strip()
    if not out:
        _allow()  # no decision payload (e.g. crashed before output) -> fail open

    try:
        payload = json.loads(out)
    except Exception:
        _allow()  # unparseable stdout (tracebacks etc.) -> fail open

    if payload.get("decision") != "block":
        # No findings, or already non-blocking: pass through verbatim.
        sys.stdout.write(out)
        sys.exit(0)

    # decision == block. Determine severities from the repr-encoded reason list.
    reason = payload.get("reason")
    findings = None
    if isinstance(reason, str):
        try:
            parsed = ast.literal_eval(reason)
            if isinstance(parsed, list):
                findings = parsed
        except Exception:
            findings = None

    if findings is None:
        # Could not determine severities -> preserve the block (fail safe).
        sys.stdout.write(out)
        sys.exit(0)

    severities = {
        str(f.get("severity", "")).upper() for f in findings if isinstance(f, dict)
    }

    if "ERROR" in severities:
        # Real high-confidence finding -> keep the block unchanged.
        sys.stdout.write(out)
        sys.exit(0)

    # WARNING/INFO only -> advisory, non-blocking.
    advisory = {
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": (
                "Semgrep flagged WARNING/INFO-level findings (advisory, "
                "non-blocking). Review if relevant; the edit was allowed:\n"
                + str(reason)
            ),
        }
    }
    print(json.dumps(advisory))
    sys.exit(0)


if __name__ == "__main__":
    main()
