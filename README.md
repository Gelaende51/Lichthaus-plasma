# Haus.Licht for Plasma

**English** · [Deutsch](docs/i18n/README.de.md)

The KDE Plasma 6 tray widget of [Haus.Licht](https://github.com/Gelaende51/Haus.Licht):
on/off, brightness, the screen window and curve, profiles, Clap and Flick
switches, and Configure pages for bulbs, profiles, sound, video and
notifications. It is a front end only: it needs the Haus.Licht service
(`hauslicht sync`) running on the same computer and talks to it through
`hauslicht-ctl`.

- **AI disclosure**
  - Agent: Claude Code with Claude Opus 5.5 (Anthropic) wrote the widget and
    these docs; its tokens are part of the figure in
    [Haus.Licht's README](https://github.com/Gelaende51/Haus.Licht#readme).
  - Author (elypter): tested it on the real bulbs and in Plasma, chose the
    features and the layout.

[License: AGPL-3.0](LICENSE) · [Icon licences](package/LICENSES.md) ·
[Haus.Licht docs](https://github.com/Gelaende51/Haus.Licht#readme) ·
[Issues](https://github.com/Gelaende51/Haus.Licht/issues)

## Install

- **With Haus.Licht:** its `install/install.sh` downloads the latest release
  of this widget, checks its SHA-256 and installs or upgrades it.
- **By hand:** download `haus.licht.tray-<version>.plasmoid` from
  [Releases](https://github.com/Gelaende51/Haus.Licht-plasma/releases), then
  `kpackagetool6 -t Plasma/Applet -i haus.licht.tray-<version>.plasmoid`
  (`-u` to upgrade). It shows up in the system tray after the next Plasma
  start.
- **From a checkout:** `kpackagetool6 -t Plasma/Applet -u package` (or `-i`
  the first time).

When the Haus.Licht service is older than the widget expects, the popup says
so in one line; update Haus.Licht.
