---
name: resolve-pr-review-threads
description: Audit, validate, address, reply to, and resolve unresolved GitHub pull-request review threads. Use when preparing a PR for merge, responding to Codex or human inline findings, checking whether review feedback is still current, or verifying that every conversation is resolved.
---

# Resolve PR review threads

## Prepare

1. Read `AGENTS.md`, resolve the current PR, and confirm the authenticated GitHub account.
2. Fetch PR metadata and the base/head diff. Fetch thread-aware review state with
   `reviewThreads`, including each thread ID, resolution state, outdated state,
   path, line, author, and full comment chain. Do not treat flat comments as a
   complete thread inventory.
3. List every unresolved thread before editing and group duplicates by behavior.

## Validate

For each unresolved finding, inspect the current head, nearby implementation,
tests, documentation, and relevant base-branch behavior. Classify it as:

- **valid** — the failure mode exists on the current head;
- **false positive** — the claimed failure does not occur, with concrete evidence;
- **outdated** — later commits already removed the failure;
- **ambiguous** — intent or the safe fix requires clarification.

Never accept generated feedback blindly, but never dismiss it without checking
the cited behavior. Report the classification and evidence before changing code.

## Address

1. Fix every valid finding with the smallest cohesive change and add or update
   regression coverage when behavior changed.
2. Run the narrow check, then the repository's required aggregate validation.
3. Review the final diff and push the validated commit before replying.
4. Reply in each thread with its disposition, rationale, validation evidence,
   and fixing commit when applicable. For false positives or outdated findings,
   explain the verified evidence instead of manufacturing a code change.
5. Resolve a thread only after its fix is present on the remote PR head or its
   non-code disposition is fully documented. Leave ambiguous threads open.

Use GitHub's `addPullRequestReviewThreadReply` and `resolveReviewThread`
GraphQL mutations, or equivalent thread-aware tooling. Never resolve through a
flat comment API that loses thread identity.

## Finish

Refetch thread-aware state and verify that no addressed thread remains open and
that no new unresolved thread appeared. Post one concise top-level PR comment
listing every reviewed finding, its disposition, commits, checks, remaining
threads, and residual risk. Do not approve your own PR. Keep credentials,
unredacted scanner output, and sensitive data out of comments and command logs.
