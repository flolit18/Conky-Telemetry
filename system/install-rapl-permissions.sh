#!/usr/bin/env bash
set -e

SERVICE="/etc/systemd/system/conky-rapl-permissions.service"

cat > "$SERVICE" <<'EOF'
[Unit]
Description=Allow Conky to read Intel RAPL energy counters
After=multi-user.target
ConditionPathExists=/sys/class/powercap/intel-rapl:0/energy_uj

[Service]
Type=oneshot
ExecStart=/bin/chmod 0444 /sys/class/powercap/intel-rapl:0/energy_uj
ExecStart=/bin/chmod 0444 /sys/class/powercap/intel-rapl:0/max_energy_range_uj
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now conky-rapl-permissions.service

echo "Intel RAPL counters are now readable by local users."
echo "Check with:"
echo "  cat /sys/class/powercap/intel-rapl:0/energy_uj"
