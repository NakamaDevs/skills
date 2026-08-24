# The Claude auto contract

An envelope's `agent` field always requires non-empty `kind` and `mode`. When
`agent.kind` is `"claude"` and `agent.mode` is `"auto"`, the lane runs
unattended: no human watches each turn before the next one starts. Because no
human is watching, five more fields become required. All five live under
`agent` in the envelope, next to `kind` and `mode`.

## `agent.model` must be a current supported model

`agent.model` must be one of the model IDs currently supported for this
work:

- `claude-fable-5`
- `claude-opus-5`
- `claude-sonnet-5`
- `claude-haiku-4-5-20251001`

Reject an envelope naming a retired model (for example an old dated Sonnet or
Opus snapshot). Update `@supported_claude_models` in
[`scripts/lane_task_envelope.exs`](../scripts/lane_task_envelope.exs) and
[model-routing.md](model-routing.md) when the supported model list changes;
do not let this reference drift from the validator.

## `agent.effort` must match the model's effort set

Effort sets are model-specific:

- `claude-fable-5`, `claude-sonnet-5`, `claude-opus-5`: one of `auto`,
  `low`, `medium`, `high`, `xhigh`, or `max`. `auto` resets effort to the
  model's default; it does not pick a level per turn and is not a
  token-saving promise.
- `claude-haiku-4-5-20251001`: exactly `not-supported`. Haiku has no effort
  control, and the envelope must say so explicitly; an ordinary level on
  Haiku is rejected with "`agent.effort` must be \"not-supported\" for
  claude-haiku-4-5-20251001, which does not support effort". The sentinel
  is rejected on every other model.

Model and effort are separate choices, and `agent.effort` is unrelated to
`agent.permission_mode` below even though both can be `"auto"`. Prefer
`auto` when no measured evidence exists for this task shape; use an explicit
higher effort only for a measured quality need. The Codex-only value `none`
is rejected here. See [model-routing.md](model-routing.md).

## `agent.routing_reason` must state why

`agent.routing_reason` is a string that is non-empty after trimming
whitespace (a whitespace-only value is rejected) and says why this model and
effort were chosen: the task shape, whether measured evidence exists, and
what that evidence showed. It is the one place a later audit can see whether
a route was a default or a measured decision.

## `agent.permission_mode` must be `"auto"`

`agent.permission_mode` must equal the string `"auto"` exactly. This makes
the unattended posture explicit in the envelope itself, rather than leaving
it to be inferred from `agent.mode`. An envelope that pairs
`agent.mode: "auto"` with any other permission mode fails validation.

## `agent.startup_verification` must be `"visible"`

`agent.startup_verification` must equal the string `"visible"`. An
unattended Claude lane must announce, in output a human can later read, that
it started, which model and permission mode it is running under, and that it
read this envelope. `"visible"` means that announcement is not suppressed or
silent; it is the one place a human (or a later audit) confirms the run
actually started under the contract it claims.

## When these fields are not required

A `kind: "claude"` agent running in any `mode` other than `"auto"` (for
example a supervised or interactive mode) does not need `model`, `effort`,
`routing_reason`, `permission_mode`, or `startup_verification` at all. Those
fields may be absent. A non-Claude `kind` is never subject to this section;
an automated Codex role has its own model, effort, and routing_reason rules
in [envelope-fields.md](envelope-fields.md#agent-and-the-claude-auto-contract).
