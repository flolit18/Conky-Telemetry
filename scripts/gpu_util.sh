#!/usr/bin/env bash
value=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -dc '0-9')
[ -n "${value:-}" ] || value=0
[ "$value" -gt 100 ] && value=100
[ "$value" -lt 0 ] && value=0
echo "$value"
