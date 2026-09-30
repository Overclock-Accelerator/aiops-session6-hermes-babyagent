# system/

This folder describes the **built-in tools** BabyAgent always has, regardless of which optional skills are installed. They are the foundation of how it grows.

Unlike the folders in `skills/` (which are installed, or created on the fly), these four are part of BabyAgent's core instructions and can't be removed:

- **write_file** — BabyAgent uses this to write its own markdown files (USER.md, MISSION.md, etc.) as you talk. This is how it writes its own soul.
- **set_secret** — stores API keys and tokens you share mid-conversation, in `/opt/data/secrets.env` inside the container (never in the workspace).
- **install_skill** — installs one of the bundled optional skills (`web_fetch`, `tavily_research`, `remember`) into `skills/`.
- **create_skill** — defines a brand-new skill on the fly: a `skills/<id>/SKILL.md` describing an HTTP call with placeholders for inputs and stored secrets.
