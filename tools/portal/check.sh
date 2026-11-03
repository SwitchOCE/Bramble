#!/usr/bin/env bash
# The portal's gate: unit tests, then a browser journey against a fresh
# server started from this checkout (not the installed service).
# Usage: tools/portal/check.sh        (env CHECK_PORT, default 8789)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here"
port="${CHECK_PORT:-8789}"

echo "== unit tests"
timeout 180 node --test --test-reporter=dot 'test/*.test.js'

echo "== journey (port $port)"
log="$(mktemp)"
PORTAL_PORT="$port" node server.js >"$log" 2>&1 &
pid=$!
trap 'kill $pid 2>/dev/null || true; rm -f "$log"' EXIT
for _ in $(seq 1 50); do
  curl -fsS "http://127.0.0.1:$port/healthz" >/dev/null 2>&1 && break
  sleep 0.2
done
curl -fsS "http://127.0.0.1:$port/healthz" >/dev/null || { echo "server didn't start:"; cat "$log"; exit 1; }

NODE_PATH="$HOME/.local/share/bramble-tools/node_modules" \
PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64 \
PORTAL_URL="http://127.0.0.1:$port" \
  timeout 300 node test/journey.js

echo "== check passed; screenshots in $here/shots/"
