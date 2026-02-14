FROM python:3.9-slim

# Install Firefox and GUI dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    firefox-esr \
    wget \
    libgtk-3-0 \
    libdbus-glib-1-2 \
    libxt6 \
    libx11-xcb1 \
    libnss3 \
    libasound2 \
    libgl1 \
    libpci3 \
    libegl1 \
    && rm -rf /var/lib/apt/lists/*

# Install Geckodriver (Multi-arch support)
RUN ARCH=$(dpkg --print-architecture) && \
    GECKO_VER=v0.36.0 && \
    if [ "$ARCH" = "amd64" ]; then \
    URL="https://github.com/mozilla/geckodriver/releases/download/$GECKO_VER/geckodriver-$GECKO_VER-linux64.tar.gz"; \
    elif [ "$ARCH" = "arm64" ]; then \
    URL="https://github.com/mozilla/geckodriver/releases/download/$GECKO_VER/geckodriver-$GECKO_VER-linux-aarch64.tar.gz"; \
    else \
    echo "Unsupported architecture: $ARCH"; exit 1; \
    fi && \
    echo "Downloading Geckodriver for $ARCH..." && \
    wget $URL -O /tmp/geckodriver.tar.gz && \
    tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin/ && \
    rm /tmp/geckodriver.tar.gz && \
    chmod +x /usr/local/bin/geckodriver

# Create a directory for the user home (needed for Firefox)
RUN mkdir -p /home/botuser && chmod 777 /home/botuser

WORKDIR /app

# Ensure /app is writable by any user (since we map UID dynamically)
RUN chmod 777 /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# Set HOME to the directory we created
ENV HOME=/home/botuser

CMD ["python", "main.py"]
