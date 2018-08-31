#!/usr/bin/env bash

set -euo pipefail

function cleanup {
  echo "Bringing down middleware:"
  docker-compose down
  docker volume rm mw-database-test 1>&2
}
trap cleanup EXIT

{
  bundle --quiet

  rm -rf mw-config mw-database
  mkdir mw-config
  docker-compose down 2>/dev/null
  docker volume create mw-database-test 1>&2

  echo -n "Generating test config..."
  ./generate test/config.yml mw-config 1>&2 
  echo "DONE"

  echo -n "Starting middleware with test config..."
  docker-compose up --detach 1>&2
  echo "DONE"

  echo -n "Checking middleware is serving metadata"
  for i in $(seq 10); do
    if test $i -eq 10; then
      echo "FAIL"
      echo "See pre-commit.log"
      docker-compose logs --no-color 1>&2
      exit 1
    fi

    curl -k -o /dev/null https://localhost:8448/eidas-middleware/Metadata && break
    echo -n "."
    sleep 3
  done
  echo "DONE"

  rm -rf mw-config mw-database

  echo "Success!"
} 2>pre-commit.log

