#!/bin/bash
# Ejecutar como ROOT (sudo)
set -Eeuo pipefail

DRY_RUN=false
VERIFY_ONLY=false
LOG_FILE="/var/log/script-debian13-sway.log"

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --verify-only) VERIFY_ONLY=true ;;
        *) echo "Argumento desconocido: $arg"; exit 2 ;;
    esac
done

exec > >(tee -a "$LOG_FILE") 2>&1

log_info() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

echo "--- 🚀 FASE 1: INSTALACIÓN MODULAR ---"

if [ "$EUID" -ne 0 ]; then
  echo "❌ EJECUTAR COMO ROOT (sudo)."
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "Modo dry-run: hardware compatible; no se aplicarán cambios."
    exit 0
fi

if [[ "$VERIFY_ONLY" == true ]]; then
    echo "Modo verify-only: comprobando configuración instalada."
    test -f /etc/modprobe.d/i915.conf
    grep -q 'enable_guc=3.*enable_fbc=1' /etc/modprobe.d/i915.conf
    test -f /etc/default/zramswap
    test -f /etc/sysctl.d/99-zram.conf
    test -f /etc/udev/rules.d/60-nvme-scheduler.rules
    findmnt -n -o FSTYPE / | grep -qx 'btrfs'
    findmnt -n -o OPTIONS / | grep -q 'subvol=/@'
    test -d /sys/class/power_supply/BAT0
    if test -f /sys/class/power_supply/BAT0/charge_control_end_threshold; then
        grep -qx '80' /sys/class/power_supply/BAT0/charge_control_end_threshold
        systemctl is-enabled battery-charge-limit.service | grep -qx 'enabled'
    fi
    ufw status | grep -q 'Status: active'
    systemctl is-active --quiet power-profiles-daemon
    systemctl is-active --quiet thermald
    systemctl is-active --quiet zramswap
    echo "Verificación completada."
    exit 0
fi

if ! lspci -nn | grep -q '8086:3ea0'; then
    echo "Hardware no compatible: no se encontró la Intel UHD 620 esperada."
    exit 1
fi

if ! lspci -nn | grep -q '10de:174d'; then
    echo "Hardware no compatible: no se encontró la NVIDIA MX130 esperada."
    exit 1
fi

#if [[ ! -b /dev/nvme0n1 ]]; then
#    echo "Hardware no compatible: no se encontró el NVMe esperado."
#    exit 1
#fi

BIOS_VERSION=$(cat /sys/class/dmi/id/bios_version 2>/dev/null || echo "desconocida")
log_info "BIOS detectado: $BIOS_VERSION"

if findmnt -n -o FSTYPE / | grep -qx 'btrfs'; then
    log_info "Sistema de archivos raíz: BTRFS"
else
    log_info "ADVERTENCIA: la raíz no está montada como BTRFS"
fi

# --- 0. PARTICIONADO (REALIZADO ANTES POR EL USUARIO) ---
# La raíz BTRFS, sus subvolúmenes, /boot y /home deben prepararse durante
# la instalación de Debian. Este script no modifica particiones ni sistemas.

# --- FUNCIÓN DE INSTALACIÓN SEGURA ---
install_pkg() {
    echo "--- 📦 Instalando bloque: $1 ---"
    read -r -a packages <<< "$2"
    apt-get -y --no-install-recommends --no-install-suggests install -- "${packages[@]}"
    echo "✅ Bloque $1 instalado correctamente."
}

# --- 1. REPOSITORIOS ---
echo "--- 📡 Configurando Repositorios (Contrib / Non-Free) ---"
SOURCES_FILE="/etc/apt/sources.list.d/debian.sources"

cat > /etc/apt/apt.conf.d/99-minimal <<'EOF'
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF

if [[ -f /etc/apt/sources.list ]] || find /etc/apt/sources.list.d -maxdepth 1 -type f -name '*.list' -print -quit | grep -q .; then
    mkdir -p /var/backups/debian-sway
    find /etc/apt/sources.list.d -maxdepth 1 -type f -name '*.list' -exec cp -a '{}' /var/backups/debian-sway/ ';'
    [[ -f /etc/apt/sources.list ]] && cp -a /etc/apt/sources.list /var/backups/debian-sway/sources.list.pre-modernize
    apt -y modernize-sources
    echo "   Fuentes APT antiguas migradas al formato .sources moderno."
fi

if [[ -f "$SOURCES_FILE" ]]; then
    mkdir -p /var/backups/debian-sway
    cp -a "$SOURCES_FILE" "/var/backups/debian-sway/debian.sources.base.$(date +%Y%m%d-%H%M%S)"

    if ! grep -q 'contrib' "$SOURCES_FILE" ||
       ! grep -q 'non-free' "$SOURCES_FILE" ||
       ! grep -q 'non-free-firmware' "$SOURCES_FILE"; then
        echo "   Detectado repositorio incompleto. Activando contrib y non-free..."
        sed -i 's/Components: main.*/Components: main contrib non-free non-free-firmware/g' "$SOURCES_FILE"
        echo "   Repositorios corregidos."
    else
        echo "   Repositorios ya configurados correctamente."
    fi
elif [[ -f "/etc/apt/sources.list" ]]; then
    if grep -q "^deb.*main" /etc/apt/sources.list; then
         sed -i 's/main.*/main contrib non-free non-free-firmware/g' /etc/apt/sources.list
    fi
fi

echo "--- ⚡ PRE-CONFIGURACIÓN: Optimizaciones Hardware (Intel i7 / PCIe) ---"
echo "options i915 enable_guc=3 enable_fbc=1" > /etc/modprobe.d/i915.conf
rm -f /etc/modprobe.d/pcie_aspm.conf
echo 'ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"' > /etc/udev/rules.d/90-backlight.rules
cat > /etc/udev/rules.d/60-nvme-scheduler.rules <<'EOF'
ACTION=="add", SUBSYSTEM=="block", KERNEL=="nvme0n1", ATTR{queue/scheduler}="none"
EOF
udevadm control --reload-rules
if [[ -w /sys/block/nvme0n1/queue/scheduler ]]; then
    echo none > /sys/block/nvme0n1/queue/scheduler
fi

echo "--- 🌡️ Optimizando Sensores Térmicos (Batería y Ventiladores Dell) ---"
echo "coretemp" > /etc/modules-load.d/sensors.conf
echo "dell-smm-hwmon" >> /etc/modules-load.d/sensors.conf

echo "--- 🔄 Actualizando lista de paquetes... ---"
apt update && apt -y full-upgrade

# 2. Kernel y Firmware
install_pkg "FIRMWARE_KERNEL" "curl build-essential pkg-config libglib2.0-bin xdg-user-dirs unzip linux-headers-amd64 dkms firmware-linux-nonfree firmware-misc-nonfree firmware-atheros firmware-realtek firmware-sof-signed intel-microcode btrfs-progs xfsprogs exfatprogs ntfs-3g"

# 3. Drivers Gráficos y Utilidades de Sistema
install_pkg "DRIVERS_INTEL" "mesa-utils rfkill intel-media-va-driver intel-gpu-tools vainfo vulkan-tools"
install_pkg "UTILIDADES_SYS" "timeshift git make wf-recorder libnotify-bin lm-sensors ufw udiskie zram-tools"

# 4. Entorno Sway (Core)
install_pkg "SWAY_CORE" "sway swaybg swayidle swaylock xwayland waybar wofi mako-notifier wlogout"

# 5. Utilidades de Escritorio
install_pkg "PORTALES_POLKIT" "grim slurp swappy wl-clipboard wdisplays xdg-desktop-portal-wlr xdg-desktop-portal-gtk greetd tuigreet lxpolkit"

# 6. Gestión de Archivos
install_pkg "ARCHIVOS" "foot thunar thunar-archive-plugin gvfs-backends xarchiver zip 7zip unrar tumbler ffmpegthumbnailer"

# 7. Aplicaciones Base
install_pkg "APPS_BASE" "mpv galculator gnome-disk-utility swayimg zathura"

echo "--- 🌐 Instalando Brave Browser ---"
curl -fsS https://dl.brave.com/install.sh | FLAVOR=origin sh

# 8. Audio, Red y Energía
install_pkg "AUDIO_RED" "brightnessctl pamixer playerctl btop nm-connection-editor blueman network-manager-gnome pipewire pipewire-pulse wireplumber pavucontrol libspa-0.2-bluetooth power-profiles-daemon fwupd thermald"

# Retirar reglas persistentes heredadas que pueden contradecir UFW
apt -y purge iptables-persistent netfilter-persistent 2>/dev/null || true

# 9. Temas y Apariencia
install_pkg "TEMAS_COMPAT" "fonts-inter fonts-jetbrains-mono fonts-font-awesome fonts-noto-color-emoji papirus-icon-theme arc-theme desktop-base dmz-cursor-theme gtk2-engines-murrine gtk2-engines-pixbuf"
# --- CONFIGURACIONES DEL SISTEMA ---

echo "--- 🧊 Configurando ZRAM sin swap en disco ---"
cat > /etc/default/zramswap <<'EOF'
# ZRAM para el portátil Dell Inspiron 5584 con 16 GB de RAM
ALGO=zstd
SIZE=8192
PRIORITY=100
EOF

cat > /etc/sysctl.d/99-zram.conf <<'EOF'
# ZRAM prioritario sobre memoria inactiva
vm.swappiness=150
vm.page-cluster=0
vm.watermark_boost_factor=0
EOF

if [[ -w /sys/class/power_supply/BAT0/charge_control_end_threshold ]]; then
    echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold
    log_info "Límite de carga conservado: 80%"
else
    log_info "La batería no expone charge_control_end_threshold; se conservará el límite del firmware"
fi

sysctl --system
systemctl enable --now zramswap.service

echo "--- 🌍 Configurando Variables de Entorno ---"
set_environment_variable() {
    local key=$1
    local value=$2
    touch /etc/environment
    sed -i "/^[[:space:]#]*${key}[[:space:]]*=.*/d" /etc/environment
    printf '%s=%s\n' "$key" "$value" >> /etc/environment
}

set_environment_variable MOZ_ENABLE_WAYLAND 1
set_environment_variable GDK_BACKEND wayland,x11
set_environment_variable XDG_SESSION_TYPE wayland
set_environment_variable XDG_CURRENT_DESKTOP sway
set_environment_variable EDITOR nano
set_environment_variable VISUAL nano

echo "--- 🌐 Configurando NetworkManager ---"
cat > /etc/NetworkManager/NetworkManager.conf <<EOF
[main]
plugins=keyfile
[ifupdown]
managed=true
EOF

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

echo "--- 🎥 Instalando Script Recorder ---"
cat > /usr/local/bin/recorder <<'EOF'
#!/bin/bash

# 1. Detectar carpeta de videos
TARGET_DIR=$(xdg-user-dir VIDEOS 2>/dev/null || echo $HOME/Videos)
mkdir -p "$TARGET_DIR"
VIDEO_FILE="$TARGET_DIR/Screencast_$(date +%Y%m%d_%H%M%S).mp4"
DEVICE="/dev/dri/renderD128"

# 2. Lógica de Conmutación
if pgrep -x "wf-recorder" > /dev/null; then
    pkill -SIGINT -x wf-recorder

    # Esperamos un momento a que cierre el archivo
    sleep 1
    notify-send "🔴 Grabación Finalizada" "Guardado en: $(basename "$TARGET_DIR")"
else
    # SI NO ESTÁ CORRIENDO: Iniciamos la grabación
    notify-send "🟢 Grabando Pantalla" "Intel VAAPI (Full HD)"
    wf-recorder --audio --codec h264_vaapi --device "$DEVICE" --file "$VIDEO_FILE" &
fi
EOF
chmod +x /usr/local/bin/recorder

echo "--- 🔧 Servicios y Limpieza ---"
systemctl enable greetd
systemctl enable bluetooth
systemctl enable fstrim.timer
systemctl disable --now NetworkManager-wait-online.service 2>/dev/null || true
systemctl disable getty@tty1 2>/dev/null || true
systemctl mask getty@tty1 2>/dev/null || true

if [[ -w /sys/class/power_supply/BAT0/charge_control_start_threshold &&
      -w /sys/class/power_supply/BAT0/charge_control_end_threshold ]]; then
    echo 70 > /sys/class/power_supply/BAT0/charge_control_start_threshold
    echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold
    cat > /etc/systemd/system/battery-charge-limit.service <<'EOF'
[Unit]
Description=Límite de carga de batería al 80%
After=sysfs.mount

[Service]
Type=oneshot
ExecStart=-/bin/sh -c 'echo 70 > /sys/class/power_supply/BAT0/charge_control_start_threshold'
ExecStart=-/bin/sh -c 'echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold'

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable battery-charge-limit.service
    systemctl restart battery-charge-limit.service
    log_info "Servicio persistente de batería creado: carga 70-80%"
fi

echo "--- Firewall ---"
ufw default deny incoming
ufw default allow outgoing
ufw enable

# ELIMINAR PAQUETES BASURA SIN USO EN ESTE PORTÁTIL
echo "   Purgando soporte de impresoras, módems y RPC..."
apt -y purge cups cups-daemon cups-browsed modemmanager rpcbind 2>/dev/null || true

# PERMISOS DE USUARIO
echo "--- 👥 Configurando Permisos de Usuario ---"
REAL_USER=${SUDO_USER:-$(whoami)}
if [ "$REAL_USER" != "root" ]; then
    usermod -aG video,render "$REAL_USER"
    echo "✅ Usuario $REAL_USER añadido a grupos video y render."
else
    echo "⚠️ ADVERTENCIA: No se pudo detectar usuario real. Ejecuta 'sudo usermod -aG video,render TU_USUARIO' manualmente."
fi

apt autoremove -y
apt clean

echo "--- 🧠 Horneando Initramfs ---"
update-initramfs -u

echo "--- 🔎 Verificando configuración final ---"
test -f /etc/modprobe.d/i915.conf
grep -q 'enable_guc=3.*enable_fbc=1' /etc/modprobe.d/i915.conf
test -f /etc/default/zramswap
grep -q '^ALGO=zstd$' /etc/default/zramswap
grep -q '^SIZE=8192$' /etc/default/zramswap
grep -q '^vm.swappiness=150$' /etc/sysctl.d/99-zram.conf
test -f /etc/udev/rules.d/60-nvme-scheduler.rules
findmnt -n -o FSTYPE / | grep -qx 'btrfs'
findmnt -n -o OPTIONS / | grep -q 'subvol=/@'
log_info "Verificación BTRFS completada: subvolumen raíz @"
if systemctl list-unit-files battery-charge-limit.service >/dev/null 2>&1; then
    systemctl is-enabled battery-charge-limit.service
fi
if command -v fwupdmgr >/dev/null; then
    log_info "Inventario de firmware:"
    fwupdmgr get-devices 2>/dev/null | sed 's/^/  /' || true
fi
test -x /usr/local/bin/recorder
ufw status | grep -q 'Status: active'
systemctl is-active --quiet power-profiles-daemon
systemctl is-active --quiet thermald
systemctl is-active --quiet zramswap

echo "--- ✅ INSTALACIÓN COMPLETADA ---"
echo " REINICIA el sistema (sudo reboot)."
