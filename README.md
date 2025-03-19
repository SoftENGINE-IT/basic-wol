# Wake-on-LAN Node.js Service

Dieses Projekt stellt eine kleine **Node.js-Anwendung** bereit, mit der Rechner im lokalen Netzwerk per **Wake-on-LAN** aufgeweckt werden können. Dabei nutzt das Skript [Express](https://www.npmjs.com/package/express) als HTTP-Server und das Paket [wol](https://www.npmjs.com/package/wol), um das Magic Packet zu versenden.

---

## Funktionsweise

1. Ein **Systemd-Service** auf einem Debian-Server sorgt dafür, dass das Node.js-Skript dauerhaft läuft.  
2. Über einen Browseraufruf (z. B. `http://<Server-IP>:5000/`) kann man per Klick bzw. Formular eine definierte **MAC-Adresse** ansprechen.  
3. Das Skript sendet das notwendige **Magic Packet** (Wake-on-LAN) an die Ziel-PCs.

---

## Installation

### 1. Repository klonen

```bash
git clone https://github.com/SoftENGINE-IT/basic-wol.git
```
Anschließend ins neue Verzeichnis wechseln:
```bash
cd basic-wol
```
### 2. Installationsskrip ausführbar machen
```bash
chmod +x install.sh
```

### Installationsskript ausführen
```bash
./install.sh
```
#### Was geschieht dabei?

1. nvm wird installiert (sofern noch nicht vorhanden).
2. Node.js v20.19.0 wird via nvm installiert und aktiviert.
3. Das Verzeichnis /opt/wol-skripte wird (falls nötig) angelegt.
4. Ein Node.js-Projekt wird initialisiert (falls keine package.json vorhanden).
5. Die Pakete express und wol werden installiert.
6. Deine vorhandene index.js wird nach /opt/wol-skripte/ kopiert.
7. Eine systemd-Service-Unit (wol.service) wird erzeugt und aktiviert.
#
Nach Abschluss kann der Status geprüft werden:
```bash
systemctl status wol
```
Die Log-Ausgabe gibt es mit:
```bash
journalctl -u wol -f
```

### Verwendung

Wenn der Service läuft, lauscht deine Anwendung standardmäßig auf Port `5000`.
Rufe also im Browser:
```cpp
http://<IP-Deines-Servers>:5000/
```

### Funktion der index.js

Innerhalb von index.js (in diesem Repo enthalten) findest du u. a. ein Objekt wie dieses:
```js
const WOL_TARGETS = {
    pc1: { mac: '00:11:22:33:44:55', broadcast: '192.168.178.255' },
    pc2: { mac: 'AA:BB:CC:DD:EE:FF', broadcast: '192.168.178.255' },
    pc3: { mac: '11:22:33:44:55:66', broadcast: '192.168.178.255' },
    // Beliebig viele weitere Einträge hinzufügen ...
};
```
- `pc1`, `pc2`, `pc3` sind frei wählbare Schlüssel, um deine Rechner zu benennen.
- `mac` ist die MAC-Adresse des Zielrechners.
- `broadcast` sollte die Broadcast-Adresse deines lokalen Netzwerks sein, z. B. 192.168.178.255

Füge hier beliebig viele weitere Rechner hinzu. Die Anwendung stellt dann entsprechende Routen oder Buttons bereit, um das Magic Packet via

```js
wol.wake(mac, { address: broadcast })
```
#
### Wartung & Weiterentwicklung

- Neustart des Dienstes:
```bash
systemctl restart wol
```
- Deaktivieren des Dienstes:
```bash
systemctl disable wol
systemctl stop wol
```
- Update:
    - Änderungen an `index.js` erneut ins Zielverzeichnis kopieren (oder das Skript neu ausführen).
    - Neue Pakete mit `npm install` im `~/basic-wol`-Verzeichnis installieren.
