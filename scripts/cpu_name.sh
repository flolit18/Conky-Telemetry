#!/usr/bin/env bash
name=$(lscpu 2>/dev/null | awk -F: '/Model name:/ {sub(/^[ \t]+/, "", $2); print $2; exit}')
[ -n "${name:-}" ] && printf "%s\n" "$name" || printf "CPU\n"
