# Contributing

Thanks for helping improve the System Monitor (Glass) widget!

## Repository layout

```
package/                    the Plasma/Applet package (what gets installed)
  metadata.json             KPackage metadata (id, version, …)
  icon.svg / icon.png       widget icon used by the Add Widgets dialog
  contents/config/          KConfig schema (main.xml) and config model
  contents/ui/              QML sources
    main.qml                PlasmoidItem root: picks representation
    SystemMonitorView.qml   full desktop card
    CompactPanel.qml        compact panel pill
    components/             this widget's own pieces (glass background,
                            sensors, palette, compact ring)
      kstats/               stat components adapted from oowl/kstats
                            (MIT — headers list the modifications)
      shaders/*.frag        GLSL sources — compiled to .qsb and committed
    config/                 configuration dialog pages
docs/                       screenshots
LICENSES/                   third-party license texts (KStats-MIT.txt)
build-shaders.sh            .frag → .qsb baker (qt6-shadertools)
install.sh                  install/upgrade + optional plasmashell restart
package.sh                  build a .plasmoid zip into dist/
```

## Development workflow

1. **Fork & branch** — `main` is stable; cut feature branches from it
   (`feat/<topic>`, `fix/<topic>`).
2. **Edit QML** — components live in `package/contents/ui/components/`.
   Keep components self-contained: representations cannot bind to ids
   declared in `main.qml`, pass nothing across that boundary.
3. **Shaders** — after touching any `.frag`, run `./build-shaders.sh` and
   commit the regenerated `.qsb` next to it. Shaders are Vulkan-style GLSL
   (`#version 440`), baked for GLSL 100es/120/150, HLSL 50 and MSL 12.
4. **Lint** — `qmllint package/contents/ui -I /usr/lib/qt6/qml` must stay
   clean.
5. **Test on a live desktop** — `./install.sh` restarts plasmashell; watch
   the journal for QML errors:
   ```bash
   journalctl --user -u plasma-plasmashell -f | grep -i system-monitor
   ```
   Test all four style combinations (glass/solid × dark/light), the panel
   representation, and a low-blur configuration.
6. **Commits** — [Conventional Commits](https://www.conventionalcommits.org/):
   `feat:`, `fix:`, `docs:`, `chore:`, `refactor:` … Keep each commit
   focused.
7. **Pull requests** — fill in the template; include before/after
   screenshots for visual changes. CI must pass (shader baking, metadata
   and config validation, bundle build).

## Versioning / releases

Bump `KPlugin.Version` in `package/metadata.json`, add a CHANGELOG entry,
then tag `vX.Y.Z`. `./package.sh` names the bundle after the metadata
version.

## Code style

- QML: 4-space indent, camelCase ids/properties, leading-underscore names
  for private properties.
- Keep comments for constraints the code cannot express (timing, caching,
  platform quirks) — not narration.
- User-visible strings go through `i18n()`.
