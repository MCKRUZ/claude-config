#!/usr/bin/env node
// Launches an MCP stdio server with secrets pulled from the DevSecrets vault
// (Windows Credential Manager) at start-up, so no token is ever written to
// .claude.json or any other config file on disk.
//
//   node launch.js --secret NAME [--secret OTHER] -- <command> [args...]
//
// Each --secret NAME is read from the vault and passed to the child process as
// an environment variable of the same name.

const { spawn } = require("child_process");
const { getSecret } = require("C:/Users/kruz7/.devsecrets/devsecrets.js");

const argv = process.argv.slice(2);
const split = argv.indexOf("--");
if (split === -1) {
  console.error('launch.js: missing "--" separator before the server command');
  process.exit(2);
}

const secretNames = [];
for (let i = 0; i < split; i += 1) {
  if (argv[i] === "--secret") {
    const name = argv[i + 1];
    if (!name) {
      console.error("launch.js: --secret requires a vault entry name");
      process.exit(2);
    }
    secretNames.push(name);
    i += 1;
  }
}

const [command, ...args] = argv.slice(split + 1);
if (!command) {
  console.error('launch.js: no server command given after "--"');
  process.exit(2);
}

const env = { ...process.env };
for (const name of secretNames) {
  const value = getSecret(name);
  if (!value) {
    console.error(`launch.js: vault entry "${name}" is empty or missing`);
    process.exit(3);
  }
  env[name] = value;
}

// On Windows, batch-style commands (npx, npm) can only be spawned through a
// shell. Real executables must NOT be, because cmd.exe interposes on the pipes
// and breaks the MCP stdio handshake with EPIPE.
const needsShell =
  process.platform === "win32" && !/\.(exe|com)$/i.test(command);

const child = spawn(command, args, {
  stdio: "inherit",
  env,
  shell: needsShell,
});

child.on("error", (err) => {
  console.error(`launch.js: failed to start "${command}" - ${err.message}`);
  process.exit(4);
});
child.on("exit", (code, signal) => process.exit(signal ? 1 : (code ?? 0)));

for (const sig of ["SIGINT", "SIGTERM"]) {
  process.on(sig, () => child.kill(sig));
}
