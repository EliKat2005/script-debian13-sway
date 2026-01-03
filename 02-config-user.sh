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
# --- 1. VARIABLES ---
set $mod Mod4
set $term kitty

# --no-custom evita problemas de foco en wofi
set $menu wofi --show drun --allow-images --no-custom
font pango:Inter 11

# --- 2. ENTORNO Y PORTALES ---
# Necesario para compartir pantalla (OBS/Discord) y temas
exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# --- 3. INPUT (TECLADO/MOUSE) ---
input * {
    xkb_layout latam
    xkb_numlock enabled
    dwt enabled
    tap enabled
    natural_scroll enabled
    middle_emulation enabled
}

# --- 4. OUTPUT (FONDO) ---
output * bg /usr/share/images/desktop-base/default fill

# --- 5. APARIENCIA ---
default_border pixel 2
gaps inner 6
gaps outer 0

# Colores del borde y ventanas
# Class                 Border  Bground Text    Indicator ChildBorder
client.focused          #00BCD4 #263238 #FFFFFF #00BCD4   #00BCD4
client.focused_inactive #333333 #5f676a #ffffff #484e50   #5f676a
client.unfocused        #333333 #222222 #888888 #292d2e   #222222
client.urgent           #2f343a #900000 #ffffff #900000   #900000

# Forzar tema oscuro en aplicaciones GTK
set $gnome-schema org.gnome.desktop.interface
exec_always {
    gsettings set $gnome-schema gtk-theme 'Arc-Dark'
    gsettings set $gnome-schema icon-theme 'Papirus-Dark'
    gsettings set $gnome-schema cursor-theme 'DMZ-White'
    gsettings set $gnome-schema color-scheme 'prefer-dark'
}

# --- 6. AUTOSTART (INICIO) ---
# Waybar: Reiniciar para evitar duplicados
exec_always sh -c "pkill waybar; sleep 0.5; waybar"

# Polkit y notificaciones
exec --no-startup-id /usr/bin/lxpolkit
exec --no-startup-id mako

# Applets de bandeja
exec --no-startup-id nm-applet --indicator
exec --no-startup-id blueman-applet
exec --no-startup-id udiskie --tray

# GESTION DE ENERGIA (Swayidle + Swaylock)
# 300s (5min) -> apagar pantalla. Al volver -> encender. Antes de dormir -> bloquear.
exec swayidle -w \
    timeout 300 'swaymsg "output * power off"' \
    resume 'swaymsg "output * power on"' \
    before-sleep 'swaylock -f -c 000000'

# --- 7. REGLAS DE VENTANAS (FLOATING) ---
# Calculadora
for_window [app_id="galculator"] floating enable, resize set 350 500, move position center

# Ventanas de sistema que deben flotar
for_window [app_id="pavucontrol"] floating enable
for_window [app_id="blueman-manager"] floating enable
for_window [app_id="nm-connection-editor"] floating enable
for_window [app_id="wdisplays"] floating enable
for_window [title="File Operation Progress"] floating enable
for_window [app_id="lxpolkit"] floating enable

# --- 8. ATAJOS DE TECLADO ---
# Aplicaciones Basicas
bindsym $mod+Return exec $term
bindsym $mod+space exec $menu
bindsym $mod+w exec chromium

# Explorador de archivos (Ranger en Kitty con fix de EDITOR)
bindsym $mod+f exec env EDITOR=micro kitty -e ranger
bindsym $mod+p exec wdisplays

# Sistema Sway
bindsym $mod+q kill
bindsym $mod+Shift+e exec swaynag -t warning -m 'Salir?' -b 'Sí' 'swaymsg exit'
bindsym $mod+Shift+c reload

# MODO RESIZE (Faltaba definir el bloque)
bindsym $mod+r mode "resize"
mode "resize" {
    bindsym Left resize shrink width 10px
    bindsym Down resize grow height 10px
    bindsym Up resize shrink height 10px
    bindsym Right resize grow width 10px

    # Salir del modo resize con Escape o Enter
    bindsym Return mode "default"
    bindsym Escape mode "default"
}

# GESTION DE VENTANAS
bindsym $mod+v splitv
bindsym $mod+h splith

# FLOTANTE: Alternar estado de la ventana actual
bindsym $mod+Shift+space floating toggle

# PANTALLA COMPLETA
bindsym $mod+Shift+f fullscreen toggle

# SCRATCHPAD (Papelera temporal / Segundo plano)
# Enviar ventana activa al fondo (ocultar)
bindsym $mod+minus move scratchpad

# Traer ventana del fondo (mostrar)
bindsym $mod+Shift+minus scratchpad show

# Navegacion (Foco)
bindsym $mod+Left focus left
bindsym $mod+Right focus right
bindsym $mod+Up focus up
bindsym $mod+Down focus down

# Mover ventanas (Cambiar de lugar dentro del mismo escritorio)
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Right move right
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Down move down

# Espacios de trabajo (1-4)
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5

# Mover ventanas a espacios
bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5

# --- 9. MULTIMEDIA Y HARDWARE ---
# Capturas (Grim + Slurp + Swappy)
bindsym Print exec grim -g "$(slurp)" - | swappy -f -

# Audio (Volumen y Multimedia)
bindsym XF86AudioRaiseVolume exec pamixer -i 5
bindsym XF86AudioLowerVolume exec pamixer -d 5
bindsym XF86AudioMute exec pamixer -t
bindsym XF86AudioMicMute exec pamixer --default-source -t
bindsym XF86AudioPlay exec playerctl play-pause
bindsym XF86Calculator exec galculator

# Brillo (Intel/Dell - Con proteccion de pantalla negra)
bindsym XF86MonBrightnessUp exec brightnessctl --device='intel_backlight' set +5%
# Nota: -n limita el brillo mínimo para no quedar a ciegas
bindsym XF86MonBrightnessDown exec brightnessctl --device='intel_backlight' set 5%- -n 1
EOF

# --- NUEVO: Script de Gestión de Energía (Optimizado con Señales) ---
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

# 4. Waybar Config (V10 Final: Batería + Energía + Signal 8)
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

/* GESTOR DE ENERGÍA */
#custom-power { padding: 0 10px; margin: 0 4px; background-color: rgba(255, 255, 255, 0.05); border-radius: 4px; }
#custom-power.performance { color: #ff5555; }
#custom-power.balanced { color: #00BCD4; }
#custom-power.power-saver { color: #26A65B; }
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
