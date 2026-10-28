# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-10-28

### Changed

- Redesigned the desktop representation around Tahoe-style liquid-glass
  section cards, matching the macOS widget mockup: a host card (machine
  name, OS/RAM summary, live mono clock), then one glass card per metric
  with an icon + semibold title + mono percentage header.
- CPU: usage sparkline in an inset panel and numbered per-core tiles
  (fill rising from the bottom, eased).
- Memory: Used / Free / Swap breakdown with macOS-style color dots.
- Disk: Used/Total columns, usage-ramp progress bar and mono R/W rates.
- Bundled **JetBrains Mono** (SIL OFL — `LICENSES/JetBrainsMono-OFL.txt`)
  for all numerals, clocks and rates — the closest open match to Apple's
  SF Mono.
- Eased fills everywhere: tiles, meters and progress bars animate with
  500 ms OutCubic instead of stepping.
- Restyled the stat presentation using components adapted from
  [KStats](https://github.com/oowl/kstats) (MIT — see
  `LICENSES/KStats-MIT.txt`): `Sparkline` history charts, `BarStat` rows
  with sparkline meters and anti-jitter tabular numerals, `DetailRow`s.
- Glass material: added an Apple-style inner edge stroke and a diagonal
  top sheen, stronger refraction/chromatic aberration and a lighter
  tint so the wallpaper reads through like real glass.
- The hand-rolled `ActivityRing` remains only in the compact panel
  representation; superseded `RingGauge`, `CpuCoreBars` and `SectionHeader`
  components were removed.

### Added

- **Bundled Inter typeface** (SIL OFL — `LICENSES/Inter-OFL.txt`), the
  closest open match to Apple's SF Pro, used across the whole widget —
  this single change does the most to make it read as macOS.
- **Vibrancy**: the blurred backdrop gains a touch of saturation in the
  glass shader, like Apple's materials.
- Ring gauges stroke through an accent gradient with a soft glow
  (activity-ring style); sparklines are smoothed with quadratic curves
  and a fading gradient fill.
- `Sparkline.maxValue` normalization for byte-rate series and BarStat
  `valueSlot`/`meterWidth` extensions for wider value strings and meters
  (upstream adaptations, documented in the file headers).

### Fixed

- Sharper outer silhouette (corner radius 30 → 22, matching macOS widget
  corners) and the host card header: hostname bold and larger, clock
  properly right-aligned (anchors inside Layouts were silently ignored).
- The inset CPU graph panel and the network meters use a glass tint
  instead of a black backdrop.
- Sparkline gradient fills fade out at 75% height and canvases clip, so
  the fill no longer smears past the card edge.
- Per-core tiles keep a visible sliver when a core is near-idle.
- Multiple GPUs are listed with their names (probed gpu/gpu0..7), each
  with its own usage bar and VRAM row.
- SF Symbols-style monochrome SVG icons replace breeze icons in the
  section headers.
- macOS accent theme presets (Blue/Purple/Pink/Red/Orange/Yellow/Green/
  Graphite + custom picker) in the appearance settings; one accent now
  drives the whole widget, like macOS.
- Stat cards now size to their content — the fixed card heights taken
  from KStats' dropdown made the detail rows overflow onto neighbouring
  cards.
- Ring gauge text scales with the ring size, so the percent/label no
  longer clip on smaller rings; ring values ease instead of jumping.
- Network/disk/GPU meter rows stretch to the card width with an aligned
  label column and a dark meter backdrop, keeping the colored sparklines
  readable on any glass tint.

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
