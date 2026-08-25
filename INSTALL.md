# Mad Skills — agent install

One-shot bootstrap for a fresh agent. This is **not** a skill (so it never appears
under Customize → Skills). Follow the workflow interactively, narrate every
mutating step, and do not invent alternate remotes or install layouts.

## Canonical remote

```text
git@github.com:arog-lahcim/Mad-Skills.git
```

Browser / HTTPS URL (docs, Releases): https://github.com/arog-lahcim/Mad-Skills

Prefer **SSH** clone. Use HTTPS (`https://github.com/arog-lahcim/Mad-Skills.git`)
only when the user asks for it, or when SSH to GitHub is unavailable.

## Workflow

### 1. Ask host (always)

Stop and ask the user to choose **one or more**:

- **Cursor**
- **Claude Desktop** (includes Claude cloud Skills upload)
- **Hermes Agent**
- **Warp**
- **VS Code** (user-profile `mcp.json` via **MCP: Open User Configuration**; per-workspace `.vscode/mcp.json` only if the user asks)
- **Multiple** (run skills/MCP steps once per chosen host)

Wait for their answer before mutating anything.

### 2. Ask install scope (always)

Stop and ask the user to choose **one**:

- **Skills only** — install skills for the chosen host(s)
- **Skills + MCP** — skills, then MCP servers
- **MCP only** — skip skills install; run MCP install from an existing clone/tree if available

Wait for their answer before mutating anything.

### 3. Skills path (Skills only or Skills + MCP)

#### Shared clone (Cursor, Hermes, and/or Warp)

**Clone directory**

- Recommend `~/Mad-Skills`.
- If missing or ambiguous, ask once; reuse an existing Mad-Skills git checkout when
  present (same remote / clearly this repo).

**Before cloning or linking**, tell the user the exact paths you will use.

**Clone** (if needed):

```bash
git clone git@github.com:arog-lahcim/Mad-Skills.git ~/Mad-Skills
```

(Adjust destination to the user’s chosen path. Switch to the HTTPS URL only if
the user prefers it or SSH fails.)

#### Agent Skills catalogs

Several hosts load skills from **catalog directories**. In that layout each skill
is one folder (not nested under a `Mad-Skills/` repo folder):

```text
<catalog>/<skill-name>/SKILL.md
```

Common catalogs (a host may scan more than one):

- `~/.agents/skills/` — shared across tools that use the Agent Skills home layout
- `~/.warp/skills/` — Warp-dedicated
- also: `~/.claude/skills/`, `~/.codex/skills/`, `~/.cursor/skills/`,
  `~/.copilot/skills/`, `~/.factory/skills/`, `~/.gemini/skills/`,
  `~/.github/skills/`, `~/.opencode/skills/`

`scripts/link-skills.sh` from the Mad-Skills clone root links each `mad-*/`
skill folder into a chosen catalog (idempotent; re-running replaces existing
symlinks; only directories named `mad-*` with a `SKILL.md` are linked):

```bash
cd /absolute/path/to/Mad-Skills
./scripts/link-skills.sh --target ~/.warp/skills
# or: ./scripts/link-skills.sh --target ~/.agents/skills
# dry-run: ./scripts/link-skills.sh --target ~/.warp/skills --dry-run
# additional repo: ./scripts/link-skills.sh --target ~/.warp/skills \
#   --source /path/to/Other-Skills
```

`scripts/link-skills.sh` safe-checks each target slot:

- existing symlink at the same name → replaced (`ln -sfn`);
- real directory or file at the target → reported as a `conflict` and left
  untouched (the script exits non-zero so the agent can surface the problem);
- missing slot → created as a fresh symlink.

**Conflicts:** if a target slot is not a symlink, stop and ask before replacing.
Do not silently overwrite. After the user confirms, move or remove the
conflicting path (e.g. `mv "$TARGET/mad-foo" "$TARGET/mad-foo.bak"`), then
re-run `./scripts/link-skills.sh --target "$TARGET"`. The script has no
`--force` flag.

**Different from Cursor's Mad Skills install:** Cursor can also discover skills
via a whole-repo symlink at `~/.cursor/skills/Mad-Skills`
(`Mad-Skills/mad-*/SKILL.md`). That is **not** the catalog shape. Per-skill
entries under `~/.cursor/skills/<skill-name>/` *are* catalog-shaped; the
`Mad-Skills` folder symlink is not.

**Overlap / duplicates:** if the same skill is visible under two catalogs a host
scans, that host lists it twice. Cursor can see both
`~/.cursor/skills/Mad-Skills/mad-*` and `~/.agents/skills/mad-*` or
`~/.cursor/skills/mad-*`. Prefer one path per host. With Cursor's `Mad-Skills`
symlink plus Warp, put Warp links under `~/.warp/skills/` — not into
`~/.agents/skills/` or per-skill `~/.cursor/skills/mad-*`.

#### Cursor

**Symlink** the whole clone (Cursor discovers nested `mad-*/SKILL.md` under this
path — not the catalog layout above):

```bash
mkdir -p ~/.cursor/skills
ln -sfn /absolute/path/to/Mad-Skills ~/.cursor/skills/Mad-Skills
```

**Conflicts:** if `~/.cursor/skills/Mad-Skills` already exists and does **not**
resolve to the intended clone, stop and ask before replacing. Do not silently
overwrite.

After linking, confirm with `ls -la ~/.cursor/skills/Mad-Skills` and list skill
dirs (`*/SKILL.md` under the clone). Tell the user to reload Cursor / check
**Customize → Skills** (user scope) if skills were newly linked.

When Cursor is chosen:

- Keep this `Mad-Skills` folder symlink for Cursor.
- Do not also link the same `mad-*` skills into `~/.agents/skills/` or as
  per-skill `~/.cursor/skills/mad-*` (see **Overlap / duplicates** above).
- For Warp alongside Cursor, prefer `~/.warp/skills/` (see Warp below).
- Do not replace the Cursor `Mad-Skills` symlink with per-skill links under
  `~/.cursor/skills/` unless the user explicitly asks.

#### Warp

Do **not** create a Cursor skills symlink for Warp-only installs (unless Cursor
was also chosen). Warp needs the **catalog** layout (see **Agent Skills
catalogs**), not the Cursor `Mad-Skills` folder symlink.

**Ask the user** which catalog to use, based on the host(s) chosen:

- Warp only → suggest `~/.warp/skills/` (Warp-dedicated).
- Warp + Cursor → suggest `~/.warp/skills/` and keep the Cursor `Mad-Skills`
  symlink; do not also link into `~/.agents/skills/` or per-skill
  `~/.cursor/skills/mad-*` (duplication).
- Warp + other non-Cursor hosts (no Cursor) → `~/.agents/skills/` is fine as a
  shared tree.
- Accept any other supported catalog above after stating the duplication risk
  when Cursor's `Mad-Skills` symlink is also present.

Run `scripts/link-skills.sh --target <catalog>` from the clone root (commands and
conflict rules are under **Agent Skills catalogs**).

After linking, confirm with `ls -la "$TARGET"` and list skill dirs
(`mad-*/SKILL.md` under the clone). Tell the user to fully quit and reopen Warp
if skills were newly linked, then confirm with `oz agent skills` (or ask the
Warp agent what skills it sees). Do **not** use `oz agent list` for skills —
that lists named/cloud agents, not skill folders.

#### Hermes Agent

Do **not** create a Cursor skills symlink for Hermes-only installs (unless Cursor
was also chosen).

Prefer **`skills.external_dirs`** so Hermes scans the Mad-Skills clone (each
`mad-*/SKILL.md` child folder is a skill):

1. Ensure the clone exists (shared clone steps above).
2. Read `~/.hermes/config.yaml` (create a minimal file only if missing — never wipe
   unrelated Hermes keys).
3. Under `skills.external_dirs`, add the **absolute** clone path if absent. Example:

```yaml
skills:
  external_dirs:
    - /absolute/path/to/Mad-Skills
```

Preserve any existing `external_dirs` entries. Expand `~` if writing a home-relative path.

4. Confirm with `hermes skills list` (or `/skills`) that Mad Skills names appear.
   New sessions pick up external skills; mention `/reset` if the current session
   still looks stale.

Optional alternative (only if the user asks): copy or symlink individual skill
folders into `~/.hermes/skills/` instead of `external_dirs`.

#### Claude Desktop / cloud

Do **not** create a Cursor skills symlink for Claude-only installs.

Prefer one of:

1. **Release zips** — open the latest GitHub Release for this repo, download
   `mad-*.zip` (or `mad-skills-all.zip` and unpack). Each zip’s root folder must
   contain `SKILL.md`. Guide the user to **Customize → Skills → upload**.
2. **Local checkout** — if a clone already exists (or the user approved cloning
   to e.g. `~/Mad-Skills`), zip each skill dir locally with
   `scripts/package-skill-zips.sh` (or point them at the skill folders) and upload.

Remind the user that Claude Skills need **code execution** enabled when Skills
appear greyed out.

### 4. MCP path (MCP only or Skills + MCP)

Resolve `mad-install-mcp-servers/SKILL.md` from:

- the clone just linked / used, or
- `~/.cursor/skills/Mad-Skills/mad-install-mcp-servers/SKILL.md` if already installed, or
- a Hermes `external_dirs` Mad-Skills clone, or
- a Warp / agents per-skill link (e.g.
  `~/.warp/skills/mad-install-mcp-servers/SKILL.md` or
  `~/.agents/skills/mad-install-mcp-servers/SKILL.md`), or
- the local checkout used for this install

**Read that skill and follow it fully** for the chosen host(s) (merge into the
host config, env stubs, CLIs, then verification). Do not re-implement MCP install
here.

For **MCP only** without any Mad-Skills tree available: clone (or fetch) enough
of the repo to read `mad-install-mcp-servers/`, then follow that skill — ask
before cloning if the user has not already approved a path.

### 5. Final report

Always print this structure (fill in real values; omit MCP/connection sections if
that path was skipped):

```markdown
# Mad Skills install

| Item | Value |
|------|--------|
| Host | Cursor / Claude Desktop / Hermes Agent / Warp / VS Code / Multiple |
| Scope | Skills only / Skills + MCP / MCP only |
| Remote | git@github.com:arog-lahcim/Mad-Skills.git (or HTTPS if the user chose that) |
| Clone | <path or n/a> |
| Warp symlinks | <target>/{mad-*} → <clone path or n/a / unchanged> |
| Cursor symlink | ~/.cursor/skills/Mad-Skills → <target or n/a / unchanged> |
| Hermes external_dirs | <path listed or n/a / unchanged> |
| Claude skills | uploaded from release zips / local zips / n/a |
| VS Code MCP | merged → user-profile mcp.json (or .vscode/mcp.json) ⟪n/a if skipped⟫ |
| Skills | <comma-separated skill folder names, or n/a> |

<If MCP ran: include the MCP install table and connection/verification notes from those skills.>
```

## Do not

- Create a `mad-install` skill or put this guide under a `SKILL.md`
- Skip the host or scope prompt
- Force-replace an existing skills symlink or wipe Hermes `config.yaml` without asking
- Write secrets into files (MCP skill handles empty env stubs only)
- Push, commit, or edit skills as part of install
- Assume `CURSOR_*`, `CLAUDE_*`, `HERMES_*`, and `WARP_*` env vars are interchangeable
