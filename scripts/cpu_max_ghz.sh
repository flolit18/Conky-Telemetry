#!/usr/bin/env bash
max=0
for f in /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq; do
    [ -r "$f" ] || continue
    v=$(cat "$f" 2>/dev/null)
    [ -n "${v:-}" ] || continue
    [ "$v" -gt "$max" ] && max="$v"
done

if [ "$max" -gt 0 ]; then
    awk -v f="$max" 'BEGIN { printf "%.1f", f / 1000000.0 }'
else
    echo "5.5"
fi
