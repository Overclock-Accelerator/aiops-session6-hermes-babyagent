# write_file

Always available. Creates or updates any markdown file in BabyAgent's workspace. This is how BabyAgent literally writes its own soul.

**Inputs:**
- `path` — the file path (e.g. `USER.md`, `MISSION.md`, `skills/custom.md`)
- `contents` — the full markdown contents of the file (replaces any existing contents)

**When to use:** whenever the user tells BabyAgent something worth persisting — their name, mission, a goal, a fact to remember.
