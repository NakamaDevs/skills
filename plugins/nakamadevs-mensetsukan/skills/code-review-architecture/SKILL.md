---
name: code-review-architecture
description: Review changed system boundaries, ownership, dependency direction, abstractions, interfaces, patterns, and quality attributes against the repository's actual architecture. Use when a change affects packages, components, APIs, schemas, data flow, persistence, or cross-cutting design.
---

# Review Architecture

Evaluate fitness for this system. Patterns and SOLID principles are diagnostic questions, not mandatory shapes.

## Reconstruct the intended design

1. Read `AGENTS.md`, architecture docs, accepted decisions, contracts, and representative neighboring code.
2. Identify sources of truth, owners of state and decisions, trust boundaries, external interfaces, and dependency direction.
3. Trace what the change adds, removes, or moves across those boundaries.

## Apply design probes

- **Cohesion / SRP:** Does each unit own one coherent reason to change, or has unrelated policy accumulated?
- **Extension / OCP:** Does a foreseeable variation require risky edits across unrelated modules? Do not invent extension points without a real variation.
- **Substitutability / LSP:** Does an implementation preserve the behavioral contract its callers rely on?
- **Interface segregation / ISP:** Are consumers forced to depend on methods or data they do not need?
- **Dependency inversion / DIP:** Does policy depend on replaceable details only where that separation earns its cost?
- **Coupling:** Are data, timing, failure, or lifecycle assumptions hidden across boundaries?
- **Ownership:** Is there one authoritative representation, or can parallel models drift?
- **Simplicity:** Is the least mechanism that satisfies current requirements used?

For Go, prefer concrete types until an interface has a consumer, keep interfaces small and consumer-owned, and favor composition. Do not demand class-oriented patterns or dependency injection frameworks merely to satisfy SOLID vocabulary.

For Mensetsukan, preserve the JSON Schema as the structural source of truth, Go for semantic invariants, the interviewer window as private-session authority, stateless/local operation, loopback security, and embedded runtime assets. Adding persistence or external runtime dependencies requires an explicit requirement and lifecycle design.

## Finding gate

Report only a changed design decision with a concrete downstream cost: incorrect ownership, dependency cycle, duplicated source of truth, broken contract, hidden lifecycle, unjustified coupling, or complexity that blocks safe maintenance. Name the affected consumers and smallest viable correction. Do not report architecture taste or speculative future scalability.

Return candidates using the orchestrator contract, or `No findings.`
