// SPDX-License-Identifier: GPL-3.0-or-later
// Spiceflow: repaint Spicetify from Ryoku's wallpaper palette without reloads.
(function spiceflow() {
  if (window.__spiceflow) return;
  window.__spiceflow = true;

  const endpoint = "http://127.0.0.1:47616/colors.json";
  const roles = {
    text: "onSurface",
    subtext: "onSurfaceVariant",
    main: "background",
    "main-elevated": "surfaceContainer",
    "main-transition": "surface",
    highlight: "surfaceContainerHigh",
    "highlight-elevated": "surfaceContainerHighest",
    sidebar: "surfaceContainerLow",
    player: "background",
    card: "surfaceContainer",
    shadow: "shadow",
    "selected-row": "onSurface",
    button: "primary",
    "button-active": "primaryContainer",
    "button-disabled": "outlineVariant",
    "tab-active": "surfaceContainerHigh",
    notification: "tertiary",
    "notification-error": "error",
    misc: "surfaceVariant",
    "play-button": "primary",
    "play-button-active": "primaryContainer",
    "progress-fg": "secondary",
    "progress-bg": "surfaceVariant",
    heart: "error",
    "pagelink-active": "tertiary",
    "radio-btn-active": "primary",
  };

  let last = "";
  const rgb = (hex) => [1, 3, 5]
    .map((offset) => parseInt(hex.slice(offset, offset + 2), 16))
    .join(",");

  async function update() {
    try {
      const response = await fetch(`${endpoint}?t=${Date.now()}`, { cache: "no-store" });
      if (!response.ok) return;
      const palette = await response.json();
      const signature = JSON.stringify(palette);
      if (signature === last) return;
      last = signature;
      const style = document.documentElement.style;
      for (const [name, role] of Object.entries(roles)) {
        const color = palette[role];
        if (!/^#[0-9a-f]{6}$/i.test(color || "")) continue;
        style.setProperty(`--spice-${name}`, color);
        style.setProperty(`--spice-rgb-${name}`, rgb(color));
      }
      window.dispatchEvent(new CustomEvent("spiceflow-palette-changed", { detail: palette }));
    } catch (_) {}
  }

  update();
  setInterval(update, 750);
})();
