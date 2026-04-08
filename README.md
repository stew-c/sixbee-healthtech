# SixBee HealthTech

Appointment booking system for a healthcare practice in West Yorkshire.

## Getting Started

### Prerequisites

- Docker and Docker Compose
- .NET 10 SDK (for local builds and tests)
- Node.js (for Elm frontend builds and tests)

Install frontend dependencies before building or running locally:

```bash
cd src/patient-app && npm install
cd src/admin-app && npm install
```

A [Justfile](https://github.com/casey/just) is provided for task automation. All commands below show both `just` and plain bash equivalents.

### Start

Start all services via Docker Compose. Database migrations run automatically on API startup.

```bash
just start
# or
docker compose up -d
```

| Service     | URL                    |
|-------------|------------------------|
| Patient App | http://localhost:3000   |
| Admin App   | http://localhost:3001   |
| API         | http://localhost:5050   |

### Stop

Stop all services (preserves data):

```bash
just stop
# or
docker compose down
```

### Build

Build all projects (API + both frontends):

```bash
just build
# or
dotnet build SixBee.sln
cd src/patient-app && npm run build
cd src/admin-app && npm run build
```

Build Docker images:

```bash
just publish
# or
docker compose build
```

### Test

Run all tests (unit, integration, BDD, Elm):

```bash
just test
```

Or run each layer individually:

**Unit tests** (no database required):

```bash
just test-unit
# or
dotnet test tests/SixBee.Appointments.Tests
dotnet test tests/SixBee.Auth.Tests
```

**Integration tests** (starts database, runs tests, stops database):

```bash
just test-integration
# or
docker compose up db -d --wait
dotnet test tests/SixBee.Appointments.Data.Tests
dotnet test tests/SixBee.Auth.Data.Tests
docker compose down
```

**BDD tests** (builds images, starts API + database, runs tests, stops all):

```bash
just test-bdd
# or
docker compose build
docker compose up db api -d --wait
dotnet test tests/SixBee.Api.Tests
docker compose down
```

**Elm tests**:

```bash
just test-elm
# or
cd src/patient-app && npx elm-test
cd src/admin-app && npx elm-test
```

### Reset

Full reset — wipe volumes, build artifacts, and rebuild from scratch:

```bash
just reset
# or
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

## Default Credentials

The following admin account is seeded on first run.

| Field    | Value              |
| -------- | ------------------ |
| Email    | admin@sixbee.co.uk |
| Password | Admin123!          |
