# create_skill

Defines a brand-new skill on the fly during a conversation. BabyAgent writes `skills/<id>/SKILL.md` describing an HTTP request, with the inputs it takes and any secrets it needs.

**Inputs (gathered in conversation):**
- `id` — snake_case identifier (e.g. `send_discord_message`)
- `description` — when to use this skill
- inputs — the arguments the skill takes
- the HTTP request to make, using stored secrets for credentials
