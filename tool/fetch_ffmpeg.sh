#!/usr/bin/env bash
# Récupère le binaire ffmpeg statique (via le paquet npm ffmpeg-static) et le
# place dans assets/bin/ pour le bundling Flutter. Multi-plateforme (mac/win/linux).
set -e
cd "$(dirname "$0")/.."
mkdir -p assets/bin
TMP="$(mktemp -d)"
( cd "$TMP" && npm init -y >/dev/null 2>&1 && npm i ffmpeg-static@5 >/dev/null 2>&1 )
SRC="$TMP/node_modules/ffmpeg-static/ffmpeg"
[ -f "$SRC" ] || SRC="$TMP/node_modules/ffmpeg-static/ffmpeg.exe"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) DST="assets/bin/ffmpeg.exe" ;;
  *) DST="assets/bin/ffmpeg" ;;
esac
cp "$SRC" "$DST"
chmod +x "$DST" 2>/dev/null || true
rm -rf "$TMP"
echo "ffmpeg -> $DST"
