# GPU Monitor – Plasma-Applet

Kleines KDE-Plasma-6-Applet für die Taskleiste: zeigt Auslastung und
Junction-Temperatur (Hotspot) der Grafikkarte und färbt den Temperaturwert
je nach Schwelle ein.

Entstanden, um bei lokaler KI-Last (LLMs, Diffusionsmodelle) früh zu sehen,
wann die GPU zu warm wird.

![Screenshot](docs/screenshot.png)

## Anzeige

Leiste: `12 % 64 °C` – Auslastung und Junction-Temperatur.

| Bereich | Farbe |
| --- | --- |
| unter Warnschwelle (Standard 85 °C) | normale Textfarbe |
| ab Warnschwelle | orange |
| ab kritischer Schwelle (Standard 100 °C) | rot |

Klick auf das Widget öffnet ein Popup mit Auslastung, Junction-, Edge- und
Speicher-Temperatur, Leistungsaufnahme und VRAM-Belegung. Tooltip zeigt
dieselben Werte ohne Klick.

## Installation

```bash
./install.sh
systemctl --user restart plasma-plasmashell.service
```

Danach Rechtsklick auf die Leiste → *Widgets hinzufügen* → **GPU Monitor**.

`install.sh` legt nur einen Symlink an:

```
~/.local/share/plasma/plasmoids/org.daniel.gpumonitor -> <repo>/package
```

Damit sind Änderungen im Repo sofort die installierte Version.

Deinstallieren:

```bash
rm ~/.local/share/plasma/plasmoids/org.daniel.gpumonitor
```

## Konfiguration

Rechtsklick auf das Widget → *GPU Monitor konfigurieren*:

- Warnschwelle (Standard 85 °C, Junction)
- kritische Schwelle (Standard 100 °C, Junction)
- Auslastung in der Leiste ein-/ausblenden

## Warum Junction statt Edge?

Die Junction-Temperatur ist der Hotspot im Die und reagiert zuerst, wenn die
Gehäusebelüftung nicht hinterherkommt. Edge liegt typischerweise 10–15 K
darunter und würde zu spät warnen. Bei AMD Navi 31 (RX 7900 XT/XTX) liegt das
Spezifikationsmaximum für Junction bei 110 °C – die rote Stufe bei 100 °C lässt
also noch Reserve.

## Technik

Kein Hilfsskript, keine Abhängigkeiten außer Plasma selbst: das Applet liest
die Sensoren über das QML-Modul `org.kde.ksysguard.sensors`, also über
`ksystemstats` und damit über `amdgpu`-Sysfs.

Verwendete Sensor-IDs:

| Sensor | Bedeutung |
| --- | --- |
| `gpu/gpu0/usage` | Auslastung in % |
| `gpu/gpu0/temp2` | Junction (Hotspot) in °C |
| `gpu/gpu0/temperature` | Edge in °C |
| `gpu/gpu0/temp3` | Speicher in °C |
| `gpu/gpu0/power` | Leistungsaufnahme in W |
| `gpu/gpu0/usedVram` / `totalVram` | VRAM in Bytes |

Aktualisierung: Auslastung und Junction alle 2 s, die übrigen Werte alle 5 s.

Zwei Stolperfallen, falls das Applet angepasst wird:

- `Sensors.Sensor.updateInterval` ist read-only, die Rate wird über
  `updateRateLimit` gesetzt.
- `Sensors.Sensor.value` ist ein QVariant und anfangs `undefined`; die
  Bindings normalisieren das auf 0.

## Getestet mit

- Bazzite (Fedora Atomic), Plasma 6.7.5, Wayland
- AMD Radeon RX 7900 XTX (Navi 31), `amdgpu`

Andere AMD-Karten mit `amdgpu` sollten funktionieren, sofern `ksystemstats`
sie als `gpu/gpu0` führt. NVIDIA ist nicht getestet.

## Lizenz

MIT – siehe [LICENSE](LICENSE).
