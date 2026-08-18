#!/usr/bin/env python3
"""Inventory Markdown roadmap checkboxes without third-party dependencies."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


HEADING = re.compile(r"^##\s+(.+?)\s*$")
CHECKBOX = re.compile(r"^-\s+\[([ xX])\]\s+(.+?)\s*$")


def inventory(path: Path) -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    section = "(sin sección)"
    pending: dict[str, object] | None = None

    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        heading = HEADING.match(raw_line)
        if heading:
            section = heading.group(1)
            pending = None
            continue

        checkbox = CHECKBOX.match(raw_line)
        if checkbox:
            pending = {
                "line": line_number,
                "section": section,
                "complete": checkbox.group(1).lower() == "x",
                "text": checkbox.group(2),
            }
            entries.append(pending)
            continue

        if pending and raw_line.startswith("  ") and raw_line.strip():
            pending["text"] = f"{pending['text']} {raw_line.strip()}"
        elif raw_line.strip():
            pending = None

    return entries


def print_markdown(entries: list[dict[str, object]]) -> None:
    complete = sum(bool(entry["complete"]) for entry in entries)
    print(f"Roadmap: {complete}/{len(entries)} checklist items complete")
    print()
    print("| Line | Status | Section | Item |")
    print("| ---: | :---: | --- | --- |")
    for entry in entries:
        status = "done" if entry["complete"] else "open"
        text = str(entry["text"]).replace("|", "\\|")
        section = str(entry["section"]).replace("|", "\\|")
        print(f"| {entry['line']} | {status} | {section} | {text} |")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("roadmap", type=Path)
    parser.add_argument("--format", choices=("markdown", "json"), default="markdown")
    args = parser.parse_args()

    entries = inventory(args.roadmap)
    if not entries:
        parser.error(f"no roadmap checkboxes found in {args.roadmap}")
    if args.format == "json":
        print(json.dumps(entries, ensure_ascii=False, indent=2))
    else:
        print_markdown(entries)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
