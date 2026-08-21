# Staged prompting contract

Do not ask one prompt to discover, judge, synthesize, and publish at once. Run the stages separately and persist each result before advancing.

## 1. Frame intent

Prompt objective:

> Convert the request into a small set of umbrella questions. Define ambiguous terms. Do not confuse questions, hypotheses, and investigations.
>
> Decompose each question into independent investigation tracks. Give every track a focused question, required evidence, and falsifier. Use six to twelve tracks for broad or thesis-scale work. Use fewer tracks only when the scope is narrow.
>
> State hypotheses without treating them as facts. Do not force symmetry between questions, hypotheses, or tracks.

Gate: `data/manifest.json` contains stable question, hypothesis, and track IDs. Broad work has a coverage matrix in `research-program.md`.

## 2. Discover without synthesizing

Prompt objective:

> Find candidate primary sources, code, research, independent reporting, and social signals. Capture only discovery metadata and a short paraphrased signal. Do not write conclusions.

Gate: each raw observation has an ID, source ID, capture date, channel, and signal. Search explicitly for earlier precedents and counterevidence.

## 3. Normalize sources

Prompt objective:

> Canonicalize URLs, deduplicate records, identify publisher and dates, classify evidentiary role, and state only what each source can support.

Gate: one record per source; social sources cannot carry production or performance claims alone.

## 4. Atomize claims and map evidence

Prompt objective:

> Break the emerging interpretation into independently testable claims. For every source-to-claim edge choose supports, contradicts, or context; assign strength and explain the relationship. Preserve contradictory evidence.

Gate: every claim has at least one mapped evidence edge or remains explicitly open. A source is never treated as support merely because it mentions the topic.

## 5. Synthesize analysis

Prompt objective:

> Write from the claim registry and evidence map, not directly from a search-result pile. Cite each externally verifiable statement in the same paragraph or table row. Separate chronology from causation. Include scope limits, alternative explanations, operational implications, and measurements that could falsify the conclusion later.

Gate: each analysis artifact declares claim dependencies and direct citations in `data/products/artifacts.json`.

## 6. Publish progressively

Prompt objective:

> Produce a short topic index, a standalone brief, modular analyses, evidence views, and a lineage explanation. Avoid duplicating full analysis in the index or brief.

Gate: published outputs declare upstream artifact dependencies. External links and `source_ids` match exactly. All local links resolve.

## 7. Adversarial refinement

Prompt objective:

> Assume the current conclusion is wrong. Find orphan sources, unsupported facts, distant citations, citation metadata drift, and overclaimed evidence.
>
> Find missing contradiction edges, circular artifact dependencies, metrics without methods, and social claims presented as facts. Recommend the smallest corrections.

Gate: rebuild lineage. Run `mise run verify` and the source validator. Add a dated update note for material conclusion changes.
