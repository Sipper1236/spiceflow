#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
spice_dir="$config_home/spicetify"
theme_dir="$spice_dir/Themes/Comfy"
runtime_dir="$spice_dir/spiceflow"
unit_dir="$config_home/systemd/user"

for command_name in git node spicetify systemctl; do
  command -v "$command_name" >/dev/null || {
    printf 'Missing required command: %s\n' "$command_name" >&2
    exit 1
  }
done

mkdir -p "$spice_dir/Extensions" "$spice_dir/Themes" "$runtime_dir" "$unit_dir"

if [[ ! -f "$theme_dir/color.ini" ]]; then
  download_dir=$(mktemp -d)
  trap 'rm -rf -- "$download_dir"' EXIT
  git clone --depth 1 https://github.com/Comfy-Themes/Spicetify.git "$download_dir/comfy"
  cp -a "$download_dir/comfy/Comfy" "$theme_dir"
fi

if [[ ! -f "$theme_dir/color.ini.spiceflow-base" ]]; then
  cp "$theme_dir/color.ini" "$theme_dir/color.ini.spiceflow-base"
fi

install -m 0644 "$project_dir/src/spiceflow.js" "$spice_dir/Extensions/spiceflow.js"
install -m 0644 "$project_dir/src/server.js" "$runtime_dir/server.js"
install -m 0644 "$project_dir/systemd/spiceflow.service" "$unit_dir/spiceflow.service"

extensions=$(spicetify config extensions 2>/dev/null | tail -n 1 || true)
if [[ "|$extensions|" != *"|spiceflow.js|"* ]]; then
  spicetify config extensions spiceflow.js
fi

spicetify config current_theme Comfy color_scheme wal16 \
  inject_css 1 replace_colors 1 overwrite_assets 1 inject_theme_js 1

systemctl --user daemon-reload
systemctl --user enable --now spiceflow.service

printf '\nSpiceflow is installed. Apply the initial Spicetify setup now? [Y/n] '
read -r answer
if [[ ! "$answer" =~ ^[Nn]$ ]]; then
  spicetify apply
else
  printf 'Skipped. Run `spicetify apply` once when convenient.\n'
fi

printf 'Installed Spiceflow. Run %s/doctor.sh to verify it.\n' "$project_dir"
