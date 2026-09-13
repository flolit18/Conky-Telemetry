#!/usr/bin/env bash
#
# Starts both Conky windows: the telemetry HUD at 1 s and the
# audio spectrum at 60 fps. They are separate instances so the
# spectrum's refresh rate does not drag the telemetry with it.

set -u

CONKY_DIR="$HOME/.config/conky"

killall conky >/dev/null 2>&1 || true
sleep 1

conky -c "$CONKY_DIR/conky.conf" >/dev/null 2>&1 &
conky -c "$CONKY_DIR/conky-spectrum.conf" >/dev/null 2>&1 &

exit 0
