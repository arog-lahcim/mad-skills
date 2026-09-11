---
name: mad-plan-and-ship-ticket
description: >-
  Orchestrates ticket delivery from plan through unpublished draft MR review
  and stops for human merge. Use when the user asks to ship work end-to-end,
  /mad-plan-and-ship-ticket, or plan -> Jira -> branch -> implement ->
  commit/MR -> draft review.
disable-model-invocation: true
---

# Plan and ship ticket

Thin orchestrator only. Sequence the pipeline below; for each delegated step,
**open that skill’s `SKILL.md` and obey it** (same as if the user attached it).
Do **not** copy-paste commit regexes, ADF tables, draft-note API details, or
review voice rules into this skill.

If a glue rule conflicts with a delegated skill, the **delegated skill wins**,
except hard gates: **never merge**; **stop for human**.

Stay generic — no org/project hard-coding.

## Pipeline checklist

Copy and track:

```
Plan and ship ticket:
- [ ] 1. Plan (approve/execute)
- [ ] 2. Jira ticket (mad-jira-tickets)
- [ ] 3. Branch from ticket
- [ ] 4. Implement + verify
- [ ] 5. Commit + push + MR
- [ ] 6. Draft review (mad-draft-code-review)
- [ ] 7. Stop for human
```

### 1. Plan

For non-trivial work, use Plan mode. Wait for explicit approve/execute before
creating tickets or changing code.

### 2. Jira ticket

Hand off entirely to [mad-jira-tickets](../mad-jira-tickets/SKILL.md).

Supply inputs inferred from the plan/chat (parent, type, labels, sprint, ADF
body). Defaults when the user expects delivery: assignee = me, active sprint,
labels from context, transition to **In Progress** after create.

**Glue gate:** confirm **In Progress** fired after create/update. Do not invent
a new ticket when one already owns the work — reuse it; ask once if ambiguous.

Ask **one** question if parent, labels, or sprint cannot be inferred.

Format ticket links with [mad-visible-links](../mad-visible-links/SKILL.md).

### 3. Branch

Glue only (not owned by another Mad Skill):

1. Fetch/update the default base branch first (avoid stale base).
2. Create a Create-branch-style name from the ticket (key + summary slug).
3. Checkout the feature branch.
4. Call Cursor `SetActiveBranch` so agent UI/cwd stay on that branch.
5. Never merge into the base branch.

### 4. Implement + verify

Execute the approved plan. Run the plan’s verification steps before shipping
(commit/MR). Fix failures before step 5.

### 5. Commit + push + MR

- **Commit:** hand off entirely to [mad-git-commit](../mad-git-commit/SKILL.md).
- **Push:** default yes unless the user forbids push.
- **MR/PR:** open with `Closes KEY` (or host equivalent). Detect host from
  `git remote` — GitLab → `glab` / GitLab MCP; GitHub → `gh` / GitHub MCP.
- Never merge the MR/PR.
- Links in MR body: [mad-visible-links](../mad-visible-links/SKILL.md).

**Follow-ups on the same work:** keep the same ticket and open MR; do not open
a second ticket by default. After pushing more commits to an open MR, run step
6 again.

**Progress comment:** only if the user asks to record status or a handoff on
the ticket — then open and follow
[mad-ticket-progress](../mad-ticket-progress/SKILL.md). Do not post
unsolicited.

### 6. Draft review

Hand off entirely to
[mad-draft-code-review](../mad-draft-code-review/SKILL.md).

### 7. Stop for human

Human reviews and merges. Do **not** auto-merge, auto-publish draft review, or
auto-transition the ticket to Done.

## Auth failures

If Atlassian / GitLab / GitHub MCP calls fail with auth errors, follow
[mad-check-connections](../mad-check-connections/SKILL.md), then retry the
failed step.

## Out of scope

- Auto-merge, auto-publish review, auto Done
- Fixed project keys or company label catalogs
- Re-implementing any delegated Mad Skill’s procedures
