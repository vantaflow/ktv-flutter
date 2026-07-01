#!/usr/bin/env bash
# Récupère les binaires bundlés dans assets/bin/ : ffmpeg (via npm ffmpeg-static)
# et cloudflared (release GitHub, pour le tunnel). Multi-plateforme (mac/win/linux).
set -e
cd "$(dirname "$0")/.."
mkdir -p assets/bin
TMP="$(mktemp -d)"

# --- ffmpeg ---
( cd "$TMP" && npm init -y >/dev/null 2>&1 && npm i ffmpeg-static@5 >/dev/null 2>&1 )
SRC="$TMP/node_modules/ffmpeg-static/ffmpeg"
[ -f "$SRC" ] || SRC="$TMP/node_modules/ffmpeg-static/ffmpeg.exe"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) DST="assets/bin/ffmpeg.exe" ;;
  *) DST="assets/bin/ffmpeg" ;;
esac
cp "$SRC" "$DST"
chmod +x "$DST" 2>/dev/null || true
echo "ffmpeg -> $DST"

# --- cloudflared (tunnel Cloudflare) ---
CF_BASE="https://github.com/cloudflare/cloudflared/releases/latest/download"
ARCH="$(uname -m)"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    curl -fL -o assets/bin/cloudflared.exe "$CF_BASE/cloudflared-windows-amd64.exe"
    echo "cloudflared -> assets/bin/cloudflared.exe" ;;
  Darwin)
    case "$ARCH" in arm64) CFA=arm64 ;; *) CFA=amd64 ;; esac
    curl -fL -o "$TMP/cf.tgz" "$CF_BASE/cloudflared-darwin-$CFA.tgz"
    tar xzf "$TMP/cf.tgz" -C assets/bin/
    chmod +x assets/bin/cloudflared
    echo "cloudflared -> assets/bin/cloudflared ($CFA)" ;;
  *)
    curl -fL -o assets/bin/cloudflared "$CF_BASE/cloudflared-linux-amd64"
    chmod +x assets/bin/cloudflared
    echo "cloudflared -> assets/bin/cloudflared" ;;
esac

rm -rf "$TMP"
