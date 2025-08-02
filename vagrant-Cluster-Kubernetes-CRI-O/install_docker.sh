#!/bin/bash

## install registry

IP=$(hostname -I | awk '{print $2}')

echo "START - install docker - "$IP

echo "[1]: install docker"
apt-get update -qq >/dev/null  # -qq Exécute la commande de manière très silencieuse, sans afficher les détails.
apt-get install -qq -y git wget curl git >/dev/null  # >/dev/null : Redirige la sortie de la commande vers dev/null, ce qui signifie qu'aucune information n'est affichée dans le terminal.
curl -fsSL https://get.docker.com | sh; >/dev/null 

# curl -fsSL https://get.docker.com : Télécharge le script d'installation de Docker à partir de l'URL https://get.docker.com.
# -f : Ignore les erreurs HTTP.
# -s : Mode silencieux, pas de progression affichée.
# -S : Affiche les erreurs si elles se produisent.
# -L : Suivre les redirections d'URL.