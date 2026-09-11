---
name: mad-draft-code-review
description: >-
  Leave unpublished draft code-review comments on GitLab MRs (or GitHub PRs)
  with team-friendly voice, Nit labeling, cross-linked threads, natural
  closers (Wdyt?, Does it make sense?), and a one-line TLDR above a horizontal
  rule on long comments. Signs every comment with author, register and an
  evidence marker (verified / inferred / unverified) so its weight matches
  what the MR actually owns and what could be checked - findings only for
  verified problems in code it authored, one-line non-blocking asks or
  heads-ups for code moved unchanged, sibling MRs, or effects that cannot be
  verified. Budgets that volume against the substantive size of the change
  rather than the raw diff, and reports what it downgraded or dropped.
  Grounds the review in the linked ticket's acceptance criteria and the specs
  it references. After posting, finish the full chat summary and steering
  notes; do not wait on a next-step question - the user reviews drafts in
  the UI. Never recreate drafts the user deleted unless they explicitly
  ask. On re-review, resolve fixed threads (award white_check_mark only when
  the author replied); do not leave acknowledgment replies. When a review
  leaves no required-change drafts and the MR looks ready to merge, award
  white_check_mark plus authorship reactions on the MR itself: robot for
  agent work, robot and technologist for shared work, or technologist for
  human work. If a re-review instead leaves new required-change drafts,
  remove the prior ready-signal reactions and award speech_balloon instead.
  Renames the chat to a fixed MR title format as soon as the MR is identified.
  Use when the user asks to review a merge request or pull request, open a
  draft review, add review comments without publishing, refine pending draft
  notes, or apply edits / decisions left under existing drafts.
---

# Draft Code Review

Perform a technical review and leave **unpublished draft** comments for the user to edit and submit. Do **not** publish, approve, request changes, or submit the review unless the user explicitly asks.

Default comment language: **English** (unless the user requests otherwise).

## Workflow

1. Load MR/PR context: title, description, commits, CI, changed files, full diffs.
2. Rename the chat — see [Chat title](#chat-title). Do this as soon as the MR `iid` and author are known; do not wait for the review to finish.
3. Load the ticket and the docs it references — see [Ticket and documentation context](#ticket-and-documentation-context).
4. Check out the branch (shallow clone is enough) and read the changed files whole, plus the code paths they contract with — writers of a field a resolver reads, callers of a changed signature. Diff-only review misses mismatches that live in unchanged code.
5. Review for correctness, edge cases, API contracts, tests, and unmet acceptance criteria.
6. **Cut before posting.** Run every candidate finding through [Restraint](#restraint) — ownership, confidence, budget — and drop the ones that do not survive. This step is not optional and happens *before* any draft is created.
7. Create **draft** inline notes on **diff lines only** (see [Anchor on diff lines](#anchor-on-diff-lines)) plus an optional general overview note.
8. If this review left **no required-change drafts** and the MR looks ready to merge, follow [Ready-to-merge signal](#ready-to-merge-signal). If this is a **re-review** that left new drafts for required changes, follow [Needs-work signal](#needs-work-signal) instead.
9. Show the user a **short summary** of what was left as draft (or that none were needed, and which ready / needs-work reactions were set on the MR), plus the [cut list](#tell-the-user-what-was-cut). Keep drafts unpublished.
10. After that summary, say briefly how to steer the drafts, then **stop** — do not ask what to do next. See [After posting drafts](#after-posting-drafts).
11. On a **follow-up apply pass** (user re-invokes this skill to process draft edits): follow [Apply draft feedback](#apply-draft-feedback). Do **not** republish deleted drafts.
12. On a **re-review** (new commits and/or author replies): verify prior threads against the current diff, then follow [Resolved threads on re-review](#resolved-threads-on-re-review). If that re-review also leaves no new required-change drafts and the MR looks ready to merge, follow [Ready-to-merge signal](#ready-to-merge-signal). If it leaves new drafts for required changes, follow [Needs-work signal](#needs-work-signal).

## Chat title

This skill is standing authorization to call `rename_chat` — do it without asking the user first.

As soon as the MR is identified (and after the first user prompt of the chat has been sent — when the host auto-names chats, that may overwrite titles set earlier), rename the chat to:

```
MR !<iid> (<JIRA-KEY>) - <MR author name> - <context>
```

- `<iid>` — GitLab MR `iid`, always prefixed with `!`.
- `<JIRA-KEY>` — Jira key from the MR title, source branch, or description. Omit the parentheses entirely when the MR references no ticket.
- `<MR author name>` — `author.name` of the MR (its creator); never the reviewer or the current user.
- `<context>` — a few words for the work in this chat, e.g. `review`, `re-review`, `apply draft feedback`, `fix failing CI`.

Separator is ` - ` (space, hyphen, space). Example: `MR !482 (PROJ-123) - Anna Kowalska - review`.

Also rename on apply-feedback and re-review passes if the title is still wrong or missing the MR prefix.

### GitLab (preferred when `glab` is available)

Use the Draft Notes API via `glab api` (authenticated as the current user). Draft notes are visible only to their author until published.

```text
GET/POST    /projects/:id/merge_requests/:iid/draft_notes
PUT/DELETE  /projects/:id/merge_requests/:iid/draft_notes/:draft_note_id
```

- General note: `{ "note": "…" }` (no `position`).
- Inline note: include `position` with `base_sha`, `start_sha`, `head_sha`, `position_type: "text"`, `old_path`, `new_path`, and `new_line` (and/or `old_line`). The line must be a **changed** line in the MR diff — see [Anchor on diff lines](#anchor-on-diff-lines).
- Prefer JSON body: `glab api --method POST … -H "Content-Type: application/json" --input <file.json>`.
- Resolve SHAs from the MR `diff_refs`.
- **Never** call publish / `bulk_publish` unless the user explicitly asks to submit.
- When editing an existing draft via `PUT`, always resend the full `position` object together with `note` — sending `note` alone wipes the inline position.

### GitHub

If the review target is GitHub, use `gh` pending-review APIs equivalently: create a pending review and comments; do not submit until asked. Same rule: only comment on lines in the PR diff ([Anchor on diff lines](#anchor-on-diff-lines)).

## After posting drafts

End the user-facing reply with two parts, in this order. Write the **entire** reply before ending the turn.

1. **Summary** — brief list of draft topics / files (or "merge-ready; :white_check_mark: plus authorship reaction(s) on MR" when applicable), plus the [cut list](#tell-the-user-what-was-cut).
2. **How to steer the drafts** — two short lines, no more:

- Edit or **delete** any draft in the MR UI; deleted drafts stay gone.
- Under a draft you want changed, append **bullet points** with decisions or rewrite instructions (e.g. `- yes, require ContainerSource — rewrite as a firm ask`). Free-form notes at the end of a draft also count.

### Do not wait after drafts

After drafts are posted or updated (first review, apply-feedback, re-review), **do not** call `AskQuestion` or any other blocking question tool. Do not wait for the next step. A question tool ends the turn and drops remaining detail.

The user reviews drafts in the MR/PR UI. Merge-ready passes with no drafts also skip a closer: report the ready signal and stop.

Keep later typed commands valid as a non-blocking note, not a menu that must be answered now:

```text
/mad-draft-code-review apply draft feedback on <MR URL>
```

Other valid phrasings: "apply my draft edits", "update drafts from my bullets", "process draft feedback" + the MR/PR link. Attaching this skill and pointing at the same MR is enough when the intent is clearly to apply feedback rather than start a full new review.

Never publish unless the user later asks. Do **not** pad the reply with publish/approve guidance unless the user asked how to submit.

`AskQuestion` stays allowed only for the **pre-post** budget overflow gate (choose which findings to keep before creating drafts). That is a real decision, not a closer.

## Apply draft feedback

When the user re-invokes this skill to apply feedback on existing drafts:

1. `GET` current draft notes for the MR/PR. Treat that list as authoritative.
2. **Never recreate** drafts the user deleted, and do not re-add topics from an earlier pass that are no longer present — unless the user **explicitly** asks to restore a specific comment.
3. For each remaining draft that has user-added bullets or trailing notes:
   - Read them as instructions/decisions for **that** comment.
   - Rewrite the draft body to match (firm ask vs open question, scope, links, tone).
   - **Remove** the instructional bullets / “update this comment” meta from the published-facing text.
   - End the rewritten body with the correct signature alone on its final line — `:technologist:` if the body is fully the human's substance, otherwise `:robot:+:technologist:` (see [Comment signature](#comment-signature-required)).
   - `PUT` the updated note **with full `position`** (GitLab) so the inline anchor is preserved.
4. Leave drafts without new user marks unchanged.
5. Do not start a full re-review of the diff unless the user also asked for one (new commits / re-review).
6. Reply with a short summary of which drafts were updated (and which deleted ones were left deleted). Do not close with a question — see [Do not wait after drafts](#do-not-wait-after-drafts).

Example: a draft ends with `- yes we do want to use ContainerSource … Update this comment.` → rewrite the body into a direct ask to use `ContainerSource` (with the cited links), drop the bullet, keep the same line anchor.

## Ticket and documentation context

A diff can be internally consistent and still not deliver what was asked for. Ground the review in the ticket before reading code.

### Find the ticket

- Ticket key from the branch name (`CPL-1024-…`), the MR/PR title, or a `Closes CPL-1024` / `Fixes #123` line in the description.
- Jira: read it with the `mcp-atlassian` MCP (`jira_get_issue`) — read-only MCP use is fine.
- GitLab/GitHub issues: the MR context already lists what it closes; fetch those issues.
- No ticket reference anywhere: review against the diff alone and say so in the summary to the user. Do not draft a comment about the missing reference.

### Follow the ticket's references

Read what the ticket points at, not just its summary:

- The `References` links — specs, ADRs, runbooks, related tickets, incidents.
- Notion via the `notion` MCP (`notion-fetch` takes the page **id** from the URL, not the URL).
- Confluence via `confluence_get_page`.
- Read the **sections the ticket names** (e.g. "sections 3.1, 3.2, 8.2"), plus the glossary and changelog of the spec.

### What this context is for

- **Acceptance criteria vs the diff.** Each criterion: met, partly met, or untestable as written. An unmet AC is a finding — anchor the draft on a related **changed** line (name the untouched symbol/path in the body if needed), not on an unchanged line and not only in the overview when a diff anchor exists.
- **Prerequisites the ticket declares.** "Documentation update committed before implementation", "depends on CPL-995 merged" — check whether it actually happened. A spec's changelog / last revision date tells you if the agreed update landed.
- **Spec citations in the code.** When a docstring or comment cites a spec section, open that section. Code claiming a contract the spec does not state — or states for a different level of the model — is a real finding, and often the most valuable one in the review.
- **Decisions already settled in the ticket.** Architectural decisions and answered questions are not open for re-litigation in review comments. Do not suggest an approach the ticket explicitly rejected without acknowledging that it was rejected.
- **Open questions the ticket flags.** If the ticket leaves a question open and the diff quietly answers it, that answer deserves a comment.

Reference the ticket and spec precisely in drafts: ticket key, section number, revision or date. `Quark §8.2` and `CPL-1024 lists this as a prerequisite` are actionable; "per the spec" is not.

### Documentation links in drafts

Whenever a draft cites documentation (Notion, Confluence, ADRs, runbooks, API specs), include a **visible deep link** to the exact section or paragraph whenever one exists — not only the document title or a bare `§7.3`.

Format per `mad-visible-links`: human title (with section) then the full URL as plaintext (clickable). Prefer a heading / block fragment over the page root.

```text
Platform Data Query API §7.3 (Data Object Queries) https://app.notion.com/p/34c0f2e73c5b80a6a335e9b59bced433#34c0f2e73c5b81e7aa86d16674f9c948
```

Resolve the fragment from the fetched doc (in-page TOC links, "Copy link to block", or cross-links that already carry `#…`). If no block/heading URL is available after a reasonable look, link the page and keep the section name in the title — do not invent hashes.

### GitLab autolink traps (`!N`, `#N`)

GitLab **rewrites** bare `!N` / `#N` in note bodies to a reference in the **project where the note is posted**, not the project named in surrounding prose. Writing `custom-resource-webhook !5` on a `platform-api` MR still links to `platform-api!5` — often a wrong, unrelated (even merged) MR. The same trap applies to bare `#N` issue refs.

In **draft / published note bodies** (inline, overview, replies):

- **Never** write bare `!N` or `#N` when the target is another project — and prefer avoiding bare `!N` even for the current project when a URL is available.
- In prose use a non-autolinking form: `MR 5`, `custom-resource-webhook MR 5`, or `issue 12` — **no** leading `!` / `#`.
- Always pair the citation with a **full visible URL** (per `mad-visible-links`). Prefer the `/diffs` URL when the point is the change itself:

```text
custom-resource-webhook MR 5 diffs https://gitlab.com/cledar/cledar-platform/platform-integrations/custom-resource-webhook/-/merge_requests/5/diffs
```

- Do **not** rely on GitLab's `group/project!5` shorthand alone without the `https://…` URL next to it — many UIs still confuse readers, and the plaintext URL is what survives copy/paste.
- Before posting or after an apply-feedback rewrite, scan the draft for bare `!\d+` / `#\d+` tokens and rewrite them.

This rule applies only to **GitLab-rendered comment text**. Chat titles may still use `MR !<iid>` (see [Chat title](#chat-title)); that string is not posted as an MR note.

## Restraint

Restraint here is about **weight, not silence**. Raising a topic is usually fine; presenting it as a blocker when it is really a question is what costs the reviewer credibility — and it is the reviewer's name on the thread, not this skill's. Review is shared learning, so "are we aware this also does X?" is a legitimate comment; "this must change" for something the author does not own is not.

Sheer count matters too: a dozen blocker-shaped threads on a move/refactor MR reads as nitpicking regardless of how each one is worded. The fix is rarely to delete the topic — it is to say it in one sentence, as a question, and to let the author close it with one word.

### Register: what weight does this finding deserve?

Before drafting, place each candidate on this scale. Most findings that used to become essays belong in the lower two rows.

| Situation | Register | Shape | Evidence needed |
| --- | --- | --- | --- |
| Correctness, contract or test gap in code **this** MR authored | `finding` | Normal comment: what happens, why it matters, what to do | `:dart:` only |
| Consequence the author may not have in view, in code they own | `ask` | One or two sentences: "this also does X — is that intended?" | `:dart:` or `:compass:` |
| Code owned elsewhere (moved verbatim, sibling MR, other team), or a downstream effect you cannot verify | `heads-up` | One sentence, explicitly non-blocking: "flagging in case it is not on the radar — custom-resource-webhook MR 5 diffs https://gitlab.com/…/merge_requests/5/diffs changes this too" | any, `:grey_question:` typical |
| Already decided in the ticket or an earlier thread | nothing, or a pointer | Do not re-litigate; at most link where it was decided | — |

The register and the evidence marker both land on the signature line, and they constrain each other — see [Comment signature](#comment-signature-required). If a candidate cannot be verified, the interlocks force it down to a question, which is the mechanism that keeps a hunch from being written as a demand.

- An `Ask` or `Heads-up` never gets a `**TLDR:**`, never gets three paragraphs of reasoning, and never carries an implied "before merge". Length signals weight, so keep the form matching the register.
- Say the register out loud when it is not obvious: "not blocking, just checking" costs five words and prevents the author from reading a question as a demand.
- If a `Heads-up` would still be the fourth one on the MR, it is better said to the user in chat than added to the pile.

### Ownership check (before drafting anything)

Ownership does not decide **whether** to raise something — it decides **how hard** to push. Establish it before writing:

- **Moved or copied code.** When the MR relocates code between repos/paths, diff it against the source it came from. Behavior that arrived unchanged belongs to the origin, so it is at most an `Ask` here ("we are inheriting X — do we want to keep it?"), never a demand on this author. Fetch the origin file (`glab api …/repository/files/<path>/raw?ref=<branch>`) and compare instead of assuming.
- **Another open MR / repo.** When the same code, schema or contract is being worked in a sibling MR, that MR owns the discussion. A one-line `Heads-up` naming it is useful; repeating its full analysis here is not.
- **Already decided.** Check the ticket, the MR threads, and prior review rounds. A settled decision is not reopened by a review comment; if the diff quietly contradicts it, that contradiction is the finding, not the decision.
- **Not in the diff's reach.** Resources the MR deliberately left behind, endpoints it does not touch, follow-up work with its own ticket — `Heads-up` at most, and only when someone could plausibly be unaware.

### Confidence bar

- What you can verify in the diff can be stated as a finding. What you cannot, ask about — the author usually has the context you are missing, and asking gets it into the thread faster than asserting.
- Hedged endings — "worth being deliberate about", "worth coordinating" — mean the register is wrong, not that the topic is worthless. Rewrite as a plain question, or move it to the chat summary.
- Downstream consumers, rollouts and other teams' plans are things the author knows better. If it seems worth raising, raise it as one question and accept a one-word answer.

### Budget

The cap scales with the **substantive** size of the change, not with the diff's line count. Substantive means what this MR actually authored: exclude verbatim moves, lockfiles, generated and vendored trees, and pure reformatting. A 400-line relocation of untouched YAML is zero substantive lines and earns a near-zero budget.

Measure before drafting: `git diff --numstat <base>..<head>` over the files that survive the ownership check, then diff any moved file against its origin so only the divergence counts.

Starting scale — a default to tune with the user, not a law:

| Substantive change | Max `finding`-weight drafts, overview included |
| --- | --- |
| Move / rename with no divergence from origin | 0–3 |
| Up to ~100 lines, or ≤3 files | 3 |
| ~100–500 lines | 5 |
| Over ~500 lines | 7, treated as a ceiling rather than a target |

Three is the floor, not the target: small MRs do collect a few genuine fixes, and a pure move can still hold a couple worth raising. Zero stays a valid outcome.

- The table caps **findings**. One-line `ask` / `heads-up` notes are cheaper, so up to **two** of them may sit on top of the cap — past that the pile-up becomes the message again.
- At most **two** threads on any single file, of any register, unless they are siblings of one issue (below). Keep the strongest one.
- More survivors than the cap means the ranking was not done. Rank by consequence, keep the top ones as findings, downgrade or drop the rest, and tell the user in chat.

### One issue, several sites

The same mistake repeated across files is **one** finding against the budget, however many threads it takes. Marking every occurrence beats keeping the count down: the marks are what makes the fix checkable later, and a wrong default that lives in three configs is only fixed when all three are.

- Pick a **primary** thread — the first occurrence, or the one where the fix belongs — and put the reasoning there together with an explicit list of every site as `path:line`.
- Every other occurrence gets a **one-line sibling** and nothing more: ``Same as `outputtopic-crd.yaml:93` (2/3).`` No repeated reasoning, no repeated links.
- Same register and same evidence marker across the whole cluster. If they would differ, it is not one issue.
- The cluster counts as **one** against the table, and its siblings are exempt from the two-threads-per-file cap.
- Past roughly four sites, stop opening threads: keep the primary with the full list and say the remainder are identical.
- On re-review, check each site separately: resolve each sibling as it lands, and keep the primary open until its list is fully done. That list is the checklist — which is the whole reason for marking every site in the first place.
- If a pass still looks like it needs to exceed the cap, **stop before posting** and ask the user which to keep (`AskQuestion`). One question beforehand is cheaper than pruning a published review.
- Length is part of the budget: prefer the shortest form that carries the ask. A multi-paragraph comment with a TLDR reads as a blocker even when it is only a question.

### Tell the user what was cut

The chat summary lists what was drafted, what was **downgraded** to a one-line question, and what was dropped — one line each, with the reason (owned by custom-resource-webhook MR 5, already decided, could not verify). Raising a comment back up is easy for the user; discovering an overweight one after publication is not.

## What to comment on

- Concrete technical findings with enough context to act on.
- Open design choices and real edge cases.
- Acceptance criteria the diff does not meet, and contracts the cited spec does not actually state.
- Relationships between findings (see below).
- Process notes that are not duplicated inline — only in the overview (and only when they affect this change’s correctness or reviewability beyond what the UI already shows).

### Do not comment on

These are about the **form**: none of them earns a demand on the author. Several are still fine as a one-line `Ask` or `Heads-up` — see [Register](#register-what-weight-does-this-finding-deserve).

- Code that arrived unchanged in a move or copy, or behavior a sibling MR already owns — as anything firmer than a question.
- Rollout sequencing, cutover coordination, who updates which client — as a review requirement. One non-blocking question is fine when it looks genuinely unnoticed.
- Code paths the author has already said are going away, or tests they have said will be rewritten — a second comment there adds nothing.
- Sparse or missing MR/PR descriptions, or a missing ticket reference — not a review problem.
- The ticket's own wording or formatting — review the code, not the ticket.
- Scope the ticket explicitly excludes, unless the diff silently depends on it.
- Praise or blame of the author’s work (“Nice work”, “This is sloppy”, etc.). Overall judgment is for the human reviewer to write.
- That the review is a draft / unpublished — the UI already shows that.
- Merge conflicts between the source/current branch and the base/target branch — the UI already shows them and blocks merging until they are resolved.
- That the source branch is behind the target, or asking the author to rebase / merge target into the branch — GitLab/GitHub already surface divergence; it is not a review finding for this MR unless a concrete correctness issue in the diff depends on it (comment on that issue inline, not as a rebase ask).
- Priority labels (`Low`, `Medium`, `High`, “nitpick priority”, etc.) except the `Nit:` prefix below.

## TLDR for long comments

A long comment buries its own ask. When a draft runs past roughly **100 words** or **four paragraphs**, open it with a one-line summary, then a horizontal rule, then the full reasoning. Applies to inline notes and the overview alike.

```text
**TLDR:** <one sentence: the finding and the ask>

---

<full comment body>

<closer, when natural>

<signature>
```

- Blank line on **both** sides of the `---`. Without the blank line above it, Markdown reads the rule as a setext heading and turns the TLDR line into a heading instead.
- One sentence, naming both what is wrong and what to do. A topic label (`**TLDR:** hotPath defaults`) is not a TLDR.
- No heading, no bullets, no second sentence inside the TLDR.
- The TLDR carries neither the closer nor the signature; both stay at the end of the comment.
- Under the threshold, skip it — a summary as long as the comment it summarizes only adds reading.
- `Nit:` drafts open with `Nit: ` and take no TLDR. A nit long enough to want one wants trimming instead.
- Long enough for a TLDR is also worth a second look for text to cut. Add the summary, then drop whatever the summary made redundant.
- On an [apply-feedback](#apply-draft-feedback) rewrite, move the TLDR with the body: a TLDR promising an ask the body no longer makes is worse than none, and a rewrite that lands under the threshold loses it.

## Overview (general) note

- No title or heading — it is already a review of this MR/PR. A `**TLDR:**` line is a summary, not a title, and stays allowed when the note is long enough to need one.
- No praise or criticism of the work.
- Do **not** restate topics covered by inline comments.
- Keep only items that have no inline home.
- Do **not** use the overview to request a rebase or to note that the branch is behind the target (see [Do not comment on](#do-not-comment-on)).
- Omit the overview entirely if there is nothing left to say.

## Inline comments

### Anchor on diff lines

GitLab and GitHub only surface inline comments on lines that appear in the MR/PR **Changes** diff. A draft pinned to an **unchanged** line (including unchanged context around a hunk) is easy to create via the API but often **invisible** in the review UI.

- Before posting an inline note, confirm the target line is **added, removed, or modified** in the current MR/PR diff (not merely present in the file or in hunk context).
- Prefer `new_line` for added/modified lines on the new side; use `old_line` (alone or with the matching deletion) for removed lines.
- Still **read** unchanged callers, writers, and contracts (workflow step 3). When the finding lives there, pin the draft to the **nearest related changed line** and name the unchanged symbol/path/line in the comment body. If no related changed line exists in any touched file, use a general overview note instead of an invisible inline.
- Do **not** pick an arbitrary nearby context line just because it is close in the file — only lines that are themselves changed.
- On re-review, new inline drafts follow the same rule against the **current** diff.

### Nit vs non-nit

- True nits (docs, naming clarity, optional polish): start with `Nit: ` then the content. No other priority wording.
- Non-nits: no priority prefix, no severity labels.

### Voice

- Inclusive team pronouns: `we could`, `could we`, `would it make sense to…`.
- Vary phrasing — do **not** lean on one template (avoid repeating `How about we…` every time).
- Collaborative, not accusatory. Describe behavior and options; do not “call out” mistakes.
- Review is shared learning, not gatekeeping. Asking whether the team has the consequence in view is a good comment; dressing the same thought as a required change is not.
- Prefer light formatting. Do not overuse bold. Use inline code for identifiers, paths, types.

### Clarity over sophistication

The reader should get the point on the first read. A comment that has to be re-read to be understood has failed, however precise it is — clever phrasing, dense clauses, and insider shorthand cost the author time and the reviewer credibility.

- **Plain words first.** Say the thing directly. Prefer short, common words over sophisticated or ornate ones; drop rhetorical flourishes, em-dash pile-ups, and abstract nouns when a concrete verb does the job.
- **One idea per sentence.** Break a long, multi-clause sentence into two or three short ones. If a sentence needs a second read to parse, rewrite it.
- **Name things the way the code and the reader do.** Use the actual symbol / path / status, not a paraphrase the reader must decode (`status.view.phase == Ready`, not "once the controller blesses it"). Expand jargon and internal shorthand the first time, or avoid it.
- **Lead with the point.** State the finding or ask up front, then the reasoning — not a build-up that only resolves at the end. For longer comments this is what the `**TLDR:**` line is for.
- **Show, don't describe, when a snippet is shorter.** A two-line before/after or a concrete example often replaces a paragraph of prose.
- **Cut every word that does not change the meaning.** After drafting, reread and delete filler; if two sentences say the same thing, keep the clearer one.
- Sophisticated writing is not the goal and is not a sign of a good review — an obvious, boring comment the author acts on immediately beats an elegant one they have to puzzle over.

### Related comments

- If two threads address the same decision space, **cross-link** them (file/symbol is enough).
- State clearly when addressing one suggestion may cover or invalidate the other.
- Do not duplicate the same ask in overview and inline.
- Related threads are different asks that interact; **the same** ask repeated at several sites is a cluster with one primary and one-line siblings instead — see [One issue, several sites](#one-issue-several-sites).

### Closers (optional, only when natural)

Put the closer alone on its **own line** after a blank line. Do not force a closer on every comment.

| Situation | Closer | Notes |
| --- | --- | --- |
| Open decision / choice of approaches | `Wdyt?` | Acronym only; write `Wdyt?` not `WDYT?`. |
| Uncertainty about current behavior or understanding | `Does it make sense?`, `Makes sense?`, or `Am I correct?` | Short sentences OK here. |

Vary the closer across a review — do not reuse the same phrase (e.g. `Does it make sense?`) on every comment; rotate through the options above as fits each one.

**Do not use:** `LMK`, long closing sentences for decisions (`Curious what you'd prefer.`, `Thoughts?`, etc.), or closers on clear consistency fixes / soft docs asks where the decision already lives on a related thread.

### Comment signature (required)

Every draft this skill writes — inline and overview, first pass and apply-feedback rewrite — ends with a signature alone on its **own final line**, after a blank line (same spacing as a closer). The line carries three fields separated by ` · `:

```text
<author> · <register> · <evidence> (<what was checked, or the assumption>)
```

```text
:robot: · finding · :dart: verified (builder.py:94, k8s_client.py patch call)
:robot: · ask · :compass: inferred (k8s_client.py:98; which 404s occur in practice not verified)
:robot: · heads-up · :grey_question: unverified (whether any client branches on that status)
:robot:+:technologist: · nit · :grey_question: unverified (assumes both deploy paths coexist for a while)
:technologist:
```

**Author** — who wrote the substance:

| When | Author |
| --- | --- |
| Agent-only draft (no human edit of this comment yet) | `:robot:` |
| Shared authorship — agent finding refined with human bullets/decisions, or a discussion follow-up that still mixes agent analysis with human steering | `:robot:+:technologist:` |
| Human content — the body is **100%** the person's statement, decision, or wording (agent only posted / lightly formatted it for MR voice). Includes: "write this answer…", paste-my-words replies, and apply-feedback rewrites that replace the draft with the human's substance rather than merging it into an agent finding | `:technologist:` |

**Register** — `finding`, `ask`, `heads-up`, or `nit`, per [Register](#register-what-weight-does-this-finding-deserve). A `nit` keeps the `Nit: ` body prefix as well: the prefix is what a reader sees first, the marker line is the uniform footer.

**Evidence** — what the claim rests on:

| Marker | Means | Parenthetical |
| --- | --- | --- |
| `:dart: verified` | The exact code, config or spec section that makes the claim true was opened on this branch (or run). Anyone can re-check it. | Optional: name the files/lines |
| `:compass: inferred` | Follows from code that was read, but one step is reasoning — runtime behavior, controller reaction, Helm/Kubernetes semantics not exercised here. | **Required**: name the reasoning step |
| `:grey_question: unverified` | Rests on something that could not be opened: another repo's plans, cluster state, client behavior, team intent. | **Required**: name the assumption |

Interlocks between the two axes — these are hard:

- `finding` requires `:dart:`. A claim that cannot be re-checked cannot demand a change.
- `:compass:` caps the register at `ask`.
- `:grey_question:` caps it at `heads-up` or `nit`, and the body says "not blocking" in words too.
- A `:technologist:` line carries **no** register and **no** evidence marker — the substance is the human's, and this skill does not rate their confidence.

Naming the assumption is the point of the marker, not decoration: "assumes both deploy paths coexist" is a sentence the author can refute in seconds, which is exactly what should happen to a weak comment.

- Do **not** put the signature mid-paragraph, on the same line as a closer, or omit it.
- Use emoji shortcodes (`:robot:`, `:technologist:`, `:dart:`, `:compass:`, `:grey_question:`) — not raw Unicode characters.
- Apply-feedback `PUT`s: strip instructional bullets, then pick `:robot:+:technologist:` or `:technologist:` from the table (never leave a bare `:robot:` after a human-steered rewrite). Prefer `:technologist:` when the rewritten body is essentially the human's decision in full; prefer `:robot:+:technologist:` when the agent finding remains and the human only steered tone/scope/firmness.
- Apply-feedback also re-checks the other two fields: a human decision that settles an assumption usually raises the evidence marker, and a rewrite from open question to firm ask raises the register — which then has to satisfy the interlocks above. Dropping to `:technologist:` drops both fields.
- Re-review drafts that only restate an unresolved agent finding stay `:robot:`; mixed or human-owned wording uses the rows above.
- When editing a **published** note the same rules apply.

### Emoji in the body (optional, off by default)

Only add emoji in comment **bodies** (aside from the required signature) if the user asks for a friendlier tone. When enabled:

- Not on every comment — leave plain the ones on serious findings (security, auth, data loss, migrations/infra risk).
- At most one body emoji per comment, placed just before the signature line (after the closer, or after the last sentence if there's no closer) — never mid-paragraph, never after the signature.
- Vary the body emoji across comments; do not reuse the same one every time (e.g. don't default to `:thinking:` everywhere).
- Match the emoji to the comment's nature: `:thinking:` for genuine uncertainty/doubt, `:bulb:` for a suggestion, `:slightly_smiling_face:` for a light nit or casual aside.
- Use GitLab/GitHub emoji shortcodes for body emoji (`:thinking:`, not a raw Unicode character). The required signature stays `:robot:`, `:robot:+:technologist:`, or `:technologist:`.

The MR-level ready-signal awards and the thread-level :white_check_mark: awards below are separate from body emoji and from comment signatures — apply each only when its section says to.

## Ready-to-merge signal

After finishing the review (first pass or re-review), if **both** are true:

1. This review left **nothing that must change before merge** — no `Finding`-weight drafts. One or two non-blocking `Heads-up` or `Nit:` drafts do not withhold the signal; withholding it over them would only push the review back toward saying nothing.
2. The MR looks ready to merge — acceptance criteria met, no correctness / contract / test / merge-risk findings worth raising.

…then award the check mark button emoji (`white_check_mark` / :white_check_mark:) plus the authorship reaction(s) on the **merge request itself** (not on a note). Classify who supplied the substance of the ready verdict using the same rules as [Comment signature](#comment-signature-required):

| Ready verdict | MR-level authorship reactions |
| --- | --- |
| Agent-only | `robot` / :robot: |
| Shared — agent analysis refined by human decisions or steering | `robot` / :robot: and `technologist` / :technologist: |
| Human-only — the verdict is 100% the person's decision and the agent only carried it out | `technologist` / :technologist: |

Treat these as one ready signal with :white_check_mark:. Before setting it, remove any prior `speech_balloon` / :speech_balloon: and any stale ready-signal awards (`white_check_mark`, `robot`, or `technologist`) by the current user, then award :white_check_mark: and exactly the reaction set in the table. Do not infer authorship from who opened or authored the MR; classify the review work that produced this ready verdict. Tell the user which reactions you awarded.

GitLab:

```text
# If a prior needs-work balloon exists, remove it first:
GET     /projects/:id/merge_requests/:iid/award_emoji
DELETE  /projects/:id/merge_requests/:iid/award_emoji/:award_id
        # stale name=speech_balloon, white_check_mark, robot,
        # or technologist awards
        # only when awarded by the current user

POST  /projects/:id/merge_requests/:iid/award_emoji
      form: name=white_check_mark
POST  /projects/:id/merge_requests/:iid/award_emoji
      form: name=robot
POST  /projects/:id/merge_requests/:iid/award_emoji
      form: name=technologist
      # Post exactly the authorship reaction(s) selected by the table.
```

**Do not** award the MR-level ready signal if you left any `Finding`-weight draft, or if the change is not merge-ready (even if you somehow left no comments). These are only emoji reactions — they are **not** an approval, publish, or merge. Still do not approve / request changes / submit unless the user asks.

GitHub PRs have no equivalent `white_check_mark`, `robot`, or `technologist` issue reactions — skip the MR-level ready signal there; say so in the summary if the review was otherwise clean.

## Needs-work signal

After a **re-review**, if this pass left a new `Finding`-weight draft (the MR is no longer merge-ready; pure optional nits, asks, and heads-ups do not trigger this), and the MR currently has a `white_check_mark` / :white_check_mark: from an earlier ready signal:

1. **Delete** the current user's MR-level `white_check_mark`, `robot`, and `technologist` awards that formed the earlier ready signal.
2. **Award** the speech balloon button emoji (`speech_balloon` / :speech_balloon:) on the **merge request itself**.
3. Tell the user in the summary that the ready signal was replaced with :speech_balloon: because new required changes were drafted.

Do **not** leave any ready-signal reaction (:white_check_mark:, :robot:, or :technologist:) alongside :speech_balloon: on the MR. Do **not** add :speech_balloon: on a first-pass review that never had :white_check_mark: — only when clearing a prior ready signal after a re-review found more required work.

GitLab:

```text
GET     /projects/:id/merge_requests/:iid/award_emoji
DELETE  /projects/:id/merge_requests/:iid/award_emoji/:award_id
        # for name=white_check_mark, robot, or technologist
        # only when awarded by the current user

POST  /projects/:id/merge_requests/:iid/award_emoji
      form: name=speech_balloon
```

If there was no prior :white_check_mark:, skip the delete; still skip adding :speech_balloon: unless a prior ready signal is being withdrawn. GitHub: skip MR-level reaction swap (same limitation as ready-to-merge).

## Resolved threads on re-review

When re-reviewing after author replies and/or new commits, check each open thread from prior review rounds against the current code.

Ignore system notes when judging thread contents (e.g. GitLab “changed this line in version N”) — they are not author replies.

### Do not resolve while answering

**Never resolve** a discussion when any of these are true:

- An unpublished **draft reply** on that discussion still exists (including one you are about to create or just created).
- The author (or another participant) asked a **follow-up question** and this pass is preparing or leaving an answer — even if the original finding looks fixed in the diff.
- The thread still needs a visible decision / clarification after publish.

Resolved threads hide new replies in the default GitLab UI. Publishing an answer onto an already-resolved discussion makes that answer easy to miss. If the code fix is done but a question remains, leave the discussion **unresolved**, post the draft answer, and only resolve later once the answer is published **and** nothing further is pending on that thread.

If a discussion was resolved too early and you still need to answer on it: **unresolve** it first (`resolved=false`), then leave or update the draft reply.

### When the finding is fully done

**If the finding is properly resolved** (fix or agreed approach is in the diff / reply, **nothing left to ask**, and no draft reply is pending on the thread):

- Do **not** leave an acknowledgment reply (“Looks good”, “Works for me”, etc.).
- Resolve the discussion.
- Award the check mark button emoji (`white_check_mark` / :white_check_mark:) on the **latest non-system note** in that discussion **only if the author (or another participant) replied** in the thread. That is usually the author’s reply.
- If the thread still has only the reviewer’s own comment(s) — the fix landed in new commits with no discussion reply — **resolve only**; do **not** award :white_check_mark: on the reviewer’s own note.

GitLab:

```text
# When an author/participant reply exists:
POST  /projects/:id/merge_requests/:iid/notes/:note_id/award_emoji
      form: name=white_check_mark

# Only when fully done — no pending answer/draft on this thread:
PUT   /projects/:id/merge_requests/:iid/discussions/:discussion_id
      form: resolved=true

# Undo an early resolve before answering:
PUT   /projects/:id/merge_requests/:iid/discussions/:discussion_id
      form: resolved=false
```

**If the finding is only partly addressed**, leave a new draft (reply or fresh inline note) on what remains — do not resolve, do not award :white_check_mark:.

**If a residual nit is distinct from the original ask**, keep it as a new draft on the relevant line; still resolve the original thread when that original ask is done **and** no follow-up answer is pending (and award :white_check_mark: on the author’s reply only if one exists).

## Withdrawing a published comment

When a comment that is already published turns out not to belong in the review — wrong owner, already decided, speculation that did not hold — withdraw it rather than delete it. Deleting breaks thread continuity and leaves any replies answering nothing.

- Strike the **entire body**, line by line: `~~…~~` does not span blank lines or paragraphs, so wrap each non-empty line on its own (`- ~~text~~` for bullets; leave a standalone `---` rule unstruck).
- Leave the signature line plain — a struck emoji renders as noise — and update it per the signature table: a human-directed withdrawal is `:robot:+:technologist:`.
- Resolve the thread once struck.
- Scripting this: match signature shortcodes literally (`:robot:`, `:robot:+:technologist:`, `:technologist:`) — do not strip or rewrite them with a broad emoji-range regex.
- Never delete the author's notes or the user's own notes.

## Example shapes

Doubt + suggestion:

```text
`_decode_projected_value` runs on every projected field here, including plain leaf projections.

That fits computed `array_map` / `named_struct` results, but it also rewrites leaf `VARCHAR` values that happen to start with `{` or `[`.

We could decode only when the projection used a nested reshape, and leave plain path projections alone.

Does it make sense?

:robot: · ask · :dart: verified (projection.py:120-168)
```

Open choice with related thread:

```text
Nit: Nested child `name`s are resolved with `apply_path(root, child.name)`, so they need to be relative to the parent.

Related to the nit on `Projection.projections` in `types.py`: documenting relative `name`s there may be enough. Alternatively, we could reject parent-prefixed paths here — if we do that, the docs-only nit becomes less important.

Wdyt?

:robot: · nit · :dart: verified (resolver.py:88, types.py:41)
```

Ask — a consequence the author may not have in view, in code they own (see [Register](#register-what-weight-does-this-finding-deserve)):

```text
This writes `spec.hotPath` on every call, so a request that only bumps `retentionDays` also resets `enabled`. Is that the behavior we want here?

:robot: · ask · :dart: verified (builder.py:94, k8s_client.py patch call)
```

One issue across several files — primary carries the reasoning and the site list (see [One issue, several sites](#one-issue-several-sites)):

```text
`hotPath.enabled` defaults to `true` on the property while the object default just above it says `false`, so a CR applying `hotPath: {}` gets hot path on, and the API sends `false`.

Same divergence in all three places:

- `charts/crds/outputtopic-crd.yaml:93`
- `charts/crds/inputtopic-crd.yaml:102`
- the description text above both ("When enabled (default)")

Could we align them on `false`?

:robot: · finding · :dart: verified (both CRDs, models/custom_resources.py:18)
```

…and each sibling site is one line, nothing more:

```text
Same as `outputtopic-crd.yaml:93` (2/3).

:robot: · finding · :dart: verified
```

Heads-up — owned elsewhere, explicitly non-blocking, with the assumption named:

```text
Not blocking: these CRDs are copies here, and custom-resource-webhook MR 5 diffs https://gitlab.com/cledar/cledar-platform/platform-integrations/custom-resource-webhook/-/merge_requests/5/diffs is changing the same `hotPath` defaults upstream. Flagging in case porting them is not already planned.

:robot: · heads-up · :grey_question: unverified (whether the port is already planned)
```

Long finding, summarized first — reserved for findings this MR actually owns, never for an ask or a heads-up (see [TLDR for long comments](#tldr-for-long-comments)):

```text
**TLDR:** every call that omits `hotPath` resets `enabled` to `false` on an existing CR — could we write the field only when the request carries it?

---

`build_manifest` always writes `spec.hotPath`, and `apply_cr` sends the manifest as a merge patch, so each call rewrites `hotPath` on an existing CR.

`dataOffload` is never written here and `topicName` only when the request carries it, so both survive a patch. `hotPath` is the one field where a call that means to bump `retentionDays` also flips hot-path state.

Downstream that is not inert: with `enabled: false` the controller stops the Routine Load and rebuilds the serving view cold-only.

Wdyt?

:robot: · finding · :dart: verified (builder.py:94, k8s_client.py:120; controller behavior per data-flow-controller MR 4 https://gitlab.com/cledar/cledar-platform/platform-integrations/data-flow-controller/-/merge_requests/4)
```

## Checklist before finishing

- [ ] Chat renamed to `MR !<iid> (<JIRA-KEY>) - <author> - <context>` (or without `(<JIRA-KEY>)` when none); author is MR creator
- [ ] Comments are drafts only (not published) unless the user asked to submit
- [ ] Each draft sits at the right [register](#register-what-weight-does-this-finding-deserve) — findings only for code this MR authored; anything owned elsewhere or unverifiable is a one-line ask / heads-up, marked non-blocking, with no TLDR
- [ ] [Ownership](#ownership-check-before-drafting-anything) established before writing: moved/copied code diffed against its origin, sibling MRs looked for, settled decisions not reopened
- [ ] Finding count within the [budget](#budget) for the **substantive** change size (moves measured as divergence from origin, not raw lines); ≤2 extra one-liners; ≤2 threads per file; if more looked necessary, the user was asked **before** posting
- [ ] Repeated occurrences of one issue marked at **every** site as a [cluster](#one-issue-several-sites) — primary carries the reasoning and the full `path:line` list, siblings are one-liners `Same as … (n/m)`, counted once against the budget
- [ ] No hedged wording ("worth coordinating", "just flagging") — rewritten as a plain question or moved to the chat summary
- [ ] Chat summary names what was drafted, what was downgraded, and what was dropped, with reasons
- [ ] Withdrawn published comments struck line by line with the signature left plain, then resolved — never deleted
- [ ] Every inline draft is on an added/removed/modified diff line (unchanged-code findings re-anchored or overview); no invisible unchanged-line pins
- [ ] English (unless user requested another language)
- [ ] Ticket read (or its absence noted to the user); referenced spec sections opened, not assumed
- [ ] Every acceptance criterion checked against the diff; unmet ones raised inline
- [ ] Spec citations in the code verified against the actual section; prerequisites the ticket declares confirmed as done
- [ ] Ticket key, section number and revision/date cited precisely in drafts — no vague "per the spec"
- [ ] Doc citations use visible deep links to the exact section/paragraph when available (title + full URL; no title-only links)
- [ ] No bare GitLab `!N` / `#N` in note bodies (autolinks to the **current** project); cross-project refs use prose `MR N` / `issue N` plus a full visible URL (prefer `/diffs` when citing the change) — see [GitLab autolink traps](#gitlab-autolink-traps-n-n)
- [ ] No praise/blame overview; no draft meta; no MR-description or missing-ticket nags; no source/base conflict or rebase/behind-target comments
- [ ] Overview does not duplicate inline topics; no overview title; no rebase asks
- [ ] Nits use `Nit: `; no other priority labels; bold used sparingly
- [ ] Drafts over ~100 words / four paragraphs open with a one-sentence `**TLDR:**` then a blank-line-wrapped `---`; shorter drafts and `Nit:` drafts have none; apply-feedback keeps each TLDR in step with its body
- [ ] Inclusive `we` voice; varied phrasing
- [ ] Every draft reads clearly on the first pass — plain words, one idea per sentence, point stated up front, real symbol/status names not paraphrases; no clever or dense phrasing that needs re-reading; filler cut
- [ ] Related threads cross-linked; mutual invalidation called out when relevant
- [ ] Closers only when natural; `Wdyt?` / doubt sentences on their own line; no `LMK`; varied across the review, not the same phrase every time
- [ ] Every draft (inline and overview) ends with `<author> · <register> · <evidence>` alone on its final line after a blank line — `:technologist:` when the body is 100% human substance (and then no register/evidence); `:robot:+:technologist:` for shared authorship; apply-feedback never leaves bare `:robot:`
- [ ] Evidence marker honest and interlocked: `finding` only with `:dart:`, `:compass:` capped at `ask`, `:grey_question:` capped at `heads-up` / `nit` with "not blocking" in the body; `:compass:` and `:grey_question:` name the reasoning step or assumption in the parenthetical
- [ ] Body emoji only if requested; not on every comment; varied, not repeated; skipped on serious findings; never after the signature; `PUT` updates include `position` alongside `note`
- [ ] After posting: short draft summary **plus** two lines on steering drafts (edit/delete in UI, bullets under a draft)
- [ ] Pass ends with a complete written summary and no blocking question after drafts; do not call `AskQuestion` or wait
- [ ] Apply-feedback pass: only update drafts that still exist; never recreate user-deleted drafts unless explicitly asked; strip instructional bullets from the final draft text
- [ ] No `Finding`-weight drafts + merge-ready → ready signal on the MR itself: :white_check_mark: plus :robot: for agent-only, :robot: + :technologist: for shared, or :technologist: for human-only; same authorship rules as comment signatures; clear stale current-user :speech_balloon: / :white_check_mark: / :robot: / :technologist: awards first; never treat reactions as approval
- [ ] Re-review left required-change drafts after a prior ready signal → delete the current user's MR-level :white_check_mark: / :robot: / :technologist: ready reactions, award `speech_balloon` / :speech_balloon: instead; do not leave ready and needs-work reactions together
- [ ] Re-review: properly resolved threads are resolved with no acknowledgment reply; :white_check_mark: (`white_check_mark`) only on an author/participant reply — not when the thread is still only the reviewer’s comment(s)
- [ ] Never resolve a discussion that still has a pending draft reply or an unanswered follow-up being answered; unresolve first if an early resolve would hide the published answer
