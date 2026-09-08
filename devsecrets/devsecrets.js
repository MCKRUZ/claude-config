/**
 * Zero-dependency secret vault access for Node, backed by Windows Credential Manager.
 *
 * Reads/writes the SAME entries as DevSecrets.psm1 (PowerShell) and devsecrets.py (Python)
 * by delegating to the PowerShell module — GENERIC credential "DevSecret:<NAME>", DPAPI,
 * per-user, not roamed, not OneDrive-synced. No native addon (no keytar) required.
 *
 * Library use:
 *   const { getSecret, setSecret, deleteSecret, listSecrets } = require('C:/Users/kruz7/.devsecrets/devsecrets.js');
 *   const key = getSecret('OPENROUTER_API_KEY'); // null if missing
 *
 * CLI use:
 *   node devsecrets.js get  OPENROUTER_API_KEY
 *   node devsecrets.js set  OPENROUTER_API_KEY <value>
 *   node devsecrets.js del  OPENROUTER_API_KEY
 *   node devsecrets.js list
 */
"use strict";
const { execFileSync } = require("child_process");
const path = require("path");

const MODULE = path.join(__dirname, "DevSecrets.psm1");
const NAME_RE = /^[A-Za-z0-9_.-]+$/;

function assertName(name) {
  if (!NAME_RE.test(name)) throw new Error(`Invalid secret name: ${name}`);
}

function ps(command) {
  return execFileSync(
    "powershell",
    [
      "-NoProfile",
      "-ExecutionPolicy",
      "Bypass",
      "-Command",
      `Import-Module '${MODULE}' -Force; ${command}`,
    ],
    { encoding: "utf8", windowsHide: true },
  );
}

function getSecret(name) {
  assertName(name);
  const out = ps(
    `$v = Get-DevSecret -Name '${name}'; if ($null -ne $v) { [Console]::Out.Write($v) }`,
  );
  return out.length ? out : null;
}

function setSecret(name, value) {
  assertName(name);
  if (typeof value !== "string" || value.length === 0)
    throw new Error("Empty secret; nothing stored.");
  // Pass the value via a base64 arg so it never appears verbatim on the command line / process list.
  const b64 = Buffer.from(value, "utf8").toString("base64");
  ps(
    `$plain = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('${b64}')); ` +
      `Set-DevSecret -Name '${name}' -Secret $plain | Out-Null`,
  );
}

function deleteSecret(name) {
  assertName(name);
  const out = ps(`Remove-DevSecret -Name '${name}'`);
  return /Removed/.test(out);
}

function listSecrets() {
  const out = ps(`Get-DevSecretNames`);
  return out
    .split(/\r?\n/)
    .map((s) => s.trim())
    .filter(Boolean);
}

module.exports = { getSecret, setSecret, deleteSecret, listSecrets };

if (require.main === module) {
  const [cmd, name, value] = process.argv.slice(2);
  try {
    if (cmd === "get") {
      const v = getSecret(name);
      if (v === null) {
        console.error(`(not found: ${name})`);
        process.exit(1);
      }
      process.stdout.write(v);
    } else if (cmd === "set") {
      if (!value) {
        console.error("usage: node devsecrets.js set NAME VALUE");
        process.exit(2);
      }
      setSecret(name, value);
      console.log(`Stored DevSecret:${name} (${value.length} chars)`);
    } else if (cmd === "del" || cmd === "delete" || cmd === "rm") {
      console.log(deleteSecret(name) ? "Removed" : "Not found");
    } else if (cmd === "list" || cmd === "ls") {
      listSecrets().forEach((n) => console.log(n));
    } else {
      console.log(
        require("fs")
          .readFileSync(__filename, "utf8")
          .split("*/")[0]
          .replace("/**", "")
          .trim(),
      );
      process.exit(2);
    }
  } catch (e) {
    console.error(String(e.message || e));
    process.exit(1);
  }
}
