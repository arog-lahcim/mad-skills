---
name: mad-ticket-progress
description: >-
  Use when the user asks to record ticket progress, status, or a handoff
  in a comment on a Jira, GitHub, or GitLab issue.
---

# Ticket progress comment

On request only. Post a **new** dated comment that leads with a monospaced
slice-bar visualization. Do **not** post when the user only asks about
progress in chat.

Stay generic — no org, project, or real ticket hard-coding.

## When not to apply

- Chat-only status ("where are we") — answer in chat
- No ticket identified and one question did not resolve it
- Tiny one-line fix with no progress to record
- User did not ask to write a ticket comment

## Host

1. Explicit URL or key in chat: `PROJ-123` -> Jira; `owner/repo#N` or
   `github.com/.../issues/N` -> GitHub; `gitlab.com/.../issues/N` -> GitLab.
2. Branch / remote / open MR (same host routing as
   [mad-plan-and-ship-ticket](../mad-plan-and-ship-ticket/SKILL.md)).
3. Last progress comment on that ticket (same host).
4. Still unclear -> ask once. Other trackers -> ask; do not guess.

## Workflow

1. Resolve ticket + host.
2. Read the issue, recent progress comments, and the current plan/slices.
3. Post a **new** comment (history). Edit only the comment you just posted
   if re-read shows broken formatting.
4. Submit via the host adapter below.
5. Re-read the comment. If bars, headings, or links broke, fix via the
   adapter. Do not leave a broken visualization.

English unless the user asks otherwise. Links:
[mad-visible-links](../mad-visible-links/SKILL.md).

## Required visualization

Immediately under `## Progress update (YYYY-MM-DD)` put a **code block**
(one slice per line). This is the primary status view — not a table, not
an unfenced list, not `#` / `.` substitutes.

```
[██████████] Slice 1 — API          DONE (MR 16, verified)
[████░░░░░░] Slice 2 — UI           IN PROGRESS (owner/repo#42)
[░░░░░░░░░░] Slice 3 — Docs         NOT STARTED
[██░░░░░░░░] Slice 4 — E2E          PARTIAL (happy path only)
```

- Bar width 10: `█` done, `░` remaining
- Labels only: `DONE`, `IN PROGRESS`, `NOT STARTED`, `PARTIAL`
- Jira: ADF `codeBlock` (line numbers on the left are fine)
- GitHub / GitLab: the same fenced code block so columns stay aligned
- After write: if `█` vanished or `_` turned italic, edit the comment

## Rest of the comment

Keep it short. Omit an empty section.

```
### What landed
- ...

### Releases / MRs
- title https://example.com/group/repo/-/merge_requests/16

### Next
- one concrete step

### Known gaps
- only work left outside this ticket
```

## Adapters

### Jira

Hand write mechanics to [mad-jira-tickets](../mad-jira-tickets/SKILL.md)
**Comments**. REST ADF `POST /rest/api/3/issue/{issueKey}/comment`.
**Do not** use MCP `jira_add_comment` / `jira_edit_comment` for the body.
Slice bars must be a `codeBlock` node, not `paragraph` nodes.

### GitHub

```bash
gh issue comment 42 --repo owner/repo --body-file -
```

Markdown. Fence the bars. Visible URL, not title-only link text.
Re-read with `gh api` / GitHub MCP. Edit only what you just posted.

### GitLab

`glab issue note` or REST issue notes. Markdown. Fence the bars.
Do **not** use bare `!N` / `#N` for cross-project targets
([mad-visible-links](../mad-visible-links/SKILL.md)).
Re-read notes; edit only what you just posted.

## Checklist

- [ ] User asked for a ticket comment (not chat-only status)
- [ ] Host resolved; other tracker asked, not guessed
- [ ] New dated comment; edit only to repair the one just posted
- [ ] Heading `## Progress update (YYYY-MM-DD)` then fenced/codeBlock bars
- [ ] Status labels from the allowed set only
- [ ] Visible title + URL links
- [ ] Re-read; bars/headings/links intact
