ExUnit.start()

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
        "required_initial_state",
        "inputs",
        "outputs",
        "observable_goal",
        "red_tests",
        "green_commands",
        "repository_gates",
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
    for field <- ["red_tests", "green_commands", "repository_gates"] do
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
