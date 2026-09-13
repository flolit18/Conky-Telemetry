#!/bin/bash

sum=0
count=0
max_cap=0

for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
    [ -r "$f" ] || continue

    value=$(cat "$f" 2>/dev/null)
    [ -n "$value" ] || continue

    sum=$((sum + value))
    count=$((count + 1))
done

for f in /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq; do
    [ -r "$f" ] || continue

    value=$(cat "$f" 2>/dev/null)
    [ -n "$value" ] || continue

    [ "$value" -gt "$max_cap" ] && max_cap="$value"
done

if [ "$count" -eq 0 ] || [ "$max_cap" -eq 0 ]; then
    echo 0
    exit
fi

avg=$((sum / count))
pct=$((avg * 100 / max_cap))

[ "$pct" -gt 100 ] && pct=100
[ "$pct" -lt 0 ] && pct=0

echo "$pct"