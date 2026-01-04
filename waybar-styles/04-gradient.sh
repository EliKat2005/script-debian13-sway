#!/bin/bash
# Waybar Style: Gradient Modern
# Descripción: Degradados suaves, colores pasteles, diseño moderno y elegante
# Ideal para: Diseño gráfico, creatividad

if [ -z "$HOME" ]; then
  echo "❌ HOME no definida"
  exit 1
fi

TARGET_DIR="$HOME/.config/waybar"
mkdir -p "$TARGET_DIR"

echo "🎨 Aplicando estilo Gradient Modern..."

# Escribimos a un archivo temporal y validamos JSON antes de sobrescribir
TMP_CFG="$(mktemp)"
cat > "$TMP_CFG" <<'EOFCONFIG'
{
    "layer": "top",
    "height": 42,
    "margin-top": 8,
    "margin-left": 14,
    "margin-right": 14,
    "modules-left": ["sway/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "custom/power", "battery", "tray"],
    
    "sway/workspaces": { "disable-scroll": true, "all-outputs": true, "format": "{name}" },
    "clock": { "format": " {:%H:%M   %d/%m}", "format-alt": "{:%d/%m/%Y}", "tooltip-format": "<big>{:%B %Y}</big>\n<tt>{calendar}</tt>", "interval": 1 },
    "cpu": { "format": " {usage}%", "interval": 2 },
    "memory": { "format": " {percentage}%", "interval": 3 },
    "network": { "format-wifi": " {essid}", "format-ethernet": " {ifname}", "format-disconnected": "⚠ Offline", "tooltip-format": "IP: {ipaddr}" },
    "pulseaudio": { "format": "{icon} {volume}%", "format-muted": "🔇 Mute", "format-icons": { "default": ["", "", ""] }, "on-click": "pavucontrol" },
    "battery": { "interval": 60, "states": { "warning": 30, "critical": 15 }, "format": "{capacity}% {icon}", "format-charging": "󰂄 {capacity}%", "format-icons": ["", "", "", "", ""] },
    "custom/power": { "format": "{icon}", "format-icons": { "performance": "", "balanced": "", "power-saver": "" }, "return-type": "json", "exec": "~/.config/waybar/scripts/power-profiles.sh", "on-click": "~/.config/waybar/scripts/power-profiles.sh toggle", "interval": 30, "signal": 8 }
}
EOFCONFIG

cat > "$TARGET_DIR/style.css" <<'EOFSTYLE'
/* Gradient Modern — cleaned, dark-friendly, no stray heredocs */
* { border: none; border-radius: 8px; font-family: "FontAwesome", "JetBrains Mono", sans-serif; font-size: 12px; margin:0; padding:0; }
window#waybar { background: linear-gradient(90deg, rgba(12,12,14,0.9), rgba(20,20,30,0.9)); color: #e6eef8; border: 1px solid rgba(255,255,255,0.04); padding: 8px 14px; border-radius: 12px; }
#workspaces { background-color: transparent; margin-right: 20px; }
#workspaces button { padding: 6px 12px; color: rgba(230,230,250,0.6); background: transparent; font-weight: 600; }
#workspaces button.focused { background: linear-gradient(135deg, #7c3aed, #ec4899); color: #ffffff; box-shadow: 0 8px 20px rgba(124,58,237,0.18); }
#clock { color: #ffffff; padding: 8px 16px; margin: 0 12px; font-weight: 600; }
#cpu, #memory, #network, #pulseaudio, #battery, #custom-power { margin-right: 10px; color: #dbeafe; }
EOFSTYLE
