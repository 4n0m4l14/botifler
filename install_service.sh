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

# 1. Update WorkingDirectory in service file to current location
echo "[*] Updating service file with current directory: $CURRENT_DIR"
sed -i "s|WorkingDirectory=.*|WorkingDirectory=$CURRENT_DIR|" systemd/$SERVICE_NAME

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
