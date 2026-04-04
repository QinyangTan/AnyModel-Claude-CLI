#!/usr/bin/env bash
# Convenience wrapper: run from repo root (local LLM gateway mode)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
exec "$ROOT/examples/provider-gateway/run-claude.sh" "$@"
