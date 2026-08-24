# lane_task_envelope.exs and lane_task_result.exs each auto-run their own
# CLI unless :lane_task_contract's :cli_suppressed application env is set.
# Suppress it around these requires so this script's own argv never
# triggers their guards with the wrong shape (this flag lives in the BEAM
# application environment, not an OS env var, so it never leaks into a
# System.cmd child process), then restore it before this script's own CLI
# guard below.
already_suppressed? = Application.get_env(:lane_task_contract, :cli_suppressed, false)
Application.put_env(:lane_task_contract, :cli_suppressed, true)
Code.require_file(Path.join([__DIR__, "lane_task_envelope.exs"]))
Code.require_file(Path.join([__DIR__, "lane_task_result.exs"]))
Application.put_env(:lane_task_contract, :cli_suppressed, already_suppressed?)

defmodule NotifyParent do
  @moduledoc """
  Validate a lane task envelope and its result, then notify the exact
  parent agent named in the envelope through `herdr agent prompt`.

  The event handed to the parent carries a fixed, closed set of fields.
  It never embeds a lane-authored free-text field (such as `evidence`),
  because that text could carry a prompt injection into the parent
  agent's next turn.
  """

  @event_fields ~w(
    type issue branch role parent_task status commit result_path
    envelope_digest
  )

  @spec validate(map(), map()) :: :ok | {:error, [String.t()]}
  def validate(task, result) do
    task_errors =
      case LaneTaskEnvelope.validate(task) do
        :ok -> []
        {:error, errors} -> errors
      end

    result_errors =
      case LaneTaskResult.validate(result, task) do
        :ok -> []
        {:error, errors} -> errors
      end

    case task_errors ++ result_errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  @spec parent_target(map()) :: String.t()
  def parent_target(task), do: task["parent_agent"]

  defp event_type(%{"status" => "blocked"}), do: "lane_task_blocked"
  defp event_type(_result), do: "lane_task_result"

  @spec build_event(map(), map()) :: map()
  def build_event(task, result) do
    event = %{
      "type" => event_type(result),
      "issue" => task["issue"],
      "branch" => task["branch"],
      "role" => task["role"],
      "parent_task" => task["parent_task"],
      "status" => result["status"],
      "commit" => result["commit"],
      "result_path" => result["result_path"],
      "envelope_digest" => LaneTaskEnvelope.digest(task)
    }

    ^event = Map.take(event, @event_fields)
    event
  end

  @doc """
  Parent-side check, run before any action on an incoming event: does the
  event's envelope_digest match the digest of the original envelope this
  coordinator actually issued? Herdr itself does not perform this check —
  it only delivers the prompt text — so the coordinator must call this
  against its own retained original before trusting a result or blocker
  event, whether the mismatch comes from a modified envelope or an event
  that actually belongs to a different parent's original envelope.
  """
  @spec verify_against_original(map(), map()) :: :ok | {:error, String.t()}
  def verify_against_original(event, original_envelope) do
    if event["envelope_digest"] == LaneTaskEnvelope.digest(original_envelope) do
      :ok
    else
      {:error,
       "the event's envelope_digest does not match this coordinator's original envelope"}
    end
  end

  @spec send!(String.t(), String.t()) :: :ok
  def send!(parent_target, event_json) do
    {_output, 0} = System.cmd("herdr", ["agent", "prompt", parent_target, event_json])
    :ok
  end

  @spec main([String.t()]) :: :ok
  def main([task_path, result_path]) do
    task = task_path |> File.read!() |> JSON.decode!()
    result = result_path |> File.read!() |> JSON.decode!()

    case validate(task, result) do
      :ok ->
        event = build_event(task, result)
        send!(parent_target(task), JSON.encode!(event))
        IO.puts("notify_parent: sent lane_task_result for #{task["issue"]} to #{parent_target(task)}")

      {:error, errors} ->
        Enum.each(errors, fn error -> IO.puts(:stderr, "notify_parent: #{error}") end)
        System.halt(1)
    end
  end

  def main(_argv) do
    IO.puts(:stderr, "usage: elixir notify_parent.exs <task.json> <result.json>")
    System.halt(2)
  end
end

unless Application.get_env(:lane_task_contract, :cli_suppressed, false) do
  NotifyParent.main(System.argv())
end
