#!/usr/bin/env bash
# Compiles the gettext catalogues from po/*.po and installs them for the
# current user, where KLocalizedString picks them up.
#
#   ./translate.sh             build and install all languages
#   ./translate.sh --extract   regenerate po/plasma_applet_gpumonitor.pot from the QML sources
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
domain="plasma_applet_org.stecker.gpumonitor"
potname="plasma_applet_gpumonitor"
locale_dir="${XDG_DATA_HOME:-$HOME/.local/share}/locale"

if [ "${1:-}" = "--extract" ]; then
    # Run from the repo root so the template holds relative paths, not /home/...
    ( cd "$here" && xgettext --language=C++ --from-code=UTF-8 --keyword=i18n:1 \
        --add-comments --package-name="GPU Monitor" \
        -o "po/$potname.pot" \
        package/contents/ui/*.qml package/contents/config/config.qml )
    echo "Template refreshed: po/$potname.pot"
fi

if ! command -v msgfmt >/dev/null; then
    echo "msgfmt not found - install gettext first." >&2
    exit 1
fi

shopt -s nullglob
for po in "$here"/po/*.po; do
    lang="$(basename "$po" .po)"
    install -d "$locale_dir/$lang/LC_MESSAGES"
    msgfmt -o "$locale_dir/$lang/LC_MESSAGES/$domain.mo" "$po"
    echo "Installed $lang -> $locale_dir/$lang/LC_MESSAGES/$domain.mo"
done

echo
echo "Reload Plasma to apply:"
echo "    systemctl --user restart plasma-plasmashell.service"
