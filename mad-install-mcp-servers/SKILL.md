---
name: mad-install-mcp-servers
description: >-
  Install GitHub, GitLab, Atlassian (Jira/Confluence), and Notion into the
  user MCP config for Cursor (~/.cursor/mcp.json), Claude Desktop
  (claude_desktop_config.json), Hermes Agent (~/.hermes/config.yaml),
  VS Code (user mcp.json), and/or Warp (~/.warp/.mcp.json), verify required
  env vars and CLI tools, then verify connectivity (mad-check-connections).
  Use when the user asks to install MCP servers, set up favourite MCPs,
  fix missing GitHub/GitLab/Jira/Notion MCP, Hermes MCP, VS Code MCP,
  Warp MCP, or run mad-install-mcp-servers.
---

# Install MCP servers

Ensure the four preferred MCP servers are present in the **user-global** MCP
config for the chosen host(s), then verify connectivity.

When **editing** this skill, read [CONTRACT.md](CONTRACT.md).

## Host selection (always)

Stop and ask the user to choose **one or more** before mutating anything:

- **Cursor** - `~/.cursor/mcp.json` + `CURSOR_*` env vars
- **Claude Desktop** - `claude_desktop_config.json` + `CLAUDE_*` env vars
- **Hermes Agent** - `~/.hermes/config.yaml` (`mcp_servers`) + `HERMES_*` env vars
- **Warp** - `~/.warp/.mcp.json` (preferred) + `WARP_*` env vars; GUI or one-off `--mcp` as fallbacks
- **VS Code** - user `mcp.json` (open via **MCP: Open User Configuration**) + `VSCODE_*` env vars; per-workspace `.vscode/mcp.json` only when the user asks
- **Multiple** - run the full workflow once per host (Cursor -> Claude -> Hermes -> Warp -> VS Code)

Env var sets are **independent**. Do not reuse `CURSOR_*` / `CLAUDE_*` /
`HERMES_*` / `WARP_*` / `VSCODE_*` across hosts; someone may configure each
host separately.

## Target files

| Host | Config path |
|------|-------------|
| Cursor | `~/.cursor/mcp.json` |
| Claude Desktop (macOS) | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Claude Desktop (Windows) | `%APPDATA%\Claude\claude_desktop_config.json` |
| Claude Desktop (Linux) | `~/.config/Claude/claude_desktop_config.json` |
| Hermes Agent | `~/.hermes/config.yaml` (merge under `mcp_servers`) |
| Warp | `~/.warp/.mcp.json` (preferred global). Optional project file: `.warp/.mcp.json` at a repo root only if the user asks. GUI: Settings -> Agents -> MCP servers. One-off: `--mcp PATH` or `--mcp JSON` on `oz agent run` (not persistent). Shared/team MCP entries may sync via Warp account; env vars are not synced and must be set per machine. |
| VS Code | User-profile `mcp.json` (open with **MCP: Open User Configuration**). Top-level key is `servers` (not `mcpServers`); each server needs `"type": "stdio"` (stdio: command + args + env) OR `"type": "http"` (http: url + headers). Per-workspace: `.vscode/mcp.json` at a repo root only if the user asks. GUI: Command Palette -> **MCP: Add Server**. One-off: `code --add-mcp JSON` (not persistent). Shared/team MCP entries may sync via VS Code Settings Sync on other machines; env vars are **not synced** and must be set per machine. |

Hermes secrets prefer `~/.hermes/.env` (resolved by `${env:…}` / `${VAR}`).

Do **not** write project `.cursor/mcp.json` unless the user explicitly asks.
Preserve any existing unrelated server entries.

## Server templates

| Host | Template |
|------|----------|
| Cursor | [mcp.cursor.json](mcp.cursor.json) |
| Claude Desktop | [mcp.claude.json](mcp.claude.json) |
| Hermes Agent | [mcp.hermes.json](mcp.hermes.json) |
| Warp | [mcp.warp.json](mcp.warp.json) |
| VS Code | [mcp.vscode.json](mcp.vscode.json) |

**Read the skill file** for the chosen host and merge its `mcpServers` keys into
the target. Do not invent alternate packages or URLs; do not copy templates from
memory when the skill file is available.

- **Cursor** uses `${env:NAME}` in JSON `mcpServers`.
- **Claude Desktop** uses `${NAME}` (or literal values in `env`) and prefers
  **stdio** `command`/`args`/`env`; GitHub is
  `@modelcontextprotocol/server-github`. Notion may use a remote `url` — if the
  host rejects `url` keys, tell the user to add Notion via Customize → Connectors.
- **Hermes** target is YAML `mcp_servers` (not JSON `mcpServers`). Copy each
  server object from [mcp.hermes.json](mcp.hermes.json) under `mcp_servers:` in
  `~/.hermes/config.yaml`. Hermes accepts `${env:VAR}` and `${VAR}`. Notion uses
  `auth: oauth`. After edits, `/reload-mcp` in Hermes (or restart).
- **Warp** preferred target is JSON `mcpServers` in `~/.warp/.mcp.json` (same
  shape as the Cursor/Claude templates). Warp resolves `${WARP_*}` (same
  `${NAME}` style as Claude, not Cursor's `${env:NAME}`). Warp may require the
  user to approve agent edits to MCP config files.
- **VS Code** preferred target is JSON `servers` in the user-profile `mcp.json`
  (open via **MCP: Open User Configuration**). Top-level key is `servers`, not
  `mcpServers`; each server needs `"type": "stdio"` (stdio: command + args +
  env) or `"type": "http"` (http: url + headers). VS Code resolves
  `${env:VSCODE_*}` (same `${env:NAME}` style as Cursor, not Claude's `${NAME}`).
  VS Code may prompt the user to approve the config change — wait for that when
  it appears.

If `GITLAB_URL` in the skill template should not be `https://gitlab.com`, ask
once and use the user's value for that field only.

### Warp (`WARP_*`)

Persistent install paths (prefer in this order):

1. **File (preferred):** Merge into `~/.warp/.mcp.json` from
   [mcp.warp.json](mcp.warp.json). Create `{\"mcpServers\": {}}` if missing.
   Preserve unrelated keys. Warp may prompt the user to approve the config
   change — wait for that when it appears. Built-in Warp `/agent-add-mcp` is an
   acceptable alternative that writes the same global (or project) file.
2. **GUI (fallback):** Settings -> Agents -> MCP servers -> Add. Instruct the
   user to paste each server's JSON block, or the whole `mcpServers` object.
3. **Run-time (one-off only):** Not a substitute for install. For a temporary
   probe, pass an **absolute** template path:

   ```bash
   oz agent run --mcp \"$SKILL_DIR/mcp.warp.json\" --prompt \"list open issues\"
   ```

Do **not** treat one-off `--mcp` as a durable install (file and GUI paths are
durable). Do **not** write a project `.warp/.mcp.json` unless the user
explicitly asks for project-scoped servers.

Warp resolves `${WARP_*}` from the **process environment** of the Warp app
(shell profile / login env on macOS — prefer `~/.zshenv`). Shared/team MCP
entries may sync via Warp account, but **env vars are not synced**; set
`WARP_*` per machine.

### VS Code (`VSCODE_*`)

Persistent install paths (prefer in this order):

1. **File (preferred):** Merge into the user-profile `mcp.json` from
   [mcp.vscode.json](mcp.vscode.json). Open the file with **MCP: Open User
   Configuration** (Command Palette). Create `{\"servers\": {}}` if missing.
   Preserve unrelated keys. VS Code may prompt the user to approve the config
   change — wait for that when it appears.
2. **GUI (fallback):** Command Palette -> **MCP: Add Server**. Instruct the user
   to paste each server's JSON block, or the whole `servers` object.
3. **Run-time (one-off only):** Not a substitute for install. For a temporary
   probe, pass a JSON server config:

   ```bash
   code --add-mcp '{\"name\":\"github\",\"type\":\"http\",\"url\":\"https://api.githubcopilot.com/mcp/\"}'
   ```

Do **not** treat one-off `code --add-mcp` as a durable install (file and GUI
paths are durable). Do **not** write a project `.vscode/mcp.json` unless the
user explicitly asks for project-scoped servers.

VS Code resolves `${env:VSCODE_*}` from the **process environment** of the VS
Code app (shell profile / login env on macOS — prefer `~/.zshenv`). MCP servers
are only available in Copilot **Agent mode**; plain chat or edit modes do not
surface MCP tools.

## Required environment variables

### Cursor (`CURSOR_*`)

Cursor interpolates `${env:NAME}` from the **process environment** of the Cursor
app (shell profile / login env / macOS launch agent — not only the current chat
shell).

| Server | Env vars |
|--------|----------|
| GitHub | `CURSOR_GITHUB_TOKEN` |
| GitLab | `CURSOR_GITLAB_TOKEN` (and `GITLAB_URL` in the server block) |
| Atlassian | `CURSOR_JIRA_URL`, `CURSOR_JIRA_USERNAME`, `CURSOR_JIRA_API_TOKEN`, `CURSOR_CONFLUENCE_URL`, `CURSOR_CONFLUENCE_USERNAME`, `CURSOR_CONFLUENCE_API_TOKEN` |
| Notion | none in JSON (OAuth via `mcp_auth` when needed) |

### Claude Desktop (`CLAUDE_*`)

Claude Desktop does not reliably inherit terminal-only env. Prefer login-shell
exports (`~/.zshenv` on macOS) and fully quit/reopen Claude Desktop after edits.
GUI apps may still need vars set system-wide; the template maps `CLAUDE_*` into
each server's expected names via `${CLAUDE_…}`.

| Server | Env vars |
|--------|----------|
| GitHub | `CLAUDE_GITHUB_TOKEN` |
| GitLab | `CLAUDE_GITLAB_TOKEN` (and `GITLAB_URL` in the server block) |
| Atlassian | `CLAUDE_JIRA_URL`, `CLAUDE_JIRA_USERNAME`, `CLAUDE_JIRA_API_TOKEN`, `CLAUDE_CONFLUENCE_URL`, `CLAUDE_CONFLUENCE_USERNAME`, `CLAUDE_CONFLUENCE_API_TOKEN` |
| Notion | none in JSON (OAuth / Connectors when needed) |

### Hermes Agent (`HERMES_*`)

Hermes resolves `${env:HERMES_…}` from `~/.hermes/.env` (preferred) and the
process environment. Prefer stubs in `~/.hermes/.env` (`NAME=`, no `export`).

| Server | Env vars |
|--------|----------|
| GitHub | `HERMES_GITHUB_TOKEN` |
| GitLab | `HERMES_GITLAB_TOKEN` (and `GITLAB_URL` in the server block) |
| Atlassian | `HERMES_JIRA_URL`, `HERMES_JIRA_USERNAME`, `HERMES_JIRA_API_TOKEN`, `HERMES_CONFLUENCE_URL`, `HERMES_CONFLUENCE_USERNAME`, `HERMES_CONFLUENCE_API_TOKEN` |
| Notion | none in env (OAuth via `auth: oauth` / `hermes mcp login`) |

### Warp (`WARP_*`)

Warp resolves `${WARP_*}` from the **process environment** of the Warp app
(shell profile / login env on macOS — prefer `~/.zshenv`).

| Server | Env vars |
|--------|----------|
| GitHub | `WARP_GITHUB_TOKEN` (HTTP MCP) |
| GitLab | `WARP_GITLAB_TOKEN` (and `GITLAB_URL` in the server block) |
| Atlassian | `WARP_JIRA_URL`, `WARP_JIRA_USERNAME`, `WARP_JIRA_API_TOKEN`, `WARP_CONFLUENCE_URL`, `WARP_CONFLUENCE_USERNAME`, `WARP_CONFLUENCE_API_TOKEN` |
| Notion | none in env (OAuth via Settings -> Agents -> MCP servers when prompted) |

### VS Code (`VSCODE_*`)

VS Code resolves `${env:NAME}` from the **process environment** of the VS Code
app (shell profile / login env on macOS — prefer `~/.zshenv`).

| Server | Env vars |
|--------|----------|
| GitHub | `VSCODE_GITHUB_TOKEN` |
| GitLab | `VSCODE_GITLAB_TOKEN` (and `GITLAB_URL` in the server block) |
| Atlassian | `VSCODE_JIRA_URL`, `VSCODE_JIRA_USERNAME`, `VSCODE_JIRA_API_TOKEN`, `VSCODE_CONFLUENCE_URL`, `VSCODE_CONFLUENCE_USERNAME`, `VSCODE_CONFLUENCE_API_TOKEN` |
| Notion | none in JSON (OAuth via `auth: oauth` when needed) |

## Required CLIs

| Server / host | CLI |
|---------------|-----|
| GitLab | `npx` (Node.js) |
| Atlassian | `uvx` (Astral uv) |
| GitHub (Cursor / Warp / VS Code) | none (HTTP MCP) |
| GitHub (Claude / Hermes) | `npx` (stdio `@modelcontextprotocol/server-github`) |
| Notion | none (HTTP / OAuth) |
| Warp optional CLI probes | `oz` if present (`oz mcp list` / `oz agent run`); not required for install or verify |
| VS Code optional CLI probes | `code` if present (`code --list-extensions`); not required for install or verify |

## Scripts

Resolve this skill directory (repo, `~/.cursor/skills/Mad-Skills/mad-install-mcp-servers`,
Warp/agents per-skill link, or a released zip unpack). **Execute** the script; do
not re-implement its logic.

```bash
SCRIPT=\"$SKILL_DIR/scripts/ensure-env-exports.sh\"
HOST=cursor   # or claude | hermes | warp | vscode
```

| Command | Purpose |
|---------|---------|
| `\"$SCRIPT\" --host \"$HOST\" status` | `set` / `MISSING` per var (never prints values) + `missing_count` |
| `\"$SCRIPT\" --host \"$HOST\" suggest` | recommended path + candidates |
| `\"$SCRIPT\" --host \"$HOST\" append --file PATH [--dry-run]` | append empty stubs for missing undeclared vars |

## Workflow

For **each** chosen host:

1. **Read** the host template ([mcp.cursor.json](mcp.cursor.json),
   [mcp.claude.json](mcp.claude.json), [mcp.hermes.json](mcp.hermes.json),
   [mcp.warp.json](mcp.warp.json), or [mcp.vscode.json](mcp.vscode.json))
   and the host target config. If the target is missing:
   - Cursor/Claude/Warp/VS Code → start from `{\"mcpServers\": {}}` (Cursor,
     Claude, Warp) or `{\"servers\": {}}` (VS Code).
   - Hermes → create `~/.hermes/config.yaml` with `mcp_servers: {}` (or add
     `mcp_servers` beside existing Hermes keys; do not wipe the rest of the file).
2. **Diff** each key under `mcpServers` (or `servers` for VS Code) in the skill
   template against the target. For Warp, the target is `~/.warp/.mcp.json`
   (or, if the user is GUI-only, confirm presence via Settings -> Agents -> MCP
   servers before treating a key as already present; `oz mcp list` only covers
   account/Drive servers). For VS Code, the target is the user-profile
   `mcp.json` (open via **MCP: Open User Configuration**); if the user is
   GUI-only, confirm presence via Settings before treating a key as already
   present. `mcp.vscode.json` template servers use `"type": "stdio"` or
   `"type": "http"`.
   - **Missing** in the target → add that key's object from the skill template
     (Hermes: under YAML `mcp_servers`).
   - **Already present** → leave untouched; note `already present`.
   - **Overwrite** — only if the user **directly asked** to update/replace/reset
     that server (or all four). Then replace that key from the skill template
     (keep unrelated servers). Note `updated`.
3. **Write** the **target** config when any key was added or explicitly updated.
   Cursor/Claude/Warp/VS Code: valid JSON, 2-space indent (`~/.warp/.mcp.json`
   for Warp; user-profile `mcp.json` for VS Code). Hermes: valid YAML under
   `mcp_servers`. Never overwrite the skill templates. For Warp, if the host
   prompts for approval of the MCP config edit, tell the user to accept it. For
   VS Code, if the host prompts the user to approve the config change, wait for
   that when it appears.
4. **Check CLIs** with `command -v npx` and `command -v uvx`. If either is
   missing, tell the user how to install (Node for `npx`,
   [uv](https://github.com/astral-sh/uv) for `uvx`) before expecting
   GitLab/Atlassian (and Claude/Hermes GitHub) to work. Warp file/GUI install
   and Settings confirmation do not require `oz`; skip optional `oz` CLI probes
   when it is absent. VS Code file/GUI install does not require `code`; skip
   optional `code` CLI probes when it is absent.
5. **Check env vars** via the script (not a hand-rolled loop):

```bash
\"$SCRIPT\" --host \"$HOST\" status
\"$SCRIPT\" --host \"$HOST\" suggest
```

### When `missing_count` > 0

Actively help the user plant stubs — do not only paste a list of names.

1. From `suggest`, propose the **recommended** file (`~/.hermes/.env` for Hermes;
   e.g. `~/.zshenv` on zsh for Cursor / Claude / Warp / VS Code) and list
   **candidates**.
2. **Prompt the user to pick a file** (recommended default, another candidate,
   or a custom path). Wait for their choice before writing.
3. Optional: `\"$SCRIPT\" --host \"$HOST\" append --file PATH --dry-run`.
4. Run: `\"$SCRIPT\" --host \"$HOST\" append --file PATH` (needs write access
   outside the repo; expand `~`).
5. Tell the user to fill the empty values and save before the reload step
   below.

If `missing_count` is 0, skip prompting and append.

### Reload and verify (always)

These steps run for every chosen host, whether or not env stubs were appended.

6. **Reload**: tell the user to reload MCP / restart the host if servers or env
   were added or changed:
   - Cursor / Claude Desktop → fully quit and reopen
   - Hermes → `/reload-mcp` or restart Hermes Agent
   - Warp → after **env** (`WARP_*`) changes, fully quit and reopen Warp so the
     app process picks up new exports. After **file-only** merges into
     `~/.warp/.mcp.json`, Warp usually auto-detects the change — confirm by
     reading the file and/or Settings -> Agents -> MCP servers (entries often
     labeled as detected from Warp). Do **not** treat `oz mcp list` as proof of
     a file install: that command lists account/Drive MCP UUIDs and may omit
     `~/.warp/.mcp.json` keys. Use `oz mcp list` only as an optional extra when
     checking shared/account servers.
   - VS Code → after **env** (`VSCODE_*`) changes, fully quit and reopen VS Code
     (or run **Developer: Reload Window**) so the app process picks up new
     exports. After **file-only** merges into the user-profile `mcp.json`, VS
     Code usually auto-detects the change — confirm by reading the file and/or
     running **MCP: List Servers** from the Command Palette. Switch Copilot
     Chat to **Agent mode** to surface MCP tools.
7. **Verify**: follow **mad-check-connections** for the **same host** and emit
   its report (Cursor probes, Claude/Hermes/Warp/VS Code observed evidence as
   that skill describes). Do not invent Cursor MCP probes for Hermes, Warp, or
   VS Code.

## Short install report

Before verification, print a brief install summary per host:

```markdown
# MCP install (<Cursor|Claude Desktop|Hermes Agent|Warp|VS Code>)

| Server key | Config | Env / CLI |
|------------|--------|-----------|
| github | added / already present / updated | <HOST>_GITHUB_TOKEN set|MISSING |
| gitlab | … | token + npx |
| mcp-atlassian | … | jira/confluence vars + uvx |
| notion | … | OAuth when prompted |
```

Include env-file action when relevant: `env stubs appended → ~/.hermes/.env` or
`env ok (no stubs)`.

`updated` only when the user directly asked to overwrite that entry.

Then run verification for that host via **mad-check-connections**.

## Do not

- Overwrite an existing server key on a normal install (missing-only); do
  overwrite when the user directly asks
- Overwrite unrelated server entries in the target (including non-MCP Hermes YAML)
- Edit or overwrite this skill's host templates
- Mix `CURSOR_*`, `CLAUDE_*`, `HERMES_*`, `WARP_*`, and `VSCODE_*` sets, or
  assume one host's tokens work for another
- Commit tokens or write raw secrets into files (stubs are empty only; user fills)
- Append env stubs without the user choosing a file path
- Re-implement `ensure-env-exports.sh` logic ad hoc in the agent
- Skip post-install verification
- Invent alternate packages or URLs, or hard-code the template instead of reading
  this skill's host template file
- Treat one-off `oz agent run --mcp` as a durable Warp install, or write a
  project `.warp/.mcp.json` without the user asking
- Treat one-off `code --add-mcp` as a durable VS Code install, or write a
  project `.vscode/mcp.json` without the user asking
