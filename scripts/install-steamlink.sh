#!/usr/bin/env bash
set -euo pipefail

ROOTFS_DIR="${1:-rootfs}"
DEBIAN_CODENAME="${2:-bookworm}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[erro] comando obrigatório não encontrado: $1" >&2
    exit 1
  }
}

for c in chroot install tee; do require_cmd "$c"; done

install -d "$ROOTFS_DIR/tmp" "$ROOTFS_DIR/usr/local/bin" "$ROOTFS_DIR/etc/sway" "$ROOTFS_DIR/etc/systemd/system/getty@tty1.service.d"

cat > "$ROOTFS_DIR/tmp/steamlinkos-install.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

cat > /etc/apt/sources.list <<'EOL'
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOL

dpkg --add-architecture i386
apt-get update

apt-get install -y --no-install-recommends \
  systemd-sysv dbus sudo \
  sway seatd xwayland foot \
  pipewire wireplumber pipewire-audio pipewire-pulse alsa-utils \
  libgl1 libgl1:i386 libgl1-mesa-dri libgl1-mesa-dri:i386 \
  mesa-va-drivers mesa-va-drivers:i386 intel-media-va-driver-non-free \
  libgbm1 libgbm1:i386 libdrm2 libdrm2:i386 \
  libasound2 libasound2:i386 libpulse0 libpulse0:i386 \
  libx11-6 libx11-6:i386 libxext6 libxext6:i386 libxrandr2 libxrandr2:i386 \
  libxcursor1 libxcursor1:i386 libxi6 libxi6:i386 libxinerama1 libxinerama1:i386 \
  libxss1 libxss1:i386 libxxf86vm1 libxxf86vm1:i386 \
  libva2 libva2:i386 libva-drm2 libva-drm2:i386 libva-x11-2 libva-x11-2:i386 \
  udev pciutils usbutils curl ca-certificates vainfo

# Steam Link: prefer package manager, fallback to Valve package.
if apt-cache show steamlink >/dev/null 2>&1; then
  apt-get install -y steamlink || true
fi

if ! command -v steamlink >/dev/null 2>&1; then
  curl -fL -o /tmp/steamlink.deb https://media.steampowered.com/steamlink/linux/latest/steamlink.deb
  apt-get install -y /tmp/steamlink.deb || apt-get -f install -y
fi

if ! id -u steamlink >/dev/null 2>&1; then
  useradd -m -s /bin/bash steamlink
fi
usermod -aG video,audio,input,render,plugdev steamlink || true

systemctl enable seatd.service || true
systemctl enable steamlink.service || true
EOS

cat > "$ROOTFS_DIR/usr/local/bin/steamlink-kiosk-launch.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export WLR_RENDERER_ALLOW_SOFTWARE=1
export LIBVA_DRIVER_NAME="${LIBVA_DRIVER_NAME:-iHD}"
export SDL_VIDEODRIVER=wayland

mkdir -p "$XDG_RUNTIME_DIR"

if command -v vainfo >/dev/null 2>&1; then
  if ! vainfo >/tmp/vainfo.log 2>&1; then
    echo "[warn] VAAPI indisponível, seguindo com fallback de software" | systemd-cat -t steamlink-kiosk
  fi
fi

exec steamlink
EOS

cat > "$ROOTFS_DIR/usr/local/bin/start-sway-kiosk.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
mkdir -p "$XDG_RUNTIME_DIR"
exec sway --config /etc/sway/steamlink-kiosk.conf
EOS

cat > "$ROOTFS_DIR/etc/sway/steamlink-kiosk.conf" <<'EOS'
set $mod Mod4

# Kiosk hardening: disable common escape keybinds.
unbindsym $mod+Shift+e
unbindsym $mod+Shift+c
unbindsym $mod+d
unbindsym $mod+Return
bindsym --locked XF86PowerOff exec systemctl poweroff

output * bg #000000 solid_color
focus_follows_mouse no
seat seat0 hide_cursor 3000

default_border none
default_floating_border none
gaps inner 0
gaps outer 0

exec_always --no-startup-id /usr/local/bin/steamlink-kiosk-launch.sh
EOS

cat > "$ROOTFS_DIR/etc/systemd/system/steamlink.service" <<'EOS'
[Unit]
Description=Steam Link Kiosk Session (Wayland/Sway)
After=systemd-user-sessions.service seatd.service
Wants=seatd.service
StartLimitIntervalSec=60
StartLimitBurst=10

[Service]
Type=simple
User=steamlink
PAMName=login
WorkingDirectory=/home/steamlink
Environment=HOME=/home/steamlink
Environment=USER=steamlink
Environment=XDG_SESSION_TYPE=wayland
Environment=XDG_CURRENT_DESKTOP=sway
ExecStart=/usr/local/bin/start-sway-kiosk.sh
Restart=always
RestartSec=2
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOS

cat > "$ROOTFS_DIR/etc/systemd/system/getty@tty1.service.d/override.conf" <<'EOS'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin steamlink --noclear %I $TERM
Type=simple
EOS

chmod +x "$ROOTFS_DIR/tmp/steamlinkos-install.sh" \
         "$ROOTFS_DIR/usr/local/bin/steamlink-kiosk-launch.sh" \
         "$ROOTFS_DIR/usr/local/bin/start-sway-kiosk.sh"

chroot "$ROOTFS_DIR" /tmp/steamlinkos-install.sh
rm -f "$ROOTFS_DIR/tmp/steamlinkos-install.sh"

echo "[ok] Steam Link stack instalada no rootfs: $ROOTFS_DIR"
