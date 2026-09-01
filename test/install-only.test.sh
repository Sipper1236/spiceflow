#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

mkdir -p "$test_root/home/.config/spicetify/Themes/Comfy" "$test_root/bin"
printf '[wal16]\nmain = 121212\n' > "$test_root/home/.config/spicetify/Themes/Comfy/color.ini"

for command_name in spicetify systemctl; do
  printf '#!/bin/sh\nexit 0\n' > "$test_root/bin/$command_name"
  chmod +x "$test_root/bin/$command_name"
done

HOME="$test_root/home" \
XDG_CONFIG_HOME="$test_root/home/.config" \
PATH="$test_root/bin:$PATH" \
  "$project_dir/install.sh" --install-only

test -x "$test_root/home/.local/bin/spiceflow"
test -x "$test_root/home/.config/spicetify/spiceflow/doctor.sh"
test -f "$test_root/home/.config/spicetify/spiceflow/server.js"
test -f "$test_root/home/.config/spicetify/Extensions/spiceflow.js"
test -f "$test_root/home/.config/systemd/user/spiceflow.service"
test -f "$test_root/home/.config/spicetify/Themes/Comfy/color.ini.spiceflow-base"

printf 'Spiceflow install-only test passed\n'
