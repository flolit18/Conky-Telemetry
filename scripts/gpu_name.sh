#!/usr/bin/env bash
name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n1)
[ -n "${name:-}" ] && printf "%s\n" "$name" || printf "NVIDIA GPU\n"
