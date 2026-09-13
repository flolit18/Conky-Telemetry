# Conky Telemetry HUD

A compact Conky system-monitor HUD for a secondary Full-HD display. This is vibe-coded by me with ChatGPT to
make my second screen more useful when I leave it blank. 

I am on Ubuntu 24.04 LTS with an NVIDIA graphics card.
## Set up and Demo

You can find it in 
```
Demos/
```

Designed around:
- Jersey 15 pixel font
- CPU load / temperature / package power / clock graph
- NVIDIA GPU utilization / temperature / power / VRAM
- RAM usage
- NVMe usage / temperature / I/O
- Weather, location, time, and uptime
- Xinerama multi-monitor placement

## Screenshot target

The default layout is intended for a 1920×1080 secondary display and uses roughly one quarter of the screen width.

## Requirements

Ubuntu/Debian:

```bash
sudo apt install conky-all lm-sensors curl fontconfig
```

For NVIDIA telemetry, the NVIDIA driver must provide `nvidia-smi`.

For NVMe tools if you want to inspect drives manually:

```bash
sudo apt install nvme-cli
```

## Quick install

Clone the repository and run:

```bash
chmod +x install.sh
./install.sh
```

Then start Conky:

```bash
conky -c ~/.config/conky/conky.conf
```

To detach it from the terminal:

```bash
nohup conky -c ~/.config/conky/conky.conf >/dev/null 2>&1 &
```

## Jersey 15

`install.sh` downloads Jersey 15 from the Google Fonts repository and installs it for the current user under:

```text
~/.local/share/fonts/Jersey15/
```

## CPU package power / Intel RAPL

`cpu_power.sh` reads:

```text
/sys/class/powercap/intel-rapl:0/energy_uj
```

Some distributions make this root-only. If `PKG POWER` shows `N/A`, test:

```bash
cat /sys/class/powercap/intel-rapl:0/energy_uj
```

If you get `Permission denied`, you can install the optional service:

```bash
sudo ./system/install-rapl-permissions.sh
```

This makes the RAPL energy counters world-readable on boot. Review the script before using it if this is a multi-user machine.

## Monitor placement

The default Conky config contains:

```lua
xinerama_head = 1,
alignment = 'top_left',
gap_x = 20,
gap_y = 18,
```

Check your monitor indices with:

```bash
xrandr --listmonitors
```

Change `xinerama_head` if your secondary display uses a different index.

## NVMe temperature

The current machine uses:

```text
nvme-pci-0300
```

for the Linux system NVMe sensor.

If your mapping changes, run:

```bash
sensors
```

and either edit `scripts/ssd_temp.sh`, or launch Conky with:

```bash
CONKY_NVME_SENSOR=nvme-pci-XXXX conky -c ~/.config/conky/conky.conf
```

## Autostart

The installer places a desktop entry in:

```text
~/.config/autostart/conky-telemetry.desktop
```

It waits 5 seconds after login so the desktop and monitor layout can initialize before Conky starts.

## Repository layout

```text
.
├── conky.conf
├── Demos
│   └── Screenshot.png -- The preview
│   └── Setup -- My setup, direct to me is the Dell 2K monitor and the FullHD secondary monitor is aligned on the bottom line of the primary
├── install.sh
├── uninstall.sh
├── autostart/
│   └── conky-telemetry.desktop.in
├── scripts/
│   ├── cpu_clock.sh
│   ├── cpu_clock_pct.sh
│   ├── cpu_max_ghz.sh
│   ├── cpu_name.sh
│   ├── cpu_power.sh
│   ├── gpu_name.sh
│   ├── gpu_util.sh
│   ├── ssd_name.sh
│   └── ssd_temp.sh
└── system/
    └── install-rapl-permissions.sh
```

## Notes

The CPU clock shown is the highest current logical-CPU frequency. This is more intuitive on hybrid Intel CPUs than displaying one arbitrary core.

The CPU clock graph is normalized to the maximum frequency reported by `cpuinfo_max_freq`, so Conky always receives a 0–100 value.

## License

MIT
