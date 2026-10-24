#!/usr/bin/env bash
# Installiert das Applet als Symlink in den Plasma-Plasmoid-Ordner.
# Aufruf: ./install.sh
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/org.daniel.gpumonitor"

mkdir -p "$(dirname "$target")"

if [ -L "$target" ]; then
    rm "$target"
elif [ -d "$target" ]; then
    backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$target" "$backup"
    echo "Vorhandene Installation gesichert: $backup"
fi

ln -s "$here/package" "$target"
echo "Installiert: $target -> $here/package"
echo
echo "Plasma neu laden, damit das Applet erscheint:"
echo "    systemctl --user restart plasma-plasmashell.service"
echo "Danach per Rechtsklick auf die Leiste -> Widgets hinzufuegen -> 'GPU Monitor'."
