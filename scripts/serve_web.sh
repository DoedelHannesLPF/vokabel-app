#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${PORT:-8080}"
cd "$ROOT"

echo "→ Baue Web-App (Release, mit Offline-Cache)..."
flutter build web --release

echo ""
echo "→ Starte lokalen HTTPS-Server auf Port $PORT"
echo ""

python3 "$ROOT/scripts/serve_web.py" --directory "$ROOT/build/web" --port "$PORT"
