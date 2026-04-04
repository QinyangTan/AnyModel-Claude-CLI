#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$DIR/gateway.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  echo "Create it and set provider key(s), then rerun."
  exit 1
fi

existing_openai_key="${OPENAI_API_KEY:-}"
existing_google_key="${GOOGLE_API_KEY:-}"
existing_gemini_key="${GEMINI_API_KEY:-}"
existing_deepseek_key="${DEEPSEEK_API_KEY:-}"
existing_openrouter_key="${OPENROUTER_API_KEY:-}"

set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

# If the env file keeps placeholders empty, do not clobber already-exported keys.
if [[ -z "${OPENAI_API_KEY:-}" && -n "$existing_openai_key" ]]; then
  export OPENAI_API_KEY="$existing_openai_key"
fi
if [[ -z "${GOOGLE_API_KEY:-}" && -n "$existing_google_key" ]]; then
  export GOOGLE_API_KEY="$existing_google_key"
fi
if [[ -z "${GEMINI_API_KEY:-}" && -n "$existing_gemini_key" ]]; then
  export GEMINI_API_KEY="$existing_gemini_key"
fi
if [[ -z "${DEEPSEEK_API_KEY:-}" && -n "$existing_deepseek_key" ]]; then
  export DEEPSEEK_API_KEY="$existing_deepseek_key"
fi
if [[ -z "${OPENROUTER_API_KEY:-}" && -n "$existing_openrouter_key" ]]; then
  export OPENROUTER_API_KEY="$existing_openrouter_key"
fi

# Normalize Gemini key aliases: accept either GOOGLE_API_KEY or GEMINI_API_KEY.
if [[ -z "${GOOGLE_API_KEY:-}" && -n "${GEMINI_API_KEY:-}" ]]; then
  export GOOGLE_API_KEY="$GEMINI_API_KEY"
fi

selected_model="${ANTHROPIC_MODEL:-gemini-via-gateway}"
case "$selected_model" in
  openai-via-gateway)
    if [[ -z "${OPENAI_API_KEY:-}" ]]; then
      echo "Selected $selected_model but OPENAI_API_KEY is empty in $ENV_FILE."
      exit 1
    fi
    ;;
  gemini-via-gateway)
    if [[ -z "${GOOGLE_API_KEY:-}" ]]; then
      echo "Selected $selected_model but GOOGLE_API_KEY (or GEMINI_API_KEY) is empty in $ENV_FILE."
      exit 1
    fi
    ;;
  deepseek-via-gateway)
    if [[ -z "${DEEPSEEK_API_KEY:-}" ]]; then
      echo "Selected $selected_model but DEEPSEEK_API_KEY is empty in $ENV_FILE."
      exit 1
    fi
    ;;
  openrouter-via-gateway)
    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
      echo "Selected $selected_model but OPENROUTER_API_KEY is empty in $ENV_FILE."
      exit 1
    fi
    ;;
  *)
    echo "Warning: ANTHROPIC_MODEL=$selected_model is custom. Ensure litellm.yaml has a matching model_name and provider key env var."
    ;;
esac

if ! command -v litellm &>/dev/null; then
  echo "LiteLLM is not on PATH. Install with:"
  echo "  pip install 'litellm[proxy]'"
  exit 1
fi

exec litellm --config "$DIR/litellm.yaml" --port 4000
