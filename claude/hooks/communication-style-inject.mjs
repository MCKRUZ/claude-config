import { readFileSync } from "node:fs";

const SOURCE = "C:/Users/kruz7/.claude/skills/communication-style/INJECT.md";

let text;
try {
  text = readFileSync(SOURCE, "utf8").trim();
} catch {
  process.exit(0);
}

if (!text) process.exit(0);

process.stdout.write(
  JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: text,
    },
  }),
);
