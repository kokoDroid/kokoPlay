#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="kokoplay-certilia"
CONTAINER_NAME="kokoplay-certilia"

docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm -f $CONTAINER_NAME 2>/dev/null || true
docker rmi $IMAGE_NAME 2>/dev/null || true
echo
echo "✅ Certilia container and image removed"
echo
read -n 1 -s -r -p "Press any key to exit..."


