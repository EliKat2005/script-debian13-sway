#!/bin/bash
# Ejecutar como USUARIO NORMAL (NO SUDO).

echo "--- 🎨 FASE 3: PERSONALIZACIÓN ---"

if [ "$EUID" -eq 0 ]; then
  echo "❌ EJECUTAR SIN SUDO."
  exit 1
fi

USER_HOME=$HOME

# 1. Directorios
echo "--- 📁 Creando carpetas ---"
xdg-user-dirs-update --force
mkdir -p "$USER_HOME/Downloads" "$USER_HOME/Documents" "$USER_HOME/Pictures" "$USER_HOME/Music" "$USER_HOME/Videos" "$USER_HOME/Desktop" "$USER_HOME/.config"
mkdir -p "$USER_HOME/.config"/{sway,waybar,wofi,mako,alacritty,xdg-desktop-portal}

# 2. Configuración Global de Perfil
if ! grep -q "export EDITOR=nano" "$USER_HOME/.profile"; then
    echo "export EDITOR=nano" >> "$USER_HOME/.profile"
    echo "export VISUAL=nano" >> "$USER_HOME/.profile"
fi

# 3. Portales
cat <<EOF > "$USER_HOME/.config/xdg-desktop-portal/portals.conf"
[preferred]
default=wlr;gtk
org.freedesktop.impl.portal.Settings=gtk
EOF

# 4. Sway Config
cat <<EOF > "$USER_HOME/.config/sway/config"
# --- SWAY CONFIG V11 ---

# VARIABLES
set \$mod Mod4
set \$term alacritty
set \$menu wofi --show drun --allow-images --no-custom

# FUENTE
font pango:Inter 11

# ENTORNO
exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# INPUT
input * {
    xkb_layout latam
    xkb_numlock enabled
    dwt enabled
    tap enabled
    natural_scroll enabled
    middle_emulation enabled
}
floating_modifier \$mod normal

# OUTPUT
output * bg /usr/share/images/desktop-base/default fill

# APARIENCIA
default_border pixel 2
gaps inner 6
gaps outer 0
client.focused          #00BCD4 #263238 #FFFFFF #00BCD4   #00BCD4
client.focused_inactive #333333 #5f676a #ffffff #484e50   #5f676a
client.unfocused        #333333 #222222 #888888 #292d2e   #222222
client.urgent           #2f343a #900000 #ffffff #900000   #900000

# TEMA GTK
set \$gnome-schema org.gnome.desktop.interface
exec_always {
    gsettings set \$gnome-schema gtk-theme 'Arc-Dark'
    gsettings set \$gnome-schema icon-theme 'Papirus-Dark'
    gsettings set \$gnome-schema cursor-theme 'DMZ-White'
    gsettings set \$gnome-schema color-scheme 'prefer-dark'
}

# AUTOSTART
exec_always sh -c "pkill waybar; sleep 0.5; waybar"
exec --no-startup-id /usr/bin/lxpolkit
exec --no-startup-id mako
exec --no-startup-id nm-applet --indicator
exec --no-startup-id blueman-applet
exec --no-startup-id udiskie --tray

# ENERGIA
exec swayidle -w timeout 300 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' timeout 600 'systemctl suspend' before-sleep 'swaylock -f -c 000000'

# REGLAS FLOTANTES
for_window [app_id="galculator"] floating enable, resize set 350 500, move position center
for_window [app_id="pavucontrol"] floating enable
for_window [app_id="blueman-manager"] floating enable
for_window [app_id="nm-connection-editor"] floating enable
for_window [app_id="wdisplays"] floating enable
for_window [app_id="lxpolkit"] floating enable
for_window [title="File Operation Progress"] floating enable
# IMV flotante
for_window [app_id="imv"] floating enable, move position center

# ATAJOS
bindsym \$mod+Return exec \$term
bindsym \$mod+space exec \$menu
bindsym \$mod+w exec chromium
bindsym \$mod+f exec \$term -e thunar
bindsym \$mod+p exec wdisplays

# GRABACIÓN (Script Global)
bindsym \$mod+Shift+r exec recorder

# CONTROL SWAY
bindsym \$mod+q kill
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Salir?' -b 'Sí' 'swaymsg exit'

# VENTANAS
bindsym \$mod+v splitv
bindsym \$mod+h splith
bindsym \$mod+Shift+space floating toggle
bindsym \$mod+Shift+f fullscreen toggle

# NAVEGACION
bindsym \$mod+Left focus left
bindsym \$mod+Right focus right
bindsym \$mod+Up focus up
bindsym \$mod+Down focus down
bindsym \$mod+Shift+Left move left
bindsym \$mod+Shift+Right move right
bindsym \$mod+Shift+Up move up
bindsym \$mod+Shift+Down move down

# ESPACIOS
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

# SCRATCHPAD
bindsym \$mod+minus move scratchpad
bindsym \$mod+Shift+minus scratchpad show

# RESIZE
bindsym \$mod+r mode "resize"
mode "resize" {
    bindsym Left resize shrink width 10px
    bindsym Down resize grow height 10px
    bindsym Up resize shrink height 10px
    bindsym Right resize grow width 10px
    bindsym Return mode "default"
    bindsym Escape mode "default"
}

# MULTIMEDIA
bindsym Print exec grim -g "\$(slurp)" - | swappy -f -
bindsym XF86AudioRaiseVolume exec pamixer -i 5
bindsym XF86AudioLowerVolume exec pamixer -d 5
bindsym XF86AudioMute exec pamixer -t
bindsym XF86AudioMicMute exec pamixer --default-source -t
bindsym XF86AudioPlay exec playerctl play-pause
bindsym XF86Calculator exec galculator
bindsym XF86MonBrightnessUp exec brightnessctl --device='intel_backlight' set +5%
bindsym XF86MonBrightnessDown exec brightnessctl --device='intel_backlight' set 5%- -n 1
EOF

# 5. Configuración ALACRITTY
cat <<EOF > "$USER_HOME/.config/alacritty/alacritty.toml"
[font]
size = 11.0
normal = { family = "JetBrains Mono", style = "Regular" }

[window]
opacity = 0.85
padding = { x = 10, y = 10 }
decorations = "None"
dynamic_title = true

[colors.primary]
background = "#1a1a1a"
foreground = "#ffffff"
EOF

# 6. Asociaciones de Archivos
echo "--- 📄 Asociando aplicaciones por defecto ---"
mkdir -p "$USER_HOME/.config"
cat <<EOF > "$USER_HOME/.config/mimeapps.list"
[Default Applications]
image/jpeg=imv.desktop
image/png=imv.desktop
image/gif=imv.desktop
image/webp=imv.desktop
application/pdf=org.pwmt.zathura.desktop
inode/directory=thunar.desktop
text/plain=alacritty.desktop
EOF

# 7. Waybar y Scripts Auxiliares
mkdir -p "$USER_HOME/.config/waybar/scripts"
cat <<EOF > "$USER_HOME/.config/waybar/scripts/power-profiles.sh"
#!/bin/bash
current=\$(powerprofilesctl get)
if [ "\$1" == "toggle" ]; then
    case \$current in
        performance) powerprofilesctl set balanced ;;
        balanced) powerprofilesctl set power-saver ;;
        power-saver) powerprofilesctl set performance ;;
    esac
    pkill -SIGRTMIN+8 waybar
    exit 0
fi
case \$current in
    performance) echo '{"text": "Perf", "alt": "performance", "class": "performance", "percentage": 100 }' ;;
    balanced) echo '{"text": "Bal", "alt": "balanced", "class": "balanced", "percentage": 50 }' ;;
    power-saver) echo '{"text": "Sav", "alt": "power-saver", "class": "power-saver", "percentage": 20 }' ;;
esac
EOF
chmod +x "$USER_HOME/.config/waybar/scripts/power-profiles.sh"

cat <<EOF > "$USER_HOME/.config/waybar/config"
{
    "layer": "top",
    "height": 34,
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "custom/power", "battery", "tray"],
    "sway/workspaces": { "disable-scroll": true, "format": "{name}" },
    "clock": { "format": " {:%H:%M   %d/%m}", "tooltip-format": "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>" },
    "cpu": { "format": " {usage}%" },
    "memory": { "format": " {}%" },
    "network": { "format-wifi": "", "format-ethernet": "", "format-disconnected": "⚠", "tooltip-format": "{essid} ({signalStrength}%)" },
    "pulseaudio": { "format": "{icon} {volume}%", "format-muted": "🔇 {volume}%", "format-icons": { "default": ["", "", ""] }, "on-click": "pavucontrol" },
    "battery": { 
        "interval": 60, 
        "states": { "warning": 30, "critical": 15 }, 
        "format": "{capacity}% {icon}", 
        "format-icons": ["", "", "", "", ""] 
    },
    "custom/power": {
        "format": "{icon}",
        "format-icons": { "performance": "", "balanced": "", "power-saver": "" },
        "return-type": "json",
        "exec": "~/.config/waybar/scripts/power-profiles.sh",
        "on-click": "~/.config/waybar/scripts/power-profiles.sh toggle",
        "interval": 30,
        "signal": 8,
        "tooltip": true
    }
}
EOF

cat <<EOF > "$USER_HOME/.config/waybar/style.css"
* { border: none; border-radius: 0; font-family: "FontAwesome", "JetBrains Mono", sans-serif; font-size: 14px; min-height: 0; }
window#waybar { background-color: rgba(26, 26, 26, 0.95); color: #ffffff; border-bottom: 2px solid #00BCD4; }
#clock, #pulseaudio, #network, #cpu, #memory, #battery, #tray {
    padding: 0 10px; margin: 0 4px; background-color: rgba(255, 255, 255, 0.05); border-radius: 4px;
}
#workspaces button.focused { background-color: #333333; color: #00BCD4; border-bottom: 2px solid #00BCD4; }
#battery.warning { color: #ffeb3b; }
#battery.critical { color: #ff5555; animation-name: blink; animation-duration: 0.5s; }
@keyframes blink { to { color: #ffffff; } }
#custom-power { padding: 0 10px; margin: 0 4px; background-color: rgba(255, 255, 255, 0.05); border-radius: 4px; }
#custom-power.performance { color: #ff5555; }
#custom-power.balanced { color: #00BCD4; }
#custom-power.power-saver { color: #26A65B; }
EOF

cat <<EOF > "$USER_HOME/.config/wofi/style.css"
window { margin: 0px; border: 2px solid #00BCD4; background-color: #1a1a1a; border-radius: 8px; font-family: "JetBrains Mono"; font-size: 14px; }
#input { margin: 5px; border-radius: 4px; border: none; color: #ffffff; background-color: #2b2b2b; }
#entry:selected { background-color: #00BCD4; border-radius: 4px; font-weight: bold; }
EOF

rm -f "$USER_HOME/.nvidia-settings-rc"

echo "--- ✅ FASE 3 COMPLETADA ---"
