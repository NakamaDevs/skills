# Velvet Iduna NakamaDevs Discord contract

Current version: 1.0.0

| Purpose | Name | ID |
| --- | --- | --- |
| Guild | Velvet Iduna | `875555017451507722` |
| Authorized member role | `NakamaDev` | `1320910752466468874` |
| Operations channel | `💻┃nakamadevs-feed` | `1533964854078214175` |
| Project forum | `💻┃proyectos` | `1320933854877450301` |

The current Kantoku source defines:

- `/kantoku jobs`: list active NakamaDevs GitHub jobs and PR links; read-only.
- `/kantoku hosts`: list runner hosts, local APIs, and reported runners; read-only.
- `/kantoku runners`: check the fleet and start degraded runners through the fixed idempotent recovery path.

The command is guild-scoped and default-denied. Grant it explicitly to the `NakamaDev` role in `nakamadevs-feed`, and retain the same guild, channel, and role checks in application code. Reconcile documentation after changing the command definition.

Discord's GitHub-compatible webhook endpoint supports existing forum threads through the `thread_id` query parameter. Keep webhook tokens only in Discord and GitHub administrative settings.
