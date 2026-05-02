#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/etc/steamlinkos/config.env"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/etc/steamlinkos/config.env
  source "$CONFIG_FILE"
fi

# Placeholder: substitua pelo binário real no ambiente alvo.
exec /usr/bin/steamlink
