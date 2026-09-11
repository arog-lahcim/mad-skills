---
name: mad-ticket-progress
description: >-
  Use when the user asks to record ticket progress, status, or a handoff
  in a comment on a Jira, GitHub, or GitLab issue, or to mark acceptance
  criteria checkboxes from conversation evidence.
---

# Ticket progress comment

On request only. Post a **new** dated comment that leads with a monospaced
slice-bar visualization. When conversation confirms an acceptance
criterion is implemented (deployed, if that is what it requires), also
check that item on the ticket description. If the user asked only to
mark AC, update the description and skip the comment. Do **not** post
when the user only asks about progress in chat.

Stay generic — no org, project, or real ticket hard-coding.

## When not to apply

- Chat-only status ("where are we") — answer in chat
- No ticket identified and one question did not resolve it
- Tiny one-line fix with no progress to record
- User did not ask to write a ticket comment and did not ask to mark
  acceptance criteria

## Host

1. Explicit URL or key in chat: `PROJ-123` -> Jira; `owner/repo#N` or
   `github.com/.../issues/N` -> GitHub; `gitlab.com/.../issues/N` -> GitLab.
2. Branch / remote / open MR (same host routing as
   [mad-plan-and-ship-ticket](../mad-plan-and-ship-ticket/SKILL.md)).
3. Last progress comment on that ticket (same host).
4. Still unclear -> ask once. Other trackers -> ask; do not guess.

## Workflow

1. Resolve ticket + host.
2. Read the issue (description + acceptance-criteria checkboxes), recent
   progress comments, and the current plan/slices.
3. Check confirmed acceptance criteria on the **description** (below).
4. If this is a progress/handoff request: post a **new** comment
   (history). Name each criterion you checked under `### What landed`.
   Edit only the comment you just posted if re-read shows broken
   formatting. If the user asked only to mark AC, skip the comment.
5. Submit via the host adapter below.
6. Re-read the description checkboxes and, if posted, the comment. If
   bars, headings, links, or checkbox state broke, fix via the adapter.

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

## Acceptance criteria checkboxes

Same request as the comment. Update the issue **description** (not a
second comment). Best effort — skip if there is no AC list.

**Check an item only when all of these hold:**

- It is currently unchecked
- This conversation confirms the outcome the criterion names (user said
  it is done, or work here was verified and matches that outcome)
- If the criterion requires deploy / production / a named env, that
  deploy is confirmed — local or MR-only work is not enough
- The match is clear (same outcome; wording need not be identical)

**Leave unchecked when** the item is only planned, coded locally, or
discussed; only partly met; deploy/verify is still missing; or two
items could match.

Do **not** rewrite criterion text. Do **not** uncheck items unless the
user says they were undone. If the description write fails, still post
the comment and say which boxes you could not update.

### Jira description

GET the description ADF. Set matching `taskItem.attrs.state` from
`TODO` to `DONE`. Keep every `localId` and every other node. PUT via
[mad-jira-tickets](../mad-jira-tickets/SKILL.md) REST description —
**not** MCP.

### GitHub / GitLab description

In the issue body only, change matching `- [ ]` to `- [x]`. Write back
with `gh issue edit` / `glab issue update` or REST. Do not replace the
rest of the body.

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

- [ ] User asked for a ticket comment or to mark AC (not chat-only status)
- [ ] Host resolved; other tracker asked, not guessed
- [ ] New dated comment unless AC-only; edit only to repair the one just posted
- [ ] Heading `## Progress update (YYYY-MM-DD)` then fenced/codeBlock bars
- [ ] Status labels from the allowed set only
- [ ] Confirmed AC items checked on the description; uncertain left
- [ ] What landed names each criterion that was checked
- [ ] Visible title + URL links
- [ ] Re-read; bars/headings/links/checkbox state intact
