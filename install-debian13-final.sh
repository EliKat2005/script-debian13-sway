#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# INSTALL DEBIAN 13 (TRIXIE) - ENGINEER EDITION (V7.0 FINAL GOLD)
# Hardware Target: Dell Inspiron 5584 (i7-8565U + Intel UHD 620 + 8GB RAM)
# Stack: Sway + Tuigreet + Waybar + ZRAM
# Philosophy: 100% Official Repos, Robust Config, No External Downloads.
# -----------------------------------------------------------------------------

USER_NAME="${SUDO_USER:-${USER:-}}"
if [[ -z "$USER_NAME" ]]; then echo "❌ Ejecuta con sudo."; exit 1; fi
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

log(){ echo -e "\n\033[1;36m[+] $1\033[0m"; }

# --- FASE 1: BASE DEL SISTEMA ---

log "1. Configurando repositorios (Contrib + Non-free)"
if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
    sed -i.bak 's/Components: main.*/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources
elif [[ -f /etc/apt/sources.list ]]; then
    sed -i.bak 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
fi

log "2. Actualizando sistema"
apt update && apt -y full-upgrade
apt -y install curl build-essential pkg-config libglib2.0-bin xdg-user-dirs unzip

log "3. Instalando Firmware, Kernel y Herramientas"
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
  zram-tools

# --- FASE 2: ENTORNO GRÁFICO (WAYLAND) ---

log "4. Instalando Stack Sway (SOLO REPOS OFICIALES)"
PKGS_SWAY=(
  # Core
  sway swaybg swayidle swaylock
  
  # Componentes
  waybar                # Barra
  wofi                  # Launcher
  mako-notifier         # Notificaciones
  grim slurp swappy     # Screenshots
  wl-clipboard          # Portapapeles
  wdisplays             # Pantallas
  
  # Portals
  xdg-desktop-portal-wlr
  xdg-desktop-portal-gtk
  
  # Login & Auth
  greetd
  tuigreet              # Paquete oficial
  lxpolkit              # Auth Agent
  
  # Apps
  kitty                 # Terminal
  thunar                # Archivos
  thunar-archive-plugin thunar-volman gvfs-backends
  xarchiver zip p7zip-full unrar-free
  chromium              # Navegador
  micro ranger          # CLI
  mpv zathura           # Multimedia
  
  # Utilidades
  brightnessctl pamixer playerctl
  btop nm-connection-editor blueman network-manager-gnome
  
  # Audio
  pipewire pipewire-pulse wireplumber pavucontrol
  libspa-0.2-bluetooth
  
  # Fuentes e Iconos (CRÍTICO: FontAwesome 4.7 + Emojis)
  fonts-inter
  fonts-jetbrains-mono
  fonts-font-awesome    
  fonts-noto-color-emoji
  papirus-icon-theme arc-theme
  desktop-base dmz-cursor-theme
  
  # QT Support
  qt5ct qt6ct qtwayland5
)

apt -y --no-install-recommends install "${PKGS_SWAY[@]}"

# --- FASE 3: OPTIMIZACIÓN DE HARDWARE ---

log "5. Configurando ZRAM (LZ4)"
# Configuración optimizada para 8GB RAM
sed -i 's/^#*\s*ALGO=.*/ALGO=lz4/' /etc/default/zramswap || true
sed -i 's/^#*\s*PERCENT=.*/PERCENT=50/' /etc/default/zramswap || true
systemctl restart zramswap.service

log "6. Parches de Hardware (Dell 5584)"
# WiFi Atheros estable
echo "options ath10k_pci irq_mode=legacy" > /etc/modprobe.d/ath10k.conf
# Ahorro de energía PCIe
echo "options pcie_aspm policy=performance" > /etc/modprobe.d/pcie_aspm.conf
# Intel Graphics optimizado
echo "options i915 enable_guc=2 enable_fbc=1 fastboot=1" > /etc/modprobe.d/i915.conf

# GRUB (PCIe errors fix)
if ! grep -q "pci=noaer" /etc/default/grub; then
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 pci=noaer pcie_aspm=off"/' /etc/default/grub
  update-grub
fi

# Servicios
systemctl enable --now bluetooth
systemctl enable --now greetd
systemctl set-default graphical.target

# Limpieza de conflictos de Display Manager
systemctl disable --now getty@tty1 2>/dev/null || true
systemctl mask getty@tty1 2>/dev/null || true

# --- FASE 4: CONFIGURACIÓN DE USUARIO ---

log "7. Generando Configuración (Dotfiles)"
sudo -u "$USER_NAME" xdg-user-dirs-update
sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.config/sway"
sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.config/waybar"
sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.config/wofi"
sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.config/mako"
sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.config/kitty"

# 7.1 SWAY CONFIG
cat > "$USER_HOME/.config/sway/config" <<EOF
# --- SWAY CONFIG (ENGINEER EDITION) ---
set \$mod Mod4
set \$term kitty
set \$menu wofi --show drun --allow-images

font pango:Inter 11

input "type:touchpad" {
    dwt enabled
    tap enabled
    natural_scroll enabled
    middle_emulation enabled
}
input "type:keyboard" { xkb_layout es }

output eDP-1 scale 1
output * bg /usr/share/images/desktop-base/default fill

default_border pixel 2
gaps inner 6
gaps outer 0
client.focused          #00BCD4 #263238 #FFFFFF #00BCD4 #00BCD4
seat seat0 xcursor_theme DMZ-White 24

# Temas GTK
exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
set \$gnome-schema org.gnome.desktop.interface
exec_always {
    gsettings set \$gnome-schema gtk-theme 'Arc-Dark'
    gsettings set \$gnome-schema icon-theme 'Papirus-Dark'
    gsettings set \$gnome-schema cursor-theme 'DMZ-White'
    gsettings set \$gnome-schema color-scheme 'prefer-dark'
}

# Autostart Esencial
exec --no-startup-id /usr/bin/lxpolkit
exec --no-startup-id mako
exec --no-startup-id nm-applet --indicator
exec --no-startup-id blueman-applet
exec --no-startup-id udiskie --tray

# Waybar: Ejecución independiente y robusta
exec_always --no-startup-id waybar

# Atajos
bindsym \$mod+Return exec \$term
bindsym \$mod+space exec \$menu
bindsym \$mod+w exec chromium
bindsym \$mod+f exec GDK_BACKEND=wayland thunar
bindsym \$mod+Shift+q kill
bindsym \$mod+Shift+e exec swaynag -t warning -m '¿Salir?' -b 'Sí' 'swaymsg exit'

# Navegación y Windows
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
bindsym \$mod+5 workspace number 5
bindsym \$mod+Shift+1 move container to workspace number 1
bindsym \$mod+Shift+2 move container to workspace number 2
bindsym \$mod+Shift+3 move container to workspace number 3
bindsym \$mod+Shift+4 move container to workspace number 4
bindsym \$mod+Shift+5 move container to workspace number 5

# Multimedia
bindsym Print exec grim -g "\$(slurp)" - | swappy -f -
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
bindsym XF86AudioRaiseVolume exec pamixer -i 5
bindsym XF86AudioLowerVolume exec pamixer -d 5
bindsym XF86AudioMute exec pamixer -t
bindsym XF86AudioMicMute exec pamixer --default-source -t
bindsym XF86AudioPlay exec playerctl play-pause
bindsym \$mod+Shift+c reload
EOF

# 7.2 WOFI STYLE
cat > "$USER_HOME/.config/wofi/style.css" <<EOF
window {
    margin: 0px;
    border: 2px solid #00BCD4;
    background-color: #1a1a1a;
    border-radius: 8px;
    font-family: "JetBrains Mono", "Inter";
    font-size: 14px;
}
#input { margin: 5px; border-radius: 4px; border: none; color: #ffffff; background-color: #2b2b2b; }
#entry:selected { background-color: #00BCD4; border-radius: 4px; font-weight: bold; }
EOF

# 7.3 WAYBAR CONFIG (Versión Validada: Sin comas extra, Iconos FA 4.7)
cat > "$USER_HOME/.config/waybar/config" <<EOF
{
    "layer": "top",
    "height": 34,
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "battery", "tray"],
    "sway/workspaces": { "disable-scroll": true, "format": "{name}" },
    "clock": { 
        "format": " {:%H:%M   %d/%m}", 
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>" 
    },
    "cpu": { 
        "format": " {usage}%" 
    },
    "memory": { 
        "format": " {}%" 
    },
    "network": { 
        "format-wifi": "", 
        "format-ethernet": "", 
        "format-disconnected": "⚠", 
        "tooltip-format": "{essid} ({signalStrength}%)" 
    },
    "pulseaudio": { 
        "format": "{icon} {volume}%",
        "format-muted": "🔇 {volume}%",
        "format-icons": { "default": ["", "", ""] }, 
        "on-click": "pavucontrol" 
    },
    "battery": { 
        "interval": 60,
        "states": { "warning": 30, "critical": 15 }, 
        "format": "{capacity}% {icon}", 
        "format-full": "{capacity}% {icon}",
        "format-plugged": "{capacity}% ",
        "format-icons": ["", "", "", "", ""] 
    }
}
EOF

# 7.4 WAYBAR STYLE (Versión Validada: FontAwesome Primero)
cat > "$USER_HOME/.config/waybar/style.css" <<EOF
* { 
    border: none; 
    border-radius: 0; 
    /* FontAwesome PRIMERO para garantizar iconos, luego texto */
    font-family: "FontAwesome", "JetBrains Mono", sans-serif; 
    font-size: 14px; 
    min-height: 0; 
}
window#waybar { background-color: rgba(26, 26, 26, 0.95); color: #ffffff; border-bottom: 2px solid #00BCD4; }
#workspaces button { padding: 0 15px; color: #aaaaaa; }
#workspaces button.focused { background-color: #333333; color: #00BCD4; border-bottom: 2px solid #00BCD4; }
#clock, #battery, #cpu, #memory, #network, #pulseaudio, #tray { padding: 0 10px; margin: 0 2px; }
#battery.warning { color: #ffeb3b; }
#battery.critical { color: #ff5555; animation-name: blink; animation-duration: 0.5s; }
@keyframes blink { to { color: #ffffff; } }
EOF

# 7.5 KITTY CONFIG
cat > "$USER_HOME/.config/kitty/kitty.conf" <<EOF
font_family      JetBrains Mono
font_size 11.0
background_opacity 0.95
enable_audio_bell no
window_padding_width 4
EOF

# 7.6 LOGIN MANAGER (Configuración Dinámica Robusta)
log "Configurando Greetd (Tuigreet)..."
# Detectar ruta real para evitar fallos
TUIGREET_PATH=$(which tuigreet)
if [[ -z "$TUIGREET_PATH" ]]; then TUIGREET_PATH="/usr/bin/tuigreet"; fi

mkdir -p /etc/greetd
cat > /etc/greetd/config.toml <<EOF
[terminal]
vt = 1
[default_session]
command = "$TUIGREET_PATH --cmd sway --time --remember --remember-session"
user = "_greetd"
EOF

# Permisos para el usuario greeter (video/render)
usermod -aG video,render _greetd 2>/dev/null || true

# 7.7 STARSHIP (Opcional)
if command -v starship &> /dev/null; then
    if ! grep -q "starship init bash" "$USER_HOME/.bashrc"; then
        echo 'eval "$(starship init bash)"' >> "$USER_HOME/.bashrc"
    fi
fi

# 7.8 QT THEME
if ! grep -q "QT_QPA_PLATFORMTHEME" /etc/environment; then
    echo "QT_QPA_PLATFORMTHEME=qt5ct" >> /etc/environment
fi

log "8. Permisos Finales"
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config" "$USER_HOME/.bashrc"
usermod -aG video "$USER_NAME" # Para control de brillo

log "✅ INSTALACIÓN COMPLETADA V7.0 (GOLD)"
log "   Sistema listo para Dell Inspiron 5584"
log "   Reinicia para entrar con Tuigreet."
