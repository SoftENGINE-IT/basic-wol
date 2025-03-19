const express = require('express');
const wol = require('wol');
const app = express();

// Middleware zum Auslesen von POST-Daten (z. B. aus Formular)
app.use(express.urlencoded({ extended: true }));

// Statische Buttons: Wir definieren hier die Zuordnung "PC-Name" -> {MAC, Broadcast}.
const WOL_TARGETS = {
    pc1: { mac: '00:11:22:33:44:55', broadcast: '192.168.178.255' },
    pc2: { mac: 'AA:BB:CC:DD:EE:FF', broadcast: '192.168.178.255' },
    pc3: { mac: '11:22:33:44:55:66', broadcast: '192.168.178.255' },
    // Beliebig viele weitere Einträge hinzufügen ...
};

// Unsere kleine HTML-Seite mit Buttons für jeden PC:
const HTML_PAGE = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Wake on LAN</title>
</head>
<body>
  <h1>Wake on LAN</h1>
  <p>Wähle den PC aus, den du aufwecken möchtest:</p>
  <form action="/wake" method="post">
    <button type="submit" name="target" value="pc1">Rechner 1</button>
    <button type="submit" name="target" value="pc2">Rechner 2</button>
    <button type="submit" name="target" value="pc3">Rechner 3</button>
  </form>
</body>
</html>
`;

// GET-Route: Liefert unser HTML mit den statischen Buttons
app.get('/', (req, res) => {
  res.send(HTML_PAGE);
});

// POST-Route zum Wecken per Magic Packet
app.post('/wake', (req, res) => {
  // "target" ist der Name, den wir oben in value="pc1/pc2/pc3" verwenden
  const targetKey = req.body.target;
  const target = WOL_TARGETS[targetKey];

  if (!target) {
    // Unbekannter Target-Name
    return res.status(400).send('Unbekannter PC!');
  }

  // Magic Packet über "wol" abschicken
  wol.wake(target.mac, { address: target.broadcast }, (err, result) => {
    if (err) {
      return res.status(500).send('Fehler beim Senden des Magic Packets: ' + err);
    }
    if (result) {
      return res.send(
        `Magic Packet an <strong>${target.mac}</strong> (Broadcast: <strong>${target.broadcast}</strong>) gesendet.`
      );
    } else {
      return res.status(500).send('Konnte Magic Packet nicht senden.');
    }
  });
});

// Server auf Port 5000 starten
app.listen(5000, () => {
  console.log('Server läuft auf Port 5000');
});
