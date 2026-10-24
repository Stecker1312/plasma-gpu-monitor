# AGENTS.md – Hinweise für KI-Agenten

**Dieses Dokument ist für Agenten geschrieben, nicht für Menschen.** Es hält
fest, was dieses Projekt ist, warum es existiert und worauf man beim Ändern
achten muss.

## Ausgangslage (wichtig!)

Der Eigentümer (Daniel, GitHub `Stecker1312`) hat dieses Applet einmal
erstellt und **wird es nicht selbst pflegen**. Es gibt keine regelmäßige
menschliche Wartung. Wenn du hier etwas änderst, bist du für Korrektheit und
Rücksicht auf ein laufendes System verantwortlich.

Das Applet läuft produktiv auf dem Rechner, auf dem du arbeitest, und hängt in
der Taskleiste des Primärmonitors.

## Worum es geht

Ein Plasma-6-Applet für die Taskleiste, das zwei Werte der AMD-Grafikkarte
zeigt: Auslastung in Prozent und Junction-Temperatur (Hotspot) in Grad Celsius.
Der Temperaturwert wechselt die Farbe, wenn konfigurierte Schwellen überschritten
werden.

Hintergrund: Bei längerer lokaler KI-Last (LLMs, Diffusionsmodelle) wird die GPU
in diesem Gehäuse zu warm, weil die Abluft nicht nachströmen kann. Das Applet ist
das Frühwarninstrument dafür. **Der fachliche Kern ist die Temperaturwarnung,
nicht die Auslastungsanzeige.**

## Harte Rahmenbedingungen

- **Keine Abhängigkeiten einführen.** Kein Build-Schritt, kein C++-Plugin, keine
  Python-Hilfsskripte, keine externen Dienste. Das Applet ist reines QML und liest
  Sensoren über ein Modul, das Plasma selbst mitbringt.
- **Applet-ID `org.stecker.gpumonitor` nicht ändern.** Sie steht in der
  Panel-Konfiguration des Nutzers (`~/.config/plasma-org.kde.plasma.desktop-appletsrc`).
  Eine Umbenennung entfernt das laufende Widget aus der Leiste.
  Die ID ist bewusst vom GitHub-Handle entkoppelt, damit Namenswechsel dort keine
  Migration auslösen. (Historie: das Applet hieß bis Oktober 2026
  `org.daniel.gpumonitor`; ein Umzug erfordert: `metadata.json`, `install.sh`,
  Symlink, altes Widget aus dem Panel entfernen, Plasma neu starten, neues Widget
  hinzufügen.)
- **Keine Secrets, keine Telemetrie, kein Netzwerkzugriff.** Das Applet liest
  ausschließlich lokale Sensoren.
- Sprache in Dokumentation und Oberfläche: Deutsch (Oberfläche nutzt `i18n()`).

## Umgebung, auf der es entwickelt und getestet wurde

| Punkt | Wert |
| --- | --- |
| Distribution | Bazzite (Fedora Atomic), Wayland |
| Plasma | 6.7.5 |
| GPU | AMD Radeon RX 7900 XTX (Navi 31), Treiber `amdgpu` |
| Sensorquelle | `ksystemstats` (DBus `org.kde.ksystemstats1`), darunter `amdgpu`-Sysfs |

Andere AMD-Karten mit `amdgpu` sollten funktionieren, solange `ksystemstats` sie
als `gpu/gpu0` führt. NVIDIA ist **nicht** getestet.

## Aufbau des Repos

```
package/                     Das Applet selbst (KPackage "Plasma/Applet")
  metadata.json              KPlugin-Metadaten, Applet-ID, Version
  contents/ui/main.qml       Gesamte Logik und beide Darstellungen
  contents/ui/configGeneral.qml   Einstellungsseite
  contents/config/main.xml   KConfigXT: Schwellen und Anzeigeoptionen
  contents/config/config.qml Liste der Einstellungsseiten
install.sh                   Symlink-Installation nach ~/.local/share/plasma/plasmoids
docs/screenshot.png          Ausschnitt der Leiste mit dem Widget
```

Installiert wird per Symlink:

```
~/.local/share/plasma/plasmoids/org.stecker.gpumonitor -> <repo>/package
```

Das heißt: **Änderungen im Repo sind sofort die laufende Version.** Es gibt keine
zweite Kopie, die synchron gehalten werden müsste.

## Wie es funktioniert

`main.qml` legt sieben `Sensors.Sensor`-Objekte an (Modul
`org.kde.ksysguard.sensors`) und leitet daraus ab:

| Sensor-ID | Bedeutung | Rate |
| --- | --- | --- |
| `gpu/gpu0/usage` | Auslastung % | 2 s |
| `gpu/gpu0/temp2` | Junction / Hotspot °C | 2 s |
| `gpu/gpu0/temperature` | Edge °C | 5 s |
| `gpu/gpu0/temp3` | Speicher °C | 5 s |
| `gpu/gpu0/power` | Leistungsaufnahme W | 5 s |
| `gpu/gpu0/usedVram`, `totalVram` | VRAM in Bytes | 5 s |

Darstellung:

- `compactRepresentation` – Text in der Leiste, Breite über einen unsichtbaren
  Platzhalter (`widthProbe`) fixiert, damit die Leiste nicht springt.
- `fullRepresentation` – Popup beim Klick mit allen Werten.
- `toolTipSubText` – dieselben Werte als Tooltip.
- Farbe: unter `warnTemperature` normal, ab Warnschwelle orange
  (`neutralTextColor`), ab `criticalTemperature` rot (`negativeTextColor`).

## Fallstricke (alle schon einmal in echte Fehler gelaufen)

1. `Sensors.Sensor.updateInterval` ist **read-only**. Die Aktualisierungsrate wird
   über `updateRateLimit` gesetzt. Ein Setzen von `updateInterval` führt zu
   `error when loading applet`.
2. `Sensors.Sensor.value` ist ein QVariant und anfangs `undefined`. Direkte
   Zuweisung an eine `real`-Property erzeugt
   `Unable to assign [undefined] to double`. Deshalb normalisiert `valueOf()` auf 0.
3. Nach Änderungen an `main.qml` hält Plasma die kompilierte QML im Speicher.
   Ein erneutes Hinzufügen des Applets im selben plasmashell-Prozess lädt **den
   alten Code**. Zum Testen deshalb `systemctl --user restart
   plasma-plasmashell.service`.
4. Panel-Scripting über DBus: Die Methode heißt `addWidget()`, nicht
   `addApplet()`. Entfernen geht über `panels()[0].widgetById(<id>).remove()`.
   `applet.expanded` ist von außen nicht setzbar, das Popup lässt sich also nicht
   per Skript öffnen und muss manuell geprüft werden.
5. In `configGeneral.qml` werden die Werte über `property alias cfg_<name>`
   angebunden. Die Namen müssen exakt zu den Einträgen in
   `contents/config/main.xml` passen.
6. Beim Schreiben von QML-Dateien mit Werkzeugen, die Telefonnummern maskieren,
   können lange Zahlenliterale (z. B. `1024 * 1024 * 1024`) beschädigt werden.
   Nach dem Schreiben die Datei gegenlesen.

## Änderungen testen (Pflicht vor jedem Commit)

```bash
# 1. Plasma neu laden (lädt die geänderte QML wirklich neu)
systemctl --user restart plasma-plasmashell.service

# 2. Auf Ladefehler prüfen – Ausgabe muss leer sein
journalctl --user --since "-1min" --no-pager \
  | grep -iE 'gpumonitor|qml.*error|Unable to assign|read-only'

# 3. Optisch prüfen: Screenshot der Leiste
spectacle -b -n -f -o /tmp/opencode/panel.png
python3 -c "
from PIL import Image
Image.open('/tmp/opencode/panel.png').crop((1400, 1140, 1920, 1200)).save('/tmp/opencode/panel_crop.png')
"
```

Das Widget muss in der Leiste einen Wert im Format `12 % 64 °C` zeigen. Steht dort
`-- °C`, liefert `ksystemstats` keine Werte – dann zuerst prüfen:

```bash
busctl --user call org.kde.ksystemstats1 /org/kde/ksystemstats1 \
  org.kde.ksystemstats1 allSensors --json=short | grep -o '"gpu/[^"]*"'
```

Die Farblogik lässt sich testen, indem man `warnTemperature` temporär unter die
aktuelle Temperatur setzt (Datei
`~/.config/plasma-org.kde.plasma.desktop-appletsrc`, Gruppe
`[Containments][<n>][Applets][<id>][Configuration][General]`, dann Plasma neu
starten) und danach wieder entfernt.

## Was du nicht tun solltest

- Nicht auf C++/KDE-Framework umbauen „weil es sauberer ist“. QML reicht, und ein
  Build-Schritt würde die Symlink-Installation zerstören.
- Keine History-Graphen, Tray-Icons, Benachrichtigungen oder Konfigdialoge
  hinzufügen, ohne dass es einen konkreten Anlass gibt. Das Applet soll klein
  bleiben.
- Kein `install.sh`-Umbau auf Kopieren statt Symlinken, ohne die Konsequenz
  (Repo und Installation laufen auseinander) zu bedenken.
- Keine Änderungen an der Panel-Konfiguration des Nutzers, die über das
  Hinzufügen/Entfernen des eigenen Applets hinausgehen.

## Versionierung

- Version steht in `package/metadata.json` (`KPlugin.Version`, aktuell `1.0`).
- Bei funktionalen Änderungen erhöhen; die Applet-ID bleibt gleich.
- Commit-Konvention: `impl:`, `docs:`, `fix:` + knapper, imperativer Text.

## Bekannte Grenzen

- Nur eine GPU (`gpu/gpu0`). Multi-GPU ist nicht abgedeckt.
- Keine Historie, kein Graph – nur Momentwerte.
- NVIDIA nicht getestet.
- Die Sensor-IDs stammen von `ksystemstats`; ändert KDE sie, muss die Liste in
  `main.qml` angepasst werden.
