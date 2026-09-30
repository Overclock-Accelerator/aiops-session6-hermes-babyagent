# install_skill

Installs a bundled optional skill from chat. The skill is usable immediately.

**Inputs:**
- `id` — the id of a bundled skill: `web_fetch`, `tavily_research`, or `remember`

**When to use:** when the user asks for a capability an existing bundled skill provides — e.g. "let me know what's on Hacker News right now" → install `web_fetch` first if it isn't installed yet.
