# set_secret

Stores API keys and tokens that skills need. Secrets are saved as `NAME=value` lines in `/opt/data/secrets.env` inside the container and referenced by name (e.g. `$RESEND_API_KEY`) from a skill's `SKILL.md`. They are never written into the workspace and never echoed back in chat.

**Inputs:**
- `key` — the secret name (UPPERCASE convention)
- `value` — the secret value
