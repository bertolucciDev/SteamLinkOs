#!/usr/bin/env bash
set -euo pipefail

TARGET_DISK="${1:-/dev/sda}"
ROOTFS_TAR="${2:-/run/live/medium/live/rootfs.tar.gz}"
TARGET_MNT="/mnt/steamlinkos-target"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[erro] comando obrigatório não encontrado: $1" >&2
    exit 1
  }
}

for cmd in parted mkfs.ext4 mount umount tar grub-install update-grub; do
  require_cmd "$cmd"
done

if [[ ! -b "$TARGET_DISK" ]]; then
  echo "[erro] disco alvo inválido: $TARGET_DISK" >&2
  exit 1
fi

if [[ ! -f "$ROOTFS_TAR" ]]; then
  echo "[erro] rootfs não encontrado no live media: $ROOTFS_TAR" >&2
  exit 1
fi

echo "[warn] instalando SteamLinkOS em $TARGET_DISK (APAGARÁ O DISCO)"
parted -s "$TARGET_DISK" mklabel gpt
parted -s "$TARGET_DISK" mkpart primary ext4 1MiB 100%
parted -s "$TARGET_DISK" set 1 boot on

TARGET_PART="${TARGET_DISK}1"
mkfs.ext4 -F "$TARGET_PART"
mkdir -p "$TARGET_MNT"
mount "$TARGET_PART" "$TARGET_MNT"

tar -xzf "$ROOTFS_TAR" -C "$TARGET_MNT"

mount --bind /dev "$TARGET_MNT/dev"
mount --bind /proc "$TARGET_MNT/proc"
mount --bind /sys "$TARGET_MNT/sys"

chroot "$TARGET_MNT" grub-install "$TARGET_DISK"
chroot "$TARGET_MNT" update-grub || true

umount -lf "$TARGET_MNT/dev" || true
umount -lf "$TARGET_MNT/proc" || true
umount -lf "$TARGET_MNT/sys" || true
umount -lf "$TARGET_MNT" || true

echo "[ok] instalação concluída. Reinicie o sistema."
