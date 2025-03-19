#!/usr/bin/env bash

set -e  # Skript bei Fehler abbrechen

# #########################################################
# Variablen anpassen, falls gewünscht
NVM_VERSION="v0.39.3"
NODE_VERSION="v20.19.0"
SERVICE_NAME="wol"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
WORK_DIR="$(pwd)"   # aktuelles Verzeichnis
MAIN_SCRIPT="index.js"  # Dein Hauptskript
RUN_USER="root"
RUN_GROUP="root"
# #########################################################

echo "=========================================================="
echo "Installationsskript für Node.js via nvm + Systemd-Service"
echo "=========================================================="

# 1) Prüfen, ob nvm bereits existiert
if [ -d "$HOME/.nvm" ]; then
  echo "[INFO] nvm-Verzeichnis gefunden: $HOME/.nvm"
else
  echo "[INFO] nvm nicht gefunden. Installiere nvm $NVM_VERSION ..."
  # NVM installieren (GitHub-Installskript)
  wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
fi

# nvm in diese Shell laden
# Achtung: Standardmäßig wird das in ~/.bashrc oder ~/.profile eingetragen
# Da wir als root laufen, ist HOME=/root
if [ -f "$HOME/.nvm/nvm.sh" ]; then
  # shellcheck source=/dev/null
  source "$HOME/.nvm/nvm.sh"
else
  echo "[FEHLER] Konnte nvm-Skripte nicht finden unter $HOME/.nvm/nvm.sh"
  exit 1
fi

echo "[INFO] Installiere und verwende Node.js $NODE_VERSION ..."
nvm install $NODE_VERSION
nvm alias default $NODE_VERSION
nvm use $NODE_VERSION

echo "[INFO] Ermittle Node-Pfad ..."
NODE_PATH="$(readlink -f "$(which node)")"

if [ -z "$NODE_PATH" ]; then
  echo "[FEHLER] Konnte keinen Node-Binary-Pfad ermitteln."
  exit 1
fi

echo "[INFO] Node-Pfad ist: $NODE_PATH"
echo "[INFO] Erstelle Systemd-Service unter $SERVICE_FILE"

cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Wake on LAN Node.js Service
After=network.target

[Service]
User=$RUN_USER
Group=$RUN_GROUP
WorkingDirectory=$WORK_DIR
ExecStart=$NODE_PATH $WORK_DIR/$MAIN_SCRIPT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "[INFO] Service-Datei erstellt."

echo "[INFO] Systemd neu laden ..."
systemctl daemon-reload

echo "[INFO] Service starten ..."
systemctl start "$SERVICE_NAME"

echo "[INFO] Service beim Systemstart aktivieren ..."
systemctl enable "$SERVICE_NAME"

echo "=========================================================="
echo "[OK] Installation abgeschlossen."
echo "Service-Status prüfen mit: systemctl status $SERVICE_NAME"
echo "Logs ansehen mit:          journalctl -u $SERVICE_NAME -f"
echo "=========================================================="
