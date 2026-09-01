const assert = require("assert");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawn } = require("child_process");

const root = path.resolve(__dirname, "..");
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), "spiceflow-pywal-test-"));
const config = path.join(temporary, "config");
const cache = path.join(temporary, "cache");
const comfy = path.join(config, "spicetify", "Themes", "Comfy");
const wal = path.join(cache, "wal");
const port = 48717;

fs.mkdirSync(comfy, { recursive: true });
fs.mkdirSync(wal, { recursive: true });
fs.writeFileSync(path.join(comfy, "color.ini.spiceflow-base"), [
  "[Comfy]",
  "main = 111111",
  "",
  "[wal16]",
  "main = ${xrdb:color0}",
  "button = ${xrdb:color6}",
  "",
].join("\n"));
fs.writeFileSync(path.join(comfy, "color.ini"), "placeholder\n");

const colors = {};
for (let number = 0; number < 16; number++) {
  colors[`color${number}`] = `#${number.toString(16).repeat(6)}`;
}
colors.color0 = "#101010";
colors.color6 = "#66aaff";
colors.color15 = "#eeeeee";
const pywal = {
  special: { background: "#121212", foreground: "#f0f0f0", cursor: "#f0f0f0" },
  colors,
};
fs.writeFileSync(path.join(wal, "colors.json"), JSON.stringify(pywal));

const child = spawn(process.execPath, [path.join(root, "src", "server.js")], {
  env: {
    ...process.env,
    HOME: temporary,
    XDG_CONFIG_HOME: config,
    XDG_CACHE_HOME: cache,
    SPICEFLOW_PORT: String(port),
    SPICEFLOW_PALETTE: "auto",
  },
  stdio: ["ignore", "pipe", "inherit"],
});

async function run() {
  try {
    await new Promise((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error("server did not start")), 5000);
      child.stdout.on("data", (data) => {
        if (!data.toString().includes("(pywal)")) return;
        clearTimeout(timeout);
        resolve();
      });
      child.once("exit", (code) => reject(new Error(`server exited ${code}`)));
    });

    const response = await fetch(`http://127.0.0.1:${port}/colors.json?t=test`);
    assert.equal(response.status, 200);
    const normalized = await response.json();
    assert.equal(normalized.background, "#121212");
    assert.equal(normalized.onSurface, "#f0f0f0");
    assert.equal(normalized.primary, "#66aaff");

    const rendered = fs.readFileSync(path.join(comfy, "color.ini"), "utf8");
    assert.match(rendered, /main\s+= #121212/);
    assert.match(rendered, /button\s+= #66aaff/);
    assert.doesNotMatch(rendered, /xrdb/);
    process.stdout.write("Spiceflow Pywal test passed\n");
  } finally {
    child.kill("SIGTERM");
    fs.rmSync(temporary, { recursive: true, force: true });
  }
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
