#!/usr/bin/env bash
set -u

RAPL="/sys/class/powercap/intel-rapl:0"
ENERGY="$RAPL/energy_uj"
MAXFILE="$RAPL/max_energy_range_uj"

if [ ! -r "$ENERGY" ]; then
    echo "N/A"
    exit 0
fi

E1=$(cat "$ENERGY" 2>/dev/null) || { echo "N/A"; exit 0; }
T1=$(date +%s%N)

sleep 0.25

E2=$(cat "$ENERGY" 2>/dev/null) || { echo "N/A"; exit 0; }
T2=$(date +%s%N)

MAX=$(cat "$MAXFILE" 2>/dev/null || true)

if [ -n "${MAX:-}" ] && [ "$E2" -lt "$E1" ]; then
    E2=$((E2 + MAX))
fi
# calculate CPU package power by P = dA/dt
awk -v e1="$E1" -v e2="$E2" -v t1="$T1" -v t2="$T2" '
BEGIN {
    dt = (t2 - t1) / 1000000000.0
    de = (e2 - e1) / 1000000.0
    if (dt > 0) printf "%.1f W\n", de / dt
    else print "N/A"
}'
