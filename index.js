const express = require('express');
const wol = require('wol');
const app = express();

app.use(express.urlencoded({ extended: true }));

// Deine Wake-on-LAN Daten
const WOL_TARGETS = {
  pc1: { mac: '00:11:22:33:44:55', broadcast: '192.168.178.255' },
  // etc.
};

// HTML mit Button, der target=pc1, pc2 etc. liefert
const HTML_PAGE = `
<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>Wake on LAN</title>
</head>
<body>
  <h1>Wake on LAN</h1>
  <p>Wähle den PC/Server aus, den du aufwecken möchtest:</p>
  <form action="/wake" method="post">
    <button type="submit" name="target" value="pc1">Büro-PC</button>
    <!-- Weitere Buttons -->
  </form>
</body>
</html>
`;

app.get('/', (req, res) => {
  res.send(HTML_PAGE);
});

app.post('/wake', (req, res) => {
  const targetKey = req.body.target;
  const target = WOL_TARGETS[targetKey];
  if (!target) {
    return res.status(400).send('Unbekannter PC!');
  }

  wol.wake(target.mac, { address: target.broadcast }, (err, result) => {
    if (err) {
      return res.status(500).send('Fehler beim Senden des Magic Packets: ' + err);
    }
    if (result) {
      // Erfolgsfall: Zusätzlichen "Zurück"-Button ausgeben
      return res.send(`
        <p>Magic Packet an <strong>${target.mac}</strong> 
           (Broadcast: <strong>${target.broadcast}</strong>) gesendet.</p>
        <form action="/" method="GET">
          <button type="submit">Zurück</button>
        </form>
      `);
    } else {
      return res.status(500).send('Konnte Magic Packet nicht senden.');
    }
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log('Server läuft auf Port ' + PORT);
});
