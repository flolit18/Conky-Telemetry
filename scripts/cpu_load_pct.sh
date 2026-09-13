#!/bin/bash
#
# Total CPU load in percent (0-100), computed from /proc/stat deltas.
#
# Conky calls this once per update_interval, so it keeps the previous
# snapshot in /tmp and reports the busy ratio since that call. Same
# definition as ${cpu}: everything except idle and iowait.
#
# No subprocesses: only builtins, so it stays cheap at any interval.

STATE="/tmp/conky-cpu-load.state"

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat

total=$((user + nice + system + idle + iowait + irq + softirq + steal))
busy=$((total - idle - iowait))

prev_total=0
prev_busy=0

if [ -r "$STATE" ]; then
    read -r prev_total prev_busy < "$STATE"
fi

printf '%s %s\n' "$total" "$busy" > "$STATE"

delta_total=$((total - prev_total))
delta_busy=$((busy - prev_busy))

# First call after boot, or counters reset: nothing to compare against.
if [ "$delta_total" -le 0 ]; then
    echo 0
    exit 0
fi

pct=$((delta_busy * 100 / delta_total))

[ "$pct" -gt 100 ] && pct=100
[ "$pct" -lt 0 ] && pct=0

echo "$pct"
exit 0
