#!/usr/bin/env bash
set -e

rm -f "$HOME/.config/autostart/conky-telemetry.desktop"
rm -rf "$HOME/.config/conky"

echo "Removed Conky Telemetry configuration and autostart entry."
echo "Jersey 15 was left installed in ~/.local/share/fonts/Jersey15."
