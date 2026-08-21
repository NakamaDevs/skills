#!/usr/bin/env python3
"""Validate the portable NakamaDevs repository-context schema."""

from __future__ import annotations

import re
import sys
import tomllib
from pathlib import Path


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


path = Path(sys.argv[1] if len(sys.argv) > 1 else ".nakama/repository.toml")
if not path.is_file():
    fail(f"missing repository context: {path}")
with path.open("rb") as stream:
    context = tomllib.load(stream)

if context.get("schema_version") != 1:
    fail("repository context must use schema_version = 1")
if not re.fullmatch(r"NakamaDevs/[A-Za-z0-9._-]+", str(context.get("repository", ""))):
    fail("repository must be a NakamaDevs owner/name pair")
if context.get("kind") not in {"single", "monorepo", "governance", "infrastructure"}:
    fail("kind must be single, monorepo, governance, or infrastructure")
if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", str(context.get("governance_version", ""))):
    fail("governance_version must be semantic")

required = {
    "skills": ("bundle", "version", "source", "revision"),
    "linear": ("team", "project"),
    "quality": ("quick", "full", "hooks_install"),
    "review": ("router",),
    "discord": ("guild_id", "project_thread_id", "operations_channel_id", "operator_role_id"),
}
for section, keys in required.items():
    values = context.get(section)
    if not isinstance(values, dict):
        fail(f"missing [{section}]")
    for key in keys:
        if not values.get(key):
            fail(f"{section}.{key} is required")

skills = context["skills"]
if skills["bundle"] != "NakamaDevs/skills":
    fail("skills.bundle must be NakamaDevs/skills")
if skills["source"] != "https://github.com/NakamaDevs/skills.git":
    fail("skills.source must be the canonical Agent Skills repository")
if not re.fullmatch(
    r"self|[0-9a-f]{40}|REPLACE_WITH_EXACT_SKLLS_COMMIT_SHA",
    str(skills["revision"]),
):
    fail("skills.revision must be self, a full Git commit SHA, or the template placeholder")

print(f"repository context is valid: {path}")
