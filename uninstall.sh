#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
spice_dir="$config_home/spicetify"
theme_dir="$spice_dir/Themes/Comfy"
unit="$config_home/systemd/user/spiceflow.service"

systemctl --user disable --now spiceflow.service 2>/dev/null || true
rm -f -- "$unit"
systemctl --user daemon-reload

if [[ -f "$theme_dir/color.ini.spiceflow-base" ]]; then
  mv -- "$theme_dir/color.ini.spiceflow-base" "$theme_dir/color.ini"
fi

rm -f -- "$spice_dir/Extensions/spiceflow.js"
rm -rf -- "$spice_dir/spiceflow"
rm -f -- "$HOME/.local/bin/spiceflow"

extensions=$(spicetify config extensions 2>/dev/null | tail -n 1 || true)
if [[ "|$extensions|" == *"|spiceflow.js|"* ]]; then
  spicetify config extensions spiceflow.js-
fi

printf 'Spiceflow removed. Comfy was left installed.\n'
printf 'Run `spicetify apply` when convenient to remove the extension from Spotify.\n'
