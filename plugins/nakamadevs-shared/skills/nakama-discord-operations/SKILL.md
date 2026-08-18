---
name: nakama-discord-operations
description: Use the private Velvet Iduna NakamaDevs Discord operations channel, project threads, GitHub-compatible webhooks, and authorized /kantoku slash commands safely. Use for nakamadevs-feed status, runner commands, project notifications, Discord permission checks, or repository-to-thread webhook setup.
---

# Nakama Discord Operations

1. Read `.nakama/repository.toml` and [the Discord contract](references/discord-contract.md). Treat snowflake IDs as identifiers, never as credentials.
2. Use the authenticated Discord surface or Kantoku service; never request or expose bot tokens, webhook URLs, interaction tokens, or local API bearer tokens.
3. Before invoking a command, verify the current `/kantoku` definition in Kantoku when available. The pinned contract supports read-only `jobs` and `hosts`, plus degradation-aware `runners` recovery.
4. Restrict operations to the configured guild, `NakamaDev` role, and `nakamadevs-feed`. Discord UI permissions complement, but do not replace, application allowlists.
5. For GitHub notifications, create one webhook credential per repository to limit blast radius. Use Discord's GitHub-compatible endpoint with the repository context's existing `thread_id`, subscribe only to supported useful events, and keep the URL out of files and logs.
6. Verify a webhook through GitHub delivery metadata and the destination thread without printing the payload URL. Rotate only the affected webhook if exposure is suspected.
7. For messages, previews, command execution, credential creation, permission changes, or host mutation, follow the active surface's confirmation requirements and the user's explicit scope.

Do not publish general send/schedule slash commands without separate authorization, preview, approval, mention suppression, and audit design.
