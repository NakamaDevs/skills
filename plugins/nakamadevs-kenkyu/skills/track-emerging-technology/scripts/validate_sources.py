#!/usr/bin/env python3
"""Validate the required shape and uniqueness of a research source ledger."""

import argparse
import json
from datetime import date
from pathlib import Path
from urllib.parse import urlparse

REQUIRED = {"id", "title", "url", "publisher", "published_at", "retrieved_at", "source_type", "confidence", "supports"}
SOURCE_TYPES = {"primary", "code", "research", "preprint", "reporting", "social"}
CONFIDENCE = {"high", "medium", "low"}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("ledger", type=Path)
    args = parser.parse_args()
    data = json.loads(args.ledger.read_text(encoding="utf-8"))
    errors = []
    seen_ids = set()
    seen_urls = set()

    for index, source in enumerate(data.get("sources", []), start=1):
        missing = REQUIRED - set(source)
        if missing:
            errors.append(f"source {index}: missing {sorted(missing)}")
            continue
        if source["id"] in seen_ids:
            errors.append(f"source {index}: duplicate id {source['id']}")
        if source["url"] in seen_urls:
            errors.append(f"source {index}: duplicate url {source['url']}")
        seen_ids.add(source["id"])
        seen_urls.add(source["url"])
        parsed = urlparse(source["url"])
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            errors.append(f"source {index}: invalid URL")
        if source["source_type"] not in SOURCE_TYPES:
            errors.append(f"source {index}: invalid source_type")
        if source["confidence"] not in CONFIDENCE:
            errors.append(f"source {index}: invalid confidence")
        try:
            date.fromisoformat(source["retrieved_at"])
        except (TypeError, ValueError):
            errors.append(f"source {index}: invalid retrieved_at")
        if not isinstance(source["supports"], list) or not source["supports"]:
            errors.append(f"source {index}: supports must be a non-empty list")

    if errors:
        raise SystemExit("\n".join(errors))
    print(f"OK: {len(seen_ids)} sources")


if __name__ == "__main__":
    main()
