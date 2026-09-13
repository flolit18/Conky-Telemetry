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
- CPU load graph / temperature / package power / current clock
- NVIDIA GPU utilization / temperature / power / VRAM
- RAM usage
- NVMe usage / temperature / I/O
- Weather, location, time, and uptime
- Audio spectrum analyser (CAVA + Lua/Cairo) with the current track
- Xinerama multi-monitor placement

## Screenshot target

The default layout is intended for a 1920×1080 secondary display and uses roughly one quarter of the screen width.

## Requirements

Ubuntu/Debian:

```bash
sudo apt install conky-all lm-sensors curl fontconfig cava playerctl
```

`conky-all` is required, not `conky-std`: the spectrum analyser is drawn from Lua
with the Cairo bindings, which only the `-all` build ships.

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

Then start both Conky windows:

```bash
~/.config/conky/scripts/start-conky.sh
```

The HUD and the spectrum are two separate Conky instances, so `start-conky.sh`
launches both and detaches them. The autostart entry calls the same script.

## Audio spectrum analyser

The bars under `AUDIO SPECTRUM` are not a Conky widget, they are drawn by
`spectrum/spectrum.lua` through `lua_draw_hook_post`. The chain is:

```text
CAVA  ->  /tmp/conky-cava.fifo  ->  spectrum_bridge.py
      ->  /tmp/conky-spectrum.dat  ->  spectrum.lua  ->  Conky window
```

The spectrum has its own Conky instance, `conky-spectrum.conf`, running at
60 fps and anchored to the bottom of the screen, while `conky.conf` holds the
telemetry at 1 s. They are separate because `update_interval` is global: at
60 fps the 480 px CPU graph would only hold 8 seconds of history, and Conky
averages `LOAD`, `READ` and `WRITE` over that same interval.

Conky only draws what it finds in `/tmp/conky-spectrum.dat`, so CAVA and the
bridge must be running as well. `install.sh` ships a user service for that:

```bash
systemctl --user enable --now conky-spectrum.service
```

It restarts the pair if either half dies, and `start-spectrum.sh` exits as soon
as one of them does so the chain is never left half alive. Logs:

```bash
systemctl --user status conky-spectrum.service
journalctl --user -u conky-spectrum.service -f
```

To run it by hand instead, without the service:

```bash
~/.config/conky/spectrum/start-spectrum.sh
```

Checks when the bars stay flat:

```bash
# is the data file being refreshed?
watch -n0.2 cat /tmp/conky-spectrum.dat

# render test with a static frame: a rising staircase should appear
for i in $(seq 1 32); do printf '%d ' $((i * 3)); done > /tmp/conky-spectrum.dat

# is Conky loading the Lua script? (run that instance in a terminal)
conky -c ~/.config/conky/conky-spectrum.conf
```

CAVA reads the default PulseAudio/PipeWire monitor source, so the bars only move
while something is actually playing.

### Now playing

The line between the `AUDIO SPECTRUM` rule and the bars comes from
`spectrum/now_playing.sh`, which asks `playerctl` for the current MPRIS track —
the same source the GNOME media tile reads, so browsers, Spotify, VLC and mpv
all work. Player preference order is at the top of the script.

Three constraints shape it, all from the bottom-anchored layout:

- It must print exactly one line. A wrapped title would push the whole block up,
  so the script truncates to `MAX_LENGTH` characters.
- It must never print nothing. An empty line collapses and shifts the block, so
  an em dash is printed when no player is running.
- It forces `LC_ALL=C.UTF-8`. Conky inherits the session locale, and under a
  non-UTF-8 one bash slices bytes instead of characters, cutting multi-byte
  titles in half.

`${scroll}` is deliberately not used for long titles: it advances one step per
Conky update, which at 60 fps is unreadable.

The line is set in DejaVu Sans rather than Jersey 15, which is a pixel font with
no accented or non-Latin glyphs. Change it in `conky-spectrum.conf` if you only
ever play ASCII-titled tracks.

### Vertical alignment

The two windows do not know about each other: the HUD is anchored `top_left` and
the spectrum `bottom_left`, and they meet in the middle. If the spectrum block
overlaps the NVME section, or leaves a visible gap under it, adjust `gap_y` in
`conky-spectrum.conf` — that is the only knob.

The Lua hook anchors the bars on `window_height - BOTTOM_OFFSET`, which measures
whatever is printed under the graph band in `conky-spectrum.conf` — currently
the `30 HZ / 20 KHZ` line and the rule below it. Adding or removing a line there
means changing that constant by the same number of pixels.

### Size of the analyser

Two values must move together, otherwise the bars overflow the band or float
above the baseline:

| What | Where |
|------|-------|
| `GRAPH_HEIGHT` | `spectrum/spectrum.lua`, height of a full-scale bar |
| `${voffset N}` | `conky-spectrum.conf`, the empty band reserved for it |

Raise both by the same amount. The window is anchored at the bottom of the
screen, so it grows upward — check that it does not collide with the HUD above.

Bar width follows from the window: `(width - 31 * BAR_GAP) / 32`. To widen the
whole analyser, change `minimum_width` and `maximum_width` in
`conky-spectrum.conf` — the bars and the rules follow automatically.

### Refresh rate

Each instance has its own `update_interval`: 1 s for the telemetry, `0.0167`
(60 fps) for the spectrum. CAVA's `framerate` must match the spectrum instance,
otherwise Conky draws the same frame twice.

`ATTACK` and `RELEASE` in `spectrum.lua` are per-frame factors, so they must be
retuned if that rate changes. Equivalent rise and decay times:

| fps | ATTACK | RELEASE |
|-----|--------|---------|
| 60  | 0.23   | 0.064   |
| 20  | 0.55   | 0.18    |
| 10  | 0.80   | 0.33    |

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
├── conky-spectrum.conf
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
│   ├── ssd_temp.sh
│   └── start-conky.sh
├── spectrum/
│   ├── cava.conf
│   ├── spectrum_bridge.py
│   ├── spectrum.lua
│   └── start-spectrum.sh
└── system/
    ├── conky-spectrum.service
    └── install-rapl-permissions.sh
```

## Notes

The CPU clock shown is the highest current logical-CPU frequency. This is more intuitive on hybrid Intel CPUs than displaying one arbitrary core.

The graph under it plots total CPU load from `scripts/cpu_load_pct.sh`, which diffs `/proc/stat` between calls and returns 0–100 — the same busy ratio as `${cpu}`, everything except idle and iowait. At `update_interval = 1` each pixel is one second, so the 480 px graph holds 8 minutes.

Conky's built-in `${cpugraph}` would be the obvious choice here, but on this machine (conky 1.19, Ubuntu 24.04) it draws an empty frame: the border renders, the data never arrives. `${execigraph}` with the script above works, so that is what the config uses.

`scripts/cpu_clock_average_pct.sh` is no longer used by `conky.conf`. It is kept for anyone who prefers an average-clock graph: swap the `${cpugraph}` line for

```text
${execigraph 1 ~/.config/conky/scripts/cpu_clock_average_pct.sh 52,480 FFFFFF FFFFFF 100}
```

Be aware that on recent Intel parts `scaling_cur_freq` reports the requested P-state rather than the measured frequency, which pins that graph near 100 % even at idle.

## License

MIT
