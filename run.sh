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
    BASE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    BASE_CMD=(docker-compose)
else
    echo "ERROR: No se encontró 'docker compose' ni 'docker-compose'."
    exit 1
fi

# 4. Seleccionar archivos Compose
# Por defecto usamos el base (headless)
COMPOSE_FILES=("-f" "docker-compose.yml")

# Si NO es headless, agregamos el override de GUI
if grep -q "BOT_HEADLESS=false" .env 2>/dev/null; then
    echo "[*] Modo GUI Activado: Incluyendo configuración gráfica..."
    COMPOSE_FILES+=("-f" "docker-compose.gui.yml")
fi

# 5. Preparar variables de entorno y comando final
# Definimos las variables individuales
V_UID="UID_ENV=$USER_ID"
V_GID="GID_ENV=$GROUP_ID"
V_DISPLAY="DISPLAY=$DISPLAY"
V_WAYLAND="WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
V_XAUTH="XAUTHORITY=$XAUTHORITY"

# Chequeamos si necesitamos sudo
if ! docker ps >/dev/null 2>&1; then
    echo "[*] Docker necesita sudo. Preparando comando..."
    # sudo acepta asignaciones de variables antes del comando: sudo VAR=VAL cmd
    FINAL_CMD=(sudo "$V_UID" "$V_GID" "$V_DISPLAY" "$V_WAYLAND" "$V_XAUTH" "${BASE_CMD[@]}" "${COMPOSE_FILES[@]}" up --build)
else
    # Sin sudo, usamos env para pasar las variables limpiamente
    # env VAR=VAL cmd
    FINAL_CMD=(env "$V_UID" "$V_GID" "$V_DISPLAY" "$V_WAYLAND" "$V_XAUTH" "${BASE_CMD[@]}" "${COMPOSE_FILES[@]}" up --build)
fi

# 6. Arrancar
echo "[*] Ejecutando: ${FINAL_CMD[*]}"
"${FINAL_CMD[@]}"
