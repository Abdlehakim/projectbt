#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT/docker-compose.yml"

# MODE can be: push (default), deploy, reset
MODE="${MODE:-push}"

echo "▶ Starting containers (db, backend)..."
docker compose -f "$COMPOSE_FILE" up -d db backend

echo "▶ Prisma validate + generate (inside container)..."
docker compose -f "$COMPOSE_FILE" exec -T backend sh -lc '
  set -e
  cd /app
  rm -rf node_modules/.prisma
  npx prisma validate
  npx prisma generate
'

echo "▶ Sync database schema (mode=$MODE)..."
case "$MODE" in
  push)
    docker compose -f "$COMPOSE_FILE" exec -T backend sh -lc '
      set -e
      cd /app
      npx prisma db push
    '
    ;;
  deploy)
    docker compose -f "$COMPOSE_FILE" exec -T backend sh -lc '
      set -e
      cd /app
      npx prisma migrate deploy
    '
    ;;
  reset)
    docker compose -f "$COMPOSE_FILE" exec -T backend sh -lc '
      set -e
      cd /app
      npx prisma migrate reset --force
    '
    ;;
  *)
    echo "❌ Unknown MODE=$MODE (use push|deploy|reset)"
    exit 1
    ;;
esac

echo "▶ Running seed (inside container)..."
docker compose -f "$COMPOSE_FILE" exec -T backend sh -lc '
  set -e
  cd /app
  if [ -f prisma/seeds/seed.js ]; then
    node prisma/seeds/seed.js
  else
    node prisma/seeds/ferraillage.seed.js
  fi
'

echo "▶ Restarting backend..."
docker compose -f "$COMPOSE_FILE" restart backend

echo "✅ Done: Prisma generated + DB synced + seed executed."
