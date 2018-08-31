#!/usr/bin/env bash

set -euo pipefail

function cleanup {
  echo "Bringing down middleware:"
  docker-compose down
}
trap cleanup EXIT

rm -rf mw-config mw-database
mkdir mw-config mw-database
docker-compose down 2>/dev/null

{
  echo -n "Generating test config..."
  ./generate test/config.yml mw-config 1>&2 
  echo "DONE"

  echo -n "Starting middleware with test config..."
  docker-compose up --detach 1>&2
  echo "DONE"

  echo -n "Checking middleware is serving metadata"
  for i in $(seq 10); do
    curl -ksf -o /dev/null https://localhost:8443/eidas-middleware/Metadata && break
    echo -n "."
    sleep 2
  done
  echo "DONE"

  echo "Success!"
} 2>pre-commit.log

rm -rf mw-config mw-database
rm pre-commit.log
