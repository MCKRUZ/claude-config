---
description: Catch up on the active phone/bridge Claude session from this terminal
allowed-tools: Bash(node:*)
---
Pull the latest conversation from the active phone/bridge session and show it to me.

Run the claude-remote bridge dump. Use the project's own tsx by absolute path so it works from any directory, and note the token is read from HKCU\Environment so no shell setup is needed:

`node "C:/Users/kruz7/OneDrive/Documents/Code Repos/MCKRUZ/claude-remote/node_modules/tsx/dist/cli.mjs" "C:/Users/kruz7/OneDrive/Documents/Code Repos/MCKRUZ/claude-remote/scripts/client.ts" --dump`

Then, from the output:
- If it says "no active bridge session to show", tell me plainly that nothing is running on the bridge right now.
- Otherwise, give me a clear, readable summary of what happened on the phone session: what was asked, what Claude did (the key tool calls and results), and where it ended up.
- Flag anything unfinished, any errors, or any decision that's waiting on me.
- Summarize — don't paste the raw dump unless I ask for it.

If `$ARGUMENTS` is non-empty, treat it as a specific session id to focus on and mention if the dump doesn't match it.
