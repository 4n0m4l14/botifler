# Botifler - Automated CodeLearn Bot

Botifler is an automated bot for completing daily tasks on CodeLearn. It is robust, dockerized, and supports both **headless** (invisible) and **GUI** (visible browser) modes on Linux (X11/Wayland).

## Features
*   **Automated Games**: Completes "Austins Powers" and "Typing Race".
*   **Smart Environment Detection**: Adapts to running natively or inside Docker.
*   **Cross-Platform GUI**: Can show the browser window even from inside Docker (Linux).
*   **Scheduled**: Systemd timers for set-and-forget daily execution.
*   **Configurable**: Easy `.env` configuration.

## Prerequisites

*   **Docker** & **Docker Compose**
*   **Git**
*   **(Optional) `xorg-xhost`**: Required only if you want to see the browser window (GUI mode) on Linux.
    *   Arch Linux: `sudo pacman -S xorg-xhost`
    *   Ubuntu/Debian: `sudo apt install x11-xserver-utils`

## Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/4n0M4l14/botifler.git
    cd botifler
    ```

2.  **Configure Environment**:
    Create a `.env` file (or edit exisiting):
    ```env
    BOT_USER=your_email@example.com
    BOT_PASSWORD=your_password
    BOT_CYCLES=4
    BOT_HEADLESS=false  # Set to 'true' for invisible mode, 'false' to see the browser
    ```

## Usage

### The Easy Way (Recommended)
Use the provided script. It handles permissions, detects your screen server (Wayland/X11), and builds the container.

```bash
./run.sh
```

### Manual Docker Command
If you prefer running docker directly (headless mode recommended for this):

```bash
sudo docker compose up --build
```

## Troubleshooting

### 1. "Process unexpectedly closed with status 1" (Firefox crash)
*   **Cause**: Docker container cannot access your screen or is running as a restricted user without permissions.
*   **Solution**: Use `./run.sh` instead of `docker compose up`. The script automatically sets the correct User ID and permissions.

### 2. Browser window doesn't appear
*   **Check `.env`**: Ensure `BOT_HEADLESS=false`.
*   **Check `xhost`**: Run `xhost +local:docker` in your terminal. If command not found, install `xorg-xhost`.
*   **Wayland**: If using Wayland, ensure you are running the script as your user (not root, though the script handles sudo internally).

### 3. "Authorization required, but no authorization protocol specified"
*   **Solution**: Run `xhost +si:localuser:$(whoami)` and try again. The `./run.sh` script attempts to do this automatically.

### 4. Git Push Issues
*   Ensure you have created the repository on GitHub and authenticated using `gh auth login` or set up SSH keys.

## Daily Schedule (Systemd)

To run the bot automatically every day (Headless mode recommended):

1.  Edit `.env` and set `BOT_HEADLESS=true`.
2.  Install systemd service:
    ```bash
    sudo cp systemd/botifler.service /etc/systemd/system/
    sudo cp systemd/botifler.timer /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable --now botifler.timer
    ```
