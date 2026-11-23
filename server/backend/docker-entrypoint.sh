#!/bin/sh
set -eu

# Railway injects PORT; Shelf ServerConfig reads SERVER_PORT and SERVER_HOST.
# Map PORT -> SERVER_PORT when SERVER_PORT is unset so no backend Dart code
# needs to be refactored for container deployment.
if [ -z "${SERVER_PORT:-}" ] && [ -n "${PORT:-}" ]; then
  export SERVER_PORT="$PORT"
fi

export SERVER_HOST="${SERVER_HOST:-0.0.0.0}"

exec /app/bin/server
