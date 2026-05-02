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


resolve_if_symlink_missing() {
  local expected="$1" pattern="$2"
  if [[ ! -f "$expected" ]]; then
    local detected
    detected="$(ls -1 $pattern 2>/dev/null | head -n1 || true)"
    if [[ -n "$detected" ]]; then
      echo "$detected"
      return 0
    fi
  fi
  echo "$expected"
}

# Auto-detect kernel/initrd if not explicitly provided.
if [[ -z "$KERNEL_IMAGE" ]]; then
  KERNEL_IMAGE="$(ls -1 rootfs/boot/vmlinuz* 2>/dev/null | head -n1 || true)"
fi
if [[ -z "$INITRD_IMAGE" ]]; then
  INITRD_IMAGE="$(ls -1 rootfs/boot/initrd.img* 2>/dev/null | head -n1 || true)"
fi

KERNEL_IMAGE="$(resolve_if_symlink_missing "$KERNEL_IMAGE" "rootfs/boot/vmlinuz*")"
INITRD_IMAGE="$(resolve_if_symlink_missing "$INITRD_IMAGE" "rootfs/boot/initrd.img*")"

for f in "$ROOTFS_TAR" "$KERNEL_IMAGE" "$INITRD_IMAGE"; do
  [[ -f "$f" ]] || { echo "[erro] arquivo não encontrado: $f" >&2; echo "[dica] rode ./scripts/bootstrap-rootfs.sh para gerar kernel/initrd no rootfs" >&2; exit 1; }
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
