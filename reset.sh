#!/bin/sh
# BabyAgent "Restart": stops the containers and deletes ./hermes-data
# (workspace, secrets, skills, chat history). Your .env is kept.
# Run ./chat.sh afterwards for a fresh blank-slate agent.
set -eu
cd "$(dirname "$0")"

printf 'This deletes ./hermes-data (workspace, secrets, skills, chat history). Continue? [y/N] '
read -r answer
[ "$answer" = "y" ] || [ "$answer" = "Y" ] || { echo "Aborted."; exit 1; }

docker compose down
rm -rf hermes-data
echo "Wiped. Run ./chat.sh for a fresh BabyAgent."
