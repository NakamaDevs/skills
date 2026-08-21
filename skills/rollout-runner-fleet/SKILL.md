---
name: rollout-runner-fleet
description: Plan and execute staged NakamaDevs Runner Fleet repairs and upgrades using a local canary followed by one-at-a-time SSH host updates. Use for runner bootstrap changes, runner version upgrades, service repair, label or group changes, host migrations, PR #7 follow-up, or fleet rollout and rollback verification.
---

# Roll out Runner Fleet

Use the checked-in topology and Mise tasks. Keep the candidate revision,
credentials, runner runtime directories, and host trust boundaries explicit.

## Prepare

1. Read `AGENTS.md`, `README.md`, `SECURITY.md`, `docs/OPERATIONS.md`,
   `config/hosts.tsv`, and `config/runner.env`.
2. Inspect the final candidate diff, open review findings, and working-tree
   status. Refuse to roll out a merge-conflicted or unidentified revision.
3. Invoke `$validate-runner-fleet-python`, then run `mise run validate`.
4. Record the exact commit SHA and rollback SHA. Never deploy an uncommitted
   change to a remote host.
5. Choose the current machine as the canary when it owns an affected profile.
   Generate the order with:

```sh
mise run rollout -- plan --canary <host-id>
```

## Canary

1. Generate target-local commands instead of reconstructing platform quoting:

```sh
mise run rollout -- commands <host-id>
```

2. Run only the affected profile commands in the correct native OS or guest.
   Do not treat the physical host shell as its Linux or Windows VM shell.
3. Do not print, copy, persist, or forward registration tokens, `.runner`,
   `.credentials`, `_diag`, `_work`, SSH material, or GitHub CLI state.
4. Verify the native service, a targeted trusted job, and the fleet contract:

```sh
mise run rollout -- verify <host-id>
```

5. Stop if the canary is offline, mislabeled, starts the wrong service identity,
   or cannot run its targeted job. Restore the recorded revision before
   considering another host.

## Remote rollout

1. Update one active host at a time in the generated order. Never launch a
   parallel SSH loop for service-changing commands.
2. Resolve the SSH destination through the user's SSH configuration. Do not
   commit addresses, usernames, keys, or passwords to this repository.
3. On the remote host, verify a clean checkout, fetch the exact candidate SHA,
   check it out, invoke `$validate-runner-fleet-python`, and run
   `mise run validate` before invoking the generated bootstrap command.
4. Treat macOS, Linux guests, Windows ARM64 guests, and native Windows x64 as
   separate targets even when they share a physical parent.
5. Run the generated service check and `mise run rollout -- verify <host-id>`.
   Continue only after both succeed.

## Finish

Report the candidate and rollback SHAs, host order, per-profile commands run,
service and GitHub status, targeted-job evidence, skipped/planned hosts, and
any rollback. Re-run `$validate-runner-fleet-python` after rollout-related
Python changes. Never call a rollout complete while a required host is
unverified.
