---
name: mad-ticket-split
description: >-
  Use when splitting remaining work into follow-up tickets, separating a large
  story by delivery concern, or deciding whether a parent can close.
---

# Ticket Split

Split work by independently deliverable outcomes, not by bullet count. Keep the
parent status truthful: close delivered scope and track distinct continuation
explicitly instead of using one long-running umbrella ticket.

**REQUIRED SUB-SKILL:** Use `mad-jira-tickets` for ticket content, ADF,
dependencies, ranking, and tracker mutations. This skill owns scope policy only.

## Evidence First

Before splitting, inspect:

- parent description and acceptance criteria;
- plans, ADRs, operational docs, merged changes, and deployment state;
- existing related tickets and dependency links.

A plan heading or documentation navigation entry is not implementation status.
Use explicit status text and operational evidence. If the boundary between
delivered and remaining scope is unclear, ask one focused question.

## Classify Each Remaining Item

| Class | Action |
|---|---|
| Same concern, same code path, required by current AC | Finish on the parent |
| Distinct layer, repository, owner, release unit, or risk | Create a dependent ticket |
| Optional improvement, backfill, hardening, or tooling | Create a non-blocking follow-up |
| Duplicate of existing work | Link the existing ticket |
| Speculative idea without a verifiable outcome | Do not create a ticket yet |

Do not create one ticket per review bullet. Group changes that should be
implemented, reviewed, deployed, and rolled back together.

## Decide Parent Status

Close the parent when all of these are true:

1. Its agreed core outcome is delivered and verified on the target environment.
2. Any unmet original criteria have been explicitly moved to linked tickets;
   the parent scope or closing comment makes that transfer visible.
3. Remaining items are independently actionable and do not make the delivered
   outcome false.

Keep the parent open when a remaining defect is on the same path, required by
its current acceptance criteria, or prevents the promised outcome from working.
Do not keep a delivered parent open merely as a dashboard for unrelated work.

## Link and Order

- A prerequisite **blocks** its dependent.
- If a dependent requires the parent's delivered outcome, the parent
  **blocks** that ticket even after the parent is resolved. Resolution satisfies
  the dependency; it does not turn the relationship into **relates to**.
- Optional follow-ups **relate to** the parent; they do not block closure.
- Rank the critical dependency chain first. Put independent documentation in
  parallel and optional hardening later.
- Verify link direction and final order using `mad-jira-tickets`.

## Public Ticket Language

Summaries and acceptance criteria describe outcomes, not planning mechanics.
Use layer or capability names such as API, UI, end-to-end verification, or
documentation. Do not expose labels such as `Slice 4`, `Phase 3`, or `Future`
unless the user explicitly wants those labels in public tracker text.

## Closing Handoff

When closing the parent, add a concise comment:

- delivered outcome and verification state;
- linked required continuation tickets;
- linked optional follow-ups;
- the higher-level epic or initiative that tracks the complete program.

Then transition the parent only after the user authorizes external changes.
