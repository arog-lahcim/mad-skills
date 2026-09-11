---
name: mad-git-commit
description: >-
  Create git commits using conventional-commit message rules. Use when
  the user asks to commit, write a commit message, stage and commit, or amend
  a commit message.
---

# Git Commit

Follow [Guidelines for Version Control](https://app.notion.com/p/Guidelines-for-Version-Control-2400f2e73c5b80c18aebf6cc839cc782) for commit messages. Commits (especially those reaching `main`) must match the conventional-commit pattern so semantic release can derive versions.

## Message format

```
type: subject
type(TICKET-123): subject
```

Allowed forms (must match):

```
^(build|ci|docs|feat|fix|perf|refactor|test)(\([A-Z][A-Z0-9]+-\d+\))?: .+
^Merge \w+
^Initial commit$
^Notes added by 'git notes add'$
```

| Part | Rules |
| --- | --- |
| `type` | One of: `build`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `test` |
| `scope` | Jira-style key only: `PROJ-123` (`[A-Z][A-Z0-9]+-\d+`). Wrap in parentheses with no spaces: `feat(ABC-123): …`. **Required** when the current branch name contains a ticket id — extract that id and put it in the scope. Omit scope only when the branch has no ticket id |
| `subject` | Required. Concise summary after `: ` (space required). Prefer imperative mood; match the repo’s existing commit style when one exists |

**Do not** use types outside the list (`chore`, `style`, `revert`, etc.). **Do not** invent free-form scopes (folder names, package names) — scope is only a ticket key, or omit it.

**Create a clean commit on the first attempt.** The commit message must contain only the intended conventional-commit subject and body. Do not record Cursor or any other AI/agent as a co-author or contributor, including trailers such as `Co-authored-by` or `Made-with`.

### Atomic commits (required)

**Prefer the smallest commits that still stand alone.** Each commit should cover one independent change so history stays clear and bisect/review stay useful.

Before staging, group the working tree by **origin of change** — separate concerns, skills, features, or fixes — and commit each group on its own when practical:

| Situation | What to do |
| --- | --- |
| Two unrelated skills / packages / areas changed | **Two commits** — one per area; never squash them into one “batch” message |
| One skill/file has two unrelated edits (e.g. new feature + unrelated typo fix elsewhere in the same file) | Prefer **two commits** if the hunks split cleanly; otherwise one commit and say so in the subject |
| Same logical change touches several files | **One commit** — keep them together |
| User asked to commit everything at once | Still split by independent origin when you can explain each commit; only combine when the changes are one unit |

Do **not** invent a single umbrella subject that hides unrelated work (e.g. one `feat:` covering two skills). Inspect `git diff` per path and ask: “Would a reviewer want these on separate commits?” If yes, split.

When rewriting a mixed commit the user asked to fix (unpushed / amend-safe), reset and re-commit **atomically** rather than leaving the mixed history.

When committing from **Cursor IDE**, ensure **Cursor Settings → Agent → Attribution → Commit Attribution** is disabled. If the environment is known to inject attribution and this cannot be confirmed, stop before committing and ask the user to disable it. Do not create a commit and then amend or rewrite it solely to remove attribution. Skip this Cursor-only check on other hosts.

### Examples

```
feat: add mad-update-skills skill
feat(ABC-123): add new feature
fix(DATA-1284): handle empty Spark input objects
docs: clarify global skills install symlink
refactor(API-90): extract artifact registry client
```

Branch `ABC-123-new-widget` → message must use scope `ABC-123`, e.g. `feat(ABC-123): add new feature`.

### Merge requests into `main`

MR titles into `main` (or `master`) must use the same conventional prefixes as commits: `feat`, `fix`, or `BREAKING CHANGE` - **not** `feature`. GitLab squash merge uses the MR title as the squashed commit message; `feature(...)` does not trigger semantic-release. Branch commits still follow the `type:` forms above.

## Commit workflow

Only commit when the user asks. Never update git config, never `--force` push, never skip hooks unless explicitly requested.

1. In parallel, inspect state:
   - `git status`
   - `git branch --show-current` (or `git status -sb`) — if the branch name matches `[A-Z][A-Z0-9]+-\d+`, that ticket **must** be the message scope
   - `git diff` and `git diff --cached`
   - `git log -5 --oneline` (match message style)
2. Partition changes into atomic commits (see [Atomic commits](#atomic-commits-required)). List each planned commit and its paths before staging. If more than one independent origin is dirty, plan multiple commits — do not stage everything into one.
3. Draft a message per commit that matches the format above. Prefer why/impact in the subject when it still fits one line; keep it short. No agent attribution in the message or trailers.
4. For each atomic unit: stage **only** that unit’s paths/hunks (no secrets: `.env`, credentials, tokens), then commit with a HEREDOC:

```bash
git commit -m "$(cat <<'EOF'
feat(ABC-123): short subject here

EOF
)"
```

5. Repeat step 4 for each remaining atomic unit.
6. Run `git status` after the last commit and confirm success. Verify each new commit’s full message has no agent attribution in subject, body, or trailers (`git log -N --format=%B` for the N commits you just created).
7. **Always print a summary of the created commits** as an ordered list. For each commit, put the short hash and the full subject each in their own monospace (inline code) spans. Use `git log -N --oneline` for the N commits you just created (oldest first or newest first is fine, but keep the list consistent). When splitting into multiple commits, briefly note why after the list.

Summary format (required):

```markdown
1. `abc1234` `type(SCOPE-1): subject here`
2. `def5678` `type: another subject`
```

Examples:

Single commit:

```markdown
1. `45d4438` `ci: log built E2E image details before push`
```

Multiple commits (with partition note):

```markdown
1. `a1b2c3d` `feat(ABC-123): add warmup Kafka producer`
2. `e4f5a6b` `docs(ABC-123): document warmup CI job`

Split because producer code and docs are independent review units.
```

If a pre-commit hook fails, fix the issue and create a **new** commit — do not amend unless the user asked to amend and the amend safety rules below are met.

### Amend (rare)

Use `--amend` only when all are true:

- User explicitly requested amend, **or** the commit succeeded but a hook auto-modified files that must be included
- `HEAD` was created by you in this conversation
- Commit has **not** been pushed

Otherwise create a new commit.
