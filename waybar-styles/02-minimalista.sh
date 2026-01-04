#!/bin/bash
# Waybar Style: Minimalista Clean
# Descripción: Diseño limpio, sin bordes, espaciado generoso, muy profesional
# Ideal para: Trabajo productivo, reducción de distracciones

if [ -z "$HOME" ]; then
  echo "❌ HOME no definida"
  exit 1
fi

TARGET_DIR="$HOME/.config/waybar"
mkdir -p "$TARGET_DIR"

echo "✨ Aplicando estilo Minimalista Clean..."

# Escribimos a un archivo temporal y validamos JSON antes de sobrescribir
TMP_CFG="$(mktemp)"
cat > "$TMP_CFG" <<'EOFCONFIG'
{
    "layer": "top",
    "height": 36,
    "margin-top": 6,
    "margin-left": 8,
    "margin-right": 8,
    "modules-left": ["sway/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "custom/power", "battery", "tray"],
    
    "sway/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{name}",
        "format-icons": {
            "1": "",
            "2": "",
            "3": "",
            "4": "",
            "5": "",
            "urgent": "",
            "focused": "",
            "default": ""
        }
    },
    "clock": {
        "format": " {:%H:%M   %d/%m}",
        "format-alt": "{:%A, %d %B %Y}",
        "tooltip-format": "<big>{:%B %Y}</big>\n<tt>{calendar}</tt>",
        "interval": 60
    },
    "cpu": {
        "format": "CPU {usage}%",
        "interval": 2
    },
    "memory": {
        "format": "RAM {percentage}%",
        "interval": 3
    },
    "network": {
        "format-wifi": " {essid}",
        "format-ethernet": " {ifname}",
        "format-disconnected": "⚠ Offline",
        "tooltip-format": "IP: {ipaddr}\nSignal: {signalStrength}%"
    },
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "🔇 {volume}%",
        "format-icons": { "default": ["", "", ""] },
        "on-click": "pavucontrol"
    },
    "battery": {
        "interval": 60,
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-charging": "󰂄 {capacity}%",
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
        "signal": 8
    }
}
EOFCONFIG

# Validar JSON y mover si es correcto
if command -v jq >/dev/null 2>&1; then
  if jq -e . "$TMP_CFG" >/dev/null 2>&1; then
    cp "$TARGET_DIR/config" "$TARGET_DIR/config.bak-$(date +%s)" 2>/dev/null || true
    mv "$TMP_CFG" "$TARGET_DIR/config"
  else
    echo "❌ JSON inválido en Minimalista: no se aplicó la configuración"
    rm -f "$TMP_CFG"
  fi
elif python3 -c 'import json,sys
json.load(open(sys.argv[1]))' "$TMP_CFG" 2>/dev/null; then
  cp "$TARGET_DIR/config" "$TARGET_DIR/config.bak-$(date +%s)" 2>/dev/null || true
  mv "$TMP_CFG" "$TARGET_DIR/config"
else
  echo "⚠ No se pudo validar JSON (instala 'jq' o usa python3). Aplicando de todos modos."
  cp "$TARGET_DIR/config" "$TARGET_DIR/config.bak-$(date +%s)" 2>/dev/null || true
  mv "$TMP_CFG" "$TARGET_DIR/config"
fi

cat > "$TARGET_DIR/style.css" <<'EOFSTYLE'
/* Dark Minimalista — no animations */
* { margin: 0; padding: 0; font-family: "FontAwesome", "JetBrains Mono", sans-serif; font-size: 12px; }
window#waybar { background: rgba(18,18,18,0.95); color: #e6e6e6; padding: 6px 12px; }
#workspaces { margin-right: 18px; }
#workspaces button { padding: 4px 8px; color: #999; background: transparent; }
#workspaces button.focused { color: #00BCD4; border-bottom: 2px solid #00BCD4; }
#clock { font-weight: 600; margin-right: 16px; }
#cpu, #memory, #network, #pulseaudio, #battery, #custom-power { color: #d0d0d0; margin-right: 12px; }
#custom-power.performance { color: #ff6b6b; }
#custom-power.balanced { color: #00BCD4; }
#custom-power.power-saver { color: #26A65B; }
#tray { margin-left: 12px; }
EOFSTYLE

echo "✅ Estilo Minimalista Clean aplicado"
echo "💡 Reinicia Waybar: pkill waybar; sleep 0.5; waybar"
