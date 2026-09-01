# Mad Skills

Personal [Agent Skills](https://agentskills.io) for **Cursor**, **Claude Desktop**
(also uploadable to Claude cloud Skills), **Hermes Agent**, **Warp**, and **VS Code**.
Workflows stay generic; install paths and MCP config differ by host.

## Install with an agent

Paste this prompt into a new agent chat (Cursor, Claude, Hermes, or Warp):

```text
Install Mad Skills from https://github.com/arog-lahcim/mad-skills — fetch
https://raw.githubusercontent.com/arog-lahcim/mad-skills/main/INSTALL.md and
follow it interactively.
```

The agent loads and follows [INSTALL.md](INSTALL.md) (interactive: host choice,
skills install, and/or MCP).

## Agent Skills catalogs

Several hosts load skills from **catalog directories**. In that layout each skill is
one folder (not nested under a `Mad-Skills/` repo folder):

```text
<catalog>/<skill-name>/SKILL.md
```

Common catalogs (a host may scan more than one):

| Directory | Typical use |
|-----------|-------------|
| `~/.agents/skills/` | Shared across tools that use the Agent Skills home layout |
| `~/.warp/skills/` | Warp-dedicated |
| `~/.claude/skills/`, `~/.codex/skills/`, `~/.cursor/skills/`, `~/.copilot/skills/`, `~/.factory/skills/`, `~/.gemini/skills/`, `~/.github/skills/`, `~/.opencode/skills/` | Other tool-specific catalogs with the same per-skill shape |

From this repo, link each `mad-*/` skill folder into a chosen catalog with
`scripts/link-skills.sh` (idempotent; re-running replaces existing symlinks; only
`mad-*` dirs with a `SKILL.md` are linked).

```bash
cd /path/to/Mad-Skills
./scripts/link-skills.sh --target ~/.warp/skills
# or: ./scripts/link-skills.sh --target ~/.agents/skills
# dry-run: ./scripts/link-skills.sh --target ~/.warp/skills --dry-run
# additional repo: ./scripts/link-skills.sh --target ~/.warp/skills \
#   --source /path/to/Other-Skills
```

**Different from Cursor's Mad Skills install:** Cursor can also discover skills via
a whole-repo symlink at `~/.cursor/skills/Mad-Skills` (`Mad-Skills/mad-*/SKILL.md`).
That is **not** the catalog shape above. Per-skill entries under
`~/.cursor/skills/<skill-name>/` *are* catalog-shaped; the `Mad-Skills` folder
symlink is not. See **Cursor** and **Warp** below.

### Overlap / duplicates

If the same skill folder is visible under two catalogs a host scans, that host
lists it twice. Cursor can see both:

- `~/.cursor/skills/Mad-Skills/mad-*` (repo-folder install), and
- `~/.agents/skills/mad-*` or `~/.cursor/skills/mad-*` (catalog install)

Prefer one path per host. With Cursor's `Mad-Skills` symlink plus Warp, put Warp
links under `~/.warp/skills/` — not into `~/.agents/skills/` or per-skill
`~/.cursor/skills/mad-*`.

## Warp (manual)

1. Clone this repo if needed.
2. Link into a catalog Warp scans (see **Agent Skills catalogs**). Prefer
   `~/.warp/skills/`. Use `~/.agents/skills/` when sharing one tree with other
   non-Cursor hosts and you are **not** also using Cursor's `Mad-Skills` folder
   symlink.
3. Fully quit and reopen Warp, then confirm with `oz agent skills` (or ask the
   Warp agent what skills it sees). Do not use `oz agent list` for this check —
   that lists named/cloud agents, not skill folders.

## VS Code (manual)

VS Code ships native MCP support (Copilot **Agent mode**). It does **not**
load Agent Skills catalogs — only Cursor/Claude/Hermes/Warp do.

1. Install Mad Skills somewhere on disk (clone or existing checkout).
2. Open the user-profile `mcp.json` via **MCP: Open User Configuration**
   (Command Palette). Top-level key is `servers`, not `mcpServers`; each
   server needs `"type": "stdio"` (command + args + env) or `"type": "http"`
   (url + headers).
3. Merge from `mad-install-mcp-servers/mcp.vscode.json`. Set `VSCODE_*` env
   vars in `~/.zshenv` (macOS), then fully quit/reopen VS Code (or run
   **Developer: Reload Window**).
4. Confirm with **MCP: List Servers** (Command Palette). Switch Copilot
   Chat to **Agent mode** to surface MCP tools.

## Cursor (manual)

Cursor's recommended Mad Skills install is a **whole-repo** symlink (not one link
per skill):

```bash
mkdir -p ~/.cursor/skills
ln -s /path/to/Mad-Skills ~/.cursor/skills/Mad-Skills
```

Reload Cursor, then check **Customize → Skills** (user scope).

Do not also install the same `mad-*` skills into `~/.agents/skills/` or as
per-skill `~/.cursor/skills/mad-*` while this symlink exists (see **Overlap /
duplicates**). Do not replace the `Mad-Skills` folder symlink with per-skill links
under `~/.cursor/skills/` unless you intentionally want the catalog layout instead.

## Claude Desktop / cloud (manual)

1. Open the latest [GitHub Release](https://github.com/arog-lahcim/mad-skills/releases).
2. Download individual `mad-*.zip` files, or `mad-skills-all.zip` and unpack.
3. In Claude: **Customize → Skills** → upload each skill zip (folder must contain
   `SKILL.md`). Enable **code execution** if Skills are greyed out.

## Hermes Agent (manual)

1. Clone this repo (e.g. `~/Mad-Skills`) if needed.
2. Add the absolute clone path under `skills.external_dirs` in
   `~/.hermes/config.yaml` (preserve other Hermes keys):

```yaml
skills:
  external_dirs:
    - /absolute/path/to/Mad-Skills
```

3. Confirm with `hermes skills list` (or `/skills`). Start a new session or
   `/reset` if skills do not appear yet.

## MCP

Ask the agent to run **mad-install-mcp-servers** and choose host:

| Host | Config | Env prefix |
|------|--------|------------|
| Cursor | `~/.cursor/mcp.json` | `CURSOR_*` |
| Claude Desktop | `claude_desktop_config.json` | `CLAUDE_*` |
| Hermes Agent | `~/.hermes/config.yaml` (`mcp_servers`) | `HERMES_*` |
| Warp | `~/.warp/.mcp.json` (GUI / one-off `--mcp` as fallbacks) | `WARP_*` |
| VS Code | user-profile `mcp.json` (**MCP: Open User Configuration**) | `VSCODE_*` |

Prefixes are independent so each app can be configured separately. Hermes
secrets prefer `~/.hermes/.env`. Warp file installs show under Settings ->
Agents -> MCP servers; `oz mcp list` covers account/Drive servers and may omit
keys that exist only in `~/.warp/.mcp.json`.

## Sync

**Cursor** (repo-folder symlink):

```bash
cd ~/.cursor/skills/Mad-Skills && git pull
```

Or ask the agent to run **mad-update-skills**.

**Warp** (catalog symlinks): `git pull` in the Mad-Skills clone; existing
symlinks pick up content updates. Re-run `./scripts/link-skills.sh --target <dir>`
when the pull adds new `mad-*` skill folders. Or ask **mad-update-skills**.

**Hermes Agent** (`external_dirs` clone): `git pull` in that clone, or ask
**mad-update-skills** for host-specific steps.

**Claude Desktop / cloud:** download newer zips from Releases and re-upload/replace
skills (or ask **mad-update-skills** for host-specific steps).

**VS Code:** no Mad Skills clone to sync (VS Code only consumes MCP servers
from `mad-install-mcp-servers/mcp.vscode.json`). After pulling updates to a
local Mad Skills clone, re-run `mad-install-mcp-servers` to refresh the
user-profile `mcp.json`. Reload VS Code (or **Developer: Reload Window**)
and confirm via **MCP: List Servers**.

## Releases

Pushes to `main` run [semantic-release](https://github.com/semantic-release/semantic-release)
and publish a GitHub Release with skill zips when conventional commits warrant a
version bump. Side branches and PRs run `semantic-release --dry-run` (no tag or
assets) to validate config and show the would-be next version.

The released version is kept in git: CI pushes a `chore(release): <version> [skip ci]`
commit with the bumped `package.json` (and lockfile) alongside the `v<version>` tag,
so the tag, the release, and `package.json` never drift apart.
