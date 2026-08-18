---
name: mensetsukan
description: Build, edit, validate, test, or operate the Mensetsukan interview configuration editor, presenter, candidate view, JSON Schema, menshu CLI, or stateless MCP server. Use when changing this repository or creating a compatible external interview JSON file.
---

# Mensetsukan

Use the schema as the source of truth. Read `interview.schema.json` before adding or naming a configuration field.

## Change a configuration

1. Read `docs/configuration.md` and the relevant schema definition.
2. Edit the external JSON or `default.config.json`.
3. Run `go run . validate path/to/config.json`.
4. Run `mise run check` if tracked source changed.
5. Test the editor and interview at half-screen width when layout or field controls changed.

For the tracked generic MLOps operations example, edit `examples/mlops-operations.profile.json`, run `mise run app:interview:mlops:generate`, and validate with `mise run app:interview:mlops:check`. `mise run app:interview:mlops` opens the selected live form with live reload. `mise run app:interview:mlops:form` writes an ignored standalone interviewer review containing the complete bank. Keep core questions on inference and platform operations; model and data-science design belongs only in clearly conditional context.

Do not invent fields. Unknown properties are rejected. A section contains either `content` or `questions`, not both. Question pools have no fixed upper limit.

## Change the contract

Update these surfaces together:

- `interview.schema.json`
- `default.config.json`
- `interview.html` runtime validation and rendering
- `editor.html` field and complete JSON editing
- `validation.go` when a semantic invariant is required
- Go and browser contract tests
- `docs/configuration.md`

Keep candidate private-data boundaries and timing behavior intact. The interviewer window is the source of truth.

When adding randomized question pools, assign one `familyId` per evidence family, keep each family in one section, and use `selection.count`. Preserve fixed scored anchors as `content` questions when the interview needs apples-to-apples comparison. Review the complete prepared form before locking it. The candidate-safe presentation allowlist must not include `interviewerGuide`, lineage, ratings, notes, identity, or detailed timing.

## Operate the app

- `menshu serve` starts one local server and opens the editor.
- `menshu serve --target interview --config file.json` validates and opens an interview.
- `menshu validate file.json` validates without a browser.
- `menshu mcp` starts the read-only stdio MCP server.

Use `mise run app:aspire` for the complete local stack. It keeps editor, interview, eval, and inventory separate behind the YARP development gateway and exposes transcriber, diarizer, Ollama, and exact model readiness as observable resources. Eval is launched through `mise run app:eval:dev`, not directly, so Aspire uses the same strict local workflow and Go service preflight. The preflight requires an ignored workflow with both transcription and structured extraction commands plus `MENSHU_OLLAMA_MODEL=gpt-oss:20b`; it installs pinned tools when absent, starts services, checks before downloading models, and refuses the empty legacy workflow. A repository-owned transcription command should invoke `["{menshu}", "transcribe", ...]`, select `--diarization-backend pyannote`, keep `workingDirectory` empty, and never depend on another checkout. Python owns only faster-whisper and pyannote Community-1 inference; separate Go services own APIs, streaming, cancellation, path boundaries, health, and telemetry. Community-1 must be loaded from its official cached snapshot; if absent, preflight requires accepted Hugging Face terms and `HF_TOKEN`, announces one download, then reuses the cache. The generic gateway root is a launcher ordered Inventory, Editor, Interview, Eval; app links use stable `*.mensetsukan.localhost:15180` hosts rather than path prefixes because app assets and APIs are root-relative. Aspire exposes the same gateway on pinned HTTP port 15180 and a session-assigned HTTPS port. Inspect the live topology with `mise exec -- aspire describe --apphost aspire-apphost/apphost.mts --format Json --non-interactive`, and run `mise run test:aspire:gateway` to probe the launcher on both schemes, all four named routes, direct roots, transcriber and diarizer readiness, and the Ollama model. Eval readiness must report both `mediaTranscriberReady` and `questionExtractorReady`. The probe requires an already-running healthy AppHost and never changes its lifecycle.

Every Go HTTP service uses the shared OpenTelemetry bootstrap when Aspire injects an OTLP endpoint. Use the dashboard Structured, Traces, and Metrics views for editor, interview, eval, inventory, transcriber, and diarizer. Evidence spans contain stage/count metadata but must not include candidate names, transcript text, prompts, responses, or model reasoning. Browser progress arrives through one Server-Sent Events connection; do not reintroduce `/api/evidence/status` polling.

Aspire starts every browser-facing Go resource with `--live-reload`. HTML, JSON, schema, catalogue, and frontend-asset saves refresh the affected browser automatically. Go source, generated templ output, module, dependency, Python adapter, or transcriber changes require a targeted `aspire resource <name> restart` followed by `aspire wait <name> --apphost aspire-apphost/apphost.mts`; AppHost topology or dependency changes require restarting `mise run app:aspire`. Do not persist Aspire-assigned direct ports or its session HTTPS gateway port. Use the stable named HTTP gateway routes or discover the current endpoints.

Released binaries embed all required assets.
