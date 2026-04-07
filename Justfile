set dotenv-load := false

# List available recipes
default:
    @just --list --unsorted

# Build all projects
build: build-api build-patient build-admin

# Build the .NET API
build-api:
    dotnet build SixBee.sln

# Build the patient app (Elm + Vite + Tailwind)
build-patient:
    cd src/patient-app && npm run build

# Build the admin app (Elm + Vite + Tailwind)
build-admin:
    cd src/admin-app && npm run build

# Run all tests (unit + integration + bdd + elm)
test: test-unit test-integration test-bdd test-elm

# Run unit tests only (no database required)
test-unit:
    dotnet test tests/SixBee.Auth.Tests
    dotnet test tests/SixBee.Appointments.Tests

# Run integration tests (starts db, runs tests, stops db)
test-integration:
    #!/usr/bin/env bash
    set -uo pipefail
    docker compose up db -d --wait
    dotnet test tests/SixBee.Appointments.Data.Tests; r1=$?
    dotnet test tests/SixBee.Auth.Data.Tests; r2=$?
    docker compose down
    [ $r1 -eq 0 ] && [ $r2 -eq 0 ]

# Run BDD integration tests (starts db + api, runs tests, stops all)
test-bdd:
    #!/usr/bin/env bash
    set -uo pipefail
    docker compose up db api -d --wait
    dotnet test tests/SixBee.Api.Tests; result=$?
    docker compose down
    exit $result

# Run all Elm tests
test-elm: test-patient test-admin

# Run patient app Elm tests
test-patient:
    cd src/patient-app && npx elm-test

# Run admin app Elm tests
test-admin:
    cd src/admin-app && npx elm-test

# Build all Docker images
publish:
    docker compose build

# Start all services
start:
    docker compose up -d

# Stop all services (preserves data)
stop:
    docker compose down

# Open a terminal per service showing live logs
logs:
    #!/usr/bin/env bash
    dir="$(pwd)"
    for service in db api patient-app admin-app; do
        osascript -e "tell application \"Terminal\" to do script \"cd '$dir' && docker compose logs -f $service\""
    done

# Full reset: wipe volumes, artifacts, rebuild from scratch
reset:
    docker compose down -v
    find . -type d -name bin -exec rm -rf {} + 2>/dev/null || true
    find . -type d -name obj -exec rm -rf {} + 2>/dev/null || true
    find . -type d -name elm-stuff -exec rm -rf {} + 2>/dev/null || true
    find . -type d -name node_modules -exec rm -rf {} + 2>/dev/null || true
    find . -type d -name dist -exec rm -rf {} + 2>/dev/null || true
    docker compose build --no-cache
    docker compose up -d
