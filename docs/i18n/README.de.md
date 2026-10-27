# Haus.Licht für Plasma

[English](../../README.md) · **Deutsch**

Das Tray-Widget für KDE Plasma 6 von [Haus.Licht](https://github.com/Gelaende51/Haus.Licht):
An/Aus, Helligkeit, Bildschirmfenster und Kurve, Profile, Schalter für
Klatschen und Flick sowie Einstellungsseiten für Lampen, Profile, Ton, Video
und Benachrichtigungen. Es ist nur eine Oberfläche: Es braucht den
Haus.Licht-Dienst (`hauslicht sync`) auf demselben Computer und spricht über
`hauslicht-ctl` mit ihm.

- **Offenlegung KI-Einsatz**
  - Agent: Claude Code mit Claude Opus 5.5 (Anthropic) hat das Widget und
    diese Dokumentation geschrieben; seine Tokens sind in der Angabe in
    [README von Haus.Licht](https://github.com/Gelaende51/Haus.Licht/blob/main/docs/i18n/README.de.md)
    enthalten.
  - Autor (elypter): an den echten Lampen und in Plasma getestet, Funktionen
    und Aufbau festgelegt.

[Lizenz: AGPL-3.0](../../LICENSE) · [Icon-Lizenzen (englisch)](../../package/LICENSES.md) ·
[Haus.Licht-Dokumentation](https://github.com/Gelaende51/Haus.Licht/blob/main/docs/i18n/README.de.md) ·
[Fehlermeldungen](https://github.com/Gelaende51/Haus.Licht/issues)

## Installation

- **Mit Haus.Licht:** dessen `install/install.sh` lädt die neueste Version
  dieses Widgets herunter, prüft ihre SHA-256-Summe und installiert oder
  aktualisiert es.
- **Von Hand:** `haus.licht.tray-<Version>.plasmoid` unter
  [Releases](https://github.com/Gelaende51/Haus.Licht-plasma/releases)
  herunterladen, dann
  `kpackagetool6 -t Plasma/Applet -i haus.licht.tray-<Version>.plasmoid`
  (`-u` zum Aktualisieren). Es erscheint nach dem nächsten Plasma-Start im
  Systemabschnitt der Kontrollleiste.
- **Aus einem Checkout:** `kpackagetool6 -t Plasma/Applet -u package` (beim
  ersten Mal `-i`).

Ist der Haus.Licht-Dienst älter, als das Widget erwartet, sagt das Popup das
in einer Zeile; dann Haus.Licht aktualisieren.

## Einstellungen

Unter Plasma finden sich die Einstellungsseiten auch in den
Systemeinstellungen → Hardware → Haus.Licht (die KCMs in `kcm/`, gebaut und
installiert von `install/install.sh` aus Haus.Licht); *Neue Lampe verbinden…*
öffnet sie dann dort. [Wie es funktioniert](https://github.com/Gelaende51/Haus.Licht/blob/main/docs/system-settings.md) (englisch).
