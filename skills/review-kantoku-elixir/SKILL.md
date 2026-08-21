---
name: review-kantoku-elixir
description: Review Kantoku Discord Manager changes in Elixir, Phoenix, Ash, Ecto/PostgreSQL, Nostrum, and Oban. Use when a diff touches discord_manager or changes Discord events, jobs, resources, policies, persistence, or the Phoenix API.
---

# Review Kantoku Elixir

1. Read the root and `discord_manager/AGENTS.md`, the Linear issue, and final base/head diff.
2. Trace behavior through Ash resources/actions/policies, Ecto constraints/migrations, Phoenix boundaries, Nostrum events, and Oban jobs.
3. Check supervision, process ownership, retries, timeouts, duplicate events, rate limits, authorization, and secret/log redaction.
4. Reject blocking work in GenServers/request processes; require bounded external calls and visible failure.
5. Verify query cardinality, transactions, preload behavior, migration compatibility/rollback, and idempotency.
6. Expect focused ExUnit coverage for success, rejection, retry, duplicate, and concurrent paths plus the repository aggregate checks.
7. Report findings by severity with file/location, failure mode, impact, and fix; otherwise state no findings and residual risk.
