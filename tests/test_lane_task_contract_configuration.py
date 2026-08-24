"""Configuration regression: define-lane-task-contract stays wired into mise."""

from __future__ import annotations

import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MISE_TOML = ROOT / "mise.toml"


class LaneTaskContractConfigurationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.config = tomllib.loads(MISE_TOML.read_text(encoding="utf-8"))

    def test_elixir_is_pinned_for_the_dependency_free_validators(self) -> None:
        self.assertIn("elixir", self.config["tools"])

    def test_lane_task_contract_test_task_runs_all_three_focused_suites(self) -> None:
        run = self.config["tasks"]["lane-task-contract:test"]["run"]
        self.assertIn(
            "elixir skills/define-lane-task-contract/test/lane_task_envelope_test.exs", run
        )
        self.assertIn(
            "elixir skills/define-lane-task-contract/test/lane_task_result_test.exs", run
        )
        self.assertIn(
            "elixir skills/define-lane-task-contract/test/notify_parent_test.exs", run
        )

    def test_verify_quick_runs_lane_task_contract_tests(self) -> None:
        run = self.config["tasks"]["verify:quick"]["run"]
        self.assertIn("mise run lane-task-contract:test", run)


if __name__ == "__main__":
    unittest.main()
