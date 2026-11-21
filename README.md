# 🚀 Debian 13 "Trixie" + Sway: Pro Wayland Environment

Una arquitectura de instalación y configuración sumamente robusta, moderna y pensada milimétricamente para exprimir al máximo el rendimiento del hardware, manteniendo una estética profesional, limpia y libre de distracciones.

## 🌟 Características Principales

- **Wayland prioritario con compatibilidad:** Sway usa Wayland nativamente y mantiene XWayland habilitado para aplicaciones compatibles que todavía requieren X11.
- **Gráficos Híbridos Inteligentes (Nvidia Prime Offload):** Configurado para que Sway se ejecute nativamente sobre la gráfica integrada (Intel UHD 620) maximizando la batería. La GPU dedicada (Nvidia MX130 Maxwell) se mantiene en reposo (D3cold/Offload) y solo se invoca usando el wrapper `nv` (ej. `nv blender`).
- **BTRFS preparado manualmente + Timeshift:** La raíz BTRFS y el subvolumen `@` se crean durante el particionado manual de la instalación Netinstall. Los scripts no modifican particiones ni subvolúmenes.
- **ZRAM sin swap en disco:** Instala `zram-tools`, crea un dispositivo ZSTD de 8 GB y configura prioridad 100 con `swappiness=150`.
- **Gestión Térmica Especializada (Dell/Intel):** Integración profunda con `thermald`, `coretemp` y `dell-smm-hwmon` para prevenir el *thermal throttling* en procesadores Intel (i7 Whiskey Lake) y gestionar los ventiladores de forma natural.
- **Armonía Visual Global:** Todas las aplicaciones (sean GTK o QT) siguen el tema maestro `Arc-Dark` con iconos `Papirus-Dark` gracias al puente nativo de variables de entorno y `qt5ct`/`qt6ct`.

---

## 📂 Estructura del Proyecto

El proyecto está dividido en tres comandos secuenciales para garantizar un despliegue sin conflictos:

### 1. `01-system-base.sh` (Kernel, Sistema BTRFS y Dependencias)
- **Requiere SUDO.**
- No modifica particiones ni sistemas de archivos; el particionado BTRFS/XFS se realiza manualmente durante la instalación de Debian.
- Configura `i915 enable_guc=3 enable_fbc=1`, sensores térmicos y ZRAM de 8 GB con ZSTD.
- Configura APT sin recomendaciones ni sugerencias, NVMe con planificador `none` y UFW con denegación entrante.
- Purga paquetes no usados para impresoras, módems y RPC en esta laptop sin puerto móvil.
- Instala herramientas Vulkan, `udiskie`, Timeshift y utilidades de gráficos.
- Elimina *bloatware* y deshabilita servicios innecesarios (`cups`, `rpcbind`, `ModemManager`).
- Reconstruye el `initramfs` asegurando carga temprana expedita.

### 2. `02-script-nvidia-offload.sh` (Gestión de GPU Híbrida)
- **Requiere SUDO.**
- Instala drivers propietarios y `linux-headers-amd64` vía `dkms` para actualizaciones automáticas ante cambios del kernel de Debian.
- Conserva el arranque limpio: evita modosets forzados, elimina `pci=noaer` si existiera y prepara Sway para iniciar sin pánico de GPU.

### 3. `03-config-user.sh` (Interfaz y Entorno de Usuario)
- **Ejecutar SIN SUDO (Usuario normal).**
- Configura parámetros crudos del compositor **SwayWM**.
- Genera archivos de configuración limpios para terminal (Alacritty), barra de estado interactiva (Waybar), notificadores (Mako) y lanzadores (Wofi).

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

- `Win + Enter` : Abrir Terminal (Alacritty)
- `Win + Espacio`: Abrir Menú (Wofi)
- `Win + W` : Navegador (Brave)
- `Win + F` : Gestor de Archivos (Thunar)
- `Win + Shift + E` : Menú de Salida/Apagado (Wlogout)
- `Win + Shift + Espacio`: Alternar ventana flotante

### Multimedia y Laptop
Soporte absoluto integrado para subir/bajar brillo (`brightnessctl`), control de volumen micro/altavoz (`pamixer`), teclado numérico y manejo nativo de batería en barra.
