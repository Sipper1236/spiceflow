#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install_only=false
if [[ ${1:-} == --install-only ]]; then
  install_only=true
elif (( $# > 0 )); then
  printf 'Usage: %s [--install-only]\n' "$0" >&2
  exit 2
fi
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
spice_dir="$config_home/spicetify"
theme_dir="$spice_dir/Themes/Comfy"
runtime_dir="$spice_dir/spiceflow"
unit_dir="$config_home/systemd/user"
bin_dir="$HOME/.local/bin"

for command_name in git node spicetify systemctl; do
  command -v "$command_name" >/dev/null || {
    printf 'Missing required command: %s\n' "$command_name" >&2
    exit 1
  }
done

mkdir -p "$spice_dir/Extensions" "$spice_dir/Themes" "$runtime_dir" "$unit_dir" "$bin_dir"

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
install -m 0755 "$project_dir/doctor.sh" "$runtime_dir/doctor.sh"
install -m 0755 "$project_dir/src/spiceflow-cli" "$bin_dir/spiceflow"
install -m 0644 "$project_dir/systemd/spiceflow.service" "$unit_dir/spiceflow.service"

systemctl --user daemon-reload

if $install_only; then
  printf 'Spiceflow installed but not activated. Run `spiceflow enable` when ready.\n'
  exit 0
fi

printf '\nSpiceflow is installed. Enable it and apply the initial Spicetify setup now? [Y/n] '
read -r answer
if [[ ! "$answer" =~ ^[Nn]$ ]]; then
  "$bin_dir/spiceflow" enable
else
  printf 'Skipped. Run `spiceflow enable` when convenient.\n'
fi

printf 'Installed Spiceflow. Run `spiceflow doctor` to verify it.\n'
