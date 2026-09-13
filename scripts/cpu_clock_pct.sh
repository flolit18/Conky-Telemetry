#!/usr/bin/env bash
max_cur=0
max_cap=0

for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
    [ -r "$f" ] || continue
    v=$(cat "$f" 2>/dev/null)
    [ -n "${v:-}" ] || continue
    [ "$v" -gt "$max_cur" ] && max_cur="$v"
done

for f in /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq; do
    [ -r "$f" ] || continue
    v=$(cat "$f" 2>/dev/null)
    [ -n "${v:-}" ] || continue
    [ "$v" -gt "$max_cap" ] && max_cap="$v"
done

if [ "$max_cap" -le 0 ]; then
    max_cap=5500000
fi

pct=$((max_cur * 100 / max_cap))
[ "$pct" -gt 100 ] && pct=100
[ "$pct" -lt 0 ] && pct=0
echo "$pct"
