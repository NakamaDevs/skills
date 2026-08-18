---
name: review-docs-change
description: Review a change to the NakamaDevs docs repository. Use for pull-request review, pre-push review, and any check that documentation is correct, current, and in the organization communication standard.
---

# Review Docs Change

This repository holds documentation. A defect here is a reader who acts on
text that is wrong, stale, or unclear. Review for that.

## Check the content first

1. Verify every factual claim against the source. Open the repository, the
   file, or the command the text describes. Do not accept a claim because it
   reads well.
2. Verify every path, command, flag, and identifier by running or locating it.
   A stale command is the most common defect in a documentation repository.
3. Verify every link resolves. Check relative links from the file's own
   directory.
4. Confirm the text states its own scope. A reader must learn early whether the
   page applies to them.
5. Confirm nothing here belongs in Kaicho. If the change creates a rule people
   must follow, it is policy, and it belongs in Kaicho instead.
6. Confirm no credential, token, private URL, or personal identifier appears.
   Examples use placeholders.

## Then check the writing

Apply [the communication contract](https://github.com/NakamaDevs/Kaicho/blob/main/governance/communication-v1.md).

1. Every sentence is 20 words or fewer, or it has a reason.
2. Every sentence is active, or the actor is genuinely unknown.
3. Each concept uses one word through the whole text.
4. No idiom, no slang, no filler.
5. Every path, name, number, and price is unchanged.
6. Nothing true was removed to save words.

Request a rewrite when the prose fails. Do not rewrite it silently in review.

## Gates

Run `mise run verify`. It runs the governance self-test, the complete-history
secret scan, and `actionlint`.
