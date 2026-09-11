# mad-ticket-progress

On-request progress comments on a tracker ticket (Jira, GitHub Issues, or
GitLab Issues). Agent instructions live in [`SKILL.md`](SKILL.md).

Stay generic — no org or project hard-coding.

## When

The user asks to record ticket **progress**, **status**, or a **handoff** in a
comment. Chat-only "where are we" stays in chat.

## What a comment looks like

1. `## Progress update (YYYY-MM-DD)`
2. A **fenced / `codeBlock`** slice-bar visualization (primary status view)
3. Short sections as needed: What landed, Releases / MRs, Next, Known gaps

```
[██████████] Slice 1 — API          DONE (verified)
[████░░░░░░] Slice 2 — UI           IN PROGRESS
[░░░░░░░░░░] Slice 3 — Docs         NOT STARTED
```

Each update is a **new** comment. Edit only to repair the one just posted.

## Hosts

| Host | Write path |
|------|------------|
| Jira | REST ADF comment — [`mad-jira-tickets`](../mad-jira-tickets/SKILL.md) |
| GitHub | `gh issue comment` (Markdown, same fenced bars) |
| GitLab | Issue note (Markdown; no bare `!N` / `#N` cross-project) |
| Other | Ask once; do not guess |

Links use [`mad-visible-links`](../mad-visible-links/SKILL.md).
