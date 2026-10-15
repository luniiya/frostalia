# Frostalia

A personal, opinionated Wayland desktop shell built with Quickshell and QML.

Frostalia is an independent hard fork of [Noctalia v4](https://github.com/noctalia-dev/noctalia-shell), continued from my [Noctaliaa](https://github.com/luniiya/noctaliaa) fork. It has its own repository and a fresh Git history. Development follows my desktop and preferences; it does not track upstream releases.

Based on Noctalia v4, Frostalia takes a more modular approach: a shell that works alongside your window manager and the tools you choose. The goal is flexibility, so you can build your setup without handing every part of it over to the shell. Keep wallpapers with a tool such as `swww` or `hyprpaper`, and use an external lock command such as `hyprlock` or `swaylock`.

It includes a bar, launcher, panels, notifications, OSD, dock, desktop widgets and wallpaper-based color generation.

> [!NOTE]
> Built for my machines first. You're welcome to use it or take pieces of it, but expect opinionated defaults, breaking changes and no support promises.

## What makes it Frostalia

- **Settings in their own window**, rather than a panel attached to the bar.
- **Wallpapers managed by your system.** Use your preferred wallpaper tool; the shell can still generate colors from a wallpaper.
- **External screen locking** through a configurable command, defaulting to `hyprlock`.
- **Built-in AI usage widget** for Claude, Codex, Copilot, Gemini, OpenRouter and OpenCode Zen.
- **Container outline controls** for thickness, color, brightness and opacity.
- **Readable TOML settings per host**, backed by a small Rust helper, so one dotfiles repository can serve several machines.
- **Monochrome tray icons** that follow the accent color.
- **Theme refresh over IPC:** `qs -c frostalia ipc call colorScheme refresh`.
- **Bundled timer plugin** with study tracking; see [its README](Plugins/timer/README.md).

The shell config is `frostalia`, user data lives in `~/.config/frostalia`, caches live in `~/.cache/frostalia`, and environment overrides use `FROSTALIA_*`.

## Requirements

- A Wayland compositor. Hyprland is my daily setup. Niri, Sway, Scroll, Labwc and MangoWC integrations are inherited and may need work.
- [noctalia-qs](https://github.com/noctalia-dev/noctalia-qs), the Quickshell build used by this shell. Its dependency name stays unchanged.
- Rust and Cargo to build the settings and theming helpers during installation. Nix builds and supplies them automatically. The shell itself remains QML and JavaScript.
- Python 3 for theme generation and template rendering, plus optional calendar integration. Rust handles wallpaper pixel extraction, color quantization and palette generation.
- Feature-specific tools such as `brightnessctl`, `ddcutil`, `wl-clipboard`, `cliphist`, `wlsunset` and ImageMagick. The Nix package supplies its runtime dependencies; see [nix/package.nix](nix/package.nix).

## Install

```sh
git clone https://github.com/luniiya/frostalia.git
cd frostalia
./install.sh
```

The installer builds both Rust helpers before changing your installation, then symlinks `~/.config/quickshell/frostalia` to your checkout and starts or restarts Frostalia in a Wayland session. Existing files at that install path are backed up. Use `--copy` for a standalone copy or `--no-restart` to install without restarting.

Add this to your Hyprland config to launch on login:

```ini
exec-once = qs -c frostalia
```

```sh
qs -c frostalia log
qs -c frostalia kill
qs -c frostalia ipc call <target> <function>
```

## Moving from Noctaliaa

Install Frostalia first with `./install.sh --no-restart`. To bring existing settings and plugins across, copy the old data directory **before launching Frostalia**, provided no Frostalia data directory exists yet:

```sh
cp -a ~/.config/noctaliaa ~/.config/frostalia
qs -c noctaliaa kill
qs -c frostalia
```

Use your actual config paths if you set `XDG_CONFIG_HOME` or an override. Keep the old directory as a backup. Caches can be regenerated.

Frostalia migrates saved performance widget IDs, Battery widget toggles, the performance settings section and bundled scheme names on first load. Update your compositor startup commands, keybinds, scripts and environment overrides from `noctaliaa` / `NOCTALIAA_*` to `frostalia` / `FROSTALIA_*`. Generated application theme filenames now use `frostalia`; regenerate and apply your themes, and update any manual includes or custom template paths that still use the old name.

## Configuration

Settings are stored in `~/.config/frostalia/settings/<hostname>.toml`. On first launch, Frostalia creates the host file automatically from `defaults.toml` when present, or from the defaults. Existing per-host JSON and legacy `settings.json` files migrate to TOML automatically; the original JSON files remain untouched. Each host keeps its own file for host settings, including interface and font scaling. Appearance preferences and font families are shared per UI style in `settings/UI/<style>.toml`; the selected style stays in the host file. On migration, existing appearance values move into the active style’s file, while other styles start from their own defaults. `defaults.toml` is only a starting configuration for new hosts; edit `settings/<hostname>.toml` to change an existing machine.

```toml
[bar]
position = "bottom"
floating = true
backgroundOpacity = 0.95

[general]
scaleRatio = 1.1
```

Scripts can switch styles through IPC:

```sh
qs -c frostalia ipc call uiStyle set material
qs -c frostalia ipc call uiStyle set caelestia
qs -c frostalia ipc call uiStyle get
qs -c frostalia ipc call uiStyle list
```

`set` returns whether the switch was accepted. Unknown IDs or requests during another switch return `false`; saving and loading finish asynchronously. Screen corners, interface scaling, and font scaling stay per host under General. Font families belong to the selected UI style.

The settings window updates TOML through the Rust helper, preserving comments. Internal defaults, theme colors and plugin metadata still use JSON. Rust handles settings parsing, migration and safe file writes; the desktop UI continues to use QML and JavaScript.

| Override | Purpose |
| --- | --- |
| `FROSTALIA_CONFIG_DIR` | User data directory |
| `FROSTALIA_CACHE_DIR` | Cache directory |
| `FROSTALIA_SETTINGS_FILE` | Explicit TOML settings file |
| `FROSTALIA_SETTINGS_HELPER` | Path to the Rust settings helper |
| `FROSTALIA_THEMING_HELPER` | Path to the Rust image and color helper |
| `FROSTALIA_DEBUG=1` | Debug logging |

The defaults respect `XDG_CONFIG_HOME` and `XDG_CACHE_HOME`.

## Nix

The flake exports a default package, overlay, development shell, Home Manager module and NixOS module:

```sh
nix run github:luniiya/frostalia
nix develop
```

Add `frostalia.url = "github:luniiya/frostalia"` to your flake inputs. Import `inputs.frostalia.homeModules.default` for `programs.frostalia`, or `inputs.frostalia.nixosModules.default` for `services.frostalia`. Home Manager’s `programs.frostalia.settings` accepts a Nix attribute set, raw TOML or a TOML file path. It writes `~/.config/frostalia/defaults.toml` as a seed for new hosts; existing per-host settings take precedence and remain editable. Colors and plugin settings continue to use JSON.

The inherited modules discourage running the shell as a systemd service; launching from your compositor is preferred.

## Privacy

Frostalia has no default telemetry endpoint and sends no telemetry unless you configure `FROSTALIA_TELEMETRY_ENDPOINT` and explicitly enable the setting. The inherited upstream changelog popup has been removed; Frostalia does not show Noctalia release notes. The supporter service is disabled by default. Release checks and contributor links point to this repository.

Some optional integrations still use upstream services: the Noctalia plugin and color scheme registries, location search/IP geolocation, and the Noctalia VS Code theme extension. Weather and other online features also contact their respective providers. These are external dependencies, not Frostalia-hosted services. The About page retains an explicitly labeled link to support upstream Noctalia.

## Development

```sh
Scripts/dev/run-tests.sh             # Rust helper tests, headless QML tests and Python repository checks
python3 Scripts/dev/build-settings-search-index.py
```

Tests require Rust/Cargo, Qt 6's `qmltestrunner` (on Arch, `qt6-declarative`) and Python 3. Pure JS helpers live in `Helpers/`; QML tests live in `Tests/`, and repository checks in `Tests/python/`. Rust helpers and their unit tests live in `Tools/settings/` and `Tools/theming/`. See [CLAUDE.md](CLAUDE.md) for conventions and the settings checklist.

### UI styles

**Settings → User Interface → UI style** selects the shell's visual style. Caelestia preserves the original appearance. Material UI adds rounded surfaces, pill buttons with interaction feedback, thick split slider tracks with vertical handles, and animated switches with checkmarks. Caelestia defaults to bundled Rubik with container outlines enabled; Material defaults to bundled Roboto with outlines disabled and opaque panels. Color schemes remain separate. Saved appearance preferences take precedence over each style’s defaults; use the reset controls to restore them. Interface and font scaling remain per host.

Shared panels load their style’s registered `views` through `NStyleView`: control center, media cards/player, OSD, and notification content each have separate renderers. Shared services retain playback, notification lifetime, settings, and panel behavior. Material uses Android-inspired quick tiles, an artwork-backed media card with a playback wave, and elastic notification dragging. Both styles have a settings home with category cards; the navigation sidebar appears inside categories.

Styles are registered in `Helpers/UiStyles.js`. Each entry has a translated label key and tokens for typography, radii, spacing, borders, animations, sliders and toggles. `Commons/Style.qml` exposes the active tokens to shared widgets; use it when adding controls instead of hardcoding style values. An unknown saved style falls back to Caelestia for rendering without rewriting the saved choice. Add a complete registry entry, its English label in `Assets/Translations/en.json`, and tests in `Tests/tst_uistyles.qml` when implementing another style. The `controls.renderer` token selects the control rendering path; Material-specific rendering stays separate from Caelestia. Styles change live, saving pending appearance edits to the previous style and loading the selected style’s preferences. `Helpers/UiStyleSettings.js` defines the appearance fields and shared defaults; a registry entry can override them with `settingsDefaults` (for example, zero radius ratios for square corners). Reset buttons use the active style’s defaults. Material UI is an original implementation with Clavis Shell used as a visual reference; no Clavis source or assets are bundled.

## Credits and license

Frostalia builds on Noctalia and its contributors' work. The inherited artwork remains credited to its original creators; see [CREDITS.md](CREDITS.md). A fresh Git history does not change that attribution.

Licensed under the [MIT License](LICENSE), with the original copyright notice retained.
