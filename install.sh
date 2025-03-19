#!/usr/bin/env bash

set -e  # Skript bei Fehler abbrechen

# #########################################################
# Variablen anpassen, falls gewünscht
NVM_VERSION="v0.39.3"
NODE_VERSION="v20.19.0"
SERVICE_NAME="wol"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# Verzeichnis für die WOL-Skripte:
WORK_DIR="/opt/wol-skripte"

# Hauptskript, das Node starten soll:
MAIN_SCRIPT="index.js"

# Benutzer/Guppe, unter dem der Service laufen soll:
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
if [ -f "$HOME/.nvm/nvm.sh" ]; then
  source "$HOME/.nvm/nvm.sh"
else
  echo "[FEHLER] Konnte nvm-Skripte nicht finden unter $HOME/.nvm/nvm.sh"
  exit 1
fi

# 2) Node.js installieren
echo "[INFO] Installiere und verwende Node.js $NODE_VERSION ..."
nvm install $NODE_VERSION
nvm alias default $NODE_VERSION
nvm use $NODE_VERSION

# 3) Projektverzeichnis erstellen (falls nicht existiert)
if [ ! -d "$WORK_DIR" ]; then
  echo "[INFO] Erstelle Projektverzeichnis: $WORK_DIR"
  mkdir -p "$WORK_DIR"
fi

# 4) Projekt initialisieren (falls kein package.json vorhanden)
cd "$WORK_DIR"
if [ ! -f "package.json" ]; then
  echo "[INFO] Initialisiere neues Node-Projekt ..."
  npm init -y
fi

# 5) Pakete installieren (express, wol) - falls nicht schon vorhanden
echo "[INFO] Installiere benötigte Pakete express & wol ..."
npm install express wol

# 6) Beispielscript index.js anlegen, falls es noch nicht existiert
if [ ! -f "$MAIN_SCRIPT" ]; then
  echo "[INFO] Erstelle Beispielscript: $MAIN_SCRIPT"
  cat <<EOF > "$MAIN_SCRIPT"
const express = require('express');
const wol = require('wol');
const app = express();

app.use(express.urlencoded({ extended: true }));

app.get('/', (req, res) => {
  res.send(\`
    <!DOCTYPE html>
    <html>
      <head><title>WOL</title></head>
      <body>
        <h1>Wake on LAN</h1>
        <form method="POST" action="/wake">
          <label for="mac">MAC-Adresse:</label>
          <input id="mac" name="mac" required>
          <label for="broadcast">Broadcast:</label>
          <input id="broadcast" name="broadcast" required>
          <button type="submit">Wecken</button>
        </form>
      </body>
    </html>
  \`);
});

app.post('/wake', (req, res) => {
  const { mac, broadcast } = req.body;
  if (!mac || !broadcast) {
    return res.status(400).send('MAC und Broadcast werden benötigt!');
  }
  wol.wake(mac, { address: broadcast }, (err, result) => {
    if (err) {
      return res.status(500).send('Fehler beim Versenden des Magic Packet: ' + err);
    }
    if (result) {
      return res.send(\`Magic Packet an \${mac} (Broadcast: \${broadcast}) gesendet.\`);
    } else {
      return res.status(500).send('Konnte Magic Packet nicht senden.');
    }
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(\`WOL-Service läuft auf Port \${PORT}\`);
});
EOF
fi

# 7) Ermitteln des absoluten Pfads zum Node-Binary
echo "[INFO] Ermittle Node-Pfad ..."
NODE_PATH="$(readlink -f "$(which node)")"
if [ -z "$NODE_PATH" ]; then
  echo "[FEHLER] Konnte keinen Node-Binary-Pfad ermitteln."
  exit 1
fi
echo "[INFO] Node-Pfad ist: $NODE_PATH"

# 8) Service-Datei erstellen
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

# 9) Service laden, starten, aktivieren
echo "[INFO] Systemd neu laden ..."
systemctl daemon-reload

echo "[INFO] Service starten ..."
systemctl start "$SERVICE_NAME"

echo "[INFO] Service beim Systemstart aktivieren ..."
systemctl enable "$SERVICE_NAME"

# 10) Zusammenfassung
echo "=========================================================="
echo "[OK] Installation abgeschlossen."
echo "Der Service '$SERVICE_NAME' läuft jetzt unter $WORK_DIR."
echo "Service-Status prüfen mit: systemctl status $SERVICE_NAME"
echo "Logs ansehen mit:          journalctl -u $SERVICE_NAME -f"
echo "Webinterface:              http://<Server-IP>:5000/"
echo "=========================================================="