#!/usr/bin/env python3
"""Validate the NakamaDevs Codex plugin marketplace."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLUGINS = ROOT / "plugins"
MARKETPLACE = ROOT / ".agents" / "plugins" / "marketplace.json"
RISKY_SKILLS = {
    "aspire-deployment",
    "aspire-init",
    "aspire-orchestration",
    "aspireify",
    "hyperframes-cli",
    "install-official-flutter-skills",
    "media-use",
    "nakama-adopt-governance",
    "nakama-deliver-change",
    "nakama-discord-operations",
    "nakama-operate-runners",
    "playwright-cli",
    "resolve-pr-review-threads",
    "rollout-runner-fleet",
    "run-playwright-agent-workflows",
    "setup-flutter-development",
    "setup-prek-git-hooks",
    "setup-self-hosted-ci-runner",
    "track-emerging-technology",
}


def fail(message: str) -> None:
    print(f"catalog: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_json(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"{path.relative_to(ROOT)} is invalid: {error}")
    if not isinstance(value, dict):
        fail(f"{path.relative_to(ROOT)} must contain a JSON object")
    return value


def frontmatter(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        fail(f"{path.relative_to(ROOT)} has no YAML frontmatter")
    try:
        return text.split("---\n", 2)[1]
    except IndexError:
        fail(f"{path.relative_to(ROOT)} has incomplete YAML frontmatter")
    raise AssertionError("unreachable")


def field(text: str, name: str) -> str:
    match = re.search(rf"(?m)^{re.escape(name)}:\s*[\"']?([^\n\"']+)", text)
    return match.group(1).strip() if match else ""


def validate_skill(skill_dir: Path) -> None:
    skill_file = skill_dir / "SKILL.md"
    metadata_file = skill_dir / "agents" / "openai.yaml"
    metadata = frontmatter(skill_file)
    name = field(metadata, "name")
    description = field(metadata, "description")
    if name != skill_dir.name:
        fail(f"{skill_file.relative_to(ROOT)} name must match its directory")
    if not description:
        fail(f"{skill_file.relative_to(ROOT)} needs a description")
    if re.search(r"(?m)^allowed-tools:", metadata):
        fail(f"{skill_file.relative_to(ROOT)} declares non-portable tools")
    if not metadata_file.is_file():
        fail(f"{metadata_file.relative_to(ROOT)} is missing")
    interface = metadata_file.read_text(encoding="utf-8")
    for required in ("display_name", "short_description", "default_prompt"):
        if not re.search(rf"(?m)^\s{{2}}{required}:\s*\".+\"$", interface):
            fail(f"{metadata_file.relative_to(ROOT)} needs quoted {required}")
    if "$" + name not in interface:
        fail(f"{metadata_file.relative_to(ROOT)} must name $" + name)
    if name in RISKY_SKILLS and "allow_implicit_invocation: false" not in interface:
        fail(f"{metadata_file.relative_to(ROOT)} must require explicit invocation")


def main() -> None:
    marketplace = load_json(MARKETPLACE)
    entries = marketplace.get("plugins")
    if not isinstance(entries, list):
        fail("marketplace plugins must be a list")
    listed: set[str] = set()
    for entry in entries:
        if not isinstance(entry, dict) or not isinstance(entry.get("name"), str):
            fail("each marketplace plugin needs a name")
        name = entry["name"]
        source = entry.get("source")
        if not isinstance(source, dict):
            fail(f"{name} needs a source")
        if source.get("source") != "local" or source.get("path") != f"./plugins/{name}":
            fail(f"{name} must use its local marketplace path")
        listed.add(name)

    directories = {path.name for path in PLUGINS.iterdir() if path.is_dir()}
    if listed != directories:
        fail("marketplace entries must match plugin directories")

    seen: dict[str, Path] = {}
    for plugin_dir in sorted(path for path in PLUGINS.iterdir() if path.is_dir()):
        manifest = load_json(plugin_dir / ".codex-plugin" / "plugin.json")
        if manifest.get("name") != plugin_dir.name:
            fail(f"{plugin_dir.name} manifest name does not match its directory")
        if manifest.get("skills") != "./skills/":
            fail(f"{plugin_dir.name} must expose ./skills/")
        for skill_dir in sorted((plugin_dir / "skills").iterdir()):
            if not skill_dir.is_dir():
                continue
            if skill_dir.name in seen:
                other = seen[skill_dir.name].relative_to(ROOT)
                fail(f"duplicate skill {skill_dir.name}; first found at {other}")
            seen[skill_dir.name] = skill_dir
            validate_skill(skill_dir)

    if len(seen) != 69:
        fail(f"expected 69 unique skills, found {len(seen)}")
    missing_risky = RISKY_SKILLS - seen.keys()
    if missing_risky:
        fail(f"risk policy names missing from catalog: {sorted(missing_risky)}")
    print(f"catalog: valid ({len(directories)} plugins, {len(seen)} skills)")


if __name__ == "__main__":
    main()
