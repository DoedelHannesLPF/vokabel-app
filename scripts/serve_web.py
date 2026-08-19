#!/usr/bin/env python3
"""Serve Flutter web build locally for iPhone installation."""

from __future__ import annotations

import argparse
import http.server
import socket
import ssl
import subprocess
import sys
from pathlib import Path


def local_ip() -> str:
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.connect(("8.8.8.8", 80))
            return sock.getsockname()[0]
    except OSError:
        return "DEINE-MAC-IP"


def ensure_cert(cert_dir: Path) -> tuple[Path, Path]:
    cert_dir.mkdir(parents=True, exist_ok=True)
    cert = cert_dir / "local-cert.pem"
    key = cert_dir / "local-key.pem"
    if cert.exists() and key.exists():
        return cert, key

    print("→ Erstelle lokales HTTPS-Zertifikat (einmalig)...")
    subprocess.run(
        [
            "openssl",
            "req",
            "-x509",
            "-newkey",
            "rsa:2048",
            "-keyout",
            str(key),
            "-out",
            str(cert),
            "-days",
            "3650",
            "-nodes",
            "-subj",
            "/CN=VokabelApp-Local",
        ],
        check=True,
    )
    return cert, key


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", required=True, help="Web build directory")
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args()

    web_dir = Path(args.directory).resolve()
    if not web_dir.is_dir():
        print(f"Fehler: Verzeichnis nicht gefunden: {web_dir}", file=sys.stderr)
        return 1

    cert_dir = Path(__file__).resolve().parent / ".certs"
    cert, key = ensure_cert(cert_dir)
    ip = local_ip()
    port = args.port

    handler = lambda *handler_args, **handler_kwargs: http.server.SimpleHTTPRequestHandler(  # noqa: E731
        *handler_args, directory=str(web_dir), **handler_kwargs
    )

    httpd = http.server.ThreadingHTTPServer(("0.0.0.0", port), handler)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(certfile=str(cert), keyfile=str(key))
    httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

    url = f"https://{ip}:{port}"
    print("")
    print("Am iPhone in Safari öffnen:")
    print(f"  {url}")
    print("")
    print("Wichtig:")
    print("  - https:// verwenden (nicht http://)")
    print("  - Beim Zertifikat-Hinweis: 'Details anzeigen' → trotzdem fortfahren")
    print("  - Dann: Teilen → Zum Home-Bildschirm")
    print("")
    print("Server läuft. Beenden mit Ctrl+C.")
    print("")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer beendet.")
    finally:
        httpd.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
