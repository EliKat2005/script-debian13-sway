# 🚀 Debian 13 "Trixie" + Sway: Pro Wayland Environment

Una arquitectura de instalación y configuración sumamente robusta, moderna y pensada milimétricamente para exprimir al máximo el rendimiento del hardware, manteniendo una estética profesional, limpia y libre de distracciones.

## 🌟 Características Principales

- **Wayland prioritario con compatibilidad:** Sway usa Wayland nativamente y mantiene XWayland habilitado para aplicaciones compatibles que todavía requieren X11.
- **Navegador Brave Origin:** Instala la variante oficial `origin` mediante el instalador publicado por Brave.
- **Gráficos Híbridos Inteligentes (Nvidia Prime Offload):** Sway se ejecuta sobre la gráfica integrada Intel UHD 620 para maximizar la batería. La NVIDIA MX130 usa gestión dinámica de energía y se invoca mediante el wrapper `nv` (ej. `nv blender`). El estado D3 real depende del firmware/ACPI del Inspiron.
- **BTRFS preparado manualmente + Timeshift:** La raíz BTRFS y el subvolumen `@` se crean durante el particionado manual de la instalación Netinstall. Los scripts no modifican particiones ni subvolúmenes.
- **ZRAM sin swap en disco:** Instala `zram-tools`, crea un dispositivo ZSTD de 8 GB y configura prioridad 100 con `swappiness=150`.
- **Batería protegida:** Configura carga entre 70% y 80% cuando el firmware Dell expone los controles correspondientes.
- **Arranque optimizado:** Habilita `nvidia-drm.modeset=1` para KMS de Wayland, desactiva `NetworkManager-wait-online`, conserva el perfil CPU automático y verifica BTRFS/subvolumen `@`.
- **CPU automático:** El perfil de CPU lo gestiona `power-profiles-daemon`/`intel_pstate`; el script no fuerza un governor fijo.
- **Gestión Térmica Especializada (Dell/Intel):** Integración profunda con `thermald`, `coretemp` y `dell-smm-hwmon` para prevenir el *thermal throttling* en procesadores Intel (i7 Whiskey Lake) y gestionar los ventiladores de forma natural.
- **Armonía visual GTK:** Las aplicaciones GTK siguen el tema maestro `Arc-Dark` con iconos `Papirus-Dark`. No se instalan integraciones Qt porque no hay aplicaciones Qt principales en este escritorio.
- **Terminal Foot:** Foot es la única terminal instalada, configurada con fondo opaco, JetBrains Mono y el mismo estilo visual solicitado.
- **Herramientas GTK ligeras:** La calculadora usa `galculator` sobre GTK3/Wayland y la gestión segura de discos usa `gnome-disk-utility` sobre GTK3/Wayland y UDisks.

---

## 📂 Estructura del Proyecto

El proyecto está dividido en tres comandos secuenciales para garantizar un despliegue sin conflictos:

### 1. `01-system-base.sh` (Kernel, Sistema BTRFS y Dependencias)
- **Requiere SUDO.**
- No modifica particiones ni sistemas de archivos; el particionado BTRFS/XFS se realiza manualmente durante la instalación de Debian.
- Configura `i915 enable_fbc=1`, sensores térmicos y ZRAM de 8 GB con ZSTD. En esta UHD 620, el kernel informa que GuC submission no está disponible, por lo que no se fuerza `enable_guc=3`.
- Configura APT sin recomendaciones ni sugerencias y selecciona el planificador `none` para discos SSD no rotacionales SATA/M.2 SATA o NVMe. No exige que el disco del sistema sea NVMe.
- Purga paquetes no usados para impresoras, módems y RPC en esta laptop sin puerto móvil.
- Instala herramientas Vulkan, `udiskie`, Timeshift y utilidades de gráficos.
- Instala `7zip`, `galculator`, `gnome-disk-utility`, BTRFS/XFS/exFAT/NTFS y retira componentes GTK/Qt heredados que no usa el entorno.
- Elimina *bloatware* y deshabilita servicios innecesarios (`cups`, `rpcbind`, `ModemManager`).
- Reconstruye el `initramfs` asegurando carga temprana expedita.

### 2. `02-script-nvidia-offload.sh` (Gestión de GPU Híbrida)
- **Requiere SUDO.**
- Instala drivers propietarios y `linux-headers-amd64` vía `dkms` para actualizaciones automáticas ante cambios del kernel de Debian.
- Habilita KMS con `nvidia-drm.modeset=1`, elimina `pci=noaer` si existiera y ajusta greetd para iniciar Sway con `--unsupported-gpu`. Sway continúa usando Intel como GPU principal; el argumento evita el fallo de inicio que puede producir el driver NVIDIA propietario presente.

### 3. `03-config-user.sh` (Interfaz y Entorno de Usuario)
- **Ejecutar SIN SUDO (Usuario normal).**
- Configura parámetros crudos del compositor **SwayWM**.
- Genera archivos de configuración limpios para terminal (Foot), barra de estado interactiva (Waybar), notificadores (Mako) y lanzadores (Wofi).

---

## 🎨 Motores de Temas Inteligentes (`Sway-Styles/`)

El repositorio incluye motores inyectores en la carpeta `Sway-Styles` para cambiar radicalmente la estética del sistema *al vuelo* sin comprometer la limpieza ni reiniciar sesión. Contamos con 3 estilos oficiales construidos milimétricamente usando la imagen de escritorio oficial por detrás:

1. **`00-theme-default.sh` (Default Pro):** Colores oscuros muy profundos (`#181818`), blanco roto (`#e0e0e0`) para evitar astigmatismo prolongado, con acentos en cyan brillante. Para productividad diaria.
2. **`01-theme-tokyo.sh` (Tokyo Neon):** Tonos cyberpunk. Fondos violeta/azulado (`#1a1b26`), espacios de ventana agresivos y un poderoso vivo Magenta purpúreo. Ideal para ambientes de total oscuridad.
3. **`02-theme-nord.sh` (Nord Arctic):** Paleta glacial de máxima paz visual. Grises escarchados, "Frost blue" (`#88c0d0`) y Waybars redondeados de forma suave.

*Simplemente ejecuta el script del tema que desees desde la terminal y Sway se adaptará instantáneamente.*

---

## ⚡ Instalación Rápida

Para desplegar este entorno en una instalación limpia de Debian 13 (Netinst / Minimal):

Antes de ejecutar los scripts:

1. Particiona manualmente el disco durante la instalación Netinstall.
2. Da formato BTRFS a la raíz, usa el subvolumen `@` y monta la EFI y `/boot` necesarias.
3. Da formato XFS o el formato deseado a `/home` y a discos adicionales.
4. Los scripts no crean, formatean ni renombran particiones o subvolúmenes.

```bash
# 1. Configuración de Sistema, BTRFS y Modprobe
sudo ./01-system-base.sh
sudo reboot

# 2. Configuración Nvidia Prime
sudo ./02-script-nvidia-offload.sh
sudo reboot

# 3. Entorno de Usuario
./03-config-user.sh
# Cerrar sesión (Log out) y acceder con Sway.
```

---

## ⌨️ Atajos de Teclado Destacados

- `Win + Enter` : Abrir Terminal (Foot)
- `Win + Espacio`: Abrir Menú (Wofi)
- `Win + W` : Navegador (Brave)
- `Win + F` : Gestor de Archivos (Thunar)
- `Win + Shift + E` : Menú de Salida/Apagado (Wlogout)
- `Win + Shift + Espacio`: Alternar ventana flotante

### Multimedia y Laptop
Soporte absoluto integrado para subir/bajar brillo (`brightnessctl`), control de volumen micro/altavoz (`pamixer`), teclado numérico y manejo nativo de batería en barra.

### Compatibilidad y migración de APT

- El script NVIDIA ejecuta `apt -y modernize-sources` cuando detecta formatos antiguos `.list`.
- Las copias de seguridad de `debian.sources` se guardan en `/var/backups/debian-sway/`, nunca dentro de `/etc/apt/sources.list.d/`.
- Las unidades `nvidia-suspend.service`, `nvidia-hibernate.service` y `nvidia-resume.service` se habilitan únicamente si existen en el paquete instalado.
