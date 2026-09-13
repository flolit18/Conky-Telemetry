#!/usr/bin/env bash
max=0
for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
    [ -r "$f" ] || continue
    value=$(cat "$f" 2>/dev/null)
    [ -n "${value:-}" ] || continue
    if [ "$value" -gt "$max" ]; then
        max="$value"
    fi
done

if [ "$max" -eq 0 ]; then
    echo "N/A"
else
    awk -v f="$max" 'BEGIN { printf "%.2f", f / 1000000.0 }'
fi
