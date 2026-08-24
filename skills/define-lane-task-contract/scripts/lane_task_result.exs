defmodule LaneTaskResult do
  @moduledoc """
  Dependency-free validator for a lane task result, cross-checked against
  the task envelope it reports against.
  """

  @allowed_fields ~w(task_issue result_path status commit red_evidence green_evidence)
  @statuses ~w(green red blocked)
  @sha_pattern ~r/^[0-9a-f]{40}$/

  @spec validate(term(), map()) :: :ok | {:error, [String.t()]}
  def validate(result, task) when is_map(result) and is_map(task) do
    errors =
      []
      |> Kernel.++(unsupported_field_errors(result))
      |> Kernel.++(task_issue_errors(result, task))
      |> Kernel.++(result_path_errors(result, task))
      |> Kernel.++(status_errors(result))
      |> Kernel.++(commit_errors(result))
      |> Kernel.++(evidence_errors(result, "red_evidence"))
      |> Kernel.++(evidence_errors(result, "green_evidence"))

    case errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  def validate(_result, _task), do: {:error, ["the result must be a JSON object"]}

  defp unsupported_field_errors(result) do
    for key <- Map.keys(result), key not in @allowed_fields do
      "#{key} is not a permitted result field"
    end
  end

  defp task_issue_errors(result, task) do
    case Map.fetch(result, "task_issue") do
      :error ->
        ["task_issue is required"]

      {:ok, value} ->
        if value == task["issue"], do: [], else: ["task_issue must equal the task issue"]
    end
  end

  defp result_path_errors(result, task) do
    case Map.fetch(result, "result_path") do
      :error ->
        ["result_path is required"]

      {:ok, value} ->
        if value == task["result_path"],
          do: [],
          else: ["result_path must equal the task result_path"]
    end
  end

  defp status_errors(result) do
    case Map.fetch(result, "status") do
      :error ->
        ["status is required"]

      {:ok, value} when value in @statuses ->
        []

      {:ok, _value} ->
        ["status must be one of: #{@statuses |> Enum.sort() |> Enum.join(", ")}"]
    end
  end

  defp commit_errors(result) do
    case Map.fetch(result, "commit") do
      :error ->
        # Omitting commit entirely is permitted for a red or blocked
        # result; only a green result must carry the delivering commit.
        commit_required_error(result)

      {:ok, nil} ->
        commit_required_error(result)

      {:ok, value} when is_binary(value) ->
        if Regex.match?(@sha_pattern, value) do
          []
        else
          ["commit must be a full 40-character lowercase commit sha"]
        end

      {:ok, _value} ->
        ["commit must be a full 40-character lowercase commit sha"]
    end
  end

  defp commit_required_error(result) do
    if Map.get(result, "status") == "green" do
      ["commit is required when status is \"green\""]
    else
      []
    end
  end

  defp evidence_errors(result, field) do
    case Map.fetch(result, field) do
      :error ->
        ["#{field} must be a non-empty list of non-empty strings"]

      {:ok, list} when is_list(list) ->
        if list != [] and Enum.all?(list, &(is_binary(&1) and &1 != "")) do
          []
        else
          ["#{field} must be a non-empty list of non-empty strings"]
        end

      {:ok, _value} ->
        ["#{field} must be a non-empty list of non-empty strings"]
    end
  end
end

unless Application.get_env(:lane_task_contract, :cli_suppressed, false) do
  case System.argv() do
    [result_path, task_path] ->
      result = result_path |> File.read!() |> JSON.decode!()
      task = task_path |> File.read!() |> JSON.decode!()

      case LaneTaskResult.validate(result, task) do
        :ok ->
          IO.puts("lane task result: valid (#{result_path})")

        {:error, errors} ->
          Enum.each(errors, fn error -> IO.puts(:stderr, "lane task result: #{error}") end)
          System.halt(1)
      end

    _other ->
      IO.puts(:stderr, "usage: elixir lane_task_result.exs <result.json> <task.json>")
      System.halt(2)
  end
end
