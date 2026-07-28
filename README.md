# ProjectBT

ProjectBT is organized as a parent repository with two Git submodules:

- `apps/customer`: the React/Vite customer application.
- `services/api`: the NestJS API backed by Prisma and PostgreSQL.

## Repository structure

```text
projectbt/
  apps/
    customer/
  services/
    api/
      prisma/
      src/
  .vscode/
  docker-compose.yml
  compose.local.yaml
  .env.example
  README.md
```

## Local ports

- Customer application: `http://localhost:5173`
- API: `http://localhost:5000`
- PostgreSQL: `127.0.0.1:15432`
- Production frontend host port: `3001` by default

## Environment

Copy `.env.example` to `.env` at the repository root and replace the placeholder database password. Real `.env` files contain credentials and must never be committed.

For commands run directly from `services/api`, make sure `DATABASE_URL` points to the PostgreSQL instance available from that environment. The Compose example uses the `db` hostname because the API container and PostgreSQL share a Compose network.

## Development

Install dependencies in each submodule:

```bash
cd services/api
npm install

cd ../../apps/customer
npm install
```

Start PostgreSQL:

```bash
docker compose -f docker-compose.yml -f compose.local.yaml up -d db
```

Generate the Prisma client and apply development migrations:

```bash
cd services/api
npx prisma generate
npx prisma migrate dev
```

Ensure the ProjectBT module catalog:

```bash
cd services/api
npm run catalog:ensure:dev
```

Start the NestJS API:

```bash
cd services/api
npm run start:dev
```

Start the React/Vite customer application in another terminal:

```bash
cd apps/customer
npm run dev
```

Prisma migration status and Studio are available from the API submodule:

```bash
cd services/api
npx prisma migrate status
npx prisma studio
```

## Production Compose

Build and start the PostgreSQL, API, and customer services:

```bash
docker compose up -d --build
```

The API container applies committed Prisma migrations and ensures the module catalog before starting NestJS. The frontend is published on `127.0.0.1:${FRONTEND_HOST_PORT:-3001}`.
