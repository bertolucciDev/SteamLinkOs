#!/usr/bin/env bash
set -euo pipefail

TARGET_ROOTFS="${1:-rootfs}"

mkdir -p "$TARGET_ROOTFS/etc/steamlinkos"

cat > "$TARGET_ROOTFS/etc/steamlinkos/config.env" <<'EOCFG'
# SteamLinkOS runtime config
STEAMLINK_FULLSCREEN=1
STEAMLINK_RESOLUTION=1920x1080
STEAMLINK_AUDIO_OUTPUT=hdmi
EOCFG

echo "[ok] configuração base criada em $TARGET_ROOTFS/etc/steamlinkos/config.env"
