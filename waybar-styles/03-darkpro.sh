#!/bin/bash
# Waybar Style: Dark Pro
# Descripción: Tema oscuro profesional, bordes sutiles, colores corporativos
# Ideal para: Programadores, profesionales

if [ -z "$HOME" ]; then
  echo "❌ HOME no definida"
  exit 1
fi

TARGET_DIR="$HOME/.config/waybar"
mkdir -p "$TARGET_DIR"

echo "🌙 Aplicando estilo Dark Pro..."

# Escribimos a un archivo temporal y validamos JSON antes de sobrescribir
TMP_CFG="$(mktemp)"
cat > "$TMP_CFG" <<'EOFCONFIG'
{
  "layer": "top",
  "height": 38,
  "margin-top": 6,
  "margin-left": 10,
  "margin-right": 10,
  "modules-left": ["sway/workspaces", "sway/mode"],
  "modules-center": ["clock"],
  "modules-right": ["pulseaudio", "network", "cpu", "memory", "custom/power", "battery", "tray"],

  "sway/workspaces": {
    "disable-scroll": true,
    "all-outputs": true,
    "format": "{name}"
  },

  "sway/mode": { "format": "{}", "max-length": 50 },

  "clock": { "format": " {:%H:%M   %d/%m}", "format-alt": "📅 {:%d.%m.%Y}", "interval": 1 },

  "cpu": { "format": " {usage}%", "interval": 2, "tooltip": true },

  "memory": { "format": " {percentage}%", "interval": 3, "tooltip": true },

  "network": { "format-wifi": " {essid}", "format-ethernet": " {ifname}", "format-disconnected": "⚠ Offline", "tooltip-format": "IP: {ipaddr}\nSignal: {signalStrength}%" },

  "pulseaudio": { "format": "{icon} {volume}%", "format-muted": "🔇 {volume}%", "format-icons": { "default": ["", "", ""] }, "on-click": "pavucontrol" },

  "battery": { "interval": 60, "states": { "warning": 30, "critical": 15 }, "format": "{capacity}% {icon}", "format-charging": "󰂄 {capacity}%", "format-icons": ["","","","",""], "tooltip": true },

  "custom/power": { "format": "{icon}", "format-icons": { "performance": "", "balanced": "", "power-saver": "" }, "return-type": "json", "exec": "~/.config/waybar/scripts/power-profiles.sh", "on-click": "~/.config/waybar/scripts/power-profiles.sh toggle", "interval": 30, "signal": 8, "tooltip": true }

}
EOFCONFIG

# Validar JSON y mover si es correcto
if command -v jq >/dev/null 2>&1; then
    if jq -e . "$TMP_CFG" >/dev/null 2>&1; then
        cp "$TARGET_DIR/config" "$TARGET_DIR/config.bak-$(date +%s)" 2>/dev/null || true
        mv "$TMP_CFG" "$TARGET_DIR/config"
    else
        echo "❌ JSON inválido en Dark Pro: no se aplicó la configuración"
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

# === ESTILO CSS ===

cat > "$TARGET_DIR/style.css" <<'EOFSTYLE'
/* Simplified Dark Pro — no animations */
* { margin:0; padding:0; font-family: "FontAwesome", "JetBrains Mono", monospace; }
window#waybar { background:#111; color:#e0e0e0; padding:6px 10px; border-radius:6px; }
#workspaces { padding:4px 8px; }
#workspaces button { color:#aaa; padding:4px 8px; }
#workspaces button.focused { color:#79b8ff; }
#clock, #cpu, #memory, #network, #pulseaudio, #battery, #custom-power { margin-right:10px; color:#d0d0d0; }
EOFSTYLE

echo "✅ Estilo Dark Pro aplicado"
echo "💡 Reinicia Waybar: pkill waybar; sleep 0.5; waybar"
