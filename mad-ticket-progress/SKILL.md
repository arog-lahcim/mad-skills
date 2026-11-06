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
3. **Verify external delivery state** cited in the comment (below) in the
   same session before writing slice bars, `### Known gaps`, or `### Next`.
4. Check confirmed acceptance criteria on the **description** (below).
5. If this is a progress/handoff request: post a **new** comment
   (history). Name each criterion you checked under `### What landed`.
   When [Execution plan block](#execution-plan-block) says this comment
   carries the plan, end with that generalized plan block and its diagram images.
   Edit only
   the comment you just posted if re-read shows broken formatting or a
   plan block that does not match its source. If the user asked only to
   mark AC, skip the comment. When the user asks to **update an existing**
   progress comment instead, `PUT` that comment via REST ADF; still
   re-read after write.
6. Submit via the host adapter below.
7. Re-read the description checkboxes and, if posted, the comment. If
   bars, headings, links, or checkbox state broke, fix via the adapter.

### Verify MR and pipeline claims (GitLab / GitHub)

Before stating that a merge request is open, unmerged, blocked, or merged —
including in slice-bar parentheticals — read its current state:

- GitLab: `glab api "projects/{encoded_path}/merge_requests/{iid}"` →
  `state`, `merged_at`, `merge_commit_sha` (or `glab mr view` when local).
- GitHub: `gh pr view` / `gh api repos/{owner}/{repo}/pulls/{number}`.

If the comment also claims a **release or deploy gate** (semantic-release tag,
pipeline success, environment deploy), verify that separately — **merged ≠
released/deployed**. Wording must match what you verified.

When the user corrects stale MR/pipeline text already on the ticket, fix the
description and/or the affected comment via REST, then post a short **Correction**
comment naming what changed and the verified state. Do not leave contradictory
progress comments unedited when the user pointed at a specific comment URL.

### Multi-agent / composer session evidence

When the user lists **composer or conversation UUIDs** instead of a single chat:

1. Use `SearchConversations` (one or two keywords per query) for titles and
   snippets — not full transcripts by default.
2. Local transcripts may be missing for **remote SSH / other-machine** sessions;
   do not claim you read a transcript file unless it exists on the current host.
3. Summarize only **observed** outcomes (MR URLs, commands, user-reported
   results). Label inference vs verified external reads.

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

What landed, Releases / MRs, Next, and Known gaps stay short. Omit an empty section. The execution plan block below is separate and is not shortened.

```
### What landed
- ...

### Releases / MRs
- title https://example.com/group/repo/-/merge_requests/16

### Next
- one concrete step

### Known gaps
- only work left outside this ticket

## Execution plan
<one image per diagram, then one fenced code block: the plan source, with local identity generalized>
```

## Execution plan block

Include the full plan in a progress comment only in two cases:

- This is the first progress comment for the current effort. No earlier progress comment on the ticket already holds this plan.
- The plan changed diametrically since the comment that holds it. A diametrical change is a change to what will be built: response shape, data source, which call returns a value, hot versus cold behavior, files or repositories in scope, or what a diagram means. A reworded sentence, an extra example of the same contract, slice status, and merge-request state are not a diametrical change.

Every other progress comment names the comment that holds the plan and does not paste the plan or its images again. Do not wait for the user to say "only at the start" or "only if the plan changed a lot".

When this comment does include the plan, it ends with `## Execution plan`. First, one image per diagram. Then one code block that is the plan another agent would implement from, after the generalization below. Do not wait for the user to say "include the diagram", "omit nothing", "paste the markdown", or "hide my username".

The plan source is the plan file when a file exists, including front matter. Otherwise it is the settled markdown. Generalize that source, then store the result. The code block includes diagrams, Mermaid, examples, SQL, and front matter. Do not summarize it, drop a section, or rewrite it into headings and bullets. Jira stores it as one ADF `codeBlock` with language `markdown`. GitHub and GitLab store it as one fenced `markdown` block. A summary plus a link to a local plan file is not this block.

Generalize machine-local identity in the whole comment, and in the plan block before it is stored:

- A home path `/Users/<name>/`, `/home/<name>/`, or `C:\Users\<name>\` becomes `~/`. The rest of the path stays.
- The account name of this machine does not appear. Outside a path, replace it with `<user>`. A hostname of this machine becomes `<host>`.
- A token, password, API key, connection string, or value copied from `.env` or a keychain becomes `<redacted>`.
- Repository-relative paths, public URLs, ticket keys, and names that belong to the product stay as written.

The same rules apply to diagram captions and to What landed, Next, and Known gaps. Compare a later plan with the generalized text already on the ticket. A rewrite that only hides a username is not a diametrical change.

Each fenced `mermaid` diagram in the generalized source is also a PNG above the code block, with a caption that is the heading of the section that contains the diagram, otherwise `Diagram 1`, `Diagram 2`, and so on. The image is the diagram, not a screenshot of a path or a terminal. Jira: upload the PNG to the issue and place it in the comment with a media node. GitHub and GitLab: upload and embed the image. One image per diagram, only in a comment that also contains the plan block. If rendering or upload fails, post the comment with the source block and name the missing image under `### Known gaps`.

After write, compare the stored block to the generalized source. If any part of that text is missing, edit the comment. Do not put a home path or account name back because the ticket text differs from the local file.

Skip the block when there is no plan, the user said to omit it, or this request is acceptance-criteria only (no comment).

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
items could match. A narrowed plan does not satisfy an older criterion.
Check it only when the shipped outcome meets that criterion's own words,
not the sentence the plan used to replace it.

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
- [ ] Every cited MR/PR/pipeline state verified this session (`glab` / `gh`) before write
- [ ] New dated comment unless AC-only or user named an existing comment to update
- [ ] Heading `## Progress update (YYYY-MM-DD)` then fenced/codeBlock bars
- [ ] Status labels from the allowed set only
- [ ] Confirmed AC items checked on the description; uncertain left
- [ ] What landed names each criterion that was checked
- [ ] Visible title + URL links
- [ ] Full plan block only on the first progress comment for this effort, or after a diametrical plan change; otherwise the comment names the comment that holds the plan
- [ ] That plan comment has one image per Mermaid diagram above the generalized source block; re-read matches that text and contains no home path or account name
- [ ] Re-read; bars/headings/links/checkbox state intact
- [ ] User corrections applied to description/comments + short Correction note if needed
