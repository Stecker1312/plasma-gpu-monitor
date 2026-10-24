#!/usr/bin/env bash
# Sanity checks for this applet. No build system, no network, no root.
# Run before committing: ./check.sh
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here" || exit 1

fail=0
ok()   { printf '  ok    %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "metadata"
if python3 -m json.tool package/metadata.json >/dev/null 2>&1; then
    ok "package/metadata.json is valid JSON"
else
    bad "package/metadata.json is not valid JSON"
fi

python3 - "$here" <<'PY' || fail=1
import json, sys
path = sys.argv[1] + '/package/metadata.json'
meta = json.load(open(path))
kplugin = meta.get('KPlugin', {})
problems = []
for key in ('Id', 'Name', 'Version', 'License'):
    if key not in kplugin:
        problems.append('KPlugin.%s missing' % key)
if meta.get('KPackageStructure') != 'Plasma/Applet':
    problems.append('KPackageStructure must be "Plasma/Applet"')
if meta.get('X-Plasma-MainScript') != 'ui/main.qml':
    problems.append('X-Plasma-MainScript must be "ui/main.qml"')
for p in problems:
    print('  FAIL  ' + p)
sys.exit(1 if problems else 0)
PY
[ $? -eq 0 ] && ok "required metadata keys present"

echo "translations"
if ! command -v msgfmt >/dev/null; then
    bad "msgfmt not found (install gettext)"
else
    pot="po/plasma_applet_gpumonitor.pot"
    if [ ! -f "$pot" ]; then
        bad "$pot missing"
    fi
    broken=""
    for po in po/*.po; do
        if ! msgfmt --check -o /dev/null "$po" 2>/dev/null; then
            broken="$broken $(basename "$po")"
        fi
    done
    if [ -n "$broken" ]; then
        bad "invalid catalogue(s):$broken"
    else
        ok "all catalogues compile ($(ls po/*.po | wc -l) files)"
    fi

    python3 - "$here" <<'PY' || fail=1
import glob, re, sys
root = sys.argv[1]
def msgids(path):
    txt = open(path, encoding='utf-8').read()
    return set(m for m in re.findall(r'^msgid "(.*)"$', txt, re.M) if m)
pot = msgids(root + '/po/plasma_applet_gpumonitor.pot')
problems = []
for po in sorted(glob.glob(root + '/po/*.po')):
    missing = pot - msgids(po)
    if missing:
        problems.append('%s untranslated: %s' % (po.split('/')[-1], ', '.join(sorted(missing))))
if problems:
    for p in problems:
        print('  FAIL  ' + p)
    sys.exit(1)
PY
    [ $? -eq 0 ] && ok "every catalogue covers every string"
fi

echo "template"
tmp=$(mktemp)
( xgettext --language=C++ --from-code=UTF-8 --keyword=i18n:1 \
    -o "$tmp" package/contents/ui/*.qml package/contents/config/config.qml 2>/dev/null )
python3 - "$here" "$tmp" <<'PY' || fail=1
import re, sys
def msgids(path):
    txt = open(path, encoding='utf-8').read()
    return set(m for m in re.findall(r'^msgid "(.*)"$', txt, re.M) if m)
pot = msgids(sys.argv[1] + '/po/plasma_applet_gpumonitor.pot')
current = msgids(sys.argv[2])
if pot != current:
    if current - pot:
        print('  FAIL  strings in QML but not in template (run ./translate.sh --extract):')
        for m in sorted(current - pot):
            print('        ' + m)
    if pot - current:
        print('  FAIL  strings in template but no longer in QML:')
        for m in sorted(pot - current):
            print('        ' + m)
    sys.exit(1)
PY
[ $? -eq 0 ] && ok "template matches the QML sources"
rm -f "$tmp"

if grep -q '"/var/home\|"/home/' po/*.pot 2>/dev/null; then
    bad "template contains absolute paths (run ./translate.sh --extract from the repo root)"
else
    ok "template references are relative"
fi

echo "consistency"
python3 - "$here" <<'PY' || fail=1
import glob, json, sys
root = sys.argv[1]
meta = json.load(open(root + '/package/metadata.json'))['KPlugin']
meta_langs = {k.split('[')[1].rstrip(']') for k in meta if '[' in k}
po_langs = {p.split('/')[-1][:-3] for p in glob.glob(root + '/po/*.po')}
problems = []
if meta_langs != po_langs:
    problems.append('metadata languages %s vs catalogues %s' %
                    (sorted(meta_langs - po_langs), sorted(po_langs - meta_langs)))
for p in problems:
    print('  FAIL  ' + p)
sys.exit(1 if problems else 0)
PY
[ $? -eq 0 ] && ok "metadata languages and catalogues match"

echo
if [ "$fail" -eq 0 ]; then
    echo "all checks passed"
else
    echo "checks failed"
fi
exit "$fail"
