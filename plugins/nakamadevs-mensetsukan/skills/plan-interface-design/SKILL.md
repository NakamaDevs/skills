---
name: plan-interface-design
description: Define an interface's users, jobs, flows, states, constraints, and acceptance evidence before planning implementation. Use when planning or changing an editor, presenter, candidate view, web page, form, navigation flow, responsive layout, or other visual interaction; use OpenPencil as the preferred design-artifact tool when available.
---

# Plan Interface Design

Establish what the interface must do before choosing components or implementation details. Keep planning read-only unless the user explicitly asks to create or edit a design artifact.

## Start with intent

1. Read `AGENTS.md`, relevant product documentation, and nearby interface code.
2. Identify the actor, job to be done, entry point, primary action, completion condition, and next actionable step.
3. Separate facts from assumptions. Ask only about choices that materially change the interface and cannot be discovered locally.
4. Describe the smallest coherent user flow before drawing screens.

For Mensetsukan, preserve interviewer ownership of identity, ratings, notes, and detailed timing. Keep candidate-visible state intentionally limited. Preserve browser Back and Forward behavior, Restart semantics, and full- and half-screen usability.

## Specify the behavioral surface

Cover every applicable state:

- initial, empty, loading, and ready
- focused, selected, edited, and unsaved
- invalid, blocked, recoverable error, and fatal error
- success, completion, restart, and return
- narrow viewport, long content, keyboard navigation, and reduced motion

Record for each state: trigger, visible information, available actions, protected/private information, and transition out.

## Use OpenPencil for artifacts

Read `.agents/skills/open-pencil/SKILL.md` completely before using OpenPencil. Use it after the flow and state model are explicit.

- Inspect an existing `.fig` file or running editor before changing it.
- Prefer a low-fidelity flow or component-state board before polished screens.
- Reuse discovered tokens and components; do not invent a parallel design system.
- Export or render evidence only when the user authorizes artifact creation.
- Treat OpenPencil lint and visual exports as evidence, not proof that the interaction is correct.

If OpenPencil tooling is unavailable, produce the same behavioral specification and identify the missing artifact step. Do not silently substitute an unrelated design tool.

## Hand off to TDD planning

End with observable acceptance cases, not implementation tasks. Include:

- primary user flow
- alternate and error flows
- state restoration and reset behavior
- privacy boundaries
- responsive and keyboard expectations
- evidence needed from automated tests and rendered/manual verification

Then invoke `plan-tdd` to turn those cases into RED-GREEN-REFACTOR work. For interface changes, this interface-intent pass precedes the TDD test matrix; for non-interface work, `plan-tdd` is the first planning gate.

## Output

Return a compact interface brief with: actors and jobs, flow, state table, constraints, acceptance cases, OpenPencil artifact status, assumptions, and unresolved decisions.
