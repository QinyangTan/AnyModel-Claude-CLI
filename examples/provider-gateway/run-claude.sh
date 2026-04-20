#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$DIR/../.." && pwd)"
ENV_FILE="$DIR/gateway.env"

# Resolve bun when it is installed but not on default PATH (common after bun.sh install).
find_bun() {
  if command -v bun &>/dev/null; then
    command -v bun
    return 0
  fi
  local candidates=(
    "${BUN_INSTALL:-$HOME/.bun}/bin/bun"
    "$HOME/.bun/bin/bun"
    /opt/homebrew/bin/bun
    /usr/local/bin/bun
  )
  local p
  for p in "${candidates[@]}"; do
    if [[ -x "$p" ]]; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  echo "Run ./bootstrap-gateway.sh from the repo root to create it safely, then set provider key(s) and rerun."
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

BUN_BIN=""
if ! BUN_BIN="$(find_bun)"; then
  echo "bun not found. Install it, then open a new terminal (or add it to PATH):"
  echo "  curl -fsSL https://bun.sh/install | bash"
  echo "  export PATH=\"\$HOME/.bun/bin:\$PATH\""
  exit 1
fi

if [[ ! -f "$REPO_ROOT/dist/cli.js" ]]; then
  # Missing deps can make Bun's bundler crash (SIGTRAP) instead of a clean error.
  if [[ ! -d "$REPO_ROOT/node_modules" ]]; then
    echo "No node_modules — running: (cd \"$REPO_ROOT\" && \"$BUN_BIN\" install)"
    (cd "$REPO_ROOT" && "$BUN_BIN" install)
  fi
  echo "No dist/cli.js — building with: $BUN_BIN run build"
  (cd "$REPO_ROOT" && "$BUN_BIN" run build)
fi

cd "$REPO_ROOT"
exec "$BUN_BIN" dist/cli.js "$@"
