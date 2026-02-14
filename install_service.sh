#!/bin/bash

# Script to Install and Enable Botifler Systemd Service

SERVICE_NAME="botifler.service"
TIMER_NAME="botifler.timer"
SYSTEMD_DIR="/etc/systemd/system"
CURRENT_DIR=$(pwd)

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (sudo ./install_service.sh)"
  exit 1
fi

echo "[*] Installing Botifler Service..."

# Detect correct docker compose command path
if docker compose version >/dev/null 2>&1; then
    # Docker V2 (plugin)
    DOCKER_BIN=$(which docker)
    COMPOSE_CMD="$DOCKER_BIN compose"
elif command -v docker-compose >/dev/null 2>&1; then
    # Docker V1 (standalone)
    COMPOSE_CMD=$(which docker-compose)
    
    # Inject environment variables for legacy compatibility into the service file
    echo "[*] Legacy docker-compose detected. Patching service for BuildKit compatibility..."
    # Insert after [Service]
    sed -i '/\[Service\]/a Environment="COMPOSE_DOCKER_CLI_BUILD=0"' systemd/$SERVICE_NAME
    sed -i '/\[Service\]/a Environment="DOCKER_BUILDKIT=0"' systemd/$SERVICE_NAME
else
    echo "ERROR: Could not find 'docker compose' or 'docker-compose'."
    exit 1
fi

echo "[*] Detected Compose Command: $COMPOSE_CMD"

# 1. Update Service File
echo "[*] Updating service file configuration..."
sed -i "s|WorkingDirectory=.*|WorkingDirectory=$CURRENT_DIR|" systemd/$SERVICE_NAME

# Update ExecStartPre and ExecStart dynamically
# We use a placeholder or overwrite lines 10 and 12 specifically if possible, or just replace the detection pattern
# Since we don't know the exact lines in target sed easily without regex, we assume standard format
sed -i "s|ExecStartPre=.*|ExecStartPre=$COMPOSE_CMD build|" systemd/$SERVICE_NAME
sed -i "s|ExecStart=.*|ExecStart=$COMPOSE_CMD up --abort-on-container-exit|" systemd/$SERVICE_NAME

# 2. Copy files
echo "[*] Copying systemd unit files..."
cp systemd/$SERVICE_NAME $SYSTEMD_DIR/
cp systemd/$TIMER_NAME $SYSTEMD_DIR/

# 3. Reload daemon
echo "[*] Reloading systemd daemon..."
systemctl daemon-reload

# 4. Enable and start timer
echo "[*] Enabling and starting timer..."
systemctl enable $TIMER_NAME
systemctl start $TIMER_NAME

echo "----------------------------------------------------------------"
echo "SUCCESS! Botifler is scheduled to run daily."
echo "Check timer status: systemctl list-timers --all | grep botifler"
echo "Check service logs: journalctl -u $SERVICE_NAME -f"
echo "----------------------------------------------------------------"
