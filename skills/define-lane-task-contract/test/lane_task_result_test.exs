ExUnit.start()

# lane_task_envelope.exs and lane_task_result.exs each exit 2 when their
# own CLI sees zero or surplus operands. Suppress that guard while
# requiring them as a library; the subprocess tests below start a fresh
# `elixir` process, so this BEAM-application-env flag never reaches them.
Application.put_env(:lane_task_contract, :cli_suppressed, true)
Code.require_file(Path.join([__DIR__, "..", "scripts", "lane_task_envelope.exs"]))
Code.require_file(Path.join([__DIR__, "..", "scripts", "lane_task_result.exs"]))

defmodule LaneTaskResultTest do
  use ExUnit.Case, async: true

  @task_fixture Path.join([__DIR__, "..", "examples", "task-envelope.json"])
  @task JSON.decode!(File.read!(@task_fixture))
  @valid_result %{
    "task_issue" => @task["issue"],
    "result_path" => @task["result_path"],
    "status" => "green",
    "commit" => String.duplicate("a", 40),
    "red_evidence" => ["lane_task_envelope_test.exs failed before implementation existed"],
    "green_evidence" => ["mise run verify:quick: pass"]
  }

  defp errors(result, task \\ @task) do
    case LaneTaskResult.validate(result, task) do
      :ok -> []
      {:error, errors} -> errors
    end
  end

  test "accepts a matching green result" do
    assert :ok == LaneTaskResult.validate(@valid_result, @task)
  end

  test "accepts a red result without a commit" do
    result = @valid_result |> Map.put("status", "red") |> Map.put("commit", nil)
    assert :ok == LaneTaskResult.validate(result, @task)
  end

  test "rejects a result that is not a map" do
    assert {:error, ["the result must be a JSON object"]} == LaneTaskResult.validate([], @task)
  end

  test "rejects an unsupported field" do
    result = Map.put(@valid_result, "notes", "free text")
    assert "notes is not a permitted result field" in errors(result)
  end

  test "task_issue must equal the task issue" do
    result = Map.put(@valid_result, "task_issue", "NAK-000")
    assert "task_issue must equal the task issue" in errors(result)
  end

  test "result_path must equal the task result_path" do
    result = Map.put(@valid_result, "result_path", "somewhere/else.json")
    assert "result_path must equal the task result_path" in errors(result)
  end

  test "status must be one of green, red, blocked" do
    result = Map.put(@valid_result, "status", "ok")
    assert "status must be one of: blocked, green, red" in errors(result)
  end

  test "green status requires a commit" do
    result = Map.put(@valid_result, "commit", nil)
    assert "commit is required when status is \"green\"" in errors(result)
  end

  test "commit must be a full 40-character lowercase sha when present" do
    result = Map.put(@valid_result, "commit", "not-a-sha")
    assert "commit must be a full 40-character lowercase commit sha" in errors(result)
  end

  test "commit may be entirely omitted for a red result" do
    result = @valid_result |> Map.delete("commit") |> Map.put("status", "red")
    assert :ok == LaneTaskResult.validate(result, @task)
  end

  test "commit may be entirely omitted for a blocked result" do
    result = @valid_result |> Map.delete("commit") |> Map.put("status", "blocked")
    assert :ok == LaneTaskResult.validate(result, @task)
  end

  test "commit omission is rejected for a green result" do
    result = Map.delete(@valid_result, "commit")
    assert "commit is required when status is \"green\"" in errors(result)
  end

  test "red_evidence must be a non-empty list of non-empty strings" do
    result = Map.put(@valid_result, "red_evidence", [])
    assert "red_evidence must be a non-empty list of non-empty strings" in errors(result)
  end

  test "green_evidence must be a non-empty list of non-empty strings" do
    result = Map.put(@valid_result, "green_evidence", [])
    assert "green_evidence must be a non-empty list of non-empty strings" in errors(result)
  end

  describe "the CLI entry point (subprocess)" do
    @result_script Path.join([__DIR__, "..", "scripts", "lane_task_result.exs"])

    defp write_temp_json(basename, content) do
      path =
        Path.join(
          System.tmp_dir!(),
          "#{basename}-#{System.unique_integer([:positive])}.json"
        )

      File.write!(path, JSON.encode!(content))
      path
    end

    test "exits 2 with zero operands" do
      {output, exit_code} = System.cmd("elixir", [@result_script], stderr_to_stdout: true)
      assert exit_code == 2
      assert output =~ "usage:"
    end

    test "exits 2 with surplus operands" do
      result_path = write_temp_json("valid-result", @valid_result)

      {output, exit_code} =
        System.cmd("elixir", [@result_script, result_path, @task_fixture, "extra"],
          stderr_to_stdout: true
        )

      assert exit_code == 2
      assert output =~ "usage:"
    end

    test "exits 0 and prints valid with exactly two operands in order" do
      result_path = write_temp_json("valid-result", @valid_result)

      {output, exit_code} =
        System.cmd("elixir", [@result_script, result_path, @task_fixture], stderr_to_stdout: true)

      assert exit_code == 0
      assert output =~ "valid"
    end
  end
end
