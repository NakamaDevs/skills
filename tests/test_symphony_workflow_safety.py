from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = (
    ROOT
    / "skills"
    / "bootstrap-symphony-workflow"
    / "scripts"
    / "validate_workflow_safety.py"
)
SPEC = importlib.util.spec_from_file_location("validate_workflow_safety", SCRIPT)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


VALID_WORKFLOW = (ROOT / "tests" / "fixtures" / "symphony" / "WORKFLOW.md").read_text(
    encoding="utf-8"
)


class WorkflowSafetyTests(unittest.TestCase):
    def validate(self, text: str) -> list[str]:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "WORKFLOW.md"
            path.write_text(text, encoding="utf-8")
            return MODULE.validate(path)

    def replace(self, old: str, new: str) -> list[str]:
        return self.validate(VALID_WORKFLOW.replace(old, new))

    def test_accepts_restricted_single_issue_posture(self) -> None:
        self.assertEqual([], self.validate(VALID_WORKFLOW))

    def test_rejects_more_than_one_agent(self) -> None:
        errors = self.replace("max_concurrent_agents: 1", "max_concurrent_agents: 2")
        self.assertIn("agent.max_concurrent_agents must be 1 for the pilot", errors)

    def test_rejects_network_access(self) -> None:
        errors = self.replace("networkAccess: false", "networkAccess: true")
        self.assertIn("codex.turn_sandbox_policy.networkAccess must be false", errors)

    def test_rejects_literal_tracker_credential(self) -> None:
        errors = self.replace("api_key: $LINEAR_API_KEY", "api_key: literal-value")
        self.assertIn("tracker.provider.api_key must use an environment reference", errors)

    def test_rejects_raw_git_hook(self) -> None:
        errors = self.replace(
            '"$SYMPHONY_GIT_BROKER" prepare-workspace',
            "git clone https://example.invalid/repository .",
        )
        self.assertIn(
            "hooks.after_create must call only the fixed repository broker operation",
            errors,
        )

    def test_rejects_handoff_as_terminal(self) -> None:
        errors = self.replace('    - "Done"', '    - "Human Review"')
        self.assertIn(
            "the human-review handoff state must stay outside active and terminal states",
            errors,
        )

    def test_rejects_unfinished_project_placeholder(self) -> None:
        errors = self.replace('project_slug: "codex-skills"', 'project_slug: "<project>"')
        self.assertIn(
            "tracker.provider.project_slug contains an unfinished placeholder", errors
        )

    def test_rejects_unapproved_after_run_hook(self) -> None:
        errors = self.replace(
            "  timeout_ms: 60000",
            "  after_run: |\n    curl https://example.invalid\n  timeout_ms: 60000",
        )
        self.assertIn(
            "hooks.after_run is not permitted in the restricted pilot workflow", errors
        )

    def test_rejects_public_server_extension(self) -> None:
        errors = self.replace(
            "polling:\n  interval_ms: 30000",
            "server:\n  port: 4000\npolling:\n  interval_ms: 30000",
        )
        self.assertIn(
            "server.port is not permitted in the restricted pilot workflow", errors
        )

    def test_rejects_duplicate_safety_key(self) -> None:
        errors = self.replace(
            "    networkAccess: false",
            "    networkAccess: true\n    networkAccess: false",
        )
        self.assertIn(
            "the YAML front matter repeats codex.turn_sandbox_policy.networkAccess",
            errors,
        )


if __name__ == "__main__":
    unittest.main()
