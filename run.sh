#!/bin/bash

# Script Refactorizado para usar DOCKER NATIVO (Sin docker-compose)
# Motivo: Incompatibilidad entre docker-compose v1 y Docker Engine modernos.

# Detectar si necesitamos sudo
SUDO_CMD=""
if ! docker ps >/dev/null 2>&1; then
    SUDO_CMD="sudo"
fi

CONTAINER_NAME="botifler_container"
IMAGE_NAME="botifler:latest"

# 1. Limpieza
if [[ "$1" == "--reset" || "$1" == "--clean" ]]; then
    echo "[!] MODO RESET ACTIVADO"
    echo "[-] Eliminando contenedor antiguo..."
    $SUDO_CMD docker rm -f $CONTAINER_NAME >/dev/null 2>&1 || true
    echo "[-] Limpieza completada."
    sleep 1
fi

# 2. Setup Entorno (Headless vs GUI)
USER_ID=$(id -u)
GROUP_ID=$(id -g)
echo "[*] UID: $USER_ID, GID: $GROUP_ID"

# Leer .env para saber si es headless
HEADLESS=true
if grep -q "BOT_HEADLESS=false" .env 2>/dev/null; then
    HEADLESS=false
fi

# Argumentos base para Docker
DOCKER_ARGS=(
    run --rm 
    --name "$CONTAINER_NAME"
    --env-file .env
    --user "$USER_ID:$GROUP_ID"
    -e PYTHONUNBUFFERED=1
    -e HOME=/home/botuser
    --shm-size=2gb
)

if [ "$HEADLESS" = "false" ]; then
    echo "[*] Modo GUI Activado."
    
    # Configurar xhost
    if command -v xhost >/dev/null 2>&1; then
        xhost +si:localuser:$(whoami) >/dev/null 2>&1
        xhost +local:docker >/dev/null 2>&1
    else
        echo "ADVERTENCIA: xhost no instalado. La GUI podría fallar."
    fi

    # Variables de entorno GUI
    DOCKER_ARGS+=(
        -e DISPLAY=$DISPLAY
        -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY
        -e MOZ_ENABLE_WAYLAND=1
        -e XAUTHORITY=/tmp/.X11-unix/Xauthority
        -e XDG_RUNTIME_DIR=/run/user/$USER_ID
    )
    
    # Volúmenes GUI
    DOCKER_ARGS+=(
        -v /tmp/.X11-unix:/tmp/.X11-unix
        -v $XAUTHORITY:/tmp/.X11-unix/Xauthority:ro
    )
    
    # Soporte Wayland extra
    if [ -n "$WAYLAND_DISPLAY" ]; then
        WAYLAND_SOCKET="/run/user/$USER_ID/$WAYLAND_DISPLAY"
        if [ -S "$WAYLAND_SOCKET" ]; then
             DOCKER_ARGS+=(-v "$WAYLAND_SOCKET:/run/user/$USER_ID/$WAYLAND_DISPLAY")
        fi
    fi
fi

# 3. Build & Run
echo "----------------------------------------------------------------"
echo "[*] Building..."
$SUDO_CMD docker build -t $IMAGE_NAME .

echo "[*] Running..."
# Usar exec para reemplazar el proceso del shell con docker
exec $SUDO_CMD docker "${DOCKER_ARGS[@]}" $IMAGE_NAME
