#!/usr/bin/env python3
"""Validate the Kenkyu catalog and required modular topic artifacts."""

import argparse
import json
import re
from datetime import date
from pathlib import Path

from build_lineage import build_lineage

REQUIRED_CATALOG_FIELDS = {
    "slug", "title", "status", "first_published_at", "last_updated_at",
    "observation_window", "tags", "path", "summary",
}
REQUIRED_TOPIC_FILES = (
    "index.md",
    "brief.md",
    "concepts.md",
    "analysis/drivers.md",
    "analysis/quality.md",
    "analysis/implications.md",
    "evidence/case-studies.md",
    "evidence/social-signals.md",
    "chronology/timeline.md",
    "lineage.md",
    "data/manifest.json",
    "data/pipeline.json",
    "data/raw/observations.json",
    "data/curated/sources.json",
    "data/curated/claims.json",
    "data/curated/evidence-map.json",
    "data/products/artifacts.json",
    "data/products/lineage.json",
)
MARKDOWN_LINK_PATTERN = re.compile(r"\[[^\]]+\]\(([^)]+)\)")


def normalize_external_url(target: str) -> str | None:
    """Return a comparable external URL without a fragment or trailing slash."""
    target = target.strip().strip("<>").split("#", 1)[0]
    if not target.startswith(("http://", "https://")):
        return None
    return target.rstrip("/")


def validate_artifact_citations(topic: Path) -> list[str]:
    """Validate direct Markdown citations against the source and artifact ledgers."""
    sources_path = topic / "data" / "curated" / "sources.json"
    artifacts_path = topic / "data" / "products" / "artifacts.json"
    if not sources_path.is_file() or not artifacts_path.is_file():
        return []

    sources = json.loads(sources_path.read_text(encoding="utf-8")).get("sources", [])
    artifacts = json.loads(artifacts_path.read_text(encoding="utf-8")).get("artifacts", [])
    source_by_id = {source.get("id"): source for source in sources}
    source_ids_by_url = {}
    errors = []

    for source in sources:
        source_id = source.get("id")
        source_url = normalize_external_url(str(source.get("url", "")))
        if source_id and source_url:
            source_ids_by_url.setdefault(source_url, set()).add(source_id)

    for artifact in artifacts:
        artifact_id = artifact.get("id", "<unknown>")
        artifact_path = topic / artifact.get("path", "")
        if not artifact_path.is_file():
            continue

        text = artifact_path.read_text(encoding="utf-8")
        linked_urls = {
            url
            for target in MARKDOWN_LINK_PATTERN.findall(text)
            if (url := normalize_external_url(target)) is not None
        }
        declared_ids = set(artifact.get("source_ids", []))

        for source_id in sorted(declared_ids):
            source = source_by_id.get(source_id)
            if source is None:
                continue
            source_url = normalize_external_url(str(source.get("url", "")))
            if source_url not in linked_urls:
                errors.append(
                    f"{topic.name}: {artifact_id} declares {source_id} but {artifact.get('path')} does not link to it"
                )

        for linked_url in sorted(linked_urls):
            matching_ids = source_ids_by_url.get(linked_url, set())
            if not matching_ids:
                errors.append(
                    f"{topic.name}: {artifact.get('path')} links to an unregistered source {linked_url}"
                )
                continue
            if not matching_ids & declared_ids:
                errors.append(
                    f"{topic.name}: {artifact.get('path')} links to {linked_url} without a matching source_id"
                )

    return errors


def valid_date(value: object) -> bool:
    try:
        date.fromisoformat(str(value))
        return True
    except ValueError:
        return False


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    catalog_path = root / "topics" / "catalog.json"
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    errors = []
    seen = set()

    for index, item in enumerate(catalog.get("topics", []), start=1):
        missing = REQUIRED_CATALOG_FIELDS - set(item)
        if missing:
            errors.append(f"catalog topic {index}: missing {sorted(missing)}")
            continue
        slug = item["slug"]
        if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", slug):
            errors.append(f"catalog topic {index}: invalid slug {slug}")
        if slug in seen:
            errors.append(f"catalog topic {index}: duplicate slug {slug}")
        seen.add(slug)
        expected_path = f"topics/{slug}/index.md"
        if item["path"] != expected_path:
            errors.append(f"catalog topic {index}: path must be {expected_path}")
        if not valid_date(item["first_published_at"]) or not valid_date(item["last_updated_at"]):
            errors.append(f"catalog topic {index}: invalid publication/update date")
        topic = root / "topics" / slug
        for relative in REQUIRED_TOPIC_FILES:
            if not (topic / relative).is_file():
                errors.append(f"{slug}: missing {relative}")
        manifest_path = topic / "data" / "manifest.json"
        if manifest_path.is_file():
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            if "investigation_tracks" in manifest and not (topic / "research-program.md").is_file():
                errors.append(f"{slug}: manifest has investigation tracks but research-program.md is missing")
        if (topic / "README.md").exists():
            errors.append(f"{slug}: use index.md and modules instead of README.md")
        updates = list((topic / "updates").glob("????-??-??.md")) if (topic / "updates").is_dir() else []
        if not updates:
            errors.append(f"{slug}: no dated update file")
        ledger_path = topic / "data" / "curated" / "sources.json"
        if ledger_path.is_file():
            ledger = json.loads(ledger_path.read_text(encoding="utf-8"))
            if ledger.get("topic") != slug:
                errors.append(f"{slug}: source ledger topic does not match slug")
        errors.extend(validate_artifact_citations(topic))
        try:
            generated_lineage = build_lineage(topic)
            lineage_path = topic / "data" / "products" / "lineage.json"
            if lineage_path.is_file() and json.loads(lineage_path.read_text(encoding="utf-8")) != generated_lineage:
                errors.append(f"{slug}: generated lineage is stale")
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            errors.append(f"{slug}: lineage validation failed: {exc}")

    for markdown in root.rglob("*.md"):
        if ".git" in markdown.parts:
            continue
        for target in MARKDOWN_LINK_PATTERN.findall(markdown.read_text(encoding="utf-8")):
            target = target.strip().strip("<>").split("#", 1)[0]
            if not target or target.startswith(("http://", "https://", "mailto:")):
                continue
            if not (markdown.parent / target).resolve().exists():
                errors.append(f"{markdown.relative_to(root)}: broken link {target}")

    if errors:
        raise SystemExit("\n".join(errors))
    print(f"OK: {len(seen)} modular topics")


if __name__ == "__main__":
    main()
