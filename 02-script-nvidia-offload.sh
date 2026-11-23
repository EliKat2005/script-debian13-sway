#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
VERIFY_ONLY=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --verify-only) VERIFY_ONLY=true ;;
        *) echo "Argumento desconocido: $arg"; exit 2 ;;
    esac
done

# -----------------------------------------------------------------------------
# NVIDIA SETUP FOR DEBIAN 13
# -----------------------------------------------------------------------------

log(){ echo -e "\n\033[1;36m[+] $1\033[0m"; }

if [[ $EUID -ne 0 ]]; then
   echo "❌ Ejecuta con sudo."
   exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "Modo dry-run: NVIDIA MX130 compatible."
    exit 0
fi

if [[ "$VERIFY_ONLY" == true ]]; then
    echo "Modo verify-only: comprobando configuración NVIDIA instalada."
    test -x /usr/local/bin/nv
    grep -q 'NVreg_PreserveVideoMemoryAllocations=1' /etc/modprobe.d/nvidia-power.conf
    grep -q 'NVreg_DynamicPowerManagement=0x02' /etc/modprobe.d/nvidia-power.conf
    grep -q 'nvidia-drm.modeset=1' /etc/default/grub
    nvidia-smi >/dev/null
    echo "Verificación NVIDIA completada."
    exit 0
fi

if ! lspci -nn | grep -q '10de:174d'; then
    echo "Hardware no compatible: no se encontró la NVIDIA MX130 esperada."
    exit 1
fi

# --- FASE 0: ARREGLO DE REPOSITORIOS ---
log "0. Verificando y corrigiendo repositorios (Non-Free / Contrib)"

if [[ -f /etc/apt/sources.list ]] || find /etc/apt/sources.list.d -maxdepth 1 -type f -name '*.list' -print -quit | grep -q .; then
    mkdir -p /var/backups/debian-sway
    find /etc/apt/sources.list.d -maxdepth 1 -type f -name '*.list' -exec cp -a '{}' /var/backups/debian-sway/ ';'
    [[ -f /etc/apt/sources.list ]] && cp -a /etc/apt/sources.list /var/backups/debian-sway/sources.list.pre-modernize.nvidia
    if apt modernize-sources --help >/dev/null 2>&1; then
        apt -y modernize-sources
        log "   Fuentes APT antiguas migradas al formato .sources moderno."
    else
        log "   APT no ofrece modernize-sources; se conserva el formato actual."
    fi
fi

SOURCES_FILE="/etc/apt/sources.list.d/debian.sources"

if [[ -f "$SOURCES_FILE" ]]; then
    mkdir -p /var/backups/debian-sway
    cp -a "$SOURCES_FILE" "/var/backups/debian-sway/debian.sources.nvidia.$(date +%Y%m%d-%H%M%S)"
fi

if [[ -f "$SOURCES_FILE" ]] && grep -q '^Components:' "$SOURCES_FILE"; then
    if ! grep -q 'contrib' "$SOURCES_FILE" ||
       ! grep -q 'non-free' "$SOURCES_FILE" ||
       ! grep -q 'non-free-firmware' "$SOURCES_FILE"; then
        log "   Detectado repositorio incompleto. Activando contrib y non-free..."
        sed -i -E 's/^Components:[[:space:]]+.*/Components: main contrib non-free non-free-firmware/' "$SOURCES_FILE"
        log "   Repositorios corregidos."
    else
        log "   Los repositorios parecen estar bien configurados."
    fi
elif [[ -f /etc/apt/sources.list ]]; then
    if grep -qE '^deb[[:space:]].*\bmain\b' /etc/apt/sources.list &&
       ! grep -q '^deb.*main.*contrib.*non-free.*non-free-firmware' /etc/apt/sources.list; then
        sed -i -E 's/(^deb([[:space:]]+[^[:space:]]+){3,}[[:space:]]+)main([[:space:]]|$)/\1main contrib non-free non-free-firmware /g' /etc/apt/sources.list
    fi
else
    log "⚠️ ALERTA: No se encontró una configuración APT de Debian reconocida."
fi

# --- FASE 1: INSTALACIÓN ---

log "1. Actualizando lista de paquetes (Ahora con Nvidia visible)"
dpkg --add-architecture i386
apt update

log "2. Instalando Driver Nvidia Propietario + Librerías 32-bits"

# Instalamos todo en un solo bloque para que APT resuelva dependencias mejor
apt -y install \
    linux-headers-amd64 \
    dkms \
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

log "3. Configurando GRUB (Clean Boot + Silenciador + BIOS Fix)"
# Limpiamos parámetros previos (si existieran) para evitar contradecirnos
sed -i -E 's/[[:space:]]+nvidia-drm\.modeset=[^[:space:]"]+//g' /etc/default/grub
sed -i -E 's/[[:space:]]+nvidia-drm\.fbdev=[^[:space:]"]+//g' /etc/default/grub
sed -i 's/ pci=noaer//g' /etc/default/grub
sed -i -E '/^GRUB_CMDLINE_LINUX_DEFAULT=/ { /nvidia-drm\.modeset=1/! s/"$/ nvidia-drm.modeset=1"/; }' /etc/default/grub
update-grub
log "✅ GRUB actualizado con DRM/KMS habilitado para NVIDIA."

# --- FASE 3: UTILIDADES ---

log "4. Creando Wrapper 'nv' (Lanzador Optimizado)"
cat <<'EOF' > /usr/local/bin/nv
#!/bin/bash
# Wrapper para Nvidia Prime Offload en Wayland
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
exec "$@"
EOF
chmod +x /usr/local/bin/nv

log "5. Configurando Gestión de Energía (Suspensión Segura y Gestión de Energía D3)"
cat > /etc/modprobe.d/nvidia-power.conf <<'EOF'
options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp NVreg_DynamicPowerManagement=0x02
EOF

for unit in nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service; do
    if systemctl list-unit-files --no-legend "$unit" 2>/dev/null | grep -q "^${unit}[[:space:]]"; then
        systemctl enable "$unit"
        log "   Habilitada unidad disponible: $unit"
    else
        log "   Unidad no disponible en Debian: $unit"
    fi
done
systemctl disable --now nvidia-persistenced.service 2>/dev/null || true

# --- FASE 4: PARCHE SWAY ---

# Sway sigue funcionando sobre Intel; este argumento permite iniciar con el
# driver NVIDIA propietario presente sin convertir la dGPU en la GPU principal.
log "6. PARCHE DE COMPATIBILIDAD: Sway/Tuigreet con NVIDIA presente"
CONFIG_GREETD="/etc/greetd/config.toml"

# Verificamos si existe el archivo y si NO tiene ya el parche
if [[ -f "$CONFIG_GREETD" ]]; then
    if grep -q "cmd sway --time" "$CONFIG_GREETD"; then
        sed -i "s/--cmd sway/--cmd 'sway --unsupported-gpu'/" "$CONFIG_GREETD"
        log "✅ Greetd parcheado: Sway iniciará con --unsupported-gpu"
    elif grep -q "sway --unsupported-gpu" "$CONFIG_GREETD"; then
         log "✅ Greetd ya estaba parcheado."
    else
         log "⚠️ No se pudo parchear Greetd automáticamente (formato desconocido)."
    fi
fi

# Parche cursor invisible
touch /etc/environment
sed -i '/^[[:space:]#]*WLR_NO_HARDWARE_CURSORS[[:space:]]*=.*/d' /etc/environment
echo 'WLR_NO_HARDWARE_CURSORS=1' >> /etc/environment

log "7. Limpieza Profunda y Regeneración de Initramfs"
# Eliminar archivo fantasma para evitar errores de módulos en boot
rm -f /etc/modules-load.d/nvidia.conf
# Purgar instrucciones viejas del núcleo
update-initramfs -u

log "✅ INSTALACIÓN DE NVIDIA COMPLETADA"
log "   Reinicia el equipo."
log "   Prueba: nv nvidia-smi"
