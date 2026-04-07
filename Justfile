set dotenv-load := false

default:
    @just --list --unsorted

build-api:
    dotnet build SixBee.sln

test: test-unit test-integration test-bdd test-elm

test-unit:
    dotnet test tests/SixBee.Auth.Tests
    dotnet test tests/SixBee.Appointments.Tests

test-integration:
    #!/usr/bin/env bash
    set -uo pipefail
    docker compose up db -d --wait
    dotnet test tests/SixBee.Appointments.Data.Tests; r1=$?
    dotnet test tests/SixBee.Auth.Data.Tests; r2=$?
    docker compose down
    [ $r1 -eq 0 ] && [ $r2 -eq 0 ]

test-bdd:
    #!/usr/bin/env bash
    set -uo pipefail
    docker compose up db api -d --wait
    dotnet test tests/SixBee.Api.Tests; result=$?
    docker compose down
    exit $result

publish:
    docker compose build

start:
    docker compose up -d

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

test-elm:
    cd src/patient-app && npx elm-test

build-patient:
    cd src/patient-app && npm run build
