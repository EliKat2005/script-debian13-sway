#!/bin/bash
echo "--- ❄️ Tema: Nord Arctic ---"
USER_HOME=$HOME

# 1. Sway Config
sed -i -E 's/^client.focused .*/client.focused          #88c0d0 #2e3440 #eceff4 #88c0d0   #88c0d0/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^client.focused_inactive .*/client.focused_inactive #4c566a #3b4252 #d8dee9 #4c566a   #4c566a/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^client.unfocused .*/client.unfocused        #2e3440 #2e3440 #e5e9f0 #2e3440   #2e3440/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^client.urgent .*/client.urgent           #bf616a #bf616a #eceff4 #bf616a   #bf616a/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^default_border .*/default_border pixel 2/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^gaps inner .*/gaps inner 10/' "$USER_HOME/.config/sway/config"
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
background = "#2e3440"
foreground = "#eceff4"

[colors.normal]
black   = "#3b4252"
red     = "#bf616a"
green   = "#a3be8c"
yellow  = "#ebcb8b"
blue    = "#81a1c1"
magenta = "#b48ead"
cyan    = "#88c0d0"
white   = "#e5e9f0"
EOF

# 3. Waybar CSS
cat << 'EOF' > "$USER_HOME/.config/waybar/style.css"
* { border: none; border-radius: 0; font-family: "FontAwesome", "JetBrains Mono", sans-serif; font-size: 14px; min-height: 0; }
window#waybar { background-color: rgba(46, 52, 64, 0.95); color: #eceff4; border-bottom: 2px solid #88c0d0; }
#clock, #pulseaudio, #network, #cpu, #memory, #battery, #tray {
    padding: 0 10px; margin: 0 4px; background-color: rgba(236, 239, 244, 0.1); border-radius: 8px;
}
#workspaces button.focused { background-color: #4c566a; color: #88c0d0; border-bottom: 2px solid #88c0d0; border-radius: 8px; }
#battery.warning { color: #ebcb8b; }
#battery.critical { color: #bf616a; animation-name: blink; animation-duration: 0.5s; }
@keyframes blink { to { color: #eceff4; } }
#custom-power { padding: 0 10px; margin: 0 4px; background-color: rgba(236, 239, 244, 0.1); border-radius: 8px; }
#custom-power.performance { color: #bf616a; }
#custom-power.balanced { color: #88c0d0; }
#custom-power.power-saver { color: #a3be8c; }
EOF

# 4. Wofi CSS
cat << 'EOF' > "$USER_HOME/.config/wofi/style.css"
window { margin: 0px; border: 2px solid #88c0d0; background-color: #2e3440; border-radius: 12px; font-family: "JetBrains Mono"; font-size: 14px; }
#input { margin: 10px; padding: 10px; border-radius: 8px; border: none; color: #eceff4; background-color: #3b4252; }
#inner-box { margin: 5px; }
#entry { padding: 8px; border-radius: 8px; }
#entry:selected { background-color: #88c0d0; color: #2e3440; font-weight: bold; }
EOF

# 5. Mako
cat << 'EOF' > "$USER_HOME/.config/mako/config"
max-history=10
sort=-time
default-timeout=5000
font=Inter 11
background-color=#2e3440
text-color=#eceff4
width=350
height=150
max-visible=5
margin=10
padding=15
border-size=2
border-color=#88c0d0
border-radius=12
icons=1
max-icon-size=48
icon-location=left
[urgency=critical]
border-color=#bf616a
default-timeout=0
[app-name=recorder]
border-color=#a3be8c
default-timeout=3000
EOF

swaymsg reload
pkill -SIGUSR2 mako
echo "✅ Tema Nord Arctic aplicado con éxito!"
