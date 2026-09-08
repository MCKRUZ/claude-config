# Common Patterns

## Privacy Tags
Wrap sensitive content in `<private>` tags to exclude from session memory logs.
The observation hook only records file paths, not contents — use `<private>` for sensitive content in prompts.

## Skeleton Projects
When implementing new functionality: search for battle-tested skeleton projects or reference implementations, evaluate the best match, and clone as a foundation rather than building from scratch.
