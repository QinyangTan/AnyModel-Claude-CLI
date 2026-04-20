#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
CURRENT_DIR="$(pwd -P)"
GW_DIR="$ROOT/examples/provider-gateway"
ENV_FILE="$GW_DIR/gateway.env"
LITELLM_CONFIG="$GW_DIR/litellm.yaml"
CI_MODE=0

PASS=0
WARN=0
FAIL=0

usage() {
  echo "Usage: ./scripts/smoke-test-gateway.sh [--ci]"
  echo ""
  echo "Runs safe local checks for the LiteLLM gateway workflow without making real network calls."
}

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

display_path() {
  local file="$1"
  case "$file" in
    "$ROOT"/*) printf '%s\n' "${file#$ROOT/}" ;;
    *) printf '%s\n' "$file" ;;
  esac
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ci)
      CI_MODE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

echo "Repo root: $ROOT"
echo "Current directory: $CURRENT_DIR"

required_files=(
  "$ROOT/README.md"
  "$ROOT/bootstrap-gateway.sh"
  "$ROOT/doctor-gateway"
  "$ROOT/run-claude.sh"
  "$ROOT/use-provider"
  "$ROOT/use-openai"
  "$ROOT/.github/workflows/ci.yml"
  "$ROOT/docs/PRACTICAL_SETUP.md"
  "$GW_DIR/gateway.env.example"
  "$GW_DIR/litellm.yaml"
  "$GW_DIR/start-litellm.sh"
  "$GW_DIR/run-claude.sh"
)

for file in "${required_files[@]}"; do
  if [[ -f "$file" ]]; then
    pass "found $(display_path "$file")"
  else
    fail "missing required file: $file"
  fi
done

executable_files=(
  "$ROOT/bootstrap-gateway.sh"
  "$ROOT/doctor-gateway"
  "$ROOT/run-claude.sh"
  "$ROOT/use-provider"
  "$ROOT/use-openai"
  "$ROOT/scripts/smoke-test-gateway.sh"
  "$GW_DIR/start-litellm.sh"
  "$GW_DIR/run-claude.sh"
)

for file in "${executable_files[@]}"; do
  if [[ -x "$file" ]]; then
    pass "executable bit set: $(display_path "$file")"
  else
    fail "expected executable bit on: $file"
  fi
done

if [[ -f "$ENV_FILE" ]]; then
  pass "gateway env file found"
else
  fail "missing gateway env file: $ENV_FILE"
  echo "      Fix: run ./bootstrap-gateway.sh"
fi

if [[ -f "$ENV_FILE" && -f "$LITELLM_CONFIG" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a

  if [[ -z "${GOOGLE_API_KEY:-}" && -n "${GEMINI_API_KEY:-}" ]]; then
    GOOGLE_API_KEY="$GEMINI_API_KEY"
  fi

  selected_model="${ANTHROPIC_MODEL:-}"
  fast_model="${ANTHROPIC_SMALL_FAST_MODEL:-}"
  master_key="$(sed -n 's/^[[:space:]]*master_key:[[:space:]]*//p' "$LITELLM_CONFIG" | head -n 1)"

  if [[ -n "${ANTHROPIC_BASE_URL:-}" ]]; then
    pass "ANTHROPIC_BASE_URL is set"
  else
    fail "ANTHROPIC_BASE_URL is missing"
  fi

  if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    pass "ANTHROPIC_API_KEY is set"
    if [[ -n "$master_key" ]]; then
      if [[ "$ANTHROPIC_API_KEY" == "$master_key" ]]; then
        pass "ANTHROPIC_API_KEY matches LiteLLM master_key"
      else
        fail "ANTHROPIC_API_KEY does not match LiteLLM master_key"
      fi
    else
      warn "could not read master_key from litellm.yaml"
    fi
  else
    fail "ANTHROPIC_API_KEY is missing"
  fi

  if [[ -n "$selected_model" ]]; then
    if grep -Eq "model_name:[[:space:]]*$selected_model([[:space:]]|$)" "$LITELLM_CONFIG"; then
      pass "ANTHROPIC_MODEL route exists in litellm.yaml: $selected_model"
    else
      fail "ANTHROPIC_MODEL route not found in litellm.yaml: $selected_model"
    fi
  else
    fail "ANTHROPIC_MODEL is missing"
  fi

  if [[ -n "$fast_model" ]]; then
    if grep -Eq "model_name:[[:space:]]*$fast_model([[:space:]]|$)" "$LITELLM_CONFIG"; then
      pass "ANTHROPIC_SMALL_FAST_MODEL route exists in litellm.yaml: $fast_model"
    else
      fail "ANTHROPIC_SMALL_FAST_MODEL route not found in litellm.yaml: $fast_model"
    fi
  else
    warn "ANTHROPIC_SMALL_FAST_MODEL is missing"
  fi

  required_key_var=""
  case "$selected_model" in
    openai-via-gateway) required_key_var="OPENAI_API_KEY" ;;
    gemini-via-gateway) required_key_var="GOOGLE_API_KEY" ;;
    deepseek-via-gateway) required_key_var="DEEPSEEK_API_KEY" ;;
    openrouter-via-gateway) required_key_var="OPENROUTER_API_KEY" ;;
    "") ;;
    *) warn "custom ANTHROPIC_MODEL selected; provider key check skipped" ;;
  esac

  if [[ -n "$required_key_var" ]]; then
    if [[ -n "${!required_key_var:-}" ]]; then
      pass "required provider key is set: $required_key_var"
    elif [[ $CI_MODE -eq 1 ]]; then
      warn "required provider key is empty in CI mode: $required_key_var"
    else
      fail "required provider key is empty: $required_key_var"
    fi
  fi
fi

if BUN_BIN="$(find_bun)"; then
  pass "bun is available at $BUN_BIN"
else
  warn "bun is not on PATH"
fi

if command -v litellm >/dev/null 2>&1; then
  pass "litellm is available"
else
  warn "litellm is not on PATH"
fi

echo ""
echo "Summary: ${PASS} pass, ${WARN} warn, ${FAIL} fail"

if [[ $FAIL -ne 0 ]]; then
  echo "Result: NOT READY"
  exit 1
fi

echo "Result: READY"
