# Session 6 — BabyAgent on Hermes

[BabyAgent](https://github.com/Overclock-Accelerator/babyagent) rebuilt as a real [Hermes Agent](https://github.com/NousResearch/hermes-agent) running in Docker. No custom UI — you talk to it through Hermes's OpenAI-compatible API, the Hermes dashboard's Chat page, or the CLI.

A fresh instance is a blank slate. As you talk to it, it writes its own markdown files (`USER.md`, `IDENTITY.md`, `MISSION.md`, `GOALS.md`, `MEMORY.md`), installs skills, and creates new ones from a description — same as BabyAgent.

## Run it

```bash
cd session-6-babyagent
./chat.sh
```

That's the whole setup. `chat.sh`:

1. Checks Docker is running.
2. **First run only:** asks for your API keys and writes `.env` (it generates the dashboard password and API key for you).
3. Seeds `./hermes-data/` from `seed/`.
4. Pulls the Hermes image (first run takes a few minutes) and starts the containers.
5. Opens a terminal chat with BabyAgent. `/quit` leaves the chat; BabyAgent keeps running.

`./chat.sh --no-chat` starts everything without opening the chat. `docker compose down` stops it.

**Prerequisites:** Docker (Docker Desktop or equivalent), and an LLM key:

| Key | Required | Where to get it |
|---|---|---|
| Anthropic | Yes (or OpenRouter) | https://console.anthropic.com/settings/keys |
| OpenRouter | Alternative to Anthropic | https://openrouter.ai/keys |
| Tavily | Optional | https://tavily.com (free tier) — powers the `tavily_research` skill. Skip it and the agent asks the user for a key if they install that skill |

## Other ways to talk to it

Once `chat.sh` has started it, these are also available:

**OpenAI-compatible API** — point any chat UI that supports a custom OpenAI endpoint at:

| Setting | Value |
|---|---|
| Base URL | `http://127.0.0.1:8642/v1` |
| API key | `API_SERVER_KEY` from `.env` |
| Model | `babyagent` |

```bash
curl http://127.0.0.1:8642/v1/chat/completions \
  -H "Authorization: Bearer $(sed -n 's/^API_SERVER_KEY=//p' .env)" -H "Content-Type: application/json" \
  -d '{"model":"babyagent","messages":[{"role":"user","content":"hi"}]}'
```

**Dashboard Chat** — open http://127.0.0.1:9119 and sign in with `HERMES_DASHBOARD_BASIC_AUTH_USERNAME` / `_PASSWORD` from `.env`, then click **Chat**.

## Where things live

Everything lives on your machine under `./hermes-data/` (mounted into the containers as `/opt/data`). Open it in VS Code with `code .` from this folder.

**What the agent writes** (edit any of these by hand; the agent re-reads them at the start of every turn):

| File | Host path | Container path |
|---|---|---|
| About-me / context (auto-loaded every turn) | `hermes-data/workspace/AGENTS.md` | `/opt/data/workspace/AGENTS.md` |
| User | `hermes-data/workspace/USER.md` | `/opt/data/workspace/USER.md` |
| Identity | `hermes-data/workspace/IDENTITY.md` | `/opt/data/workspace/IDENTITY.md` |
| Mission | `hermes-data/workspace/MISSION.md` | `/opt/data/workspace/MISSION.md` |
| Goals | `hermes-data/workspace/GOALS.md` | `/opt/data/workspace/GOALS.md` |
| Memory | `hermes-data/workspace/MEMORY.md` | `/opt/data/workspace/MEMORY.md` |
| Skills (installed + agent-created) | `hermes-data/workspace/skills/<id>/SKILL.md` | `/opt/data/workspace/skills/<id>/SKILL.md` |
| Built-in tool docs | `hermes-data/workspace/system/` | `/opt/data/workspace/system/` |
| Secrets (`chmod 600`, never copied into the workspace) | `hermes-data/secrets.env` | `/opt/data/secrets.env` |

`USER.md`, `IDENTITY.md`, `MISSION.md`, `GOALS.md` and `MEMORY.md` don't exist until the agent writes them.

**Hermes internals** (read-only in practice):

| What | Host path |
|---|---|
| Active instructions (`SOUL.md`) — a copy, overwritten on every start; edit `seed/SOUL.md` instead | `hermes-data/SOUL.md` |
| Generated config (model, working dir, disabled tools) — overwritten on every start; edit `chat.sh` / `.env` instead | `hermes-data/config.yaml` |
| Copies of the installable skills | `hermes-data/bundled-skills/` |
| Logs — `agent.log` shows every tool call the agent makes | `hermes-data/logs/` |
| Chat sessions | `hermes-data/sessions/` |

**Repo files you edit** (`./chat.sh` re-applies them on every start):

| File | What |
|---|---|
| `seed/SOUL.md` | BabyAgent's instructions — the equivalent of BabyAgent's `prompt.ts`. **Refreshed on every `up`.** |
| `seed/bundled-skills/` | The three installable skills: `web_fetch`, `tavily_research`, `remember`. Refreshed on every `up`. |
| `seed/workspace/` | The starting workspace. Copied **only on first run** (or after a reset), so it never overwrites the agent's files. |
| `chat.sh` | Generates Hermes's `config.yaml` on every start (model, working dir, disabled tools — edit the `cat > "$D/config.yaml"` block to change them). |

`hermes-data/` doesn't exist until the first `./chat.sh`, and `./reset.sh` deletes it.

## Console session

`./chat.sh` does this for you. To open a chat with an already-running container yourself:

```bash
docker compose exec -it -u hermes gateway hermes chat
```

- `-u hermes` runs it as the container's normal user. Without it you're root, and files the agent writes into `hermes-data/` can end up root-owned on Linux hosts.
- It uses the same config, instructions and workspace as the API and dashboard, so it's the same BabyAgent.
- Inside the chat: `/help` lists commands, `/new` starts a fresh session, `/resume` resumes a named session, `/quit` (or `/exit`) leaves.

One-shot question with no interactive session:

```bash
docker compose exec -T -u hermes gateway hermes chat -q "hello" --oneshot -Q
```

A plain shell inside the container (to look around, or run other `hermes` commands such as `hermes sessions list`):

```bash
docker compose exec -it -u hermes gateway bash
```

## Reset (BabyAgent's "Restart")

Stops the containers and wipes the workspace, secrets, skills and all chat history (your `.env` is kept):

```bash
./reset.sh
./chat.sh      # fresh blank-slate agent
```

## How BabyAgent maps to Hermes

| BabyAgent | This setup |
|---|---|
| Virtual filesystem in `localStorage` | `hermes-data/workspace/` on disk |
| System prompt assembled from the files each turn | `seed/SOUL.md` + `AGENTS.md` (auto-loaded by Hermes) + the agent re-reads the other files at the start of every turn |
| `write_file` | Hermes's `write_file` tool |
| `set_secret` | Appends to `hermes-data/secrets.env` |
| `install_skill` | Copies `bundled-skills/<id>` into `workspace/skills/` |
| `create_skill` (HTTP spec + `{{input}}`/`{{secrets}}`) | Agent writes `workspace/skills/<id>/SKILL.md` — a curl/python call reading secrets from `secrets.env` |
| Bundled skills `web_fetch`, `tavily_research`, `remember` | Same three, as Hermes `SKILL.md` files |
| Browser sandbox, CORS, `/api/proxy` | Not applicable — it runs in a container, so any HTTP API works (Notion, Resend, Linear, …) with no proxy |
| Journey panel, file tree, editor UI | Not included — the 7-step journey is driven from chat by the agent |

To keep it "baby", `chat.sh` disables Hermes's other tools (web, browser, memory, cron, delegation, …) and skips its ~58 default skills. Only file, terminal and skills tools remain, so new abilities come from skills. Edit `disabled_toolsets` in `chat.sh` to change that.

## Troubleshooting

- **`curl` to port 8642 fails / "No messaging platforms enabled" in `docker compose logs gateway`** — `API_SERVER_KEY` is missing or under 16 characters. Fix it in `.env`, then run `./chat.sh` again.
- **Dashboard won't load, and `docker compose logs dashboard` says "Refusing to bind dashboard to 0.0.0.0"** — `HERMES_DASHBOARD_BASIC_AUTH_USERNAME` / `_PASSWORD` are missing from `.env`.
- **The agent says "Wrote X" but the file isn't there** — the model isn't reliable enough at tool use. Sonnet 4.5 did this in testing; the default `claude-sonnet-4-6` (and `claude-opus-4-6`) worked correctly. Set `HERMES_MODEL` in `.env`, then run `./chat.sh` again.
- **A UI's "new chat" resumes the old conversation** — Hermes derives the API session from the first message of a chat, so starting a new chat with the same opening message resumes the stored session. Use `./reset.sh` for a true blank slate.
- **Changed `.env` and nothing happened** — containers read `.env` only when they're created: `docker compose up -d --force-recreate` (or `docker compose down`, then `./chat.sh`).
- **`tavily_research` says no key** — add `TAVILY_API_KEY=...` to `.env` and recreate the containers (see above), or have the user give the agent a key in chat (it stores it via `set_secret`).
- **Anything else** — `docker compose logs gateway --tail 50` and `hermes-data/logs/agent.log`. Hermes ships fast; if a command or setting has moved, `docker compose exec gateway hermes --help` shows the current CLI.
