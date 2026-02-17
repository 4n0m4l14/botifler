#!/bin/bash

# Script to Install and Enable Botifler Systemd Service
# Refactored to use native docker (via run.sh) and run as the correct user.

SERVICE_NAME="botifler.service"
TIMER_NAME="botifler.timer"
SYSTEMD_DIR="/etc/systemd/system"
CURRENT_DIR=$(pwd)

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (sudo ./install_service.sh)"
  exit 1
fi

# Detect Real User (to run the service as)
if [ -n "$SUDO_USER" ]; then
    REAL_USER=$SUDO_USER
else
    echo "WARNING: Could not detect SUDO_USER. Service will run as root."
    REAL_USER="root"
fi

echo "[*] Installing Botifler Service..."
echo "[*] Service will run as user: $REAL_USER"
echo "[*] Working Directory: $CURRENT_DIR"

# 1. Ensure run.sh is executable
chmod +x "$CURRENT_DIR/run.sh"

# 2. Create Service File content
# We write directly to the destination to avoid messing with local templates
cat <<EOF > "$SYSTEMD_DIR/$SERVICE_NAME"
[Unit]
Description=Botifler Daily Run
After=docker.service network-online.target
Requires=docker.service

[Service]
Type=oneshot
User=$REAL_USER
WorkingDirectory=$CURRENT_DIR
# We simply delegate to run.sh which handles docker build & run
ExecStart=$CURRENT_DIR/run.sh
# Optional: Cleanup is handled inside run.sh with --rm

[Install]
WantedBy=multi-user.target
EOF

# 3. Copy Timer file
# We assume the timer file in systemd/ is still valid (it just triggers the service)
if [ -f "systemd/$TIMER_NAME" ]; then
    cp systemd/$TIMER_NAME "$SYSTEMD_DIR/"
else
    # Fallback if timer file missing
    echo "[!] Timer file missing, creating default..."
    cat <<EOF > "$SYSTEMD_DIR/$TIMER_NAME"
[Unit]
Description=Run Botifler Daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF
fi

# 4. Reload daemon
echo "[*] Reloading systemd daemon..."
systemctl daemon-reload

# 5. Enable and start timer
echo "[*] Enabling and starting timer..."
systemctl enable $TIMER_NAME
systemctl start $TIMER_NAME

echo "----------------------------------------------------------------"
echo "SUCCESS! Botifler is scheduled to run daily."
echo "Service User: $REAL_USER"
echo "Check timer status: systemctl list-timers --all | grep botifler"
echo "Check service logs: journalctl -u $SERVICE_NAME -f"
echo "----------------------------------------------------------------"
