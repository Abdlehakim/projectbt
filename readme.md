# PROJECTBT

This repository contains two projects:
- `backendbt` (Node.js/TypeScript backend, Prisma, Docker setup)
- `frontendclientbt` (frontend client)

The backend is now self-contained: runtime config, scripts, and Docker files live under `backendbt/`.

## Repository Structure

```text
PROJECTBT/
  backendbt/
    src/
    prisma/
    scripts/
      prisma-regen.js
      prisma-regen.sh
    docker/
      docker-compose.yml
    .env
    Dockerfile
    package.json
    package-lock.json
    tsconfig.json
    prisma.config.ts
    .dockerignore
    .gitignore
  frontendclientbt/
  readme.md
```

## Backend Environment

Backend environment variables are expected in:
- `backendbt/.env`
- Start from `backendbt/.env.example`

No backend `.env` is required at repository root.

## Run Backend with Docker

Recommended workflow:

```bash
cd backendbt/docker
docker compose up --build
```

Database port mapping uses `3307` by default to avoid conflicts with local MySQL.
To override it, set `DB_HOST_PORT` before running compose.

Stop containers:

```bash
cd backendbt/docker
docker compose down
```

Alternative from backend root:

```bash
cd backendbt
npm run docker:up
npm run docker:down
```

## Run Backend Scripts

Prisma helper script is now inside the backend:

```bash
cd backendbt
npm run prisma:regen
```

Supported modes:

```bash
cd backendbt
MODE=push npm run prisma:regen
MODE=deploy npm run prisma:regen
MODE=reset npm run prisma:regen
```

Mode intent:
- `push`: dev/local schema sync (non-destructive to existing tables).
- `reset`: dev/local full reset (destructive).
- `deploy`: production-like migration apply only (expects Prisma migration history already tracked for that DB).

You can also pass mode as the first argument:

```bash
cd backendbt
node scripts/prisma-regen.js deploy
```

`scripts/prisma-regen.sh` is still available for Bash users.

## Backend Development (without Docker)

```bash
cd backendbt
npm install
npm run dev
```

## Frontend

Frontend remains unchanged and lives in `frontendclientbt/`.
Use its existing workflow from that directory.

## Migration Notes

Moved from repository root into `backendbt`:
- `scripts/` -> `backendbt/scripts/`
- `.env` -> `backendbt/.env`
- `docker-compose.yml` -> `backendbt/docker/docker-compose.yml`

If you had old shell aliases or CI steps pointing to root-level paths, update them to the new backend paths.
doker cpmopos