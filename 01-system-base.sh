#!/bin/bash
# Ejecutar como ROOT (sudo)

echo "--- 🚀 FASE 1: INSTALACIÓN MODULAR ---"

if [ "$EUID" -ne 0 ]; then
  echo "❌ EJECUTAR COMO ROOT (sudo)."
  exit 1
fi

# --- FUNCIÓN DE INSTALACIÓN SEGURA ---
install_pkg() {
    echo "--- 📦 Instalando bloque: $1 ---"
    apt -y install $2
    if [ $? -ne 0 ]; then
        echo "⚠️ ERROR CRÍTICO: Falló la instalación de $1. Verifica tu internet."
        sleep 3
    else
        echo "✅ Bloque $1 instalado correctamente."
    fi
}

# --- 1. REPOSITORIOS ---
echo "--- 📡 Configurando Repositorios (Contrib / Non-Free) ---"
SOURCES_FILE="/etc/apt/sources.list.d/debian.sources"

if [[ -f "$SOURCES_FILE" ]]; then
    cp "$SOURCES_FILE" "$SOURCES_FILE.bak_script"
    
    if ! grep -q "contrib" "$SOURCES_FILE" || ! grep -q "non-free " "$SOURCES_FILE"; then
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

echo "--- 🔄 Actualizando lista de paquetes... ---"
apt update && apt -y full-upgrade

# 2. Kernel y Firmware
install_pkg "FIRMWARE_KERNEL" "curl build-essential pkg-config libglib2.0-bin xdg-user-dirs unzip linux-headers-$(uname -r) firmware-linux-nonfree firmware-misc-nonfree firmware-atheros firmware-realtek firmware-intel-sound firmware-sof-signed intel-microcode"

# 3. Drivers Gráficos y Utilidades de Sistema
install_pkg "DRIVERS_INTEL" "mesa-utils rfkill intel-media-va-driver-non-free intel-gpu-tools vainfo"
install_pkg "UTILIDADES_SYS" "snapper inotify-tools git make wf-recorder libnotify-bin"

# 4. Entorno Sway (Core)
install_pkg "SWAY_CORE" "sway swaybg swayidle swaylock xwayland waybar wofi mako-notifier wlogout"

# 5. Utilidades de Escritorio
install_pkg "PORTALES_POLKIT" "grim slurp swappy wl-clipboard wdisplays xdg-desktop-portal-wlr xdg-desktop-portal-gtk greetd tuigreet lxpolkit"

# 6. Gestión de Archivos
install_pkg "ARCHIVOS" "alacritty thunar thunar-archive-plugin thunar-volman gvfs-backends xarchiver zip p7zip-full unrar-free tumbler ffmpegthumbnailer"

# 7. Aplicaciones Base
install_pkg "APPS_BASE" "chromium mpv gnome-disk-utility galculator imv zathura"

# 8. Audio, Red y Energía
install_pkg "AUDIO_RED" "brightnessctl pamixer playerctl btop nm-connection-editor blueman network-manager-gnome pipewire pipewire-pulse wireplumber pavucontrol libspa-0.2-bluetooth power-profiles-daemon fwupd thermald"

# 9. Temas y Apariencia
install_pkg "TEMAS_COMPAT" "fonts-inter fonts-jetbrains-mono fonts-font-awesome fonts-noto-color-emoji papirus-icon-theme arc-theme desktop-base dmz-cursor-theme qt5ct qt6ct qtwayland5 qt6-wayland openssh-server gtk2-engines-murrine gtk2-engines-pixbuf"
# --- CONFIGURACIONES DEL SISTEMA ---

echo "--- 🌍 Configurando Variables de Entorno ---"
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

echo "--- 🌐 Configurando NetworkManager ---"
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

echo "--- ⚡ Optimizaciones Hardware (Intel GuC/HuC) ---"
echo "options i915 enable_guc=2 enable_fbc=1 fastboot=1" > /etc/modprobe.d/i915.conf
echo "options pcie_aspm policy=performance" > /etc/modprobe.d/pcie_aspm.conf
# Regla para permitir cambiar brillo sin ser root
echo 'ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"' > /etc/udev/rules.d/90-backlight.rules

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
TARGET_DIR=\$(xdg-user-dir VIDEOS 2>/dev/null || echo \$HOME/Videos)
mkdir -p \"\$TARGET_DIR\"
VIDEO_FILE=\"\$TARGET_DIR/Screencast_\$(date +%Y%m%d_%H%M%S).mp4\"
DEVICE=\"/dev/dri/renderD128\"

# 2. Lógica de Conmutación
if pgrep -x \"wf-recorder\" > /dev/null; then
    pkill -SIGINT -x wf-recorder

    # Esperamos un momento a que cierre el archivo
    sleep 1
    notify-send \"🔴 Grabación Finalizada\" \"Guardado en: \$(basename \"\$TARGET_DIR\")\"
else
    # SI NO ESTÁ CORRIENDO: Iniciamos la grabación
    notify-send \"🟢 Grabando Pantalla\" \"Intel VAAPI (Full HD)\"
    wf-recorder --audio --codec h264_vaapi --device \"\$DEVICE\" --file \"\$VIDEO_FILE\" &
fi
EOF
chmod +x /usr/local/bin/recorder

echo "--- 🔧 Servicios y Limpieza ---"
systemctl disable ssh
systemctl enable greetd
systemctl enable bluetooth
systemctl enable fstrim.timer
systemctl disable getty@tty1 2>/dev/null || true
systemctl mask getty@tty1 2>/dev/null || true

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

echo "--- ✅ INSTALACIÓN COMPLETADA ---"
echo " REINICIA el sistema (sudo reboot)."
