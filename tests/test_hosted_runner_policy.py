"""Public Linux routing must not weaken self-hosted routing checks."""
import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("hosted_runner_policy", ROOT / "scripts/nakama_governance.py")
G = importlib.util.module_from_spec(spec)
spec.loader.exec_module(G)

class HostedRunnerPolicy(unittest.TestCase):
    def workflow(self, runner, workload="portable-non-server"):
        return f"""on:
  pull_request:
jobs:
  verify:
    if: ${{{{ github.event.pull_request.head.repo.full_name == github.repository }}}}
    # nakama-workload: {workload}
    runs-on: {runner}
"""

    def test_literal_public_linux_runner_is_supported(self):
        for workload in ("portable-non-server", "server-only"):
            self.assertEqual([], G.runner_policy_errors("ci.yml", self.workflow("ubuntu-24.04", workload)))

    def test_unknown_or_mixed_runner_does_not_bypass_capability_checks(self):
        for runner in ("unknown-runner", "self-hosted", "${{ vars.CI_RUNNER }}", "[ubuntu-24.04, self-hosted]", "${{ github.event.pull_request.user.login == 'dependabot[bot]' && 'nakama-dependabot-macos-arm64' || 'ubuntu-24.04' }}"):
            self.assertTrue(G.runner_policy_errors("ci.yml", self.workflow(runner)))

    def test_linux_does_not_satisfy_native_or_cross_platform_workloads(self):
        for workload in ("native-macos", "native-windows", "cross-platform-desktop"):
            self.assertTrue(G.runner_policy_errors("ci.yml", self.workflow("ubuntu-24.04", workload)))
