---
tracker:
  kind: linear
  provider:
    api_key: $LINEAR_API_KEY
    project_slug: "codex-skills"
  required_labels:
    - "symphony-pilot"
  active_states:
    - "In Progress"
  terminal_states:
    - "Done"
    - "Canceled"
    - "Duplicate"
polling:
  interval_ms: 30000
workspace:
  root: $SYMPHONY_WORKSPACE_ROOT
hooks:
  after_create: |
    "$SYMPHONY_GIT_BROKER" prepare-workspace
  before_run: |
    "$SYMPHONY_GIT_BROKER" verify-workspace
  before_remove: |
    "$SYMPHONY_GIT_BROKER" release-workspace
  timeout_ms: 60000
agent:
  max_concurrent_agents: 1
  max_turns: 8
  max_retry_backoff_ms: 60000
codex:
  command: codex app-server
  approval_policy:
    reject:
      sandbox_approval: true
      rules: true
      mcp_elicitations: true
  thread_sandbox: workspace-write
  turn_sandbox_policy:
    type: workspaceWrite
    networkAccess: false
  turn_timeout_ms: 1800000
  read_timeout_ms: 5000
  stall_timeout_ms: 120000
---

Work on {{ issue.identifier }} and stop at human review.
