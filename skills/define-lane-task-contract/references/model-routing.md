# Model routing

Every automated Claude or Codex lane (`agent.mode == "auto"`) names three
routing choices in its envelope: `agent.model`, `agent.effort`, and
`agent.routing_reason`. The validator enforces the vocabulary; this document
is the policy behind it.

This is **user policy for this workspace, not an official cross-provider
benchmark**. Neither vendor publishes a comparison against the other, and
this document does not claim one. Official sources retrieved 2026-08-24:

- OpenAI, "Latest model": <https://developers.openai.com/api/docs/guides/latest-model>
- Anthropic, Claude Code "Model configuration": <https://code.claude.com/docs/en/model-config>

Update this file, [`claude-auto-contract.md`](claude-auto-contract.md), and
the `@supported_*` / `@*_efforts` attributes in
[`scripts/lane_task_envelope.exs`](../scripts/lane_task_envelope.exs)
together; do not let any of them drift.

## Supported models

| Provider (`agent.kind`) | `agent.model` | Tier |
| --- | --- | --- |
| `codex` | `gpt-5.6-sol` | Frontier: the most capable Codex model; use for the hardest reasoning and the highest measured quality need. |
| `codex` | `gpt-5.6-terra` | Balanced: default capability, latency, and cost for ordinary implementation lanes. |
| `codex` | `gpt-5.6-luna` | Efficient, high volume: many short, bounded, or mechanical lanes where latency and tokens matter more than peak reasoning. |
| `claude` | `claude-fable-5` | Workspace frontier model. For routing in this workspace it is treated as **at least equal to Sol** (user policy, see above). |
| `claude` | `claude-opus-5` | High capability below Fable 5. |
| `claude` | `claude-sonnet-5` | Balanced default for ordinary implementation lanes. |
| `claude` | `claude-haiku-4-5-20251001` | Efficient, high volume. Does not support effort; its `agent.effort` must be the sentinel `not-supported`. |

A retired or dated snapshot outside this table fails validation for either
provider.

## Model and effort are separate choices

`agent.model` picks *which* model runs the lane. `agent.effort` picks *how
much reasoning* that model spends per turn. Choose them independently; a
balanced model at high effort and a frontier model at low effort are both
valid routes, and neither substitutes for the other.

| Provider / model | `agent.effort` values |
| --- | --- |
| `claude` — `claude-fable-5`, `claude-sonnet-5`, `claude-opus-5` | `auto`, `low`, `medium`, `high`, `xhigh`, `max` |
| `claude` — `claude-haiku-4-5-20251001` | `not-supported` only |
| `codex` — every model | `none`, `low`, `medium`, `high`, `xhigh`, `max` |

Claude effort sets are model-specific. Haiku 4.5 has no effort control; the
envelope still has to say so explicitly with the sentinel `not-supported`,
and an ordinary level (`auto`, `low`, ..., `max`) on Haiku is rejected
rather than silently ignored. `none` exists only for Codex. Each value is
rejected for the other provider.

### What Claude `auto` means

Claude `auto` **resets effort to the model's default**. It is not a mode
where the model chooses an effort level per turn, and it is not a promise to
save tokens. Adaptive reasoning — the model deciding how much to think on a
given turn — works *within* the effective effort level, whatever that level
is (the default under `auto`, or the explicit level you set). Setting a
higher explicit level raises the ceiling adaptive reasoning works under; it
does not turn adaptive reasoning off.

### `permission_mode` is not effort

`agent.permission_mode: "auto"` (see
[claude-auto-contract.md](claude-auto-contract.md)) is an unattended
*permission* posture — which tool calls run without a human answering. It
is unrelated to `agent.effort: "auto"`, which is a *reasoning* setting. The
two share a word and nothing else, and neither implies the other.
`permission_mode: "auto"` is required only for automated **Claude** lanes.
An automated **Codex** lane requires `model`, `effort`, `routing_reason`,
and `command` under its existing contract in
[envelope-fields.md](envelope-fields.md#agent-and-the-claude-auto-contract);
it has no `permission_mode` field.

## Routing rules

1. **Prefer Claude `auto` when no measured evidence exists.** A new lane, or
   a lane whose task shape has not been measured before, starts as
   `kind: "claude"` on an effort-supporting model with `effort: "auto"` —
   that is, the model's default effort (the example envelope uses
   `claude-sonnet-5`). Do not pre-pay for effort you cannot yet justify. On
   Haiku, the only value is `not-supported`, so this rule does not apply.
2. **Use an explicit higher effort only for a measured quality need.** Move
   to `high`, `xhigh`, or `max` (either provider) only when a previous run of
   the same task shape recorded a quality shortfall at the lower setting —
   rework, a failed gate, or a human intervention that a stronger setting is
   expected to remove. Say which measurement in `routing_reason`.
3. **Route by tier, not by name.** Pick frontier (`gpt-5.6-sol`,
   `claude-fable-5`) for the hardest reasoning, balanced (`gpt-5.6-terra`,
   `claude-sonnet-5`) for ordinary implementation, and efficient
   (`gpt-5.6-luna`, `claude-haiku-4-5-20251001`) for high-volume bounded
   work.
4. **`agent.routing_reason` states the evidence.** One sentence that is
   non-empty after trimming whitespace:
   the task shape, whether measured evidence exists, and why this model and
   effort follow from it. "no measured evidence; Claude auto default" is a
   complete and honest reason.

## Default lane matrix

The coordinator starts with this matrix. It can use another route when
`agent.routing_reason` names measured evidence for the change.

| Task shape | Codex route | Claude route |
| --- | --- | --- |
| Link, version, inventory, or source check | `gpt-5.6-luna`, `low` | `claude-haiku-4-5-20251001`, `not-supported` |
| Mechanical edit with exact tests | `gpt-5.6-luna`, `medium` | `claude-sonnet-5`, `auto` |
| Routine coordinator or implementation lane | `gpt-5.6-terra`, `medium` | `claude-sonnet-5`, `auto` |
| Exact-head review or integration diagnosis | `gpt-5.6-terra`, `high` | `claude-fable-5`, `auto` |
| Difficult architecture, concurrency, security, or policy work | `gpt-5.6-sol`, `high` | `claude-fable-5`, `high` |
| Unresolved quality-critical work after a failed frontier run | `gpt-5.6-sol`, `xhigh` | `claude-fable-5`, `xhigh` |

Use Codex `none` only for a proven transformation without tool judgment. Use
`low` when a fast task still needs tools or several steps.

Use Luna agents for parallel discovery. Use Terra agents for most writers and
reviewers. Keep Sol capacity available for hard defects and architecture.

For an escalation, change the model or the effort first. Do not change both at
the same time. The next measurement then shows which change helped.

Do not replace a healthy active agent only to change its route. Preserve its
context unless measured evidence supports replacement.

## Record what the route cost

After every automated lane, record these five measurements next to its
result (in the lane's `red_evidence`/`green_evidence`, a worklog entry, or
the coordinator's own notes — not in Linear):

- **quality** — did the observable goal hold, and did every gate pass on the
  first handoff?
- **latency** — wall-clock time from start to handoff.
- **tokens** — input and output tokens the lane consumed.
- **rework** — how many red/green cycles or re-prompts the lane needed
  beyond the first.
- **human intervention** — how many times a human had to answer, unblock,
  or correct the lane.

These records are the "measured evidence" rules 1 and 2 refer to. A change
of model or effort for a task shape should point at them.
