#!/usr/bin/env python3
"""Create and register a lineage-ready Kenkyu topic without dependencies."""

import argparse
import json
import re
from datetime import date
from pathlib import Path

from build_lineage import build_lineage


def write(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def write_json(path: Path, data: dict) -> None:
    write(path, json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--slug", required=True)
    parser.add_argument("--title", required=True)
    args = parser.parse_args()

    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", args.slug):
        raise SystemExit("slug must use lowercase letters, numbers, and hyphens")

    root = args.root.resolve()
    topics = root / "topics"
    topic = topics / args.slug
    catalog_path = topics / "catalog.json"
    if topic.exists():
        raise SystemExit(f"topic already exists: {topic}")

    today = date.today().isoformat()
    for relative in ("analysis", "evidence", "chronology", "data/raw", "data/curated", "data/products", "updates"):
        (topic / relative).mkdir(parents=True, exist_ok=True)

    write(
        topic / "index.md",
        f"# {args.title}\n\n- Status: Draft\n- First published: {today}\n- Last updated: {today}\n"
        "- Observation window: Not set\n\n## Current finding\n\nTODO\n\n## Read by concern\n\n"
        "- [Executive brief](brief.md)\n- [Research program](research-program.md)\n- [Definitions](concepts.md)\n"
        "- [Drivers](analysis/drivers.md)\n- [Quality and risk](analysis/quality.md)\n"
        "- [Practical implications](analysis/implications.md)\n- [Case studies](evidence/case-studies.md)\n"
        "- [Social signals](evidence/social-signals.md)\n- [Timeline](chronology/timeline.md)\n"
        "- [Research lineage](lineage.md)\n- [Manifest](data/manifest.json)\n"
        "- [Source ledger](data/curated/sources.json)\n- [Claims](data/curated/claims.json)\n"
        "- [Evidence map](data/curated/evidence-map.json)\n- [Update history](updates/" + today + ".md)\n",
    )
    write(topic / "brief.md", "# Executive brief\n\nTODO\n\n## Provisional conclusion\n\nTODO\n")
    write(
        topic / "research-program.md",
        "# Research program\n\nTODO: map umbrella questions to independent investigation tracks.\n\n"
        "Each track needs a focused question, evidence requirements, a falsifier, and a planned output.\n",
    )
    write(topic / "concepts.md", "# Definitions and conceptual model\n\nTODO\n")
    write(topic / "analysis" / "drivers.md", "# Drivers and causal analysis\n\nTODO\n\n## Counterevidence and limits\n\nTODO\n")
    write(topic / "analysis" / "quality.md", "# Quality, risk, and verification\n\nTODO\n")
    write(topic / "analysis" / "implications.md", "# Practical implications\n\nTODO\n")
    write(topic / "evidence" / "case-studies.md", "# Case studies\n\nTODO\n")
    write(topic / "evidence" / "social-signals.md", "# Social signals\n\nTODO or explain why this module is not needed.\n")
    write(topic / "chronology" / "timeline.md", f"# Timeline\n\nLast updated: {today}\n\n| Date | Event | Why it matters |\n|---|---|---|\n")
    write(topic / "lineage.md", "# Research lineage\n\nTODO: summarize the question → claim → evidence → output paths.\n\nMachine graph: [`data/products/lineage.json`](data/products/lineage.json).\n")
    write(topic / "updates" / f"{today}.md", f"# Initial research — {today}\n\n## Added\n\nTODO\n\n## Current conclusion\n\nTODO\n")

    write_json(topic / "data" / "manifest.json", {
        "schema_version":"1.0", "topic":args.slug, "title":args.title,
        "updated_at":today, "research_scale":"standard",
        "research_questions":[], "hypotheses":[], "investigation_tracks":[],
    })
    write_json(topic / "data" / "pipeline.json", {
        "schema_version":"1.0", "topic":args.slug,
        "stages":[
            {"id":"stage-intent","inputs":["user request"],"outputs":["data/manifest.json"]},
            {"id":"stage-program","inputs":["data/manifest.json"],"outputs":["research-program.md"]},
            {"id":"stage-intake","inputs":["research-program.md","discovery"],"outputs":["data/raw/observations.json"]},
            {"id":"stage-normalize","inputs":["data/raw/observations.json"],"outputs":["data/curated/sources.json"]},
            {"id":"stage-map","inputs":["data/curated/sources.json"],"outputs":["data/curated/claims.json","data/curated/evidence-map.json"]},
            {"id":"stage-analyze","inputs":["data/curated/claims.json"],"outputs":["analysis/*.md","evidence/*.md"]},
            {"id":"stage-publish","inputs":["analysis/*.md"],"outputs":["brief.md","index.md","lineage.md"]},
            {"id":"stage-lineage","inputs":["data/raw/*.json","data/curated/*.json","data/products/artifacts.json"],"outputs":["data/products/lineage.json"]}
        ]
    })
    write_json(topic / "data" / "raw" / "observations.json", {"topic":args.slug,"updated_at":today,"observations":[]})
    write_json(topic / "data" / "curated" / "sources.json", {"topic":args.slug,"updated_at":today,"sources":[]})
    write_json(topic / "data" / "curated" / "claims.json", {"topic":args.slug,"updated_at":today,"claims":[]})
    write_json(topic / "data" / "curated" / "evidence-map.json", {"topic":args.slug,"updated_at":today,"evidence":[]})
    artifact_specs = [
        ("artifact-research-program", "research-program.md", "research-plan", []),
        ("artifact-concepts", "concepts.md", "semantic-model", []),
        ("artifact-drivers", "analysis/drivers.md", "analysis", ["artifact-concepts"]),
        ("artifact-quality", "analysis/quality.md", "analysis", ["artifact-concepts"]),
        ("artifact-implications", "analysis/implications.md", "analysis", ["artifact-drivers", "artifact-quality"]),
        ("artifact-cases", "evidence/case-studies.md", "evidence-view", []),
        ("artifact-social", "evidence/social-signals.md", "evidence-view", []),
        ("artifact-timeline", "chronology/timeline.md", "chronology", []),
        ("artifact-brief", "brief.md", "output", ["artifact-research-program", "artifact-drivers", "artifact-quality", "artifact-implications", "artifact-cases"]),
        ("artifact-lineage-view", "lineage.md", "output", ["artifact-drivers", "artifact-quality", "artifact-cases", "artifact-social", "artifact-timeline"]),
        ("artifact-index", "index.md", "output", ["artifact-brief", "artifact-lineage-view"]),
    ]
    artifacts = [{"id":item_id,"path":path,"type":kind,"claim_ids":[],"source_ids":[],"derived_from":parents} for item_id, path, kind, parents in artifact_specs]
    write_json(topic / "data" / "products" / "artifacts.json", {"topic":args.slug,"updated_at":today,"artifacts":artifacts})
    write_json(topic / "data" / "products" / "lineage.json", build_lineage(topic))

    if catalog_path.exists():
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    else:
        topics.mkdir(parents=True, exist_ok=True)
        catalog = {"updated_at": today, "topics": []}
    if any(item.get("slug") == args.slug for item in catalog.get("topics", [])):
        raise SystemExit(f"catalog already contains slug: {args.slug}")
    catalog.setdefault("topics", []).append({
        "slug":args.slug, "title":args.title, "status":"draft",
        "first_published_at":today, "last_updated_at":today,
        "observation_window":"Not set", "tags":[],
        "path":f"topics/{args.slug}/index.md", "summary":"TODO",
    })
    catalog["updated_at"] = today
    write_json(catalog_path, catalog)
    print(topic)


if __name__ == "__main__":
    main()
