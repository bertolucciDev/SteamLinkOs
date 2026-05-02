#!/usr/bin/env bash
set -euo pipefail

ROOTFS_DIR="${1:-rootfs}"
OUTPUT_DIR="${2:-build}"
IMAGE_NAME="steamlinkos-rootfs.tar.gz"

mkdir -p "$OUTPUT_DIR"

if [[ ! -d "$ROOTFS_DIR" ]]; then
  echo "[erro] rootfs não encontrado: $ROOTFS_DIR" >&2
  exit 1
fi

tar -C "$ROOTFS_DIR" -czf "$OUTPUT_DIR/$IMAGE_NAME" .

echo "[ok] imagem gerada em: $OUTPUT_DIR/$IMAGE_NAME"
