#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd -P)"
CURRENT_DIR="$(pwd -P)"
GW_DIR="$ROOT/examples/provider-gateway"
ENV_EXAMPLE="$GW_DIR/gateway.env.example"
ENV_FILE="$GW_DIR/gateway.env"

PASS=0
WARN=0
FAIL=0

pass() {
  PASS=$((PASS + 1))
  echo "[PASS] $1"
}

warn() {
  WARN=$((WARN + 1))
  echo "[WARN] $1"
}

fail() {
  FAIL=$((FAIL + 1))
  echo "[FAIL] $1"
}

find_bun() {
  if command -v bun >/dev/null 2>&1; then
    command -v bun
    return 0
  fi

  local candidates=(
    "${BUN_INSTALL:-$HOME/.bun}/bin/bun"
    "$HOME/.bun/bin/bun"
    /opt/homebrew/bin/bun
    /usr/local/bin/bun
  )
  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

find_python() {
  if command -v python3 >/dev/null 2>&1; then
    command -v python3
    return 0
  fi
  if command -v python >/dev/null 2>&1; then
    command -v python
    return 0
  fi
  return 1
}

echo "Repo root: $ROOT"
echo "Current directory: $CURRENT_DIR"

case "$CURRENT_DIR/" in
  "$ROOT/"* ) pass "current directory is inside this repo" ;;
  * )
    fail "run this script from somewhere inside $ROOT"
    echo "Tip: cd \"$ROOT\" and rerun ./bootstrap-gateway.sh"
    exit 1
    ;;
esac

if [[ ! -f "$ENV_EXAMPLE" ]]; then
  fail "missing template env file: $ENV_EXAMPLE"
  exit 1
fi
pass "template env file found"

if [[ -f "$ENV_FILE" ]]; then
  pass "existing gateway.env preserved"
else
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  pass "created local gateway.env from gateway.env.example"
fi

if BUN_BIN="$(find_bun)"; then
  pass "bun found at $BUN_BIN"
else
  warn "bun not found"
  echo "      Install Bun: curl -fsSL https://bun.sh/install | bash"
fi

PYTHON_BIN=""
if PYTHON_BIN="$(find_python)"; then
  pass "python found at $PYTHON_BIN"
  if "$PYTHON_BIN" -m pip --version >/dev/null 2>&1; then
    pass "pip is available via $PYTHON_BIN -m pip"
  elif command -v pip3 >/dev/null 2>&1; then
    pass "pip3 is available"
  elif command -v pip >/dev/null 2>&1; then
    pass "pip is available"
  else
    warn "pip not found"
    echo "      Install pip for your Python runtime before installing LiteLLM."
  fi
else
  warn "python not found"
  echo "      Install Python 3 so you can run LiteLLM locally."
fi

if command -v litellm >/dev/null 2>&1; then
  pass "LiteLLM is on PATH"
elif [[ -n "$PYTHON_BIN" ]] && "$PYTHON_BIN" -m pip show litellm >/dev/null 2>&1; then
  warn "LiteLLM package is installed, but the litellm command is not on PATH"
  echo "      Try running it from the same Python environment or reopen the shell."
else
  warn "LiteLLM is not installed yet"
  if [[ -n "$PYTHON_BIN" ]]; then
    echo "      Install with: $PYTHON_BIN -m pip install \"litellm[proxy]\""
  else
    echo "      Install Python first, then run: python3 -m pip install \"litellm[proxy]\""
  fi
fi

echo ""
echo "Summary: ${PASS} pass, ${WARN} warn, ${FAIL} fail"
echo ""
echo "Next steps:"
echo "  1) Edit examples/provider-gateway/gateway.env and add one provider key"
echo "  2) Choose a route: ./use-provider auto"
echo "  3) Run checks:    ./doctor-gateway"
echo "                     ./scripts/smoke-test-gateway.sh"
echo "  4) Start gateway: cd examples/provider-gateway && ./start-litellm.sh"
echo "  5) Run the CLI:   ./run-claude.sh"

if [[ $FAIL -ne 0 ]]; then
  exit 1
fi
