#!/bin/bash
# Runs the file share without Docker: FileBrowser + a Cloudflare quick tunnel. Ctrl+C stops both.
set -euo pipefail

cd "$(dirname "$0")"
PORT=${PORT:-8080}
FB=./bin/filebrowser
DB=data-local/filebrowser.db
LOG_DIR=logs

# Homebrew's filebrowser ships without its web UI; use the official release binary
[ -x "$FB" ] || { echo "Missing $FB. Download darwin-arm64-filebrowser.tar.gz v2.32.0 from github.com/filebrowser/filebrowser/releases into bin/" >&2; exit 1; }
command -v cloudflared >/dev/null || { echo "Missing cloudflared. Install with: brew install cloudflared" >&2; exit 1; }

SHARE_DIR=$(sed -n 's/^[[:space:]]*SHARE_DIR=[[:space:]]*//p' .env 2>/dev/null | sed 's/[[:space:]]*$//' || true)
[ -d "$SHARE_DIR" ] || { echo "Set SHARE_DIR in .env to an existing folder (got: '${SHARE_DIR}')" >&2; exit 1; }

if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Port $PORT is in use. If the Docker version is running, stop it first: docker compose stop" >&2
  exit 1
fi

# Own copy of the DB: FileBrowser locks its DB, so sharing Docker's would hang if both run
if [ ! -f "$DB" ]; then
  [ -f data/filebrowser.db ] || { echo "No user database found. Start the Docker version once first, or create $DB with: $FB config init -d $DB" >&2; exit 1; }
  mkdir -p data-local
  cp data/filebrowser.db "$DB"
  chmod 600 "$DB"
  echo "Copied users from the Docker setup (same admin password)."
fi

mkdir -p "$LOG_DIR"
cleanup() {
  trap - INT TERM EXIT
  echo; echo "Stopping..."
  kill "${TUNNEL_LOOP_PID:-}" "${FB_PID:-}" 2>/dev/null || true
  pkill -f "cloudflared tunnel --no-autoupdate --url http://127.0.0.1:$PORT" 2>/dev/null || true
  { wait; } 2>/dev/null || true
}
trap 'cleanup; exit 0' INT TERM
trap cleanup EXIT

"$FB" -d "$DB" -r "$SHARE_DIR" -a 127.0.0.1 -p "$PORT" >"$LOG_DIR/filebrowser.log" 2>&1 &
FB_PID=$!

for _ in $(seq 1 20); do
  curl -s -o /dev/null "http://127.0.0.1:$PORT/" && break
  kill -0 "$FB_PID" 2>/dev/null || { echo "FileBrowser failed to start. See $LOG_DIR/filebrowser.log" >&2; exit 1; }
  sleep 0.5
done

# Quick-tunnel requests often time out when Cloudflare is slow, so keep retrying
: >"$LOG_DIR/tunnel.log"
(
  while true; do
    cloudflared tunnel --no-autoupdate --url "http://127.0.0.1:$PORT" >>"$LOG_DIR/tunnel.log" 2>&1 || true
    echo "cloudflared exited; retrying in 5s" >>"$LOG_DIR/tunnel.log"
    sleep 5
  done
) &
TUNNEL_LOOP_PID=$!
disown "$TUNNEL_LOOP_PID"

echo "Sharing: $SHARE_DIR"
echo "Local:   http://127.0.0.1:$PORT"
echo "Waiting for public link (Cloudflare can take a few minutes)..."
SHOWN=""
while kill -0 "$FB_PID" 2>/dev/null; do
  URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOG_DIR/tunnel.log" | grep -v '//api\.' | tail -1 || true)
  if [ -n "$URL" ] && [ "$URL" != "$SHOWN" ]; then
    echo "Public:  $URL"
    echo "Press Ctrl+C to stop sharing."
    SHOWN=$URL
  fi
  sleep 2
done
echo "FileBrowser stopped unexpectedly. See $LOG_DIR/filebrowser.log" >&2
exit 1
