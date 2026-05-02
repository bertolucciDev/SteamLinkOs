#!/usr/bin/env bash
set -euo pipefail

ROOTFS_TAR="${1:-build/steamlinkos-rootfs.tar.gz}"
KERNEL_IMAGE="${2:-rootfs/boot/vmlinuz}"
INITRD_IMAGE="${3:-rootfs/boot/initrd.img}"
ISO_STAGING="${4:-build/iso-hybrid-staging}"
ISO_OUTPUT="${5:-build/steamlinkos-installer-hybrid.iso}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[erro] comando obrigatório não encontrado: $1" >&2
    exit 1
  }
}

require_cmd grub-mkrescue
require_cmd xorriso

for f in "$ROOTFS_TAR" "$KERNEL_IMAGE" "$INITRD_IMAGE"; do
  [[ -f "$f" ]] || { echo "[erro] arquivo não encontrado: $f" >&2; exit 1; }
done

rm -rf "$ISO_STAGING"
mkdir -p "$ISO_STAGING/boot/grub" "$ISO_STAGING/live"

cp iso/boot/grub/grub.cfg "$ISO_STAGING/boot/grub/grub.cfg"
cp "$ROOTFS_TAR" "$ISO_STAGING/live/rootfs.tar.gz"
cp "$KERNEL_IMAGE" "$ISO_STAGING/live/vmlinuz"
cp "$INITRD_IMAGE" "$ISO_STAGING/live/initrd.img"
cp scripts/auto-install.sh "$ISO_STAGING/live/auto-install.sh"
chmod +x "$ISO_STAGING/live/auto-install.sh"

grub-mkrescue -o "$ISO_OUTPUT" "$ISO_STAGING"

echo "[ok] ISO híbrida (BIOS+UEFI) gerada: $ISO_OUTPUT"
