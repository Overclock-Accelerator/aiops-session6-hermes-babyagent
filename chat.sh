#!/bin/sh
# Start BabyAgent (pulls the Hermes image if needed) and open a chat with it.
#   ./chat.sh              start everything, then chat in this terminal
#   ./chat.sh --no-chat    start everything and stop there
set -eu
cd "$(dirname "$0")"

command -v docker >/dev/null 2>&1 || { echo "Docker isn't installed. Install Docker Desktop first."; exit 1; }
docker info >/dev/null 2>&1 || { echo "Docker isn't running. Start Docker Desktop, then run this again."; exit 1; }

# --- 1. .env (first run only): ask for a key, generate the rest ---------------
ask_secret() {  # $1 = prompt; result in $REPLY_VALUE
  printf '%s' "$1"
  stty -echo 2>/dev/null || true; read -r REPLY_VALUE || true; stty echo 2>/dev/null || true; echo
}
if [ ! -f .env ]; then
  echo "First run — let's set up your keys."
  ask_secret 'Anthropic API key (https://console.anthropic.com/settings/keys) — Enter to use OpenRouter instead: '
  ANTHROPIC=$REPLY_VALUE; OPENROUTER=""
  if [ -z "$ANTHROPIC" ]; then
    ask_secret 'OpenRouter API key (https://openrouter.ai/keys): '
    OPENROUTER=$REPLY_VALUE
    [ -n "$OPENROUTER" ] || { echo "A key is required."; exit 1; }
  fi
  printf 'Tavily API key (https://tavily.com, optional) — Enter to skip: '
  read -r TAVILY || true
  {
    if [ -n "$ANTHROPIC" ]; then
      echo "ANTHROPIC_API_KEY=$ANTHROPIC"
    else
      echo "OPENROUTER_API_KEY=$OPENROUTER"
      echo "HERMES_PROVIDER=openrouter"
      echo "HERMES_MODEL=anthropic/claude-sonnet-4.6"
    fi
    echo "TAVILY_API_KEY=$TAVILY"
    echo "HERMES_DASHBOARD_BASIC_AUTH_USERNAME=instructor"
    echo "HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=$(openssl rand -hex 8)"
    echo "API_SERVER_KEY=$(openssl rand -hex 24)"
  } > .env
  chmod 600 .env
  echo "Saved .env (the dashboard login and API key were generated for you)."
fi

env_get() { sed -n "s/^$1=//p" .env | tail -1; }

# --- 2. Seed ./hermes-data (safe to repeat; never overwrites the agent's files) -
D=./hermes-data
[ -d "$D" ] && FRESH=0 || FRESH=1   # data folder missing => any running containers hold a stale mount
MODEL=$(env_get HERMES_MODEL); MODEL=${MODEL:-claude-sonnet-4-6}
PROVIDER=$(env_get HERMES_PROVIDER); PROVIDER=${PROVIDER:-auto}

mkdir -p "$D/workspace/skills" "$D/skills"
cp seed/SOUL.md "$D/SOUL.md"                                   # refreshed every start
rm -rf "$D/bundled-skills" && cp -R seed/bundled-skills "$D/bundled-skills"   # refreshed every start
[ -f "$D/workspace/CLAUDE.md" ] && [ ! -f "$D/workspace/AGENTS.md" ] && mv "$D/workspace/CLAUDE.md" "$D/workspace/AGENTS.md"
[ -f "$D/workspace/AGENTS.md" ] || cp -R seed/workspace/. "$D/workspace/"   # first run only
touch "$D/.no-bundled-skills" "$D/skills/.no-bundled-skills"   # don't load Hermes' ~58 default skills

# Only file, terminal and skills tools stay on, so abilities come from skills.
cat > "$D/config.yaml" <<EOF
model:
  default: $MODEL
  provider: $PROVIDER
terminal:
  backend: local
  cwd: /opt/data/workspace
approvals:
  mode: "off"
agent:
  disabled_toolsets: [web, search, x_search, vision, video, image_gen, video_gen, computer_use, browser, cronjob, tts, todo, memory, session_search, connections, project, clarify, code_execution, delegation, kanban]
skills:
  external_dirs:
    - /opt/data/workspace/skills
EOF

# --- 3. Start the containers ---------------------------------------------------
export HERMES_UID="$(id -u)" HERMES_GID="$(id -g)"
[ "$FRESH" = 1 ] && docker compose down   # containers left running after hermes-data was deleted would still point at the old folder
docker compose up -d

printf 'Waiting for BabyAgent'
i=0; until curl -sf -m 2 http://127.0.0.1:8642/health >/dev/null 2>&1; do
  i=$((i+1)); [ "$i" -le 60 ] || { echo; echo "Didn't come up. Try: docker compose logs gateway"; exit 1; }
  printf '.'; sleep 2
done
echo " up."
echo "  API:       http://127.0.0.1:8642/v1  (model: babyagent, key: API_SERVER_KEY in .env)"
echo "  Dashboard: http://127.0.0.1:9119     (login in .env)"

# --- 4. Chat ---------------------------------------------------------------------
if [ "${1:-}" = "--no-chat" ]; then
  echo "Started. Chat any time with ./chat.sh — stop with: docker compose down"
  exit 0
fi
echo "Opening chat (/quit to leave; BabyAgent keeps running — stop it with: docker compose down)"
exec docker compose exec -it -u hermes gateway hermes chat
