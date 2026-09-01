const assert = require("assert");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawn } = require("child_process");

const root = path.resolve(__dirname, "..");
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), "spiceflow-test-"));
const config = path.join(temporary, "config");
const cache = path.join(temporary, "cache");
const comfy = path.join(config, "spicetify", "Themes", "Comfy");
const ryoku = path.join(cache, "ryoku");
const port = 48716;

fs.mkdirSync(comfy, { recursive: true });
fs.mkdirSync(ryoku, { recursive: true });
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

const colors = {
  onSurface: "#eeeeee",
  onSurfaceVariant: "#cccccc",
  background: "#101010",
  surfaceContainer: "#202020",
  surface: "#181818",
  surfaceContainerHigh: "#303030",
  surfaceContainerHighest: "#404040",
  surfaceContainerLow: "#151515",
  shadow: "#000000",
  primary: "#80aaff",
  primaryContainer: "#304060",
  outlineVariant: "#505050",
  tertiary: "#c080ff",
  error: "#ff8080",
  surfaceVariant: "#454545",
  secondary: "#80d0c0",
};
fs.writeFileSync(path.join(ryoku, "colors.json"), JSON.stringify(colors));

const child = spawn(process.execPath, [path.join(root, "src", "server.js")], {
  env: {
    ...process.env,
    HOME: temporary,
    XDG_CONFIG_HOME: config,
    XDG_CACHE_HOME: cache,
    SPICEFLOW_PORT: String(port),
  },
  stdio: ["ignore", "pipe", "inherit"],
});

async function run() {
  try {
    await new Promise((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error("server did not start")), 5000);
      child.stdout.on("data", (data) => {
        if (!data.toString().includes("Spiceflow listening")) return;
        clearTimeout(timeout);
        resolve();
      });
      child.once("exit", (code) => reject(new Error(`server exited ${code}`)));
    });

    const response = await fetch(`http://127.0.0.1:${port}/colors.json?t=test`);
    assert.equal(response.status, 200);
    assert.equal(response.headers.get("access-control-allow-private-network"), "true");
    assert.deepEqual(await response.json(), colors);

    const rendered = fs.readFileSync(path.join(comfy, "color.ini"), "utf8");
    assert.match(rendered, /\[Comfy\][\s\S]*main = 111111/);
    assert.match(rendered, /\[wal16\][\s\S]*main\s+= #101010/);
    assert.match(rendered, /button\s+= #80aaff/);
    assert.doesNotMatch(rendered, /xrdb/);
    process.stdout.write("Spiceflow server test passed\n");
  } finally {
    child.kill("SIGTERM");
    fs.rmSync(temporary, { recursive: true, force: true });
  }
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
