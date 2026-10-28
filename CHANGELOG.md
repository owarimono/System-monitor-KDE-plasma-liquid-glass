# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-10-28

### Changed

- Restyled the stat presentation to the macOS Stats-app look using
  components adapted from [KStats](https://github.com/oowl/kstats)
  (MIT — see `LICENSES/KStats-MIT.txt`): `RingGauge`, `BarStat` rows with
  sparkline meters and anti-jitter tabular numerals, `Sparkline` history
  charts, `CpuCoreBars` and `DetailRow`s.
- Per-metric accent colors (CPU blue, RAM purple, network green/orange,
  GPU pink), following the macOS Stats convention.
- The hand-rolled `ActivityRing`, `RollingGraph`, `StatBar`, `CoreBars`
  and `SectionHeader` components were removed where superseded
  (`ActivityRing` remains in the compact panel representation).

### Added

- `Sparkline.maxValue` normalization for byte-rate series and BarStat
  `valueSlot`/`meterWidth` extensions for wider value strings and meters
  (upstream adaptations, documented in the file headers).

## [0.1.0] - 2026-10-28

### Added

- Initial release of the System Monitor (Glass) widget for KDE Plasma 6.
- Liquid glass material: wallpaper capture → crop → separable Gaussian blur
  → compose shader with squircle mask, Snell-style edge refraction, chromatic
  aberration, specular border, mouse-following sheen and dithering.
- Glass and solid materials, dark/light/system appearance, configurable
  accent color, blur strength and refraction.
- CPU section: activity ring, average frequency and temperature, per-core
  bars, rolling usage graph.
- Memory section with swap indicator; Network section with download/upload
  sparklines; Disk section with usage color ramp and R/W rates; GPU section
  auto-shown when sensors exist.
- Compact panel representation with a mini activity ring.
- Configuration pages (sections, appearance, about) and burst-based GPU
  idle behavior for the blur chain.
- Packaging (.plasmoid bundle), install script, shader build script and CI.
