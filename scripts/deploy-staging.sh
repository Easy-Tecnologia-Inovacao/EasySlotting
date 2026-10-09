#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="${STAGING_REPO_DIR:-$HOME/EasySlotting}"
ENV_FILE="${STAGING_ENV_FILE:-backend/.env.staging}"
COMPOSE_FILE="${STAGING_COMPOSE_FILE:-compose.staging.yaml}"

cd "$REPO_DIR"
exec 9>"${STAGING_DEPLOY_LOCK:-/tmp/easyslotting-staging-deploy.lock}"
flock -n 9 || { echo "Outro deploy de staging já está em execução." >&2; exit 1; }

if [[ -n "$(git status --porcelain)" ]]; then
  echo "A árvore de trabalho está suja; preserve ou remova as alterações locais antes do deploy." >&2
  exit 1
fi

git checkout staging
git pull --ff-only origin staging

docker=(docker)
if ! "${docker[@]}" info >/dev/null 2>&1; then
  docker=(sudo -n docker)
fi

compose=("${docker[@]}" compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE")
"${compose[@]}" config --quiet
"${compose[@]}" up -d --build --force-recreate

web_container=$("${compose[@]}" ps -q web)
if [[ -z "$web_container" ]]; then
  echo "O container web não foi criado." >&2
  exit 1
fi

for attempt in {1..30}; do
  health=$("${docker[@]}" inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$web_container")
  case "$health" in
    healthy) echo "Deploy de staging concluído com sucesso."; exit 0 ;;
    unhealthy|dead) echo "O container web ficou em estado: $health" >&2; "${compose[@]}" ps --all; exit 1 ;;
  esac
  sleep 2
done

echo "O container web não ficou saudável no tempo esperado." >&2
"${compose[@]}" ps --all
exit 1
