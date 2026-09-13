#!/bin/bash
#
# Currently playing track, for the line above the spectrum bars.
#
# Reads MPRIS over D-Bus through playerctl, the same source the GNOME
# media tile uses, so anything that shows up there works: browsers,
# Spotify, VLC, mpv.
#
# The output must stay on ONE line of bounded length: the spectrum Conky
# window is anchored to the bottom of the screen, so a line that wraps
# would push the whole block upward.

# Conky inherits whatever locale the session was started with, and it is
# not always a UTF-8 one. Without this, bash counts and slices BYTES, so
# truncating a title like "NGÀY TÀN" cuts a multi-byte character in half
# and prints a broken glyph.
export LC_ALL=C.UTF-8

# Players are tried in this order; %any catches everything else.
PLAYERS="brave,chromium,firefox,spotify,vlc,mpv,%any"

# Characters, not bytes. Roughly what fits in 500 px at size 9.
MAX_LENGTH=52

# Printed when nothing is playing. Never print an empty string: the line
# would collapse and the block would shift.
IDLE_TEXT="—"

if ! command -v playerctl >/dev/null 2>&1; then
    echo "playerctl not installed"
    exit 0
fi

raw=$(playerctl -p "$PLAYERS" metadata --format '{{artist}}|{{title}}' 2>/dev/null | head -n 1)

artist="${raw%%|*}"
title="${raw#*|}"

if [ -z "$title" ]; then
    echo "$IDLE_TEXT"
    exit 0
fi

if [ -n "$artist" ]; then
    line="$artist — $title"
else
    line="$title"
fi

# Strip anything that could break the single-line layout.
line="${line//$'\n'/ }"
line="${line//$'\t'/ }"

if [ "${#line}" -gt "$MAX_LENGTH" ]; then
    line="${line:0:$MAX_LENGTH}…"
fi

echo "$line"
exit 0
