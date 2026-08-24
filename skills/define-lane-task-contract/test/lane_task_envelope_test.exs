ExUnit.start()

# lane_task_envelope.exs exits 2 when its own CLI sees zero or surplus
# operands. Suppress that guard while requiring it as a library; the
# subprocess tests below start a fresh `elixir` process, so this
# BEAM-application-env flag never reaches them.
Application.put_env(:lane_task_contract, :cli_suppressed, true)
Code.require_file(Path.join([__DIR__, "..", "scripts", "lane_task_envelope.exs"]))

defmodule LaneTaskEnvelopeTest do
  use ExUnit.Case, async: true

  @fixture Path.join([__DIR__, "..", "examples", "task-envelope.json"])
  @valid JSON.decode!(File.read!(@fixture))

  defp errors(envelope) do
    case LaneTaskEnvelope.validate(envelope) do
      :ok -> []
      {:error, errors} -> errors
    end
  end

  test "accepts the shipped example envelope" do
    assert :ok == LaneTaskEnvelope.validate(@valid)
  end

  describe "the CLI entry point (subprocess)" do
    @envelope_script Path.join([__DIR__, "..", "scripts", "lane_task_envelope.exs"])

    test "exits 2 with zero operands" do
      {output, exit_code} = System.cmd("elixir", [@envelope_script], stderr_to_stdout: true)
      assert exit_code == 2
      assert output =~ "usage:"
    end

    test "exits 2 with surplus operands" do
      {output, exit_code} =
        System.cmd("elixir", [@envelope_script, @fixture, "extra-operand"],
          stderr_to_stdout: true
        )

      assert exit_code == 2
      assert output =~ "usage:"
    end

    test "exits 0 and prints valid with exactly one operand" do
      {output, exit_code} = System.cmd("elixir", [@envelope_script, @fixture], stderr_to_stdout: true)
      assert exit_code == 0
      assert output =~ "valid"
    end
  end

  describe "resolve_integration_head/1 (live git verification, not part of validate/1)" do
    test "accepts when integration.base_head matches the real merge base in the declared worktree" do
      assert :ok == LaneTaskEnvelope.resolve_integration_head(@valid)
    end

    test "rejects when integration.base_head does not exist in the worktree" do
      envelope = put_in(@valid, ["integration", "base_head"], String.duplicate("0", 40))
      assert {:error, [error]} = LaneTaskEnvelope.resolve_integration_head(envelope)
      assert error =~ "does not exist in the worktree"
    end

    test "rejects when integration.base_head does not match the actual merge base" do
      {head, 0} = System.cmd("git", ["rev-parse", "HEAD"])

      envelope = put_in(@valid, ["integration", "base_head"], String.trim(head))
      assert {:error, [error]} = LaneTaskEnvelope.resolve_integration_head(envelope)
      assert error =~ "does not match the merge base"
    end

    test "rejects when the declared worktree does not exist" do
      envelope = Map.put(@valid, "worktree", "/nonexistent/worktree/path")
      assert {:error, [error]} = LaneTaskEnvelope.resolve_integration_head(envelope)
      assert error =~ "worktree does not exist"
    end
  end

  describe "digest" do
    test "is a stable sha256 digest of the envelope content" do
      digest = LaneTaskEnvelope.digest(@valid)
      assert String.starts_with?(digest, "sha256:")
      assert digest == LaneTaskEnvelope.digest(@valid)
    end

    test "changes when the envelope content changes" do
      modified = Map.put(@valid, "owner", "someone-else")
      refute LaneTaskEnvelope.digest(@valid) == LaneTaskEnvelope.digest(modified)
    end
  end

  test "rejects an envelope that is not a map" do
    assert {:error, errors} = LaneTaskEnvelope.validate("not a map")
    assert errors == ["the envelope must be a JSON object"]
  end

  test "rejects an unsupported top-level field" do
    envelope = Map.put(@valid, "extra_field", "nope")
    assert "extra_field is not a permitted envelope field" in errors(envelope)
  end

  for field <- [
        "role",
        "owner",
        "issue",
        "branch",
        "worktree",
        "parent_task",
        "parent_agent",
        "result_path",
        "notification_state",
        "graph_depth",
        "panes",
        "delegation_allowed",
        "required_initial_state",
        "integration",
        "affects_runtime",
        "feature_test_inventory_path",
        "inputs",
        "outputs",
        "observable_goal",
        "red_tests",
        "green_commands",
        "repository_gates",
        "post_integration_tests",
        "deletion_decisions",
        "stop_conditions",
        "protected_actions",
        "writers",
        "agent"
      ] do
    test "rejects a missing #{field}" do
      envelope = Map.delete(@valid, unquote(field))
      assert Enum.any?(errors(envelope), &String.starts_with?(&1, unquote(field)))
    end
  end

  test "role must be lane" do
    envelope = Map.put(@valid, "role", "coordinator")
    assert "role must be \"lane\"" in errors(envelope)
  end

  test "owner must be a non-empty string" do
    envelope = Map.put(@valid, "owner", "")
    assert "owner must be a non-empty string" in errors(envelope)
  end

  test "issue must match an ORG-123 issue key" do
    envelope = Map.put(@valid, "issue", "nak452")
    assert "issue must match an ORG-123 issue key format" in errors(envelope)
  end

  test "branch must start with an accepted Conventional Commit type prefix" do
    envelope = Map.put(@valid, "branch", "nak-452-no-prefix")

    assert "branch must start with an accepted Conventional Commit type prefix" in errors(
             envelope
           )
  end

  test "branch accepts every Conventional Commit type prefix" do
    for type <- ~w(feature feat fix docs refactor test build ci chore perf style revert) do
      branch = "#{type}/cx/nak-452-example"

      envelope =
        @valid
        |> Map.put("branch", branch)
        |> put_in(["required_initial_state", "branch"], branch)

      assert [] == errors(envelope), "expected #{type}/ branch prefix to be accepted"
    end
  end

  test "worktree must be an absolute path" do
    envelope = Map.put(@valid, "worktree", "relative/path")
    assert "worktree must be an absolute path" in errors(envelope)
  end

  test "parent_task must be a non-empty string" do
    envelope = Map.put(@valid, "parent_task", "")
    assert "parent_task must be a non-empty string" in errors(envelope)
  end

  test "parent_agent must match the herdr agent name pattern" do
    envelope = Map.put(@valid, "parent_agent", "Not Valid")

    assert "parent_agent must match the herdr agent name pattern ^[a-z][a-z0-9_-]{0,31}$" in errors(
             envelope
           )
  end

  test "result_path must be relative" do
    envelope = Map.put(@valid, "result_path", "/absolute/results.json")
    assert "result_path must be a relative path" in errors(envelope)
  end

  test "result_path must not traverse out of the worktree" do
    envelope = Map.put(@valid, "result_path", "../escape.json")
    assert "result_path must not contain a parent directory segment" in errors(envelope)
  end

  test "notification_state must be a known state" do
    envelope = Map.put(@valid, "notification_state", "sent-ish")

    assert "notification_state must be one of: pending, sent, acknowledged" in errors(
             envelope
           )
  end

  test "graph_depth must be an integer from 0 through 2" do
    envelope = Map.put(@valid, "graph_depth", 3)
    assert "graph_depth must be an integer from 0 through 2" in errors(envelope)
  end

  test "panes must be an integer from 1 through 4" do
    envelope = Map.put(@valid, "panes", 5)
    assert "panes must be an integer from 1 through 4" in errors(envelope)
  end

  test "panes rejects zero panes" do
    envelope = Map.put(@valid, "panes", 0)
    assert "panes must be an integer from 1 through 4" in errors(envelope)
  end

  describe "delegation_allowed and leaf commands" do
    test "must be a boolean" do
      envelope = Map.put(@valid, "delegation_allowed", "no")
      assert "delegation_allowed must be a boolean" in errors(envelope)
    end

    test "must be false when graph_depth is 2 (a leaf task must not delegate further)" do
      envelope =
        @valid
        |> Map.put("graph_depth", 2)
        |> Map.put("delegation_allowed", true)

      assert "delegation_allowed must be false when graph_depth is 2 (a leaf task must not delegate further)" in errors(
               envelope
             )
    end

    test "permits true when graph_depth is under the cap" do
      envelope = @valid |> Map.put("graph_depth", 1) |> Map.put("delegation_allowed", true)
      assert [] == errors(envelope)
    end

    test "rejects an attempted herdr agent start delegation when delegation_allowed is false" do
      envelope =
        @valid
        |> Map.put("delegation_allowed", false)
        |> Map.put("green_commands", [
          %{
            "command" => ["herdr", "agent", "start", "child", "--kind", "claude", "--pane", "p1"],
            "timeout_ms" => 5000
          }
        ])

      assert "green_commands[0].command must not start or delegate to another herdr agent when delegation_allowed is false" in errors(
               envelope
             )
    end

    test "rejects an attempted herdr agent prompt delegation when delegation_allowed is false" do
      envelope =
        @valid
        |> Map.put("delegation_allowed", false)
        |> Map.put("green_commands", [
          %{"command" => ["herdr", "agent", "prompt", "child", "do-work"], "timeout_ms" => 5000}
        ])

      assert "green_commands[0].command must not start or delegate to another herdr agent when delegation_allowed is false" in errors(
               envelope
             )
    end

    test "permits herdr agent start when delegation_allowed is true" do
      envelope =
        @valid
        |> Map.put("delegation_allowed", true)
        |> Map.put("green_commands", [
          %{
            "command" => ["herdr", "agent", "start", "child", "--kind", "claude", "--pane", "p1"],
            "timeout_ms" => 5000
          }
        ])

      assert [] == errors(envelope)
    end
  end

  describe "required_initial_state" do
    test "must include branch, clean_worktree, and base_ref" do
      envelope = Map.put(@valid, "required_initial_state", %{})

      state_errors = errors(envelope)
      assert Enum.any?(state_errors, &String.starts_with?(&1, "required_initial_state"))
    end

    test "branch must match the envelope branch" do
      envelope =
        Map.put(@valid, "required_initial_state", %{
          "branch" => "feat/cx/nak-000-other",
          "clean_worktree" => true,
          "base_ref" => "main"
        })

      assert "required_initial_state.branch must equal the envelope branch" in errors(envelope)
    end

    test "clean_worktree must be true" do
      envelope =
        Map.put(@valid, "required_initial_state", %{
          "branch" => @valid["branch"],
          "clean_worktree" => false,
          "base_ref" => "main"
        })

      assert "required_initial_state.clean_worktree must be true" in errors(envelope)
    end
  end

  test "inputs must be a non-empty list of non-empty strings" do
    envelope = Map.put(@valid, "inputs", [])
    assert "inputs must be a non-empty list of non-empty strings" in errors(envelope)
  end

  test "outputs must be a non-empty list of non-empty strings" do
    envelope = Map.put(@valid, "outputs", [""])
    assert "outputs must be a non-empty list of non-empty strings" in errors(envelope)
  end

  test "observable_goal must be a non-empty string" do
    envelope = Map.put(@valid, "observable_goal", "")
    assert "observable_goal must be a non-empty string" in errors(envelope)
  end

  test "observable_goal must be a single line" do
    envelope = Map.put(@valid, "observable_goal", "line one\nline two")
    assert "observable_goal must not contain a newline" in errors(envelope)
  end

  describe "command lists" do
    for field <- ["red_tests", "green_commands", "repository_gates", "post_integration_tests"] do
      test "#{field} must be a non-empty list" do
        envelope = Map.put(@valid, unquote(field), [])

        assert "#{unquote(field)} must be a non-empty list of command objects" in errors(
                 envelope
               )
      end

      test "#{field} rejects a shell string instead of an argv list" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => "mix test", "timeout_ms" => 1000}
          ])

        assert "#{unquote(field)}[0].command must be an argv list, not a shell string" in errors(
                 envelope
               )
      end

      test "#{field} rejects shell metacharacters in an argv token" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => ["mix", "test && rm -rf /"], "timeout_ms" => 1000}
          ])

        assert "#{unquote(field)}[0].command contains an argv token with unsupported characters" in errors(
                 envelope
               )
      end

      test "#{field} rejects a manual database lifecycle command" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => ["dropdb", "app_dev"], "timeout_ms" => 1000}
          ])

        assert "#{unquote(field)}[0].command must not run a manual database lifecycle command" in errors(
                 envelope
               )
      end

      test "#{field} rejects a wait over 60000 ms" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => ["mix", "test"], "timeout_ms" => 60_001}
          ])

        assert "#{unquote(field)}[0].timeout_ms must be an integer from 1 through 60000" in errors(
                 envelope
               )
      end

      test "#{field} rejects a manual database lifecycle command wrapped in env" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{
              "command" => ["env", "DATABASE_URL=x", "dropdb", "app_dev"],
              "timeout_ms" => 1000
            }
          ])

        assert "#{unquote(field)}[0].command must not run a manual database lifecycle command" in errors(
                 envelope
               )
      end

      test "#{field} rejects a manual database lifecycle command wrapped in mise exec --" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => ["mise", "exec", "--", "dropdb", "app_dev"], "timeout_ms" => 1000}
          ])

        assert "#{unquote(field)}[0].command must not run a manual database lifecycle command" in errors(
                 envelope
               )
      end

      test "#{field} rejects a manual database lifecycle command wrapped in sh -c" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => ["sh", "-c", "dropdb"], "timeout_ms" => 1000}
          ])

        assert "#{unquote(field)}[0].command must not run a manual database lifecycle command" in errors(
                 envelope
               )
      end

      test "#{field} rejects a manual database lifecycle command wrapped in bash -c" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => ["bash", "-c", "dropdb"], "timeout_ms" => 1000}
          ])

        assert "#{unquote(field)}[0].command must not run a manual database lifecycle command" in errors(
                 envelope
               )
      end

      test "#{field} permits an env-wrapped command that is not a database lifecycle command" do
        envelope =
          Map.put(@valid, unquote(field), [
            %{"command" => ["env", "MIX_ENV=test", "mix", "test"], "timeout_ms" => 1000}
          ])

        refute Enum.any?(errors(envelope), &String.contains?(&1, "database lifecycle"))
      end
    end
  end

  describe "repository_gates handoff cadence" do
    test "each repository gate must declare when: handoff" do
      envelope =
        Map.put(@valid, "repository_gates", [
          %{"command" => ["mise", "run", "verify:quick"], "timeout_ms" => 60_000}
        ])

      assert "repository_gates[0].when must equal \"handoff\"" in errors(envelope)
    end

    test "a repository gate must not declare a per-commit cadence" do
      envelope =
        Map.put(@valid, "repository_gates", [
          %{
            "command" => ["mise", "run", "verify:quick"],
            "timeout_ms" => 60_000,
            "when" => "every-commit"
          }
        ])

      assert "repository_gates[0].when must equal \"handoff\"" in errors(envelope)
    end
  end

  describe "integration" do
    test "must include target, base_head, and branch_lifecycle" do
      envelope = Map.put(@valid, "integration", %{})

      integration_errors = errors(envelope)
      assert Enum.any?(integration_errors, &String.starts_with?(&1, "integration"))
    end

    test "target must be a non-empty string" do
      envelope = put_in(@valid, ["integration", "target"], "")
      assert "integration.target must be a non-empty string" in errors(envelope)
    end

    test "base_head must be a full 40-character lowercase commit sha" do
      envelope = put_in(@valid, ["integration", "base_head"], "main")

      assert "integration.base_head must be a full 40-character lowercase commit sha" in errors(
               envelope
             )
    end

    test "branch_lifecycle must be short-lived" do
      envelope = put_in(@valid, ["integration", "branch_lifecycle"], "long-lived")
      assert "integration.branch_lifecycle must be \"short-lived\"" in errors(envelope)
    end

    test "rejects an unsupported integration field" do
      envelope = put_in(@valid, ["integration", "extra"], "nope")
      assert "integration.extra is not a permitted field" in errors(envelope)
    end
  end

  describe "affects_runtime and live_smoke" do
    test "affects_runtime must be a boolean" do
      envelope = Map.put(@valid, "affects_runtime", "yes")
      assert "affects_runtime must be a boolean" in errors(envelope)
    end

    test "live_smoke is required when affects_runtime is true and absent" do
      envelope = Map.put(@valid, "affects_runtime", true)
      assert "live_smoke is required when affects_runtime is true" in errors(envelope)
    end

    test "live_smoke must be a valid command object when affects_runtime is true" do
      envelope =
        @valid
        |> Map.put("affects_runtime", true)
        |> Map.put("live_smoke", %{"command" => "curl localhost", "timeout_ms" => 5000})

      assert "live_smoke.command must be an argv list, not a shell string" in errors(envelope)
    end

    test "live_smoke passes command safety rules when affects_runtime is true" do
      envelope =
        @valid
        |> Map.put("affects_runtime", true)
        |> Map.put("live_smoke", %{
          "command" => ["curl", "-fsS", "http://localhost:4000/health"],
          "timeout_ms" => 5000
        })

      assert [] == errors(envelope)
    end

    test "live_smoke rejects a trivial no-op probe" do
      envelope =
        @valid
        |> Map.put("affects_runtime", true)
        |> Map.put("live_smoke", %{"command" => ["true"], "timeout_ms" => 1000})

      assert "live_smoke.command must be an observable probe, not a no-op like [\"true\"]" in errors(
               envelope
             )
    end

    test "live_smoke rejects a unit-test runner standing in for a live probe" do
      envelope =
        @valid
        |> Map.put("affects_runtime", true)
        |> Map.put("live_smoke", %{
          "command" => ["elixir", "test/lane_task_envelope_test.exs"],
          "timeout_ms" => 5000
        })

      assert "live_smoke.command must be an observable probe, not a unit-test runner" in errors(
               envelope
             )
    end

    test "live_smoke must be absent when affects_runtime is false" do
      envelope =
        Map.put(@valid, "live_smoke", %{
          "command" => ["curl", "-fsS", "http://localhost:4000/health"],
          "timeout_ms" => 5000
        })

      assert "live_smoke must be absent when affects_runtime is false" in errors(envelope)
    end
  end

  test "feature_test_inventory_path must be a non-empty relative path" do
    envelope = Map.put(@valid, "feature_test_inventory_path", "/absolute/inventory.md")
    assert "feature_test_inventory_path must be a relative path" in errors(envelope)
  end

  describe "deletion_decisions" do
    test "an empty list is valid" do
      envelope = Map.put(@valid, "deletion_decisions", [])
      assert [] == errors(envelope)
    end

    test "must reject deletion_decisions that is not a list" do
      envelope = Map.put(@valid, "deletion_decisions", "none")
      assert "deletion_decisions must be a list of {target, replacement_decision} objects" in errors(
               envelope
             )
    end

    test "each entry must have a non-empty target and replacement_decision" do
      envelope = Map.put(@valid, "deletion_decisions", [%{"target" => "old_field.ex"}])

      assert "deletion_decisions[0] must have a non-empty target and replacement_decision" in errors(
               envelope
             )
    end
  end

  test "stop_conditions must be a non-empty list of non-empty strings" do
    envelope = Map.put(@valid, "stop_conditions", [])
    assert "stop_conditions must be a non-empty list of non-empty strings" in errors(envelope)
  end

  describe "protected_actions" do
    test "must be a non-empty list" do
      envelope = Map.put(@valid, "protected_actions", [])
      assert "protected_actions must be a non-empty list" in errors(envelope)
    end

    test "must be drawn from the protected action vocabulary" do
      envelope = Map.put(@valid, "protected_actions", ["make-coffee"])

      assert "protected_actions[0] must be one of: credential-changes, deploy, force-push, merge, production-effects, public-ingress, push, release" in errors(
               envelope
             )
    end

    test "must not repeat an action" do
      envelope = Map.put(@valid, "protected_actions", ["merge", "merge"])
      assert "protected_actions must not repeat an action" in errors(envelope)
    end
  end

  describe "writers" do
    test "rejects duplicate writer ownership of the same path" do
      envelope =
        Map.put(@valid, "writers", [
          %{"path" => "skills/define-lane-task-contract/", "owner" => "lane-a"},
          %{"path" => "skills/define-lane-task-contract/", "owner" => "lane-b"}
        ])

      assert "writers must not assign more than one owner to the same path" in errors(envelope)
    end

    test "normalizes a trailing slash before comparing paths" do
      envelope =
        Map.put(@valid, "writers", [
          %{"path" => "skills/define-lane-task-contract/", "owner" => "lane-a"},
          %{"path" => "skills/define-lane-task-contract", "owner" => "lane-b"}
        ])

      assert "writers must not assign more than one owner to the same path" in errors(envelope)
    end

    test "rejects an ancestor-descendant overlap" do
      envelope =
        Map.put(@valid, "writers", [
          %{"path" => "skills/define-lane-task-contract", "owner" => "lane-a"},
          %{"path" => "skills/define-lane-task-contract/scripts", "owner" => "lane-b"}
        ])

      assert "writers must not assign more than one owner to the same path" in errors(envelope)
    end

    test "permits disjoint sibling paths" do
      envelope =
        Map.put(@valid, "writers", [
          %{"path" => "skills/define-lane-task-contract/scripts", "owner" => "lane-a"},
          %{"path" => "skills/define-lane-task-contract/test", "owner" => "lane-b"}
        ])

      assert [] == errors(envelope)
    end
  end

  describe "agent" do
    test "kind and mode must be non-empty strings" do
      envelope = Map.put(@valid, "agent", %{"kind" => "", "mode" => "auto"})
      assert "agent.kind must be a non-empty string" in errors(envelope)
    end

    test "a claude auto contract requires a current supported model" do
      envelope =
        put_in(@valid, ["agent", "model"], "claude-2")

      assert "agent.model must be a currently supported Claude model" in errors(envelope)
    end

    test "a claude auto contract requires permission_mode auto" do
      envelope = put_in(@valid, ["agent", "permission_mode"], "manual")
      assert "agent.permission_mode must be \"auto\"" in errors(envelope)
    end

    test "a claude auto contract requires visible startup verification" do
      envelope = put_in(@valid, ["agent", "startup_verification"], "silent")
      assert "agent.startup_verification must be \"visible\"" in errors(envelope)
    end

    test "a non-auto claude agent does not require the auto contract fields" do
      envelope =
        @valid
        |> put_in(["agent", "mode"], "supervised")
        |> Map.update!("agent", &Map.drop(&1, ["model", "permission_mode", "startup_verification"]))

      assert [] == errors(envelope)
    end
  end
end
