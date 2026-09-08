# DevSecrets — local secret vault

A zero-dependency secret store backed by **Windows Credential Manager**. Secrets are
DPAPI-encrypted by Windows under your user account, stored on **this machine only**
(persist = `LOCAL_MACHINE`) — **not roamed, not OneDrive-synced, never in plaintext on disk**.

Three helpers, one store. All use the identical entry name `DevSecret:<NAME>`, so a secret
set in any language is readable from the other two:

| Language   | File              | How it reaches Credential Manager        |
| ---------- | ----------------- | ---------------------------------------- |
| PowerShell | `DevSecrets.psm1` | native P/Invoke (`advapi32`), no modules |
| Python     | `devsecrets.py`   | native `ctypes`, no `pip install`        |
| Node       | `devsecrets.js`   | shells to the PS module, no `keytar`     |

> Why not Nexus? Nexus is a _memory_ layer that deliberately **scrubs secrets out**
> (`filterSecrets()`) and injects its content into the model's context. A key stored there
> would get piped into prompts — the opposite of a vault.

---

## Usage

### PowerShell

```powershell
Import-Module C:\Users\kruz7\.devsecrets\DevSecrets.psm1
Set-DevSecret -Name YOUTUBE_API_KEY        # prompts securely (no echo, not in history)
Get-DevSecret -Name YOUTUBE_API_KEY        # returns the value
Get-DevSecretNames                         # list all
Remove-DevSecret -Name YOUTUBE_API_KEY
```

To make it always available, add to your profile:

```powershell
Import-Module C:\Users\kruz7\.devsecrets\DevSecrets.psm1
```

### Python

```python
import sys; sys.path.insert(0, r"C:\Users\kruz7\.devsecrets")
from devsecrets import get_secret
HF_TOKEN = get_secret("HUGGINGFACE_TOKEN")   # None if missing
```

CLI: `py C:\Users\kruz7\.devsecrets\devsecrets.py get HUGGINGFACE_TOKEN`

### Node

```js
const { getSecret } = require("C:/Users/kruz7/.devsecrets/devsecrets.js");
const key = getSecret("YOUTUBE_API_KEY"); // null if missing
```

CLI: `node C:\Users\kruz7\.devsecrets\devsecrets.js get YOUTUBE_API_KEY`

---

## The rule

**Never hardcode a secret in a script, profile, doc, or `settings.local.json` again.**
Fetch it at runtime from the vault. If a process genuinely needs an env var, inject it at
launch from the vault instead of storing it in `HKCU\Environment`:

```powershell
$env:YOUTUBE_API_KEY = Get-DevSecret -Name YOUTUBE_API_KEY   # session-only, pulled from vault
```

---

## Migration checklist (run each line AFTER you rotate that key)

Rotation and storage go together: rotate in the provider console, then paste the **new**
value when `Set-DevSecret` prompts. Do **not** store the old, compromised values.

```powershell
Import-Module C:\Users\kruz7\.devsecrets\DevSecrets.psm1

# --- from the failover proxy / profile (item 2) ---
Set-DevSecret -Name OPENROUTER_API_KEY      # only if you still use OpenRouter elsewhere; else skip

# --- from openclaw settings.local.json + youtube-monitor docs (item 3) ---
Set-DevSecret -Name YOUTUBE_API_KEY         # Google/YouTube Data API key
Set-DevSecret -Name HUGGINGFACE_TOKEN       # hf_...
Set-DevSecret -Name DISCORD_BOT_TOKEN       # Discord bot token
Set-DevSecret -Name OPENCLAW_GATEWAY_TOKEN  # gateway/bridge auth token

# --- from global HKCU env vars (item 11) ---
Set-DevSecret -Name OPENAI_API_KEY
Set-DevSecret -Name REDDIT_CLIENT_SECRET
Set-DevSecret -Name SEMGREP_APP_TOKEN
Set-DevSecret -Name SERPAPI_API_KEY
Set-DevSecret -Name LANGFUSE_SECRET_KEY
Set-DevSecret -Name SQL_PASSWORD
Set-DevSecret -Name GEORGIA_LMS_CONNECTION_STRING
Set-DevSecret -Name BRIDGE_TOKEN
```

### Leave OUT of the vault (they already have proper homes)

- **GitHub PATs** → use `gh`'s secure storage (`gh auth login`); stop pasting `ghp_...`.
- **Anthropic keys/OAuth** → managed by Claude Code (`~/.claude/.credentials.json`).
- **LANGFUSE_PUBLIC_KEY** → not a secret (public key), fine as-is.
- **Anything deployed** → Azure Key Vault (your prod standard).

### After migrating, remove the old copies

- Delete the leaked on-disk copies (openclaw docs + `settings.local.json` lines).
- Drop the global env vars once consumers read from the vault:
  `[Environment]::SetEnvironmentVariable('OPENAI_API_KEY', $null, 'User')` (repeat per name).
