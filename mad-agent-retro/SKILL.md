---
name: mad-agent-retro
description: >-
  Use when the user asks for a retrospective, lessons learned, conclusions
  from agent-assisted work, or reusable rules and skill improvements.
---

# Agent Work Retrospective

Turn evidence from completed or paused agent-assisted work into reusable
guidance. Separate process failures from missing guidance: a rule that already
existed but was skipped needs enforcement or clearer triggering, not a duplicate.

## Boundaries

- Do not run after every merge, ticket transition, or status request.
- Analyze first. Do not edit skills or rules in the same turn.
- Keep incident identifiers and organization-specific paths in the analysis,
  not in reusable skill or rule proposals.
- This is not code review, ticket splitting, or project agent documentation.

## Evidence Pass

1. Establish the scope: conversation, plan, tickets, repositories, and delivery
   window. Ask one focused question only when the scope cannot be inferred.
2. Inspect available read-only evidence: transcript/plan; git, merge requests,
   pipelines and deployment; ticket content/status; existing skills and rules.
3. Do not state uncertain recollections as findings. Label unavailable evidence
   and explain what would confirm it.
4. Search existing guidance before proposing new guidance.

## Classify Findings

Use these four buckets:

1. **Worked well** - behavior worth repeating, tied to an observed outcome.
2. **Failed under pressure** - symptom, root cause, and impact.
3. **Already covered but violated** - existing skill/rule and why it did not
   prevent the failure.
4. **True guidance gap** - reusable behavior not covered anywhere.

Do not turn a one-off implementation detail into a global rule. Prefer a small
patch to the owning skill over a competing always-on rule.

## Response Contract

Lead with concise findings in the user's language. Use progress bars only when
the work had explicit phases or slices and the active rules require them.

Default shape:

1. **Evidence status** - one short paragraph; name unavailable sources.
2. **Findings** - at most eight bullets across the four classification buckets.
3. **Proposed patches** - only evidence-backed changes; omit when none qualify.
4. **Next step** - one sentence offering an isolated worktree.

Do not restate the whole implementation history or the skill's method.

For each proposed patch include:

| Field | Required content |
|---|---|
| Target | Existing skill/rule or a justified new skill/rule |
| Change | Exact section and 1-3 sentences of proposed guidance |
| Evidence | Concrete incident behavior that motivates it |
| Why here | Ownership reason; note overlaps avoided |

For each proposal, distinguish:

- **Edit existing guidance** - the topic already has an owner.
- **Create new skill** - a reusable judgment workflow has no owner.
- **Create rule** - short standing context must apply broadly.
- **Automate** - a mechanical constraint is better enforced by validation.

End by offering to apply the proposed patches in an isolated worktree. Stop
without editing, committing, pushing, or opening a pull request until asked.
