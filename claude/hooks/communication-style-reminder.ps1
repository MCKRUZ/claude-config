# Injects Matt's communication preferences into context on every user prompt.
# Wired as a UserPromptSubmit hook in ~/.claude/settings.json.
# Hooks cannot detect "an explanation is starting", so this fires every turn —
# the reminder is cheap and keeps the rule in front of the model before it responds.

Write-Output @'
[COMMUNICATION REMINDER — always apply, Matt's standing preference]
Matt is a Managing Director and senior technologist, NOT a day-to-day coder.
Before ANY technical explanation or when presenting a choice:
- Lead with plain language: what it does and why it matters, before any code/jargon.
- Replace jargon with its meaning; if a term is needed, define it briefly in plain words.
- Answer first, reasoning second.
- For choices: give your recommendation + the one tradeoff that matters; max 2-3 options.
If you are about to explain something technical, ask a clarifying question, or present
options, follow the communication-style skill. Do not rely on memory alone.
'@
