# AGENTS.md – notes for AI agents

**This document is written for agents, not for people.** It records what this
project is, why it exists and what to watch out for when changing it.

## Starting position (important!)

The owner (Daniel, GitHub `Stecker1312`) built this applet once and **will not
maintain it by hand**. There is no regular human maintenance. If you change
something here, you are responsible for correctness and for not disturbing a
running system.

The applet runs in production on the machine you are working on, attached to the
panel of the primary display.

## What this is about

A Plasma 6 panel applet that shows two values from the AMD graphics card: GPU
utilisation in percent and junction (hotspot) temperature in degrees Celsius.
The temperature figure changes colour when configured thresholds are exceeded.

Background: during extended local AI workloads (LLMs, diffusion models) the GPU
in this case gets too warm, because exhaust air cannot be replaced. The applet is
the early warning instrument for that. **The temperature warning is the point of
the project, not the utilisation figure.**

## Hard constraints

- **Do not introduce dependencies.** No build step, no C++ plugin, no Python
  helper scripts, no external services. The applet is pure QML and reads sensors
  through a module shipped with Plasma itself.
- **Do not change the applet ID `org.stecker.gpumonitor`.** It appears in the
  user's panel configuration
  (`~/.config/plasma-org.kde.plasma.desktop-appletsrc`). Renaming it removes the
  running widget from the panel. The ID is deliberately decoupled from the GitHub
  handle so that name changes there do not trigger a migration. (History: the
  applet was called `org.daniel.gpumonitor` until October 2026; moving it
  requires: `metadata.json`, `install.sh`, the symlink, removing the old widget
  from the panel, restarting Plasma, adding the new widget.)
- **No secrets, no telemetry, no network access.** The applet reads local sensors
  only.
- Source strings in the UI are English and wrapped in `i18n()`; documentation is
  British English.

## Environment it was developed and tested on

| Item | Value |
| --- | --- |
| Distribution | Bazzite (Fedora Atomic), Wayland |
| Plasma | 6.7.5 |
| GPU | AMD Radeon RX 7900 XTX (Navi 31), `amdgpu` driver |
| Sensor source | `ksystemstats` (DBus `org.kde.ksystemstats1`), reading `amdgpu` sysfs |

Other AMD cards using `amdgpu` should work as long as `ksystemstats` exposes them
as `gpu/gpu0`. NVIDIA is **not** tested.

## Repository layout

```
package/                        The applet itself (KPackage "Plasma/Applet")
  metadata.json                 KPlugin metadata, applet ID, version
  contents/ui/main.qml          All logic and both representations
  contents/ui/configGeneral.qml Settings page
  contents/config/main.xml      KConfigXT: thresholds and display options
  contents/config/config.qml    List of settings pages
install.sh                      Symlink install into ~/.local/share/plasma/plasmoids
docs/screenshot.png             Crop of the panel showing the widget
```

Installation is a symlink:

```
~/.local/share/plasma/plasmoids/org.stecker.gpumonitor -> <repo>/package
```

Therefore: **changes in the repository are immediately the running version.**
There is no second copy to keep in sync.

## How it works

`main.qml` creates seven `Sensors.Sensor` objects (module
`org.kde.ksysguard.sensors`) and derives everything from them:

| Sensor ID | Meaning | Rate |
| --- | --- | --- |
| `gpu/gpu0/usage` | utilisation in % | 2 s |
| `gpu/gpu0/temp2` | junction / hotspot in °C | 2 s |
| `gpu/gpu0/temperature` | edge in °C | 5 s |
| `gpu/gpu0/temp3` | memory in °C | 5 s |
| `gpu/gpu0/power` | power draw in W | 5 s |
| `gpu/gpu0/usedVram`, `totalVram` | VRAM in bytes | 5 s |

Representations:

- `compactRepresentation` – text in the panel, width pinned through an invisible
  placeholder (`widthProbe`) so the panel does not shift.
- `fullRepresentation` – popup on click, showing every value.
- `toolTipSubText` – the same values as a tooltip.
- Colour: below `warnTemperature` normal, from the warning threshold onwards
  amber (`neutralTextColor`), from `criticalTemperature` onwards red
  (`negativeTextColor`).

## Pitfalls (each of these has caused a real bug already)

1. `Sensors.Sensor.updateInterval` is **read-only**. The update rate is set
   through `updateRateLimit`. Assigning `updateInterval` produces
   `error when loading applet`.
2. `Sensors.Sensor.value` is a QVariant and starts out `undefined`. Assigning it
   directly to a `real` property yields `Unable to assign [undefined] to double`.
   That is why `valueOf()` normalises to 0.
3. After editing `main.qml`, Plasma keeps the compiled QML in memory.
   Re-adding the applet inside the same plasmashell process loads **the old
   code**. Always `systemctl --user restart plasma-plasmashell.service` when
   testing.
4. Panel scripting over DBus: the method is `addWidget()`, not `addApplet()`.
   Removal is `panels()[0].widgetById(<id>).remove()`; `widgetById(id).type`
   gives the plugin ID. `applet.expanded` cannot be set from outside, so the
   popup has to be checked manually.
5. In `configGeneral.qml` values are bound via `property alias cfg_<name>`. The
   names must match the entries in `contents/config/main.xml` exactly.
6. When writing QML files with tools that redact phone numbers, long numeric
   literals (for example `1024 * 1024 * 1024`) can be damaged. Re-read the file
   after writing.
7. The translation domain is derived, not free: Plasma looks for
   `plasma_applet_<applet id>`. A catalogue named `plasma_applet_gpumonitor` or
   after the plain plugin id is **silently ignored**. Also, adding
   `X-KDE-TranslationDomain` to `metadata.json` does *not* fix this for applets —
   it is not the switch that sets the QML i18n domain.

## Localisation

- Every user-visible string goes through `i18n()`; the source language is English.
- Catalogues live in `po/` and are compiled by `translate.sh` into
  `${XDG_DATA_HOME:-$HOME/.local/share}/locale/<lang>/LC_MESSAGES/`.
- The file must be named `plasma_applet_org.stecker.gpumonitor.mo` (see pitfall 7).
- Applet name and description are translated through localised keys in
  `package/metadata.json` (`"Name[de]"`, `"Description[de]"`). These do show up in
  the widget list and in `kpackagetool6 --show`.
- `.mo` files are generated artefacts and are ignored by git.
- New or changed strings: wrap in `i18n()`, run `./translate.sh --extract`, then
  fill in `po/*.po` and run `./translate.sh`.
- Testing translations without changing the system language:

  ```bash
  systemctl --user set-environment LANGUAGE=de
  systemctl --user restart plasma-plasmashell.service
  # check, then revert:
  systemctl --user unset-environment LANGUAGE
  systemctl --user restart plasma-plasmashell.service
  ```

  Tip: temporarily bind a translated string into the compact representation to
  make it visible without hovering or opening a dialog.

## Testing changes (mandatory before every commit)

```bash
# 1. Reload Plasma (this actually reloads the changed QML)
systemctl --user restart plasma-plasmashell.service

# 2. Check for load errors – output must be empty
journalctl --user --since "-1min" --no-pager \
  | grep -iE 'gpumonitor|qml.*error|Unable to assign|read-only'

# 3. Check visually: screenshot of the panel
spectacle -b -n -f -o /tmp/panel.png
python3 -c "
from PIL import Image
Image.open('/tmp/panel.png').crop((1400, 1140, 1920, 1200)).save('/tmp/panel_crop.png')
"
```

The widget must show a value in the format `12 % 64 °C`. If it shows `-- °C`,
`ksystemstats` is not delivering values — check this first:

```bash
busctl --user call org.kde.ksystemstats1 /org/kde/ksystemstats1 \
  org.kde.ksystemstats1 allSensors --json=short | grep -o '"gpu/[^"]*"'
```

The colour logic can be exercised by temporarily setting `warnTemperature` below
the current temperature (file
`~/.config/plasma-org.kde.plasma.desktop-appletsrc`, group
`[Containments][<n>][Applets][<id>][Configuration][General]`, then restart
Plasma), and removing it again afterwards.

## What you should not do

- Do not rewrite this in C++ or on top of the KDE frameworks "because it is
  cleaner". QML is sufficient, and a build step would break the symlink
  installation.
- Do not add history graphs, tray icons, notifications or configuration dialogs
  without a concrete reason. The applet is meant to stay small.
- Do not change `install.sh` from symlinking to copying without considering the
  consequence: repository and installation would drift apart.
- Do not touch the user's panel configuration beyond adding or removing this one
  applet.

## Versioning

- The version lives in `package/metadata.json` (`KPlugin.Version`, currently
  `1.0`).
- Increase it for functional changes; the applet ID stays the same.
- Commit convention: `impl:`, `docs:`, `fix:` plus a short imperative message.

## Known limitations

- Single GPU only (`gpu/gpu0`). Multi-GPU is not covered.
- No history, no graph — current values only.
- NVIDIA untested.
- The sensor IDs come from `ksystemstats`; if KDE changes them, the list in
  `main.qml` has to be adapted.
