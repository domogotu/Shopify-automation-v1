#!/bin/sh
set -eu

root_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
env_file="$root_dir/config/.env"

if [ ! -f "$env_file" ]; then
  echo "Missing config/.env. Create it from config/.env.docker.example first."
  exit 1
fi

kill_switch="$(sed -n 's/^SYSTEM_KILL_SWITCH=//p' "$env_file" | tail -n 1)"
if [ "$kill_switch" != "true" ]; then
  echo "SYSTEM_KILL_SWITCH must be true before workflow import."
  exit 1
fi

sh "$root_dir/scripts/validate-foundation.sh"

docker compose --project-directory "$root_dir" --env-file "$env_file" \
  exec -T n8n-main n8n import:workflow --separate --input=/files/workflows

echo "Workflows imported. n8n deactivates CLI imports by default; review credentials and settings before activating any trigger."
