# 🚀 Debian 13 "Trixie" + Sway: Wayland Environment

Una arquitectura de instalación y configuración sumamente robusta, moderna y pensada milimétricamente para exprimir al máximo el rendimiento del hardware, manteniendo una estética profesional, limpia y libre de distracciones.

## 🌟 Características Principales

- **Pureza Wayland:** Entorno 100% nativo. `XWayland` está deshabilitado para ahorrar RAM, evitar lag de renderizado y mantener el entorno limpio de dependencias X11 heredadas.
- **Gráficos Híbridos Inteligentes (Nvidia Prime Offload):** Configurado para que Sway se ejecute nativamente sobre la gráfica integrada (Intel UHD 620) maximizando la batería. La GPU dedicada (Nvidia MX130 Maxwell) se mantiene en reposo (D3cold/Offload) y solo se invoca usando el wrapper `nv command`.
- **Integración Nativa BTRFS + Timeshift:** Renombrado automático del subvolumen `@rootfs` a `@` para que `Timeshift` funcione de maravilla de forma nativa. Snapshots instantáneos sin ocupar espacio extra.
- **Gestión Térmica Especializada (Dell/Intel):** Integración profunda con `thermald`, `coretemp` y `dell-smm-hwmon` para prevenir el *thermal throttling* en procesadores Intel (i7 Whiskey Lake) y gestionar los ventiladores de forma natural.
- **Estética Profesional:** Interfaz pulida con base en márgenes espaciados, colores "blanco roto" (`#e0e0e0`) y fondos grises profundos (`#181818`) diseñados científicamente para evitar la fatiga visual (astigmatismo inducido) en largas jornadas de programación.

---

## 📂 Estructura del Proyecto

El proyecto está dividido en tres fases secuenciales para garantizar un despliegue sin conflictos:

### 1. `01-system-base.sh` (Kernel, Sistema BTRFS y Dependencias)
- **Requiere SUDO.**
- Renombra subvolúmenes BTRFS para Timeshift.
- Configura parámetros del kernel (`i915.enable_guc=3`, `pcie_aspm=force`).
- Elimina *bloatware* y servicios innecesarios (`cups`, `rpcbind`, `ModemManager`).
- Reconstruye el `initramfs` asegurando que todos los sensores térmicos carguen desde el segundo cero.

### 2. `script-nvidia-offload.sh` (Gestión de GPU)
- **Requiere SUDO.**
- Instala drivers propietarios y `linux-headers-amd64` vía `dkms` (las actualizaciones de Debian recompilarán el módulo Nvidia automáticamente).
- Aplica "Clean Boot": limpia `nvidia.conf` residuales y quita DRM modesets forzados en GRUB que colisionan con tarjetas Maxwell.

### 3. `02-config-user.sh` (Interfaz y Entorno de Usuario)
- **Ejecutar SIN SUDO (Usuario normal).**
- Configura el compositor **SwayWM**.
- Genera archivos de configuración para:
  - **Alacritty:** Terminal acelerada por GPU (Espaciada y con paleta de colores armónica).
  - **Waybar:** Barra de estado superior interactiva.
  - **Wofi:** Menú de aplicaciones moderno y espaciado (estilo Spotlight).
  - **Mako:** Notificaciones minimalistas.
- Establece temas globales y desactiva componentes redundantes en segundo plano (`thunar --daemon`).

---

## ⚡ Instalación Rápida

Para desplegar este entorno en una instalación limpia de Debian 13 (Netinst / Minimal):

```bash
# 1. Configuración de Sistema, BTRFS y Modprobe
sudo ./01-system-base.sh
sudo reboot

# 2. Configuración Nvidia Prime
sudo ./script-nvidia-offload.sh
sudo reboot

# 3. Entorno de Usuario
./02-config-user.sh
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

### Multimedia
Soporte absoluto integrado para subir/bajar brillo (`brightnessctl`), control de volumen (`pamixer`), y pausas en contenido multimedia.

---
*Construido para desarrolladores y usuarios avanzados que demandan estabilidad absoluta, rendimiento y herramientas que no se crucen en el camino.*
