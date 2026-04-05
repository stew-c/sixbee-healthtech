set dotenv-load := false

default:
    @just --list --unsorted

start:
    docker compose up -d

stop:
    docker compose down
