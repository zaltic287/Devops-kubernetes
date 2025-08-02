#!/bin/bash

## install postgres

IP=$(hostname -I | awk '{print $2}')
echo "START - install postgres - "$IP

echo "[1]: install utils and postgres"
apt-get update -qq >/dev/null
apt-get install -qq -y wget unzip postgresql-10 >/dev/null

echo "END - install postgres"

