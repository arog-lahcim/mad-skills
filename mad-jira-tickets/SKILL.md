---
name: mad-jira-tickets
description: Create and update Jira tickets with action-verb summaries and ADF descriptions (user story for Stories/Tasks; flexible bug layout with Evidence; References; Acceptance Criteria); set Blocks links and Rank order via REST; post formatted comments as ADF. Use when creating, updating, or reformatting Jira issues (including Bugs), writing ticket descriptions or comments, linking dependencies, ranking backlog order, or submitting descriptions or comments via the Jira Cloud REST API.
---

# Jira Tickets

## Writing documents and tickets

All descriptions produced as documents, notes, specifications, or Jira tickets must be **maximally concise** — no filler, repetition, or vague generalities. Every sentence should carry concrete information. Prefer short sentences, bullet lists, and precise wording over narrative prose.

Wrap all code-like text in inline code marks: variable names, field names, table/column names, API paths, GraphQL types, enum values, file paths, config keys, CLI flags, and similar identifiers (e.g. `artifacts`, `ArtifactMode`, `/data/graphql`, `customfield_10010`). In ADF descriptions, use the `code` text mark — not bare text or HTML.

**Default language: English.** Write tickets, task descriptions, acceptance criteria, and agent-produced documents in English unless the user explicitly requests another language.

## Jira tickets

Every Jira ticket must have a `Summary` (title) and a `Description` submitted as ADF via REST (see below).

**Issue-type layout:**

| Issue type | Opening | Required sections | Optional |
| --- | --- | --- | --- |
| Story, Task, and similar feature/work items | User story (`As a` / `I want` / `So that`) — **required** | `# Acceptance Criteria` | `# Evidence`, `# References` |
| Bug | Problem-first opening — **not** forced into a user story | `# Acceptance Criteria` | `# Evidence` (strongly preferred), `# References`, user story only when it fits |

The sections below under “User story at the start of the description” are the **default for Stories/Tasks**. For Bugs, follow **Bug tickets** instead — do not stretch a defect into an awkward user story just to match the Story/Task template.

### Ticket title (Summary)

Start the title with an action verb — what someone will do on this ticket. Use verbs such as `Implement`, `Check`, `Validate`, `Research`, `Fix`, `Add`, `Remove`, `Update`, `Document`.

**Good:** `Implement GraphQL schema + Postgres Artifact Registry`, `Validate JWT auth on artifact queries`, `Research StarRocks table lifecycle options`

**Bad:** `GraphQL schema + Postgres Artifact Registry`, `Artifact Registry`, `JWT auth`

Keep titles short and specific. No leading ticket keys, no trailing punctuation.

### Submitting descriptions (REST API, not MCP)

**Use the Jira Cloud REST API v3** to create or update ticket descriptions. **Do not use the Atlassian MCP** (`jira_create_issue` / `jira_update_issue`) for description bodies — it accepts Markdown or wiki markup but stores them as plain-text ADF paragraphs. Headings (`# References`, `h1. References`), links, and checkboxes do not render correctly.

Submit descriptions as **Atlassian Document Format (ADF)** via:

```
PUT /rest/api/3/issue/{issueKey}
{"fields": {"description": <adf doc>}}
```

Auth: Basic auth with `JIRA_USERNAME` + `JIRA_API_TOKEN` from the `mcp-atlassian` MCP config (`JIRA_URL` is the site base from that config — do not hardcode a host).

**ADF mapping** from the schema below:

| Schema element | ADF node |
| --- | --- |
| User story (3 lines, one block; Stories/Tasks required, Bugs optional) | `paragraph` with `hardBreak` between lines; labels `As a`, `I want`, `So that` use `strong` marks; label and rest of line in the same text run — no `hardBreak` after a label |
| Bug opening (when no user story) | one or more `paragraph` nodes — expected vs actual / where it fails; no persona formula required |
| `# Evidence` | `heading` attrs `level: 1`, text `Evidence` (omit section if none; strongly preferred on Bugs) |
| Warning / log / traceback body | `codeBlock` with `attrs.language` (e.g. `text`) and a single `text` child — paste the **full** user-provided output verbatim |
| `# References` | `heading` attrs `level: 1`, text `References` |
| Reference bullet + link | `bulletList` → `listItem` → `paragraph` with `text` + `link` mark |
| `# Acceptance Criteria` | `heading` attrs `level: 1`, text `Acceptance Criteria` |
| `- [ ] Criterion` | `taskList` → `taskItem` attrs `state: "TODO"` (each needs a unique `localId`); **`taskItem.content` is inline `text` nodes — do not wrap in `paragraph`** (paragraph wrapper returns `INVALID_INPUT`) |
| Inline code (names, paths, types) | `text` with `code` mark — e.g. `artifacts`, `ArtifactMode`, `/data/graphql` |

Root document: `{"version": 1, "type": "doc", "content": [...]}`.

MCP is fine for read-only operations (search, get issue) and non-description fields (summary, epic link, transitions, issue links metadata). **Do not use MCP to set description bodies.**

### Rich comments (REST ADF, not MCP Markdown)

Use REST API v3 with ADF for comments that contain headings, lists, links,
inline code, code blocks, or task items:

```
POST /rest/api/3/issue/{issueKey}/comment
{"body": <adf doc>}

PUT /rest/api/3/issue/{issueKey}/comment/{commentId}
{"body": <adf doc>}
```

Do not send rich comments through MCP Markdown or wiki markup. It can flatten
the content into plain paragraphs or render formatting characters literally.
Use the same ADF node rules as descriptions.

Auth and site base are the same as descriptions (`JIRA_URL` / `JIRA_USERNAME` /
`JIRA_API_TOKEN`).

Keep the description concise and stable. Put detailed execution guidance or a
long agent handoff in one structured ADF comment when it would make the
description unwieldy.

Progress / status / handoff comment **content** (when to post, slice bars,
sections) is owned by [mad-ticket-progress](../mad-ticket-progress/SKILL.md).
This section is write mechanics only.

### Never create validation issues

There is no validate-only Jira issue endpoint. **Never create a temporary
issue** such as `TEST` or `ADF validation` to probe an ADF payload. It consumes
a real key, changes Rank, can notify users, and can pollute a parent or sprint.

On `400` / `INVALID_INPUT`, fix the payload and retry the intended issue. If a
real issue was created with bad formatting, update that issue in place.

After a batch create:

1. Confirm the returned keys exactly match the intended issue list.
2. Search the affected parent/sprint for unexpected test or validation issues.
3. Treat unexpected issues as failed cleanup; report them and remove them only
   with authorization for destructive tracker changes.

### Empty success responses

Jira link, rank, transition, and delete endpoints may return HTTP `204` with no
body. Treat every expected `2xx` status as success; parse JSON only when the
response body is non-empty. Verify the resulting links, Rank, or status with a
read after the write.

### Issue links — Blocks / is blocked by

Use link type `Blocks` so prerequisites show **blocks** dependents, and dependents show **is blocked by** prerequisites.

**Create via REST** (`POST /rest/api/3/issueLink`). For “A blocks B” (A must finish before B) on the configured Jira site, use:

```json
{
  "type": { "name": "Blocks" },
  "inwardIssue": { "key": "A" },
  "outwardIssue": { "key": "B" }
}
```

This is **intentional for this site’s UI**. Do **not** follow the common Atlassian doc example that puts the blocker in `outwardIssue` — that reverses labels in this site’s Linked work items UI.

**Meaning:**

| Intent | `inwardIssue` | `outwardIssue` | UI on A | UI on B |
| --- | --- | --- | --- | --- |
| A blocks B | A (blocker / prerequisite) | B (blocked / dependent) | **blocks** B | **is blocked by** A |

**Verify after create** (do not “fix” from memory or from Atlassian docs alone):

1. Open the prerequisite ticket in UI (or ask the user): Linked work must list dependents under **blocks**.
2. Open a dependent ticket: Linked work must list the prerequisite under **is blocked by**.
3. When reading `GET /rest/api/3/issue/{key}?fields=issuelinks` on this site, map fields to UI as follows (matches this site’s UI; opposite of many Atlassian blog examples):
   - `outwardIssue: Y` on X → UI on X shows **blocks** Y
   - `inwardIssue: Y` on X → UI on X shows **is blocked by** Y
4. If UI is wrong, delete the link (`DELETE /rest/api/3/issueLink/{linkId}`) and recreate with the table above. Do not flip again based on docs without a UI check.

**Do not** invent a second “fix” after a correct UI state. Trust the UI checklist above.

### Rank / backlog order (execution sequence)

**Prefer create order over re-rank.** When creating a set of tickets from scratch, create them **sequentially in the intended execution order** (first ticket first). Jira assigns Rank roughly by creation time, so natural create order usually matches backlog order without a second pass. Do **not** create tickets out of order and plan to fix Rank afterward unless creation order was wrong or the user asks to reorder an existing set.

When the user asks to reorder **existing** tickets (or create order was wrong), set **Rank** via the Agile REST API — not by issue key order alone.

**Endpoint (only this works here):**

```
PUT /rest/agile/1.0/issue/rank
{"issues": ["CPL-1107"], "rankBeforeIssue": "CPL-1106"}
```

or

```
PUT /rest/agile/1.0/issue/rank
{"issues": ["CPL-1107"], "rankAfterIssue": "CPL-1105"}
```

- Use **`PUT /rest/agile/1.0/issue/rank`** with body `issues` + `rankBeforeIssue` / `rankAfterIssue`.
- Do **not** use `POST` to that path (405).
- Do **not** use `PUT /rest/agile/1.0/issue/{key}/rank` (wrong path).

**Reliable procedure** for a desired ordered list `[T1, T2, …, Tn]`:

1. Decide execution order first (dependencies + critical path; independent / nice-to-have last).
2. Apply ranks **from the end of the list toward the start** with `rankBeforeIssue`:
   - For `i` from `n-2` down to `0`: rank `order[i]` **before** `order[i+1]`.
3. Verify with JQL: `key in (...) ORDER BY Rank ASC` (search API). Confirm the printed order matches the intended sequence.
4. If a middle item is still wrong, re-run the backward `rankBeforeIssue` chain; a single `rankAfterIssue` pass alone can leave LexoRank gaps inconsistent.

**Example intent:** contract → skeleton → Redis store → immediate → timestamped/cron → update/cancel → multi-dispatch → iteration depth → replay recovery.

### Updating existing tickets

When reformatting a ticket to match this schema — ADF structure, bold user-story labels, checkboxes, inline code, section headings — **preserve all existing content**. Change formatting only; do not drop, shorten, or rewrite sections, bullets, links, instructions, or acceptance criteria unless the user explicitly asks for content changes.

Before submitting an update, compare the new description against the current issue and confirm every fact, link, and criterion is still present.

### Bug tickets

Use issue type `Bug`. Summary still starts with an action verb — prefer `Fix` (or `Investigate` when root cause is unknown).

Bugs describe a defect, not planned feature work. **Do not require** the Story/Task user-story block. A forced `As a` / `I want` / `So that` often reads fake for regressions, CI breaks, or infra failures.

**When a user story is appropriate for a Bug:** use it only if it states a clear persona, desired restored behavior, and business impact without padding — e.g. “CI must build image X after runner Y changed so merges publish artifacts.” If that formula feels forced, skip it.

**Default Bug description layout** (ADF via REST; omit unused optional sections):

```
<opening — see below>

# Evidence
...
# References
...
# Acceptance Criteria
...
```

**Opening** (starts the description; nothing before it):

1. **Preferred when no natural user story:** 1–3 short paragraphs — what fails, where (env / pipeline / job / component), expected vs actual. Lead with the broken behavior, not a persona.
2. **Optional user story:** only when it fits cleanly (same ADF rules as Stories/Tasks: one paragraph, `strong` labels, `hardBreak` between lines). Example that fits: restoring `master` CI after a runner change so merges publish images. Example that does not: inventing a persona for a null-pointer in a library.

**Evidence** (strongly preferred for Bugs):

- Include failing job/pipeline logs, stack traces, assertions, or repro output under `# Evidence` as an ADF `codeBlock`.
- Prefer full user-provided or investigation-captured output over paraphrase.
- Add brief root-cause bullets after the code block when known (runner change, missing var, bad pin) — keep them factual.

**References:** same rules as other tickets — URL-reachable sources only (failing pipeline, job log, commit that changed behavior, related MR).

**Acceptance Criteria** for Bugs = verifiable fix outcomes, not feature scope. Prefer:

- Failing job/pipeline/path succeeds (or fails for the right reason)
- Root cause addressed (not only a flaky retry)
- Related skipped downstream jobs unblocked when relevant
- Regression signal if useful (re-run on `master`, specific change path)

**Do not** invent epic links for Bugs unless the user asks. Create under the requested project (e.g. `CPL`) with type `Bug` and leave epic/parent unset by default.

### User story at the start of the description (Stories / Tasks)

For Stories, Tasks, and similar feature/work items, the description starts **directly** with the user story formula. Nothing may precede it — no heading, intro, or other content.

For Bugs, see **Bug tickets** — user story is optional and must not be forced.

The three user story lines form **one block** — a single paragraph in Jira. Use exactly one newline (`\n`) between lines. **Never** insert a blank line between them; a blank line becomes `\n\n` in Jira and splits the block into separate paragraphs.

Bold the user story labels exactly as `**As a**`, `**I want**`, and `**So that**`. In ADF, apply the `strong` mark only to the labels.

Each user story line is **one line** — the bold label and its text stay together. **Never** break after the label; do not put `As a` / `I want` / `So that` on a separate line from the rest of that sentence. In ADF: one `hardBreak` only **between** complete lines (after the persona text, after the want text) — never immediately after a `strong` label.

**Correct** (label + text on the same line; single `\n` between lines):

```
**As a** platform engineering team
**I want** Workflow Stage Artifact support in the Artifacts API
**So that** continuous agent pipelines are tracked alongside Data View artifacts
```

**Wrong** — label split from its text (do not submit):

```
**As a**
platform engineering team
**I want**
Workflow Stage Artifact support in the Artifacts API
**So that**
continuous agent pipelines are tracked alongside Data View artifacts
```

**Wrong** — blank lines between lines (do not submit):

```
As a <role / persona>

I want <what should be done>

So that <problem solved / business value>
```

Logical layout (implement in ADF as described above — do not send this Markdown string via MCP):

```
**As a** <role / persona>
**I want** <what should be done>
**So that** <problem solved / business value>

# Evidence
...
# References
...
# Acceptance Criteria
...
```

Use `I want` for a single person or user perspective; `We want` when the ticket concerns a team, system, or broader organizational context.

The formula must answer **why** the work is needed — not only **what** should be done.

### Evidence (warnings, logs, traces)

When the user provides diagnostic output that motivates the ticket — warnings, stack traces, log excerpts, exception dumps, failing assertions, or similar — include it in the description under a level-one heading after the opening (user story for Stories/Tasks, or the Bug problem statement) and before References:

```
# Evidence
```

Paste the **full** user-provided text in an ADF `codeBlock` (do not summarize, truncate, or rephrase). Preserve paths, line numbers, indentation, and wording exactly.

Omit the `Evidence` section when the user did not supply such output.

Do not put multi-line traces only in References or Acceptance Criteria — those sections may cite them, but the raw output belongs under `Evidence`.

### Source links and references

When possible, add a level-one heading after the opening (and after `Evidence`, if present) and before Acceptance Criteria:

```
# References
```

Under the heading, list links and pointers that help a developer understand **why** the ticket exists — not only what to build. Include only items that add context; omit the section if nothing useful is available.

Typical sources:

- Internal or external documentation (specs, ADRs, runbooks, API docs)
- Related Jira/Linear/GitHub issues or merge requests
- Slack threads, incident reports, or postmortems
- Logs, dashboards, or monitoring alerts that surfaced the problem
- Design files (Figma) or product briefs

Use descriptive link text or a short label per item (e.g. `ADR-12: Spark empty-file handling`). One line per reference; no narrative between items.

Only include URL references under `References`. Raw warnings/logs/traces go under `Evidence`, even when they came from chat context rather than a URL.

Do not list the parent ticket or parent item — Jira already links it.

### Acceptance Criteria at the end of the description

At the end of the description, add a level-one heading:

```
# Acceptance Criteria
```

Under the heading, list acceptance criteria as Jira action items (checkboxes). Each line must use `[ ]` with a space inside the brackets — `[]` renders as plain text. Prefix each item with `-`:

```
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
```

Each criterion must be unambiguous and verifiable. Describe the expected outcome, not the implementation — unless implementation details are part of the requirements.

In instructions, references, and acceptance criteria, format every identifier as inline code (`code` mark in ADF): table names, GraphQL types, API paths, env vars, migration names, enum values, etc. Do not leave them as plain text.

### Example of a complete description

```
**As a** data platform engineer
**I want** Spark offloading jobs to skip empty objects instead of failing
**So that** nightly pipelines complete reliably when upstream sends zero-byte files

# Evidence

org.apache.spark.SparkException: Job aborted due to stage failure: empty object at s3://bucket/path/file.parquet

# References

- [INC-4521](https://jira.example.com/browse/INC-4521) — nightly job failed on zero-byte S3 objects
- [Spark offloading runbook](https://wiki.example.com/spark-offload) — current empty-file behavior

# Acceptance Criteria

- [ ] Job processes a batch containing an empty object without error
- [ ] Empty object is logged with source identifier
- [ ] Existing behavior for non-empty objects is unchanged
- [ ] Unit tests cover the empty-object case
```

In ADF, the Evidence body is a `codeBlock` (not a plain paragraph), even when shown as indented text in Markdown examples.

### Example of a Bug description (problem-first, no user story)

```
master pipeline #41 fails on build-hms-image: COPY --chmod requires BuildKit, but the basement runner builds without it. Last good master (#35) used cledar-docker with BuildKit. MR pipelines stay green because they skip image builds.

adls-preview-scripts also fails when spark/** changes: ADLS_ACCOUNT is unset.

# Evidence

COPY --chmod=755 run.sh run.sh
the --chmod option requires BuildKit.
...
ADLS_ACCOUNT: Missing ADLS_ACCOUNT

# References

- Failing master pipeline #41 https://gitlab.example.com/.../pipelines/2737075600
- common-ci basement default https://gitlab.example.com/.../commit/33a7af67

# Acceptance Criteria

- [ ] build-hms-image succeeds on basement
- [ ] adls-preview-scripts has ADLS_* vars or fails open when absent
- [ ] master pipeline touching spark/** and HMS completes without these two failures
```

Use a Bug user story instead of the problem-first opening only when it is natural (persona + restored behavior + impact). Do not rewrite the example above into a user story for its own sake.

### Checklist before creating or updating a ticket

- [ ] Text is in English (unless the user specified otherwise)
- [ ] Summary starts with an action verb (`Implement`, `Check`, `Validate`, `Research`, `Fix`, etc.)
- [ ] Description submitted via REST API v3 as ADF — not via MCP description field
- [ ] Rich comments submitted via REST API v3 as ADF — not MCP Markdown/wiki
- [ ] Description is concise with high information density — no fluff
- [ ] Issue type chosen correctly: `Bug` for defects; Story/Task schema for feature/work items
- [ ] **Stories/Tasks:** description starts with `**As a**...` / `**I want**...` / `**So that**...` with no preceding heading
- [ ] **Stories/Tasks:** user story labels use `strong` marks in ADF; label + text on one line; one ADF paragraph with `hardBreak` between lines; explains business rationale
- [ ] **Bugs:** opening is problem-first (or a natural user story only if it fits — never forced); no epic/parent unless requested
- [ ] **Bugs:** `Evidence` included when logs/traces/repro exist (`codeBlock`, not paraphrased away)
- [ ] If the user supplied warnings/logs/traces: `Evidence` H1 + full verbatim `codeBlock` (not summarized)
- [ ] `References` H1 and linked bullet list present when useful (omitted otherwise)
- [ ] Description ends with `Acceptance Criteria` H1 and `taskList` checkboxes
- [ ] All code-like identifiers use inline code marks (`code` in ADF) — not plain text
- [ ] On updates: all prior description content preserved — styling-only changes unless user requested edits
- [ ] `taskItem` content is inline `text` (no nested `paragraph`)
- [ ] If linking dependencies: `Blocks` created with `inwardIssue`=prerequisite, `outwardIssue`=dependent; UI verified (prerequisite **blocks**, dependent **is blocked by**)
- [ ] If ordering stories: create new tickets in execution order when possible; otherwise Rank via `PUT /rest/agile/1.0/issue/rank` (backward `rankBeforeIssue` chain) and verify with `ORDER BY Rank ASC`
- [ ] No temporary issue was created to validate ADF; batch keys match intent and the affected parent/sprint has no unexpected test issues
- [ ] Empty `2xx` / `204` responses were accepted without JSON parsing and verified with a read
