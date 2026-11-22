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
sed -i -E 's/^gaps outer .*/gaps outer 2/' "$USER_HOME/.config/sway/config"
sed -i -E 's|^output \* bg .*|output * bg /usr/share/images/desktop-base/default fill|' "$USER_HOME/.config/sway/config"

# 2. Foot
cat << 'EOF' > "$USER_HOME/.config/foot/foot.ini"
[main]
font=JetBrains Mono:size=11
pad=20x20
dpi-aware=yes

[cursor]
style=block
blink=no

[colors]
background=1a1b26
foreground=c0caf5
regular0=15161e
regular1=f7768e
regular2=9ece6a
regular3=e0af68
regular4=7aa2f7
regular5=bb9af7
regular6=7dcfff
regular7=a9b1d6
bright0=414868
bright1=ff8aa1
bright2=b0df82
bright3=efbb82
bright4=95baf7
bright5=c9afff
bright6=a3e1ff
bright7=c0caf5
selection-foreground=1a1b26
selection-background=bb9af7
EOF

# 3. Waybar CSS
cat << 'EOF' > "$USER_HOME/.config/waybar/style.css"
* { border: none; border-radius: 0; font-family: "FontAwesome", "JetBrains Mono", sans-serif; font-size: 13px; min-height: 0; }
window#waybar { background-color: rgba(26, 27, 38, 0.94); color: #c0caf5; border-bottom: 1px solid rgba(187, 154, 247, 0.72); }
#workspaces { margin: 4px 6px 4px 8px; padding: 0 3px; background: rgba(187, 154, 247, 0.07); border-radius: 11px; }
#workspaces button { padding: 0 9px; color: #565f89; border-radius: 9px; transition: all 140ms ease; }
#workspaces button.focused { background: #292e42; color: #bb9af7; border-bottom: 2px solid #bb9af7; }
#workspaces button.urgent { background: #f7768e; color: #1a1b26; }
#clock, #pulseaudio, #network, #cpu, #memory, #battery, #tray, #custom-power {
    padding: 0 10px; margin: 4px 3px; background-color: rgba(187, 154, 247, 0.065); border: 1px solid rgba(192, 202, 245, 0.04); border-radius: 9px;
}
#clock { color: #c0caf5; min-width: 150px; }
#cpu { color: #7dcfff; }
#memory { color: #bb9af7; }
#network { color: #9ece6a; }
#pulseaudio { color: #e0af68; }
#battery { color: #c0caf5; }
#battery.charging, #battery.plugged { color: #9ece6a; }
#battery.warning { color: #e0af68; }
#battery.critical { color: #f7768e; }
#custom-power.performance { color: #f7768e; }
#custom-power.balanced { color: #bb9af7; }
#custom-power.power-saver { color: #9ece6a; }
EOF

# 4. Wofi CSS
cat << 'EOF' > "$USER_HOME/.config/wofi/style.css"
window { margin: 0px; border: 1px solid #bb9af7; background-color: #1a1b26; border-radius: 14px; font-family: "JetBrains Mono"; font-size: 14px; }
#input { border-radius: 9px; border: none; color: #c0caf5; background-color: #292e42; }
#inner-box { margin: 0 10px 10px 10px; }
#entry { padding: 11px 14px; border-radius: 8px; border-left: 3px solid transparent; }
#entry:selected { background-color: #292e42; color: #bb9af7; font-weight: bold; border-left: 3px solid #bb9af7; }
EOF

# 5. Mako
cat << 'EOF' > "$USER_HOME/.config/mako/config"
max-history=12
sort=-time
default-timeout=5000
font=Inter 11
background-color=#1a1b26
text-color=#c0caf5
width=380
height=180
max-visible=4
margin=12
padding=16
border-size=1
border-color=#bb9af7
border-radius=10
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
pkill -SIGUSR2 waybar 2>/dev/null || true
pkill -SIGUSR2 mako
echo "✅ Tema Tokyo Neon aplicado con éxito!"
