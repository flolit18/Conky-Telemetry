#!/usr/bin/env bash
# Find the block device that backs /
src=$(findmnt -n -o SOURCE / 2>/dev/null)
base=$(basename "$src")

# Strip partition suffix for NVMe devices: nvme2n1p2 -> nvme2n1
dev=$(printf "%s" "$base" | sed -E 's/p[0-9]+$//')

model=$(lsblk -dn -o MODEL "/dev/$dev" 2>/dev/null | sed 's/[[:space:]]*$//')
size=$(lsblk -dn -o SIZE "/dev/$dev" 2>/dev/null | sed 's/[[:space:]]*$//')

if [ -n "${model:-}" ]; then
    printf "%s / %s\n" "$model" "$size"
else
    printf "%s\n" "$dev"
fi
