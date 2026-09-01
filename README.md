# Spiceflow

Playback-safe wallpaper colors for **Ryoku + Spicetify + Comfy**.

Spiceflow makes an open Spotify client follow Ryoku's live Matugen wallpaper
palette without restarting Spotify, reloading its renderer, or pausing playback.

## Why

Comfy includes a `wal16` scheme that reads Xresources. Ryoku uses Matugen and
stores its palette in `~/.cache/ryoku/colors.json`, so Comfy's stock `wal16`
scheme does not receive Ryoku's colors. Spicetify's normal `refresh` and `watch`
flows reload theme resources or the renderer; renderer reloads pause playback.

Spiceflow changes only CSS custom properties in the running page.

## How it works

```text
wallpaper → Ryoku/Matugen → ~/.cache/ryoku/colors.json
                                │
                                ├─ Spiceflow bridge → Comfy/color.ini
                                │
                                └─ localhost:47616 → Spotify extension
                                                        │
                                                        └─ --spice-* variables
```

- A small Node service watches Ryoku's palette and keeps Comfy's on-disk
  `wal16` scheme current for future launches.
- The service exposes the palette on localhost only, with Chromium's required
  private-network CORS headers.
- A Spicetify extension polls the local endpoint and updates `--spice-*` plus
  `--spice-rgb-*` variables in place.
- No renderer reload means playback continues uninterrupted.

## Requirements

- Ryoku with Follow Wallpaper and app theming enabled
- Spotify patched by Spicetify
- Node.js, Git, curl, and systemd user services
- Linux (the current integration targets Ryoku)

## Install

```bash
git clone https://github.com/Sipper1236/spiceflow.git
cd spiceflow
./install.sh
```

The installer can download Comfy if it is absent. The initial `spicetify apply`
may reload Spotify once to install the theme and extension. Wallpaper changes
after setup do not reload Spotify or pause playback.

For install-only environments such as RyoStore:

```bash
./install.sh --install-only
spiceflow enable
```

The first command places the integration without changing Spotify or starting
the service. Activation remains an explicit user action.

## Verify

```bash
spiceflow doctor
```

Or inspect each layer manually:

```bash
systemctl --user status spiceflow.service
curl -fsS http://127.0.0.1:47616/colors.json
spicetify config current_theme
spicetify config color_scheme
spicetify config extensions
```

Expected theme/scheme values are `Comfy` and `wal16`, and the extensions list
must contain `spiceflow.js`.

## Troubleshooting

### Wallpaper changes but Spotify does not

Check whether Ryoku updated its source palette:

```bash
stat ~/.cache/ryoku/colors.json
```

If it did not change, confirm Follow Wallpaper and app theming in Ryoku, then
run `ryoku reload`.

If it changed, inspect Spiceflow:

```bash
systemctl --user restart spiceflow.service
journalctl --user -u spiceflow.service -n 100 --no-pager
curl -i http://127.0.0.1:47616/colors.json
```

The response should include `Access-Control-Allow-Origin: *` and
`Access-Control-Allow-Private-Network: true`.

### Extension is missing

```bash
spicetify config extensions spiceflow.js
spicetify refresh -e -n
```

Restart Spotify normally once if it was already open; future palette updates
remain reload-free.

### Comfy reverted or disappeared

```bash
spicetify config current_theme Comfy color_scheme wal16 \
  inject_css 1 replace_colors 1 overwrite_assets 1 inject_theme_js 1
spicetify apply
```

Do not use `spicetify watch -s` for this purpose: its renderer reload pauses
playback.

## Uninstall

```bash
./uninstall.sh
```

The uninstaller removes Spiceflow and restores Comfy's pre-Spiceflow
`color.ini` when a backup exists. It leaves Comfy itself installed.

## License

[GPL-3.0-or-later](LICENSE). Comfy is a separate project and retains its own
license.
