# Fleet review checklist

- Exact target hosts, labels, architectures, services, users, and environments are resolved before mutation.
- Bootstrap/update is rerunnable and handles interruption, version skew, offline hosts, and partial fleet rollout.
- Tokens and signing material use least privilege, safe storage, rotation, and redacted diagnostics.
- Runner labels and workflow selectors cannot route privileged jobs to unintended hosts.
- Capacity, disk, concurrency, cleanup, auto-update, and stuck-job recovery are observable.
- Rollout uses a canary and explicit health gate; rollback restores config, binaries, and service state.
