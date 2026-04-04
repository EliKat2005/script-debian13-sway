#!/bin/bash
echo "--- 🎨 Tema: Base Default Pro ---"
USER_HOME=$HOME

# 1. Sway Config
sed -i -E 's/^client.focused .*/client.focused          #00BCD4 #263238 #e0e0e0 #00BCD4   #00BCD4/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^client.focused_inactive .*/client.focused_inactive #333333 #5f676a #e0e0e0 #484e50   #5f676a/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^client.unfocused .*/client.unfocused        #333333 #222222 #888888 #292d2e   #222222/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^client.urgent .*/client.urgent           #2f343a #900000 #e0e0e0 #900000   #900000/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^default_border .*/default_border pixel 2/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^gaps inner .*/gaps inner 8/' "$USER_HOME/.config/sway/config"
sed -i -E 's|^output \* bg .*|output * bg /usr/share/images/desktop-base/default fill|' "$USER_HOME/.config/sway/config"

# 2. Alacritty
cat << 'EOF' > "$USER_HOME/.config/alacritty/alacritty.toml"
[font]
size = 11.0
normal = { family = "JetBrains Mono", style = "Regular" }
offset = { x = 0, y = 4 }

[window]
opacity = 1.0
padding = { x = 24, y = 24 }
decorations = "None"
dynamic_title = true

[colors.primary]
background = "#181818"
foreground = "#e0e0e0"

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

# 3. Waybar CSS
cat << 'EOF' > "$USER_HOME/.config/waybar/style.css"
* { border: none; border-radius: 0; font-family: "FontAwesome", "JetBrains Mono", sans-serif; font-size: 14px; min-height: 0; }
window#waybar { background-color: rgba(24, 24, 24, 0.95); color: #e0e0e0; border-bottom: 2px solid #00BCD4; }
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

# 4. Wofi CSS
cat << 'EOF' > "$USER_HOME/.config/wofi/style.css"
window { margin: 0px; border: 2px solid #00BCD4; background-color: #181818; border-radius: 8px; font-family: "JetBrains Mono"; font-size: 14px; }
#input { margin: 10px; padding: 10px; border-radius: 4px; border: none; color: #e0e0e0; background-color: #2b2b2b; }
#inner-box { margin: 5px; }
#entry { padding: 8px; border-radius: 4px; }
#entry:selected { background-color: #00BCD4; color: #181818; font-weight: bold; }
EOF

# 5. Mako
cat << 'EOF' > "$USER_HOME/.config/mako/config"
max-history=10
sort=-time
default-timeout=5000
font=Inter 11
background-color=#181818
text-color=#e0e0e0
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
[urgency=critical]
border-color=#ff5555
default-timeout=0
[app-name=recorder]
border-color=#26A65B
default-timeout=3000
EOF

swaymsg reload
pkill -SIGUSR2 mako
echo "✅ Tema Default Pro aplicado con éxito!"
