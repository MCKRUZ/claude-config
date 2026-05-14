"""
Ollama Subagent Delegation Hook for Claude Code.

Intercepts Agent tool calls and routes them to a local/cloud Ollama model,
passing the result back via additionalContext while replacing the native
prompt with a no-op to minimize token cost.

Environment variables (set in settings.json "env"):
  OLLAMA_SUBAGENT_MODEL    - Ollama model to use. If unset, passthrough to Claude.
  OLLAMA_SUBAGENT_FLAGS    - Extra flags for the Ollama Claude instance.
  OLLAMA_SUBAGENT_TIMEOUT  - Seconds before treating call as failed (default: 180).
  OLLAMA_DELEGATE_TYPES    - Comma-separated subagent types to delegate.
                             If empty, ALL Agent calls go to Ollama.
                             Example: "general-purpose,Explore"

Based on: https://pub.towardsai.net/cutting-claude-code-costs-without-sacrificing-quality-6f0cd3bcc97d
"""

import json
import os
import subprocess
import sys


def passthrough() -> None:
    """Exit without output - Claude handles the tool call natively."""
    sys.exit(0)


def deny(reason: str) -> None:
    """Block the tool call and surface a reason to Claude."""
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def main() -> None:
    data = json.load(sys.stdin)
    tool_input = data.get("tool_input", {})
    subagent_type = tool_input.get("subagent_type") or "general-purpose"

    # Filter by delegate types if configured
    delegate_types_raw = os.environ.get("OLLAMA_DELEGATE_TYPES", "")
    if delegate_types_raw:
        allowed = {t.strip() for t in delegate_types_raw.split(",")}
        if subagent_type not in allowed:
            passthrough()

    # Model is required; fall back to Claude if not set
    model = os.environ.get("OLLAMA_SUBAGENT_MODEL", "")
    if not model:
        passthrough()

    flags = os.environ.get("OLLAMA_SUBAGENT_FLAGS", "")
    timeout = int(os.environ.get("OLLAMA_SUBAGENT_TIMEOUT", "180"))
    prompt = tool_input.get("prompt", "")

    # Use --settings to override ANTHROPIC_* env vars so the subprocess
    # connects to the local Ollama server instead of inheriting the
    # Langfuse proxy (bablyon:4040) from the parent's settings.json.
    ollama_settings = json.dumps({
        "env": {
            "ANTHROPIC_BASE_URL": "http://localhost:11434",
            "ANTHROPIC_AUTH_TOKEN": "ollama",
            "ANTHROPIC_API_KEY": "",
        }
    })

    cmd = [
        "claude",
        "--settings", ollama_settings,
        "--model", model,
        "-p", prompt,
    ]
    if flags:
        cmd.extend(flags.split())

    # Clear CLAUDECODE to prevent inheriting parent session state
    sub_env = {**os.environ, "CLAUDECODE": ""}

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            env=sub_env,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        deny(f"Ollama subagent timed out after {timeout}s.")
        return

    ollama_output = result.stdout + result.stderr
    updated_input = {**tool_input, "prompt": "Just say: TASK_DELEGATED_TO_LOCAL_MODEL"}

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "updatedInput": updated_input,
            "additionalContext": f"Local Ollama agent result:\n{ollama_output}",
        }
    }))


if __name__ == "__main__":
    main()

