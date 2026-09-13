#!/usr/bin/env bash
# Default for the current machine: nvme-pci-0300 corresponds to the Linux system NVMe.
# If your controller mapping changes, run `sensors` and update SENSOR below.
SENSOR="${CONKY_NVME_SENSOR:-nvme-pci-0300}"

temp=$(sensors "$SENSOR" 2>/dev/null | awk '/Composite:/ {print $2; exit}')
[ -n "${temp:-}" ] && printf "%s\n" "$temp" || printf "N/A\n"
