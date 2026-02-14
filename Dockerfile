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

# Create a directory for the user home (needed for Firefox)
RUN mkdir -p /home/botuser && chmod 777 /home/botuser

WORKDIR /app

# Ensure /app is writable by any user (since we map UID dynamically)
RUN chmod 777 /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY botifler-0.2.py .

# Set HOME to the directory we created
ENV HOME=/home/botuser

CMD ["python", "botifler-0.2.py"]
