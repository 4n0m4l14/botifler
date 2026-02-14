#!/bin/bash

# Script to Uninstall Botifler Systemd Service

SERVICE_NAME="botifler.service"
TIMER_NAME="botifler.timer"
SYSTEMD_DIR="/etc/systemd/system"

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (sudo ./uninstall_service.sh)"
  exit 1
fi

echo "[*] Uninstalling Botifler Service..."

# 1. Stop and Disable
echo "[*] Stopping and disabling service/timer..."
systemctl stop $TIMER_NAME 2>/dev/null
systemctl disable $TIMER_NAME 2>/dev/null
systemctl stop $SERVICE_NAME 2>/dev/null

# 2. Remove files
echo "[*] Removing systemd unit files..."
rm -f $SYSTEMD_DIR/$SERVICE_NAME
rm -f $SYSTEMD_DIR/$TIMER_NAME

# 3. Reload daemon
echo "[*] Reloading systemd daemon..."
systemctl daemon-reload

echo "----------------------------------------------------------------"
echo "SUCCESS! Botifler service has been removed."
echo "----------------------------------------------------------------"
