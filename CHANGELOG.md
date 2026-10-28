# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project adheres to [Semantic Versioning](https://semver.org/).

## [0.4.0] - 2026-10-29

### Added

- **Battery section** (orderable, laptops only): macOS-style battery pill
  with level fill and terminal nub, mono percentage in the card header,
  and the charge state (charging / discharging with remaining time,
  fully charged) using plasma's own battery control (Solid/UPower).
- **macOS-style bars**: progress bars across the widget (disk, GPUs,
  battery) now render as inset rounded tracks with a gradient fill and a
  glossy leading cap.
- Battery level follows the macOS color language: green while charging
  or healthy, yellow below 25%, red below 10%.

## [0.3.1] - 2026-10-29

### Fixed

- Sparkline sample spacing was derived from the buffer limit instead of
  the actual series length, pushing curves and fills past the plot edge
  (the vertical bars around the network graphs).
- Sparklines draw with a light 3-sample moving average so bursty traffic
  renders as rounded hills instead of detached vertical bars.

## [0.3.0] - 2026-10-29

### Added

- **Deep customization pass** — the settings dialog now has five pages
  (Sections, Appearance, Effects, Colors, About):
  - **Sections**: every card can be reordered (up/down) and toggled
    independently; the order persists across restarts.
  - Host card toggle, 12/24-hour clock, seconds and date switches.
  - **Effects** page: blur strength, glass tint strength (40–160%),
    refractive edge, continuous background sampling, floating drop
    shadow with adjustable opacity.
  - **Colors** page: per-metric colors for CPU, memory, download,
    upload and GPU — empty follows the accent theme, with per-row and
    bulk reset.
  - Appearance adds inner-card corner radius (4–28 px) and a layout
    density switch (comfortable / compact).
- Per-metric colors fall back to the accent theme when empty.
- The color pickers use KDE's KColorButton (org.kde.kquickcontrols).

### Fixed

- The config schema validation in CI now handles the KConfig namespace.

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

### Changed

- The widget now floats with a macOS-style soft drop shadow (MultiEffect
  renders a blurred copy of the glass silhouette behind it).
- The edge treatment is soft and even — the previous hard directional
  specular drew a bright streak along the top edge.

### Fixed

- Per-core tiles were permanently empty: the Instantiator materializes
  its sensors in componentComplete, after bindings that call objectAt()
  during construction, leaving those bindings stuck on null with no
  re-run trigger. A core revision counter (bumped on sensor readiness)
  now re-arms the tile bindings, and fills use a perceptual sqrt scale
  with a 4px minimum so near-idle cores stay visible.
- Removed the diagonal top sheen that read as a white stain over the
  host card; the glass instead gains a luminosity lift (brightness +
  saturation) so dark wallpapers glow through the material.
- Section icons load reliably: white-stroke SVGs rendered as plain
  images (Kirigami isMask silently failed on several), and the paths
  were fixed after the Image switch.
- The glass silhouette is now an exact rounded-rect SDF — the previous
  superellipse swelled with widget height, reading as huge round corners.
  Corner radius is configurable (8–40 px, default 20) in the appearance
  settings.
- Host header: hostname 23 px bold, clock/date genuinely right-aligned
  (anchors inside Layouts were silently ignored).
- Network rows are transparent — label, bare sparkline and mono rate sit
  directly on the card like the history graph; the dark meter pills are
  gone, as is the unused BarStat component.
- Sparkline fills fade out by 80% height with a 1px inset and clipped
  canvases, killing the colored smear that leaked past the card edge.
- Sparkline geometry fix: sample spacing was derived from the buffer
  limit (36) instead of the actual series length (60), pushing the curve
  and fill past the left edge of the plot; spacing now follows the real
  series length and the area polygon closes on the correct side.
- Sparkline draws with a centered 3-sample moving average, turning
  one-sample traffic bursts into rounded hills (stored data untouched).
- Per-core tiles keep a 3px sliver near idle and a shorter, lighter
  track.
- GPU cards show a small temperature readout next to each usage
  percentage.
- Section icons render as plain white SF-style SVG images (Kirigami
  isMask silently failed on several of them).
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
