# Contract: mad-install-mcp-servers

Stable facts for agents **editing** this skill. Install-time agents follow `SKILL.md` only.

## Scope

- Prefer GitHub, GitLab, Atlassian (`mcp-atlassian`), and Notion only.
- Stay generic: no org-specific hosts, tokens, or project names in templates.
- Five hosts: Cursor (`~/.cursor/mcp.json`), Claude Desktop
  (`claude_desktop_config.json`), Hermes Agent (`~/.hermes/config.yaml` ->
  `mcp_servers`), Warp (`~/.warp/.mcp.json`, optional project
  `.warp/.mcp.json`, GUI Settings -> Agents -> MCP servers, or one-off
  `--mcp`; `WARP_*` env vars), and VS Code (user-profile `mcp.json` opened
  via **MCP: Open User Configuration**; top-level key is `servers`, not
  `mcpServers`; optional project `.vscode/mcp.json`; GUI
  Command Palette -> **MCP: Add Server**; one-off `code --add-mcp JSON`;
  `VSCODE_*` env vars). Project `.cursor/mcp.json` or `.vscode/mcp.json`
  only when the user asks.
- Env prefixes stay independent: `CURSOR_*` vs `CLAUDE_*` vs `HERMES_*` vs
  `WARP_*` vs `VSCODE_*`. Never merge them.

## Sources of truth

| Concern | File |
|---------|------|
| Cursor MCP server templates | [mcp.cursor.json](mcp.cursor.json) |
| Claude Desktop MCP server templates | [mcp.claude.json](mcp.claude.json) |
| Hermes Agent MCP server templates | [mcp.hermes.json](mcp.hermes.json) |
| Warp MCP server templates | [mcp.warp.json](mcp.warp.json) |
| VS Code MCP server templates | [mcp.vscode.json](mcp.vscode.json) |
| Required env var names + stub append behavior | [scripts/ensure-env-exports.sh](scripts/ensure-env-exports.sh) (`CURSOR_VARS` / `CLAUDE_VARS` / `HERMES_VARS` / `WARP_VARS` / `VSCODE_VARS`, `--host`) |
| Install / check / prompt workflow | [SKILL.md](SKILL.md) |
| Connectivity probes — MCP + CLI (`gh`, `glab`, `argocd`; all hosts) | `mad-check-connections` |

When adding or renaming an env var: update the matching `*_VARS` array, the host
template `${…}` / `${env:…}` refs, and the SKILL.md env table together.

When adding or changing a server: edit each host template that should carry it;
do not invent packages or URLs only in prose. Keep hosts in sync on *which*
servers exist, even when shapes differ (HTTP vs stdio, JSON vs Hermes YAML).

Hermes template stays JSON (`mcpServers`) for edit parity; install writes YAML
`mcp_servers` in `~/.hermes/config.yaml`. Hermes secrets prefer stubs in
`~/.hermes/.env`.

Warp preferred persistent target is `~/.warp/.mcp.json` (JSON `mcpServers`,
same shape as Cursor/Claude templates). Warp may require user approval before
an agent edit to that file sticks. GUI paste and built-in `/agent-add-mcp` are
valid alternatives. Run-time `oz agent run --mcp` is one-off only, not the
default install path. Warp templates use `${WARP_*}` (not `${env:…}`).
Warp usually auto-detects `.mcp.json` file changes; require a full quit/reopen
mainly after `WARP_*` env changes. Confirm file installs by reading
`~/.warp/.mcp.json` and/or Settings -> Agents -> MCP servers — do not treat
`oz mcp list` (account/Drive UUIDs) as the sole proof of a file-based install.

## Behavioral invariants

- Do not overwrite an existing target server key unless the user directly asks to update/replace/reset it.
- Preserve unrelated server entries in the target (and non-MCP keys in Hermes YAML).
- Never write secret values into config or env files; stubs are empty only.
- Never append env stubs without the user choosing a file path (`suggest` -> prompt -> `append`).
- Do not edit or overwrite this skill’s templates during an install run.
- Post-install: reload/restart the host as needed (Hermes: `/reload-mcp` or
  restart; Warp: quit/reopen after env changes; confirm file MCP via
  `~/.warp/.mcp.json` / Settings, not `oz mcp list` alone; VS Code: quit/reopen
  after `VSCODE_*` env changes, then reload via **MCP: List Servers** / Developer:
  Reload Window), then all hosts -> **mad-check-connections** (host-specific
  probe rules in that skill). For Hermes/Warp/VS Code OAuth (e.g. Notion),
  complete host login before treating the check as final.

## Related

- Missing / misconfigured MCP in a connection report -> point at this skill (`mad-check-connections`).
