#!/usr/bin/env bash
#
# Starts the audio pipeline feeding the Conky spectrum analyser:
#
#   CAVA  ->  /tmp/conky-cava.fifo  ->  spectrum_bridge.py
#         ->  /tmp/conky-spectrum.dat  ->  spectrum.lua (Conky)
#
# Run it in a terminal to see what is happening, or in the
# background:  ./start-spectrum.sh >/dev/null 2>&1 &
#
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FIFO="/tmp/conky-cava.fifo"
CAVA_CONF="$HERE/cava.conf"
BRIDGE="$HERE/spectrum_bridge.py"

if ! command -v cava >/dev/null 2>&1; then
    echo "cava is not installed. Install it with:"
    echo "  sudo apt install cava"
    exit 1
fi

if [ ! -f "$CAVA_CONF" ] || [ ! -f "$BRIDGE" ]; then
    echo "Missing $CAVA_CONF or $BRIDGE"
    exit 1
fi

# Stop a previous run so the FIFO is never claimed twice.
pkill -f "spectrum_bridge.py" >/dev/null 2>&1 || true
pkill -f "cava -p $CAVA_CONF" >/dev/null 2>&1 || true
sleep 0.3
rm -f "$FIFO"

# The bridge creates the FIFO, then blocks until CAVA connects.
python3 "$BRIDGE" &
BRIDGE_PID=$!

for _ in $(seq 1 50); do
    [ -p "$FIFO" ] && break
    sleep 0.1
done

if [ ! -p "$FIFO" ]; then
    echo "The bridge did not create $FIFO"
    kill "$BRIDGE_PID" 2>/dev/null || true
    exit 1
fi

cava -p "$CAVA_CONF" &
CAVA_PID=$!

cleanup() {
    kill "$CAVA_PID" "$BRIDGE_PID" 2>/dev/null || true
}

trap cleanup INT TERM EXIT

echo "Spectrum pipeline running (cava=$CAVA_PID bridge=$BRIDGE_PID)."
echo "Play some audio; Conky should show the bars."

# Return as soon as either half dies, so systemd (or you) restarts the
# whole pair instead of leaving a half-dead chain behind.
wait -n

echo "CAVA or the bridge exited; stopping the pipeline."
exit 1
