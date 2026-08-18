# Research topic structure

Use progressive disclosure plus data-lake-style lineage. Keep indexes short; persist each processing stage before producing downstream work.

```text
topics/<slug>/
├── index.md
├── brief.md
├── research-program.md
├── concepts.md
├── lineage.md
├── analysis/
│   ├── drivers.md
│   ├── quality.md
│   └── implications.md
├── evidence/
│   ├── case-studies.md
│   └── social-signals.md
├── chronology/timeline.md
├── data/
│   ├── manifest.json
│   ├── pipeline.json
│   ├── raw/observations.json
│   ├── curated/
│   │   ├── sources.json
│   │   ├── claims.json
│   │   └── evidence-map.json
│   └── products/
│       ├── artifacts.json
│       └── lineage.json
└── updates/YYYY-MM-DD.md
```

## Data responsibilities

- `manifest.json`: Stable umbrella questions, hypotheses, investigation tracks, evidence needs, and falsifiers.
- `pipeline.json`: Stage inputs, outputs, and quality gates.
- `raw/observations.json`: Append-oriented discovery metadata and paraphrased signals.
- `curated/sources.json`: Canonical, deduplicated source identity and provenance.
- `curated/claims.json`: Atomic findings, hypotheses, constraints, and confidence.
- `curated/evidence-map.json`: Explicit support, contradiction, or context edges with rationale.
- `products/artifacts.json`: Output paths and their claim, direct citation, and upstream artifact dependencies.
- `products/lineage.json`: Deterministically generated observation → source → claim → artifact graph. Never edit by hand.

## Document responsibilities

- `index.md`: Metadata, one-paragraph current finding, and navigation only.
- `brief.md`: Standalone executive synthesis and provisional conclusion.
- `research-program.md`: Investigation tracks, comparison design, evidence needs, and stopping rules.
- `concepts.md`: Stable definitions and relationships.
- `lineage.md`: Human-readable question-to-output map linking the machine graph.
- `analysis/`: Arguments that can evolve independently.
- `evidence/`: Concrete deployments and social narratives with different evidence roles.
- `chronology/`: Sequence separated from causal interpretation.
- `updates/`: Dated changes to data, mappings, and conclusions.

Add topic-specific modules when needed, but retain the standard layers for automation. Do not duplicate the same prose across the brief and analysis.

## Citation contract

Every external Markdown link in a registered artifact is a citation. Its canonical URL must exist in `data/curated/sources.json`. The artifact's `source_ids` must declare that source. Every declared `source_id` must have a matching link in the artifact. `validate_archive.py` enforces this bidirectional match.
