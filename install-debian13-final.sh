#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# INSTALL DEBIAN 13 (TRIXIE) - V8.0 BULLETPROOF EDITION
# Hardware Target: Dell Inspiron 5584 (i7-8565U + Intel UHD 620 + NVMe)
# Stack: Sway + Tuigreet + Waybar
# Fixes included: WiFi Atheros, Latam Keyboard, Brightness Safety, NM Keyfile.
# -----------------------------------------------------------------------------

USER_NAME="${SUDO_USER:-${USER:-}}"
if [[ -z "$USER_NAME" ]]; then echo "❌ Ejecuta con sudo."; exit 1; fi
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

log(){ echo -e "\n\033[1;36m[+] $1\033[0m"; }

# --- FASE 1: BASE DE INGENIERÍA ---

log "1. Configurando repositorios (Non-free Firmware)"
if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
    sed -i.bak 's/Components: main.*/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources
elif [[ -f /etc/apt/sources.list ]]; then
    sed -i.bak 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
fi

log "2. Actualizando kernel y firmware"
apt update && apt -y full-upgrade
apt -y install curl build-essential pkg-config libglib2.0-bin xdg-user-dirs unzip

# CRÍTICO: rfkill para desbloqueo WiFi y microcódigo
KERNEL_VERSION=$(uname -r)
apt -y install \
  "linux-headers-$KERNEL_VERSION" \
  firmware-linux-nonfree \
  firmware-misc-nonfree \
  firmware-atheros \
  firmware-realtek \
  firmware-intel-sound \
  firmware-sof-signed \
  intel-microcode \
  mesa-utils \
  rfkill

# --- FASE 2: ENTORNO GRÁFICO (WAYLAND PURO) ---

log "3. Instalando Stack Sway"
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

# --- FASE 3: CORRECCIONES DE HARDWARE Y RED (CRÍTICO) ---

log "4. Blindando NetworkManager (Fix 'Unmanaged')"
# Forzar uso de keyfile y eliminar gestión legacy
cat > /etc/NetworkManager/NetworkManager.conf <<EOF
[main]
plugins=keyfile

[ifupdown]
managed=true
EOF

# Backup y anulación de interfaces antiguas para liberar la tarjeta WiFi
if [[ -f /etc/network/interfaces ]]; then
    mv /etc/network/interfaces /etc/network/interfaces.bak
    echo "# Gestionado por NetworkManager" > /etc/network/interfaces
fi

log "5. Optimizaciones Dell 5584"
# Intel Graphics: Habilitar GuC/HuC para ahorro de energía y performance
echo "options i915 enable_guc=2 enable_fbc=1 fastboot=1" > /etc/modprobe.d/i915.conf

# Ahorro de energía PCIe (Fix errores de log)
echo "options pcie_aspm policy=performance" > /etc/modprobe.d/pcie_aspm.conf

# Regla Udev para Brillo (Permisos sin reiniciar)
echo 'ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"' > /etc/udev/rules.d/90-backlight.rules

# Deshabilitar SSH por defecto (Seguridad)
systemctl disable ssh

# Servicios Base
systemctl enable --now greetd
systemctl enable --now bluetooth
systemctl enable --now fstrim.timer

# Limpieza de conflictos de Login
systemctl disable --now getty@tty1 2>/dev/null || true
systemctl mask getty@tty1 2>/dev/null || true

# --- FASE 4: DOTFILES (CONFIGURACIÓN DE USUARIO) ---

log "6. Generando Configuración"
sudo -u "$USER_NAME" xdg-user-dirs-update
sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.config"/{sway,waybar,wofi,mako,kitty}

# 6.1 SWAY CONFIG (Fix: Latam + Numpad + Brillo Seguro)
cat > "$USER_HOME/.config/sway/config" <<EOF
# --- SWAY CONFIG V8.0 ---
set \$mod Mod4
set \$term kitty
set \$menu wofi --show drun --allow-images

font pango:Inter 11

# FIX: Teclado Latinoamericano + Numpad activo
input * {
    xkb_layout latam
    xkb_numlock enabled
    dwt enabled
    tap enabled
    natural_scroll enabled
    middle_emulation enabled
}

output eDP-1 scale 1
output * bg /usr/share/images/desktop-base/default fill

default_border pixel 2
gaps inner 6
gaps outer 0
client.focused          #00BCD4 #263238 #FFFFFF #00BCD4 #00BCD4

exec_always --no-startup-id waybar
exec --no-startup-id /usr/bin/lxpolkit
exec --no-startup-id mako
exec --no-startup-id nm-applet --indicator
exec --no-startup-id blueman-applet
exec --no-startup-id udiskie --tray

# Temas GTK
set \$gnome-schema org.gnome.desktop.interface
exec_always {
    gsettings set \$gnome-schema gtk-theme 'Arc-Dark'
    gsettings set \$gnome-schema icon-theme 'Papirus-Dark'
    gsettings set \$gnome-schema cursor-theme 'DMZ-White'
    gsettings set \$gnome-schema color-scheme 'prefer-dark'
}

# Atajos
bindsym \$mod+Return exec \$term
bindsym \$mod+space exec \$menu
bindsym \$mod+w exec chromium
bindsym \$mod+f exec GDK_BACKEND=wayland thunar
bindsym \$mod+Shift+q kill
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Salir?' -b 'Si' 'swaymsg exit'
bindsym \$mod+Shift+c reload
bindsym \$mod+r mode "resize"

# Navegación
bindsym \$mod+Left focus left
bindsym \$mod+Down focus down
bindsym \$mod+Up focus up
bindsym \$mod+Right focus right
bindsym \$mod+Shift+Left move left
bindsym \$mod+Shift+Down move down
bindsym \$mod+Shift+Up move up
bindsym \$mod+Shift+Right move right

# Workspaces
bindsym \$mod+1 workspace number 1
bindsym \$mod+2 workspace number 2
bindsym \$mod+3 workspace number 3
bindsym \$mod+4 workspace number 4
bindsym \$mod+Shift+1 move container to workspace number 1
bindsym \$mod+Shift+2 move container to workspace number 2
bindsym \$mod+Shift+3 move container to workspace number 3
bindsym \$mod+Shift+4 move container to workspace number 4

# Multimedia
bindsym Print exec grim -g "\$(slurp)" - | swappy -f -
bindsym XF86AudioRaiseVolume exec pamixer -i 5
bindsym XF86AudioLowerVolume exec pamixer -d 5
bindsym XF86AudioMute exec pamixer -t
bindsym XF86AudioMicMute exec pamixer --default-source -t
bindsym XF86AudioPlay exec playerctl play-pause

# FIX: Brillo con Suelo de Seguridad (Nunca baja del 1%)
bindsym XF86MonBrightnessUp exec brightnessctl --device='intel_backlight' set +5%
bindsym XF86MonBrightnessDown exec sh -c "brightnessctl --device='intel_backlight' set 5%-; if [ \$(brightnessctl --device='intel_backlight' get) -eq 0 ]; then brightnessctl --device='intel_backlight' set 1%; fi"
EOF

# 6.2 WOFI STYLE
cat > "$USER_HOME/.config/wofi/style.css" <<EOF
window { margin: 0px; border: 2px solid #00BCD4; background-color: #1a1a1a; border-radius: 8px; font-family: "JetBrains Mono"; font-size: 14px; }
#input { margin: 5px; border-radius: 4px; border: none; color: #ffffff; background-color: #2b2b2b; }
#entry:selected { background-color: #00BCD4; border-radius: 4px; font-weight: bold; }
EOF

# 6.3 WAYBAR CONFIG (Fix: JSON Validado + Emoji Mute)
cat > "$USER_HOME/.config/waybar/config" <<EOF
{
    "layer": "top",
    "height": 34,
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "battery", "tray"],
    "sway/workspaces": { "disable-scroll": true, "format": "{name}" },
    "clock": { "format": " {:%H:%M   %d/%m}", "tooltip-format": "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>" },
    "cpu": { "format": " {usage}%" },
    "memory": { "format": " {}%" },
    "network": { "format-wifi": "", "format-ethernet": "", "format-disconnected": "⚠", "tooltip-format": "{essid} ({signalStrength}%)" },
    "pulseaudio": { "format": "{icon} {volume}%", "format-muted": "🔇 {volume}%", "format-icons": { "default": ["", "", ""] }, "on-click": "pavucontrol" },
    "battery": { "interval": 60, "states": { "warning": 30, "critical": 15 }, "format": "{capacity}% {icon}", "format-icons": ["", "", "", "", ""] }
}
EOF

# 6.4 WAYBAR STYLE (Fix: FontAwesome Priority)
cat > "$USER_HOME/.config/waybar/style.css" <<EOF
* { border: none; border-radius: 0; font-family: "FontAwesome", "JetBrains Mono", sans-serif; font-size: 14px; min-height: 0; }
window#waybar { background-color: rgba(26, 26, 26, 0.95); color: #ffffff; border-bottom: 2px solid #00BCD4; }
#workspaces button.focused { background-color: #333333; color: #00BCD4; border-bottom: 2px solid #00BCD4; }
#battery.warning { color: #ffeb3b; }
#battery.critical { color: #ff5555; animation-name: blink; animation-duration: 0.5s; }
@keyframes blink { to { color: #ffffff; } }
EOF

# 6.5 KITTY CONFIG
cat > "$USER_HOME/.config/kitty/kitty.conf" <<EOF
font_family JetBrains Mono
font_size 11.0
background_opacity 0.95
EOF

# 6.6 LOGIN (Tuigreet Robust Path)
TUIGREET_PATH=$(which tuigreet || echo "/usr/bin/tuigreet")
mkdir -p /etc/greetd
cat > /etc/greetd/config.toml <<EOF
[terminal]
vt = 1
[default_session]
command = "$TUIGREET_PATH --cmd sway --time --remember --remember-session"
user = "_greetd"
EOF

# Permisos Finales
usermod -aG video,render _greetd 2>/dev/null || true
usermod -aG video "$USER_NAME"
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config"

log "✅ INSTALACIÓN V8.0 COMPLETADA"
log "   1. Reinicia el sistema."
log "   2. Si el WiFi está apagado, usa 'Fn+F2'."
log "   3. Conéctate con 'nmtui'."
log "   4. Instala ZRAM manualmente con: sudo apt install zram-tools"
