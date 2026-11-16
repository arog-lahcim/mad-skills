---
name: mad-guided-review
description: >-
  Use only when the user explicitly asks to run mad-guided-review by name.
  Do not use it because a document, link, paste, or discussion request appeared.
---

# Guided review

Read one source, one fragment at a time, and wait. This skill never starts by itself.

## When to use

Run only after the user asks for `mad-guided-review` by name. A linked document, a pasted source, or a request to discuss a text is not a request to run this skill. Do not begin a read-through because it would be helpful.

## Each step

Reply in the language the user is using.

Cover one fragment, about half a page. Stop on a heading or another natural break. Do not preview later fragments in the same reply.

Shape the reply like this:

1. A numbered step heading.
2. A blank line.
3. A locator: the section or heading this fragment comes from.
4. A short explanation.
5. A diagram only when it makes that fragment clearer.
6. The source link at the end. Follow [mad-visible-links](../mad-visible-links/SKILL.md).

Add a warning only when that fragment shows a concrete problem.

`dalej` means the same as `Next`.

## Leave the source unchanged

Do not edit the source: not its body, changelog, or an existing diagram or table. The source stays unchanged until a separate, accepted plan says otherwise.

A table, diagram, question, or wording the user wants kept is a proposal in one plan for this read-through. Do not post it until the user accepts that plan.

While that plan is still being drafted, or only some of its todos are done, update that file. Do not create another plan file for the same read-through. If a tool creates a new file anyway, move the new content into the existing plan in the same turn and write at the top of the new file that it is superseded and which file replaced it.

After the plan has been fully executed and the user adds more, ask once whether to extend that plan or start a new plan. Use the question tool. Do not choose automatically. While the user is still adding to a plan they chose to extend, keep updating that file. Ask again only when that same plan has been fully executed once more and the user starts adding to it again. A partial execution followed by more additions keeps the current plan.

## Discussion comments

When a proposal will be posted as a discussion comment:

- The comment body starts with the suggestion or the question. It does not open with a statement that the comment does not change the page.
- An anchor is a unique contiguous slice of the stored sentence. Ten characters from the start are not enough when that prefix also appears elsewhere.
- A word inside a code span is anchored as stored, including the code markup, because the stored text is not the plain sentence.
- A slice that relies on parentheses can be read as a pattern. Prefer a unique slice that still identifies the sentence.
- If the slice matches more than once or is not found, lengthen it, or use the next unique sentence in the same paragraph, and say where it landed. Do not post an unanchored comment.
- Replacing a comment replaces the whole body. Send the original markdown, not the rendered form.

## Buttons

Buttons are an extra control. The read-through does not depend on them.

Look for a connected tool named `show_buttons`. Inspect its schema, then call it after the written reply. Do not install it, configure it, or describe where it lives. Do not name an owner, product, repository, host, config key, or address for it.

When the tool is available, send:

- **Next** on every fragment except the last. Label `Next`, message `Next`. Advance one fragment.
- **Skip** on every fragment except the last. Label `Skip`, message `Skip this section`. Advance without recording a proposal.
- **Add to plan** only when this step offered a concrete proposal. Label `Add to plan`, message `Add this step's proposal to the plan.`

On the last fragment, say the source is finished and omit Next and Skip. Send Add to plan only when a proposal is still open. Send no buttons when nothing was proposed.

There is no Implement button. Starting implementation stays a separate request.

A click arrives as a normal user message. Obey that message: `Next` advances, `Skip this section` advances without recording, and `Add this step's proposal to the plan.` appends the proposal to the current plan and does not edit the source.

### When the tool is missing

On the first step only, if `show_buttons` is not connected or the call fails, add one plain sentence and then continue the text walkthrough.

- Polish reply: `Serwer przycisków nie działa. Napisz dalej.`
- English reply: `The button server is not working. Write Next to continue.`

Later steps do not mention the button server again unless the user asks. Typing `Next` or `dalej` still advances.
