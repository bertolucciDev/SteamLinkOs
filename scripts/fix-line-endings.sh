#!/usr/bin/env bash
set -euo pipefail

if command -v dos2unix >/dev/null 2>&1; then
  dos2unix scripts/*.sh README.md iso/boot/grub/grub.cfg ui/*.html ui/*.css || true
else
  sed -i 's/\r$//' scripts/*.sh README.md iso/boot/grub/grub.cfg ui/*.html ui/*.css
fi

echo "[ok] line endings normalizados para LF"
