#!/bin/bash
set -e

if [ ! -s /etc/hostname ]; then
  ID=$(cat /etc/machine-id 2>/dev/null | cut -c1-6)

  # fallback if machine-id not ready yet
  if [ -z "$ID" ]; then
    ID=$(head -c6 /dev/urandom | tr -dc a-f0-9)
  fi

  HOST="kokoplay-$ID"

  echo "$HOST" > /etc/hostname
  hostnamectl set-hostname "$HOST"
fi