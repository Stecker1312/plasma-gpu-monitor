#!/usr/bin/env bash
# Installs the applet as a symlink into the Plasma plasmoid directory.
# Usage: ./install.sh
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/org.stecker.gpumonitor"

mkdir -p "$(dirname "$target")"

if [ -L "$target" ]; then
    rm "$target"
elif [ -d "$target" ]; then
    backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$target" "$backup"
    echo "Existing installation backed up to: $backup"
fi

ln -s "$here/package" "$target"
echo "Installed: $target -> $here/package"

if [ -x "$here/translate.sh" ]; then
    "$here/translate.sh"
fi
echo
echo "Reload Plasma so the applet appears:"
echo "    systemctl --user restart plasma-plasmashell.service"
echo "Then right-click the panel -> Add Widgets -> 'GPU Monitor'."
