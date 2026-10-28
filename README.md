# System Monitor — KDE Plasma Liquid Glass

A macOS Tahoe-style **liquid glass** system monitor widget for KDE Plasma 6.

CPU, memory, network, disk and GPU live in frosted glass section cards over a real-time blurred, refracted and debanded backdrop — with Inter + JetBrains Mono typography, per-core usage tiles, rolling graphs and a live clock.

[![CI](https://github.com/owarimono/System-monitor-KDE-plasma-liquid-glass/actions/workflows/ci.yml/badge.svg)](https://github.com/owarimono/System-monitor-KDE-plasma-liquid-glass/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/owarimono/System-monitor-KDE-plasma-liquid-glass)](https://github.com/owarimono/System-monitor-KDE-plasma-liquid-glass/releases)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue)](LICENSE)

![screenshot](docs/screenshot.png)

## Features

- **Real liquid glass** — the widget's backdrop is captured from the wallpaper, blurred through a separable Gaussian chain, then composed with edge refraction, chromatic aberration, a soft specular rim, mpv-style debanding and triangle dithering.
- **Glass section cards** — one card per metric with an icon, semibold title and mono percentage header; reorderable and individually toggleable.
- **Host card** — machine name, OS/RAM summary and a live clock with configurable format.
- **Per-metric colors** — macOS accent theme presets (Blue, Purple, Pink, Red, Orange, Yellow, Green, Graphite) plus per-metric overrides.
- **Tunable effects** — blur strength, glass tint, refraction, corner radii, layout density, drop shadow and glass tint strength.
- **Typography** — bundled Inter (labels) and JetBrains Mono (numerals), both SIL OFL.

### Sections

| Section | Shows |
| --- | --- |
| **CPU** | Usage percentage, average frequency, temperature, per-core tiles, rolling graph |
| **Memory** | Usage percentage, Used / Free / Swap breakdown with color dots |
| **Network** | Download / upload rates with smoothed sparklines and a rolling history graph |
| **Disk** | Usage percentage, Used / Total columns, usage-ramp bar, read/write rates |
| **GPU** | One block per adapter with name, usage bar, temperature and VRAM (auto-detected) |

## Requirements

- KDE Plasma **6.1+** (Wayland or X11)
- `ksystemstats` / `libksysguard` (ship with Plasma)

## Installation

**Option 1 — .plasmoid bundle (easiest)**

1. Download `SystemMonitor-Glass-v*.plasmoid` from [Releases](https://github.com/owarimono/System-monitor-KDE-plasma-liquid-glass/releases).
2. Right-click the desktop → *Add Widgets…* → *Get New Widgets…* → *Install Widget From Local File…*

**Option 2 — from source**

```bash
git clone https://github.com/owarimono/System-monitor-KDE-plasma-liquid-glass.git
cd System-monitor-KDE-plasma-liquid-glass
./install.sh        # installs and restarts plasmashell
```

**Option 3 — kpackagetool6**

```bash
kpackagetool6 --type=Plasma/Applet --install package/
```

### Uninstall

```bash
kpackagetool6 --type=Plasma/Applet --remove io.github.system-monitor-kde.glass
```

## Configuration

Right-click the widget → *Configure System Monitor (Glass)*. Five pages:

| Page | Controls |
| --- | --- |
| **Sections** | Card order (up/down), per-section visibility, per-core tiles, graphs, temperatures, R/W rates, VRAM, host card, clock format |
| **Appearance** | Material (liquid glass / solid), color scheme (dark / light / system), accent theme presets, widget & card corner radius, layout density |
| **Effects** | Blur strength, glass tint strength, refractive edge, continuous background sampling, drop shadow and its opacity |
| **Colors** | Per-metric colors (CPU, memory, download, upload, GPU) — empty follows the accent theme |
| **About** | Version, links |

## How it works

```
wallpaper item ──► ShaderEffectSource (capture)
                     │
                     ▼
              crop shader        widget region, UV-mapped
                     │
                     ▼
        Gaussian blur (H → V)      adaptive resolution
                     │
                     ▼
              glass shader       rounded-rect mask, edge refraction,
                                 chroma, vibrancy, deband, specular rim,
                                 triangle dithering
```

Sensor data comes from KDE's `ksystemstats` daemon through the `org.kde.ksysguard.sensors` QML API — the same source plasma-systemmonitor uses. The glass pass applies mpv-style debanding (randomized-radius flattening + triangle dithering) so smooth gradients stay free of 8-bit banding rings.

## Development

```bash
./build-shaders.sh   # bake .frag → .qsb (needs qt6-shadertools)
qmllint package/contents/ui -I /usr/lib/qt6/qml
./install.sh         # install/upgrade + restart plasmashell
./package.sh         # build a .plasmoid bundle into dist/
```

Compiled `.qsb` shaders are committed, so installing a checkout never requires the shader toolchain — only editing a `.frag` file does. See [CONTRIBUTING.md](CONTRIBUTING.md) for the layout and workflow.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Flat translucent card, no glass | The wallpaper could not be sampled (panel placement, unsupported wallpaper plugin) |
| Blur looks pixelated | Raise *Effects → Blur strength* past 16 px (the blur chain switches to full resolution) |
| GPU section missing | The `ksystemstats` GPU plugin exposes no sensors on your system |
| CPU temperature missing | Needs lm-sensors-capable hardware; the row hides itself |
| Banding on smooth gradients | Handled by deband + dithering; raise *Effects → Blur strength* if your display exaggerates it |

## Credits

- Stat components (sparklines, detail rows, fixed-slot typography) adapted from [KStats](https://github.com/oowl/kstats) by Jun Ouyang — MIT, see `LICENSES/KStats-MIT.txt`. KStats is inspired by the macOS [Stats](https://github.com/exelban/stats) menu-bar app.
- Bundled fonts: [Inter](https://rsms.me/inter/) and [JetBrains Mono](https://www.jetbrains.com/lp/mono/) — SIL OFL 1.1 (`LICENSES/`).
- Design inspired by [liquidglass-kde-widgets](https://github.com/jaxparrow07/liquidglass-kde-widgets) by jaxparrow07 — this project is an independent implementation.
- Apple, macOS and iOS are trademarks of Apple Inc. This project is not affiliated with or endorsed by Apple. No Apple fonts or artwork are bundled.

## License

[GPL-3.0](LICENSE)
