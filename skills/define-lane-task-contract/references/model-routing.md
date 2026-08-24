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
| `claude` | `claude-haiku-4-5-20251001` | Efficient, high volume. |

A retired or dated snapshot outside this table fails validation for either
provider.

## Model and effort are separate choices

`agent.model` picks *which* model runs the lane. `agent.effort` picks *how
much reasoning* that model spends per turn. Choose them independently; a
balanced model at high effort and a frontier model at low effort are both
valid routes, and neither substitutes for the other.

| Provider | `agent.effort` values |
| --- | --- |
| `claude` | `auto`, `low`, `medium`, `high`, `xhigh`, `max` |
| `codex` | `none`, `low`, `medium`, `high`, `xhigh`, `max` |

`auto` exists only for Claude and lets the model choose its own effort per
turn. `none` exists only for Codex. Each value is rejected for the other
provider.

## Routing rules

1. **Prefer Claude `auto` when no measured evidence exists.** A new lane, or
   a lane whose task shape has not been measured before, starts as
   `kind: "claude"` with `effort: "auto"` (the model in the example envelope
   is `claude-sonnet-5`). Do not pre-pay for effort you cannot yet justify.
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
4. **`agent.routing_reason` states the evidence.** One non-empty sentence:
   the task shape, whether measured evidence exists, and why this model and
   effort follow from it. "no measured evidence; Claude auto default" is a
   complete and honest reason.

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
