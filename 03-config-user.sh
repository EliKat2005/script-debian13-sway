#!/bin/bash
# Ejecutar como USUARIO NORMAL (NO SUDO).

echo "--- 🎨 FASE 3: PERSONALIZACIÓN ---"

if [ "$EUID" -eq 0 ]; then
  echo "❌ EJECUTAR SIN SUDO."
  exit 1
fi

USER_HOME=$HOME

# 1. Directorios y Carpetas Base
echo "--- 📁 Asegurando estructura de carpetas ---"
xdg-user-dirs-update --force
mkdir -p "$USER_HOME/.config"/{sway,waybar,wofi,mako,alacritty,xdg-desktop-portal,qt5ct,qt6ct}

# 2. Configuración Global de Perfil (Nano Default)
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
# --- SWAY CONFIG ---

# VARIABLES
set \$mod Mod4
set \$term alacritty
set \$menu wofi --show drun --allow-images --no-custom

# FUENTE
font pango:Inter 11

# ENTORNO
exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
seat seat0 xcursor_theme DMZ-White 24
xwayland disable

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
gaps inner 8
gaps outer 0
client.focused          #00BCD4 #263238 #FFFFFF #00BCD4   #00BCD4
client.focused_inactive #333333 #5f676a #ffffff #484e50   #5f676a
client.unfocused        #333333 #222222 #888888 #292d2e   #222222
client.urgent           #2f343a #900000 #ffffff #900000   #900000

# AUTOSTART
exec_always sh -c "pkill waybar; sleep 0.5; waybar"
exec --no-startup-id /usr/bin/lxpolkit
exec --no-startup-id mako
exec --no-startup-id nm-applet --indicator
exec --no-startup-id blueman-applet
exec --no-startup-id udiskie --tray --smart-tray
exec --no-startup-id thunar --daemon

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
# IMV flotante y centrado
for_window [app_id="imv"] floating enable, move position center

# ATAJOS
bindsym \$mod+Return exec \$term
bindsym \$mod+space exec \$menu
bindsym \$mod+w exec brave-browser
bindsym \$mod+f exec thunar
bindsym \$mod+p exec wdisplays

# GRABACIÓN
bindsym \$mod+Shift+r exec recorder

# CONTROL SWAY
bindsym \$mod+q kill
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+e exec wlogout

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
offset = { x = 0, y = 4 } # Añade interlineado extra para mejor lectura

[window]
opacity = 1.0
padding = { x = 24, y = 24 } # Margen interno generoso para no asfixiar el texto
decorations = "None"
dynamic_title = true

[colors.primary]
background = "#181818" # Un tono de oscuridad más profundo y elegante
foreground = "#e0e0e0" # Blanco roto para reducir la fatiga visual

# Paleta base para que 'ls' y comandos tengan colores armónicos
[colors.normal]
black   = "#181818"
red     = "#ff5555"
green   = "#26A65B"
yellow  = "#ffeb3b"
blue    = "#00BCD4"
magenta = "#b388ff"
cyan    = "#84ffff"
white   = "#e0e0e0"
EOF

# 6. Asociaciones de Archivos (Mimeapps)
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

# 7. Waybar y Scripts
echo "--- 🔋 Configurando Waybar ---"
mkdir -p "$USER_HOME/.config/waybar/scripts"

# Script Power Profiles
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

# Waybar Config
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
    "network": { "format-wifi": " {essid}", "format-ethernet": "", "format-disconnected": "⚠", "tooltip-format": "{essid} ({signalStrength}%)" },
    "pulseaudio": { "format": "{icon} {volume}%", "format-muted": "🔇 {volume}%", "format-icons": { "default": ["", "", ""] }, "on-click": "pavucontrol" },
    "battery": { 
        "interval": 60, 
        "states": { "warning": 30, "critical": 15 }, 
        "format": "{capacity}% {icon}", 
        "format-charging": "{capacity}% ",
        "format-plugged": "{capacity}% ",
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

# Waybar Style
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

# 8. Wofi Style
cat <<EOF > "$USER_HOME/.config/wofi/style.css"
window { margin: 0px; border: 2px solid #00BCD4; background-color: #181818; border-radius: 8px; font-family: "JetBrains Mono"; font-size: 14px; }
#input { margin: 10px; padding: 10px; border-radius: 4px; border: none; color: #e0e0e0; background-color: #2b2b2b; }
#inner-box { margin: 5px; }
#entry { padding: 8px; border-radius: 4px; }
#entry:selected { background-color: #00BCD4; color: #181818; font-weight: bold; }
EOF

# 9. Notificaciones Mako
echo "--- 🔔 Configurando Notificaciones Modernas ---"
mkdir -p "$USER_HOME/.config/mako"
cat <<EOF > "$USER_HOME/.config/mako/config"
# 1. Comportamiento
max-history=10
sort=-time
default-timeout=5000

# 2. Apariencia
font=Inter 11
background-color=#1a1a1a
text-color=#ffffff
width=350
height=150
max-visible=5
margin=10
padding=15
border-size=2
border-color=#00BCD4
border-radius=8
icons=1
max-icon-size=48
icon-location=left

# 3. Reglas
[urgency=critical]
border-color=#ff5555
default-timeout=0

[app-name=recorder]
border-color=#26A65B
default-timeout=3000
EOF

# Configuración de MPV para reproducir videos
echo "--- Configuración de MPV ---"
mkdir -p "$USER_HOME/.config/mpv"
cat <<EOF > "$USER_HOME/.config/mpv/mpv.conf"
# --- FIX GRÁFICO PARA WAYLAND E INTEL ---
vo=gpu
gpu-api=opengl
gpu-context=wayland

# --- RENDIMIENTO Y BATERÍA ---
# Activar decodificación por hardware (Intel VAAPI)
hwdec=auto
# Perfil optimizado para evitar desincronización de audio/video
profile=fast
EOF

# 10. CONFIGURACIÓN AUTOMÁTICA DE TEMAS
echo "--- 🎨 Aplicando Temas GTK y QT Automáticamente ---"
gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'DMZ-White'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Auto-configurar QT5CT para usar GTK2
mkdir -p "$USER_HOME/.config/qt5ct"
cat <<EOF > "$USER_HOME/.config/qt5ct/qt5ct.conf"
[Appearance]
icon_theme=Papirus-Dark
standard_dialogs=gtk2
style=gtk2
EOF

# Auto-configurar QT6CT
mkdir -p "$USER_HOME/.config/qt6ct"
cat <<EOF > "$USER_HOME/.config/qt6ct/qt6ct.conf"
[Appearance]
icon_theme=Papirus-Dark
standard_dialogs=gtk2
style=gtk2
EOF

# 11. Limpieza
systemctl --user mask evolution-source-registry.service
systemctl --user mask evolution-addressbook-factory.service
rm -f "$USER_HOME/.nvidia-settings-rc"

echo "--- ✅ FASE 3 COMPLETADA ---"
echo "Por favor, CIERRA SESIÓN y vuelve a entrar para aplicar todos los cambios."
