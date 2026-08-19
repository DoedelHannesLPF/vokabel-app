# Vokabel App als Web-App auf dem iPhone

Die Web-Version speichert alle Daten **lokal auf dem iPhone** (localStorage).
Es gibt **kein 7-Tage-Ablauf** wie bei der nativen Debug-App.

---

## Einmalige Installation

### 1. Mac und iPhone vorbereiten

- Mac und iPhone im **gleichen WLAN**
- Flutter ist installiert (`flutter --version`)

### 2. Web-App bauen und starten

Im Terminal:

```bash
cd ~/Developer/VokabelApp
chmod +x scripts/serve_web.sh
./scripts/serve_web.sh
```

Das Skript baut die App und startet einen **HTTPS-Server** im lokalen Netzwerk.
Die URL wird im Terminal angezeigt, z. B.:

```
https://192.168.178.61:8080
```

**Wichtig:** `https://` verwenden, nicht `http://`.

### 3. Am iPhone installieren

1. **Safari** öffnen (nicht Chrome)
2. Die **https://**-URL aus dem Terminal eingeben
3. Beim Zertifikat-Hinweis: **Details anzeigen** → **Website besuchen** / trotzdem fortfahren
4. Warten, bis die App vollständig geladen ist
5. **Teilen** (Quadrat mit Pfeil) → **Zum Home-Bildschirm**
6. Name bestätigen → **Hinzufügen**

Die App erscheint als Icon auf dem Home-Bildschirm.

### 4. Server beenden

Im Terminal **Ctrl+C** drücken. Die App auf dem iPhone funktioniert danach weiter.

---

## Danach nutzen

- App **immer über das Home-Bildschirm-Icon** starten (nicht über Safari-Lesezeichen)
- **Flugmodus** und **ohne Mac** funktionieren, sobald die App einmal geladen war
- Deine Vokabeln, Fortschritte und Konten bleiben auf dem iPhone

---

## App aktualisieren (nach Code-Änderungen)

1. Am Mac erneut ausführen:

   ```bash
   ./scripts/serve_web.sh
   ```

2. Am iPhone die App **über Safari** einmal neu laden (gleiche URL wie bei der Installation)
3. Seite schließen und die App erneut über das **Home-Bildschirm-Icon** öffnen

---

## Wichtige Hinweise

| Thema | Hinweis |
|---|---|
| **Daten** | Liegen nur auf dem iPhone, nicht auf dem Mac oder im Internet |
| **Mac-IP ändert sich** | Wenn sich die IP ändert, ist es technisch eine „neue“ App – Daten wären getrennt. IP im Router fest vergeben oder immer dieselbe URL nutzen |
| **Safari-Daten löschen** | Kann App-Daten mit löschen – in iOS-Einstellungen vermeiden |
| **Native vs. Web** | Das sind zwei getrennte Installationen mit getrennten Daten |

---

## Alternative: Stabile URL (optional)

Wenn die Mac-IP oft wechselt, kann die App einmalig auf kostenlosem Static Hosting liegen (z. B. GitHub Pages). Nur die App-Dateien werden hochgeladen – **keine persönlichen Vokabeldaten**.
