---
name: mad-check-connections
description: >-
  Probe MCP auth for GitLab, GitHub, Jira, and Notion, verify CLI tools (gh,
  glab, argocd), and emit a simple connection report for Cursor, Claude
  Desktop, Hermes Agent, or Warp. Use when the user asks to check
  connections, test MCP auth, verify integrations or CLIs, diagnose missing
  GitLab/GitHub/Jira/Notion access, or run mad-check-connections.
---

# Check connections

Verify the agent can reach the four required MCP services, that common CLIs
(`gh`, `glab`, `argocd`) are installed and authenticated, and report the result.

If the active host is ambiguous, ask once: **Cursor**, **Claude Desktop**,
**Hermes Agent**, or **Warp**.

## Services under test

| Service | MCP server id (typical) | Probe |
|---------|-------------------------|--------|
| GitHub | `user-github` / `github` | `get_me` |
| GitLab | `user-gitlab` / `gitlab` | `get_current_user` |
| Jira | `user-mcp-atlassian` / `mcp-atlassian` | `jira_get_all_projects` (`include_archived: false`) |
| Notion | `user-notion` / `notion` | `notion-get-users` (`user_id: "self"`) |

### Cursor (agent MCP introspection available)

Resolve the real server id with `GetMcpTools` (pattern search or catalog) before
calling tools. Prefer the smallest whoami-style probe above; do not create, edit,
or delete anything.

### Claude Desktop (no agent-side MCP probe API)

Do **not** invent passing statuses. When running inside Claude Desktop (or when
`GetMcpTools` / `mcp_auth` are unavailable):

1. Confirm preferred servers were merged into `claude_desktop_config.json` (see
   **mad-install-mcp-servers** / [mcp.claude.json](../mad-install-mcp-servers/mcp.claude.json)).
2. Confirm the user fully quit and relaunched Claude Desktop after config/env changes.
3. Report each service as:
   - `⚪ missing` — server key absent from config
   - `💥 error` — config present but user reports load failure / logs show startup errors
   - `🔐 needsAuth` — connector/OAuth still required (Notion, etc.)
   - Otherwise ask the user to trigger a tiny read-only action in chat that would
     use that MCP; only then mark `✅ ok` or `❌ fail` from the observed result
4. Prefer naming expected `CLAUDE_*` env vars when tokens look unset.

### Hermes Agent (no Cursor MCP probe API)

Do **not** invent Cursor-style probes. When the host is Hermes:

1. Confirm preferred servers were merged under `mcp_servers` in
   `~/.hermes/config.yaml` (see **mad-install-mcp-servers** /
   [mcp.hermes.json](../mad-install-mcp-servers/mcp.hermes.json)).
2. Confirm `/reload-mcp` (or Hermes restart) after config/env changes.
3. Confirm `HERMES_*` stubs are filled in `~/.hermes/.env` (or process env) when
   tokens look unset.
4. Report each service as:
   - `⚪ missing` — server key absent from `mcp_servers`
   - `💥 error` — config present but Hermes reports load/connect failure
   - `🔐 needsAuth` — OAuth still required (e.g. Notion:
     `hermes mcp login notion`)
   - Otherwise ask the user to run a tiny read-only MCP action in Hermes; only
     then mark `✅ ok` or `❌ fail` from the observed result

### Warp (no Cursor MCP probe API)

Do **not** invent Cursor-style probes. When the host is Warp:

1. Confirm preferred servers are present in `~/.warp/.mcp.json` (see
   **mad-install-mcp-servers** / [mcp.warp.json](../mad-install-mcp-servers/mcp.warp.json))
   and/or under Settings -> Agents -> MCP servers (file-based entries often show
   as detected from Warp). Optionally note account/Drive servers from
   `oz mcp list` if `oz` is available — that list is **not** required for a
   successful file install and may omit `~/.warp/.mcp.json` keys. Do **not**
   require `oz` for this skill.
2. After **env** (`WARP_*`) changes, confirm the user fully quit and relaunched
   Warp. File-only edits to `~/.warp/.mcp.json` are usually auto-detected; do not
   require a restart solely for JSON merges.
3. Confirm `WARP_*` stubs are filled in the process env (prefer `~/.zshenv` on
   macOS) when tokens look unset.
4. Report each service as:
   - `⚪ missing` — absent from `~/.warp/.mcp.json` and from Settings MCP (and
     not listed by `oz mcp list` if that was checked)
   - `💥 error` — present in config/Settings but Warp reports load failure
   - `🔐 needsAuth` — OAuth still required (e.g. Notion in Settings -> Agents ->
     MCP servers)
   - Otherwise run a tiny read-only check: ask the user to trigger a read-only
     action in the Warp agent against the already-configured server. If `oz` is
     available and `oz mcp list` shows a UUID for that server,
     `oz agent run --mcp <UUID> --prompt "…"` is an optional alternative. Only
     then mark `✅ ok` or `❌ fail` from the observed result. Missing `oz` is
     not an error by itself.

## CLI tools under test

Host-agnostic shell probes. Run in parallel with MCP checks when possible.
Read-only only — do not create, edit, or delete anything via these CLIs.

| CLI | Presence | Probe | Detail on ok |
|-----|----------|-------|--------------|
| `gh` | `command -v gh` | `gh api user --jq .login` | `login=<name>` |
| `glab` | `command -v glab` | `glab api user \| jq -r .username` | `user=<name>` |
| `argocd` | `command -v argocd` | `argocd version --client --short`, then `argocd account get-user-info -o name` | `user=<name>` (include client version in Detail when useful) |

CLI status uses the same render map as MCP (`✅ ok`, `❌ fail`, `⚪ missing`,
`💥 error`). Treat unauthenticated or unreachable CLI auth as `❌ fail`, not
`🔐 needsAuth` (that status is MCP-only here).

- **`⚪ missing`** — binary not on `PATH`
- **`❌ fail`** — binary present but probe failed (not logged in, bad token, no
  Argo CD context/server, permission, or network error)
- **`💥 error`** — binary present but exits abnormally (crash, corrupt install)

`glab` has no `--jq` flag (unlike `gh`); pipe JSON to `jq` instead.

One-line Detail examples for CLI:

- `✅ ok` — `login=octocat`, `user=jdoe`, `user=admin@argocd`
- `❌ fail` — `not logged in`, `401 Unauthorized`, `no current Argo CD context`
- `⚪ missing` — `gh not on PATH`

## Workflow

### Cursor

1. Discover which of the four servers are present and their `serverStatus`.
2. For each MCP service, in parallel when possible:
   - **Missing** — server not in the MCP catalog → `missing`
   - **needsAuth** — call `mcp_auth` for that server once, then re-inspect
   - **error / loading** — record as `error` or wait briefly and re-check once
   - **ready** — call the probe tool; success → `ok`, failure → `fail`
3. In parallel with step 2 when possible, run the **CLI tools under test**
   probes via the shell (`command -v`, then each probe command).
4. Do not retry auth loops. One `mcp_auth` attempt per server max.
5. Emit the report below. Keep it short — no dump of full API payloads or CLI
   stdout.
6. Rename the chat (see **Chat title** — Cursor only).

### Claude Desktop / Hermes Agent / Warp

1. Follow the host-specific probe section above (config / `oz` / observed evidence).
2. Run the **CLI tools under test** probes via the shell (same table as Cursor).
3. Emit the report below. Keep it short — no dump of full API payloads or CLI
   stdout.
4. Do **not** call Cursor `rename_chat` / `cursor-app-control` on these hosts.

## Status values

Always render Status with the literal Unicode emoji and label from this fixed map. Do not use colon-delimited emoji shortcodes because Cursor chat displays them as text.

| Status | Render as | Meaning |
|--------|-----------|---------|
| `ok` | `✅ ok` | Probe succeeded; include a short identity hint (login, display name, or account id) |
| `fail` | `❌ fail` | Server present but probe errored (auth, permission, or API) |
| `needsAuth` | `🔐 needsAuth` | Server requires authentication and is not usable yet |
| `missing` | `⚪ missing` | MCP server not available in this session, or CLI binary not on `PATH` |
| `error` | `💥 error` | Server listed but in error/unavailable state |

## Report format

Use this exact structure (Markdown). Status column must include the emoji from the map above:

```markdown
# Connection report

## MCP

| Service | Status | Detail |
|---------|--------|--------|
| GitHub | ✅ ok | <short detail> |
| GitLab | ❌ fail | <short detail> |
| Jira | 🔐 needsAuth | <short detail> |
| Notion | ⚪ missing | <short detail> |

## CLI

| Tool | Status | Detail |
|------|--------|--------|
| gh | ✅ ok | <short detail> |
| glab | ❌ fail | <short detail> |
| argocd | ⚪ missing | <short detail> |

**Summary:** MCP <N>/4 ok | CLI <M>/3 ok
```

Detail examples:

- `✅ ok` — `login=octocat` or `user=Jane Doe`
- `❌ fail` — one-line error reason (no stack traces)
- `🔐 needsAuth` — `authenticate MCP server`
- `⚪ missing` — MCP: `MCP server not configured — run mad-install-mcp-servers`;
  CLI: `<tool> not on PATH`
- `💥 error` — `serverStatus=error`

Optional one-liner after the table only if something is blocked: what the user should fix (enable MCP, re-auth, check token). No essays.

## Chat title

**Cursor only.** After emitting the report on Cursor, call the `rename_chat` tool
(server `cursor-app-control`) once with a title that encodes the overall status.
On Claude Desktop, Hermes, or Warp, skip chat rename.

- **Overall status is OK** only when all four MCP services and all three CLI
  tools are `ok`.
- **Overall status is FAILED** if any MCP service or CLI tool is `fail`,
  `needsAuth`, `missing`, or `error`.

Use the literal Unicode emoji in the title:

- All ok → `✅ Connections | 7/7 OK`
- Otherwise → `❌ Connections | FAILED <N>/7` (where `<N>` is the count of `ok`
  rows across both tables)

If `rename_chat` fails (e.g. the conversation can't be identified), skip silently — do not retry and do not report it as an error.

## When missing or misconfigured

If any service is `⚪ missing`, or `❌ fail` / `💥 error` looks like absent MCP config or bad server setup (not merely expired auth):

- Point the user to **mad-install-mcp-servers** for the **same host**:
  - Cursor → `~/.cursor/mcp.json` + `CURSOR_*` vars
  - Claude Desktop → `claude_desktop_config.json` + `CLAUDE_*` vars
  - Hermes Agent → `~/.hermes/config.yaml` (`mcp_servers`) + `HERMES_*` vars
    (prefer `~/.hermes/.env`)
  - Warp → `~/.warp/.mcp.json` (confirm file and/or Settings; GUI / one-off
    `--mcp` as fallbacks) + `WARP_*` vars
- For `🔐 needsAuth` alone on Cursor, prefer `mcp_auth` — do not treat that as an install problem.
- For Hermes OAuth (e.g. Notion), prefer `hermes mcp login <server>`.
- For Warp OAuth (e.g. Notion), prefer Settings -> Agents -> MCP servers.
- For token/URL env issues after the server is present, name the host-specific
  vars (`CURSOR_*`, `CLAUDE_*`, `HERMES_*`, or `WARP_*`) rather than inventing
  new ones or crossing hosts.

When a CLI is `⚪ missing` or `❌ fail` due to auth:

- `gh` — install [GitHub CLI](https://cli.github.com/); then `gh auth login`
- `glab` — install [GitLab CLI](https://gitlab.com/gitlab-org/cli); then
  `glab auth login`
- `argocd` — install [Argo CD CLI](https://argo-cd.readthedocs.io/en/stable/user-guide/installation/);
  then `argocd login <server>` (or set context) before re-checking

## Do not

- Skip a listed MCP service or CLI tool
- Write data to any service or CLI target as part of the check
- Invent a passing status without a successful probe (Cursor) or observed
  evidence (Claude Desktop / Hermes Agent / Warp)
- Call Cursor-only rename/MCP introspection tools on Claude / Hermes / Warp
- Expand the report with unrelated diagnostics unless the user asks
