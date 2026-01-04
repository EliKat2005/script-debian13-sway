#!/bin/bash
# Waybar Style: Cyberpunk Neon
# Descripción: Colores vibrantes (magenta/cyan), gradientes, bordes brillantes
# Ideal para: Entorno de trabajo moderno, desarrolladores

if [ -z "$HOME" ]; then
  echo "❌ HOME no definida"
  exit 1
fi

TARGET_DIR="$HOME/.config/waybar"
mkdir -p "$TARGET_DIR"

echo "🌆 Aplicando estilo Cyberpunk Neon..."

# === CONFIGURACIÓN WAYBAR ===
# Escribimos primero a un archivo temporal y validamos JSON antes de sobrescribir
TMP_CFG="$(mktemp)"
cat > "$TMP_CFG" <<'EOFCONFIG'
{
    "layer": "top",
    "height": 40,
    "margin-top": 8,
    "margin-left": 12,
    "margin-right": 12,
    "margin-bottom": 0,
    "modules-left": ["sway/workspaces"],
    "modules-center": ["clock", "sway/mode"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "custom/power", "battery", "tray"],
    
    "sway/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{name}"
    },
    "sway/mode": {
        "format": "󰏎 {}",
        "max-length": 50
    },
    "clock": {
        "format": " {:%H:%M   %d/%m}",
        "format-alt": "󰓅 {:%d/%m/%Y}",
        "tooltip-format": "<big>{:%Y-%B}</big>\n<tt>{calendar}</tt>",
        "interval": 1
    },
    "cpu": { "format": " {usage}%", "interval": 2, "tooltip": true },
    "memory": { "format": " {percentage}%", "interval": 3, "tooltip": true },
    "network": {
        "format-wifi": " {essid}",
        "format-ethernet": " {ifname}",
        "format-disconnected": "⚠ Desconectado",
        "tooltip-format": "IP: {ipaddr}\nFortaleza: {signalStrength}%",
        "on-click": "nm-connection-editor"
    },
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "🔇 {volume}%",
        "format-icons": { "default": ["", "", ""] },
        "on-click": "pavucontrol",
        "scroll-step": 5
    },
    "battery": {
        "interval": 60,
        "states": { "warning": 30, "critical": 15 },
        "format": "{capacity}% {icon}",
        "format-charging": "󰂄 {capacity}%",
        "format-plugged": "󰂄 {capacity}%",
        "format-icons": ["", "", "", "", ""],
        "tooltip": true
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

# Validar JSON y mover si es correcto
if command -v jq >/dev/null 2>&1; then
  if jq -e . "$TMP_CFG" >/dev/null 2>&1; then
    cp "$TARGET_DIR/config" "$TARGET_DIR/config.bak-$(date +%s)" 2>/dev/null || true
    mv "$TMP_CFG" "$TARGET_DIR/config"
  else
    echo "❌ JSON inválido en Cyberpunk: no se aplicó la configuración"
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
/* Simplified Cyberpunk style — no animations or keyframes */
* { margin: 0; padding: 0; font-family: "FontAwesome", "JetBrains Mono", sans-serif; font-size: 13px; }
window#waybar { background: linear-gradient(135deg,#0a0e27,#0f3460); color: #00d9ff; border-radius: 8px; padding: 4px 8px; }
#workspaces { background: rgba(0,0,0,0.35); padding: 4px 8px; border-radius: 6px; }
#workspaces button { padding: 4px 8px; margin: 0 4px; color: #bbb; }
#workspaces button.focused { color: #fff; background: rgba(255,0,128,0.12); }
#clock, #cpu, #memory, #network, #pulseaudio, #battery, #custom-power, #tray { padding: 6px 10px; margin: 0 4px; border-radius: 6px; background: rgba(255,255,255,0.03); }
#custom-power.performance { color: #ff6b81; }
#custom-power.balanced { color: #00d9ff; }
#custom-power.power-saver { color: #00ff41; }
#tray { background: transparent; }
EOFSTYLE

echo "✅ Estilo Cyberpunk Neon aplicado correctamente"
echo "💡 Reinicia Waybar: pkill waybar; sleep 0.5; waybar"
