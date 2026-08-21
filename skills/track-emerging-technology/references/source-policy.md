# Source evaluation policy

## Evidence hierarchy

1. `primary`: Official announcements, specifications, and first-party statistics. Use them to establish what an organization claims about itself.
2. `code`: Official or author-owned code. Use it to establish that an implementation exists and inspect its documented behavior.
3. `research`: Peer-reviewed work or transparent empirical research. Preserve its population and methodological limits.
4. `preprint`: Research not yet peer reviewed. Treat findings as provisional.
5. `reporting`: Independent journalism. Use it for corroboration and social or organizational context.
6. `social`: X, Reddit, and similar sources. Use only for narratives, reactions, reach, and discovery paths.

Do not derive `confidence` from source type mechanically. A first-party benchmark is high-confidence evidence that the company made the claim, but not independent proof that the result generalizes.

## Required ledger fields

- Stable `id`
- `title`
- Canonical `url`
- `publisher`
- `published_at`, or null when unknown
- `retrieved_at`
- `source_type`
- `confidence`
- A non-empty `supports` list

## Citation standard

- Cite every externally verifiable statement unless it is common knowledge.
- Put the direct link in the same paragraph or table row as the statement.
- Cite statements about dates, behavior, limits, prices, metrics, releases, and reported events.
- Cite analysis when it depends on an external fact.
- Pure recommendations, repository-defined terms, navigation, and clearly labelled hypotheses do not need citations.
- Add every cited source to `data/curated/sources.json`.
- Add every direct citation to the artifact's `source_ids`.
- Do not add a `source_id` when the artifact does not link to that source.
- Do not use a bibliography entry as a substitute for a nearby citation.

## Verification checklist

- Is the date the event date or the article’s publication date?
- What population, time range, and method produced a quoted number?
- Does a benchmark measure the model alone or the deployed model-plus-harness system?
- Does the source report failures, cost, rework, and human effort, or only successes?
- Can a social retelling be traced to an official or independently verified source?
- Is there an earlier precedent or counterexample that weakens the causal story?
