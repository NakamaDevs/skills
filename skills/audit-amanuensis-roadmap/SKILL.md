---
name: audit-amanuensis-roadmap
description: Audit docs/ROADMAP.md against Amanuensis implementation, tests, documentation, workflows, and recent history. Use when checking whether roadmap completion markers are current, reconciling delivered work with planned work, reviewing roadmap drift before a release or planning session, or updating roadmap status from repository evidence.
---

# Audit the Amanuensis roadmap

Verify roadmap claims from evidence in the current default branch. Treat a checked item as a claim, not as proof.

## Prepare

1. Read `AGENTS.md`, `.governance/engineering-v1.md`, and `docs/ROADMAP.md`.
2. Confirm the default branch is current. Preserve unrelated work by using an isolated worktree when necessary.
3. Run `python .agents/skills/audit-amanuensis-roadmap/scripts/roadmap_inventory.py docs/ROADMAP.md` to inventory every checkbox and its line number.
4. Find the most recent roadmap change with `git log -1 --format=%H -- docs/ROADMAP.md`, then inspect product and infrastructure changes after it.

## Verify

For each item affected by recent changes, and for any suspicious existing claim, inspect the implementation plus the strongest available corroboration:

- shared behavior: `app/lib`, `app/test`, and `app/integration_test`;
- macOS behavior: `app/macos`, native tests, permissions, and packaging;
- Windows behavior: `app/windows`, native tests, lifecycle, and packaging;
- delivery behavior: `.github`, `mise.toml`, release artifacts, and runner documentation;
- durable product decisions: architecture docs, tests, and relevant commit history.

Classify each reviewed item as `verified`, `implemented-but-open`, `checked-without-evidence`, `planned`, or `ambiguous`. Do not mark manual device, meeting-client, permission, release, or cross-platform validation complete solely because an automated test exists. Do not mark exploratory work complete because a production-adjacent component exists.

## Update

1. Make the smallest evidence-backed roadmap edit.
2. Preserve the roadmap's Spanish language, intent, section ordering, and distinction between committed work and later backlog.
3. Turn status-bearing prose lists into checklists when completion otherwise remains invisible.
4. Keep unresolved or partially delivered work open and state a decision or residual gap when that prevents false confidence.
5. Avoid implementation details that will age faster than the product decision.

## Report

Report:

- stale claims corrected;
- completed work newly reflected;
- open items deliberately left open and why;
- evidence inspected and validation run;
- ambiguities that require a product or manual-validation decision.

If no changes are warranted, say that the roadmap is current and cite the evidence reviewed instead of manufacturing an edit.
