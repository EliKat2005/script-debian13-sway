#!/bin/bash
# 03-config-user.sh - V10
# Misión: Configurar entorno de usuario, arreglar brillo y waybar.
# Ejecutar como USUARIO NORMAL (NO SUDO).

echo "--- 🎨 FASE 3: PERSONALIZACIÓN V8 + FIXES ---"

if [ "$EUID" -eq 0 ]; then
  echo "❌ EJECUTAR SIN SUDO."
  exit 1
fi

USER_HOME=$HOME

# 1. Carpetas
xdg-user-dirs-update
mkdir -p "$USER_HOME/.config"/{sway,waybar,wofi,mako,kitty,xdg-desktop-portal}

# 2. Portales (Fix Waybar Timeout)
cat <<EOF > "$USER_HOME/.config/xdg-desktop-portal/portals.conf"
[preferred]
default=wlr;gtk
org.freedesktop.impl.portal.Settings=gtk
EOF

# 3. Sway Config (V8 + Fixes Brillo/Waybar)
cat <<EOF > "$USER_HOME/.config/sway/config"
# --- SWAY CONFIG V10 ---
set \$mod Mod4
set \$term kitty
set \$menu wofi --show drun --allow-images

font pango:Inter 11

# Variables para Nvidia/Portales
exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
exec systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# Fix: Teclado Latam + Numpad
input * {
    xkb_layout latam
    xkb_numlock enabled
    dwt enabled
    tap enabled
    natural_scroll enabled
    middle_emulation enabled
}

output * bg /usr/share/images/desktop-base/default fill

default_border pixel 2
gaps inner 6
gaps outer 0
client.focused #00BCD4 #263238 #FFFFFF #00BCD4 #00BCD4

# INICIO AUTOMÁTICO (Waybar con delay de seguridad)
exec_always sh -c "pkill waybar; sleep 1; waybar"
exec --no-startup-id /usr/bin/lxpolkit
exec --no-startup-id mako
exec --no-startup-id nm-applet --indicator
exec --no-startup-id blueman-applet
exec --no-startup-id udiskie --tray

# Temas GTK (V8)
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
bindsym \$mod+f exec thunar
bindsym \$mod+Shift+q kill
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Salir?' -b 'Sí' 'swaymsg exit'
bindsym \$mod+Shift+c reload
bindsym \$mod+r mode "resize"

# Navegación
bindsym \$mod+Left focus left
bindsym \$mod+Right focus right
bindsym \$mod+Up focus up
bindsym \$mod+Down focus down
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

# Subir brillo (5%)
bindsym XF86MonBrightnessUp exec brightnessctl --device='intel_backlight' set +5%

# Bajar brillo (Protección: Mínimo 2400/2% para evitar pantalla negra)
bindsym XF86MonBrightnessDown exec brightnessctl --device='intel_backlight' set 5%- -n 2400
EOF

# 4. Waybar Config (V8 JSON + CSS Mejorado)
cat <<EOF > "$USER_HOME/.config/waybar/config"
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

cat <<EOF > "$USER_HOME/.config/waybar/style.css"
/* Estilo V8 con corrección de espaciado */
* { border: none; border-radius: 0; font-family: "FontAwesome", "JetBrains Mono", sans-serif; font-size: 14px; min-height: 0; }
window#waybar { background-color: rgba(26, 26, 26, 0.95); color: #ffffff; border-bottom: 2px solid #00BCD4; }
#clock, #pulseaudio, #network, #cpu, #memory, #battery, #tray {
    padding: 0 10px; margin: 0 4px; background-color: rgba(255, 255, 255, 0.05); border-radius: 4px;
}
#workspaces button.focused { background-color: #333333; color: #00BCD4; border-bottom: 2px solid #00BCD4; }
#battery.warning { color: #ffeb3b; }
#battery.critical { color: #ff5555; animation-name: blink; animation-duration: 0.5s; }
@keyframes blink { to { color: #ffffff; } }
EOF

# 5. Kitty Config (V8)
cat <<EOF > "$USER_HOME/.config/kitty/kitty.conf"
font_family JetBrains Mono
font_size 11.0
background_opacity 0.95
EOF

# 6. Wofi Style (V8)
cat <<EOF > "$USER_HOME/.config/wofi/style.css"
window { margin: 0px; border: 2px solid #00BCD4; background-color: #1a1a1a; border-radius: 8px; font-family: "JetBrains Mono"; font-size: 14px; }
#input { margin: 5px; border-radius: 4px; border: none; color: #ffffff; background-color: #2b2b2b; }
#entry:selected { background-color: #00BCD4; border-radius: 4px; font-weight: bold; }
EOF

# 7. Alias
echo "--- ⌨️ Añadiendo Alias ---"
if ! grep -q "alias nvgame=" ~/.bashrc; then
  echo "alias update='sudo apt update && sudo apt full-upgrade && sudo apt autoremove -y'" >> ~/.bashrc
  echo "alias nvgame='nv'" >> ~/.bashrc
  echo "alias gpu='nvidia-smi'" >> ~/.bashrc
fi

echo "--- ✅ FASE 3 COMPLETADA ---"
echo "Todo listo. Disfruta tu Dell 5584 Optimizado."
