# Vokabel App auf GitHub Pages (iPhone)

Die App läuft unter einer **echten HTTPS-URL** ohne Zertifikats-Warnung.
Deine Vokabeldaten bleiben **lokal auf dem iPhone** — es werden nur App-Dateien gehostet.

---

## Einmalige Einrichtung

### 1. Repository auf GitHub erstellen

1. Öffne [github.com/new](https://github.com/new)
2. **Repository name:** `vokabel-app` (oder ein anderer Name — URL passt sich an)
3. **Private** empfohlen (der Code bleibt privat; die Web-Seite ist trotzdem öffentlich erreichbar)
4. **Kein** README, .gitignore oder License hinzufügen
5. **Create repository** klicken

### 2. Projekt hochladen

Im Terminal (GitHub-Benutzername einsetzen):

```bash
cd ~/Developer/VokabelApp
git init
git add .
git commit -m "Initial commit: Vokabel App"
git branch -M main
git remote add origin https://github.com/DEIN-USERNAME/vokabel-app.git
git push -u origin main
```

Beim Push: GitHub-Benutzername und **Personal Access Token** als Passwort (nicht dein GitHub-Passwort).
Token erstellen: GitHub → Settings → Developer settings → Personal access tokens → Generate (Scope: `repo`).

### 3. GitHub Pages aktivieren

1. Repository auf GitHub öffnen
2. **Settings** → **Pages**
3. **Build and deployment** → Source: **GitHub Actions**
4. Fertig — der erste Push startet automatisch einen Deploy

Deploy-Status: Tab **Actions** → Workflow „Deploy Web App to GitHub Pages“ (ca. 2–4 Minuten).

### 4. URL der App

Nach erfolgreichem Deploy:

```
https://DEIN-USERNAME.github.io/vokabel-app/
```

(Der Repository-Name muss im Pfad vorkommen.)

---

## Am iPhone installieren

1. URL in **Safari** öffnen — **keine** Sicherheitswarnung
2. Warten, bis die App geladen ist
3. **Teilen** → **Zum Home-Bildschirm** → **Hinzufügen**
4. App künftig nur über das **Home-Bildschirm-Icon** starten

---

## Updates deployen

Nach Code-Änderungen am Mac:

```bash
cd ~/Developer/VokabelApp
git add .
git commit -m "Beschreibung der Änderung"
git push
```

Nach dem Deploy (Actions grün): App auf dem iPhone einmal schließen und über das Icon neu öffnen.

---

## Hinweise

| Thema | Details |
|---|---|
| **Daten** | Liegen nur auf dem iPhone (localStorage), nicht auf GitHub |
| **Alte lokale Web-App** | Separate Installation — Daten sind getrennt |
| **Repository-Name geändert?** | In `.github/workflows/deploy-pages.yml` passt `--base-href` automatisch mit an |
