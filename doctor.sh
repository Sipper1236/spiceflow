#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -u

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
cache_home=${XDG_CACHE_HOME:-"$HOME/.cache"}
failed=0

check() {
  if "$@" >/dev/null 2>&1; then
    printf 'ok   %s\n' "$*"
  else
    printf 'FAIL %s\n' "$*"
    failed=1
  fi
}

check test -s "$cache_home/ryoku/colors.json"
check test -s "$config_home/spicetify/Themes/Comfy/color.ini"
check test -s "$config_home/spicetify/Extensions/spiceflow.js"
check systemctl --user is-active spiceflow.service
check curl -fsS http://127.0.0.1:47616/colors.json

theme=$(spicetify config current_theme 2>/dev/null | tail -n 1)
scheme=$(spicetify config color_scheme 2>/dev/null | tail -n 1)
extensions=$(spicetify config extensions 2>/dev/null | tail -n 1)

[[ "$theme" == Comfy ]] || { printf 'FAIL current theme is %q, expected Comfy\n' "$theme"; failed=1; }
[[ "$scheme" == wal16 ]] || { printf 'FAIL color scheme is %q, expected wal16\n' "$scheme"; failed=1; }
[[ "|$extensions|" == *"|spiceflow.js|"* ]] || {
  printf 'FAIL spiceflow.js is not enabled\n'
  failed=1
}

if (( failed == 0 )); then
  printf 'Spiceflow is healthy.\n'
fi
exit "$failed"
