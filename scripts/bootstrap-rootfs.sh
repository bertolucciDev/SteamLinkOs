#!/usr/bin/env bash
set -euo pipefail

ROOTFS_DIR="${1:-rootfs}"
DEBIAN_RELEASE="${2:-bookworm}"
DEBIAN_MIRROR="${3:-http://deb.debian.org/debian}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[erro] comando obrigatório não encontrado: $1" >&2
    exit 1
  }
}

require_cmd debootstrap
require_cmd chroot
require_cmd install

echo "[info] criando rootfs Debian minimal em: $ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR"

debootstrap --arch=amd64 --variant=minbase "$DEBIAN_RELEASE" "$ROOTFS_DIR" "$DEBIAN_MIRROR"

install -d "$ROOTFS_DIR/etc/steamlinkos" "$ROOTFS_DIR/usr/local/bin" "$ROOTFS_DIR/etc/systemd/system"
install -m 0644 rootfs/etc/steamlinkos/config.env "$ROOTFS_DIR/etc/steamlinkos/config.env"
install -m 0755 scripts/launch-steamlink.sh "$ROOTFS_DIR/usr/local/bin/launch-steamlink.sh"
install -m 0644 systemd/steamlink.service "$ROOTFS_DIR/etc/systemd/system/steamlink.service"

cat > "$ROOTFS_DIR/tmp/steamlinkos-chroot-setup.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  systemd-sysv \
  sudo \
  xorg \
  openbox \
  lightdm

if ! id -u steamlink >/dev/null 2>&1; then
  useradd -m -s /bin/bash steamlink
fi

usermod -aG audio,video,input,bluetooth steamlink || true
mkdir -p /etc/systemd/system/getty@tty1.service.d

cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<'EOAUTO'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin steamlink --noclear %I $TERM
EOAUTO

systemctl enable steamlink.service
EOS

chmod +x "$ROOTFS_DIR/tmp/steamlinkos-chroot-setup.sh"
chroot "$ROOTFS_DIR" /tmp/steamlinkos-chroot-setup.sh
rm -f "$ROOTFS_DIR/tmp/steamlinkos-chroot-setup.sh"

echo "[ok] rootfs bootável inicial pronto em: $ROOTFS_DIR"
