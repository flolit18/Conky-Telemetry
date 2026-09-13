#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONKY_DIR="$HOME/.config/conky"
FONT_DIR="$HOME/.local/share/fonts/Jersey15"
AUTOSTART_DIR="$HOME/.config/autostart"

echo "[1/5] Creating directories..."
mkdir -p "$CONKY_DIR/scripts" "$FONT_DIR" "$AUTOSTART_DIR"

echo "[2/5] Installing Conky configuration..."
cp "$ROOT/conky.conf" "$CONKY_DIR/conky.conf"
cp "$ROOT"/scripts/*.sh "$CONKY_DIR/scripts/"
chmod +x "$CONKY_DIR"/scripts/*.sh

echo "[3/5] Installing Jersey 15..."
FONT_FILE="$FONT_DIR/Jersey15-Regular.ttf"
if [ ! -f "$FONT_FILE" ]; then
    curl -L \
      "https://raw.githubusercontent.com/google/fonts/main/ofl/jersey15/Jersey15-Regular.ttf" \
      -o "$FONT_FILE"
fi
fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || fc-cache -f >/dev/null 2>&1

echo "[4/5] Installing autostart entry..."
sed "s|__HOME__|$HOME|g" \
    "$ROOT/autostart/conky-telemetry.desktop.in" \
    > "$AUTOSTART_DIR/conky-telemetry.desktop"

echo "[5/5] Done."
echo
echo "Start now with:"
echo "  conky -c \"$CONKY_DIR/conky.conf\""
echo
echo "If PKG POWER shows N/A, read README.md -> Intel RAPL."
