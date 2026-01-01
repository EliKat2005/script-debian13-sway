#!/bin/bash
# 01-system-base.sh - V10 (V8 INTEGRATED)
# Misión: Base Completa, Firmware Dell, Sway Stack V8, Network Hardening.
# Ejecutar como ROOT (sudo)

echo "--- 🚀 FASE 1: BASE DEBIAN TRIXIE + DELL OPTIMIZATIONS ---"

if [ "$EUID" -ne 0 ]; then
  echo "❌ EJECUTAR COMO ROOT (sudo)."
  exit 1
fi

# 1. Repositorios (Lógica V8)
echo "--- 📦 Configurando Repositorios ---"
if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
    sed -i.bak 's/Components: main.*/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources
elif [[ -f /etc/apt/sources.list ]]; then
    sed -i.bak 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
fi
apt update && apt -y full-upgrade

# 2. Kernel y Firmware (CRÍTICO DELL 5584)
echo "--- 📦 Instalando Kernel, Firmware WiFi/Audio y Microcode ---"
KERNEL_VERSION=$(uname -r)
apt -y install curl build-essential pkg-config libglib2.0-bin xdg-user-dirs unzip \
    "linux-headers-$KERNEL_VERSION" \
    firmware-linux-nonfree \
    firmware-misc-nonfree \
    firmware-atheros \
    firmware-realtek \
    firmware-intel-sound \
    firmware-sof-signed \
    intel-microcode \
    mesa-utils \
    rfkill \
    intel-media-va-driver-non-free \
    intel-gpu-tools \
    vainfo

# 3. Stack Sway Completo (Lista V8 Original)
echo "--- 🖼️ Instalando Stack Sway V8 Completo ---"
PKGS_SWAY=(
  sway swaybg swayidle swaylock
  waybar wofi mako-notifier
  grim slurp swappy wl-clipboard wdisplays
  xdg-desktop-portal-wlr xdg-desktop-portal-gtk
  greetd tuigreet lxpolkit
  kitty thunar thunar-archive-plugin thunar-volman gvfs-backends
  xarchiver zip p7zip-full unrar-free
  chromium micro ranger mpv zathura viewnior
  brightnessctl pamixer playerctl
  btop nm-connection-editor blueman network-manager-gnome
  pipewire pipewire-pulse wireplumber pavucontrol libspa-0.2-bluetooth
  fonts-inter fonts-jetbrains-mono fonts-font-awesome fonts-noto-color-emoji
  papirus-icon-theme arc-theme desktop-base dmz-cursor-theme
  qt5ct qt6ct qtwayland5 openssh-server
)
apt -y --no-install-recommends install "${PKGS_SWAY[@]}"

# 4. Blindando NetworkManager (Fix V8)
echo "--- 🌐 Blindando NetworkManager ---"
cat > /etc/NetworkManager/NetworkManager.conf <<EOF
[main]
plugins=keyfile

[ifupdown]
managed=true
EOF

# Backup interfaces antiguas para liberar WiFi
if [[ -f /etc/network/interfaces ]]; then
    mv /etc/network/interfaces /etc/network/interfaces.bak
    echo "# Gestionado por NetworkManager" > /etc/network/interfaces
fi

# 5. Optimizaciones Dell 5584 (Fix V8)
echo "--- ⚡ Aplicando Optimizaciones Dell (Intel/PCIe) ---"
# Intel Graphics: GuC/HuC para ahorro y performance
echo "options i915 enable_guc=2 enable_fbc=1 fastboot=1" > /etc/modprobe.d/i915.conf
# Ahorro PCIe
echo "options pcie_aspm policy=performance" > /etc/modprobe.d/pcie_aspm.conf
# Regla Udev Brillo
echo 'ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"' > /etc/udev/rules.d/90-backlight.rules

# 6. Configuración Login (Tuigreet System Level)
echo "--- 🔐 Configurando Tuigreet (System) ---"
TUIGREET_PATH=$(which tuigreet || echo "/usr/bin/tuigreet")
mkdir -p /etc/greetd
cat > /etc/greetd/config.toml <<EOF
[terminal]
vt = 1
[default_session]
# Nota: --unsupported-gpu se añade en el script de Nvidia si es necesario
command = "$TUIGREET_PATH --cmd sway --time --remember --remember-session"
user = "_greetd"
EOF

# 7. Servicios
echo "--- 🔧 Servicios ---"
systemctl disable ssh # Seguridad V8
systemctl enable greetd
systemctl enable bluetooth
systemctl enable fstrim.timer
# Fix TTY conflicto
systemctl disable getty@tty1 2>/dev/null || true
systemctl mask getty@tty1 2>/dev/null || true

apt autoremove -y
apt clean

echo "--- ✅ FASE 1 COMPLETADA ---"
echo "Ahora ejecuta '02-install-nvidia.sh'."
