#!/bin/bash

echo "[*] Cleaning up Botifler Docker artifacts..."

# 1. Try standard compose down
if command -v docker-compose >/dev/null 2>&1; then
    echo "[-] Attempting docker-compose down..."
    export DOCKER_BUILDKIT=0
    export COMPOSE_DOCKER_CLI_BUILD=0
    docker-compose down --volumes --remove-orphans || true
fi

# 2. Force remove containers by name pattern
echo "[-] Force removing containers with 'botifler' in name..."
docker ps -a | grep botifler | awk '{print $1}' | xargs -r sudo docker rm -f

# 3. Prune images just in case
# echo "[-] Pruning unused images..."
# docker image prune -f

echo "[*] Cleanup done. You can now run ./run.sh"
