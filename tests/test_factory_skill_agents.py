"""Check the software factory skills and their Claude Code agent assets."""

from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "skills"

ROLE_SKILLS = {
    "nakama-direct-software-factory": "director",
    "nakama-manage-program": "program-manager",
    "nakama-engineer-quality-process": "quality-process-engineer",
    "nakama-automate-delivery": "delivery-automation-manager",
    "nakama-manage-allowances": "allowance-manager",
    "nakama-investigate-patterns": "investigator",
}


def frontmatter(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    assert text.startswith("---\n"), f"{path} has no frontmatter"
    return text.split("---\n", 2)[1]


class FactorySkillAgentTests(unittest.TestCase):
    def test_umbrella_skill_names_every_role(self) -> None:
        text = (SKILLS / "nakama-run-software-factory" / "SKILL.md").read_text(encoding="utf-8")
        for skill in ROLE_SKILLS:
            self.assertIn(f"${skill}", text, f"{skill} is missing from the roles table")

    def test_each_role_ships_a_claude_agent(self) -> None:
        for skill, agent in ROLE_SKILLS.items():
            asset = SKILLS / skill / "assets" / "claude-agent.md"
            self.assertTrue(asset.is_file(), f"{skill} has no assets/claude-agent.md")
            front = frontmatter(asset)
            name = re.search(r"(?m)^name:\s*(.+)$", front)
            self.assertIsNotNone(name, f"{asset} needs a name")
            self.assertEqual(name.group(1).strip(), agent)
            self.assertRegex(front, r"(?m)^description:\s*\S")
            self.assertRegex(front, r"(?m)^tools:\s*\S")

    def test_each_role_skill_references_the_shared_rules(self) -> None:
        for skill in ROLE_SKILLS:
            text = (SKILLS / skill / "SKILL.md").read_text(encoding="utf-8")
            self.assertIn("$nakama-run-software-factory", text, skill)
            self.assertIn("assets/claude-agent.md", text, skill)

    def test_frontmatter_scalars_have_no_unquoted_colon(self) -> None:
        # The skills CLI parses frontmatter as YAML. An unquoted ": " inside
        # a value is a nested mapping and the skill is skipped at install.
        for skill in [*ROLE_SKILLS, "nakama-run-software-factory"]:
            front = frontmatter(SKILLS / skill / "SKILL.md")
            for line in front.splitlines():
                key, _, value = line.partition(": ")
                if key in {"name", "description"} and not value.startswith(('"', "'")):
                    self.assertNotIn(": ", value, f"{skill}: unquoted colon in {key}")

    def test_no_role_may_merge_or_deploy(self) -> None:
        text = (SKILLS / "nakama-run-software-factory" / "SKILL.md").read_text(encoding="utf-8")
        self.assertIn("No role merges, releases, deploys, or spends.", text)

    def test_no_agent_definition_lists_the_agent_tool(self) -> None:
        # The owner decided on 2026-11-08: every agent runs in a Rex tab.
        # An embedded subagent is visible to one agent only.
        for skill in ROLE_SKILLS:
            asset = SKILLS / skill / "assets" / "claude-agent.md"
            front = frontmatter(asset)
            tools_line = re.search(r"(?m)^tools:\s*(.+)$", front)
            self.assertIsNotNone(tools_line, f"{asset} needs a tools line")
            tools = {tool.strip() for tool in tools_line.group(1).split(",")}
            self.assertNotIn("Agent", tools, f"{asset} lists the Agent tool")
            body = asset.read_text(encoding="utf-8")
            self.assertNotIn("Agent tool", body, f"{asset} tells the agent to use the Agent tool")

    def test_every_role_runs_in_a_rex_tab(self) -> None:
        text = (SKILLS / "nakama-run-software-factory" / "SKILL.md").read_text(encoding="utf-8")
        self.assertIn("Every agent runs in a Rex tab or child session.", text)
        for skill in ROLE_SKILLS:
            for path in (SKILLS / skill / "SKILL.md", SKILLS / skill / "assets" / "claude-agent.md"):
                self.assertIn("Rex tab", path.read_text(encoding="utf-8"), path)


if __name__ == "__main__":
    unittest.main()
