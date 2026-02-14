#!/bin/bash

# Script para arrancar el bot detectando el entorno (X11 vs Wayland)

# 1. Detectar Servidor Gráfico y permisos
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    echo "[!] Detectado Wayland. Configurando para compatibilidad..."
    # Wayland suele necesitar permisos específicos o XWayland
    if command -v xhost >/dev/null 2>&1; then
        xhost +local:docker >/dev/null
    fi
else
    echo "[!] Detectado X11."
    if command -v xhost >/dev/null 2>&1; then
        xhost +local:docker >/dev/null
    fi
fi

# 2. Detectar Usuario y UID
USER_ID=$(id -u)
GROUP_ID=$(id -g)
echo "[*] Ejecutando como UID: $USER_ID, GID: $GROUP_ID"

# Verificar xhost si no estamos en modo headless
if grep -q "BOT_HEADLESS=false" .env 2>/dev/null; then
    if ! command -v xhost >/dev/null 2>&1; then
        echo "----------------------------------------------------------------"
        echo "¡ADVERTENCIA! No se encontró el comando 'xhost'."
        echo "Es probable que la ventana del navegador NO aparezca o falle."
        echo "Por favor instala xorg-xhost: sudo pacman -S xorg-xhost"
        echo "----------------------------------------------------------------"
        sleep 3
    else
        # Intentar dar permisos explícitos al usuario actual (local)
        xhost +si:localuser:$(whoami) >/dev/null 2>&1
        # Y también local genérico por si acaso (para Docker)
        xhost +local:docker >/dev/null 2>&1
    fi
fi

# 3. Preparar el comando de Docker (pasando variables si se usa sudo)
DOCKER_CMD="docker compose"
if ! docker ps >/dev/null 2>&1; then
    echo "[*] Docker necesita sudo. Pasando variables de entorno..."
    DOCKER_CMD="sudo UID_ENV=$USER_ID GID_ENV=$GROUP_ID DISPLAY=$DISPLAY WAYLAND_DISPLAY=$WAYLAND_DISPLAY XAUTHORITY=$XAUTHORITY docker compose"
else
    # Si no usa sudo, también pasamos las variables
    DOCKER_CMD="UID_ENV=$USER_ID GID_ENV=$GROUP_ID DISPLAY=$DISPLAY WAYLAND_DISPLAY=$WAYLAND_DISPLAY XAUTHORITY=$XAUTHORITY docker compose"
fi

# 4. Arrancar
echo "[*] Reconstruyendo y arrancando contenedor..."
$DOCKER_CMD up --build
