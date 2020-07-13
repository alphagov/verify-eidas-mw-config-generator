#!/usr/bin/env bash

set -euo pipefail

rm -rf mw-config mw-database
mkdir mw-config
docker-compose down
docker volume create mw-database-test

echo "Generating test config for run-local..."
./generate test/config.yml mw-config

echo "Starting middleware with test config..."
docker-compose up -d
echo "Check if middleware is up at https://localhost:8448/eidas-middleware/Metadata"
echo "Remove with \`docker-compose down\`"


