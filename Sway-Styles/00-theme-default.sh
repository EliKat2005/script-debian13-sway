#!/bin/bash
echo "--- 🎨 Tema: Base Default Pro ---"
USER_HOME=$HOME

# 1. Sway Config
sed -i -E 's/^client.focused .*/client.focused          #00BCD4 #263238 #e0e0e0 #00BCD4   #00BCD4/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^client.focused_inactive .*/client.focused_inactive #333333 #5f676a #e0e0e0 #484e50   #5f676a/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^client.unfocused .*/client.unfocused        #333333 #222222 #888888 #292d2e   #222222/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^client.urgent .*/client.urgent           #2f343a #900000 #e0e0e0 #900000   #900000/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^default_border .*/default_border pixel 2/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^gaps inner .*/gaps inner 10/' "$USER_HOME/.config/sway/config"
sed -i -E 's/^gaps outer .*/gaps outer 2/' "$USER_HOME/.config/sway/config"
sed -i -E 's|^output \* bg .*|output * bg /usr/share/images/desktop-base/default fill|' "$USER_HOME/.config/sway/config"

# 2. Foot
cat << 'EOF' > "$USER_HOME/.config/foot/foot.ini"
[main]
font=JetBrains Mono:size=11
pad=18x18
dpi-aware=yes

[cursor]
style=block
blink=no

[colors]
background=181818
foreground=e0e0e0
regular0=181818
regular1=ff5555
regular2=26A65B
regular3=ffeb3b
regular4=00BCD4
regular5=b388ff
regular6=84ffff
regular7=e0e0e0
bright0=414141
bright1=ff6e6e
bright2=39d98a
bright3=fff176
bright4=26c6da
bright5=c4a7ff
bright6=a7ffff
bright7=ffffff
selection-foreground=e0e0e0
selection-background=263238
EOF

# 3. Waybar CSS
cat << 'EOF' > "$USER_HOME/.config/waybar/style.css"
* { border: none; border-radius: 0; font-family: "FontAwesome", "JetBrains Mono", sans-serif; font-size: 13px; min-height: 0; }
window#waybar { background-color: rgba(24, 24, 24, 0.92); color: #e0e0e0; border-bottom: 1px solid rgba(0, 188, 212, 0.75); }
#workspaces { margin: 4px 6px 4px 8px; padding: 0 3px; background: rgba(255, 255, 255, 0.055); border-radius: 10px; }
#workspaces button { padding: 0 9px; color: #777777; border-radius: 8px; transition: all 120ms ease; }
#workspaces button.focused { background: #263238; color: #00BCD4; border-bottom: 2px solid #00BCD4; }
#workspaces button.urgent { background: #900000; color: #ffffff; }
#clock, #pulseaudio, #network, #cpu, #memory, #battery, #tray, #custom-power {
    padding: 0 10px; margin: 4px 3px; background-color: rgba(255, 255, 255, 0.055); border: 1px solid rgba(255, 255, 255, 0.035); border-radius: 8px;
}
#clock { color: #ffffff; min-width: 150px; }
#cpu { color: #84ffff; }
#memory { color: #b388ff; }
#network { color: #26A65B; }
#pulseaudio { color: #ffeb3b; }
#battery { color: #e0e0e0; }
#battery.charging, #battery.plugged { color: #00BCD4; }
#battery.warning { color: #ffeb3b; }
#battery.critical { color: #ff5555; }
#custom-power.performance { color: #ff5555; }
#custom-power.balanced { color: #00BCD4; }
#custom-power.power-saver { color: #26A65B; }
EOF

# 4. Wofi CSS
cat << 'EOF' > "$USER_HOME/.config/wofi/style.css"
window { margin: 0px; border: 1px solid #00BCD4; background-color: #181818; border-radius: 14px; font-family: "JetBrains Mono"; font-size: 14px; }
#input { border-radius: 9px; border: none; color: #e0e0e0; background-color: #263238; }
#inner-box { margin: 0 10px 10px 10px; }
#entry { padding: 11px 14px; border-radius: 8px; border-left: 3px solid transparent; }
#entry:selected { background-color: #263238; color: #00BCD4; font-weight: bold; border-left: 3px solid #00BCD4; }
EOF

# 5. Mako
cat << 'EOF' > "$USER_HOME/.config/mako/config"
max-history=12
sort=-time
default-timeout=4500
font=Inter 11
background-color=#181818
text-color=#e0e0e0
width=380
height=180
max-visible=4
margin=12
padding=16
border-size=1
border-color=#00BCD4
border-radius=10
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
pkill -SIGUSR2 waybar 2>/dev/null || true
pkill -SIGUSR2 mako
echo "✅ Tema Default Pro aplicado con éxito!"
