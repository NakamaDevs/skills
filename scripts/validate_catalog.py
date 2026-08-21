#!/usr/bin/env python3
"""Validate the NakamaDevs Agent Skills catalog."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "skills"
NAME = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def fail(message: str) -> None:
    print(f"catalog: {message}", file=sys.stderr)
    raise SystemExit(1)


def validate_skill(skill_dir: Path) -> None:
    skill_file = skill_dir / "SKILL.md"
    if not skill_file.is_file():
        fail(f"{skill_dir.relative_to(ROOT)} is missing SKILL.md")
    text = skill_file.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        fail(f"{skill_file.relative_to(ROOT)} has no YAML frontmatter")
    frontmatter = text.split("---\n", 2)[1]
    name_match = re.search(r"(?m)^name:\s*([^\n]+)$", frontmatter)
    description_match = re.search(r"(?m)^description:\s*(.+)$", frontmatter)
    if not name_match:
        fail(f"{skill_file.relative_to(ROOT)} needs a name")
    if not description_match:
        fail(f"{skill_file.relative_to(ROOT)} needs a description")
    name = name_match.group(1).strip().strip("\"'")
    description = description_match.group(1).strip()
    if not NAME.fullmatch(skill_dir.name):
        fail(f"{skill_dir.relative_to(ROOT)} must use a lowercase kebab-case name")
    if name != skill_dir.name:
        fail(f"{skill_file.relative_to(ROOT)} name must match its directory")
    if len(description) > 1024:
        fail(f"{skill_file.relative_to(ROOT)} description exceeds 1024 characters")
    if re.search(r"(?m)^allowed-tools:", frontmatter):
        fail(f"{skill_file.relative_to(ROOT)} declares non-portable tools")


def main() -> None:
    if not SKILLS.is_dir():
        fail("missing skills directory")
    skill_dirs = sorted(path for path in SKILLS.iterdir() if path.is_dir())
    if not skill_dirs:
        fail("skills directory is empty")
    seen: set[str] = set()
    for skill_dir in skill_dirs:
        if skill_dir.name in seen:
            fail(f"duplicate skill {skill_dir.name}")
        seen.add(skill_dir.name)
        validate_skill(skill_dir)
    if len(seen) != 69:
        fail(f"expected 69 unique skills, found {len(seen)}")
    print(f"catalog: valid ({len(seen)} skills in skills/)")


if __name__ == "__main__":
    main()
