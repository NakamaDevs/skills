---
name: track-emerging-technology
description: Research, document, and refresh emerging technology shifts in the English-language Kenkyu Markdown archive. Use when investigating a new technical trend, collecting current articles or social signals, testing a causal narrative against primary evidence, creating a dated topic dossier, or updating sources and conclusions as the field changes.
---

# Track Emerging Technology

Produce an English, evidence-traceable topic dossier. Separate what happened from what people claim it means.

## Workflow

1. Read `references/source-policy.md`, `references/output-structure.md`, and `references/prompt-contract.md`.
2. Inspect the repository and avoid overwriting an existing topic. For a new topic, run `scripts/new_topic.py` with a stable English slug and title. The generator creates the modular topic tree and registers it in `topics/catalog.json`.
3. Run the staged prompting contract. Persist the research program before discovery. Then persist every downstream stage before publishing prose.
4. Search in this order:
   - official announcements, documentation, code repositories, and system cards;
   - papers, reproducible datasets, and benchmark methodology;
   - independent reporting and practitioner case studies;
   - X, Reddit, and newsletters as adoption or narrative signals.
5. Search for counterevidence and earlier precedents. Do not infer causation from publication order alone.
6. Record every consequential source in `data/curated/sources.json`. Map observations to sources, sources to claims, and claims to artifacts with stable IDs.
7. Write modular English documents following `references/output-structure.md`. Cite externally verifiable statements in the same paragraph or table row. Keep `index.md` navigational; place synthesis, arguments, evidence, chronology, and data in their dedicated files.
8. Declare only direct citations in each artifact's `source_ids`. Build `data/products/lineage.json` with `scripts/build_lineage.py`. Run `mise run verify`, then validate the topic ledger with `scripts/validate_sources.py`.
9. Run the adversarial refinement prompt before finalizing. Correct overclaims, missing contradictions, orphan mappings, and stale lineage.
10. On refreshes, update `topics/catalog.json`, the topic `index.md`, and relevant data layers; add a dated note under `updates/`. Preserve earlier conclusions and explain what new evidence changed.

## Research rules

- Prefer primary sources for product behavior, dates, prices, and claimed production metrics.
- Treat company benchmarks and case studies as primary evidence of the company's claim, not independent proof.
- Use social posts to document reach, framing, examples, or discovery paths; corroborate factual claims elsewhere.
- Report model, product, and workflow as separate variables. A deployed coding agent is a model plus harness, tools, permissions, context, and evaluation.
- Compare throughput with outcome metrics such as acceptance, revert, defects, coverage, maintenance, cost, and human review time.
- Add a retrieval date to sources because model pages and social metrics change.
- Paraphrase sources. Do not reproduce paid articles or long passages.
- Cite every externally verifiable statement unless it is common knowledge.
- Put each citation in the same paragraph or table row as the supported statement.
- Do not use a bibliography entry as a substitute for a nearby citation.
- Keep an artifact's external links, source ledger, and `source_ids` in exact agreement.
- Use research questions only to organize the inquiry. Do not treat them as investigation tracks.
- For broad research, define six to twelve tracks. Give each track its own evidence needs and falsifier.
- Do not force equal counts for questions, hypotheses, claims, sources, or tracks.

## Scripts

Create a topic skeleton:

```bash
python3 scripts/new_topic.py --root <repo> --slug <slug> --title <title>
```

Validate the source ledger:

```bash
python3 scripts/validate_sources.py <topic>/data/curated/sources.json
```

Validate the archive structure and catalog:

```bash
mise run verify
```

Build or check lineage:

```bash
python3 scripts/build_lineage.py <topic>
python3 scripts/build_lineage.py <topic> --check
```

Trace lineage in either direction:

```bash
python3 scripts/trace_lineage.py <topic> --id <node-id> --direction upstream
```
