# Readiness report

Use this report only after you read the canonical Kaicho controls.

## Identity

- Repository:
- Target revision:
- Default branch:
- Governance source and revision:
- Host and date:
- Working tree state:

## Repository adoption evidence

| Requirement | Status | Evidence | Gap or risk |
| --- | --- | --- | --- |
| Repository profile and governance version | | | |
| Protected default branch and code-owner review | | | |
| Repository-owned quality commands | | | |
| Supply-chain and secret checks | | | |
| Agent-ready declaration | | | |

## Harness evidence

| Control | Status | Command or file | Exact result | Owner |
| --- | --- | --- | --- | --- |
| C1 Repository knowledge | | | | |
| C2 Architecture invariants | | | | |
| C3 Validation | | | | |

For C3, list every validation rung in order. Record the first failure and stop
the ladder there.

## Decision

Select one result:

- `ready`: all local entry evidence passes at the target revision.
- `not ready`: one or more required checks fail.
- `unverified`: required evidence is unavailable or needs external access.

List blocking gaps before recommendations. Do not declare pilot authorization.
Controls C4 through C11 have a separate gate.
