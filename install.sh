#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONKY_DIR="$HOME/.config/conky"
FONT_DIR="$HOME/.local/share/fonts/Jersey15"
AUTOSTART_DIR="$HOME/.config/autostart"
SYSTEMD_DIR="$HOME/.config/systemd/user"

echo "[1/7] Creating directories..."
mkdir -p "$CONKY_DIR/scripts" "$CONKY_DIR/spectrum" "$FONT_DIR" \
         "$AUTOSTART_DIR" "$SYSTEMD_DIR"

echo "[2/7] Installing Conky configuration..."
cp "$ROOT/conky.conf" "$CONKY_DIR/conky.conf"
cp "$ROOT/conky-spectrum.conf" "$CONKY_DIR/conky-spectrum.conf"
cp "$ROOT"/scripts/*.sh "$CONKY_DIR/scripts/"
chmod +x "$CONKY_DIR"/scripts/*.sh

echo "[3/7] Installing spectrum analyser..."
cp "$ROOT"/spectrum/spectrum.lua \
   "$ROOT"/spectrum/spectrum_bridge.py \
   "$ROOT"/spectrum/cava.conf \
   "$ROOT"/spectrum/start-spectrum.sh \
   "$CONKY_DIR/spectrum/"
chmod 644 "$CONKY_DIR"/spectrum/spectrum.lua "$CONKY_DIR"/spectrum/cava.conf
chmod 755 "$CONKY_DIR"/spectrum/start-spectrum.sh \
          "$CONKY_DIR"/spectrum/spectrum_bridge.py

# Conky does expand ~ in lua_load, but the installed copy is made
# explicit so it never depends on that.
sed -i "s|^    lua_load = .*|    lua_load = '$CONKY_DIR/spectrum/spectrum.lua',|" \
    "$CONKY_DIR/conky-spectrum.conf"

echo "[4/7] Installing spectrum systemd user service..."
cp "$ROOT/system/conky-spectrum.service" "$SYSTEMD_DIR/conky-spectrum.service"
systemctl --user daemon-reload >/dev/null 2>&1 || true

echo "[5/7] Installing Jersey 15..."
FONT_FILE="$FONT_DIR/Jersey15-Regular.ttf"
if [ ! -f "$FONT_FILE" ]; then
    curl -L \
      "https://raw.githubusercontent.com/google/fonts/main/ofl/jersey15/Jersey15-Regular.ttf" \
      -o "$FONT_FILE"
fi
fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || fc-cache -f >/dev/null 2>&1

echo "[6/7] Installing autostart entry..."
sed "s|__HOME__|$HOME|g" \
    "$ROOT/autostart/conky-telemetry.desktop.in" \
    > "$AUTOSTART_DIR/conky-telemetry.desktop"

echo "[7/7] Done."
echo
echo "Start both Conky windows now with:"
echo "  \"$CONKY_DIR/scripts/start-conky.sh\""
echo
echo "Enable the audio pipeline (needs cava installed):"
echo "  systemctl --user enable --now conky-spectrum.service"
echo
echo "If PKG POWER shows N/A, read README.md -> Intel RAPL."
