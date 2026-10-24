# GPU Monitor – Plasma-Applet

Zeigt in der KDE-Taskleiste **GPU-Auslastung und Junction-Temperatur** – und
warnt per Farbe, bevor die Grafikkarte zu heiß wird.

![Screenshot](docs/screenshot.png)

## Warum es das gibt

Wer lokal mit LLMs oder Diffusionsmodellen arbeitet, belastet die GPU über
längere Zeit. Bei zu wenig Frischluft im Gehäuse reicht die Wärmeabfuhr irgendwann
nicht mehr, und die Hotspot-Temperatur klettert, während die Lüfter längst voll
laufen.

Die übliche Anzeige (Edge-Temperatur) merkt das zu spät: sie liegt typischerweise
10–15 K unter dem Hotspot. Dieses Applet zeigt deshalb die **Junction-Temperatur**
und färbt sie ein:

| Bereich | Farbe |
| --- | --- |
| unter der Warnschwelle (Standard 85 °C) | normale Textfarbe |
| ab Warnschwelle | orange |
| ab kritischer Schwelle (Standard 100 °C) | rot |

Beide Schwellen sind einstellbar.

## Funktionen

- Auslastung in Prozent und Junction-Temperatur direkt in der Leiste
- Farbcodierte Temperaturwarnung
- Klick öffnet ein Popup mit Edge- und Speicher-Temperatur, Leistungsaufnahme
  und VRAM-Belegung
- Tooltip mit denselben Werten, ohne klicken zu müssen
- Feste Breite: die Leiste springt beim Aktualisieren nicht
- Reines QML, keine Abhängigkeiten, kein Build-Schritt, kein Hintergrunddienst

## Installation

```bash
git clone https://github.com/Stecker1312/plasma-gpu-monitor.git
cd plasma-gpu-monitor
./install.sh
systemctl --user restart plasma-plasmashell.service
```

Danach Rechtsklick auf die Leiste → *Widgets hinzufügen* → **GPU Monitor**.

`install.sh` legt lediglich einen Symlink an:

```
~/.local/share/plasma/plasmoids/org.stecker.gpumonitor -> <repo>/package
```

Dadurch ist die Repo-Version immer die laufende Version.

Deinstallieren:

```bash
rm ~/.local/share/plasma/plasmoids/org.stecker.gpumonitor
```

## Konfiguration

Rechtsklick auf das Widget → **GPU Monitor konfigurieren**

- Warnschwelle in °C (Standard 85)
- kritische Schwelle in °C (Standard 100)
- Auslastungsanzeige in der Leiste ein-/ausblenden

Die Schwellen beziehen sich auf die Junction-Temperatur. AMD gibt für Navi 31
(RX 7900 XT/XTX) 110 °C als Maximum an – die rote Stufe bei 100 °C lässt also
noch Reserve.

## Kompatibilität

| | |
| --- | --- |
| Getestet mit | Bazzite, Plasma 6.7.5, Wayland |
| GPU | AMD Radeon RX 7900 XTX (Navi 31), `amdgpu` |
| Voraussetzung | Plasma 6, `ksystemstats` mit GPU-Plugin |

Andere AMD-Karten mit `amdgpu` sollten funktionieren, solange `ksystemstats` sie
als `gpu/gpu0` führt. NVIDIA ist nicht getestet.

Prüfen, welche Sensoren verfügbar sind:

```bash
busctl --user call org.kde.ksystemstats1 /org/kde/ksystemstats1 \
  org.kde.ksystemstats1 allSensors --json=short | grep -o '"gpu/[^"]*"'
```

## Grenzen

- nur eine GPU (`gpu/gpu0`)
- keine Verlaufsgraphen, nur Momentwerte
- kein NVIDIA-Support (ungetestet)

## Entwicklung

Die technische Dokumentation für Bearbeitung und Fehlersuche steht in
[AGENTS.md](AGENTS.md) – inklusive der Sensor-IDs, der bekannten Fallstricke und
eines Testrezepts vor jedem Commit.

Kurzfassung: Dateien unter `package/` ändern, Plasma neu starten, prüfen, committen.

```bash
systemctl --user restart plasma-plasmashell.service
journalctl --user --since "-1min" --no-pager | grep -iE 'qml.*error|Unable to assign'
```

> Dieses Projekt wird nicht regelmäßig von Hand gepflegt, sondern bei Bedarf mit
> KI-Unterstützung weiterentwickelt. Es ist bewusst klein gehalten: keine
> Abhängigkeiten, keine Architektur, die Aufmerksamkeit braucht.

## Lizenz

MIT – siehe [LICENSE](LICENSE).
