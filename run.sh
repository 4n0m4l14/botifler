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
# 3. Detectar comando Compose (V2 vs V1)
if docker compose version >/dev/null 2>&1; then
    BASE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    BASE_CMD="docker-compose"
else
    echo "ERROR: No se encontró 'docker compose' ni 'docker-compose'."
    exit 1
fi

# 4. Preparar el comando de Docker (pasando variables y sudo si hace falta)
DOCKER_CMD="$BASE_CMD"

# Chequeamos si necesitamos sudo para docker
NEED_SUDO=0
if ! docker ps >/dev/null 2>&1; then
    NEED_SUDO=1
fi

# Construimos el prefijo de variables
ENV_VARS="UID_ENV=$USER_ID GID_ENV=$GROUP_ID DISPLAY=$DISPLAY WAYLAND_DISPLAY=$WAYLAND_DISPLAY XAUTHORITY=$XAUTHORITY"

if [ $NEED_SUDO -eq 1 ]; then
    echo "[*] Docker necesita sudo. Pasando variables de entorno..."
    DOCKER_CMD="sudo $ENV_VARS $BASE_CMD"
else
    DOCKER_CMD="$ENV_VARS $BASE_CMD"
fi

# 5. Arrancar
echo "[*] Usando comando: $BASE_CMD"
echo "[*] Reconstruyendo y arrancando contenedor..."
# Nota: eval es necesario aquí para que las variables de entorno se interpreten correctamente antes del comando
eval $DOCKER_CMD up --build
