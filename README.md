# Botifler - Automated CodeLearn Bot

Botifler is an automated bot for completing daily tasks on CodeLearn. It is designed to run in a Docker container, headless, and scheduled daily via systemd.

## Features
*   **Automated Games**: Completes "Austins Powers" and "Typing Race".
*   **Dockerized**: Isolated environment with Firefox and Selenium.
*   **Scheduled**: Runs automatically daily using systemd timers.
*   **Configurable**: Number of cycles and credentials via `.env`.

## Installation

### Prerequisites
*   Docker & Docker Compose
*   Git

### Setup

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/4n0M4l14/botifler.git
    cd botifler
    ```

2.  **Configure Environment**:
    Create a `.env` file based on the example (or just edit the existing one if pulling my changes):
    ```env
    BOT_USER=your_email@example.com
    BOT_PASSWORD=your_password
    BOT_CYCLES=4
    ```

3.  **Build and Run**:
    ```bash
    docker compose up --build
    ```

## Daily Schedule (Linux/Systemd)

To run the bot automatically every day:

1.  Copy the systemd files:
    ```bash
    sudo cp systemd/botifler.service /etc/systemd/system/
    sudo cp systemd/botifler.timer /etc/systemd/system/
    ```

2.  Reload and Enable:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable --now botifler.timer
    ```

3.  Check status:
    ```bash
    systemctl list-timers --all
    ```

## Development

To run locally without Docker (requires Firefox and Geckodriver installed):
```bash
pip install -r requirements.txt
python botifler-0.2.py
```
