#!/usr/bin/env bash
set -euo pipefail

ROOTFS_TAR="${1:-build/steamlinkos-rootfs.tar.gz}"
KERNEL_IMAGE="${2:-rootfs/boot/vmlinuz}"
INITRD_IMAGE="${3:-rootfs/boot/initrd.img}"
ISO_STAGING="${4:-build/iso-staging}"
ISO_OUTPUT="${5:-build/steamlinkos-installer.iso}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[erro] comando obrigatório não encontrado: $1" >&2
    exit 1
  }
}

require_cmd xorriso
require_cmd grub-mkstandalone

if [[ ! -f "$ROOTFS_TAR" ]]; then
  echo "[erro] rootfs tarball não encontrado: $ROOTFS_TAR" >&2
  echo "[dica] execute antes: ./scripts/build-image.sh rootfs build" >&2
  exit 1
fi


if [[ ! -f "$KERNEL_IMAGE" ]]; then
  echo "[erro] kernel não encontrado: $KERNEL_IMAGE" >&2
  exit 1
fi

if [[ ! -f "$INITRD_IMAGE" ]]; then
  echo "[erro] initramfs não encontrado: $INITRD_IMAGE" >&2
  exit 1
fi

rm -rf "$ISO_STAGING"
mkdir -p "$ISO_STAGING/boot/grub" "$ISO_STAGING/live"

cp iso/boot/grub/grub.cfg "$ISO_STAGING/boot/grub/grub.cfg"
cp "$ROOTFS_TAR" "$ISO_STAGING/live/rootfs.tar.gz"
cp "$KERNEL_IMAGE" "$ISO_STAGING/live/vmlinuz"
cp "$INITRD_IMAGE" "$ISO_STAGING/live/initrd.img"
cp scripts/auto-install.sh "$ISO_STAGING/live/auto-install.sh"
chmod +x "$ISO_STAGING/live/auto-install.sh"

# Build GRUB EFI image
mkdir -p "$ISO_STAGING/EFI/BOOT"
grub-mkstandalone \
  -O x86_64-efi \
  -o "$ISO_STAGING/EFI/BOOT/BOOTX64.EFI" \
  "boot/grub/grub.cfg=$ISO_STAGING/boot/grub/grub.cfg"

# Build El Torito boot image
mkdir -p "$ISO_STAGING/boot/grub/x86_64-efi"
cp "$ISO_STAGING/EFI/BOOT/BOOTX64.EFI" "$ISO_STAGING/boot/grub/efiboot.img"

xorriso -as mkisofs \
  -iso-level 3 \
  -full-iso9660-filenames \
  -volid "STEAMLINKOS" \
  -eltorito-alt-boot \
  -e EFI/BOOT/BOOTX64.EFI \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -output "$ISO_OUTPUT" \
  "$ISO_STAGING"

echo "[ok] ISO gerada: $ISO_OUTPUT"
echo "[info] ISO live pronta com kernel+initramfs e script de instalação em /live/auto-install.sh"
