# The Claude auto contract

An envelope's `agent` field always requires non-empty `kind` and `mode`. When
`agent.kind` is `"claude"` and `agent.mode` is `"auto"`, the lane runs
unattended: no human watches each turn before the next one starts. Because no
human is watching, three more fields become required. All three live under
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
[`scripts/lane_task_envelope.exs`](../scripts/lane_task_envelope.exs) when
the supported model list changes; do not let this reference drift from the
validator.

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
example a supervised or interactive mode) does not need `model`,
`permission_mode`, or `startup_verification` at all. Those fields may be
absent. A non-Claude `kind` is never subject to this section.
