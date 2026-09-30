---
name: remember
description: Append a single fact to MEMORY.md. Use whenever the user shares something worth remembering across conversations — a preference, a name, a context cue.
---
# remember

Appends a fact to `MEMORY.md` in the workspace.

**Inputs:** `fact` (string, required) — a short statement, one sentence.

**Run:**

```
cd /opt/data/workspace
[ -f MEMORY.md ] || printf '# Memory\n\n' > MEMORY.md
printf -- '- (%s) %s\n' "$(date +%F)" "<fact>" >> MEMORY.md
```

**Returns:** confirm with `Remembered: <fact>`.
