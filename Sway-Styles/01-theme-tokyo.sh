#!/bin/bash
echo "--- 🌃 Tema: Tokyo Neon ---"
USER_HOME=$HOME

# 1. Sway Config
sed -i -E 's/^client.focused .*/client.focused          #bb9af7 #1a1b26 #c0caf5 #bb9af7   #bb9af7/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^client.focused_inactive .*/client.focused_inactive #292e42 #414868 #c0caf5 #292e42   #414868/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^client.unfocused .*/client.unfocused        #1a1b26 #1a1b26 #a9b1d6 #1a1b26   #1a1b26/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^client.urgent .*/client.urgent           #f7768e #f7768e #1a1b26 #f7768e   #f7768e/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^default_border .*/default_border pixel 2/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^gaps inner .*/gaps inner 12/' "$USER_HOME/.config/sway/config"
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
background = "#1a1b26"
foreground = "#c0caf5"

[colors.normal]
black   = "#15161e"
red     = "#f7768e"
green   = "#9ece6a"
yellow  = "#e0af68"
blue    = "#7aa2f7"
magenta = "#bb9af7"
cyan    = "#7dcfff"
white   = "#a9b1d6"
EOF

# 3. Waybar CSS
cat << 'EOF' > "$USER_HOME/.config/waybar/style.css"
* { border: none; border-radius: 0; font-family: "FontAwesome", "JetBrains Mono", sans-serif; font-size: 14px; min-height: 0; }
window#waybar { background-color: rgba(26, 27, 38, 0.95); color: #c0caf5; border-bottom: 2px solid #bb9af7; }
#clock, #pulseaudio, #network, #cpu, #memory, #battery, #tray {
    padding: 0 10px; margin: 0 4px; background-color: rgba(255, 255, 255, 0.05); border-radius: 6px;
}
#workspaces button.focused { background-color: #292e42; color: #bb9af7; border-bottom: 2px solid #bb9af7; }
#battery.warning { color: #e0af68; }
#battery.critical { color: #f7768e; animation-name: blink; animation-duration: 0.5s; }
@keyframes blink { to { color: #ffffff; } }
#custom-power { padding: 0 10px; margin: 0 4px; background-color: rgba(255, 255, 255, 0.05); border-radius: 6px; }
#custom-power.performance { color: #f7768e; }
#custom-power.balanced { color: #bb9af7; }
#custom-power.power-saver { color: #9ece6a; }
EOF

# 4. Wofi CSS
cat << 'EOF' > "$USER_HOME/.config/wofi/style.css"
window { margin: 0px; border: 2px solid #bb9af7; background-color: #1a1b26; border-radius: 12px; font-family: "JetBrains Mono"; font-size: 14px; }
#input { margin: 10px; padding: 10px; border-radius: 8px; border: none; color: #c0caf5; background-color: #292e42; }
#inner-box { margin: 5px; }
#entry { padding: 8px; border-radius: 8px; }
#entry:selected { background-color: #bb9af7; color: #1a1b26; font-weight: bold; }
EOF

# 5. Mako
cat << 'EOF' > "$USER_HOME/.config/mako/config"
max-history=10
sort=-time
default-timeout=5000
font=Inter 11
background-color=#1a1b26
text-color=#c0caf5
width=350
height=150
max-visible=5
margin=10
padding=15
border-size=2
border-color=#bb9af7
border-radius=12
icons=1
max-icon-size=48
icon-location=left
[urgency=critical]
border-color=#f7768e
default-timeout=0
[app-name=recorder]
border-color=#9ece6a
default-timeout=3000
EOF

swaymsg reload
pkill -SIGUSR2 mako
echo "✅ Tema Tokyo Neon aplicado con éxito!"
