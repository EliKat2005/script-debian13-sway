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
background=2e3440
foreground=eceff4
regular0=3b4252
regular1=bf616a
regular2=a3be8c
regular3=ebcb8b
regular4=81a1c1
regular5=b48ead
regular6=88c0d0
regular7=e5e9f0
bright0=4c566a
bright1=cf6f7a
bright2=b3c998
bright3=f2d6a2
bright4=94b3cf
bright5=c09cbc
bright6=9ed0dd
bright7=eceff4
selection-foreground=eceff4
selection-background=434c5e
EOF

# 3. Waybar CSS
cat << 'EOF' > "$USER_HOME/.config/waybar/style.css"
* { border: none; border-radius: 0; font-family: "FontAwesome", "JetBrains Mono", sans-serif; font-size: 13px; min-height: 0; }
window#waybar { background-color: rgba(46, 52, 64, 0.94); color: #eceff4; border-bottom: 1px solid rgba(136, 192, 208, 0.72); }
#workspaces { margin: 4px 6px 4px 8px; padding: 0 3px; background: rgba(236, 239, 244, 0.06); border-radius: 11px; }
#workspaces button { padding: 0 9px; color: #4c566a; border-radius: 9px; transition: all 140ms ease; }
#workspaces button.focused { background: #4c566a; color: #88c0d0; border-bottom: 2px solid #88c0d0; }
#workspaces button.urgent { background: #bf616a; color: #eceff4; }
#clock, #pulseaudio, #network, #cpu, #memory, #battery, #tray, #custom-power {
    padding: 0 10px; margin: 4px 3px; background-color: rgba(236, 239, 244, 0.065); border: 1px solid rgba(236, 239, 244, 0.04); border-radius: 9px;
}
#clock { color: #eceff4; min-width: 150px; }
#cpu { color: #88c0d0; }
#memory { color: #b48ead; }
#network { color: #a3be8c; }
#pulseaudio { color: #ebcb8b; }
#battery { color: #eceff4; }
#battery.charging, #battery.plugged { color: #a3be8c; }
#battery.warning { color: #ebcb8b; }
#battery.critical { color: #bf616a; }
#custom-power.performance { color: #bf616a; }
#custom-power.balanced { color: #88c0d0; }
#custom-power.power-saver { color: #a3be8c; }
EOF

# 4. Wofi CSS
cat << 'EOF' > "$USER_HOME/.config/wofi/style.css"
window { margin: 0px; border: 1px solid #88c0d0; background-color: #2e3440; border-radius: 14px; font-family: "JetBrains Mono"; font-size: 14px; }
#input { border-radius: 9px; border: none; color: #eceff4; background-color: #3b4252; }
#inner-box { margin: 0 10px 10px 10px; }
#entry { padding: 11px 14px; border-radius: 8px; border-left: 3px solid transparent; }
#entry:selected { background-color: #3b4252; color: #88c0d0; font-weight: bold; border-left: 3px solid #88c0d0; }
EOF

# 5. Mako
cat << 'EOF' > "$USER_HOME/.config/mako/config"
max-history=12
sort=-time
default-timeout=5000
font=Inter 11
background-color=#2e3440
text-color=#eceff4
width=380
height=180
max-visible=4
margin=12
padding=16
border-size=1
border-color=#88c0d0
border-radius=10
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
pkill -SIGUSR2 waybar 2>/dev/null || true
pkill -SIGUSR2 mako
echo "✅ Tema Nord Arctic aplicado con éxito!"
