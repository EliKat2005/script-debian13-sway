#!/bin/bash
# Waybar Style: Default Base Configuration
# Descripción: Tu configuración original base (funcionando correctamente)
# Versión: Original V8

if [ -z "$HOME" ]; then
  echo "❌ HOME no definida"
  exit 1
fi

TARGET_DIR="$HOME/.config/waybar"
mkdir -p "$TARGET_DIR"

echo "🔵 Aplicando configuración DEFAULT (Base Original)..."

# === CONFIGURACIÓN WAYBAR (CONFIG JSON) ===
cat > "$TARGET_DIR/config" <<'EOFCONFIG'
{
    "layer": "top",
    "height": 34,
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "battery", "custom/power", "tray"],
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
        "format-icons": {
            "performance": "",
            "balanced": "",
            "power-saver": ""
        },
        "return-type": "json",
        "exec": "~/.config/waybar/scripts/power-profiles.sh",
        "on-click": "~/.config/waybar/scripts/power-profiles.sh toggle",
        "interval": 30,
        "signal": 8,
        "tooltip": true
    }
}
EOFCONFIG

# === ESTILO CSS (STYLE.CSS) ===
cat > "$TARGET_DIR/style.css" <<'EOFSTYLE'
/* Estilo V8 con corrección de espaciado - CONFIGURACIÓN BASE ORIGINAL */
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
EOFSTYLE

echo "✅ Configuración DEFAULT aplicada correctamente"
echo "💡 Reinicia Waybar: pkill waybar; sleep 0.5; waybar"
