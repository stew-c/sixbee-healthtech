set dotenv-load := false

default:
    @just --list --unsorted

build-api:
    dotnet build SixBee.sln

test-unit:
    dotnet test tests/SixBee.Auth.Tests

test-integration:
    #!/usr/bin/env bash
    set -uo pipefail
    docker compose up db -d --wait
    dotnet test tests/SixBee.Auth.Data.Tests; result=$?
    docker compose down
    exit $result

start:
    docker compose up -d

stop:
    docker compose down
