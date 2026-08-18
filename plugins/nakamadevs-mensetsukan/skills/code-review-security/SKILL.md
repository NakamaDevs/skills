---
name: code-review-security
description: Review changed trust boundaries, input and output handling, files, processes, origins, messages, dependencies, permissions, secrets, and private data for demonstrable vulnerabilities. Use when a change touches any security- or privacy-sensitive surface.
---

# Review Security

Build a change-specific threat model before applying a checklist.

## Trace the boundary

1. Identify attacker-controlled or untrusted inputs, protected data, privileged actions, and security assumptions.
2. Trace validation, normalization, authorization, use, output encoding, logging, storage, and cleanup.
3. Inspect failure behavior: fail open versus closed, partial success, repeated requests, resource exhaustion, and error disclosure.
4. Check applicable classes: injection, path traversal, unsafe file access, origin/window confusion, cross-site scripting, command execution, request forgery, insecure randomness, race conditions, dependency risk, and secret exposure.
5. Run repository security checks when appropriate. Never retrieve or print secret values.

For Mensetsukan, preserve loopback binding and Host checks, same-origin plus popup-window message validation, separation of interviewer-only data, generic tracked content, scoped file access, and the read-only/stateless MCP contract.

## Finding gate

Report only a reachable attack or privacy scenario introduced or worsened by the change. State the attacker-controlled input, security boundary crossed, impact, and evidence that existing validation does not stop it. Avoid generic hardening advice with no changed path.

Treat severe secret exposure, arbitrary code execution, authorization bypass, or private-data disclosure as high priority according to demonstrated blast radius. Return candidates using the orchestrator contract, or `No findings.`
