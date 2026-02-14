#!/bin/bash

# Script para arrancar el bot detectando el entorno (X11 vs Wayland)

# Detectar si necesitamos sudo para docker
SUDO_CMD=""
if ! docker ps >/dev/null 2>&1; then
    SUDO_CMD="sudo"
fi

# 1. Detectar Argumentos (Reset/Clean)
if [[ "$1" == "--reset" || "$1" == "--clean" ]]; then
    echo "[!] MODO RESET ACTIVADO"
    echo "[-] Deteniendo y limpiando contenedores antiguos..."
    
    # Intentar limpiar con docker-compose si existe
    if command -v docker-compose >/dev/null 2>&1; then
        export DOCKER_BUILDKIT=0
        export COMPOSE_DOCKER_CLI_BUILD=0
        # Usamos el prefijo sudo si es necesario
        $SUDO_CMD docker-compose down --volumes --remove-orphans 2>/dev/null || true
    fi
    
    # Limpieza forzada de contenedores zombies
    echo "[-] Forzando eliminación de contenedores 'botifler'..."
    # Importante: docker ps necesita sudo también si docker lo necesita
    $SUDO_CMD docker ps -a | grep botifler | awk '{print $1}' | xargs -r $SUDO_CMD docker rm -f
    
    echo "[-] Limpieza completada. Continuando con arranque normal..."
    echo "---------------------------------------------------------"
    sleep 2
fi

# 2. Detectar Servidor Gráfico y permisos
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
    # FORZAR compatibilidad con versiones antiguas (evita error KeyError: 'ContainerConfig')
    export DOCKER_BUILDKIT=0
    export COMPOSE_DOCKER_CLI_BUILD=0
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
