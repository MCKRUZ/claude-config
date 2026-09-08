# Infrastructure

## Babylon NAS (Synology)

### SSH Access

```bash
ssh -i ~/.ssh/id_ed25519 Hyriel@bablyon
```

- **Username:** `Hyriel`
- **Host:** `bablyon` (also `192.168.50.9` or `bablyon.synology.me`)
- **Key:** `~/.ssh/id_ed25519` (already in known_hosts, no passphrase prompt)

### Key Paths (NAS)

- Docker configs: `/volume1/docker/`
- OpenClaw stack: `/volume1/docker/openclaw/`
- OpenClaw workspace: `/volume1/docker/openclaw/workspace/`
- Selfies: `/volume1/docker/openclaw/workspace/selfies/`

### Docker (OpenClaw)

- Docker binary: `/usr/local/bin/docker` (not in Hyriel's PATH by default)
- Hyriel has passwordless sudo for docker: `sudo -n /usr/local/bin/docker ...`
- Container name: `openclaw-gateway`
- OpenClaw CLI inside container: `node /app/dist/index.js <command>` (no `openclaw` binary in PATH)
- Compose files live at: `/volume1/docker/openclaw/docker-compose.yml`

**Example commands:**

```bash
# Run openclaw doctor
ssh -i ~/.ssh/id_ed25519 Hyriel@bablyon 'sudo -n /usr/local/bin/docker exec openclaw-gateway sh -c "node /app/dist/index.js doctor --fix"'

# List containers
ssh -i ~/.ssh/id_ed25519 Hyriel@bablyon 'sudo -n /usr/local/bin/docker ps'
```

**Gotchas:**

- `sudo -n` is passwordless **only for `/usr/local/bin/docker`**. Plain `sudo tar`/`sudo cat` prompts for a password and will fail non-interactively. To touch root-owned files on `/volume1`, run a throwaway container instead:
  `sudo -n /usr/local/bin/docker run --rm -v /volume1/docker/<dir>:/x alpine:latest <cmd>`
- The **SFTP subsystem is disabled**, so `scp` fails with `subsystem request failed`. Copy files by piping over SSH:
  `ssh -i ~/.ssh/id_ed25519 Hyriel@bablyon 'cat > /remote/path' < localfile`

### Portainer (Docker management UI)

- **URL:** **`https://bablyon.tail2800e3.ts.net:9443`** — use this. Real Let's Encrypt cert, no browser warning.
  - Must be the **full MagicDNS name**. `https://bablyon:9443` or the LAN IP will throw a name mismatch — the cert's only SAN is `bablyon.tail2800e3.ts.net`.
  - **HTTPS-only.** Port 9000 (cleartext HTTP) is closed and Portainer runs with `--http-disabled`. There is no HTTP fallback by design.
- **TLS:** cert issued by `tailscale cert`, stored in `/volume1/docker/portainer/certs/`, passed via `--sslcert`/`--sslkey`. Renewed automatically by the `portainer-cert-renew` sidecar in the same compose stack (polls every 12h, restarts Portainer only when the cert actually rotates — Portainer reads its cert only at startup).
  - To reissue by hand (needs root, so go through a container):
    `sudo -n /usr/local/bin/docker run --rm -v /var/packages/Tailscale/var/tailscaled.sock:/tailscaled.sock -v /var/packages/Tailscale/target/bin:/ts:ro -v /volume1/docker/portainer/certs:/out alpine:latest /ts/tailscale --socket=/tailscaled.sock cert --cert-file=/out/portainer.crt --key-file=/out/portainer.key bablyon.tail2800e3.ts.net`
- **Stack:** `/volume1/docker/portainer/docker-compose.yml` (compose-managed since 2026-07-12)
- **Data:** `/volume1/docker/portainer/data/` → bind-mounted to `/data`
- **Version:** pinned to `portainer/portainer-ce:2.39.4` (LTS). Deliberately **not** `:latest` — upgrades are an explicit act.
- **Upgrade:** edit the tag in the compose file, then
  `cd /volume1/docker/portainer && sudo -n /usr/local/bin/docker compose pull && sudo -n /usr/local/bin/docker compose up -d`.
  Portainer auto-backs-up its DB to `data/backups/` before migrating; the migration can take ~2-3 min before the API answers.
- **Port 8000 (Edge agent tunnel) is intentionally not published** — no edge agents are registered. Leaving it open just drew daily `chisel-v3` probe noise into the logs.
- **Note:** Portainer mounts `/var/run/docker.sock`, so its admin login is root-equivalent on the NAS. Prefer the HTTPS endpoint.
- **Avast (Windows):** Avast Web/Mail Shield MITM-intercepts TLS on FURIOUS. It re-signs with a root Windows trusts, so it works **as long as the upstream cert is valid** — it only failed while Portainer served a self-signed cert. If HTTPS ever breaks on Windows but works from the Mac Mini, suspect an expired/invalid upstream cert, not Avast itself.

## Mac Mini

> **Always address the Mac Mini by its stable Tailscale MagicDNS name**, never a LAN IP. The
> DHCP lease churns (`.189` → `.103` → `.104` → `.189`…), which repeatedly breaks hardcoded configs.
> Tailscale name: `matthews-mac-mini.tail2800e3.ts.net` (Tailscale IP `100.113.210.70`).

### SSH Access

```bash
ssh matthewkruczek@matthews-mac-mini.tail2800e3.ts.net
```

- **Username:** `matthewkruczek`
- **Host:** `matthews-mac-mini.tail2800e3.ts.net` (Tailscale; resolves from any tailnet device)
- **Note:** the LAN IP (`192.168.50.x`, currently `.189`) is not reachable from Windows/FURIOUS and churns — use the Tailscale name.

### Bifrost MCP Gateway — RETIRED 2026-08-06

Its eleven MCP servers were migrated to run locally on Windows. See `~/.claude/rules/mcp-servers.md`.

- **Container:** stopped, not removed. `~/bifrost/` on the Mini still holds `docker-compose.yml`, `.env`, and `data/config.db` (its config lives in SQLite, not the `config.json` this file used to claim).
- **Restart if ever needed:** `ssh matthewkruczek@matthews-mac-mini.tail2800e3.ts.net '/usr/local/bin/docker start bifrost'`
- **Do not re-point Claude Code at it** without first removing the local server registrations, or tools will be duplicated.

### MCP-related services still on the Mini

- **searxng-mcp** — port 3080, container `searxng-mcp`. Claude Code now connects to this **directly** at `http://matthews-mac-mini.tail2800e3.ts.net:3080/mcp`. Independent of Bifrost; do not stop it.
- **searxng** — port 8888, the search engine behind the above.

### Firecrawl (on the NAS, not the Mini)

- **Engine:** `http://bablyon:3002` — the local `firecrawl` MCP server points here.
- **Broken as of 2026-08-06:** returns `SCRAPE_TIMEOUT` even for `example.com`. API root responds fine, so the service is up but its scrape pipeline is not completing. Historical success rate through Bifrost was 19%.

### Network

- **Mac Mini:** `matthews-mac-mini.tail2800e3.ts.net` (Tailscale) — LAN IP churns, do not hardcode
- NAS (bablyon): `192.168.50.9` (also `bablyon.synology.me`)
- Windows/ComfyUI machine (FURIOUS): `192.168.50.47`
