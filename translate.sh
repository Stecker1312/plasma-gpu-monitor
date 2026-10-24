#!/usr/bin/env bash
# Compiles the gettext catalogues from po/*.po and installs them for the
# current user, where KLocalizedString picks them up.
#
#   ./translate.sh             build and install all languages
#   ./translate.sh --extract   regenerate po/plasma_applet_gpumonitor.pot from the QML sources
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
domain="plasma_applet_org.stecker.gpumonitor"
locale_dir="${XDG_DATA_HOME:-$HOME/.local/share}/locale"

if [ "${1:-}" = "--extract" ]; then
    xgettext --language=C++ --from-code=UTF-8 --keyword=i18n:1 --add-comments \
        --package-name="GPU Monitor" \
        -o "$here/po/$domain.pot" \
        "$here"/package/contents/ui/*.qml "$here"/package/contents/config/config.qml
    echo "Template refreshed: po/$domain.pot"
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
