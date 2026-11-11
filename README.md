# Lichthaus for Plasma

**English** · [Deutsch](docs/i18n/README.de.md)

The KDE Plasma 6 tray widget of [Lichthaus](https://github.com/Gelaende51/Lichthaus):
on/off, brightness, the screen window and curve, profiles, Clap and Flick
switches, and Configure pages for bulbs, profiles, sound, video and
notifications. It is a front end only: it needs the Lichthaus service
(`lichthaus sync`) running on the same computer and talks to it through
`lichthaus-ctl`.

Formerly Haus.Licht-plasma (widget id `haus.licht.tray`); Lichthaus's `install/install.sh` moves a panel's widget to the new id `lichthaus.tray`, settings and position kept. <!-- rename-lichthaus: keep -->

- **AI disclosure**
  - Agent: Claude Code with Claude Opus 5.5 (Anthropic) wrote the widget and
    these docs; its tokens are part of the figure in
    [Lichthaus's README](https://github.com/Gelaende51/Lichthaus#readme).
  - Author (elypter): tested it on the real bulbs and in Plasma, chose the
    features and the layout.

[License: AGPL-3.0](LICENSE) · [Icon licences](package/LICENSES.md) ·
[Lichthaus docs](https://github.com/Gelaende51/Lichthaus#readme) ·
[Issues](https://github.com/Gelaende51/Lichthaus/issues)

## Install

- **With Lichthaus:** its `install/install.sh` downloads the latest release
  of this widget, checks its SHA-256 and installs or upgrades it.
- **By hand:** download `lichthaus.tray-<version>.plasmoid` from
  [Releases](https://github.com/Gelaende51/Lichthaus-plasma/releases), then
  `kpackagetool6 -t Plasma/Applet -i lichthaus.tray-<version>.plasmoid`
  (`-u` to upgrade). It shows up in the system tray after the next Plasma
  start.
- **From a checkout:** `kpackagetool6 -t Plasma/Applet -u package` (or `-i`
  the first time).

When the Lichthaus service is older than the widget expects, the popup says
so in one line; update Lichthaus.

## Settings

On Plasma the Configure pages are also in System Settings → Connected Devices →
Lichthaus (the KCMs in `kcm/`, built and installed by Lichthaus's
`install/install.sh`); *Connect new bulb…* then opens them there.
[How it works](https://github.com/Gelaende51/Lichthaus/blob/main/docs/system-settings.md).
