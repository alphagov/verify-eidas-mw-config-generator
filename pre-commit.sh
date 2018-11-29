#!/usr/bin/env bash

set -euo pipefail

function check_metadata {
  echo -n "Checking middleware is serving metadata"
  for i in $(seq 10); do
    if test $i -eq 10; then
      echo "FAIL"
      echo "See pre-commit.log"
      docker-compose logs --no-color 1>&2
      exit 1
    fi

    curl -k -s -o /dev/null https://localhost:8448/eidas-middleware/Metadata && break
    echo -n "."
    sleep 3
  done
  echo "DONE"
}

function cleanup {
  echo "Bringing down middleware:"
  docker-compose down
  docker volume rm mw-config-test || :
}
trap cleanup EXIT

{
  docker-compose down

  docker volume rm mw-config-test 2>/dev/null || :
  docker volume create mw-config-test

  echo "[YAML] Generating test config..."
  docker build -q -t mwcfgen-test .
  docker run --rm -v $PWD/test:/test -v mw-config-test:/output mwcfgen-test \
    --config-file=/test/config.yml /output

  echo "[YAML] Starting middleware with test config..."
  docker-compose up -d

  check_metadata

  docker-compose down

  echo "[ENV] Generating test config..."
  docker build -q -t mwcfgen-test .
  docker run --rm --env-file ./test/config.env -v mw-config-test:/output mwcfgen-test \
    --env /output

  echo "[ENV] Starting middleware with test config..."
  docker-compose up -d

  check_metadata

  echo "Success!"
} 2>&1 | tee pre-commit.log

