#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# NVIDIA SETUP FOR DEBIAN 13
# -----------------------------------------------------------------------------

log(){ echo -e "\n\033[1;36m[+] $1\033[0m"; }

if [[ $EUID -ne 0 ]]; then
   echo "❌ Ejecuta con sudo."
   exit 1
fi

# --- FASE 0: ARREGLO DE REPOSITORIOS ---
log "0. Verificando y corrigiendo repositorios (Non-Free / Contrib)"

SOURCES_FILE="/etc/apt/sources.list.d/debian.sources"

if [[ -f "$SOURCES_FILE" ]]; then
    cp "$SOURCES_FILE" "$SOURCES_FILE.bak_nvidia"
    
    if grep -q "Components: main non-free-firmware" "$SOURCES_FILE"; then
        log "   Detectado repositorio incompleto. Activando contrib y non-free..."
        sed -i 's/Components: main non-free-firmware/Components: main contrib non-free non-free-firmware/g' "$SOURCES_FILE"
        log "   Repositorios corregidos."
    else
        log "   Los repositorios parecen estar bien configurados."
    fi
else
    log "⚠️ ALERTA: No se encontró $SOURCES_FILE. Verificando sources.list antiguo..."
    if grep -q "^deb.*main non-free-firmware$" /etc/apt/sources.list; then
         sed -i 's/main non-free-firmware/main contrib non-free non-free-firmware/g' /etc/apt/sources.list
    fi
fi

# --- FASE 1: INSTALACIÓN ---

log "1. Actualizando lista de paquetes (Ahora con Nvidia visible)"
dpkg --add-architecture i386
apt update

log "2. Instalando Driver Nvidia Propietario + Librerías 32-bits"
KERNEL_VERSION=$(uname -r)

# Instalamos todo en un solo bloque para que APT resuelva dependencias mejor
apt -y install \
    linux-headers-"$KERNEL_VERSION" \
    nvidia-driver \
    nvidia-smi \
    nvidia-vulkan-icd \
    libglx-nvidia0 \
    libgl1-nvidia-glvnd-glx:i386 \
    nvidia-driver-libs:i386 \
    libvulkan1:i386 \
    mesa-vulkan-drivers \
    mesa-vulkan-drivers:i386

# --- FASE 2: CONFIGURACIÓN KERNEL ---

log "3. Configurando GRUB (Modeset + Silenciador de Logs + BIOS Fix)"
if ! grep -q "pci=noaer" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1 nvidia-drm.fbdev=1 pci=noaer loglevel=3"/' /etc/default/grub
    update-grub
    log "✅ GRUB Actualizado y Silenciado."
else
    log "✅ GRUB ya estaba optimizado."
fi

# --- FASE 3: UTILIDADES ---

log "4. Creando Wrapper 'nv' (Lanzador Optimizado)"
cat <<'EOF' > /usr/local/bin/nv
#!/bin/bash
# Wrapper para Nvidia Prime Offload en Wayland
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
exec "$@"
EOF
chmod +x /usr/local/bin/nv

log "5. Configurando Gestión de Energía (Suspensión Segura)"
echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp" > /etc/modprobe.d/nvidia-power.conf

systemctl enable nvidia-suspend.service
systemctl enable nvidia-hibernate.service
systemctl enable nvidia-resume.service

# --- FASE 4: PARCHE SWAY ---

log "6. PARCHE CRÍTICO: Habilitar Nvidia en Sway/Tuigreet"
CONFIG_GREETD="/etc/greetd/config.toml"

# Verificamos si existe el archivo y si NO tiene ya el parche
if [[ -f "$CONFIG_GREETD" ]]; then
    if grep -q "cmd sway --time" "$CONFIG_GREETD"; then
    	sed -i "s/cmd sway/cmd 'sway --unsupported-gpu'/" "$CONFIG_GREETD"
        log "✅ Greetd parcheado: Sway iniciará en modo --unsupported-gpu"
    elif grep -q "cmd sway --unsupported-gpu" "$CONFIG_GREETD"; then
         log "✅ Greetd ya estaba parcheado."
    else
         log "⚠️ No se pudo parchear Greetd automáticamente (formato desconocido)."
    fi
fi

# Parche cursor invisible
if ! grep -q "WLR_NO_HARDWARE_CURSORS" /etc/environment; then
    echo "WLR_NO_HARDWARE_CURSORS=1" >> /etc/environment
fi

log "✅ INSTALACIÓN DE NVIDIA COMPLETADA"
log "   Reinicia el equipo."
log "   Prueba: nv nvidia-smi"
