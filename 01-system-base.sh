#!/bin/bash
# Ejecutar como ROOT (sudo)

echo "--- 🚀 FASE 1: INSTALACIÓN DEL SISTEMA BASE (V11 CLEAN) ---"

if [ "$EUID" -ne 0 ]; then
  echo "❌ EJECUTAR COMO ROOT (sudo)."
  exit 1
fi

# 1. Configuración de Repositorios
echo "--- 📦 Configurando Repositorios ---"
if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
    sed -i.bak 's/Components: main.*/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources
elif [[ -f /etc/apt/sources.list ]]; then
    sed -i.bak 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
fi
apt update && apt -y full-upgrade

# 2. Kernel, Firmware y Utilidades
echo "--- 📦 Instalando Kernel y Firmware Específico Dell ---"
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
    vainfo \
    snapper \
    inotify-tools \
    git \
    make 

# 3. Stack Sway
echo "--- 🖼️ Instalando Entorno Gráfico ---"
PKGS_SWAY=(
  # Core
  sway swaybg swayidle swaylock xwayland
  waybar wofi mako-notifier 
  
  # Utilidades
  grim slurp swappy wl-clipboard wdisplays
  xdg-desktop-portal-wlr xdg-desktop-portal-gtk
  greetd tuigreet lxpolkit wf-recorder libnotify-bin
  
  # Terminal y Archivos
  alacritty
  thunar thunar-archive-plugin thunar-volman gvfs-backends
  xarchiver zip p7zip-full unrar-free
  
  # Apps Base
  chromium mpv gnome-disk-utility galculator
  imv zathura
  
  # Hardware y Audio
  brightnessctl pamixer playerctl
  btop nm-connection-editor blueman network-manager-gnome
  pipewire pipewire-pulse wireplumber pavucontrol libspa-0.2-bluetooth
  power-profiles-daemon fwupd thermald
  
  # Temas
  fonts-inter fonts-jetbrains-mono fonts-font-awesome fonts-noto-color-emoji
  papirus-icon-theme arc-theme desktop-base dmz-cursor-theme
  qt5ct qt6ct qtwayland5 openssh-server
)
apt -y --no-install-recommends install "${PKGS_SWAY[@]}"

# 4. Variables Globales
echo "--- 🌍 Configurando Variables Globales ---"
cat > /etc/environment <<EOF
MOZ_ENABLE_WAYLAND=1
QT_QPA_PLATFORM=wayland;xcb
QT_QPA_PLATFORMTHEME=qt5ct
GDK_BACKEND=wayland,x11
XDG_SESSION_TYPE=wayland
XDG_CURRENT_DESKTOP=sway
EDITOR=nano
VISUAL=nano
EOF

# 5. NetworkManager
echo "--- 🌐 Blindando Red ---"
cat > /etc/NetworkManager/NetworkManager.conf <<EOF
[main]
plugins=keyfile
[ifupdown]
managed=true
EOF

if [[ -f /etc/network/interfaces ]]; then
    mv /etc/network/interfaces /etc/network/interfaces.bak
    echo "# Gestionado por NetworkManager" > /etc/network/interfaces
fi

# 6. Optimizaciones Dell 5584
echo "--- ⚡ Aplicando Optimizaciones Hardware (GuC/HuC) ---"
echo "options i915 enable_guc=2 enable_fbc=1 fastboot=1" > /etc/modprobe.d/i915.conf
echo "options pcie_aspm policy=performance" > /etc/modprobe.d/pcie_aspm.conf
echo 'ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"' > /etc/udev/rules.d/90-backlight.rules

# 7. Login Manager
echo "--- 🔐 Configurando Login ---"
TUIGREET_PATH=$(which tuigreet || echo "/usr/bin/tuigreet")
mkdir -p /etc/greetd
cat > /etc/greetd/config.toml <<EOF
[terminal]
vt = 1
[default_session]
command = "$TUIGREET_PATH --cmd sway --time --remember --remember-session"
user = "_greetd"
EOF

# 8. Script de Grabación Global (recorder)
echo "--- 🎥 Instalando herramienta de grabación ---"
cat > /usr/local/bin/recorder <<'EOF'
#!/bin/bash
# Uso: Ejecutar 'recorder' para iniciar/parar grabación Intel VAAPI
PIDFILE="/tmp/recorder_pid"
VIDEO_FILE="$HOME/Videos/Screencast_$(date +%Y%m%d_%H%M%S).mp4"
DEVICE="/dev/dri/renderD128"

if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if ps -p $PID > /dev/null; then
        kill -SIGINT $PID
        rm "$PIDFILE"
        notify-send "🔴 Grabación Detenida" "Guardado en: $VIDEO_FILE"
        exit 0
    fi
fi

notify-send "🟢 Grabando Pantalla" "Intel VAAPI (Full HD)"
wf-recorder --audio --codec h264_vaapi --device "$DEVICE" --file "$VIDEO_FILE" &
echo $! > "$PIDFILE"
EOF
chmod +x /usr/local/bin/recorder

# 9. Servicios
echo "--- 🔧 Servicios ---"
systemctl disable ssh
systemctl enable greetd
systemctl enable bluetooth
systemctl enable fstrim.timer
systemctl disable getty@tty1 2>/dev/null || true
systemctl mask getty@tty1 2>/dev/null || true

apt autoremove -y
apt clean

echo "--- ✅ FASE 1 COMPLETADA ---"
