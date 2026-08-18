---
name: nakama-write-plain-language
description: Write NakamaDevs prose in ASD-STE100 Simplified Technical English. Use for documentation, README files, commit messages, pull request titles and descriptions, Linear issues, release notes, Discord and feed posts, handoff documents, and error messages. Apply when the reader is non-native, non-technical, or reading under time pressure, and when the text will be translated.
---

# Nakama Write Plain Language

Apply the organization communication standard in
[`governance/communication-v1.md`](../../../../governance/communication-v1.md).
Write so the reader understands the text one time, at reading speed.

## Rules

- Use the active voice. Name the actor.
- Keep sentences to 20 words or fewer.
- Give one idea in each sentence.
- Use simple tenses: present, past, and future.
- Use the same word for the same idea each time. Do not use synonyms for variety.
- Do not use idioms, slang, or jargon.
- Keep paragraphs to 6 sentences or fewer.
- Keep one instruction in each step of a procedure.
- Write the condition before the action.
- Put a warning before the step it applies to.
- Prefer the short common word: "use" not "utilize", "start" not "initiate".
- Do not stack more than three nouns together.
- Remove filler: "in order to", "it should be noted that", "basically", "simply".

## Technical items stay exact

Reproduce these without change, translation, rounding, or paraphrase:

- file paths, directory names, and URLs;
- function, class, module, variable, and column names;
- commands, flags, and configuration keys;
- error messages and status codes;
- numbers, prices, versions, dates, and identifiers.

Simplify the prose around the technical item. Never the item itself.

## Accuracy wins

The standard controls form, not honesty or depth.

- Do not drop a limitation, risk, or failure to make a sentence shorter.
- Do not raise confidence because hedging costs words. "The test failed." and
  "I did not test this." are both short and true.
- Do not remove a necessary technical detail. Split it into another sentence.

Break the 20-word limit rather than write something untrue.

## Other languages

The rules describe plain writing, not English grammar. Keep the same discipline
in Spanish and any other language: active voice, short sentences, one idea for
each sentence, one word for each concept, no idioms, exact technical items. The
ASD-STE100 approved-word list is English-only. The structural rules are not.

## Check before you publish

1. Every sentence is 20 words or fewer, or it has a reason.
2. Every sentence is active, or the actor is genuinely unknown.
3. Each concept uses one word through the whole text.
4. No idiom, no slang, no filler.
5. Every path, name, number, and price is unchanged.
6. Nothing true was removed to save words.

## Example

Before:

> It should be noted that in the event that the aforementioned deployment
> pipeline has been triggered without the requisite approval having been
> obtained, the job will subsequently be terminated by the system.

After:

> The system stops the job if the deployment starts without approval.
