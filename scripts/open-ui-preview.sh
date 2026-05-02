#!/usr/bin/env bash
set -euo pipefail

UI_DIR="${1:-ui}"
INDEX_FILE="$UI_DIR/index.html"

if [[ ! -f "$INDEX_FILE" ]]; then
  echo "[erro] arquivo não encontrado: $INDEX_FILE" >&2
  exit 1
fi

echo "Abra no navegador: file://$(realpath "$INDEX_FILE")"
